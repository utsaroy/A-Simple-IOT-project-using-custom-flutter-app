import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:simple_iot/firebase_options.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Simple IOT Project'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool lightState = false;
  bool _speechEnabled = false;

  final _firebaseRef = FirebaseDatabase.instance.ref("light");

  final FlutterTts flutterTts = FlutterTts();

  _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  //speech to text functions
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  bool _listening = false;
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    // setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    // print("Started Listening\n");
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _listening = true;
    });
  }

  void _stopListening() async {
    // print("Stopped Listening");
    await _speechToText.stop();
    setState(() {
      _listening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // setState(() {
    //   _lastWords = result.recognizedWords;
    // });
    _lastWords = result.recognizedWords;
    // print(_lastWords);
    if (_lastWords.toLowerCase().contains("turn on") && !lightState) {
      _speak("Turning on the light.");
      _lastWords = "";
      updataData();
      _stopListening();
    } else if (_lastWords.toLowerCase().contains("turn off") && lightState) {
      _speak("Turning off the light");
      _lastWords = "";
      updataData();
      _stopListening();
    }
  }

  void updataData() async {
    _firebaseRef.update({"state": lightState ? 0 : 1});

    setState(() {
      lightState = !lightState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: StreamBuilder(
          stream: _firebaseRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                !snapshot.hasError &&
                snapshot.data != null) {
              if (snapshot.data?.snapshot.child("state").value == 0) {
                lightState = false;
              } else {
                lightState = true;
              }
              return Center(
                  child: GestureDetector(
                onTap: () {
                  updataData();
                },
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                      color: lightState ? Colors.green : Colors.blueGrey,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(200))),
                  child: Center(
                      child: Text(
                    lightState ? "ON" : "OFF",
                    style: const TextStyle(fontSize: 50, color: Colors.amber),
                  )),
                ),
              ));
            } else {
              return const Center(
                child: Text("Getting Data"),
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_listening) {
            _stopListening();
          } else {
            _startListening();
          }
        },
        child: Icon(_listening ? Icons.stop : Icons.mic),
      ),
    );
  }
}
