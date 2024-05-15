// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { TokenizedRWA } from "../src/TokenizedRWA.sol";
import { console2 } from "forge-std/console2.sol";

address constant CONTRACT_ADDRESS = 0x48336990d70fCb7E88a7191b56065A5Ca60ab698;
uint8 constant DON_HOSTED_SECRETS_SLOT_ID = 0;
uint64 constant DON_HOSTED_SECRETS_VERSION = 1715800008;

contract InteractTokenizedRWA is Script {

    function run() external {
        // getBalance();
        // getParams();
        // setParams();
        // sendRequest(DON_HOSTED_SECRETS_SLOT_ID, DON_HOSTED_SECRETS_VERSION);
    }

    function getBalance() public {
        console2.log("InteractTokenizedRWA.getBalance...");
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        console2.log("  s_portfolioBalance=%s", rwa.s_portfolioBalance());
        vm.stopBroadcast();
    }

    function getParams() public {
        console2.log("InteractTokenizedRWA.getParams...");
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        console2.log("  s_balanceSourceCode=%s", rwa.s_balanceSourceCode());
        vm.stopBroadcast();
    }

    function setParams() public {
        console2.log("InteractTokenizedRWA.setParams...");
        string memory alpacaBalance = "./functions/sources/alpacaBalance.js";
        string memory balanceSourceCode = vm.readFile(alpacaBalance);
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        rwa.setSourceCode(balanceSourceCode);
        console2.log("  s_balanceSourceCode=%s", rwa.s_balanceSourceCode());
        rwa.setCallbackGasLimit(3_000_000);
        console2.log("  s_callbackGasLimit=%s", rwa.s_callbackGasLimit());
        vm.stopBroadcast();
    }

    function sendRequest(uint8 donHostedSecretsSlotID, uint64 donHostedSecretsVersion) public {
        console2.log("InteractTokenizedRWA.sendRequest...");
        vm.startBroadcast();
        TokenizedRWA rwa = TokenizedRWA(CONTRACT_ADDRESS);
        bytes32 requestId = rwa.sendQueryPortfolioBalanceRequest(donHostedSecretsSlotID, donHostedSecretsVersion);
        console2.log("  requestId=%s", string(abi.encodePacked(requestId)));
        vm.stopBroadcast();
    }
}
