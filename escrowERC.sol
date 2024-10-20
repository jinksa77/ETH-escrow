pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol";

contract escrow{
    struct Data {
        address sender;
        address recipient;
        uint value;
        uint time;
        bool complete;
    }
    struct Index {
        address sender;
        uint value;
    }
    mapping(address => Data[]) public sending_list;
    mapping(address => Index[]) public recieving_list;
    mapping(uint => Index[]) public time_list;
    address public manager;
    uint public commission;
    IERC20 public token;
    
    constructor(IERC20 Token) public {
        manager = msg.sender;
        commission = 0;
        token = Token;
    }
    function make_contract(address recipient, uint value, uint time) public {
        require(value <= token.allowance(msg.sender,address(this)));
        token.transferFrom(msg.sender,address(this),value);
        Data memory new_data = Data({
            sender: msg.sender,
            recipient: recipient,
            value:  value - value/100,
            time:  time,
            complete: false
        });
        sending_list[msg.sender].push(new_data);
        Index memory new_index = Index({
            sender: msg.sender,
            value:  sending_list[msg.sender].length-1
        });
        recieving_list[recipient].push(new_index);
        time_list[time].push(new_index);
        commission = commission + value/100;
    }
    function confirm_payment(uint contract_number) public {
        Data storage data = sending_list[msg.sender][contract_number];
        
        require(!data.complete);

        token.transfer(data.recipient,data.value);
        data.complete = true;
    }
    function retrieve_commission(address recipient, uint value) public {
        token.transfer(recipient,value);
        commission = commission - value;
    }
    function automatic_sending(uint time) public {
        require(time<block.timestamp);
        for (uint i=0; i<time_list[time].length; i++) {
            Data storage data = sending_list[time_list[time][i].sender][time_list[time][i].value];
            if (!data.complete) {
                token.transfer(data.recipient,data.value);
                data.complete = true;
            }
        }
    }
    function sending_list_length(address sender) public view returns(uint length) {
        return sending_list[sender].length;
    }
    function recieving_list_length(address recipient) public view returns(uint length) {
        return recieving_list[recipient].length;
    }
    function time_list_length(uint time) public view returns(uint length) {
        return time_list[time].length;
    }
}