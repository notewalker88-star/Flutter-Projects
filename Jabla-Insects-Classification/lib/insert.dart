import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'profile.dart';
import 'loading_screen.dart'; // Add LoadingScreen import
import 'services/database_helper.dart';
import 'insect_detail_screen.dart';

// Add permission handler
const Color kDarkBackground = Color(0xFF10091E);
const Color kPrimaryColor = Color(0xFF5D3DFD);
const Color kSecondaryColor = Color(0xFFC764FF);
const Color kAccentBorderColor = Color(0xFF332749);
const Color kTextColor = Colors.white;
const Color kLightTextColor = Color(0xFFD6D6D6);

class _ClassPercent {
  final String label;
  final double percent;
  final bool primary;
  _ClassPercent(this.label, this.percent, this.primary);
}

class _InsectImage {
  final String assetPath;
  final String label;
  _InsectImage(this.assetPath, this.label);
}

const _primaryBase = Color(0xFFFFE0B2);
const _primaryFill = Color(0xFFEF6C00);
const _barHeight = 22.0;
const _basePalette = <Color>[
  Color(0xFFFDECEF),
  Color(0xFFE7F0FF),
  Color(0xFFF5EBFF),
  Color(0xFFEFF7E8),
  Color(0xFFFFF3E0),
];
const _fillPalette = <Color>[
  Color(0xFFF8CBD1),
  Color(0xFFCDDEFF),
  Color(0xFFD8C9FF),
  Color(0xFFCFE8C6),
  Color(0xFFFFE0B2),
];
const _textPalette = <Color>[
  Color(0xFFFF6F61),
  Color(0xFF6B93F3),
  Color(0xFF8E5CF2),
  Color(0xFF5CA66F),
  Color(0xFFF98C20),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dbRef = FirebaseDatabase.instance.ref("insect_classifications");
  XFile? _pickedImage;
  String? _classificationResult;
  bool _isClassifying = false;
  tfl.Interpreter? _interpreter; // Make it nullable
  List<String> _labels = [];
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _modelLoaded = false; // Track model loading state
  List<_ClassPercent> _classConfidences = [];
  List<_InsectImage> _supportedImages = [];
  final PageController _imagesController = PageController(
    viewportFraction: 0.75,
  );
  int _currentImageIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    print('=== INITIALIZING HOME PAGE ===');
    super.initState();
    _loadModelAndLabels()
        .then((_) {
          print('Model and labels loaded');
          _initializeCamera();
          _loadSupportedImages();
          _startAutoPlay();
        })
        .catchError((error, stackTrace) {
          print('Error in initState during model loading: $error');
          print('Stack trace: $stackTrace');
        });
  }

  // Load TensorFlow Lite model and labels
  Future<void> _loadModelAndLabels() async {
    try {
      print('=== MODEL LOADING PROCESS STARTED ===');
      print('Attempting to load model from assets/tflite/model_unquant.tflite');

      // Check labels file first
      print('Loading labels from assets/tflite/labels.txt');
      final labelsFile = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/tflite/labels.txt');
      print('Labels file loaded successfully');

      // Process labels more carefully
      _labels = labelsFile.split('\n')
        ..removeWhere((element) => element.trim().isEmpty);
      print('Labels processed. Count: ${_labels.length}');

      // Print labels for debugging
      for (var i = 0; i < _labels.length; i++) {
        print('Label $i: "${_labels[i]}"');
      }

      // Try to load model with specific options to improve mobile compatibility
      print('Loading model with tflite_flutter...');
      final options = tfl.InterpreterOptions()
        ..threads = 4
        ..useNnApiForAndroid = true;

      _interpreter = await tfl.Interpreter.fromAsset(
        'assets/tflite/model_unquant.tflite',
        options: options,
      );
      print('Model loaded successfully with tflite_flutter');
      try {
        _interpreter!.allocateTensors();
        print('Interpreter tensors allocated');
      } catch (e) {
        print('Interpreter allocateTensors failed: $e');
      }

      // Get model information
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print('Input tensors count: ${inputTensors.length}');
      print('Output tensors count: ${outputTensors.length}');

      if (inputTensors.isNotEmpty) {
        final inputShape = inputTensors[0].shape;
        print('First input tensor shape: $inputShape');
        // Validate input shape
        if (inputShape.length != 4 ||
            inputShape[0] != 1 ||
            inputShape[1] != 224 ||
            inputShape[2] != 224 ||
            inputShape[3] != 3) {
          print(
            'WARNING: Unexpected input tensor shape. Expected [1, 224, 224, 3]',
          );
          print('This may cause issues with model inference.');
        }
      }

      if (outputTensors.isNotEmpty) {
        final outputShape = outputTensors[0].shape;
        print('First output tensor shape: $outputShape');

        // Validate model and labels compatibility
        if (_labels.length != outputShape.last) {
          print(
            'WARNING: Label count (${_labels.length}) does not match model output size (${outputShape.last})',
          );
        }

        // Validate output shape
        if (outputShape.length != 2 ||
            outputShape[0] != 1 ||
            outputShape[1] != _labels.length) {
          print(
            'WARNING: Unexpected output tensor shape. Expected [1, ${_labels.length}]',
          );
        }
      }

      // Print interpreter info
      print('=== INTERPRETER INFO ===');
      print('Input tensor count: ${_interpreter!.getInputTensors().length}');
      print('Output tensor count: ${_interpreter!.getOutputTensors().length}');
      if (_interpreter!.getInputTensors().isNotEmpty) {
        print(
          'Input tensor shape: ${_interpreter!.getInputTensors()[0].shape}',
        );
      }
      if (_interpreter!.getOutputTensors().isNotEmpty) {
        print(
          'Output tensor shape: ${_interpreter!.getOutputTensors()[0].shape}',
        );
      }
      print('=== END INTERPRETER INFO ===');

      print('=== MODEL AND LABELS LOADING COMPLETED SUCCESSFULLY ===');
      setState(() {
        _modelLoaded = true; // Set model loaded flag and trigger rebuild
      });
    } catch (e, stackTrace) {
      print('!!! FATAL ERROR LOADING MODEL OR LABELS: $e');
      print('Detailed error information:');
      print('- Error type: ${e.runtimeType}');
      print('- Error message: ${e.toString()}');
      print('Stack trace: $stackTrace');
      // Show error in UI
      setState(() {
        _classificationResult =
            'Model Load Error: ${e.runtimeType} - ${e.toString().substring(0, (e.toString().length < 100 ? e.toString().length : 100))}';
        _modelLoaded = true; // Set to true to show the error message in UI
      });
    }
  }

  // Retry model loading
  Future<void> _retryLoadModel() async {
    print('Retrying model loading...');
    setState(() {
      _classificationResult = null;
      _modelLoaded = false;
    });
    await _loadModelAndLabels();
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    try {
      print('Getting available cameras...');
      _cameras = await availableCameras();
      print('Available cameras count: ${_cameras?.length ?? 0}');

      if (_cameras != null && _cameras!.isNotEmpty) {
        print('Creating camera controller for camera 0...');
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );
        print('Initializing camera controller...');
        await _cameraController!.initialize();
        print('Camera controller initialized successfully');
        setState(() {});
      } else {
        print('No cameras available');
      }
    } catch (e, stackTrace) {
      print('Error initializing camera: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    print('=== PICKING IMAGE FROM GALLERY ===');
    final ImagePicker picker = ImagePicker();
    try {
      print('Requesting permission and picking image...');
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage != null) {
        print('Image picked successfully: ${pickedImage.path}');
        setState(() {
          _pickedImage = pickedImage;
          _classificationResult = null;
        });

        // Create progress notifier
        final progressNotifier = ValueNotifier<double>(0.0);

        // Show loading screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LoadingScreen(
                progressNotifier: progressNotifier,
                onCancel: () {
                  // Simply pop the loading screen; _classifyImage will likely continue
                  // or we could add a cancellation flag if strict cancellation is needed.
                  // For now, we just close the screen.
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }

        print('Starting image classification...');
        // Pass the notifier to the classification function
        final result = await _classifyImage(
          pickedImage.path,
          progressNotifier: progressNotifier,
        );

        // Pop the loading screen once classification is done
        if (mounted) {
          Navigator.of(context).pop(); // Remove LoadingScreen

          if (result != null) {
            _showSaveConfirmationDialog(result['label'], result['confidence']);
          }
        }
      } else {
        print('No image selected from gallery');
        setState(() {
          _classificationResult = 'No image selected';
        });
      }
    } catch (e, stackTrace) {
      print('Error picking image from gallery: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _classificationResult = 'Error picking image: ${e.toString()}';
      });
      // Ensure we pop loading screen if it was shown and error occurred
      // (Handling this properly would require tracking if it was pushed,
      // but simpler for now to assume it won't be lingering if we didn't push it yet or handled inside)
    }
  }

  // Capture image from camera
  Future<void> _captureImageFromCamera() async {
    print('=== CAPTURING IMAGE FROM CAMERA ===');
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        print('Taking picture...');
        final XFile picture = await _cameraController!.takePicture();
        print('Picture taken successfully: ${picture.path}');
        setState(() {
          _pickedImage = picture;
          _classificationResult = null;
        });

        // Create progress notifier
        final progressNotifier = ValueNotifier<double>(0.0);

        // Show loading screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LoadingScreen(
                progressNotifier: progressNotifier,
                onCancel: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }

        print('Starting image classification...');
        final result = await _classifyImage(
          picture.path,
          progressNotifier: progressNotifier,
        );

        // Pop the loading screen once classification is done
        if (mounted) {
          Navigator.of(context).pop(); // Remove LoadingScreen

          if (result != null) {
            _showSaveConfirmationDialog(result['label'], result['confidence']);
          }
        }
      } catch (e, stackTrace) {
        print('Error capturing image: $e');
        print('Stack trace: $stackTrace');
        setState(() {
          _classificationResult = 'Error capturing image: ${e.toString()}';
        });
      }
    } else {
      print('Camera not initialized or not available');
      setState(() {
        _classificationResult = 'Camera not available';
      });
    }
  }

  // Classify image using TensorFlow Lite model
  Future<Map<String, dynamic>?> _classifyImage(
    String imagePath, {
    ValueNotifier<double>? progressNotifier,
  }) async {
    print('=== STARTING IMAGE CLASSIFICATION PROCESS ===');
    print('Image path: $imagePath');

    // Add early debug information
    print('DEBUG: Current state before classification:');
    print('  Model loaded: $_modelLoaded');
    print('  Interpreter available: ${_interpreter != null}');
    print('  Labels count: ${_labels.length}');
    print('  Is classifying: $_isClassifying');

    // Check if model is loaded
    if (!_modelLoaded || _interpreter == null) {
      print('ERROR: Model not loaded yet. Cannot classify image.');
      setState(() {
        _classificationResult =
            'Error: Model not loaded. Please wait and try again.';
        _isClassifying = false;
      });
      return null;
    }

    setState(() {
      _isClassifying = true;
    });

    try {
      progressNotifier?.value = 0.1; // Started
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Simulate initial delay for UI

      print('Step 1: Loading image file...');
      // Load and preprocess image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }
      print('Image file exists');

      final imageBytes = await imageFile.readAsBytes();
      print(
        'Step 2: Image bytes loaded. Size: ${imageBytes.lengthInBytes} bytes',
      );

      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      progressNotifier?.value = 0.2; // Loaded bytes

      print('Step 3: Decoding image...');
      // Safely decode image and handle potential errors
      var image = img.decodeImage(imageBytes);
      if (image == null) {
        // Try different formats
        print('Primary decoding failed, trying alternative methods...');
        final imageJpg = img.decodeJpg(imageBytes);
        final imagePng = img.decodePng(imageBytes);

        if (imageJpg != null) {
          print('Successfully decoded as JPG');
          image = imageJpg;
        } else if (imagePng != null) {
          print('Successfully decoded as PNG');
          image = imagePng;
        } else {
          throw Exception(
            'Failed to decode image. Supported formats: JPEG, PNG. File may be corrupted or unsupported.',
          );
        }
      }
      print(
        'Image decoded successfully. Original size: ${image.width}x${image.height}',
      );

      print('Step 4: Resizing image to 224x224...');
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      print('Image resized successfully');

      progressNotifier?.value = 0.4; // Resized
      await Future.delayed(const Duration(milliseconds: 200));

      print('Step 5: Converting image to tensor input...');
      // Build input as a 4D List [1, 224, 224, 3] normalized to 0-1
      print('Step 6: Preparing input tensor as nested list [1,224,224,3]...');
      final input4d = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(224, (x) {
            final p = resizedImage.getPixel(x, y);
            final r = (p.r / 255.0).clamp(0.0, 1.0);
            final g = (p.g / 255.0).clamp(0.0, 1.0);
            final b = (p.b / 255.0).clamp(0.0, 1.0);
            return [r, g, b];
          }),
        ),
      );
      print('Input tensor prepared successfully. Shape: [1, 224, 224, 3]');

      // Prepare output tensor - ensure size matches model expectations
      print('Step 7: Checking labels and preparing output tensor...');
      if (_labels.isEmpty) {
        throw Exception(
          'Labels not loaded. Please check if labels.txt is properly loaded.',
        );
      }
      print('Labels available. Count: ${_labels.length}');

      // Create output tensor as [1, numLabels]
      final output2d = List.generate(
        1,
        (_) => List.filled(_labels.length, 0.0),
      );
      print('Output tensor prepared. Shape: [1, ${_labels.length}]');

      progressNotifier?.value = 0.6; // Tensor prepared

      // Run inference
      print('Step 8: Running model inference...');
      print('Checking interpreter status...');

      if (_interpreter == null) {
        throw Exception(
          'Model interpreter not initialized. Please check model loading.',
        );
      }

      print('Running inference...');
      try {
        // Run inference with proper tensor mapping
        _interpreter!.run(input4d, output2d);
        print('Model inference completed successfully');
      } catch (e) {
        print('Error during model inference: $e');
        print('Input tensor type: ${input4d.runtimeType}');
        print('Output tensor type: ${output2d.runtimeType}');
        print(
          'Output tensor shape: [${output2d.length}, ${output2d.isNotEmpty ? output2d[0].length : 0}]',
        );

        // Try to get more detailed error information
        try {
          print('Attempting to allocate tensors...');
          _interpreter!.allocateTensors();
          print('Tensors allocated successfully');
        } catch (allocError) {
          print('Tensor allocation failed: $allocError');
        }

        // Handle specific TensorFlow Lite errors
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('pad') ||
            errorMessage.contains('pool') ||
            errorMessage.contains('strided_slice') ||
            errorMessage.contains('bad state') ||
            errorMessage.contains('failed precondition')) {
          print('TensorFlow Lite compatibility error detected:');
          print(
            'This indicates the model uses operations not fully supported by the current TensorFlow Lite version.',
          );
          print('Possible solutions:');
          print(
            '1. Re-export the model with TensorFlow Lite compatible operations',
          );
          print('2. Use a quantized model version');
          print('3. Update the TensorFlow Lite Flutter plugin');

          // Show a clear error message to the user
          setState(() {
            _classificationResult =
                'Model Compatibility Error: The model uses operations not supported by this version. Contact developer for updated model.';
            _isClassifying = false;
          });

          // Save error info to Firebase for debugging
          await _saveClassificationResult('Model_Error_Compatibility', 0.0);
          return null; // Exit early since we can't proceed
        }

        rethrow;
      }

      progressNotifier?.value = 0.8; // Inference done, processing result
      await Future.delayed(const Duration(milliseconds: 300));

      // Get the predicted class
      print('Step 9: Processing predictions...');
      final predictions = output2d.first.toList();
      print('Raw predictions: $predictions');

      if (predictions.isEmpty) {
        throw Exception('Model returned empty predictions');
      }

      final maxIndex = predictions.indexOf(
        predictions.reduce((a, b) => a > b ? a : b),
      );
      final confidence = predictions[maxIndex];

      print('Max prediction index: $maxIndex, Confidence: $confidence');

      // Validate index
      if (maxIndex < 0 || maxIndex >= _labels.length) {
        throw Exception(
          'Prediction index ($maxIndex) out of bounds (0-${_labels.length - 1})',
        );
      }

      // Get label name
      final labelParts = _labels[maxIndex].split(' ');
      final label = labelParts.length > 1
          ? labelParts.sublist(1).join(' ')
          : _labels[maxIndex];
      print('Predicted label: $label');

      // Add debug information for the classification result
      print('DEBUG: Classification result details:');
      print('  Max index: $maxIndex');
      print('  Confidence: $confidence');
      print('  Label from labels list: ${_labels[maxIndex]}');
      print('  Cleaned label: $label');
      print(
        '  Formatted result: $label (${(confidence * 100).toStringAsFixed(2)}%)',
      );

      final normalized = _normalizePredictions(predictions);
      final topPercent = (normalized[maxIndex] * 100).clamp(0, 100);
      final items = <_ClassPercent>[];
      if (topPercent >= 99.5) {
        for (var i = 0; i < _labels.length; i++) {
          final lParts = _labels[i].split(' ');
          final l = lParts.length > 1
              ? lParts.sublist(1).join(' ')
              : _labels[i];
          final p = i == maxIndex ? 100.0 : 0.0;
          items.add(_ClassPercent(l, p, i == maxIndex));
        }
      } else {
        for (var i = 0; i < _labels.length; i++) {
          final lParts = _labels[i].split(' ');
          final l = lParts.length > 1
              ? lParts.sublist(1).join(' ')
              : _labels[i];
          final p = (normalized[i] * 100);
          items.add(_ClassPercent(l, p, i == maxIndex));
        }
      }
      final filteredItems = items.where((e) => e.percent > 0.0).toList();

      setState(() {
        _classificationResult =
            '$label (${(confidence * 100).toStringAsFixed(2)}%)';
        print('Final result set in UI: $_classificationResult');
        _isClassifying = false;
        _classConfidences = filteredItems;
      });

      // Save result to Firebase (Moved to confirmation dialog)
      // Save result to Firebase (Moved to confirmation dialog)
      print('Step 10: Returning result for confirmation dialog...');
      progressNotifier?.value = 0.95; // Finishing up

      // Return result map instead of showing dialog directly
      // if (mounted) {
      //   _showSaveConfirmationDialog(label, confidence);
      // }

      progressNotifier?.value = 1.0; // Done
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Short pause at 100%
      print('Result return prepared');

      print('=== IMAGE CLASSIFICATION COMPLETED SUCCESSFULLY ===');
      print('FINAL RESULT: $_classificationResult');

      return {'label': label, 'confidence': confidence};
    } catch (e, stackTrace) {
      print('!!! ERROR DURING IMAGE CLASSIFICATION: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _classificationResult = 'Classification Error: ${e.toString()}';
        _isClassifying = false;
      });
      return null;
    }
  }

  List<double> _normalizePredictions(List<double> values) {
    final adjusted = values.map((v) => v.isFinite ? v : 0.0).toList();
    final maxV = adjusted.reduce((a, b) => a > b ? a : b);
    final minV = adjusted.reduce((a, b) => a < b ? a : b);
    var areLogits = false;
    if (maxV > 1.0 || minV < 0.0) {
      areLogits = true;
    }
    if (areLogits) {
      final exps = adjusted.map((v) => math.exp(v - maxV)).toList();
      final sumE = exps.fold(0.0, (s, v) => s + v);
      return exps.map((e) => e / (sumE == 0 ? 1 : sumE)).toList();
    } else {
      var sum = adjusted.fold(0.0, (s, v) => s + v);
      if (sum <= 0.0) sum = 1.0;
      return adjusted.map((v) => v / sum).toList();
    }
  }

  // Save classification result to Firebase
  Future<void> _saveClassificationResult(
    String label,
    double confidence,
  ) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      // Save to Firebase
      await dbRef.push().set({
        'label': label,
        'confidence': confidence.toStringAsFixed(4),
        'timestamp': timestamp,
      });

      // Save to local database
      final dbHelper = DatabaseHelper();
      await dbHelper.insertClassification({
        'label': label,
        'confidence': confidence,
        'imagePath': _pickedImage?.path ?? '',
        'timestamp': timestamp,
      });
      print('Result saved to Firebase and local database successfully');
    } catch (e) {
      print('Error saving to storage: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Save Error'),
            content: Text(
              'Failed to save result: $e\n\nEnsure you are connected to the internet and authenticated.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Show Confirmation Dialog
  Future<void> _showSaveConfirmationDialog(
    String label,
    double confidence,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1436), // Match app theme
          title: const Text(
            'Save to Database?',
            style: TextStyle(color: kTextColor),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Detected: $label',
                  style: const TextStyle(color: kTextColor),
                ),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: kLightTextColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Do you want to save this result to your history?',
                  style: TextStyle(color: kTextColor),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: kLightTextColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: kPrimaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
                _saveClassificationResult(label, confidence);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _imagesController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        backgroundColor: kDarkBackground,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bug_report, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              'Insect Identifier',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      // Fixed bottom navigation and center-focused camera button
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1C132E),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.image_outlined, size: 28),
              color: kTextColor,
              onPressed: _modelLoaded ? _pickImageFromGallery : null,
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 28),
              color: kTextColor,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [kSecondaryColor, kPrimaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.camera_alt_outlined,
            color: kTextColor,
            size: 30,
          ),
          onPressed: _modelLoaded ? _captureImageFromCamera : null,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.5),
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kSecondaryColor, kDarkBackground],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Insect\n',
                              style: TextStyle(color: kTextColor),
                            ),
                            TextSpan(
                              text: 'Classification\nProcess',
                              style: TextStyle(color: kPrimaryColor),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Use your camera or gallery to identify insects.',
                        style: TextStyle(color: kLightTextColor, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_modelLoaded)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1436),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    if (_classificationResult != null &&
                        _classificationResult!.contains('Error'))
                      Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 10),
                          Text(
                            _classificationResult!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _retryLoadModel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: kTextColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Retry Loading Model'),
                          ),
                        ],
                      )
                    else
                      const Column(
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            color: kTextColor,
                            size: 60,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Loading model...',
                            style: TextStyle(
                              fontSize: 16,
                              color: kPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'This may take a moment on first launch',
                            style: TextStyle(
                              fontSize: 12,
                              color: kLightTextColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: kDarkBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccentBorderColor, width: 2),
              ),
              child: Column(
                children: [
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kAccentBorderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CameraPreview(_cameraController!),
                    )
                  else
                    const SizedBox(),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _pickedImage != null
                        ? Container(
                            key: const ValueKey('imageSelected'),
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kAccentBorderColor),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.contain,
                            ),
                          )
                        : Container(
                            key: const ValueKey('imagePlaceholder'),
                            height: 200,
                            alignment: Alignment.center,
                            child: CustomPaint(
                              painter: _DashedBorderPainter(color: kTextColor),
                              child: SizedBox.expand(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      color: kTextColor,
                                      size: 60,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'No image selected',
                                      style: TextStyle(
                                        color: kLightTextColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Upload an image to start the classification process',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: kTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: const [
                Icon(Icons.grid_view_outlined, color: kPrimaryColor),
                SizedBox(width: 8),
                Text(
                  'Classification Result',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1436),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _isClassifying
                  ? Column(
                      children: const [
                        Icon(
                          Icons.manage_search_rounded,
                          color: kTextColor,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Awaiting analysis...',
                          style: TextStyle(color: kTextColor, fontSize: 16),
                        ),
                      ],
                    )
                  : (_classConfidences.isNotEmpty
                        ? Column(
                            children: _classConfidences.map<Widget>((
                              _ClassPercent item,
                            ) {
                              final idx =
                                  item.label.hashCode.abs() %
                                  _basePalette.length;
                              final baseColor = item.primary
                                  ? _primaryBase
                                  : _basePalette[idx];
                              final bgColor = item.primary
                                  ? _primaryFill
                                  : _fillPalette[idx];
                              final textColor = item.primary
                                  ? _textPalette.last
                                  : _textPalette[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    final assetPath = _getAssetPathForLabel(
                                      item.label,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => InsectDetailScreen(
                                          label: item.label,
                                          assetPath: assetPath,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 96,
                                        child: Text(
                                          item.label.length > 7
                                              ? '${item.label.substring(0, 7)}...'
                                              : item.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.primary
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.centerRight,
                                          children: [
                                            Container(
                                              height: _barHeight,
                                              decoration: BoxDecoration(
                                                color: baseColor,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: (item.percent / 100)
                                                  .clamp(0.0, 1.0),
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                height: _barHeight,
                                                decoration: BoxDecoration(
                                                  color: bgColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                '${item.percent.round()}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: item.primary
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : const Text(
                            'No classification yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: kLightTextColor,
                            ),
                          )),
            ),
            const SizedBox(height: 30),
            if (_supportedImages.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1436),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported Insects:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: _imagesController,
                        itemCount: _supportedImages.length,
                        onPageChanged: (i) {
                          setState(() {
                            _currentImageIndex = i;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = _supportedImages[index];
                          return AnimatedBuilder(
                            animation: _imagesController,
                            builder: (context, child) {
                              final page = _imagesController.hasClients
                                  ? (_imagesController.page ??
                                        _imagesController.initialPage
                                            .toDouble())
                                  : 0.0;
                              final dist = (index - page).abs();
                              final scale =
                                  (1 - dist).clamp(0.0, 1.0) * 0.1 + 0.9;
                              final opacity = (1 - dist).clamp(0.4, 1.0);
                              return Center(
                                child: Opacity(
                                  opacity: opacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        print('Tapped on ${item.label}');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => InsectDetailScreen(
                                              label: item.label,
                                              assetPath: item.assetPath,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: 140,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                if (index == _currentImageIndex)
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                              ],
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Image.asset(
                                              item.assetPath,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: kTextColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSupportedImages() async {
    try {
      final manifest = await DefaultAssetBundle.of(
        context,
      ).loadString('AssetManifest.json');
      final data = jsonDecode(manifest) as Map<String, dynamic>;
      final keys = data.keys
          .where((k) => k.startsWith('assets/images/'))
          .toList();
      final items = <_InsectImage>[];
      for (final k in keys) {
        final name = k.split('/').last.split('.').first;
        final label = name.replaceAll('_', ' ');
        items.add(_InsectImage(k, _titleCase(label)));
      }
      setState(() {
        _supportedImages = items;
      });
    } catch (e) {
      print('Error loading supported images: $e');
    }
  }

  String _titleCase(String s) {
    final parts = s.split(' ');
    return parts
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_imagesController.hasClients || _supportedImages.isEmpty) return;
      final next = (_currentImageIndex + 1) % _supportedImages.length;
      _imagesController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  String? _getAssetPathForLabel(String label) {
    try {
      final cleanLabel = label.replaceAll(RegExp(r'^\d+\s*'), '');
      final image = _supportedImages.firstWhere(
        (img) => img.label.toLowerCase() == cleanLabel.toLowerCase(),
      );
      return image.assetPath;
    } catch (e) {
      return null;
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth = 2.0;
  final double dashLength = 8.0;
  final double dashGap = 6.0;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _drawDashedLine(
      canvas,
      paint,
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.top),
    );
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const epsilon = 0.0001;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final direction = Offset(
      dx / (distance + epsilon),
      dy / (distance + epsilon),
    );
    double traveled = 0.0;
    while (traveled < distance) {
      final currentDash = math.min(dashLength, distance - traveled);
      final p1 = start + direction * traveled;
      final p2 = start + direction * (traveled + currentDash);
      canvas.drawLine(p1, p2, paint);
      traveled += currentDash + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap;
  }
}

class AccurateResultScreen extends StatelessWidget {
  final String? classificationResult;
  final List<Map<String, Object>> classData;
  const AccurateResultScreen({
    super.key,
    this.classificationResult,
    this.classData = const [],
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = classData
        .where((e) => ((e['percent'] as num?)?.toDouble() ?? 0.0) > 0)
        .toList();
    Map<String, Object>? top;
    if (nonZero.isNotEmpty) {
      top = nonZero.reduce((a, b) {
        final ap = (a['percent'] as num?)?.toDouble() ?? 0.0;
        final bp = (b['percent'] as num?)?.toDouble() ?? 0.0;
        return ap >= bp ? a : b;
      });
    }
    String label = '';
    String percentText = '';
    if (top != null) {
      final p = (top['percent'] as num?)?.toDouble() ?? 0.0;
      label = (top['label'] as String?) ?? '';
      percentText = '${p.toStringAsFixed(2)}%';
    } else if (classificationResult != null &&
        classificationResult!.contains('(')) {
      final parts = classificationResult!.split('(');
      label = parts.first.trim().replaceAll(RegExp(r'^\d+\s*'), '');
      percentText = parts.last.replaceAll(')', '').trim();
    }
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        backgroundColor: kDarkBackground,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bug_report, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              'Insect Identifier',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1436),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: kPrimaryColor, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    label.isEmpty ? 'No result yet' : label,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (percentText.isNotEmpty)
                    _PercentBar(
                      percent:
                          double.tryParse(percentText.replaceAll('%', '')) ??
                          0.0,
                      highlight: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (nonZero.length > 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1436),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list, color: kPrimaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Top Classes',
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...nonZero
                        .sortedByPercentDesc()
                        .take(3)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _PercentBar(
                              label: (e['label'] as String?) ?? '',
                              percent:
                                  (e['percent'] as num?)?.toDouble() ?? 0.0,
                              highlight: false,
                            ),
                          ),
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

class GraphScreen extends StatelessWidget {
  final List<Map<String, Object>> classData;
  const GraphScreen({super.key, this.classData = const []});

  @override
  Widget build(BuildContext context) {
    final nonZero = classData
        .where((e) => ((e['percent'] as num?)?.toDouble() ?? 0.0) > 0)
        .toList();
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        backgroundColor: kDarkBackground,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bug_report, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              'Insect Identifier',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: nonZero.isEmpty
            ? const Center(
                child: Text(
                  'No classification yet',
                  style: TextStyle(color: kLightTextColor),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Confidence Graph',
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: nonZero.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = nonZero[index];
                        final label = (item['label'] as String?) ?? '';
                        final percent =
                            (item['percent'] as num?)?.toDouble() ?? 0.0;
                        final primary = (item['primary'] as bool?) ?? false;
                        final idx = label.hashCode.abs() % _basePalette.length;
                        final baseColor = primary
                            ? _primaryBase
                            : _basePalette[idx];
                        final bgColor = primary
                            ? _primaryFill
                            : _fillPalette[idx];
                        final textColor = primary
                            ? _textPalette.last
                            : _textPalette[idx];
                        return Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: primary
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  Container(
                                    height: _barHeight,
                                    decoration: BoxDecoration(
                                      color: baseColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: (percent / 100).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: _barHeight,
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '${percent.round()}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primary
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class InsectClassesScreen extends StatefulWidget {
  final List<Map<String, String>> images;
  final List<Map<String, Object>>? classData;
  const InsectClassesScreen({
    super.key,
    this.images = const [],
    this.classData,
  });

  @override
  State<InsectClassesScreen> createState() => _InsectClassesScreenState();
}

class _InsectClassesScreenState extends State<InsectClassesScreen> {
  late final PageController _controller;
  int _currentIndex = 0;
  String? _topLabel;
  static const Map<String, String> _insectDescriptions = {
    'Beetle':
        'Beetles have hard protective wings and are commonly found on plants and soil. They help maintain ecological balance.',
    'Fly':
        'Flies are small, fast-moving insects often found near food and waste. Some species can spread diseases.',
    'Butterfly':
        'Butterflies are colorful insects that feed on nectar and help plants reproduce through pollination.',
    'Bee':
        'Bees collect nectar and pollen from flowers and play a crucial role in pollination and food production.',
    'Dragonfly':
        'Dragonflies are fast-flying insects found near water and help control mosquito populations.',
    'Grasshopper':
        'Grasshoppers are plant-eating insects known for their strong legs used for jumping.',
    'Ladybug':
        'Ladybugs are small beetles that feed on plant pests, making them beneficial to crops.',
    'Mosquito':
        'Mosquitoes are small insects that feed on blood and can transmit diseases.',
    'Spider':
        'Spiders are eight-legged creatures that hunt insects and help control pest populations.',
    'Wasp':
        'Wasps are stinging insects that help control pests and assist in pollination.',
  };
  static const Map<String, String> _insectEmojis = {
    'Beetle': '🪲',
    'Fly': '🪰',
    'Butterfly': '🦋',
    'Bee': '🐝',
    'Dragonfly': '🪲',
    'Grasshopper': '🦗',
    'Ladybug': '🐞',
    'Mosquito': '🦟',
    'Spider': '🕷️',
    'Wasp': '🐝',
  };

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.75);
    if (widget.classData != null && widget.classData!.isNotEmpty) {
      final primary = widget.classData!.firstWhere(
        (e) => (e['primary'] as bool?) == true,
        orElse: () => {},
      );
      if (primary.isNotEmpty) {
        _topLabel = (primary['label'] as String?) ?? _topLabel;
      } else {
        final top = widget.classData!.reduce((a, b) {
          final ap = (a['percent'] as num?)?.toDouble() ?? 0.0;
          final bp = (b['percent'] as num?)?.toDouble() ?? 0.0;
          return ap >= bp ? a : b;
        });
        _topLabel = (top['label'] as String?) ?? _topLabel;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        backgroundColor: kDarkBackground,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bug_report, color: kPrimaryColor, size: 28),
            SizedBox(width: 8),
            Text(
              'InsectID',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child:
            widget.images
                .where((e) => _insectDescriptions.containsKey(e['label'] ?? ''))
                .isEmpty
            ? const Center(
                child: Text(
                  'No images found',
                  style: TextStyle(color: kLightTextColor),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.grid_view, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Supported Insects',
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.images
                          .where(
                            (e) => _insectDescriptions.containsKey(
                              e['label'] ?? '',
                            ),
                          )
                          .length,
                      onPageChanged: (i) => setState(() => _currentIndex = i),
                      itemBuilder: (context, index) {
                        final filtered = widget.images
                            .where(
                              (e) => _insectDescriptions.containsKey(
                                e['label'] ?? '',
                              ),
                            )
                            .toList();
                        final item = filtered[index];
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final page = _controller.hasClients
                                ? (_controller.page ??
                                      _controller.initialPage.toDouble())
                                : 0.0;
                            final dist = (index - page).abs();
                            final scale =
                                (1 - dist).clamp(0.0, 1.0) * 0.1 + 0.9;
                            final opacity = (1 - dist).clamp(0.4, 1.0);
                            return Center(
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: scale,
                                  child: InkWell(
                                    onTap: () {
                                      final label = item['label'] ?? '';
                                      final desc = _insectDescriptions[label];
                                      if (desc == null) return;
                                      final emoji = _insectEmojis[label] ?? '';
                                      _showInsectDescription(
                                        context,
                                        label,
                                        desc,
                                        emoji: emoji,
                                        topLabel: _topLabel,
                                        assetPath: item['assetPath'] ?? '',
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 180,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              if (index == _currentIndex)
                                                const BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 12,
                                                  offset: Offset(0, 6),
                                                ),
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.asset(
                                            item['assetPath'] ?? '',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          item['label'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: kTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  final String? label;
  final double percent;
  final bool highlight;
  const _PercentBar({
    this.label,
    required this.percent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final idx = (label ?? 'x').hashCode.abs() % _basePalette.length;
    final baseColor = highlight ? _primaryBase : _basePalette[idx];
    final fillColor = highlight ? _primaryFill : _fillPalette[idx];
    final textColor = highlight ? _textPalette.last : _textPalette[idx];
    return Row(
      children: [
        if (label != null)
          SizedBox(
            width: 120,
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (label != null) const SizedBox(width: 10),
        Expanded(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${percent.round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: highlight ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension _SortExt on List<Map<String, Object>> {
  List<Map<String, Object>> sortedByPercentDesc() {
    final copy = List<Map<String, Object>>.from(this);
    copy.sort((a, b) {
      final ap = (a['percent'] as num?)?.toDouble() ?? 0.0;
      final bp = (b['percent'] as num?)?.toDouble() ?? 0.0;
      return bp.compareTo(ap);
    });
    return copy;
  }
}

void _showInsectDescription(
  BuildContext context,
  String label,
  String description, {
  String? emoji,
  String? topLabel,
  String? assetPath,
}) {
  showGeneralDialog(
    context: context,
    barrierLabel: 'insect_description',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim, secondary) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondary, child) {
      final t = Curves.easeOut.transform(anim.value);
      final media = MediaQuery.of(ctx).size;
      final maxW = media.width * 0.85;
      final maxH = media.height * 0.85;
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
            ),
          ),
          Center(
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.92 + 0.08 * t,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        if ((assetPath ?? '').isNotEmpty)
                          Positioned.fill(
                            child: Image.asset(assetPath!, fit: BoxFit.cover),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.50),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.10),
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.10),
                                    ],
                                    stops: const [0.0, 0.12, 0.88, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.08),
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.08),
                                    ],
                                    stops: const [0.0, 0.10, 0.90, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if ((emoji ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Builder(
                                        builder: (context) {
                                          final isPrimary =
                                              topLabel != null &&
                                              topLabel == label;
                                          final idx =
                                              label.hashCode.abs() %
                                              _basePalette.length;
                                          final bg = isPrimary
                                              ? _primaryBase.withValues(
                                                  alpha: 0.35,
                                                )
                                              : _basePalette[idx].withValues(
                                                  alpha: 0.25,
                                                );
                                          final border = isPrimary
                                              ? _primaryFill
                                              : _fillPalette[idx];
                                          final chip = Container(
                                            width: isPrimary ? 32 : 28,
                                            height: isPrimary ? 32 : 28,
                                            decoration: BoxDecoration(
                                              color: bg,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: border,
                                                width: 1,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              emoji!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          );
                                          return isPrimary
                                              ? TweenAnimationBuilder<double>(
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ),
                                                  duration: const Duration(
                                                    milliseconds: 220,
                                                  ),
                                                  curve: Interval(
                                                    0.18,
                                                    1.0,
                                                    curve: Curves.easeOut,
                                                  ),
                                                  builder:
                                                      (context, tt, child) {
                                                        final scale =
                                                            0.85 + 0.15 * tt;
                                                        final opacity = tt;
                                                        return Opacity(
                                                          opacity: opacity,
                                                          child:
                                                              Transform.scale(
                                                                scale: scale,
                                                                child: child,
                                                              ),
                                                        );
                                                      },
                                                  child: chip,
                                                )
                                              : chip;
                                        },
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
