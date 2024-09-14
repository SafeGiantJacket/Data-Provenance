// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DataProvenance is ERC20, ReentrancyGuard {
    struct DataSource {
        string name;
        string dataHash;
        address owner;
        uint256 timestamp;
        bool verified;
        uint256 reward;
        uint256 averageRating;
        uint256 numRatings;
    }

    struct Verifier {
        address verifierAddress;
        bool isVerifier;
        uint256 reputation;
    }

    mapping(string => DataSource) private dataSources;
    mapping(address => Verifier) private verifiers;
    string[] private dataHashes;
    address[] private verifierAddresses;

    address public admin;
    uint256 public verificationFee = 50;
    uint256 public totalTokens = 1000000;

    event DataAdded(string indexed dataHash, string name, address indexed owner, uint256 timestamp);
    event DataVerified(string indexed dataHash, address indexed verifier, uint256 timestamp, uint256 reward);
    event DataAccessed(string indexed dataHash, address indexed accessor, uint256 timestamp);
    event VerifierAdded(address indexed verifier);
    event TokensRewarded(address indexed to, uint256 amount);
    event FeedbackProvided(string indexed dataHash, address indexed user, uint256 rating);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender].isVerifier, "Only verifiers can perform this action");
        _;
    }

    constructor() ERC20("DataToken", "DTK") {
        admin = msg.sender;
        _mint(admin, totalTokens * (10 ** uint256(decimals()))); // Allocate all tokens to the admin initially
    }

    function addDataSource(string memory name, string memory dataHash) public {
        require(bytes(dataHash).length > 0, "Data hash cannot be empty");
        require(bytes(dataSources[dataHash].dataHash).length == 0, "Data hash already exists");

        dataSources[dataHash] = DataSource({
            name: name,
            dataHash: dataHash,
            owner: msg.sender,
            timestamp: block.timestamp,
            verified: false,
            reward: 0,
            averageRating: 0,
            numRatings: 0
        });
        dataHashes.push(dataHash);

        emit DataAdded(dataHash, name, msg.sender, block.timestamp);
    }

    function verifyDataSource(string memory dataHash) public onlyVerifier nonReentrant {
        require(bytes(dataSources[dataHash].dataHash).length != 0, "Data source does not exist");
        require(!dataSources[dataHash].verified, "Data source already verified");

        dataSources[dataHash].verified = true;
        uint256 reward = calculateReward(msg.sender); // Dynamic reward
        dataSources[dataHash].reward = reward;

        // Transfer tokens to the data source owner
        _transfer(admin, dataSources[dataHash].owner, reward);

        // Increase verifier's reputation
        verifiers[msg.sender].reputation += 10;

        emit DataVerified(dataHash, msg.sender, block.timestamp, reward);
        emit TokensRewarded(dataSources[dataHash].owner, reward);
    }

    function calculateReward(address verifier) internal view returns (uint256) {
        uint256 baseReward = 100;
        uint256 multiplier = verifiers[verifier].reputation / 10; // More reputation = higher reward
        return baseReward + (multiplier * 10);
    }

    function accessDataSource(string memory dataHash) public view returns (DataSource memory) {
        require(bytes(dataSources[dataHash].dataHash).length != 0, "Data source does not exist");
        return dataSources[dataHash];
    }

    function logDataAccess(string memory dataHash) public {
        require(bytes(dataSources[dataHash].dataHash).length != 0, "Data source does not exist");
        emit DataAccessed(dataHash, msg.sender, block.timestamp);
    }

    function getAllDataHashes() public view returns (string[] memory) {
        return dataHashes;
    }

    function addVerifier(address verifierAddress) public onlyAdmin {
        require(verifierAddress != address(0), "Invalid verifier address");
        require(!verifiers[verifierAddress].isVerifier, "Verifier already added");

        verifiers[verifierAddress] = Verifier({
            verifierAddress: verifierAddress,
            isVerifier: true,
            reputation: 0
        });
        verifierAddresses.push(verifierAddress);

        emit VerifierAdded(verifierAddress);
    }

    function provideFeedback(string memory dataHash, uint256 rating) public {
        require(bytes(dataSources[dataHash].dataHash).length != 0, "Data source does not exist");
        require(rating > 0 && rating <= 5, "Rating must be between 1 and 5");

        DataSource storage ds = dataSources[dataHash];
        ds.numRatings++;
        ds.averageRating = ((ds.averageRating * (ds.numRatings - 1)) + rating) / ds.numRatings;

        emit FeedbackProvided(dataHash, msg.sender, rating);
    }

    // Token balance function
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    // Token transfer function
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return super.transfer(recipient, amount);
    }

    // Token transferFrom function
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
