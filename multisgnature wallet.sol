// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract multiSig {
    address[] public owners;
    uint public numConfirmationsRequired;


    struct Transaction{
        address to;
        uint  value;
        bool executed;
    }
    Transaction[] public transactions;  
    mapping(uint=>mapping(address => bool)) isConfirmed;

    event TransactionSubmitted(uint indexed  transactionId, address sender, address receiver, uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);


    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
         require(_owners.length > 1, "Owners Required Must be greater than 1");
         require(_numConfirmationsRequired> 0 && _numConfirmationsRequired <= _owners.length, "Number of Confirmation are not in syn with number of owners ");

         for(uint i=0; i<_owners.length; i++){
            require(_owners[i]!=address(0), "invalid Owner");//it means it should not contain any empty addresses 
            owners.push(_owners[i]);
         }
         numConfirmationsRequired=_numConfirmationsRequired;
    } 
    
    //submited transaction and paid money to the contact
    function submitTransaction(address _to) public payable {
       require(_to != address(0), "invalid receiver address");
       require(msg.value > 0 , "Transfer amount must be greater than zero");
       uint transactionId = transactions.length;
       transactions.push(Transaction({to:_to, value:msg.value, executed: false}));

       emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }

    function confirmTransaction(uint _transactionId) public {
        require(_transactionId < transactions.length, "Invalid Transaction id");
        require(!isConfirmed[_transactionId][msg.sender], "Transaction is already confirmed by the owner");
        isConfirmed[_transactionId][msg.sender]= true;

        emit TransactionConfirmed( _transactionId);
        if(isTransactionComfirmed(_transactionId)){
            executeTransaction(_transactionId);
        }
    }
 
    //Function to check for confirmation
    function isTransactionComfirmed(uint _transactionId) internal  view returns (bool){
         require(_transactionId < transactions.length, "Invalid Transaction id");

         uint confirmationCount;//initially zero

         for (uint i=0; i<owners.length;i++){
            if(isConfirmed[_transactionId][owners[i]]){
                confirmationCount++;
            }
         }
         return confirmationCount >= numConfirmationsRequired;
    }
     
    //function to execute transaction
    function executeTransaction(uint _transactionId) public  payable {
        require(_transactionId < transactions.length, "Invalid Transaction id");
        require(!transactions[_transactionId].executed, "The trnsaction is already executed");
        (bool success,) = transactions[_transactionId].to.call{value:transactions[_transactionId].value}("");
        require(success, "Transaction execution failed");
        transactions[_transactionId].executed= true;

        emit TransactionExecuted( _transactionId);
    }
}