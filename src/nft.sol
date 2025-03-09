pragma solidity ^0.8.26;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract VoteResult is ERC721, Ownable {

    using Strings for uint256;

    struct Result {
        uint256 id;
        string description;
        uint256 yesCount;
        uint256 noCount;
        bool result;
    }

    uint256 private _tokenIdCounter;
    mapping(uint256 => Result) private _tokenInfo;

    constructor(address owner) ERC721("Result", "VTF") Ownable(owner) {}

    function mint(address to, Result memory info) public {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        _tokenInfo[tokenId] = info;
    }

    function getTokenInfo(uint256 tokenId) public view returns (Result memory) {
        return _tokenInfo[tokenId];
    }

    function resultToString(Result memory result) internal pure returns(string memory) {
        return string(abi.encodePacked(
            "id: ", result.id.toString(), " ",
            result.description, " yes count: ", result.yesCount.toString(),
            " no count: ", result.noCount.toString()
        ));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        Result memory results = _tokenInfo[tokenId];
        string memory json = string(abi.encodePacked(
            '{Vote Result #', tokenId.toString(), ', info: ', resultToString(results),' }'
        ));
        return string(abi.encodePacked("data:json;base64,", Base64.encode(bytes(json))));
    }
}