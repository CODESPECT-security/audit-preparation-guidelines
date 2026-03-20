//! Account structure examples for audit-ready Solana programs.
//!
//! This file demonstrates:
//! - Account struct definitions with field documentation
//! - PDA derivation with explicit seeds and bump storage
//! - Anchor constraints for ownership, signer, and relationship validation
//! - Checked arithmetic to prevent overflow
//!
//! Auditors spend significant time tracing account ownership and PDA
//! derivation. Clear definitions like these dramatically reduce that time.

use anchor_lang::prelude::*;

// =============================================================================
// Account Structs
// =============================================================================

/// Per-user vault storing deposit state.
///
/// PDA seeds: `["vault", user.key()]`
/// Size: `UserVault::LEN` bytes
/// Lifecycle: created by `initialize_vault`, closed by `close_vault`
#[account]
#[derive(Default)]
pub struct UserVault {
    /// The owner of this vault. Only this address can deposit or withdraw.
    pub owner: Pubkey,      // 32 bytes

    /// Total lamports deposited. Updated on every deposit and withdrawal.
    pub deposited: u64,     // 8 bytes

    /// Bump seed used in PDA derivation. Stored to avoid recomputation.
    pub bump: u8,           // 1 byte
}

impl UserVault {
    /// Total account size: discriminator (8) + owner (32) + deposited (8) + bump (1)
    pub const LEN: usize = 8 + 32 + 8 + 1;
}

// =============================================================================
// Instruction: Initialize Vault
// =============================================================================

/// Create a new UserVault PDA for the signer.
///
/// Access control: any signer can create their own vault.
/// One vault per user; the PDA derivation enforces uniqueness.
#[derive(Accounts)]
pub struct InitializeVault<'info> {
    /// The vault PDA being created.
    /// Seeds enforce one vault per user. Bump is stored in the account.
    #[account(
        init,
        payer = user,
        space = UserVault::LEN, // Anchor uses this to calculate and charge rent-exempt minimum from payer
        seeds = [b"vault", user.key().as_ref()],
        bump,
    )]
    pub vault: Account<'info, UserVault>,

    /// The user paying for account rent and becoming the vault owner.
    #[account(mut)]
    pub user: Signer<'info>,

    pub system_program: Program<'info, System>,
}

// =============================================================================
// Instruction handler: Initialize Vault logic
// =============================================================================

pub fn initialize_vault(ctx: Context<InitializeVault>) -> Result<()> {
    let vault = &mut ctx.accounts.vault;
    vault.owner = ctx.accounts.user.key();
    vault.bump = ctx.bumps.vault;
    // deposited starts at 0 via #[derive(Default)]
    Ok(())
}

// =============================================================================
// Instruction: Deposit
// =============================================================================

/// Deposit lamports into the caller's vault.
///
/// Access control: only the vault owner (matching signer) can deposit.
/// The `constraint` below enforces this; if it fails, the transaction
/// is rejected before any state changes occur.
#[derive(Accounts)]
pub struct Deposit<'info> {
    /// The vault receiving the deposit.
    /// - `seeds` + `bump`: verify this is the correct PDA (not a spoofed account)
    /// - `constraint`: verify the signer owns this vault
    #[account(
        mut,
        seeds = [b"vault", user.key().as_ref()],
        bump = vault.bump,
        constraint = vault.owner == user.key() @ VaultError::Unauthorized,
    )]
    pub vault: Account<'info, UserVault>,

    /// Must be the vault owner. Anchor verifies this account signed the transaction.
    #[account(mut)]
    pub user: Signer<'info>,

    pub system_program: Program<'info, System>,
}

// =============================================================================
// Instruction handler: Deposit logic
// =============================================================================

pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    require!(amount > 0, VaultError::ZeroAmount);

    // Transfer lamports from user to vault via system program CPI
    let cpi_ctx = CpiContext::new(
        ctx.accounts.system_program.to_account_info(),
        anchor_lang::system_program::Transfer {
            from: ctx.accounts.user.to_account_info(),
            to: ctx.accounts.vault.to_account_info(),
        },
    );
    anchor_lang::system_program::transfer(cpi_ctx, amount)?;

    // Checked arithmetic: returns VaultError::Overflow instead of panicking
    ctx.accounts.vault.deposited = ctx
        .accounts
        .vault
        .deposited
        .checked_add(amount)
        .ok_or(VaultError::Overflow)?;

    emit!(DepositMade {
        owner: ctx.accounts.user.key(),
        amount,
        new_balance: ctx.accounts.vault.deposited,
    });

    Ok(())
}

// =============================================================================
// Events
// =============================================================================

#[event]
pub struct DepositMade {
    pub owner: Pubkey,
    pub amount: u64,
    pub new_balance: u64,
}

// =============================================================================
// Errors
// =============================================================================

#[error_code]
pub enum VaultError {
    #[msg("Signer is not the vault owner")]
    Unauthorized,

    #[msg("Deposit or withdrawal amount must be greater than zero")]
    ZeroAmount,

    #[msg("Arithmetic overflow")]
    Overflow,
}
