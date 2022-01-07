import { expect } from 'chai';
import { ethers } from 'hardhat';
import { TicTacToe } from '../typechain';

const { parseEther } = ethers.utils;

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe('TicTacToe', () => {
  let contractFactory: any;
  let contract: TicTacToe;

  beforeEach(async () => {
    contractFactory = await ethers.getContractFactory('TicTacToe');
    contract = await contractFactory.deploy();
    await contract.deployed();
  });

  it('has an empty games list after initializing', async function () {
    const promise = contract.games(0);
    expect(promise).to.be.revertedWith('');
  });

  describe('createGame', () => {
    it('accepts only the exact buy-in amount, not less', async () => {
      const buyInWrong = parseEther('0.1');
      const buyIn = parseEther('1');
      const promise = contract.createGame(buyIn, { value: buyInWrong });
      expect(promise).to.be.revertedWith('Error: Buy in amount must match the amount sent.');
    });

    it('accepts only the exact buy-in amount, not more', async () => {
      const buyInWrong = parseEther('1');
      const buyIn = parseEther('0.1');
      const promise = contract.createGame(buyIn, { value: buyInWrong });
      expect(promise).to.be.revertedWith('Error: Buy in amount must match the amount sent.');
    });

    it('accepts only the exact buy-in amount', async () => {
      const buyIn = parseEther('1');
      const promise = contract.createGame(buyIn, { value: buyIn });
      expect(promise).to.not.be.revertedWith('Error: Buy in amount must match the amount sent.');
    });

    it('sets msg.sender as player1', async function () {
      const buyIn = parseEther('0.001');
      await contract.createGame(buyIn, { value: buyIn });
      const game = await contract.games(0);
      const sender = await contract.signer.getAddress();
      expect(game.player1).to.equal(sender);
    });

    it('sets address(0) as player2', async function () {
      const buyIn = parseEther('0.001');
      await contract.createGame(buyIn, { value: buyIn });
      const game = await contract.games(0);
      expect(game.player2).to.equal(ZERO_ADDRESS);
    });
  });
});
