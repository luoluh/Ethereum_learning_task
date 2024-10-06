// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 引入 OpenZeppelin 的 IERC721 接口和 Ownable 合约
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTSwap is Ownable {
    struct Order {
        address owner;
        uint256 price;
        bool active;
    }

    mapping(address => mapping(uint256 => Order)) public orders;

    event Listed(address indexed nftContract, uint256 indexed tokenId, address indexed owner, uint256 price);
    event Revoked(address indexed nftContract, uint256 indexed tokenId);
    event PriceUpdated(address indexed nftContract, uint256 indexed tokenId, uint256 newPrice);
    event Purchased(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 price);

    // 构造函数，传递 msg.sender 给 Ownable 合约的构造函数
    constructor() Ownable(msg.sender) {}  // 传递当前合约部署者地址作为初始所有者

    function list(address nftContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "You must own the NFT to list it");

        orders[nftContract][tokenId] = Order({
            owner: msg.sender,
            price: price,
            active: true
        });

        emit Listed(nftContract, tokenId, msg.sender, price);
    }

    function revoke(address nftContract, uint256 tokenId) external {
        Order memory order = orders[nftContract][tokenId];
        require(order.active, "Order does not exist");
        require(order.owner == msg.sender, "Only the owner can revoke the order");

        delete orders[nftContract][tokenId];

        emit Revoked(nftContract, tokenId);
    }

    function updatePrice(address nftContract, uint256 tokenId, uint256 newPrice) external {
        require(newPrice > 0, "New price must be greater than zero");
        Order storage order = orders[nftContract][tokenId];
        require(order.active, "Order does not exist");
        require(order.owner == msg.sender, "Only the owner can update the price");

        order.price = newPrice;

        emit PriceUpdated(nftContract, tokenId, newPrice);
    }

    function purchase(address nftContract, uint256 tokenId) external payable {
        Order memory order = orders[nftContract][tokenId];
        require(order.active, "Order does not exist");
        require(msg.value == order.price, "Incorrect payment amount");

        IERC721(nftContract).safeTransferFrom(order.owner, msg.sender, tokenId);

        payable(order.owner).transfer(msg.value);

        delete orders[nftContract][tokenId];

        emit Purchased(nftContract, tokenId, msg.sender, order.price);
    }
}
