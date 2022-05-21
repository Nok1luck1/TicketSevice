//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTTicket is ERC1155,Ownable{
	


	constructor () public {
	}   
	
	
	function mint(address to, uint tokenId, uint amount,bytes32 _saltOfCollection,uint _lifetime) public onlyOwner returns (bool) {
		 _mint(to, tokenId, amount, _lifetime,_saltOfCollection, "");
		
		return true;
	}
	

}

