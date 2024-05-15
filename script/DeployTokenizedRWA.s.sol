// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { Config } from "../src/Config.sol";
import { TokenizedRWA } from "../src/TokenizedRWA.sol";
import { console2 } from "forge-std/console2.sol";


contract DeployTokenizedRWA is Script {
    string constant alpacaBalance = "./functions/sources/alpacaBalance.js";

    function run() external {
        bytes32 donId = hex"66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000";
        uint8 donHostedSecretsSlotID = 0;
        uint64 donHostedSecretsVersion = 1715713702;
        uint64 subscriptionId = 2656;
        address functionsRouter = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
        uint32 callbackGasLimit = 300000;
        string memory getBalanceSourceCode = vm.readFile(alpacaBalance);
        uint256 minWithdrawalAmount = 100e18;

        vm.startBroadcast();
        TokenizedRWA rwa = new TokenizedRWA(
            donId,
            donHostedSecretsSlotID,
            donHostedSecretsVersion,
            subscriptionId,
            functionsRouter,
            callbackGasLimit,
            // getBalanceSourceCode,
            minWithdrawalAmount
        );
        rwa.setSourceCode(getBalanceSourceCode);
        vm.stopBroadcast();
        console2.log("TokenizedRWA deployed at:", address(rwa));
    }
}
