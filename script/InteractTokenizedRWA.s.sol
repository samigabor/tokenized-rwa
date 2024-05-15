// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { TokenizedRWA } from "../src/TokenizedRWA.sol";
import { console2 } from "forge-std/console2.sol";

address constant CONTRACT_ADDRESS = 0xa62612BbEae270609c888E677A61EEdEB9aA43a0;

contract InteractTokenizedRWA is Script {
    string constant alpacaBalance = "./functions/sources/alpacaBalance.js";

    function run() external {
        setParams();
        // getBalance();
        // sendRequest();
    }

    function sendRequest() public {
        vm.startBroadcast();

        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        console2.log("Sending request...");
        rwa.sendQueryPortfolioBalanceRequest();
        console2.log("Sent request!!!");

        vm.stopBroadcast();
    }

    function getBalance() public {
        vm.startBroadcast();

        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        console2.log("Querying balance...");
        uint256 balance = rwa.s_portfolioBalance();
        console2.log("Balance = ", balance);

        vm.stopBroadcast();
    }

    function setParams() public {
        string memory getBalanceSourceCode = vm.readFile(alpacaBalance);
        vm.startBroadcast();

        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        rwa.setSourceCode(getBalanceSourceCode);
        console2.log("rwa.setSourceCode", getBalanceSourceCode);

        vm.stopBroadcast();
    }
}
