// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract LMTBridge is Ownable, EIP712{  
    event TokenLocked(address indexed tokenAddress, address indexed user,uint256 amount);
    event TokenReleased(address indexed token,address indexed user , uint256 amount);
    event TokenAdded(address indexed token, address indexed destinationChainTokenAddress);

    bytes32 private constant UNLOCK_TYPEHASH =
        keccak256("Claim(address tokenAddress,address claimer,uint256 amount,uint256 nonce)");
    // @dev Key is the address of a user and the value is token address => amount.
    mapping(address => mapping(address => uint256)) public lockedBalances;
    // @dev Nonces for replay protection.
    mapping(address => uint256) public nonces;
    mapping(address => address) public destinationChainTokenAddresses;
    
    constructor() EIP712("LMTBridge", "1") Ownable(){
    }

    /**
     * @notice  . The function accepts the amount of tokens to be locked in the bridge contract and emmit an event, which is used by the trusted provider to initiate the minting of the same amount of tokens on the other chain.
     * @dev     . If the sender does not have enough tokens, the transaction will be reverted.
     * @param   amount  . amount of LMT tokens to be locked in the bridge contract.
     */
    function lockTokens(address tokenAddress,uint256 amount) external{
        require(amount > 0, "LMTBridge: Amount must be greater than 0");
        require(tokenAddress != address(0), "LMTBridge: Token address must not be zero");

        require(destinationChainTokenAddresses[tokenAddress] != address(0), "LMTBridge: Token not supported");
        

        lockedBalances[msg.sender][tokenAddress]+= amount;
       (bool result) = ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
       require(result, "LMTBridge: Transfer failed");

       emit TokenLocked(tokenAddress, msg.sender,  amount);
    }

    function addDestinationChainToken(address tokenAddress, address destinationAddress) onlyOwner external{
        require(tokenAddress != address(0), "LMTBridge: Token address must not be zero");
        require(destinationAddress != address(0), "LMTBridge: Destination address must not be zero");
        destinationChainTokenAddresses[tokenAddress] = destinationAddress;
        emit TokenAdded(tokenAddress, destinationAddress);
    }

    /**
     * @notice  . The function should be triggered only by the trusted provider, who is responsible to guarantee the burning of the same amount of tokens on the other chain.
     * @dev     . The function will revert if the amount is greater than the locked balance of the user.
     * @param   amount  . of LMT tokens to be unlocked.
     * @param   user  . The address of the user, who will receive the unlocked tokens.
     */
    function unlockTokensWithSignature(address tokenAddress, uint256 amount, address user, uint8 v, bytes32 r, bytes32 s) external{
        require(amount > 0, "LMTBridge: Amount must be greater than 0");
        require(lockedBalances[user][tokenAddress] >= amount, "LMTBridge: Amount must be less than or equal locked balance");
        require(destinationChainTokenAddresses[tokenAddress] != address(0), "Token not supported");

        bytes32 structHash  = keccak256(abi.encode(UNLOCK_TYPEHASH,tokenAddress, user, amount, nonces[user]));
        nonces[user]++;
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), v, r, s);
        require(signer == owner(), "LMTBridge: Invalid signature");


        lockedBalances[user][tokenAddress]-= amount;
        (bool result) = ERC20(tokenAddress).transfer(user, amount);
        require(result, "LMTBridge: Transfer failed");

        emit TokenReleased(tokenAddress, user,amount);
    }
}