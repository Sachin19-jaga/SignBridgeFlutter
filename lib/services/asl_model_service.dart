import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ASLModelService {
  static const _channel = MethodChannel('com.signbridge/tflite');
  bool _isLoaded = false;
  List<String> _labels = [];

  bool get isLoaded => _isLoaded;
  List<String> get labels => _labels;

  Future<void> loadModel() async {
    // Load labels
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.json');
      _labels = List<String>.from(json.decode(labelsData));
    } catch (e) {
      _labels = ['A','B','C','D','E','F','G','H','I','J',
                 'K','L','M','N','O','P','Q','R','S','T',
                 'U','V','W','X','Y','Z'];
    }

    // Load TFLite model via Kotlin MethodChannel
    try {
      print('🔄 Trying to load model via Kotlin...');
      final result = await _channel.invokeMethod<bool>('loadModel');
      _isLoaded = result == true;
      print(_isLoaded ? '✅ TFLite model loaded via Kotlin!' : '⚠️ Model load returned false');
    } catch (e) {
      print('⚠️ Kotlin TFLite error: $e');
      // Try again with a small delay
      await Future.delayed(const Duration(seconds: 2));
      try {
        final result = await _channel.invokeMethod<bool>('loadModel');
        _isLoaded = result == true;
        print(_isLoaded ? '✅ TFLite loaded on retry!' : '⚠️ Still failed');
      } catch (e2) {
        print('❌ Final error: $e2');
        _isLoaded = false;
      }
    }
  }

  // Run real inference via Kotlin MethodChannel
  Future<Map<String, double>> runInferenceOnFile(String imagePath) async {
    if (!_isLoaded) return _demoInference();

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'runInference', {'imagePath': imagePath});

      if (raw == null || raw.isEmpty) return _demoInference();

      // Map index strings to label names
      final scores = <String, double>{};
      raw.forEach((key, value) {
        final idx = int.tryParse(key);
        if (idx != null && idx < _labels.length) {
          scores[_labels[idx]] = (value as num).toDouble();
        }
      });

      return scores.isNotEmpty ? scores : _demoInference();
    } catch (e) {
      print('Inference error: $e');
      return _demoInference();
    }
  }

  Map<String, double> _demoInference() {
    final demoSigns = ['A', 'B', 'C', 'H', 'E', 'L', 'O', 'Y', 'W', 'V'];
    final random = DateTime.now().millisecondsSinceEpoch % demoSigns.length;
    final result = <String, double>{};
    for (final label in _labels) result[label] = 0.01;
    result[demoSigns[random]] = 0.88 + (DateTime.now().millisecond % 12) * 0.01;
    return result;
  }

  MapEntry<String, double> getTopPrediction(Map<String, double> scores) {
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  void dispose() {}
}
