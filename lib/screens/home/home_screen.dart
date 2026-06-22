import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

import '../../services/camera_service.dart';
import '../../services/database_service.dart';
import '../../services/face_detection_mlkit_service.dart';
import '../../services/model_service.dart';
import '../../services/mood_record.dart';
import 'widgets/save_mood_details_sheet.dart';
import 'widgets/result_card.dart';
import 'widgets/prediction_status.dart';
import 'widgets/bottom_controls.dart';
import 'widgets/camera_section.dart';
import 'widgets/emotion_palette_card.dart';
import 'widgets/tips_start_app.dart';
import 'widgets/more_info_save_to_stats_buttons.dart';


/// Main application screen responsible for:
/// - camera interaction,
/// - face detection,
/// - emotion prediction,
/// - result visualization,
/// - mood record storage.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Coordinates the complete Face2Mood workflow:
/// Camera → Face Detection → Emotion Recognition → Statistics Storage.
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin  {

  @override
  bool get wantKeepAlive => true;

  CameraController? _controller;
  bool _isCameraInitialized = false;


  // Core services used by the Home screen.
  final EmotionModelService _emotionModelService = EmotionModelService();  // class of model_service.dart
  final FaceDetectionService _faceDetectionService = FaceDetectionService(); // class of face_detection_mlkit_service.dart
  final DatabaseService _dbService = DatabaseService(); // class of database_service.dart

  final GlobalKey _moreInfoSectionKey = GlobalKey();  // build-in method

  final GlobalKey _statusTextKey = GlobalKey();

  final ScrollController _homeScrollController = ScrollController();

  // Stores the latest prediction results and UI state.
  List<EmotionScore> _topResults = [];
  bool _modelReady = false;
  bool _showMoreInfo = false;

  bool _hasError = false;

  bool _isSaved = false;
  MoodRecord? _pendingRecord;

  int? _lastSavedMoodId;

  String _mainEmotion = 'No prediction yet';
  String _debugMessage = 'Position your face in the frame and tap the button';

  Uint8List? _capturedPreviewBytes;

  final List<String> _emotionOptions = [
    'angry',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  // Used for measuring on-device performance.
  final List<int> _tfliteInferenceTimes = [];
  final List<int> _fullPipelineTimes = [];


  /// Initializes camera, model, and startup user guidance.
  @override
  void initState() {
    super.initState();
    _initializeCamera().then((_) {
      _scrollToCameraInstructions();
      _showTipsSheet();
    });

    _scrollToPredictionResult();

    _initModel();

  }


  /// Initializes the front camera used for emotion analysis.
  Future<void> _initializeCamera() async {
    _controller = await CameraService.initializeCamera();

    if (!mounted) return;

    if (_controller != null) {
      setState(() => _isCameraInitialized = true);
    }
  }


  void _scrollToCameraInstructions() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!_homeScrollController.hasClients) return;

      final maxScroll = _homeScrollController.position.maxScrollExtent;

      _homeScrollController.animateTo(
        100.0.clamp(0.0, maxScroll).toDouble(),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }


  void _scrollToPredictionResult() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_homeScrollController.hasClients) {
        final maxScroll = _homeScrollController.position.maxScrollExtent;

        _homeScrollController.animateTo(
          (0.0).clamp(0.0, maxScroll).toDouble(),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      }
    });
  }


  /// Collects additional user information before storing a mood record inside the local database.
  Future<void> _showSaveMoodDetailsSheet() async {
    if (_pendingRecord == null || _isSaved) return;

    List<String> people = await _dbService.getPeople();

    if (!mounted) return;

    if (people.isEmpty) {
      people = ['You - Main User'];
    }

    final details = await showModalBottomSheet<MoodSaveDetails>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF15151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SaveMoodDetailsSheet(
        people: people,
        emotionOptions: _emotionOptions,
        emotionColor: _emotionColor,
      ),
    );

    if (!mounted) return;

    if (details == null) {
      _showMoodSnackBar(
        'Mood was not saved. Confirm details first.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final old = _pendingRecord!;

    final updatedRecord = MoodRecord(
      id: old.id,
      timestamp: old.timestamp,
      primaryEmotion: old.primaryEmotion,
      confidence: old.confidence,
      secondEmotion: old.secondEmotion,
      secondConfidence: old.secondConfidence,
      thirdEmotion: old.thirdEmotion,
      thirdConfidence: old.thirdConfidence,
      blendedColorHex: old.blendedColorHex,
      personName: details.personName,
      userDescription: details.userDescription,
      userDominantEmotion: details.userDominantEmotion,
      allEmotionScores: old.allEmotionScores,
    );

    try {
      final insertedId = await _dbService.insertMood(updatedRecord);

      if (!mounted) return;

      await _dbService.syncPeopleWithMoods();

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _lastSavedMoodId = insertedId;
      });

      _showMoodSnackBar(
        'Mood saved to statistics!',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _showMoodSnackBar(
        'Could not save mood. Please try again.',
        backgroundColor: Colors.redAccent,
      );

      debugPrint('SAVE ERROR: $e');
    }
  }


  /// Loads the TensorFlow Lite emotion recognition model.
  Future<void> _initModel() async {
    try {
      setState(() => _debugMessage = 'Loading model...');
      await _emotionModelService.loadModel();
      setState(() {
        _modelReady = true;
        _debugMessage = 'Position your face in the frame and tap the button';
      });
    } catch (e) {
      setState(() => _debugMessage = 'Error loading model: $e');
    }
  }


  /// Complete emotion recognition pipeline:
  /// 1. Capture image
  /// 2. Detect and crop face
  /// 3. Validate image quality
  /// 4. Run TensorFlow Lite inference
  /// 5. Generate prediction results
  /// 6. Prepare mood record
  /// 7. Update the user interface
  Future<void> _captureAndPredict() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        setState(() {
          _debugMessage = 'Camera not ready';
        });
        return;
      }

      final fullPipelineStopwatch = Stopwatch()..start();

      setState(() {
        _debugMessage = 'Capturing image...';
      });

      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      setState(() {
        _debugMessage = 'Detecting face...';
      });


      // Detect, validate, and crop the largest visible face.
      final detectionResult =  await _faceDetectionService.detectAndCropLargestFace(bytes);


      if (detectionResult.image == null) {
        setState(() {
          _capturedPreviewBytes = bytes;
          _debugMessage = detectionResult.error ?? 'No face detected. Try again.';
          _hasError = true;
          _topResults = [];
          _mainEmotion = 'No prediction yet';
        });
        return;
      }

      final brightness = _calculateMeanIntensity(detectionResult.image!);
      debugPrint('DEBUG: Mean Pixel Intensity: $brightness');

      if (brightness < 50) {
        setState(() {
          _capturedPreviewBytes = bytes;
          _debugMessage = "It's too dark for an accurate prediction.";
          _hasError = true;
          _topResults = [];
          _mainEmotion = 'No prediction yet';
        });
        return;
      }

      setState(() {
        _debugMessage = 'Running prediction...';
      });


      // Run emotion recognition using the TensorFlow Lite model.
      final results = _emotionModelService.predictFromImage(detectionResult.image!);

      _topResults = results.take(3).toList();
      final blendedColor = _calculateBlendedColor();

      // Prepare a mood record that can later be saved to SQLite.
      final record = MoodRecord(
        timestamp: DateTime.now(),
        primaryEmotion: results[0].label,
        confidence: results[0].confidence,
        secondEmotion: results.length > 1 ? results[1].label : null,
        secondConfidence: results.length > 1 ? results[1].confidence : null,
        thirdEmotion: results.length > 2 ? results[2].label : null,
        thirdConfidence: results.length > 2 ? results[2].confidence : null,
        blendedColorHex: '#${blendedColor.value.toRadixString(16).padLeft(8, '0')}',
        allEmotionScores: {for (var r in results) r.label: r.confidence},
      );


      setState(() {
        _capturedPreviewBytes = bytes;
        _mainEmotion = _topResults.first.label;
        _debugMessage = 'Prediction completed';
        _pendingRecord = record;
        _isSaved = false;
        _lastSavedMoodId = null;
      });

      fullPipelineStopwatch.stop();

      final tfliteTimeMs = _emotionModelService.lastInferenceTimeMs;

      if (tfliteTimeMs != null) {
        _logPerformanceSummary(
          tfliteTimeMs: tfliteTimeMs,
          fullPipelineTimeMs: fullPipelineStopwatch.elapsedMilliseconds,
        );
      }

    } catch (e) {
      setState(() {
        _debugMessage = 'Error: $e';
      });
    }

    _scrollToPredictionResult();
  }


  /// Maps each emotion to its corresponding application color.
  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return const Color(0xFF4CAF50);
      case 'neutral':
        return const Color(0xFFF1C40F);
      case 'sad':
        return const Color(0xFF3498DB);
      case 'angry':
        return const Color(0xFFE74C3C);
      case 'fear':
        return const Color(0xFF8E44AD);
      case 'disgust':
        return const Color(0xFF6B8E23);
      case 'surprise':
        return const Color(0xFFE67E22);
      default:
        return Colors.grey;
    }
  }


  /// Calculates image brightness to reject extremely dark captures.
  double _calculateMeanIntensity(img.Image image){
    double totalIntensity = 0;
    for (final pixel in image){
      totalIntensity += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
    }
    return totalIntensity / (image.width * image.height);
  }



  /// Generates a blended color representation using the Top-3 predicted emotions and their confidence scores.
  Color _calculateBlendedColor() {
    if (_topResults.isEmpty) return Colors.grey;

    double totalConfidence = 0;
    double r = 0, g = 0, b = 0;

    // Use top 3 results for blending
    for (var i = 0; i < math.min(3, _topResults.length); i++) {
      final res = _topResults[i];
      final color = _emotionColor(res.label);
      r += color.red * res.confidence;
      g += color.green * res.confidence;
      b += color.blue * res.confidence;
      totalConfidence += res.confidence;
    }

    if (totalConfidence == 0) return Colors.grey;

    return Color.fromARGB(  // ARGB type
      255,  // A (255=opaque, 0=transparent)
      (r / totalConfidence).round().clamp(0, 255),  //R
      (g / totalConfidence).round().clamp(0, 255), //G
      (b / totalConfidence).round().clamp(0, 255), //B
    );
  }


  Future<void> _scrollToMoreInfoSection() async {
    await Future.delayed(const Duration(milliseconds: 250));

    final context = _moreInfoSectionKey.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }


  /// Displays feedback messages for save, delete,
  /// and validation operations.
  void _showMoodSnackBar(String message, {Color backgroundColor = Colors.green}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.fixed,
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text(
                'HIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Removes the previously saved mood record from statistics.
  Future<void> _unsaveFromStats() async {
    if (!_isSaved || _lastSavedMoodId == null) return;

    try {
      await _dbService.deleteMood(_lastSavedMoodId!);

      setState(() {
        _isSaved = false;
        _lastSavedMoodId = null;
      });

      _showMoodSnackBar(
        'Mood removed from statistics.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showMoodSnackBar(
        'Error removing mood: $e',
        backgroundColor: Colors.red,
      );
    }
  }


  /// Displays the usage guide shown at application startup and through the information button.
  void _showTipsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => const TipsBottomSheet(),
    );
  }


  /// Resets the current prediction and returns the screen to its initial state.
  void _clearResult() {
    setState(() {
      _capturedPreviewBytes = null;
      _topResults = [];
      _mainEmotion = 'No prediction yet';
      _showMoreInfo = false;
      _hasError = false;
      _isSaved = false;
      _pendingRecord = null;
      _lastSavedMoodId = null;
      _debugMessage = 'Position your face in the frame and tap the button';
    });
  }


  @override
  void dispose() {
    _controller?.dispose();
    _emotionModelService.close();
    _faceDetectionService.close();
    _homeScrollController.dispose();
    super.dispose();
  }


  /// Builds the Home screen user interface.
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0813),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _homeScrollController,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [

              ResultCard(
                topResults: _topResults,
                mainEmotion: _mainEmotion,
              ),

              const SizedBox(height: 14),


              if (_topResults.isNotEmpty) ...[
                ActionButtons(
                  showMoreInfo: _showMoreInfo,
                  isSaved: _isSaved,
                  onToggleInfo: () async {
                    final shouldShow = !_showMoreInfo;

                    setState(() {
                      _showMoreInfo = shouldShow;
                    });

                    if (shouldShow) {
                      await _scrollToMoreInfoSection();
                    }
                  },
                  onSave: _showSaveMoodDetailsSheet,
                  onUnsave: _unsaveFromStats,
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 14),

              CameraSection(
                capturedPreviewBytes: _capturedPreviewBytes,
                isCameraInitialized: _isCameraInitialized,
                controller: _controller,
              ),
              const SizedBox(height: 20),

              BottomControls(
                modelReady: _modelReady,
                hasCapturedPreview: _capturedPreviewBytes != null,
                onShowTips: _showTipsSheet,
                onCapture: _captureAndPredict,
                onRetry: () {
                  _clearResult();
                  _scrollToCameraInstructions();
                },
              ),
              const SizedBox(height: 14),

              StatusText(
                message: _debugMessage,
                hasError: _hasError,
                statusKey: _statusTextKey,
              ),
              const SizedBox(height: 18),

              if (_showMoreInfo && _topResults.isNotEmpty)
                EmotionPaletteCard(
                  topResults: _topResults,
                  emotionColor: _emotionColor,
                  blendedColor: _calculateBlendedColor(),
                  sectionKey: _moreInfoSectionKey,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  /// Collects and prints TensorFlow Lite inference time and full prediction pipeline performance metrics.
  void _logPerformanceSummary({
    required int tfliteTimeMs,
    required int fullPipelineTimeMs,
  }) {
    _tfliteInferenceTimes.add(tfliteTimeMs);
    _fullPipelineTimes.add(fullPipelineTimeMs);

    final avgTflite = _tfliteInferenceTimes.reduce((a, b) => a + b) /
        _tfliteInferenceTimes.length;

    final avgPipeline = _fullPipelineTimes.reduce((a, b) => a + b) /
        _fullPipelineTimes.length;

    debugPrint('--- Face2Mood Performance Summary ---');
    debugPrint('Successful predictions: ${_tfliteInferenceTimes.length}');
    debugPrint('Latest TFLite inference: $tfliteTimeMs ms');
    debugPrint('Average TFLite inference: ${avgTflite.toStringAsFixed(2)} ms');
    debugPrint('Latest full pipeline: $fullPipelineTimeMs ms');
    debugPrint('Average full pipeline: ${avgPipeline.toStringAsFixed(2)} ms');
    debugPrint('-------------------------------------');
  }

}
