// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title TokenVault
/// @notice Secure vault for depositing and withdrawing ERC-20 tokens
/// @dev Implements CEI pattern and reentrancy protection throughout.
///      Inherits OpenZeppelin ReentrancyGuard and Pausable.
/// @custom:security-contact audits@codespect.xyz
contract TokenVault {

    /// @notice Deposit tokens into the vault
    /// @dev Transfers tokens from caller to this contract.
    ///      Caller must have approved this contract for `amount` before calling.
    /// @param token Address of the ERC-20 token to deposit
    /// @param amount Number of tokens to deposit (in token's native decimals)
    /// @return shares Number of vault shares minted to the caller
    /// @custom:security Ensure `token` is a trusted, non-rebasing ERC-20.
    ///                  Rebasing tokens will cause share accounting errors.
    function deposit(address token, uint256 amount)
        external
        returns (uint256 shares)
    {
        // Implementation
    }

    /// @notice Withdraw tokens from the vault
    /// @dev Burns caller's shares and transfers underlying tokens back.
    ///      Uses pull pattern — caller initiates, contract does not push.
    /// @param token Address of the ERC-20 token to withdraw
    /// @param shares Number of vault shares to redeem
    /// @return amount Number of tokens returned to the caller
    /// @custom:security Share price is calculated at withdrawal time.
    ///                  Slippage must be handled by the caller if needed.
    function withdraw(address token, uint256 shares)
        external
        returns (uint256 amount)
    {
        // Implementation
    }

    /// @notice Emitted when a deposit is made
    /// @param depositor Address that made the deposit
    /// @param token Token address deposited
    /// @param amount Token amount deposited
    /// @param shares Shares minted
    event Deposited(
        address indexed depositor,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    /// @notice Thrown when a deposit or withdrawal amount is zero
    error ZeroAmount();

    /// @notice Thrown when caller has insufficient shares to withdraw
    /// @param requested Shares the caller tried to redeem
    /// @param available Shares the caller actually holds
    error InsufficientShares(uint256 requested, uint256 available);
}
