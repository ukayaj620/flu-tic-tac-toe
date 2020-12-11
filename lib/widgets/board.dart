import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flu_tic_tac_toe/controllers/board_controller.dart';
import 'package:flu_tic_tac_toe/controllers/game_controller.dart';
import 'package:flu_tic_tac_toe/controllers/user_controller.dart';
import 'package:flu_tic_tac_toe/utils/storage.dart';
import 'package:flu_tic_tac_toe/widgets/dialogs.dart';
import 'package:flutter/material.dart';

class Cell extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final bool disable;

  Cell(this.value, {@required this.onTap, @required this.disable});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disable ? null : onTap,
      child: Container(
        width: 1 / 3 * (.75 * MediaQuery.of(context).size.width - 48.0),
        height: 1 / 3 * (.75 * MediaQuery.of(context).size.width - 48.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: value != '' ? Image.asset('assets/icons/$value.png') : null,
      ),
    );
  }
}

class Board extends StatefulWidget {

  @override
  _BoardState createState() => _BoardState();
}

class _BoardState extends State<Board> {
  BoardController _boardController;
  GameController _gameController;
  UserController _userController;
  StreamSubscription<Event> _boardStream;
  Storage _storage;
  bool _isHost;
  String _turn;
  String _code;
  String _uid;

  @override
  void initState() {
    _storage = Storage();
    _storage.init();
    _boardController = BoardController();
    _gameController = GameController();
    _userController = UserController();
    _boardController.subscribeToBoard((event) {
      final value = event.snapshot.value;
      setState(() {
        _boardController.updateBoardState = value['boardState'];
        _uid = _storage.getUID();
        _isHost = _storage.getUID() == value['host'];
        _turn = value['turn'];
        _code = value['code'];
        _showGameResult();
      });
    }).then((stream) {
      _boardStream = stream;
    });
    super.initState();
  }

  @override
  void dispose() {
    _boardStream.cancel();
    super.dispose();
  }

  bool _determineDisableCell() {
    if (_isHost && _turn == 'X') {
      return false;
    } else if (!_isHost && _turn == 'O') {
      return false;
    } else {
      return true;
    }
  }

  void _showGameResult() {
    switch(_boardController.evaluateBoardState(_isHost ? 'X' : 'O')) {
      case BoardStatus.WIN:
        showDialog(
            context: context,
            builder: (context) => TheAlert(
                title: 'Game Result',
                content: 'It\'s a win. Congratulations!',
                buttonText: 'Close',
                onPressed: () {
                  _gameController.updateGamePlay(_code, _isHost, 'win');
                  _userController.updateUserGamePlay(_uid, 'win');
                  Navigator.pushReplacementNamed(context, 'profile');
                }
            )
        );
        break;
      case BoardStatus.LOSE:
        showDialog(
            context: context,
            builder: (context) => TheAlert(
                title: 'Game Result',
                content: 'Haiya. You lose, so shame!',
                buttonText: 'Close',
                onPressed: () {
                  Navigator.pop(context);
                  _gameController.updateGamePlay(_code, _isHost, 'lose');
                  _userController.updateUserGamePlay(_uid, 'lose');
                  Navigator.pushReplacementNamed(context, 'profile');
                }
            )
        );
        break;
      case BoardStatus.DRAW:
        showDialog(
            context: context,
            builder: (context) => TheAlert(
                title: 'Game Result',
                content: 'It\'s a draw. Good Job!',
                buttonText: 'Close',
                onPressed: () {
                  Navigator.pop(context);
                  _gameController.updateGamePlay(_code, _isHost, 'draw');
                  _userController.updateUserGamePlay(_uid, 'draw');
                  Navigator.pushReplacementNamed(context, 'profile');
                }
            )
        );
        break;
      case BoardStatus.PLAY:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: .75 * MediaQuery.of(context).size.width,
      height: .75 * MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _boardController.boardState
            .asMap()
            .map((x, row) {
              return MapEntry(
                x,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: row
                      .asMap()
                      .map((y, cell) {
                        return MapEntry(
                          y,
                          Cell(
                            cell,
                            disable: _determineDisableCell(),
                            onTap: () {
                              if (_isHost && _turn == 'X') {
                                setState(() {
                                  _boardController.occupy(_turn, x: x, y: y);
                                });
                                print(_boardController.boardState);
                                _gameController.updateBoardState(
                                    _code,
                                    _boardController.boardStateJSON,
                                    'O');
                              }
                              if (!_isHost && _turn == 'O') {
                                setState(() {
                                  _boardController.occupy(_turn, x: x, y: y);
                                });
                                print(_boardController.boardState);
                                _gameController.updateBoardState(
                                    _code,
                                    _boardController.boardStateJSON,
                                    'X');
                              }
                            },
                          ),
                        );
                      })
                      .values
                      .toList(),
                ),
              );
            })
            .values
            .toList(),
      ),
    );
  }
}