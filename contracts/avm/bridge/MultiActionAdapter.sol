// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

/// @dev This adapter smart contract performs a role of a receiver of the outcome
///      of the cross-chain swap and immediately supplies it to the MultiAction
///      contract.
/// @dev To make this happen:
///      1. Deploy this contract specifying necessary contracts addresses
///      2. Construct the cross-chain swap using these guides:
///         https://docs.debridge.finance/deswap/api-quick-start-guide
///         https://deswap.debridge.finance/v1.0/
///      3. Specify MultiActionAdapter's address to the
///         `dstChainTokenOutRecipient` parameter (this is counter-intuitive)
///      4. Encode a call to `MultiActionAdapter.operateAddAndBuy()` method
///         specifying its args as it was intended to be called by the user,
///         and put MultiActionAdapter's address along with this calldata
///         (separated with a comma) to the `dstChainTxBundle` parameter,
///         as follows:
///         0x00000000MultiActionAdapter,0xEncodedCallToOperateAddAndBuyMethod
/// @dev After you execute the cross-chain transaction taken from the deSwap API,
///      deBridge gate will first execute the transaction to swap assets, putting
///      the outcome to this contract address, and then call the second transaction
///      that will execute the operateAddAndBuy() method. In case any of this
///      transaction fails, the whole transaction fails as well sending the
///      intermediary tokens to the fallback address.
/// @notice https://docs.debridge.finance/deswap/transaction-bundling#deploying-the-operator-smart-contract
contract MultiActionAdapter {
    IERC20 public dai;
    IMultiAction public multiActionContract;
    IDebridgeGate public deBridgeGateContract;

    /// @dev ensure method is called by the deBridge gate
    modifier onlyDeBridgeGate() {
        require(deBridgeGateContract.callProxy() == msg.sender);

        _;
    }

    constructor(address _dai, address _multiActionContractAddress, address _deBridgeGate) {
        dai = IERC20(_dai);
        multiActionContract = IMultiAction(_multiActionContractAddress);
        deBridgeGateContract = IDebridgeGate(_deBridgeGate);
    }

    /// @notice Mind that operateAddAndBuy() has almost the same set of args
    ///         as IMultiAction.addAndBuy(). The only difference is the missing
    ///         `amount` arg - we assume it equals the outcome of a swap
    function operateAddAndBuy(string calldata tokenName, uint marketID, uint lockDuration, address recipient) external onlyDeBridgeGate {
        uint amount = dai.balanceOf(address(this));

        require(dai.approve(address(multiActionContract), amount), "approve");

        multiActionContract.addAndBuy(tokenName, marketID, amount, lockDuration, recipient);

        require(dai.approve(address(multiActionContract), 0), "revoke-approve");

        // necessary to check if multiActionContract has pulled the approved tokens completely!
        uint balanceAfter = dai.balanceOf(address(this));

        // If we revert this call then the whole txn bundle will be reverted.
        // require(balanceAfter == 0, "");

        // Or, we can gracefully handle this case and send dai to the fallback address
        // (bc why not? swap has succeeded, let the user receive dai)
        if (balanceAfter > 0) {
            dai.transfer(recipient, balanceAfter);
        }
    }
}

interface IDebridgeGate {
    function callProxy() external returns (address);
}

interface IMultiAction {
    function addAndBuy(string calldata tokenName, uint marketID, uint amount, uint lockDuration, address recipient) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
