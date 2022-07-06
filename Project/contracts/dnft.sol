// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

interface vrf {
    function requestRandomWords() external returns (uint256);
    function randomNumber(uint256 requestId) external view returns(uint256);
    function senderAddress() external view returns(address);
}

/*
@title Dynamic NFT contract
@notice NFT is able to change its image by three methods: 1) deterministically rotate 2) randomly change 
3) increase or decrease by a given price feed contract (Ethereum, for example). 
*/
contract dNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // @notice Metadata info for each stage of the NFT on IPFS.
    string[] internal IpfsUri = [
        "ipfs://bafyreifguuazwfh6qhtwcwe3arhuvbi5t7jq43q4ystgzwbs226jsinfoi/metadata.json",
        "ipfs://bafyreiey5dwt6fkecufvm25y4x3ppuwjuit7ngawmp7qia3sa2ldjkduc4/metadata.json",
        "ipfs://bafyreibwiucepwpfe4ewxa7r3b5afvpuevtkskihafhonboeutm32min5a/metadata.json"        
    ];
    
    // @used to keep track of chainlink upkeep
    uint256 internal lastTimeStamp;
    uint256 public keeperTokenID;
    uint256 public interval;
    // @notice requestId for Chainlink VRF
    uint256 public requestId;
    address public vrfGenerator;

    constructor() ERC721("dnft", "dnft") {
        interval = 120;
        lastTimeStamp = block.timestamp;
        requestId = 0;
        vrfGenerator = 0xec267adccDC192De82E6F78f794aA3A6e800B451;
        keeperTokenID = 0;
        safeMint(0xAefe9691A3d2e7E7b13F148Ec6E656B491E30E5F);
    }

    function destroy() public payable onlyOwner {
        address payable s = payable(owner());
        selfdestruct(s);
    } 
    
    // @notice request a random number from Chainlink vrf contract.
    function requestRandom() public {
        requestId = vrf(vrfGenerator).requestRandomWords();
    }

    function randomNumber() public view returns (uint256){
        return vrf(vrfGenerator).randomNumber(requestId);
    }

    function senderAddress() public view returns (address){
        return vrf(vrfGenerator).senderAddress();
    }

    function setVrfContract(address contractAddress) external onlyOwner {
        require( contractAddress != vrfGenerator , "already existing address");
        vrfGenerator = contractAddress;
    }

    // @notice used by Chainlink to see if upkeep needs to be performed
    function checkUpkeep(bytes calldata /*checkData*/) external view 
        returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = bytes("");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            changeStageOne(keeperTokenID);
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function changeKeeperTokenID(uint newID) external {
        require(newID != keeperTokenID, "newID is identical to current keeperTokenID");
        keeperTokenID = newID;
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        string memory uri0 = IpfsUri[0];
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri0);
    }

    function changeInterval(uint256 _interval) public {
        require(_interval != interval, "new interval same as old");
        interval = _interval;
    }

    // @notice change stage randomly. First has to request random number. 
    function changeStageRandom(uint256 tokenID) public {
        require(requestId>0, "Please request random number first");
        uint256 r = randomNumber() % IpfsUri.length;
        requestId = 0;
        _setTokenURI(tokenID, IpfsUri[r]);  
    }

    // @notice increase stage if price increase else decrease
    // use 0x0715A7794a1dc8e42615F059dD6e406A6594651A for eth on Polygon Mumbai
    function changeStagePricefeed(uint256 tokenID, address priceFeedAdd) public returns (int, int, int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAdd);
        (uint80 roundID, int price, , ,) = priceFeed.latestRoundData();
        (, int price1, , uint timeStamp,) = priceFeed.getRoundData(roundID-1);
        require(timeStamp > 0, "Round not complete");
        int r = (price>price1? int(1) : -1);
        int L = int(IpfsUri.length);
        int targetStage = (L + int(getStage(tokenID)) + r) % L; 
        _setTokenURI(tokenID, IpfsUri[uint(targetStage)]);
        return (r, price, price1);
    }

    // @notice increase stage by one
    function changeStageOne(uint256 _tokenId) public {
        uint256 targetStage = (getStage(_tokenId) + 1) % IpfsUri.length;
        string memory newUri = IpfsUri[targetStage];
        _setTokenURI(_tokenId, newUri);
    }

    // @notice find out the current stage by string comparison
    function getStage(uint256 _tokenId) public view returns (uint256) {
        //string memory _url = tokenURI(_tokenId);
        bytes32 tbyte = keccak256(abi.encodePacked(tokenURI(_tokenId)));
        uint256 L = IpfsUri.length;
        for (uint256 i=0; i<L; i++) {
            if (keccak256(abi.encodePacked(IpfsUri[i])) == tbyte) {
                return i;
            }
        }
        return L + 1;
    }

    function thisAddress() public view returns (address) {
        return address(this);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
