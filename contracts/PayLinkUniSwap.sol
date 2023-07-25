// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import './libraries/TransferHelper.sol';
import './interface/ISwapRouter.sol';
import './interface/IQuoterV2.sol';
import "./interface/IERC20.sol";
import  "./utils/SafeERC20.sol" ;
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IQuickSwapRouter.sol";
import "./upgrade/utils/UUPSUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./upgrade/utils/Initializable.sol";
import  "./access/AccessControlEnumerableUpgradeable.sol" ;

contract PayLinkUniSwap is Initializable,AccessControlEnumerableUpgradeable, UUPSUpgradeable, OwnableUpgradeable{

        using SafeERC20 for IERC20;
        using AddressUpgradeable for address;
    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    ISwapRouter public  swapRouter;
    IQuoterV2 public  quoterV2;

    // This example swaps DAI/WETH9 for single path swaps and DAI/USDC/WETH9 for multi path swaps.

    // address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address public constant matic = 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0;
    event Swap(uint256  bizId, uint amountIn, uint amountOut, address  to);

    IERC20 public usdtToken;
    IERC20 public maticToken;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;
    uint24 private constant SLIPPAGE = 1000; // 1% slippage

        bytes32 public constant DEFAULT_OP_ROLE = keccak256("DEFAULT_OP_ROLE");
        bytes32 public constant DEFAULT_FINANCIAL_ROLE = keccak256("DEFAULT_FINANCIAL_ROLE");

    function initialize(IERC20 USDT_ADDRESS,IERC20 MATIC_ADDRESS, address QUICKSWAP_ROUTER_ADDRESS,address IQuoterV2_ADDRESS) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        IPaySwap_init_unchained(USDT_ADDRESS,MATIC_ADDRESS,QUICKSWAP_ROUTER_ADDRESS,IQuoterV2_ADDRESS);
    }
    function IPaySwap_init_unchained(IERC20 USDT_ADDRESS,IERC20 MATIC_ADDRESS, address QUICKSWAP_ROUTER_ADDRESS,address IQuoterV2_ADDRESS) internal onlyInitializing() {
        usdtToken = USDT_ADDRESS;
        maticToken = MATIC_ADDRESS;
        swapRouter = ISwapRouter(QUICKSWAP_ROUTER_ADDRESS);
        quoterV2 = IQuoterV2(IQuoterV2_ADDRESS);
        _setRoleAdmin(DEFAULT_OP_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(DEFAULT_FINANCIAL_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

    }


function addOp(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_OP_ROLE, account);
    }
    function addAmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }
    function addFinancial(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_FINANCIAL_ROLE, account);
    }

    function removeOp(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_OP_ROLE, account);
    }

      function removeAmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }
    function removeFinancial(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_FINANCIAL_ROLE, account);
    }
       function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}



    function inputCanExactOutput(uint256 amountIn) external  view returns (uint256 amountOut,uint256 fee) {

         bytes memory callResult =address(quoterV2).functionStaticCall(abi.encodeWithSelector(IQuoterV2.quoteExactInputSingle.selector,
            IQuoterV2.QuoteExactInputSingleParams({
                tokenIn: address(usdtToken),
                tokenOut: address(maticToken),
                fee: poolFee,
                amountIn: amountIn,
                sqrtPriceLimitX96:   2 ** 48
            })
        ));

        (amountOut,,, fee) = abi.decode(callResult, (uint256,uint160,uint32, uint256));
        // If the returned amountIn is less than the limit, then the input can exact the output
    }

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingle(address receiver,uint256 amountIn,uint256 bizId,uint256 amountOutMinimum)  external onlyRole(DEFAULT_OP_ROLE) returns (uint256 amountOut) {
        // msg.sender must approve this contract
        require(usdtToken.balanceOf(address(this)) >= amountIn, "Not enough USDT balance");

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(address(usdtToken), address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(usdtToken),
                tokenOut: address(maticToken),
                fee: poolFee,
                recipient: receiver,
                deadline: block.timestamp +300,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96:  2**96
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        emit Swap(bizId, amountIn, amountOut, receiver);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of DAI for a fixed amount of WETH.
    /// @dev The calling address must approve this contract to spend its DAI for this function to succeed. As the amount of input DAI is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of WETH9 to receive from the swap.
    /// @param amountInMaximum The amount of DAI we are willing to spend to receive the specified amount of WETH9.
    /// @return amountIn The amount of DAI actually spent in the swap.
    function swapExactOutputSingle(address receiver,uint256 amountOut, uint256 amountInMaximum,uint256 bizId) external onlyRole(DEFAULT_OP_ROLE) returns (uint256 amountIn)  {

       require(usdtToken.balanceOf(address(this)) >= amountInMaximum, "Not enough USDT balance");

        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(address(usdtToken), address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(usdtToken),
                tokenOut: address(maticToken),
                fee: poolFee,
                recipient: receiver,
                deadline: block.timestamp + 300,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96:  2**96
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(address(usdtToken), address(swapRouter), 0);
        }
        emit Swap(bizId, amountIn, amountOut, receiver);
    }

         function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal override {
        super._setRoleAdmin(role, adminRole);
       }



    function withdraw(uint amount, address payAddress, IERC20 token) external  onlyRole(DEFAULT_FINANCIAL_ROLE) {
        require(amount >0, "amount too low");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Not enough token balance");
        token.transfer(payAddress, amount);
    }
        receive() payable external{
          require(msg.value <= 1, "amount too high");
       }
       fallback() external{

       }
}