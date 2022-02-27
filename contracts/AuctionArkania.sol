pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ArkaniaToken.sol';

contract AuctionContract is Ownable {


    struct RoyaltiesAddresses {
        address addressRoyalties;
        bool valid;
    }

    struct Bidder {
        address addressBidder;
        uint256 bid;
    }
    
    event Bidders(address indexed addressBidder, uint256 bid);

    mapping( uint8 => RoyaltiesAddresses ) private _addressRoyalties;
    mapping( uint256 => Bidder ) private _bidders;
    mapping( string => uint ) paramsContract;//Allows great scalability, you can add or remove as many variables as you want
    address addressContractToken;
    address lastBidder;
    uint256 countBidder;
    uint8 countAddressRoyalties;
    bool endedAndTransfered;


    constructor(address _addressContract) {
        addressContractToken = _addressContract;
        paramsContract["bid"] = 100000000000000000;//set minimum price
        paramsContract["startAuction"] = 0;//start auction date
        //transferOwnership(_sender);//Change Owner contract
        /**
        Create two addresses to collect royalties
         */
        setRoyaltiesAdress(0x0cE1A376d6CC69a6F74f27E7B1D65171fcB69C80);
        setRoyaltiesAdress(0xb02D6e4A6aae738C02651739c27Fb2AE0Fc92b14);
    }

    /**
    Create addresses to which to send royalties and the percentages they will receive
     */
    function setRoyaltiesAdress(address _address) internal{
        _addressRoyalties[countAddressRoyalties] = RoyaltiesAddresses(_address,true);
        countAddressRoyalties++;
    }

    /**
    Remove addresses to which to send royalties and the percentages they will receive
     */
    function removeRoyaltiesAdress(address _address) external {
        for (uint8 iRoyalties = 0; iRoyalties <= countAddressRoyalties; iRoyalties++) {
            if(_addressRoyalties[iRoyalties].addressRoyalties == _address){
                _addressRoyalties[iRoyalties].valid = false;
                countAddressRoyalties--;
            }
        }
    }

    /**
    Update address of token
     */
    function setAddressContract(address _addressContract) external onlyOwner {
        addressContractToken = _addressContract;
    }

    /**
    Update dynamic array of params of this contract
     */
    function setParamsContract(string memory keyParams, uint valueParams) external onlyOwner {
        paramsContract[keyParams] = valueParams;
    }

    /**
    Get value of one element of array parameter of contract  
    */
    function getParamsContract(string memory keyParams) external view returns (uint256){
        return paramsContract[keyParams];
    }

    /**
    We add a small random parameter for fun
    And we leave 9 place in a dynamic array if needed to add variables
    */
    function randomParams8() internal virtual returns (uint8[] memory) {
        uint8[] memory randomParts = new uint8[](10);
        randomParts[0] = random(4);//color
        return randomParts;
    }

    /**
    We add created_at and price buy in auction
    And we leave 9 place in a dynamic array if needed to add variables
     */
    function randomParams256() internal virtual returns (uint256[] memory) {
        uint256[] memory randomParams = new uint256[](10);
        randomParams[0] = block.timestamp;//created_at
        return randomParams;
    }

    function mintDelegate() payable external {
        uint8[] memory randomParts = randomParams8();
        uint256[] memory randomParams = randomParams256();

        TokenArkania contrat = TokenArkania(addressContractToken);
        contrat.mint(msg.sender, randomParts, randomParams);
    }

    /**
    retrieve all id tokens of a specific user in a table
     */
    function getAllTokensForUser(address user) external view returns (uint256[] memory){
        TokenArkania contrat = TokenArkania(addressContractToken);
        return contrat.getAllTokensForUser(user);
    }

    /**
    Recover the details of a token by passing its id
     */
    function getTokenDetails(uint256 tokenId) external view returns (TokenArkania.Token memory){
        TokenArkania contrat = TokenArkania(addressContractToken);
        return contrat.getTokenDetails(tokenId);
    }

    /**
    Bid for the collection
    Verify that the bidder has sent more ETH than the initial and the last auction
    Check that the auction has started and is not yet finished
     */
    function bidding() payable external {
        require(msg.value>paramsContract["bid"],"Require more ETH for bidding");
        require(paramsContract["startAuction"]!=0,"Auction not started");
        require(block.timestamp<(paramsContract["startAuction"]+10 minutes),"Auction is finished");
        paramsContract["bid"] = msg.value;
        _bidders[countBidder] = Bidder(msg.sender,msg.value);
        lastBidder = msg.sender;
        emit Bidders(msg.sender,msg.value);
        countBidder++;
    }
    
    function getAllBidders() external view returns (uint256[] memory){
        uint[] memory result = new uint256[](countBidder);
        uint256 resultIndex = 0;
        uint256 i;
        for(i = 0; i < countBidder; i++){
            result[resultIndex] = i;
            resultIndex++;
        }
        return result;
    }

    function getBidderDetails(uint256 bidderId) external view returns (Bidder memory){
        return _bidders[bidderId];
    }

    /**
    should be only owner, but louis must be able to use it
     */
    function startAuction() external {
        paramsContract["startAuction"] = block.timestamp;
    }

    /**
    We refund all those who are not the last to bid
    We send the collection to the winner of the auction
    And we send royalties percent at address setted
    should be only owner, but louis must be able to use it
     */
    function endAuction() external{
        require(block.timestamp>=(paramsContract["startAuction"]+10 minutes),"Auction is finished");
        require(endedAndTransfered==false,"collection selled");
        TokenArkania contrat = TokenArkania(addressContractToken);
        for(uint256 i = 0; i <= countBidder; i++){
            if(lastBidder == _bidders[i].addressBidder){
                for (uint256 iToken = 0; iToken < 10; iToken++) {
                    contrat.transfer(contrat.getOwnerOf(iToken), _bidders[i].addressBidder, iToken);
                }
            }else{
                payable(_bidders[i].addressBidder).transfer(_bidders[i].bid);
            }
        }
        endedAndTransfered = true;
        payRoyalties();
    }

    /**
    Pay royalties
    */
    function payRoyalties() internal {
        uint256 percent = address(this).balance/countAddressRoyalties;
        for (uint8 iRoyalties = 0; iRoyalties <= countAddressRoyalties; iRoyalties++) {
            if(_addressRoyalties[iRoyalties].valid == true){
                payable(_addressRoyalties[iRoyalties].addressRoyalties).transfer(percent);
            }
        }
    }

    /**
    Very heavy function, but useful to create random values on the token mint
     */
    function random(uint8 maxNumber) internal returns (uint8) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, paramsContract["nonce"]))) % maxNumber;
        paramsContract["nonce"]++;
        return uint8(randomnumber);
    }

    /**
    Handling of funds, just in case
    should be only owner, but louis must be able to use it
     */
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function deposit(uint256 amount) payable external {
        require(msg.value == amount);
    }

}

