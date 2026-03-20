// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AuditReadyPatterns
/// @notice Demonstrates the four patterns auditors look for first.
///         A clean implementation of these patterns lets auditors move
///         faster — they spend time on your business logic, not basics.
contract AuditReadyPatterns is ReentrancyGuard, Pausable, Ownable {

    // =========================================================
    // Pattern 1: Checks-Effects-Interactions (CEI)
    //
    // ALWAYS update state before making external calls.
    // This prevents reentrancy even without ReentrancyGuard.
    // Use both: CEI as the pattern, ReentrancyGuard as the backstop.
    // =========================================================

    mapping(address => uint256) public pendingWithdrawals;

    /// @notice Withdraw pending balance using CEI + reentrancy guard
    function withdraw() external nonReentrant whenNotPaused {
        // 1. CHECKS — validate before doing anything
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        // 2. EFFECTS — update state before any external interaction
        pendingWithdrawals[msg.sender] = 0;

        // 3. INTERACTIONS — external call comes last
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    // =========================================================
    // Pattern 2: Pull Over Push
    //
    // Never push funds to addresses. Record pending amounts and let
    // recipients pull them. This prevents griefing via reverting
    // recipients and simplifies reentrancy analysis.
    // =========================================================

    /// @notice Record a pending payment — recipient pulls, protocol does not push
    /// @dev Internal. Call this instead of transferring ETH directly.
    function _recordPayment(address recipient, uint256 amount) internal {
        pendingWithdrawals[recipient] += amount;
        emit PaymentRecorded(recipient, amount);
    }

    // =========================================================
    // Pattern 3: ReentrancyGuard
    //
    // Apply nonReentrant to every function that makes an external call
    // or transfers value. OpenZeppelin's implementation is battle-tested.
    // Do not write your own reentrancy guard.
    // =========================================================
    //
    // Usage: inherit ReentrancyGuard, apply `nonReentrant` modifier.
    // Already shown on `withdraw()` above.

    // =========================================================
    // Pattern 4: Pausable (Emergency Stop)
    //
    // Implement a pause mechanism for emergency response.
    // Auditors check: can the protocol be stopped if a vulnerability
    // is found post-deployment? If not, that is a finding.
    // =========================================================

    /// @notice Pause all protocol operations — callable by owner only
    /// @dev Use in response to discovered vulnerabilities or exploits
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Resume protocol operations after incident resolution
    function unpause() external onlyOwner {
        _unpause();
    }

    // =========================================================
    // Events & Errors
    // =========================================================

    event PaymentRecorded(address indexed recipient, uint256 amount);

    error NothingToWithdraw();
    error TransferFailed();

    constructor() Ownable(msg.sender) {}
}
