//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrimeDetector is Ownable {
    struct Commitment {
        uint input;
        uint submitted;
        uint stake;
        bool valid;
    }

    Commitment[] public commitments;
    uint public minimum_stake = 1e18;

    function generatePrimeNumberCandidate(uint input) external payable onlyOwner {
        require(msg.value >= minimum_stake, 'Stake provided is not high enough');
        require(input != 1 && input != 2, 'trivially prime numbers provided');
        commitments.push(
            Commitment({
                input: input,
                submitted: block.timestamp,
                stake: msg.value,
                valid: true
            })
        );
    }

    function challenge(uint factor1, uint factor2, uint id) public payable {
        Commitment storage commitment = commitments[id];
        require(commitment.submitted + 3600 seconds >= block.timestamp, 'Challenging too late');    
        
        require(commitment.valid == true, 'No valid data to challenge');

        // Assumes that 1 and 2 are not valid commitment.input
        require(factor1 != 1 && factor2 != 1, '1 cannot be used as a factor to detect primality');
        require(factor1 * factor2 == commitment.input, 'Incorrect factors');
        

        delete commitments[id];

        // Burn the stake
        address payable zero = payable(0x0);
        zero.transfer(minimum_stake); 

        address payable owner = payable(owner());
        if (commitment.stake > minimum_stake) {
            owner.transfer(commitment.stake - minimum_stake);
        }
    }

    function getNumberOfCommitments() external view returns(uint) {
        return commitments.length;
    }

    function getMaybePrimeAt(uint id) external view returns(uint) {
        Commitment storage commitment = commitments[id];
        return commitment.input;
    }

    function commit(uint id) external {
        Commitment storage commitment = commitments[id];

        require(commitment.valid == true, 'No valid data to commit');

        require(commitment.submitted + 3600 seconds < block.timestamp, 'Committing too soon');
      
        address payable owner = payable(owner());
        owner.transfer(commitment.stake);
    }
}
