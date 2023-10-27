import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? path;
  img.Image? image;
  final austronautPath = 'assets/astronaut.jpg';
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    loadImageFromAssets(austronautPath);
  }

  void loadImageFromCache(String path) {
    File file = File(path);
    List<int> imageBytes = file.readAsBytesSync();
    Uint8List modifiedImageUint8List = Uint8List.fromList(imageBytes);
    img.Image? decodedImage = img.decodeImage(modifiedImageUint8List);

    if (decodedImage != null) {
      setState(() {
        image = decodedImage;
      });
    }
  }

  Future<void> loadImageFromAssets(String path) async {
    ByteData data = await rootBundle.load(path);
    Uint8List imageBytes = data.buffer.asUint8List();
    img.Image? decodedImage = img.decodeImage(imageBytes);

    setState(() {
      image = decodedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/gifs/bouncing-ball.gif'),
              //Blocking UI task
              ElevatedButton(
                onPressed: () async {
                  var total = await complexTask1();
                  debugPrint('Result 1: $total');
                },
                child: const Text('Task 1'),
              ),
              //Isolate
              ElevatedButton(
                onPressed: () async {
                  final receivePort = ReceivePort();
                  await Isolate.spawn(complexTask2, receivePort.sendPort);
                  receivePort.listen((total) {
                    debugPrint('Result 2: $total');
                  });
                },
                child: const Text('Task 2'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final Directory directory =
                      await getApplicationDocumentsDirectory();
                  final receivePort = ReceivePort();
                  await Isolate.spawn(complexTask3,
                      [receivePort.sendPort, image, directory, uuid.v4()]);
                  receivePort.listen((photoPath) {
                    setState(() {
                      path = photoPath;
                    });
                    loadImageFromCache(photoPath);
                  });
                },
                child: const Text('Task 3'),
              ),
              Expanded(
                  child: path == null
                      ? Image.asset(austronautPath)
                      : Image.file(File(path!)))
            ],
          ),
        ),
      ),
    );
  }

  Future<double> complexTask1() async {
    var total = 0.0;
    for (var i = 0; i < 1000000000; i++) {
      total += i;
    }
    return total;
  }
}

complexTask2(SendPort sendPort) {
  var total = 0.0;
  for (var i = 0; i < 1000000000; i++) {
    total += i;
  }
  sendPort.send(total);
}

void complexTask3(List<dynamic> args) async {
  SendPort sendPort = args[0];
  img.Image? image = args[1];
  Directory directory = args[2];
  String name = args[3];
  if (image != null) {
    image = img.copyRotate(image, angle: 180);
    String imagePreviewPath = p.join(directory.path, '$name.jpg');
    List<int> modifiedRotatedDecodedImage = img.encodeJpg(image);
    File(imagePreviewPath).writeAsBytesSync(modifiedRotatedDecodedImage);
    sendPort.send(imagePreviewPath);
  }
}
