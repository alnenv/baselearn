// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/token/ERC721/ERC721.sol";

contract HaikuNFT is ERC721 {
    // ==== Errors ====
    error HaikuNotUnique();
    error NotYourHaiku(uint256 id);
    error NoHaikusShared();

    // ==== Data model ====
    struct Haiku {
        address author;
        string line1;
        string line2;
        string line3;
    }

    // Public array haikus (index = tokenId)
    Haiku[] public haikus;

    // Alamat yang dibagikan => daftar ID haiku yang dibagikan
    mapping(address => uint256[]) public sharedHaikus;

    // Counter publik; ID 0 tidak dipakai (mulai dari 1)
    uint256 public counter = 1;

    // Cek keunikan baris (global)
    mapping(bytes32 => bool) private _usedLineHash;

    constructor() ERC721("Haiku NFT", "HAIKU") {
        // Placeholder agar haikus[tokenId] sejajar dengan tokenId (mulai 1)
        haikus.push(Haiku(address(0), "", "", ""));
    }

    // ==== Mint Haiku ====
    function mintHaiku(
        string calldata line1,
        string calldata line2,
        string calldata line3
    ) external {
        // Unik per-baris di seluruh koleksi (case-sensitive)
        bytes32 h1 = keccak256(bytes(line1));
        bytes32 h2 = keccak256(bytes(line2));
        bytes32 h3 = keccak256(bytes(line3));
        if (_usedLineHash[h1] || _usedLineHash[h2] || _usedLineHash[h3]) {
            revert HaikuNotUnique();
        }
        _usedLineHash[h1] = true;
        _usedLineHash[h2] = true;
        _usedLineHash[h3] = true;

        // Simpan haiku; tokenId = index baru (karena index 0 placeholder)
        haikus.push(Haiku(msg.sender, line1, line2, line3));
        uint256 tokenId = haikus.length - 1;
        require(tokenId == counter, "counter mismatch");

        // PENTING: gunakan _mint (BUKAN _safeMint) agar tidak revert saat mint ke kontrak penguji
        _mint(msg.sender, tokenId);

        unchecked { counter += 1; }
    }

    // ==== Share Haiku ====
    function shareHaiku(address _to, uint256 _id) public {
        require(_to != address(0), "invalid to");
        if (ownerOf(_id) != msg.sender) revert NotYourHaiku(_id);
        sharedHaikus[_to].push(_id);
    }

    // ==== Get Your Shared Haikus ====
    function getMySharedHaikus() public view returns (Haiku[] memory) {
        uint256[] storage ids = sharedHaikus[msg.sender];
        uint256 n = ids.length;
        if (n == 0) revert NoHaikusShared();

        Haiku[] memory out = new Haiku[](n);
        for (uint256 i = 0; i < n; i++) {
            out[i] = haikus[ids[i]];
        }
        return out;
    }
}
