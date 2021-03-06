import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gamebidder_screen.dart';
import 'board.dart';

class PlayersScreen extends StatefulWidget {
  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<String> _players = [];
  final List<List<int>> _scoreboard = [];
  bool _isComposing = false;
  final TextEditingController _textController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).accentColor,
      title: Text("Add Players"),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.check),
          disabledColor: Colors.red,
          onPressed: (_players.length > 0) ? _startPlaying : null,
        )
      ],
    );
  }

  void _startPlaying() {
    int n = _players.length;
    print("Created table with $n players");
    final boardID = _createTable();

    for (int i = 0; i < n; i++) {
      _scoreboard.add([]);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return GameBidderScreen(
            boardID: boardID,
            gameID: 1,
            players: _players,
            scoreboard: _scoreboard,
          );
        },
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Column(
        children: <Widget>[
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
              padding: EdgeInsets.all(20.0),
              itemCount: _players.length,
              itemBuilder: _playerTileBuilder,
            ),
          ),
          Divider(height: 20.0),
          Container(
            decoration: new BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  String _createTable() {
    Board b = new Board();
    Firestore.instance.settings(timestampsInSnapshotsEnabled: true);
    Map<String, dynamic> data = <String, dynamic>{"created_at": b.createdAt};
    final document = Firestore.instance.collection("boards").document();
    print(document.documentID);
    document.setData(data);

    for (var p in _players) {
      Map<String, dynamic> playerData = <String, dynamic>{"name": p};
      final newPlayer = document.collection("players").document();
      final playerID = newPlayer.documentID;
      print("Player Name: $p, PlayerID:$playerID");
      newPlayer.setData(playerData);
    }
    return document.documentID;
  }

  Widget _playerTileBuilder(BuildContext context, int index) {
    final name = _players[index];
    return Dismissible(
      key: Key(name),
      onDismissed: (direction) {
        // Remove the item from our data source.
        setState(() {
          _players.removeAt(index);
        });

        // Then show a snackbar!
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("$name has been from the board! 🙁")));
      },
      background: Container(color: Colors.red),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          margin: EdgeInsets.only(right: 16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5.0),
            color: Colors.yellow,
          ),
          child: ListTile(
            leading: Container(
              margin: EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(
                child: new Text(name[0] + name[1]),
                radius: 24,
              ),
            ),
            title: Text(name),
          ),
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Flexible(
              child: TextField(
                style: Theme.of(context).textTheme.display1,
                decoration: InputDecoration(
                  labelStyle: Theme.of(context).textTheme.display1,
                  labelText: "Name",
                  // errorText: "Invalid name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                controller: _textController,
                onChanged: (String text) {
                  setState(
                    () {
                      _isComposing = text.length > 0;
                    },
                  );
                },
                onSubmitted: _handleSubmitted,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: _isComposing
                    ? () => _handleSubmitted(_textController.text)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();

    setState(() {
      _isComposing = false;
      _players.add(text.trim());
    });
  }
}
