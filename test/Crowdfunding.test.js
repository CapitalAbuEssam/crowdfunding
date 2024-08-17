const Crowdfunding = artifacts.require("Crowdfunding");
const { time } = require('@openzeppelin/test-helpers');

contract("Crowdfunding", (accounts) => {
    let crowdfunding;
    const [creator, contributor1, contributor2] = accounts;

    beforeEach(async () => {
        crowdfunding = await Crowdfunding.new();
    });

    it("should create a campaign", async () => {
        const goal = web3.utils.toWei("1", "ether");
        const duration = 86400; // 1 day in seconds

        await crowdfunding.createCampaign(goal, duration, { from: creator });

        const campaign = await crowdfunding.getCampaign(1);

        assert.equal(campaign.creator, creator, "Campaign creator is incorrect");
        assert.equal(campaign.goal.toString(), goal, "Campaign goal is incorrect");
        assert.equal(campaign.pledged.toString(), '0', "Campaign pledged amount should be 0");
        assert.equal(campaign.completed, false, "Campaign should not be completed");
    });

    it("should allow contributions", async () => {
        const goal = web3.utils.toWei("1", "ether");
        const duration = 86400; // 1 day in seconds

        await crowdfunding.createCampaign(goal, duration, { from: creator });

        const contribution = web3.utils.toWei("0.5", "ether");

        await crowdfunding.contribute(1, { from: contributor1, value: contribution });

        const campaign = await crowdfunding.getCampaign(1);
        const contributionAmount = await crowdfunding.getContribution(1, contributor1);

        assert.equal(campaign.pledged.toString(), contribution, "Campaign pledged amount is incorrect");
        assert.equal(contributionAmount.toString(), contribution, "Contributor's contribution is incorrect");
    });

    it("should allow withdrawal if the goal is met", async () => {
        const goal = web3.utils.toWei("1", "ether");
        const duration = 86400; // 1 day in seconds

        await crowdfunding.createCampaign(goal, duration, { from: creator });

        const contribution = web3.utils.toWei("1", "ether");

        await crowdfunding.contribute(1, { from: contributor1, value: contribution });

        // Increase time to after the campaign deadline
        await time.increase(duration + 1000); // 1 day + 1 second

        const initialBalance = web3.utils.toBN(await web3.eth.getBalance(creator));

        await crowdfunding.withdrawFunds(1, { from: creator });

        const campaign = await crowdfunding.getCampaign(1);
        const finalBalance = web3.utils.toBN(await web3.eth.getBalance(creator));

        assert.equal(campaign.completed, true, "Campaign should be marked as completed");
        assert(finalBalance.gt(initialBalance), "Creator's balance should have increased");
    });

    it("should fail to withdraw funds if the goal is not met", async () => {
        const goal = web3.utils.toWei("2", "ether");
        const duration = 86400; // 1 day in seconds

        await crowdfunding.createCampaign(goal, duration, { from: creator });

        const contribution = web3.utils.toWei("1", "ether");

        await crowdfunding.contribute(1, { from: contributor1, value: contribution });

        // Increase time to after the campaign deadline
        await time.increase(duration + 1000); // 1 day + 1 second

        try {
            await crowdfunding.withdrawFunds(1, { from: creator });
            assert.fail("Expected withdraw to fail because goal wasn't met");
        } catch (error) {
            assert(error.message.includes("Goal not reached"), `Expected "Goal not reached" but got ${error.message}`);
        }
    });

    it("should refund contributions if the campaign failed", async () => {
        const goal = web3.utils.toWei("2", "ether");
        const duration = 86400; // 1 day in seconds
    
        await crowdfunding.createCampaign(goal, duration, { from: creator });
    
        const contribution = web3.utils.toWei("1", "ether");
        await crowdfunding.contribute(1, { from: contributor1, value: contribution });
    
        // Increase time to after the campaign deadline
        await time.increase(duration + 1000); // 1 day + 1 second
    
        // Try refunding
        const initialBalance = web3.utils.toBN(await web3.eth.getBalance(contributor1));
    
        // Execute refund
        await crowdfunding.refund(1, { from: contributor1 });
    
        const newBalance = web3.utils.toBN(await web3.eth.getBalance(contributor1));
        const expectedRefundAmount = web3.utils.toBN(contribution);
        const actualRefundAmount = newBalance.sub(initialBalance);
    
        // Allow for a small margin of error due to gas costs
        const marginOfError = web3.utils.toBN(web3.utils.toWei("0.01", "ether"));
        assert(actualRefundAmount.gte(expectedRefundAmount.sub(marginOfError)) && actualRefundAmount.lte(expectedRefundAmount.add(marginOfError)),
               `Refund amount is not as expected. Expected ${expectedRefundAmount.toString()} but got ${actualRefundAmount.toString()}`);
    });

    it('should return the correct campaign status', async () => {
        const goal = web3.utils.toWei('1', 'ether');
        const duration = 3600; // 1 hour
        await crowdfunding.createCampaign(goal, duration, { from: creator });

        // Check status before deadline
        const statusBeforeDeadline = await crowdfunding.getStatus(1);
        assert.equal(statusBeforeDeadline, 'Active');

        // Advance time past deadline
        await time.increase(duration + 1000); // 1 hour + 1 second

        // Check status after deadline
        const statusAfterDeadline = await crowdfunding.getStatus(1);
        assert.equal(statusAfterDeadline, 'Failed');
    });
});
