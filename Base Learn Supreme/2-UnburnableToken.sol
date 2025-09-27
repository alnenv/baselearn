// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
UnburnableToken – minimal, sesuai spes Exercise:

Storage (public):
- balances: jumlah token per alamat
- totalSupply: total suplai tetap (100,000,000)
- totalClaimed: total token yang sudah didistribusikan via claim

Fitur:
- constructor(): set totalSupply = 100_000_000
- claim(): sekali per wallet, +1000 token, increment totalClaimed, 
           revert TokensClaimed jika sudah pernah klaim,
           revert AllTokensClaimed jika habis (totalClaimed + CLAIM_AMOUNT > totalSupply)
- safeTransfer(_to, _amount): transfer dari msg.sender ke _to hanya jika:
    * _to != address(0)
    * _to.balance > 0 (punya Base Sepolia ETH > 0)
  kalau gagal -> revert UnsafeTransfer(_to)

Catatan: Tidak memakai desimal; unit token = uint biasa sesuai materi.
*/

contract UnburnableToken {
    // === Storage yang diminta (public) ===
    mapping(address => uint) public balances;
    uint public totalSupply;
    uint public totalClaimed;

    // Tambahan untuk melacak hak klaim per wallet
    mapping(address => bool) public hasClaimed;

    // === Errors sesuai spes ===
    error TokensClaimed();
    error AllTokensClaimed();
    error UnsafeTransfer(address addr);

    // Konstanta jumlah klaim per wallet
    uint private constant CLAIM_AMOUNT = 1000;

    constructor() {
        totalSupply = 100_000_000;
        // totalClaimed awal = 0; balances awal = 0 untuk semua
    }

    // Siapa pun boleh claim 1000 token sekali saja selama stok masih ada
    function claim() public {
        if (hasClaimed[msg.sender]) revert TokensClaimed();

        // Pastikan stok masih cukup untuk klaim berikutnya
        if (totalClaimed + CLAIM_AMOUNT > totalSupply) revert AllTokensClaimed();

        hasClaimed[msg.sender] = true;
        balances[msg.sender] += CLAIM_AMOUNT;
        totalClaimed += CLAIM_AMOUNT;
    }

    // Transfer yang aman: tujuan bukan zero dan punya saldo ETH > 0
    function safeTransfer(address _to, uint _amount) public {
        if (_to == address(0) || _to.balance == 0) {
            revert UnsafeTransfer(_to);
        }

        // Cek saldo cukup
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        unchecked {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
        }
    }
}
