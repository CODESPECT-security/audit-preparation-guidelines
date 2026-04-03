// This file is a documentation template. The function bodies contain
// `// Implementation` stubs intentionally; replace them with your logic.
// These stubs are not production code.

/// @title ITokenVault
/// @notice Interface for the token vault contract
/// @dev Implement this trait in your contract using #[abi(embed_v0)]
#[starknet::interface]
pub trait ITokenVault<TContractState> {
    /// Transfers tokens from the caller to a recipient.
    ///
    /// # Arguments
    /// * `recipient` - The address receiving the tokens
    /// * `amount` - The amount of tokens to transfer (u256)
    ///
    /// # Returns
    /// * `bool` - True if transfer succeeded
    ///
    /// # Panics
    /// * `'Insufficient balance'` - If caller has insufficient balance
    /// * `'Invalid zero address'` - If recipient is the zero address
    fn transfer(ref self: TContractState, recipient: starknet::ContractAddress, amount: u256) -> bool;

    /// Returns the token balance of an account.
    ///
    /// # Arguments
    /// * `account` - The address to query
    ///
    /// # Returns
    /// * `u256` - Token balance of the account
    fn balance_of(self: @TContractState, account: starknet::ContractAddress) -> u256;

    /// Returns the total token supply.
    ///
    /// # Returns
    /// * `u256` - Total supply of tokens
    fn total_supply(self: @TContractState) -> u256;
}

/// Emitted when tokens are transferred between addresses.
///
/// # Fields
/// * `from` - The sender address (zero address on mint)
/// * `to` - The recipient address (zero address on burn)
/// * `value` - The amount transferred
#[derive(Drop, starknet::Event)]
pub struct Transfer {
    #[key]
    pub from: starknet::ContractAddress,
    #[key]
    pub to: starknet::ContractAddress,
    pub value: u256,
}
