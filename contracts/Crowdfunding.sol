// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        uint goal;
        uint pledged;
        uint deadline;
        bool completed;
        mapping(address => uint) contributions;
    }

    mapping(uint => Campaign) private campaigns;
    uint public campaignCount;

    event CampaignCreated(uint id, address creator, uint goal, uint deadline);
    event Contributed(uint id, address contributor, uint amount);
    event Withdrawn(uint id, address creator, uint amount);
    event Refunded(uint id, address contributor, uint amount);

    // Create a new campaign
    function createCampaign(uint _goal, uint _duration) external {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.creator = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.deadline = block.timestamp + _duration;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, msg.sender, _goal, newCampaign.deadline);
    }

    // Contribute to a campaign
    function contribute(uint _id) external payable {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(msg.value > 0, "Contribution must be greater than 0");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit Contributed(_id, msg.sender, msg.value);
    }

    // Withdraw funds if the campaign is successful
    function withdrawFunds(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "Only the creator can withdraw");
        require(block.timestamp > campaign.deadline, "Campaign not ended yet");
        require(campaign.pledged >= campaign.goal, "Goal not reached");
        require(!campaign.completed, "Campaign already completed");

        uint amount = campaign.pledged;
        campaign.completed = true;
        campaign.pledged = 0;

        campaign.creator.transfer(amount);

        emit Withdrawn(_id, msg.sender, amount);
    }

    // Refund contributions if the campaign failed
    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.deadline, "Campaign not ended yet");
        require(campaign.pledged < campaign.goal, "Goal reached, no refunds");

        uint contributed = campaign.contributions[msg.sender];
        require(contributed > 0, "No contributions to refund");

        campaign.contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributed);

        emit Refunded(_id, msg.sender, contributed);
    }

    // Get campaign details
    function getCampaign(uint _id) external view returns (
        address creator,
        uint goal,
        uint pledged,
        uint deadline,
        bool completed
    ) {
        Campaign storage campaign = campaigns[_id];
        return (
            campaign.creator,
            campaign.goal,
            campaign.pledged,
            campaign.deadline,
            campaign.completed
        );
    }

    // Get the contribution of an address to a campaign
    function getContribution(uint _id, address _contributor) external view returns (uint) {
        Campaign storage campaign = campaigns[_id];
        return campaign.contributions[_contributor];
    }

    // Get the status of a campaign
    function getStatus(uint _id) public view returns (string memory) {
        Campaign storage campaign = campaigns[_id];

        if (block.timestamp >= campaign.deadline) {
            if (campaign.pledged >= campaign.goal) {
                return "Completed";
            } else {
                return "Failed";
            }
        } else {
            return "Active";
        }
    }
}
