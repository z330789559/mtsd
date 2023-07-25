// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./interface/IERC20.sol";

import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Pair.sol";
import "./interface/IUniswapV2Router02.sol";
import "./utils/SafeERC20.sol";
import "./upgrade/utils/UUPSUpgradeable.sol";
import "./access/OwnableUpgradeable.sol";
import "./upgrade/utils/Initializable.sol";
import "./access/AccessControlEnumerableUpgradeable.sol";

contract IPaySwap is
    Initializable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;


    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant MATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    IUniswapV2Router02 public constant ROUTER = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    bytes32 public constant DEFAULT_OP_ROLE = keccak256("DEFAULT_OP_ROLE");
    bytes32 public constant DEFAULT_FINANCIAL_ROLE =
        keccak256("DEFAULT_FINANCIAL_ROLE");


    event PaySwap(
        address receiver,
        uint256 amountIn,
        uint256 amountOut,
        address token,
        string  txId
    );

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        IPaySwap_init_unchained();
    }

    function IPaySwap_init_unchained() internal onlyInitializing {
        _setRoleAdmin(DEFAULT_OP_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(DEFAULT_FINANCIAL_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_OP_ROLE, _msgSender());
        _grantRole(DEFAULT_FINANCIAL_ROLE, _msgSender());
    }

    function addOp(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_OP_ROLE, account);
    }

    function addAmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addFinancial(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_FINANCIAL_ROLE, account);
    }

    function removeOp(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_OP_ROLE, account);
    }

    function removeAmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeFinancial(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_FINANCIAL_ROLE, account);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function withdraw(
        address token,
        uint256 amount
    ) external onlyRole(DEFAULT_FINANCIAL_ROLE) {
        IERC20(token).safeTransfer(_msgSender(), amount);
    }

    function withdrawNative(
        uint256 amount
    ) external onlyRole(DEFAULT_FINANCIAL_ROLE) {
        payable(_msgSender()).transfer(amount);
    }

    function buyMATICWithUSDT(
        address recipient,
        uint256 usdtAmount,
        uint256 minMaticAmount,
        string calldata txId
    ) external onlyRole(DEFAULT_OP_ROLE) {
        // First, the user must approve the contract to spend their USDT

        require(
            IERC20(USDT).balanceOf(address(this)) >= usdtAmount,
            "Not enough USDT balance"
        );

        // We'll use the QuickSwap router to make the swap
        address[] memory path = new address[](4);
        path[0] = USDT;
        path[1] = DAI;
        path[2] = QUICK;
        path[3] = MATIC;

        // Get the expected MATIC amount for the given USDT amount
        uint256[] memory amountsOut = ROUTER.getAmountsIn(usdtAmount, path);
        require(amountsOut[1] >= minMaticAmount, "Slippage too high");

        // Transfer the user's USDT to the contract
        // usdtToken.safeTransfer(recipient, usdtAmount);

        // Swap the USDT for MATIC using the QuickSwap router
        uint256  fee= usdtAmount * 3 / 1000;
        require(
            IERC20(USDT).approve(address(ROUTER), usdtAmount + fee),
            "USDT approve failed"
        );
       uint256[] memory amountOuts= ROUTER.swapExactTokensForETH(
            usdtAmount,
            minMaticAmount,
            path,
            recipient,
            block.timestamp + 10 minutes
        );


        // Transfer any remaining USDT back to the user
        uint256 buyMatic =  address(recipient).balance;
        if (buyMatic < minMaticAmount) {
            revert("buyMatic < minMaticAmount");
        }
        emit PaySwap(recipient, usdtAmount, amountOuts[amountOuts.length - 1],address(0), txId);
    }
    

    function buyErc20WithUSDT(
        address recipient,
        uint256 usdtAmount,
        uint256 minMaticAmount,
        address token,
        address[] memory path,
        string calldata txId
    ) external onlyRole(DEFAULT_OP_ROLE) {
        // First, the user must approve the contract to spend their USDT
          require(token!=address(0),"token is zero");
            require(
                IERC20(USDT).balanceOf(address(this)) >= usdtAmount,
                "Not enough USDT balance"
            );

        // Get the expected MATIC amount for the given USDT amount
        uint256[] memory amountsOut = ROUTER.getAmountsIn(usdtAmount, path);
        require(amountsOut[1] >= minMaticAmount, "Slippage too high");

        // Transfer the user's USDT to the contract
        // usdtToken.safeTransfer(recipient, usdtAmount);

        // Swap the USDT for MATIC using the QuickSwap router
        uint256  fee= usdtAmount * 3 / 1000;
        require(
            IERC20(USDT).approve(address(ROUTER), usdtAmount + fee),
            "USDT approve failed"
        );
       uint256[] memory amountOuts= ROUTER.swapExactTokensForTokens(
            usdtAmount,
            minMaticAmount,
            path,
            recipient,
            block.timestamp + 10 minutes
        );


        // Transfer any remaining USDT back to the user
        uint256 buyToken =  IERC20(token).balanceOf(recipient);
        if (buyToken < minMaticAmount) {
            revert("buyMatic < minMaticAmount");
        }
        emit PaySwap(recipient, usdtAmount, amountOuts[amountOuts.length - 1],token, txId);
    }

    function canExchangeAmount(
        uint256 usdtAmount,
        address token
    ) external view returns (uint256) {
        // We'll use the QuickSwap router to make the swap
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = token;

        // Get the expected MATIC amount for the given USDT amount
        uint256[] memory amountsOut = ROUTER.getAmountsOut(usdtAmount, path);
        return amountsOut[1];
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal override {
        super._setRoleAdmin(role, adminRole);
    }

    receive() external payable {
        require(msg.value <= 1, "amount too high");
    }

    fallback() external {}
}
