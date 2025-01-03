// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoeftiCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 Milliarde Tokens

    // Anteile
    uint256 public constant OWNER_SHARE = 60; // 60% für den Besitzer
    uint256 public constant COMMUNITY_SHARE = 11; // 11% für Community
    uint256 public constant MARKETING_SHARE = 5; // 5% für Marketing
    uint256 public constant DEVELOPMENT_SHARE = 11; // 11% für Entwicklung
    uint256 public constant LIQUIDITY_SHARE = 8; // 8% für Liquidität
    uint256 public constant TEAM_SHARE = 5; // 5% für Team (gesperrt für 12 Monate)

    // Gebühren
    uint256 public constant BURN_FEE = 1; // 1% wird verbrannt
    uint256 public constant OWNER_FEE = 2; // 2% gehen an den Besitzer
    uint256 public constant LIQUIDITY_FEE = 2; // 2% gehen in den Liquiditätspool

    // Zeitliche Sperre für Team-Tokens
    uint256 public teamTokensUnlockedAt;

    // Adresse für Liquiditätspool (initial auf die Null-Adresse gesetzt)
    address public liquidityPoolAddress;

    constructor(address owner) ERC20("BoeftiCoin", "BFTI") Ownable(owner) {
        // Tokens basierend auf der Verteilung erstellen
        uint256 ownerTokens = (MAX_SUPPLY * OWNER_SHARE) / 100;
        uint256 communityTokens = (MAX_SUPPLY * COMMUNITY_SHARE) / 100;
        uint256 marketingTokens = (MAX_SUPPLY * MARKETING_SHARE) / 100;
        uint256 developmentTokens = (MAX_SUPPLY * DEVELOPMENT_SHARE) / 100;
        uint256 liquidityTokens = (MAX_SUPPLY * LIQUIDITY_SHARE) / 100;
        uint256 teamTokens = (MAX_SUPPLY * TEAM_SHARE) / 100;

        // Mint Tokens
        _mint(owner, ownerTokens); // 60% gehen an den Besitzer
        _mint(msg.sender, communityTokens); // 11% für die Community
        _mint(address(this), marketingTokens); // 5% für Marketing
        _mint(address(this), developmentTokens); // 11% für Entwicklung
        _mint(address(this), liquidityTokens); // 8% für den Liquiditätspool
        _mint(address(this), teamTokens); // 5% für das Team, gesperrt für 12 Monate

        teamTokensUnlockedAt = block.timestamp + 365 days; // Team-Tokens sind 12 Monate gesperrt
    }

    // Überschreibe die transfer-Methode, um Gebühren anzuwenden
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 burnAmount = (amount * BURN_FEE) / 100; // 1% Verbrennung
        uint256 ownerFee = (amount * OWNER_FEE) / 100; // 2% an den Besitzer
        uint256 liquidityFee = (amount * LIQUIDITY_FEE) / 100; // 2% in den Liquiditätspool
        uint256 amountAfterFees = amount - burnAmount - ownerFee - liquidityFee; // Restbetrag

        require(amountAfterFees > 0, "Transfer amount too small after fees.");

        // Gebühren anwenden
        _burn(msg.sender, burnAmount); // Verbrennen
        super.transfer(owner(), ownerFee); // An den Besitzer
        if (liquidityPoolAddress != address(0)) {
            super.transfer(liquidityPoolAddress, liquidityFee); // An den Liquiditätspool
        }

        // Übertragung des Restbetrags
        return super.transfer(recipient, amountAfterFees);
    }

    // Funktion zum Festlegen der Liquiditätspool-Adresse (nur der Besitzer kann das tun)
    function setLiquidityPoolAddress(address _liquidityPoolAddress) public onlyOwner {
        require(_liquidityPoolAddress != address(0), "Invalid address");
        liquidityPoolAddress = _liquidityPoolAddress;
    }

    // Funktion zum Freischalten der Team-Tokens nach 12 Monaten
    function unlockTeamTokens() public onlyOwner returns (bool) {
        require(block.timestamp >= teamTokensUnlockedAt, "Tokens are locked for 12 months.");
        uint256 teamBalance = balanceOf(address(this));
        require(teamBalance > 0, "No locked tokens to unlock.");
        _transfer(address(this), owner(), teamBalance); // Übertrage die gesperrten Team-Tokens an den Besitzer
        emit TeamTokensUnlocked(teamBalance);
        return true;
    }

    // Ereignisse für Transparenz
    event TeamTokensUnlocked(uint256 amount);

    // Zusatz: Tokens vom Contract verteilen
    function distributeTokens(address recipient, uint256 amount) public onlyOwner {
        require(balanceOf(address(this)) >= amount, "Not enough tokens available.");
        _transfer(address(this), recipient, amount);
    }
}
