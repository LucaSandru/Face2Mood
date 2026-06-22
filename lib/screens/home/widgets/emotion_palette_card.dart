import 'package:flutter/material.dart';

import '../../../services/model_service.dart';


/// Displays the emotion prediction results as a color palette,
/// together with interpretations, suggestions, and emotion meanings.
class EmotionPaletteCard extends StatefulWidget {
  final List<EmotionScore> topResults;
  final Color Function(String emotion) emotionColor;
  final Color blendedColor;
  final GlobalKey sectionKey;

  const EmotionPaletteCard({
    super.key,
    required this.topResults,
    required this.emotionColor,
    required this.blendedColor,
    required this.sectionKey,
  });

  @override
  State<EmotionPaletteCard> createState() => _EmotionPaletteCardState();
}

class _EmotionPaletteCardState extends State<EmotionPaletteCard> {

  // Controls the visibility of expandable sections.
  bool _showFullLegend = false;
  bool _showInterpretation = false;
  bool _showSuggestion = false;

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }


  /// Short description associated with each emotion color.
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


  /// Generates an interpretation (based on Top1 emotion)
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


  /// Generates a suggestion (based on Top1 emotion)
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


  /// Builds a single emotion legend entry used in the color meaning section.
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
              color: widget.emotionColor(label),
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
                    text: '${_capitalize(label)}: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: _emotionMeaning(label)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (widget.topResults.isEmpty) {
      return const SizedBox.shrink();
    }


    // Extract Top3 emotions predicted by the model.
    final top3Labels = widget.topResults.take(3).map((e) => e.label).toList();


    // Remaining emotions used when the full legend is expanded.
    final otherLabels = EmotionModelService.labels
        .where((label) => !top3Labels.contains(label))
        .toList();

    final mainEmotion = widget.topResults.first.label;

    return Container(
      key: widget.sectionKey,
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


          // Visual representation of the top-3 emotions and the blended color result.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.topResults.take(3).map((emotion) {
                    final percent =
                    (emotion.confidence * 100).toStringAsFixed(1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                          widget.emotionColor(emotion.label).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget
                                .emotionColor(emotion.label)
                                .withOpacity(0.5),
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
                                  color: widget.emotionColor(emotion.label),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_capitalize(emotion.label)} • $percent%',
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
                        color: widget.blendedColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.blendedColor.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '(color palette)',
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


          // Interpretation - Expandable explanation of the detected dominant emotion
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showInterpretation = !_showInterpretation;
                });
              },
              icon: Icon(
                _showInterpretation
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: widget.emotionColor(mainEmotion),
                size: 20,
              ),
              label: Text(
                'Interpretation',
                style: TextStyle(
                  color: widget.emotionColor(mainEmotion),
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
                _getInterpretation(mainEmotion),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),


          // Suggestion - Expandable explanation of the detected dominant emotion
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showSuggestion = !_showSuggestion;
                });
              },
              icon: Icon(
                _showSuggestion
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
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
                _getSuggestion(mainEmotion),
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


          // Displays the emotion-to-color mapping used throughout the application.
          const Text(
            'Color Meanings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          ...top3Labels.map((label) => _buildLegendItem(label)),

          if (!_showFullLegend)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFullLegend = true;
                  });
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFD4BEFF),
                  size: 20,
                ),
                label: const Text(
                  'Show all emotions',
                  style: TextStyle(
                    color: Color(0xFFD4BEFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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
                onPressed: () {
                  setState(() {
                    _showFullLegend = false;
                  });
                },
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Color(0xFFD4BEFF),
                  size: 20,
                ),
                label: const Text(
                  'Show less',
                  style: TextStyle(
                    color: Color(0xFFD4BEFF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}