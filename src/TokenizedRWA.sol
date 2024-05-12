// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenizedRWA is FunctionsClient, ERC20 {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;

    enum MintOrRedeem {
        mint,
        redeem
    }

    struct RWARequest {
        uint256 amountOfToken;
        address requester;
        MintOrRedeem mintOrRedeem;
    }

    error dTSLA__BelowMinimumRedemption();
    error dTSLA__TransferFailed();

    address constant SEPOLIA_FUNCTIONS_ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    uint32 constant CALLBACK_GAS_LIMIT = 300000;
    bytes32 constant DON_ID = hex"66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000";
    address constant SEPOLIA_TSLA_PRICE_FEED = 0xc59E3633BAAC79493d908e63626716e204A45EdF;

    uint256 constant MIN_WITHDRAWAL_AMOUNT = 100e18; // not 100e6 even though USDC has 6 decimals

    uint64 immutable i_subscriptionId;
    string private s_mintSourceCode;
    string private s_redeemSourceCode;

    mapping(bytes32 requestId => RWARequest) private s_requests;
    mapping(address user => uint256 amountToWithdraw) private s_userToWithdrawAmount;

    constructor(uint64 subId, string memory mintSourceCode, string memory redeemSourceCode) FunctionsClient(SEPOLIA_FUNCTIONS_ROUTER) ERC20("dTSLA", "Tokenized Tesla") {
        i_subscriptionId = subId;
        s_mintSourceCode = mintSourceCode;
        s_redeemSourceCode = redeemSourceCode;
    }

    /**
     * Send HTTP request to:
     *  - see how much of the RWA is bought
     *  - if enough RWA is in the alpaca account, mint the RWA
     * @param amount Amount of RWA to mint
     */
    function sendMintRequest(uint256 amount) external returns(bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_mintSourceCode);

        // TODO: send the amount of RWA to mint on the brokerage
        // string[] memory args = new string[](1);
        // args[0] = amount.toString();
        // req.setArgs(args);

        requestId = _sendRequest(
            req.encodeCBOR(),
            i_subscriptionId,
            CALLBACK_GAS_LIMIT,
            DON_ID
        );
        s_requests[requestId] = RWARequest(amount, msg.sender, MintOrRedeem.mint);
    }

    /**
     * Mint the RWA for the user
     * Return the amount of RWA stored in our broker
     * The amount of tokenized RWA is 1-1 with the actual asset held in the broker (no additional collateral needed e.g. overcollateralized)
     */
    function _mintFulfillRequest(bytes32 requestId, bytes memory /*response*/) internal {
        uint256 amountOfTokenToMint = s_requests[requestId].amountOfToken;
        if (amountOfTokenToMint != 0) {
            _mint(s_requests[requestId].requester, amountOfTokenToMint);
        }
    }

    /**
     * User sends a request to sell the RWA for USDC (redemptionToken)
     * This will have the chainlink function call the alpaca (bank) and do the following:
     *  - Sell RWA on the brokerage
     *  - Buy USDC on the brokerage
     *  - Send USDC to this contract for the user to withdraw
     */
    function sendRedeemRequest(uint256 rwaAmount) external returns (bytes32 requestId) {
        // TODO: enforce brokerage min redeem amount (e.g. 20 for USDC)

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_redeemSourceCode);

        string[] memory args = new string[](1);
        args[0] = rwaAmount.toString();
        // args[1] = amountRwaInUsdc.toString(); // how much USDC to send back (TODO: dig the USDC amount on fulfillRequest)
        req.setArgs(args);

        // Send the request and store the request ID
        // assuming requestId is unique
        requestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, CALLBACK_GAS_LIMIT, DON_ID);

        _burn(msg.sender, rwaAmount);
    }

    function _redeemFulfillRequest(bytes32 requestId, bytes memory response) internal {
        // assume for now this has 18 decimals (TODO: handle this security vulnerability)
        uint256 usdcAmount = uint256(bytes32(response));
        // if the brokerage doesn't send any USDC to this contract, then the user gets his tokenized RWA back
        if (usdcAmount == 0) {
            uint256 amountOfRwaBurned = s_requests[requestId].amountOfToken;
            _mint(s_requests[requestId].requester, amountOfRwaBurned);
            return;
        }

        s_userToWithdrawAmount[s_requests[requestId].requester] += usdcAmount;
    }

    function withdraw() external {
        uint256 amountToWithdraw = s_userToWithdrawAmount[msg.sender];
        s_userToWithdrawAmount[msg.sender] = 0;
        bool success = ERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238).transfer(msg.sender, amountToWithdraw); // sepolia USDC
        if (!success) revert dTSLA__TransferFailed();

    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory /*err*/) internal override {
        // called by the functions router
        // TODO: enforce access control
        if (s_requests[requestId].mintOrRedeem == MintOrRedeem.mint) {
            _mintFulfillRequest(requestId, response);
        } else {
            _redeemFulfillRequest(requestId, response);
        }
    }

    function getTslaPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(SEPOLIA_TSLA_PRICE_FEED);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price) * 1e10; // additional fee precision (grrrr USDC)
    }
}
