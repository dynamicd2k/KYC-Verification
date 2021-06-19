pragma solidity ^0.5.9;


contract KYC{
    
    address admin;  
    
    /*Struct for a customer*/
    struct Customer{
    
    string  userName;           //unique
    string data_hash;  //unique
    uint256 upvotes;
    address bank;
    uint256 customerRating;
    string password;//given by other banks to customer
}

     /*Struct for a customer*/
    struct FinalCustomer{
    
    string  userName;           //unique
    string data_hash;  //unique
    string password;//given by other banks to customer
}

    /*Struct for bank*/
    struct Bank{
    
    string bank_name;
    address ethAddress;   //unique
    string regNumber;        //unique
    uint256 bankRating;      //rating recei
    uint256 KycCount;       //number of KYC requests initiated by the bank/organisation
    uint256 bankUpvotes;
    address validatorBank;
    
}

    /* struct for KYC request*/
    struct KYCRequest{
        
    string userName;
    string data_hash;       //unique
    address bank;
    bool isAllowed;         //used to specify if the request is added by a trusted bank or not
}

    event RequestDenied(address bank );
/* Mapping customer username to Customer struct and keeping an array of all keys of the mapping to loop thru' when required.*/

mapping(string => Customer) public customers;
string[] customerNames;

/* Mapping customer username to Final Customer struct and keeping an array of all keys of the mapping to loop thru'*/ 
mapping(string => FinalCustomer) public finalcustomers;
string[] final_customerList;

/* Mapping bank's address to the bank struct and also keeping an array of all keys of the mapping.*/

mapping(address => Bank) public banks;
address[] bankAddresses;

/* Mapping a customers data hash to the KYC request captured for that customer and keeps a track of every KYCrequest initiated for a customer by a bank*/

mapping(string => KYCRequest) public KycRequests;
string[] customerDataList;



/* Mapping a customer's username with a bank's address, used to keep a track of every upvote given by a bank to a customer*/

mapping(string => mapping(address => uint256)) public upVotes;

 /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
     constructor () public{
         admin=msg.sender;      //initialize admin as the initiator of the contract
     }
     
/**
     * Add Bank can be done only by the admin 
     * @param {string} _bankName Name of the customer to be added
     * @param {address} _bankAddress Address of teh bank to be added
     * @param {string} _regNo Registration number of the bank
     */
function addBank(string memory _bankName, address _bankAddress, string memory _regNo) public returns (uint8){
        require(admin==msg.sender, 'The calling user is not an admin');
       
        banks[_bankAddress].bank_name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNo;
        banks[_bankAddress].validatorBank = msg.sender;
        bankAddresses.push(_bankAddress);
       
        return 1;
    }
    

/**
     * Add a new customer
     * @param {string} _userName Name of the customer to be added
     * @param {string} _hash Hash of the customer's ID submitted for KYC
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */

function addCustomer(string memory _userName, string memory _customerData) public returns (uint8){
    for(uint j=0;j<customerNames.length;j++){
        if(stringEquals(customers[customerNames[j]].userName , _userName)){
            return 0;
        }
    }
    customers[_userName].userName=_userName;
    customers[_userName].data_hash =_customerData; 
    customers[_userName].bank = msg.sender;
    customerNames.push(_userName);
// }
    // }
    return 1;
}

/**
     * Record a new KYC request on behalf of a customer
     * The sender of message call is the bank itself
     * @param  {string} _userName The name of the customer for whom KYC is to be done
     * @param  {address} _bankEthAddress The ethAddress of the bank issuing this request
     * @return {bool}        True if this function execution was successful
     */
     
function addKycRequest(string memory _userName, string memory _customerData) public returns (bool) {
    //require(KycRequests[_customerData].bank == address(0), 'This user already has a KYC request with same data in process.');
    for(uint i=0;i<customerDataList.length;i++){
        if(stringEquals(customers[customerDataList[i]].userName , _userName)){
            emit RequestDenied(msg.sender);
            return false;
        }
    }
    KycRequests[_customerData].userName = _userName;
    KycRequests[_customerData].data_hash = _customerData;
    KycRequests[_customerData].bank = msg.sender;
   if(banks[msg.sender].bankRating >= 50){
        KycRequests[_customerData].isAllowed=true;
   }
    customerDataList.push(_customerData);
    
    return true;
}

 /**
     * Remove KYC request
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
function removeKycRequest(string memory _userName) public  returns (uint8){
   uint8 k=0;
   for(uint256 i=0; i< customerDataList.length; i++){
       if(stringEquals(KycRequests[customerDataList[i]].userName, _userName)){
           if(customers[_userName].customerRating<= 50){
           delete KycRequests[customerDataList[i]];
           for(uint j=i+1;j<customerDataList.length;j++){
               customerDataList[j-1] =customerDataList[j];
           }
           customerDataList.length--;
           k=1;
       }
       }
   }
    return k; //1 returned if no request with input username is found.
    
}


     /**
     * Add a new upvote from a bank
     * @param {string} _userName Name of the customer to be upvoted
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */

function upVoteCustomer(string memory _userName) public returns (uint8){
    uint256 noofbanks= getTotalBanks();
    for(uint256 i=0;i<customerNames.length;i++){
        if(customers[customerNames[i]].bank == msg.sender){
            emit RequestDenied(msg.sender);
            return 0;
        }
        if(stringEquals(customers[_userName].userName, _userName)){
            customers[_userName].upvotes = (customers[_userName].upvotes) + 100 ; //used 100 as ufixed tye not implemented in solidity yet
            customers[_userName].bank = msg.sender;
            break;
        }
    }
    customers[_userName].customerRating = customers[_userName].upvotes/noofbanks;
    return 1;
}

/** 
   * Add Customer to final customer based on customer rating
   * @param {string} _userName Name of the customer
   * @param {string} _customerData data_hash of the customer
   * @return {uint8}         A 0 indicates failure, 1 indicates success
  */
    
function addCustomerToFinalCustomerList(string memory _userName, string memory _customerData ) public returns(uint){
    if(KycRequests[_customerData].isAllowed != true){
        emit RequestDenied(customers[_userName].bank);
        return 0;
    }
    else{
        if(customers[_userName].customerRating > 50){
        finalcustomers[_userName].userName = _userName;
        finalcustomers[_userName].data_hash = _customerData;
        finalcustomers[_userName].password = customers[_userName].password;
        for(uint i=0;i<customerDataList.length;i++){
            if(stringEquals(KycRequests[customerDataList[i]].userName, _userName)){
        delete(KycRequests[customerDataList[i]]);
            for(uint j=i+1;j<customerDataList.length;j++){
                customerDataList[j-1]=customerDataList[j];
            }
            customerDataList.length--;
    return 1;
            }
        }
        }
    }

}


 /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */

function removeCustomer(string memory _userName) public returns (uint8){
    for(uint256 i=0;i<customerNames.length; i++){
        if(stringEquals(customerNames[i], _userName)){
            delete customers[_userName];
            for(uint j=i+1;j<customerNames.length;j++){
                customerNames[j-1]=customerNames[j];
            }
            customerNames.length--;
            return 1;
        }
    }
    return 0;
}


    /**
     * Edit customer information
     * @param  {string} _userName Name of the customer
     * @param  {string} _hash New hash of the updated ID provided by the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
     
function modifyCustomer(string memory _userName, string memory _password , string memory _customerData) public returns (uint16){
    for(uint i=0; i< customerNames.length;i++){
        if(stringEquals(customers[customerNames[i]].userName,_userName)){
            if(stringEquals(customers[_userName].password,_password) || stringEquals(customers[_userName].password,'0')){
            customers[_userName].data_hash = _customerData;
            KycRequests[_customerData].data_hash= _customerData;
            delete customers[_userName].upvotes;
            customers[_userName].customerRating = 0;
            customers[_userName].bank = msg.sender;
            return 1;
            }
        }
    }
    return 0;
}

function getKycRequestCount()public view returns(uint){
    return customerDataList.length;
}

/**
     * Get Bank Requests
     * @param  {address} _userName Address of Bank
     * @return {string}     Request initiated by bank
     */
function getBankRequest(address  _bankAddress) public view returns (string memory){
    string memory pendingRequest;
    uint k= getKycRequestCount();
    for(uint i=0;i<k;i++){
        if(KycRequests[customerDataList[i]].bank == _bankAddress){
            pendingRequest=KycRequests[customerDataList[i]].userName;
            return pendingRequest;
        }
    }
     return 'null'; 
 }
 

function viewCustomer(string memory _userName) public view returns (string memory, string memory, uint256, address){
    return (customers[_userName].userName,customers[_userName].data_hash,customers[_userName].upvotes, customers[_userName].bank);
}

function getTotalBanks() public view returns(uint count){
    return bankAddresses.length;
}

/**
     * Upvote Bank
     * @param  {address} _userName Address of Bank
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function upVoteBank(address  _bankAddress) public returns(uint8){
        require(_bankAddress != msg.sender, 'Banks cannot upvote themselves');
         uint s= getTotalBanks();
        for(uint i=0; i < s;i++){
            if(banks[bankAddresses[i]].ethAddress == _bankAddress && banks[bankAddresses[i]].validatorBank != msg.sender){
                banks[_bankAddress].bankUpvotes = banks[_bankAddress].bankUpvotes + 100;
                banks[_bankAddress].validatorBank= msg.sender;
                banks[_bankAddress].bankRating = uint8(banks[_bankAddress].bankUpvotes/s-1); //s= total no of banks excluding self
                return 1;
        }
        }
    
    return 0;
    }
    
    function getCustomerRating(string memory _userName) public view returns(uint256 ){
        return customers[_userName].customerRating;
    }
    
    function getBankRating(address _bankAddress ) public view returns(uint256){
        return banks[_bankAddress].bankRating;
    }
    
    function getAccessHistory(string memory _userName) public view returns(address){
        return customers[_userName].bank;
    }
    
    function getPasswordLength(string memory _password) public pure returns(uint){
        bytes memory pwd = bytes(_password);
       // bytes storage l = bytes(_password);
        return pwd.length;
    }
    
   
    function setPassword(string memory _userName, string memory _password) public returns (bool){
        for(uint256 i=0;i<customerNames.length;i++){
            if(stringEquals(customers[customerNames[i]].userName,_userName)){
                require(customers[_userName].bank==msg.sender, 'Password can be set only by bank that added the customer');
                if(getPasswordLength(_password) == 0){
                customers[_userName].password = '0';
                return true;
                }
                else
                customers[_userName].password = _password;
                return true;
            }
        }
        return false;
    }
    
    function getBankDetails(address _bankAddress) public view returns(string memory){
                return banks[_bankAddress].regNumber;
    }
    
    /**
     * Remove Bank
     * @param  {address} _userName Address of Bank
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    
    function removeBank(address _bankAddress) public returns(uint8){
        require(msg.sender==admin, 'Only admin can add or remove a bank');
        for(uint256 i=0;i<bankAddresses.length;i++){
            if(banks[bankAddresses[i]].ethAddress== _bankAddress){
                delete banks[_bankAddress];  
                for(uint j=i+1;j<bankAddresses.length;j++){
                bankAddresses[j-1] =bankAddresses[j];
           }
           bankAddresses.length--;
                return 1;
            }
        }
        return 0;
    }
// function addRequset(string memory _userName, string memory _customerData) public returns(uint8){
//   // require(banks[_userName].bankRating > 0.5,'Bank rating is lower than required.');
//   require(KycRequests[_customerData].bank == address(0), 'This user already has a KYC request with same data in process.');
   
// }

// if you are using string, you can use the following function to compare two strings
// function to compare two string value
// This is an internal fucntion to compare string values
// @Params - String a and String b are passed as Parameters
// @return - This function returns true if strings are matched and false if the strings are not matching
    function stringEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if(a.length != b.length)
        return false;
        
        //TODO unroll this loop
        for(uint8 i=0;i<a.length;i++){
            if(a[i] != b[i])
            return false;
        }
    return true;
    }
}