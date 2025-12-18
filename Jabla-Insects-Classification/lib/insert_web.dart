import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePage> {
  final dbRef = FirebaseDatabase.instance.ref("insect_classifications");
  Uint8List? _pickedImageBytes;
  String? _classificationResult;
  bool _isClassifying = false;
  List<String> _labels = [];
  bool _assetsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsLoaded) {
      _loadLabels();
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsFile =
          await DefaultAssetBundle.of(context).loadString('assets/tflite/labels.txt');
      _labels = labelsFile
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();
      setState(() {
        _assetsLoaded = true;
      });
    } catch (e) {
      setState(() {
        _classificationResult = 'Error loading labels: $e';
        _assetsLoaded = true;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        final bytes = await pickedImage.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _classificationResult = null;
        });
        await _classifyDemo(bytes.length);
      } else {
        setState(() {
          _classificationResult = 'No image selected';
        });
      }
    } catch (e) {
      setState(() {
        _classificationResult = 'Error picking image: $e';
      });
    }
  }

  Future<void> _classifyDemo(int sizeHint) async {
    if (_labels.isEmpty) {
      setState(() {
        _classificationResult = 'Labels not loaded';
      });
      return;
    }
    setState(() {
      _isClassifying = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final index = sizeHint % _labels.length;
    final cleanLabel = _labels[index].split(' ').length > 1
        ? _labels[index].split(' ').sublist(1).join(' ')
        : _labels[index];
    final confidence = ((sizeHint % 100) / 100.0).clamp(0.15, 0.95);

    setState(() {
      _classificationResult = '[Demo] $cleanLabel (${(confidence * 100).toStringAsFixed(2)}%)';
      _isClassifying = false;
    });

    try {
      await dbRef.push().set({
        'label': '[Demo] $cleanLabel',
        'confidence': confidence.toStringAsFixed(4),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'web-demo',
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Insect Classification"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Insect Classification (Web Demo)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TensorFlow Lite (dart:ffi) is not supported on web.\n'
                'This web build provides a demo flow so the app runs on Chrome.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _assetsLoaded ? _pickImageFromGallery : null,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Pick Image', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.grey[200],
              ),
              child: _pickedImageBytes != null
                  ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                  : const Center(child: Text('No image selected')),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Classification Result:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_isClassifying)
                    const Center(child: CircularProgressIndicator())
                  else if (_classificationResult != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _classificationResult!,
                          style: TextStyle(
                            fontSize: 16,
                            color: _classificationResult!.contains('Error') ? Colors.red : Colors.orange,
                          ),
                        ),
                        if (_classificationResult!.contains('[Demo]'))
                          const Text(
                            'NOTE: This is a demonstration result on web',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    )
                  else
                    const Text(
                      'No classification yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_labels.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported Insects:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _labels.map((label) {
                        final cleanLabel =
                            label.split(' ').length > 1 ? label.split(' ').sublist(1).join(' ') : label;
                        return Chip(
                          label: Text(cleanLabel),
                          backgroundColor: Colors.green[100],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

