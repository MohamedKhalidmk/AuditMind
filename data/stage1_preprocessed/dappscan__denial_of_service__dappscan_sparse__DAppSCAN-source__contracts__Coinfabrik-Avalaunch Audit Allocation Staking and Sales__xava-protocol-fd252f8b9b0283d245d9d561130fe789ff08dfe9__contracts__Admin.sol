
pragma solidity 0.6.12;

contract Admin {

    
    address [] public admins;

    
    mapping(address => bool) public isAdmin;

    
    modifier onlyAdmin {
        require(isAdmin[msg.sender] == true, "not admin");
        _;
    }

    
    constructor (address [] memory _admins) public {
        for(uint i = 0; i < _admins.length; i++) {
            admins.push(_admins[i]);
            isAdmin[_admins[i]] = true;
        }
    }

    function addAdmin(
        address _adminAddress
    )
    external
    onlyAdmin
    {
        
        require(_adminAddress != address(0x0), "[RBAC] : Admin must be != than 0x0 address");
        
        require(isAdmin[_adminAddress] == false, "[RBAC] : Admin already exists.");
        
        admins.push(_adminAddress);
        
        isAdmin[_adminAddress] = true;
    }

    
    function removeAdmin(
        address _adminAddress
    )
    external
    onlyAdmin
    {
        
        require(isAdmin[_adminAddress] == true);

        uint i = 0;

        while(admins[i] != _adminAddress) {
            if(i == admins.length) {
                revert("Passed admin address does not exist");
            }
            i++;
        }

        
        admins[i] = admins[admins.length-1];

        isAdmin[_adminAddress] = false;

        
        admins.pop();
    }

    
    function getAllAdmins()
    external
    view
    returns (address [] memory)
    {
        return admins;
    }

}
