// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        uint goal;
        uint pledged;
        uint deadline;
        bool completed;
    }

    mapping(uint => Campaign) public campaigns;
    uint public campaignCount;

    event CampaignCreated(uint id, address creator, uint goal, uint deadline);
    event Contributed(uint id, address contributor, uint amount);
    event Withdrawn(uint id, address creator, uint amount);
    event CampaignStatus(uint id, string status);

    // Create a new campaign
    function createCampaign(uint _goal, uint _duration) external {
        require(_goal > 0, "Goal must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        campaignCount++;
        campaigns[campaignCount] = Campaign(
            payable(msg.sender),
            _goal,
            0,
            block.timestamp + _duration,
            false
        );

        emit CampaignCreated(campaignCount, msg.sender, _goal, block.timestamp + _duration);
    }

    // Contribute to a campaign
    function contribute(uint _id) external payable {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(msg.value > 0, "Contribution must be greater than 0");

        campaign.pledged += msg.value;

        emit Contributed(_id, msg.sender, msg.value);
    }

    // Withdraw funds if the campaign is successful
    function withdrawFunds(uint256 campaignId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender, "Only the creator can withdraw");
        require(block.timestamp > campaign.deadline, "Campaign not ended yet");
        require(campaign.pledged >= campaign.goal, "Goal not reached");

        uint256 amount = campaign.pledged;
        campaign.pledged = 0;
        campaign.completed = true;
        payable(campaign.creator).transfer(amount);

        emit Withdrawn(campaignId, msg.sender, amount);
    }

    // Get the status of a campaign
    function getStatus(uint256 campaignId) public view returns (string memory) {
        Campaign storage campaign = campaigns[campaignId];
        if (block.timestamp < campaign.deadline) {
            return "Active";
        } else {
            if (campaign.pledged >= campaign.goal) {
                return "Completed";
            } else {
                return "Failed";
            }
        }
    }
}
