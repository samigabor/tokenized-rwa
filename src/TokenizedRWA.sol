// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract TokenizedRWA is FunctionsClient, ERC20 {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;

    /// Chainlink API
    bytes32 public s_donId;
    uint8 public s_donHostedSecretsSlotID; // slotIdNumber
    uint64 public s_donHostedSecretsVersion;
    // bytes encryptedSecretsUrls; // not needed since we're using one of the public gateways
    uint64 public s_subscriptionId;
    address public s_functionsRouter;
    uint32 public s_callbackGasLimit;
    mapping(string ticker => address priceFeed) s_priceFeed;

    /// Brokerage API
    string public s_getBalanceSourceCode;
    uint256 public s_minWithdrawalAmount;

    uint256 public s_portfolioBalance;
    bytes32 public s_mostRecentRequestId;

    constructor(
        bytes32 donId,
        uint8 donHostedSecretsSlotID,
        uint64 donHostedSecretsVersion,
        uint64 subscriptionId,
        address functionsRouter,
        uint32 callbackGasLimit,
        // string memory getBalanceSourceCode,
        uint256 minWithdrawalAmount
    ) FunctionsClient(functionsRouter) ERC20("dTSLA", "Tokenized Tesla") {
        s_donId = donId;
        s_donHostedSecretsSlotID = donHostedSecretsSlotID;
        s_donHostedSecretsVersion = donHostedSecretsVersion;
        s_subscriptionId = subscriptionId;
        s_functionsRouter = functionsRouter;
        s_callbackGasLimit = callbackGasLimit;
        // s_getBalanceSourceCode = getBalanceSourceCode;
        s_minWithdrawalAmount = minWithdrawalAmount;
    }

    /**
     * Send HTTP request to query the Brockerage portfolio balance
     */
    function sendQueryPortfolioBalanceRequest() external returns(bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_getBalanceSourceCode);
        req.addDONHostedSecrets(s_donHostedSecretsSlotID, s_donHostedSecretsVersion);

        requestId = _sendRequest(
            req.encodeCBOR(),
            s_subscriptionId,
            s_callbackGasLimit,
            s_donId
        );
        s_mostRecentRequestId = requestId;
    }

    function fulfillRequest(bytes32 /*requestId*/, bytes memory response, bytes memory /*err*/) internal override {
        s_portfolioBalance = uint256(bytes32(response));
        // removed additional logic for now due to functions gas restriction
    }


    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setDonId(bytes32 donId) external /*onlyOwner*/ {
        s_donId = donId;
    }

    function setDonSecrets(uint8 slotId, uint64 version) external /*onlyOwner*/ {
        s_donHostedSecretsSlotID = slotId;
        s_donHostedSecretsVersion = version;
    }

    function setSubscriptionId(uint64 subId) external /*onlyOwner*/ {
        s_subscriptionId = subId;
    }

    function setFunctionsRouter(address newRouter) external /*onlyOwner*/ {
        s_functionsRouter = newRouter;
    }

    function setCallbackGasLimit(uint32 gasLimit) external /*onlyOwner*/ {
        s_callbackGasLimit = gasLimit;
    }

    function setPriceFeed(string memory ticker, address priceFeed) external /*onlyOwner*/ {
        s_priceFeed[ticker] = priceFeed;
    }

    function setSourceCode(string memory balanceSourceCode) external /*onlyOwner*/ {
        s_getBalanceSourceCode = balanceSourceCode;
    }

    function setMinWithdrawalAmount(uint256 amount) external /*onlyOwner*/ {
        s_minWithdrawalAmount = amount;
    }
}
