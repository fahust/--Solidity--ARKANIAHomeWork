//SPDX-License-Identifier MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract ERC721Arkania is ERC721, Ownable, RoyaltiesV2Impl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    constructor() ERC721("ArkaToken", "ARKTK") {}

    function mint(address _to) public onlyOwner {
        super._mint(_to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
