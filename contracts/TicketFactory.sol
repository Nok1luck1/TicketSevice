//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/NFTTicket.sol";

contract TicketFactory {
using SafeERC20 for IERC20;

struct EventInfo{
    uint countOfTickets;
    uint price;
    uint startSale;
    uint endSale;
    uint nftID;
    uint nftVIPid;
    uint countOfVIP;
    uint priceVIP;
    IERC20 paymentToken;
    address creator;
    string nameEvent;
    bytes32 saltOfEvent;
}
mapping(bytes32 => EventInfo) public EventBySalt;
event NewEvent(bytes32 HashOfEvent,uint DataOfEnding ,string nameEvent,uint countOfTickets,uint TicketPrice);
event BoughtTicket(address  buyer, uint countOfTicket);
event BoughtVIPTicket(address buyer, uint countOfVIPTIcket);
event AddedVIPTicket( bytes32 hashEvent,uint _countOfVIP,uint _nftVIPid);

NFTTicket public nfttoken;
address public owner;
uint public feePerTarget;

constructor (NFTTicket _nfttoken,uint fee){
    nfttoken = _nfttoken;
    feePerTarget = fee;
}

//_duration in second (2592000 is 1 month)
//price with decimals counter;
//set NFt id who does not exists
function createEvent(uint _countOfTickets,uint _duration,uint _price,string calldata _nameEvent,IERC20 _paymentToken, uint _nftID)public returns(bytes32){
    bytes32 _salt = keccak256(abi.encode(_nftID,_countOfTickets,_nameEvent));
    nfttoken.mint(address(this), _nftID, _countOfTickets, _salt, _duration);
    EventInfo storage info = EventBySalt[_salt];
    info.countOfTickets = _countOfTickets;
    info.price = _price;
    info.startSale = block.timestamp;
    info.endSale = block.timestamp + _duration;
    info.nftID =_nftID;
    info.creator = msg.sender;
    info.paymentToken = _paymentToken;
    info.nameEvent = _nameEvent;
    info.saltOfEvent = _salt;
    emit NewEvent(_salt,info.endSale,_nameEvent,_countOfTickets,_price);
    }

function addVIPticketsToEvent(bytes32 hashEvent,uint _countOfVIP,uint _priceVIP ,uint _nftVIPid) public  { 
    EventInfo storage info = EventBySalt[hashEvent];
    require(msg.sender == info.creator);
    info.countOfVIP = _countOfVIP;
    info.priceVIP = _priceVIP;
    info.nftVIPid = _nftVIPid;
    uint timeVIPNFTlife = info.endSale - block.timestamp;
    nfttoken.mint(address(this), _nftVIPid, _countOfVIP, hashEvent, timeVIPNFTlife);
    emit AddedVIPTicket(hashEvent,_countOfVIP,_nftVIPid);
}

function buyTicket(bytes32 hashInfo, uint _countOfTicket) public returns(bool){
    require(_countOfTicket > 0,"cant buy zero ticket");
    EventInfo storage info = EventBySalt[hashInfo];
    //uint balanceOfTicket = NFTTicket.balanceOf(address(this),info.nftID);
    //require(balanceOfTicket > 0 );
    require(info.endSale > block.timestamp,"Too late to buy a ticket");
    uint amountByBuyer = (info.price * _countOfTicket );
    uint ticketCostWithFee = amountByBuyer -(_countOfTicket * feePerTarget);
    info.paymentToken.transferFrom(address(msg.sender),address(this),amountByBuyer);
    info.paymentToken.transfer(info.creator,ticketCostWithFee);
    nfttoken.safeTransferFrom(address(this),address(msg.sender),info.nftID, _countOfTicket,"0x0");
    emit BoughtTicket(msg.sender,_countOfTicket);
    }
function buyVipTicket(bytes32 hashInfo, uint _countOfVipTicket)public returns(uint){
    EventInfo storage info = EventBySalt[hashInfo];
    require(info.countOfVIP > 0,"all vip tickets are bought");
    require(info.endSale > block.timestamp);
    uint amountByBuyer =  (info.priceVIP * _countOfVipTicket );
    uint ticketValueToCreator = amountByBuyer - (_countOfVipTicket * feePerTarget);
    info.paymentToken.transferFrom(address(msg.sender),address(this), amountByBuyer);
    info.paymentToken.transfer(info.creator, ticketValueToCreator); 
    nfttoken.safeTransferFrom(address(this),address(msg.sender),info.nftVIPid,_countOfVipTicket,"0x0");
    info.countOfVIP = info.countOfVIP - _countOfVipTicket;
    emit BoughtVIPTicket(msg.sender,_countOfVipTicket);
}
function costOfVIPTicket(bytes32 hashevent)public view returns(uint){
    EventInfo storage info = EventBySalt[hashevent];
    return info.priceVIP;
    
}
function costOFDefoltTicket(bytes32 hashevent) public view returns(uint){
    EventInfo storage info = EventBySalt[hashevent];
    return info.price;
}
function VIPticketsLeft(bytes32 hashevent) public view returns(uint){
    EventInfo storage info = EventBySalt[hashevent];
    return info.countOfVIP;
}
function defoltTicketLeft(bytes32 hashevent) public view returns(uint){
    EventInfo storage info = EventBySalt[hashevent];
    return info.countOfTickets;
    
}




}


