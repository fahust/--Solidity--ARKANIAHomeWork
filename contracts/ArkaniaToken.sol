pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './AuctionArkania.sol';

contract TokenArkania is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    /*
    Object of Token
    With two array of parameter uint8 / uint256
     */
    struct Token {
        uint8[] params8;
        uint256[] params256;
    }

    mapping( string => uint ) paramsContract;
    mapping( uint256 => Token ) private _tokenDetails;
    string public baseURI;
    string public baseExtension = ".json";
    bool public paused = false;
    address adressDelegateContract;

    constructor(string memory name, string memory symbol, string memory _initBaseURI) ERC721(name, symbol){
        setBaseURI(_initBaseURI);
        /**
        No need to create here the auction contract from the token contract, but since it seemed to interest louis I did it
        And it also allowed to save some time for the tests
         */
        AuctionContract instanceAuctionContract = new AuctionContract(address(this));
        adressDelegateContract = address(instanceAuctionContract);
        
        /**
        And we mint 10 tokens
         */
        uint8[] memory params8 = new uint8[](10);
        uint256[] memory params256 = new uint256[](10);
        params256[0] = block.timestamp;//created_at
        for (uint8 index = 0; index < 10; index++) {
            _tokenDetails[_tokenIdTracker.current()] = Token(params8,params256);
            _safeMint(msg.sender, _tokenIdTracker.current());
            approve(adressDelegateContract, _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    /**
    All functions using this modifier can only be called by the delegation contract
     */
    modifier byDelegate() {
        require((msg.sender == adressDelegateContract || adressDelegateContract == address(0))&& !paused,"Not good address delegate contract");
        _;
    }

    /**
    Temporarily lock the contract
     */
    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    /**
    Mint a token with parameter send in function argument 
     */
    function mint(address sender, uint8[] memory params8, uint256[] memory params256) external byDelegate {
        _tokenDetails[_tokenIdTracker.current()] = Token(params8,params256);
        _safeMint(sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
    Safe transfer one token to another address
     */
    function transfer(address from, address to ,uint256 tokenId) external byDelegate {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
    Set array of contract's parameter dynamicaly, possibility of add an infinite of parameters
     */
    function setParamsContract(string memory keyParams, uint valueParams) external onlyOwner {
        paramsContract[keyParams] = valueParams;
    }

    /**
    Get value of one element of array parameter of contract
     */
    function getParamsContract(string memory keyParams) external view returns (uint){
        return paramsContract[keyParams];
    }

    /**
    Update the only address that will be able to call on the token contract 
    */
    function setAdressDelegateContract(address _adress) external onlyOwner {
        adressDelegateContract = _adress;
    }

    function getAdressDelegateContract() external view returns (address){
        return adressDelegateContract;
    }

    function getTokenDetails(uint256 tokenId) external view returns (Token memory){
        return _tokenDetails[tokenId];
    }

    /**
    Return array of all token of one user
     */
    function getAllTokensForUser(address user) external view returns (uint256[] memory){
        uint256 tokenCount = balanceOf(user);
        if(tokenCount == 0){
            return new uint256[](0);
        }
        else{
            uint[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 i;
            for(i = 0; i < _tokenIdTracker.current(); i++){
                if(ownerOf(i) == user){
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /**
    update the values of the token structure dynamicaly
    */
    function updateToken(Token memory _token,uint256 tokenId,address owner) external byDelegate {
        require(ownerOf(tokenId) == owner,"Not Your token");
        _tokenDetails[tokenId] = _token;
    }
    
    /**
    Burn a token (Useless for this project, but it's always good to have one)
     */
    function burn(uint256 tokenId) external byDelegate {
        _burn(tokenId);
    }

}
