//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract TicTacToe is Ownable {
    event GameStarted(uint256 gameId, address player1, address player2);
    event GameEnded(uint256 gameId, address player1, address player2, address winner);
    event MoveMade(uint256 gameId, address player, uint8 _cell);

    struct TicTacToeGame {
        uint8[9] board;
        address player1;
        address player2;
        address winner;
        address turn;
        uint256 buyIn;
    }

    TicTacToeGame[] public games;

    mapping(address => bool) public playerHasActiveGame;
    mapping(address => uint256) public playerActiveGame;

    function isPlayer1(uint256 _gameId, address _player) public view returns (bool) {
        return games[_gameId].player1 == _player;
    }

    function isPlayer2(uint256 _gameId, address _player) public view returns (bool) {
        return games[_gameId].player2 == _player;
    }

    function _hasActiveGame(address _playerAddress) private view returns (bool) {
        return playerHasActiveGame[_playerAddress];
    }

    function _getActiveGame(address _playerAddress) private view returns (uint256) {
        // Be sure to check playerHasActiveGame first
        return playerActiveGame[_playerAddress];
    }

    function _setActiveGame(address _playerAddress, uint256 _gameId) private {
        playerHasActiveGame[_playerAddress] = true;
        playerActiveGame[_playerAddress] = _gameId;
    }

    function _unsetActiveGame(address _playerAddress) private {
        playerHasActiveGame[_playerAddress] = false;
    }

    function _hasWonGame(uint256 _gameId) private view returns (bool) {
        uint8[9] memory board = games[_gameId].board;

        // Horizontal top row
        if (board[0] == board[1] && board[1] == board[2]) {
            return true;
        }

        // Horizontal middle row
        if (board[3] == board[4] && board[4] == board[5]) {
            return true;
        }

        // Horizontal bottom row
        if (board[6] == board[7] && board[7] == board[8]) {
            return true;
        }

        // Vertical left col
        if (board[0] == board[3] && board[3] == board[6]) {
            return true;
        }

        // Vertical middle col
        if (board[1] == board[4] && board[4] == board[7]) {
            return true;
        }

        // Vertical right col
        if (board[2] == board[5] && board[5] == board[8]) {
            return true;
        }

        // Diagonal top left to bottom right
        if (board[0] == board[4] && board[4] == board[8]) {
            return true;
        }

        // Diagonal top right to bottom left
        if (board[2] == board[4] && board[4] == board[6]) {
            return true;
        }

        return false;
    }

    function createGame(uint256 _buyIn) external payable {
        require(msg.value == _buyIn, "Error: Buy in amount must match the amount sent.");
        require(_hasActiveGame(msg.sender) == false, "Error: You already have an active game.");

        games.push(
            TicTacToeGame({
                board: [0, 0, 0, 0, 0, 0, 0, 0, 0],
                player1: msg.sender,
                player2: address(0),
                winner: address(0),
                turn: msg.sender,
                buyIn: _buyIn
            })
        );

        _setActiveGame(msg.sender, games.length - 1);
    }

    function joinGame(uint256 _gameId) external payable {
        require(msg.value == games[_gameId].buyIn, "Error: You must pay the buy in amount.");
        require(_hasActiveGame(msg.sender) == false, "Error: You already have an active game.");
        require(_gameId < games.length, "Error: Game does not exist.");
        require(
            games[_gameId].player1 != msg.sender,
            "Error: You are already playing in this game."
        );
        require(games[_gameId].player2 == address(0), "Error: This game is full.");

        games[_gameId].player2 = msg.sender;

        _setActiveGame(msg.sender, _gameId);
    }

    function makeMove(uint256 _gameId, uint8 _cell) external {
        require(_gameId < games.length);

        TicTacToeGame memory game = games[_gameId];

        require(isPlayer1(_gameId, msg.sender) || isPlayer2(_gameId, msg.sender));
        require(game.turn == msg.sender);
        require(game.winner == address(0));
        require(_cell < 9);
        require(game.board[_cell] == 0);

        game.board[_cell] = msg.sender == game.player1 ? 1 : 2;
        emit MoveMade(_gameId, msg.sender, _cell);

        if (_hasWonGame(_gameId)) {
            game.winner = msg.sender;
            game.turn = address(0);
            emit GameEnded(_gameId, game.player1, game.player2, game.winner);
            _unsetActiveGame(game.player1);
            _unsetActiveGame(game.player2);
        } else {
            game.turn = msg.sender == game.player1 ? game.player2 : game.player1;
        }
    }
}
