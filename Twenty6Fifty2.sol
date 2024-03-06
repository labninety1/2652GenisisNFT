// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./EnefteOwnership.sol";
import "./ERC721A.sol";
import "./IFold.sol";
import "./IFoldStaking.sol";
import "./INinety1.sol";

/*
* @title Twenty6Fifty2
* @desc 
* @author lileddie.eth / Enefte Studio
*/
contract Twenty6Fifty2 is ERC721A, EnefteOwnership {

    uint64 public MAX_SUPPLY = 2652;
    uint64 public TOKEN_PRICE = 8.33 ether;
    uint64 public SALE_OPENS = 1685811600;
    uint64 public SALE_CLOSES = 999999999999; 
    uint256 private constant FOLD_TOKEN_PRECISION = 1e18;    
    uint256 public EMISSIONS = 91000 ether;

    INinety1 NINETY_ONE; 
    IFold FOLD;
    IFoldStaking foldStaking;

    mapping(uint => uint) handMultiplier;

    string public BASE_URI = "https://enefte.info/n1/?token_id=";
    
    /**
    * @notice minting process for the main sale
    *
    * @param _numberOfTokens number of tokens to be minted
    */
    function mint(uint64 _numberOfTokens) external payable {
        
        if(block.timestamp < SALE_OPENS || block.timestamp > SALE_CLOSES){
            revert("Sale Closed");
        }
        
        if(totalSupply() + _numberOfTokens > MAX_SUPPLY){
            revert("Not Enough Tokens Left");
        }
        
        if(TOKEN_PRICE * _numberOfTokens > msg.value){
            revert("Not Enough Funds Sent");
        }

        _safeMint(msg.sender, _numberOfTokens);
        FOLD.mint(EMISSIONS*_numberOfTokens);
    }

    function fold(uint _tokenId) external {
        if(ownerOf(_tokenId) != msg.sender){
            revert("Not your token");
        }
        NINETY_ONE.mint(msg.sender);
        FOLD.transfer(address(NINETY_ONE),EMISSIONS);
        _burn(_tokenId);
    }

    // Deposit the staking value of the FLD once the modifier is published after minting.
    // Read owner at time of deposit in case owner changes between mint and multiplier being set
    function setMultiplier(uint _tokenId, uint _tier) external onlyOwner {
        if(_exists(_tokenId)){
            handMultiplier[_tokenId] = _tier;
            uint256 totalEmissions = calculateEmissions(_tokenId,1);
            address to = ownerOf(_tokenId);
            foldStaking.deposit(totalEmissions,to);
        }else{
            revert("Token does not exist to apply modifier to");
        }
    }
    
    function setMultipliers(uint[] calldata _tokenIds, uint _tier) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            handMultiplier[_tokenIds[i]] = _tier;
            uint256 totalEmissions = calculateEmissions(_tokenIds[i],1);
            address to = ownerOf(_tokenIds[i]);
            foldStaking.deposit(totalEmissions,to);
        }
    }

    /**
    * @notice set the timestamp of when the main sale should begin
    *
    * @param _openTime the unix timestamp the sale opens
    * @param _closeTime the unix timestamp the sale closes
    */
    function setSaleTimes(uint64 _openTime, uint64 _closeTime) external onlyOwner {
        SALE_OPENS = _openTime;
        SALE_CLOSES = _closeTime;
    }
    
    /**
    * @notice set the address for the smart contracts
    *
    */
    function setContracts(address _address91, address _addressFold, address _addressStaking) external onlyOwner {
        NINETY_ONE = INinety1(_address91);
        FOLD = IFold(_addressFold);
        foldStaking = IFoldStaking(_addressStaking);
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyOwner {
        BASE_URI = _uri;
    }

    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Avax to Wallet");
    }

    
    function calculateEmissions(uint256 _firstTokenId, uint256 _quantity) internal view returns (uint256 totalEmissions) {
        uint _emissions = 0;
        uint shareEmissions = EMISSIONS/FOLD_TOKEN_PRECISION;
        for(uint i = 0;i < _quantity;i++){
            uint tokenId = _firstTokenId + i;
            uint multiplier = handMultiplier[tokenId];
            _emissions += shareEmissions * multiplier;
        }
        return _emissions;
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        uint256 totalEmissions = calculateEmissions(startTokenId,quantity);
        if(from == address(0)){ //minted
            // Do nothing, trigger initial staking deposit when modifier value is updated shortly after mint.
        }   
        else if(to == address(0)){ //burned
            foldStaking.withdraw(totalEmissions,from);
        }  
        else {  //transferred
            foldStaking.withdraw(totalEmissions,from);
            foldStaking.deposit(totalEmissions,to);
        }  
    }

    /**
    * @notice Start token IDs from this number
    */
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    constructor() ERC721A("Twenty6Fifty2", "2652") {
        setOwner(msg.sender);
    }

}