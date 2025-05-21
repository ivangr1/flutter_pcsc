import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcsc_macos/flutter_pcsc_macos.dart';
import 'dart:async';

import 'package:flutter_pcsc_platform_interface/flutter_pcsc_platform_interface.dart';

void main() {
  MyApp? myApp;

  runZonedGuarded(() async {
    PcscMacOS.registerWith();
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      myApp?.addError(details.toString());
    };

    runApp(myApp = MyApp());
  }, (Object error, StackTrace stack) {
    print(error.toString());
    myApp?.addError(error.toString());
  });
}

class MyApp extends StatelessWidget {
  final GlobalKey<_MyAppBodyState> _myAppKey = GlobalKey();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: MyAppBody(key: _myAppKey)),
    );
  }

  void addError(String msg) {
    _myAppKey.currentState?.addMessage(Message.error(msg));
  }
}

class MyAppBody extends StatefulWidget {
  const MyAppBody({required Key key}) : super(key: key);

  @override
  _MyAppBodyState createState() {
    return _MyAppBodyState();
  }
}

enum MessageType { info, error }

class Message {
  final String content;
  final MessageType type;
  Message(this.type, this.content);

  static info(String content) {
    return Message(MessageType.info, content);
  }

  static error(String content) {
    return Message(MessageType.error, content);
  }
}

class _MyAppBodyState extends State<MyAppBody> {
  static const List<int> getCardSerialNumberCommand = [
    0xFF,
    0xCA,
    0x00,
    0x00,
    0x00
  ];
  static const List<int> controlCommand = [0xE0, 0x00, 0x00, 0x28, 0x01, 0x05];
  static const int IOCTL_SMARTCARD_VENDOR_IFD_EXCHANGE = 0x42000000 + 3400;
  final ScrollController _scrollController = ScrollController();

  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    getCardSerialNumber();
  }

  void addMessage(Message m) {
    setState(() {
      _messages.add(m);
    });
  }

  int scardCtlCode(int x) => (0x31 << 16) | (x << 2);

  Future<void> getCardSerialNumber() async {
    int ctx = await PcscPlatform.instance
        .establishContext(PcscConstants.CARD_SCOPE_USER);
    Map? card;
    try {
      List<String> readers = await PcscPlatform.instance.listReaders(ctx);

      if (readers.isEmpty) {
        setState(() {
          _messages.add(Message.error('Could not detect any reader'));
        });
      } else {
        String reader = readers[0];
        setState(() {
          _messages.add(Message.info('Using reader: $reader'));
        });

        card = await PcscPlatform.instance.cardConnect(ctx, reader,
            PcscConstants.SCARD_SHARE_DIRECT, PcscConstants.SCARD_PROTOCOL_ANY);

        // Send control command to the reader
        setState(() {
          _messages.add(Message.info('Sending control command to reader...'));
        });

        try {
          var controlResponse = await PcscPlatform.instance.cardControl(
            card['h_card'],
            1107299756,
            [0xE0, 0x00, 0x00, 0x21, 0x01, 0x6F],
          );

          setState(() {
            _messages.add(Message.info(
                'Control command response: ${hexDump(controlResponse)}'));
          });
        } catch (e) {
          print(e);
          setState(() {
            _messages.add(Message.error('Control command failed: $e'));
          });
        }
      }
    } finally {
      if (card != null) {
        try {
          await PcscPlatform.instance
              .cardDisconnect(card['h_card'], PcscConstants.SCARD_RESET_CARD);
        } on Exception catch (e) {
          setState(() {
            _messages.add(Message.error(e.toString()));
          });
        }
      }
      try {
        await PcscPlatform.instance.releaseContext(ctx);
      } on Exception catch (e) {
        setState(() {
          _messages.add(Message.error(e.toString()));
        });
      }
    }
  }

  static String hexDump(List<int> csn) {
    return csn
        .map((i) => i.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    TextStyle errorStyle = const TextStyle(color: Colors.red);
    WidgetsBinding.instance?.addPostFrameCallback((_) => _scrollToBottom());
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: Column(children: [
        Expanded(
            child: ListView(
                controller: _scrollController,
                children: _messages
                    .map((e) => Text(e.content,
                        style: e.type == MessageType.error ? errorStyle : null))
                    .toList())),
        Container(
            margin: const EdgeInsets.all(10),
            child: ElevatedButton(
                onPressed: () async {
                  await tryAgain();
                },
                child: const Text("Try again")))
      ]))
    ]);
  }

  tryAgain() async {
    setState(() {
      _messages.clear();
    });
    await getCardSerialNumber();
  }
}
