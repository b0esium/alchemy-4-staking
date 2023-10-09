//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ExampleExternalContract {
    bool public isCompleted;

    function completed() public view returns(bool) {
        return isCompleted;
    }

    function complete() public payable {
        isCompleted = true;
    }
}