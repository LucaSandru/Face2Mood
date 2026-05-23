import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

import 'services/camera_service.dart';
import 'services/model_service(RS-Xception).dart';
import 'services/face_detection_MLKit_service.dart';
import 'services/mood_record_service.dart';
import 'services/database_service.dart';


class MoodSaveDetails {
  final String personName;
  final String? userDescription;
  final String userDominantEmotion;

  MoodSaveDetails({
    required this.personName,
    required this.userDescription,
    required this.userDominantEmotion,
  });
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin  {

  @override
  bool get wantKeepAlive => true;

  CameraController? _controller;
  bool _isCameraInitialized = false;

  final EmotionModelService _emotionModelService = EmotionModelService();  //class of model_service.dart
  final FaceDetectionService _faceDetectionService = FaceDetectionService(); //class of facce_detection.dart
  final DatabaseService _dbService = DatabaseService(); //class of database_service.dart

  final ScrollController _scrollController = ScrollController();  // built-in class
  final GlobalKey _moreInfoSectionKey = GlobalKey();  // build-in class

  final GlobalKey _statusTextKey = GlobalKey();


  List<EmotionScore> _topResults = [];  // from model_service.dart (EmotionScore)
  bool _modelReady = false;
  bool _showMoreInfo = false;
  bool _showFullLegend = false;
  bool _showInterpretation = false;
  bool _showSuggestion = false;

  bool _hasError = false;

  bool _isSaved = false;
  MoodRecord? _pendingRecord;

  int? _lastSavedMoodId;

  String _mainEmotion = 'No prediction yet';
  String _debugMessage = 'Position your whole face in the frame and tap the button';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedUserEmotion;
  final ScrollController _homeScrollController = ScrollController();


  @override
  void initState() {   // lifecycle method, called just once when widget created
    super.initState();
    _initializeCamera().then((_) {
      _scrollToCameraInstructions();
      _showTipsSheet();
    });

    _scrollToPredictionResult();

    _initModel();

  }


  @override
  void didChangeDependencies() {  // lifecycle method, called when dependencies change
    super.didChangeDependencies();
  }

  Future<void> _initializeCamera() async {
    _controller = await CameraService.initializeCamera();  //wait for camera to be initialized

    if (!mounted) return;

    if (_controller != null) {
      setState(() => _isCameraInitialized = true);  // _isCameraInitialized become true, it was defined as false
    }
  }


  int _countWords(String text) {
    int count = 0;

    for (var word in text.trim().split(' ')) {
      if (word.isNotEmpty) {
        count++;
      }
    }

    return count;
  }


  void _scrollToCameraInstructions() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_homeScrollController.hasClients) {
        final maxScroll = _homeScrollController.position.maxScrollExtent;

        _homeScrollController.animateTo(
          (90.0).clamp(0.0, maxScroll).toDouble(),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      }
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


  Future<void> _showSaveMoodDetailsSheet() async {
    if (_pendingRecord == null || _isSaved) return;

    final descriptionController = TextEditingController();
    final newPersonController = TextEditingController();

    String selectedEmotion = 'no_emotion';

    int wordCount = 0;

    List<String> people = await _dbService.getPeople();

    if (!mounted) return;

    if (people.isEmpty) {
      people = ['You - Main User'];
    }

    String selectedPerson = people.first;
    bool addingNewPerson = false;

    final details = await showModalBottomSheet<MoodSaveDetails>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF15151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Save mood details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Add details before saving this mood to statistics.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Person',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...people.map((person) {
                          final isSelected =
                              !addingNewPerson && selectedPerson == person;

                          return ChoiceChip(
                            label: Text(person),
                            selected: isSelected,
                            selectedColor: Colors.green.withOpacity(0.35),
                            backgroundColor: const Color(0xFF20202C),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.greenAccent : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setModalState(() {
                                addingNewPerson = false;
                                selectedPerson = person;
                                newPersonController.clear();
                              });
                            },
                          );
                        }),

                        ChoiceChip(
                          label: const Text('+ Add new person'),
                          selected: addingNewPerson,
                          selectedColor: Colors.purpleAccent.withOpacity(0.25),
                          backgroundColor: const Color(0xFF20202C),
                          labelStyle: TextStyle(
                            color: addingNewPerson
                                ? Colors.purpleAccent
                                : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              addingNewPerson = true;
                            });
                          },
                        ),
                      ],
                    ),

                    if (addingNewPerson) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: newPersonController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'New person name',
                          hintText: 'Example: Mum, Dad, Brother',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF20202C),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setModalState(() {
                          wordCount = _countWords(value);
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Short description',
                        hintText: 'Maximum 30 words...',
                        errorText:
                        wordCount > 30 ? 'Maximum 30 words allowed' : null,
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF20202C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$wordCount / 30 words',
                      style: TextStyle(
                        color: wordCount > 30
                            ? Colors.redAccent
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: selectedEmotion,
                      dropdownColor: const Color(0xFF20202C),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your believed dominant emotion',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF20202C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'no_emotion',
                          child: Text('NO EMOTION',
                            style: TextStyle(color: Colors.redAccent,
                            fontWeight: FontWeight.bold,),),
                        ),
                        ..._emotionOptions.map((emotion) {
                          return DropdownMenuItem(
                            value: emotion,
                            child: Text(emotion.toUpperCase()),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedEmotion = value;
                        });
                      },
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(null);
                            },
                            child: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: wordCount > 30
                                ? null
                                : () {
                              final finalPersonName = addingNewPerson
                                  ? newPersonController.text.trim()
                                  : selectedPerson;

                              if (finalPersonName.isEmpty) {
                                _showMoodSnackBar(
                                  'Please enter a person name.',
                                  backgroundColor: Colors.orange,
                                );
                                return;
                              }

                              if (selectedEmotion == 'no_emotion') {
                                _showMoodSnackBar(
                                  'Please select your believed emotion.',
                                  backgroundColor: Colors.orange,
                                );
                                return;
                              }

                              Navigator.of(sheetContext).pop(
                                MoodSaveDetails(
                                  personName: finalPersonName,
                                  userDescription: descriptionController
                                      .text
                                      .trim()
                                      .isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  userDominantEmotion: selectedEmotion,
                                ),
                              );
                            },
                            child: const Text('Confirm Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    descriptionController.dispose();
    newPersonController.dispose();

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

  Future<void> _captureAndPredict() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        setState(() {
          _debugMessage = 'Camera not ready';
        });
        return;
      }

      setState(() {
        _debugMessage = 'Capturing image...';
      });

      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      setState(() {
        _debugMessage = 'Detecting face...';
      });


      final detectionResult =
      await _faceDetectionService.detectAndCropLargestFace(bytes);


      if (detectionResult.image == null) {
        setState(() {
          _capturedPreviewBytes = bytes;
          // Display the actual error message from the service
          _debugMessage = detectionResult.error ?? 'No face detected. Try again.';
          _hasError = true;
          _topResults = [];
          _mainEmotion = 'No prediction yet';
        });
        return;
      }

      final brightness = _calculateMeanIntensity(detectionResult.image!);
      print('DEBUG: Mean Pixel Intensity: $brightness');

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
      // -----------------------------------

      setState(() {
        _debugMessage = 'Running prediction...';
      });


      final results = _emotionModelService.predictFromImage(detectionResult.image!);

      // Prepare the record but DON'T save yet
      _topResults = results.take(3).toList();
      final blendedColor = _calculateBlendedColor();
      final record = MoodRecord(
        timestamp: DateTime.now(),
        primaryEmotion: results[0].label,
        confidence: results[0].confidence,
        secondEmotion: results.length > 1 ? results[1].label : null,
        secondConfidence: results.length > 1 ? results[1].confidence : null,
        thirdEmotion: results.length > 2 ? results[2].label : null,
        thirdConfidence: results.length > 2 ? results[2].confidence : null,
        blendedColorHex: '#${blendedColor.value.toRadixString(16).padLeft(8, '0')}',
      );


      setState(() {
        _capturedPreviewBytes = bytes;
        _mainEmotion = _topResults.first.label;
        _debugMessage = 'Prediction completed';
        _showFullLegend = false;
        _showInterpretation = false;
        _showSuggestion = false;
        _pendingRecord = record;
        _isSaved = false;
        _lastSavedMoodId = null;
      });

    } catch (e) {
      setState(() {
        _debugMessage = 'Error: $e';
      });
    }

    _scrollToPredictionResult();
  }

  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return const Color(0xFF4CAF50); // Green
      case 'neutral':
        return const Color(0xFFF1C40F); // Yellow
      case 'sad':
        return const Color(0xFF3498DB); // Blue
      case 'angry':
        return const Color(0xFFE74C3C); // Red
      case 'fear':
        return const Color(0xFF8E44AD); // Purple
      case 'disgust':
        return const Color(0xFF6B8E23); // Olive Green
      case 'surprise':
        return const Color(0xFFE67E22); // Orange
      default:
        return Colors.grey;
    }
  }

  String _emotionMeaning(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return 'High intensity, tension, and emotional heat.';
      case 'disgust':
        return 'Physical aversion, discomfort, or rejection.';
      case 'fear':
        return 'High alert, uncertainty, and inner unease.';
      case 'happy':
        return 'Joy, optimism, and high positive energy.';
      case 'neutral':
        return 'A state of balance, stability, and calm focus.';
      case 'sad':
        return 'Low energy, quiet reflection, and stillness.';
      case 'surprise':
        return 'Sudden novelty, wonder, and sharp attention.';
      default:
        return 'No meaning available.';
    }
  }

  String _getInterpretation(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return 'Your expression shows signs of tension or frustration.';
      case 'disgust':
        return 'Your expression suggests a reaction of aversion or rejection.';
      case 'fear':
        return 'Your expression shows signals of alertness or unease.';
      case 'happy':
        return 'Your expression appears positive and relaxed.';
      case 'neutral':
        return 'Your expression suggests a balanced and calm state.';
      case 'sad':
        return 'Your expression shows signs of low energy or reflection.';
      case 'surprise':
        return 'Your expression appears reactive to something sudden or novel.';
      default:
        return 'Interpretation not available.';
    }
  }

  String _getSuggestion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return 'Take a deep breath and pause before reacting.';
      case 'disgust':
        return 'Identify the source of discomfort and step back if needed.';
      case 'fear':
        return 'Focus on slow, steady breathing to regain your balance.';
      case 'happy':
        return 'Keep this positive state by focusing on what made you feel good.';
      case 'neutral':
        return 'Maintain this steady focus as you move through your day.';
      case 'sad':
        return 'A short walk or break may help improve your mood.';
      case 'surprise':
        return 'Take a moment to process the new information with calm attention.';
      default:
        return 'No suggestion available.';
    }
  }

  double _calculateMeanIntensity(img.Image image){
    double totalIntensity = 0;
    for (final pixel in image){
      totalIntensity += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
    }
    return totalIntensity / (image.width * image.height);
  }




  Color _calculateBlendedColor() {   // calculate the blending for pallete
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


  Widget _buildActionButtons() {
    if (_topResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // More Info Button
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final shouldShow = !_showMoreInfo;
                setState(() => _showMoreInfo = shouldShow);
                if (shouldShow) await _scrollToMoreInfoSection();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4BEFF)),
                backgroundColor: const Color(0xFF292545),
                foregroundColor: Color(0xFFD4BEFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _showMoreInfo ? 'Hide info' : 'More info',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(width: 12),
          // Save to Stats Button
          Expanded(
            child: OutlinedButton(
              onPressed: _topResults.isEmpty
                  ? null
                  : _isSaved
                  ? _unsaveFromStats
                  : _showSaveMoodDetailsSheet,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isSaved ? Colors.redAccent : Colors.greenAccent,
                ),
                backgroundColor: _isSaved
                    ? Colors.redAccent.withOpacity(0.15)
                    : Colors.greenAccent.withOpacity(0.15),
                foregroundColor: _isSaved ? Colors.redAccent : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isSaved ? 'Unsave' : 'Save to stats',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLegendItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: _emotionColor(label),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '${label[0].toUpperCase()}${label.substring(1)}: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: _emotionMeaning(label),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildColorPaletteSection() {
    if (!_showMoreInfo || _topResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final top3Labels = _topResults.take(3).map((e) => e.label).toList();
    final otherLabels = EmotionModelService.labels
        .where((l) => !top3Labels.contains(l))
        .toList();

    return Container(
      key: _moreInfoSectionKey,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emotional color palette',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Top 3 Tags
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _topResults.take(3).map((emotion) {
                    final percent = (emotion.confidence * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _emotionColor(emotion.label).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _emotionColor(emotion.label).withOpacity(0.5),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _emotionColor(emotion.label),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${emotion.label} • $percent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '}',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 60,
                    fontWeight: FontWeight.w100,
                    fontFamily: 'serif',
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your Color',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: _calculateBlendedColor(),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _calculateBlendedColor().withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '(legend)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(color: Colors.white10, thickness: 1),
          const SizedBox(height: 8),
          
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showInterpretation = !_showInterpretation),
              icon: Icon(
                _showInterpretation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: _emotionColor(_topResults.first.label),
                size: 20,
              ),
              label: Text(
                'Interpretation',
                style: TextStyle(
                  color: _emotionColor(_topResults.first.label),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (_showInterpretation)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                _getInterpretation(_topResults.first.label),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showSuggestion = !_showSuggestion),
              icon: Icon(
                _showSuggestion ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFFF1C40F),
                size: 20,
              ),
              label: const Text(
                'Suggestion',
                style: TextStyle(
                  color: Color(0xFFF1C40F),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (_showSuggestion)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                _getSuggestion(_topResults.first.label),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white10, thickness: 1),
          const SizedBox(height: 18),

          const Text(
            'Color Meanings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // Render top 3 in order
          ...top3Labels.map((label) => _buildLegendItem(label)),

          if (!_showFullLegend)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showFullLegend = true),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4BEFF), size: 20),
                label: const Text(
                  'Show all emotions',
                  style: TextStyle(color: Color(0xFFD4BEFF), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),

          if (_showFullLegend) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(color: Colors.white10, thickness: 0.5),
            ),
            ...otherLabels.map((label) => _buildLegendItem(label)),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showFullLegend = false),
                icon: const Icon(Icons.keyboard_arrow_up, color: Color(0xFFD4BEFF), size: 20),
                label: const Text(
                  'Show less',
                  style: TextStyle(color: Color(0xFFD4BEFF), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


/*  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: 8),
          Text(
            'Capture your facial expression and discover your top emotional signals.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }*/


  Widget _buildCameraSection() {
    if (_capturedPreviewBytes != null) {
      return Container(
        height: 430,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white10),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.memory(
            _capturedPreviewBytes!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return Container(
        height: 360,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF171522),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final controller = _controller!;
    final previewAspectRatio = 1 / controller.value.aspectRatio;

    return Container(
      height: 430,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white10),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  void _showTipsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How to use Face2Mood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                        '• Center your face in the frame\n'
                        '• Use clear and natural expressions\n'
                        '• If detection fails, tap Retry and try again\n'
                        '• Check “More info” after prediction\n'
                        '• "Save to stats" to track progression\n'
                        '• View history in the "Stats" tab\n',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38D26F),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _clearResult() {
    setState(() {
      _capturedPreviewBytes = null;
      _topResults = [];
      _mainEmotion = 'No prediction yet';
      _showMoreInfo = false;
      _showInterpretation = false;
      _showSuggestion = false;
      _hasError = false;
      _isSaved = false;
      _pendingRecord = null;
      _lastSavedMoodId = null;
      _debugMessage = 'Position your face in the frame and tap the button';
    });
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left button - Tips
          GestureDetector(
            onTap: _showTipsSheet,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B1828),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          // Center button - Capture
          Column(
            children: [
              GestureDetector(
                onTap: (_modelReady && _capturedPreviewBytes == null)
                    ? _captureAndPredict
                    : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_modelReady && _capturedPreviewBytes == null)
                        ? Colors.white
                        : Colors.grey,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.12),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white30,
                      width: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                !_modelReady
                    ? 'Model loading...'
                    : _capturedPreviewBytes != null
                    ? 'Press retry to analyze again'
                    : 'Tap to analyze',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Right button - Retry / Reset
          GestureDetector(
            onTap: () {
              _clearResult();
              _scrollToCameraInstructions();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B1828),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    // These logic checks are good! Let's use them.
    /*final isError = _debugMessage.toLowerCase().contains('error') ||
        _debugMessage.toLowerCase().contains('no face');*/
    final isSuccess = _debugMessage == 'Prediction completed';

    return Padding(
      key: _statusTextKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _debugMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          // Logic: Red if error, Green if success, otherwise white/grey
          color: _hasError
              ? Colors.redAccent
              : (isSuccess ? Colors.greenAccent : Colors.white70),
          fontSize: 14,
          fontWeight: (_hasError || isSuccess) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_topResults.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF171522),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'No prediction yet',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You seem mostly: ${_mainEmotion[0].toUpperCase()}${_mainEmotion.substring(1)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          ..._topResults.map((emotion) {
            final percent = emotion.confidence * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          emotion.label,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: emotion.confidence.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4BEFF),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller?.dispose();
    _emotionModelService.close();
    _faceDetectionService.close();
    _homeScrollController.dispose();
    super.dispose();
  }

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
              /*_buildHeader(),
              const SizedBox(height: 20),*/

              _buildResultCard(),
              const SizedBox(height: 14),

              _buildActionButtons(),
              const SizedBox(height: 22),

              _buildCameraSection(),
              const SizedBox(height: 20),

              _buildBottomControls(),
              const SizedBox(height: 14),

              _buildStatusText(),
              const SizedBox(height: 18),

              _buildColorPaletteSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
