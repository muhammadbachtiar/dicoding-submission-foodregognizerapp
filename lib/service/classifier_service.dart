import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../model/classification_result.dart';

class ClassifierService {
  static Uint8List? _modelBytes;
  static List<String> _labels = [];

  static Future<void> initialize() async {
    final modelData = await rootBundle.load('assets/model.tflite');
    _modelBytes = modelData.buffer.asUint8List();

    // Priority 1: load from assets/labels.txt
    try {
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      return;
    } catch (_) {}

    // Priority 2: extract labels embedded inside model metadata (zip format)
    _labels = _extractLabelsFromModelBytes(_modelBytes!);
  }

  static List<String> _extractLabelsFromModelBytes(Uint8List bytes) {
    try {
      // TFLite models with metadata have a zip file appended to the flatbuffer.
      // Find the End of Central Directory (EOCD) signature: PK 05 06
      int eocdOffset = -1;
      for (int i = bytes.length - 22; i >= 0; i--) {
        if (bytes[i] == 0x50 && bytes[i + 1] == 0x4B &&
            bytes[i + 2] == 0x05 && bytes[i + 3] == 0x06) {
          eocdOffset = i;
          break;
        }
      }
      if (eocdOffset == -1) return [];

      // Read central directory start offset (4 bytes at EOCD+16)
      final bd = ByteData.sublistView(bytes, eocdOffset + 16, eocdOffset + 20);
      final cdOffset = bd.getUint32(0, Endian.little);

      // Find first local file header (PK 03 04) before central directory
      int zipStart = -1;
      for (int i = cdOffset; i >= 0; i--) {
        if (bytes[i] == 0x50 && bytes[i + 1] == 0x4B &&
            bytes[i + 2] == 0x03 && bytes[i + 3] == 0x04) {
          zipStart = i;
          break;
        }
      }
      if (zipStart == -1) return [];

      final zipBytes = bytes.sublist(zipStart).toList();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final file in archive) {
        if (!file.isFile) continue;
        final content = String.fromCharCodes(file.content as List<int>);
        final lines = content.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (lines.length > 50) return lines; // likely a labels file
      }
    } catch (_) {}

    return [];
  }

  static Future<List<ClassificationResult>> classify(String imagePath) async {
    assert(_modelBytes != null, 'Call initialize() before classify()');
    return compute(_runInference, {
      'imagePath': imagePath,
      'modelBytes': _modelBytes!,
      'labels': _labels,
    });
  }
}

List<ClassificationResult> _runInference(Map<String, dynamic> args) {
  final imagePath = args['imagePath'] as String;
  final modelBytes = args['modelBytes'] as Uint8List;
  final labels = args['labels'] as List<String>;

  final imageBytes = File(imagePath).readAsBytesSync();
  final decoded = img.decodeImage(imageBytes)!;
  final resized = img.copyResize(decoded, width: 224, height: 224);

  final interpreter = Interpreter.fromBuffer(modelBytes);
  final inputType  = interpreter.getInputTensor(0).type.toString().toLowerCase();
  final outputType = interpreter.getOutputTensor(0).type.toString().toLowerCase();
  final numClasses = interpreter.getOutputTensor(0).shape[1];

  // --- Build input tensor ---
  Object input;
  if (inputType.contains('uint8') || inputType.contains('int8')) {
    final buf = Uint8List(224 * 224 * 3);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = resized.getPixel(x, y);
        buf[idx++] = p.r.toInt().clamp(0, 255);
        buf[idx++] = p.g.toInt().clamp(0, 255);
        buf[idx++] = p.b.toInt().clamp(0, 255);
      }
    }
    input = buf.reshape([1, 224, 224, 3]);
  } else {
    final buf = Float32List(224 * 224 * 3);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = resized.getPixel(x, y);
        buf[idx++] = p.r / 255.0;
        buf[idx++] = p.g / 255.0;
        buf[idx++] = p.b / 255.0;
      }
    }
    input = buf.reshape([1, 224, 224, 3]);
  }

  // --- Build output tensor & run ---
  List<double> scores;

  if (outputType.contains('uint8') || outputType.contains('int8')) {
    var output = List.generate(1, (i) => List.filled(numClasses, 0));

    interpreter.run(input, output);
    interpreter.close();
    
    scores = output[0].map((e) => e / 255.0).toList();

  } else {
    var output = List.generate(1, (i) => List.filled(numClasses, 0.0));

    interpreter.run(input, output);
    interpreter.close();
    
    scores = output[0];
  }

  // Return top-5
  final indexed = List.generate(scores.length, (i) => MapEntry(i, scores[i]));
  indexed.sort((a, b) => b.value.compareTo(a.value));

  return indexed.take(5).map((e) {
    final label = e.key < labels.length ? labels[e.key] : 'Food_${e.key}';
    return ClassificationResult(label: label, confidence: e.value);
  }).toList();
}
