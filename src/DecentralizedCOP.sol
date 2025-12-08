// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title DCOP
 * @author Vankora.finance
 * @notice DCOP is a decentralized stablecoin protocol designed to bring closer the Colombian Peso (COP) to the new digital economy.
 * Minting : Algorithmic
 * Collateral : Exogenous
 * Anchor : Colombian Peso (COP)
 *
 * This ERC20 token contract is meant to be governed by the DCOP Engine contract.
 */
contract DecentralizedCOP is ERC20Burnable, Ownable {
    // Custom errors.
    error MustBeMoreThanZero();
    error BurnAmountExceedsBalance();
    error NotZeroAddress();

    constructor(address _owner) ERC20("DCOP", "DCOP") Ownable(_owner) {}

    function burn(uint256 amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (amount <= 0) {
            revert MustBeMoreThanZero();
        }

        if (amount > balance) {
            revert BurnAmountExceedsBalance();
        }

        super.burn(amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert NotZeroAddress();
        }

        if (_amount <= 0) {
            revert MustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
