// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { TokenizedRWA } from "../src/TokenizedRWA.sol";
import { console2 } from "forge-std/console2.sol";

address constant CONTRACT_ADDRESS = 0x1aF9647d8F51Fe57c4588540d08Aa505905d1B98;

contract InteractTokenizedRWA is Script {
    string constant alpacaBalance = "./functions/sources/alpacaBalance.js";

    function run() external {
        // getBalance();
        // setParams();
        sendRequest();
    }

    function getBalance() public {
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        console2.log("InteractTokenizedRWA.getBalance: s_portfolioBalance=%s", rwa.s_portfolioBalance());
        vm.stopBroadcast();
    }

    function setParams() public {
        string memory getBalanceSourceCode = vm.readFile(alpacaBalance);
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        rwa.setSourceCode(getBalanceSourceCode);
        console2.log("InteractTokenizedRWA.setParams: s_getBalanceSourceCode=%s", rwa.s_getBalanceSourceCode());
        // rwa.setCallbackGasLimit(3_000_000);
        // console2.log("InteractTokenizedRWA.setParams: s_callbackGasLimit=%s", rwa.s_callbackGasLimit());
        vm.stopBroadcast();
    }

    function sendRequest() public {
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        console2.log("TokenizedRWA.sendQueryPortfolioBalanceRequest...");
        bytes32 requestId = rwa.sendQueryPortfolioBalanceRequest();
        console2.log("TokenizedRWA.s_mostRecentRequestId=", string(abi.encodePacked(requestId)));
        vm.stopBroadcast();
    }
}
