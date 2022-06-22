// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

interface vrf {
    function requestRandomWords() external returns (uint256);
    function randomNumber(uint256 requestId) external view returns(uint256);
    function senderAddress() external view returns(address);
}

contract dNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // Metadata info for each stage of the NFT on IPFS.
    string[] internal IpfsUri = [
        "ipfs://bafyreifguuazwfh6qhtwcwe3arhuvbi5t7jq43q4ystgzwbs226jsinfoi/metadata.json",
        "ipfs://bafyreiey5dwt6fkecufvm25y4x3ppuwjuit7ngawmp7qia3sa2ldjkduc4/metadata.json",
        "ipfs://bafyreibwiucepwpfe4ewxa7r3b5afvpuevtkskihafhonboeutm32min5a/metadata.json"        
    ];

    uint256 internal interval;
    uint256 internal lastTimeStamp;
    uint256 public requestId;
    address public vrfGenerator;

    constructor() ERC721("dnft", "dnft") {
        interval = 120;
        lastTimeStamp = block.timestamp;
        requestId = 0;
        vrfGenerator = 0xec267adccDC192De82E6F78f794aA3A6e800B451;
    }

    function destroy() public payable onlyOwner {
        address payable s = payable(owner());
        selfdestruct(s);
    } 
    
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
        require( contractAddress != vrfGenerator );
        vrfGenerator = contractAddress;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool upkeepNeeded /*, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            growFlower(0);
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        string memory uri0 = IpfsUri[0];
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri0);
    }

    function changeInterval(uint256 _interval) public {
        interval = _interval;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }

    function growRandom(uint256 tokenID) public {
        uint256 r = randomNumber() % IpfsUri.length;
        requestId = 0;
        _setTokenURI(tokenID, IpfsUri[r]);  
    }

    function growFlower(uint256 _tokenId) public {
        uint256 currentStage = flowerStage(_tokenId);
        if(currentStage >= IpfsUri.length){
            _setTokenURI(_tokenId, IpfsUri[0]);           
        } else {
            string memory newUri = IpfsUri[currentStage+1];
            _setTokenURI(_tokenId, newUri);
        }
    }

    // determin the stage of the flower growth
    function flowerStage(uint256 _tokenId) public view returns (uint256) {
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
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function thisAddress() public view returns (address) {
        return address(this);
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