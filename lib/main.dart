import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop and Trim Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  late String inputPath;
  VideoPlayerController? controller;
  String outputPath = "";
  
  @override
  void initState() {
    super.initState();
    copyVideoToApplicationDirectory().then((path) async {
      inputPath = path;
      controller = VideoPlayerController.file(File(inputPath));
      await controller?.initialize();
      await controller?.play();
      setState(() {});
      outputPath = await getOutputPath();
    });
  }

  ///Copy input file to ApplicationStorage Directory
  ///returns path to copied video
  Future<String> copyVideoToApplicationDirectory() async {
    const filename = "file1.mp4";
    var bytes = await rootBundle.load("assets/file1.mp4");
    String dir = (await getApplicationDocumentsDirectory()).path;
    writeToFile(bytes, '$dir/$filename');

    return '$dir/$filename';
  }

  /// Output path with a file name where the result will be stored.
  Future<String> getOutputPath() async {
    final appDirectory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final externalPath = '${appDirectory?.path}/out_file.mp4';
    return externalPath;
  }

  Future<void> ffmpegExecute(String command) async {

    final session = await FFmpegKit.execute(command);

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {

      print("Success");
      //Replace the preview video
      await controller?.pause();
      await controller?.dispose();
      controller = VideoPlayerController.file(File(outputPath));
      await controller?.initialize();
      await controller?.play();
      setState(() {});

    } else if (ReturnCode.isCancel(returnCode)) {

      print("Cancel");

    } else {

      print("Error");
      final failStackTrace = await session.getFailStackTrace();
      print(failStackTrace);
      List<Log> logs = await session.getLogs();
      for (var element in logs) {
        print(element.getMessage());
      }

    }
  }

  ///Write to Path.
  Future<void> writeToFile(data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     body: Column(
       children: [
         (controller != null)
             ? AspectRatio(
             aspectRatio: controller!.value.aspectRatio,
             child: VideoPlayer(controller!))
             : const SizedBox(),
       ],
     ),
   );
  }
}

