// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract TicTacToe {
    event GameStarted(uint256 gameId, address player1, address player2);
    event GameEnded(uint256 gameId, address player1, address player2, address winner);
    event MoveMade(uint256 gameId, address player, uint8 _cell);

    struct TicTacToeGame {
        uint256 id;
        uint8[9] board;
        address player1;
        address player2;
        address winner;
        address turn;
        uint256 buyIn;
        bool claimed;
    }

    TicTacToeGame[] public games;

    uint256 private constant GAME_ID_OFFSET = 1000;

    mapping(address => uint256) public playerActiveGame;

    /**
     * Modifiers
     */

    modifier canCreateGame() {
        require(playerActiveGame[msg.sender] == 0, "You already have an active game.");
        require(msg.value > 0, "Buy in amount must be more than zero.");
        _;
    }

    modifier canJoinGame(uint256 _gameId) {
        require(playerActiveGame[msg.sender] == 0, "You already have an active game.");
        require(_gameId >= GAME_ID_OFFSET, "Game does not exist.");

        uint256 gameIndex = _gameId - GAME_ID_OFFSET;

        require(gameIndex < games.length, "Game does not exist.");

        TicTacToeGame memory game = games[_gameId - GAME_ID_OFFSET];

        require(msg.value == game.buyIn, "You must pay the buy in amount to join.");
        require(game.winner == address(0), "Game is already over.");
        require(msg.sender != game.player1, "You are already playing in this game.");
        require(game.player2 == address(0), "This game is full.");
        _;
    }

    modifier canForfeitGame() {
        require(playerActiveGame[msg.sender] > 0, "You do not have an active game.");
        _;
    }

    modifier canLeaveGame() {
        require(playerActiveGame[msg.sender] > 0, "You do not have an active game.");
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        require(games[gameIndex].winner != address(0), "Game still in progress.");
        require(
            msg.sender != games[gameIndex].winner ||
                (msg.sender == games[gameIndex].winner && games[gameIndex].claimed == true),
            "Claim your winnings before leaving."
        );
        _;
    }

    modifier canClaimProfit() {
        require(playerActiveGame[msg.sender] > 0, "You do not have an active game.");
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        require(games[gameIndex].winner != address(0), "Game still in progress.");
        require(msg.sender == games[gameIndex].winner, "You are not the winner.");
        require(games[gameIndex].claimed == false, "You have already claimed your winnings.");
        _;
    }

    modifier canMakeMove(uint256 _cell) {
        require(playerActiveGame[msg.sender] > 0, "You do not have an active game.");
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        TicTacToeGame memory game = games[gameIndex];
        require(game.player2 != address(0), "This game has not started yet.");
        require(game.turn == msg.sender, "It is not your turn.");
        require(game.winner == address(0), "This game has already ended.");
        require(_cell < 9, "Invalid cell.");
        require(game.board[_cell] == 0, "This cell is already occupied.");
        _;
    }

    /**
     * Views
     */

    function myAddress() public view returns (address) {
        return msg.sender;
    }

    function hasActiveGame() external view returns (bool) {
        return playerActiveGame[msg.sender] > 0;
    }

    function getActiveGame() external view returns (TicTacToeGame memory) {
        uint256 gameId = playerActiveGame[msg.sender];
        require(gameId > 0, "Game does not exist.");
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        return games[gameIndex];
    }

    function getAllGames() external view returns (TicTacToeGame[] memory) {
        return games;
    }

    /**
     * Functions
     */

    function _hasWonGame() private view returns (bool) {
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        uint8[9] memory board = games[gameIndex].board;

        // Horizontal top row
        if (board[0] != 0 && board[0] == board[1] && board[1] == board[2]) {
            return true;
        }

        // Horizontal middle row
        if (board[3] != 0 && board[3] == board[4] && board[4] == board[5]) {
            return true;
        }

        // Horizontal bottom row
        if (board[6] != 0 && board[6] == board[7] && board[7] == board[8]) {
            return true;
        }

        // Vertical left col
        if (board[0] != 0 && board[0] == board[3] && board[3] == board[6]) {
            return true;
        }

        // Vertical middle col
        if (board[1] != 0 && board[1] == board[4] && board[4] == board[7]) {
            return true;
        }

        // Vertical right col
        if (board[2] != 0 && board[2] == board[5] && board[5] == board[8]) {
            return true;
        }

        // Diagonal top left to bottom right
        if (board[0] != 0 && board[0] == board[4] && board[4] == board[8]) {
            return true;
        }

        // Diagonal top right to bottom left
        if (board[2] != 0 && board[2] == board[4] && board[4] == board[6]) {
            return true;
        }

        return false;
    }

    function createGame() external payable canCreateGame {
        uint256 gameId = games.length + GAME_ID_OFFSET;

        games.push(
            TicTacToeGame({
                id: gameId,
                board: [0, 0, 0, 0, 0, 0, 0, 0, 0],
                player1: msg.sender,
                player2: address(0),
                winner: address(0),
                turn: address(0),
                buyIn: msg.value,
                claimed: false
            })
        );

        playerActiveGame[msg.sender] = gameId;
    }

    function joinGame(uint256 _gameId) external payable canJoinGame(_gameId) {
        uint256 gameIndex = _gameId - GAME_ID_OFFSET;
        games[gameIndex].player2 = msg.sender;
        games[gameIndex].turn = msg.sender;
        playerActiveGame[msg.sender] = _gameId;
    }

    function forfeitGame() external canForfeitGame {
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        games[gameIndex].winner = msg.sender == games[gameIndex].player1
            ? games[gameIndex].player2
            : games[gameIndex].player1;
        games[gameIndex].turn = address(0);
        emit GameEnded(
            gameId,
            games[gameIndex].player1,
            games[gameIndex].player2,
            games[gameIndex].winner
        );
    }

    function leaveGame() external canLeaveGame {
        playerActiveGame[msg.sender] = 0;
    }

    function claimProfit() external canClaimProfit {
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        games[gameIndex].claimed = true;
        payable(msg.sender).transfer(games[gameIndex].buyIn * 2);
    }

    function makeMove(uint8 _cell) external canMakeMove(_cell) {
        uint256 gameId = playerActiveGame[msg.sender];
        uint256 gameIndex = gameId - GAME_ID_OFFSET;
        TicTacToeGame storage game = games[gameIndex];

        game.board[_cell] = msg.sender == game.player1 ? 1 : 2;
        emit MoveMade(gameId, msg.sender, _cell);

        if (_hasWonGame()) {
            game.winner = msg.sender;
            game.turn = address(0);
            emit GameEnded(gameId, game.player1, game.player2, game.winner);
        } else {
            game.turn = msg.sender == game.player1 ? game.player2 : game.player1;
        }
    }
}
