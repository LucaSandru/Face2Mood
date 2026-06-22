import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/mood_record.dart';
import 'widgets/stats_header.dart';
import 'widgets/empty_stats_state.dart';
import 'widgets/empty_filter_state.dart';
import 'widgets/stats_filter_bar.dart';
import 'widgets/pie_chart.dart';
import 'widgets/mood_history_list.dart';


/// Statistics dashboard displaying mood history, emotion analytics,
/// filtering options, and user-model agreement information.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}


/// Manages mood data loading, filtering, statistics generation,
/// and visualization within the Statistics tab.
class _StatsScreenState extends State<StatsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  // Local database used to retrieve and manage stored mood records.
  final DatabaseService _dbService = DatabaseService();

  // Current filtered mood records and chart visualization data.
  List<MoodRecord> _history = [];
  Map<String, double> _chartData = {};
  bool _isLoading = true;

  // Tracks which mood history cards are currently expanded.
  final Set<int> _expandedItems = {};

  // Active statistics filters selected by the user.
  String _selectedPerson = 'All';
  String _selectedTimeRange = 'all';
  List<String> _availablePeople = ['All'];

  String _selectedStatisticType = 'Average Signals';

  // Supported analytics modes available in the statistics dashboard.
  final List<String> _statisticTypes = [
    'Average Signals',
    'Top Prediction Count',
    'User vs Model Agreement',
  ];


  /// Loads mood data when the Statistics screen is opened.
  @override
  void initState() {
    super.initState();
    _loadData();
  }


  /// Restores all filters to their default values.
  void _resetFilters() {
    setState(() {
      _selectedPerson = 'All';
      _selectedTimeRange = 'all';
      _selectedStatisticType = 'Average Signals';
    });

    _loadData();
  }


  /// Formats emotion labels for display.
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    if (text.length < 2) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }


  /// Loads mood records from the database, applies filters, and prepares the data required for statistics generation.
  void _loadData() async {
    try {
      setState(() => _isLoading = true);
      final allHistory = await _dbService.getAllMoods();

      if (allHistory.isEmpty) {
        setState(() {
          _history = [];
          _chartData = {};
          _availablePeople = ['All'];
          _isLoading = false;
        });
        return;
      }

      // Build the list of available people from stored mood records.
      final names = allHistory
          .map((e) => e.personName)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      names.sort();
      List<String> updatedPeopleList = ['All', ...names];

      final now = DateTime.now();

      // Apply person, time-range, and statistic-specific filters.
      final filteredHistory = allHistory.where((record) {
        bool matchesPerson = (_selectedPerson == 'All' ||
            record.personName == _selectedPerson);
        bool matchesTime = true;
        if (_selectedTimeRange == '1 Day') {
          final dayAgo = now.subtract(const Duration(days: 1));
          matchesTime = record.timestamp.isAfter(dayAgo);
        } else if (_selectedTimeRange == '1 Week') {
          final weekAgo = now.subtract(const Duration(days: 7));
          matchesTime = record.timestamp.isAfter(weekAgo);
        } else if (_selectedTimeRange == '1 Month') {
          final monthAgo = now.subtract(const Duration(days: 30));
          matchesTime = record.timestamp.isAfter(monthAgo);
        } else if (_selectedTimeRange == '1 Year') {
          matchesTime = record.timestamp.year == now.year;
        }

        bool matchesType = true;
        if (_selectedStatisticType == 'User vs Model Agreement') {
          matchesType = record.userDominantEmotion != null &&
              record.userDominantEmotion!.isNotEmpty;
        }

        return matchesPerson && matchesTime && matchesType;
      }).toList();


      // No records satisfy the current filters.
      if (filteredHistory.isEmpty) {
        setState(() {
          _history = [];
          _chartData = {};
          _availablePeople = updatedPeopleList;
          _isLoading = false;
        });
        return;
      }

      _processStatistics(filteredHistory);

      setState(() {
        _history = filteredHistory;
        _availablePeople = updatedPeopleList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading moods: $e");
      setState(() {
        _history = [];
        _isLoading = false;
      });
    }
  }


  /// Selects the appropriate statistics calculation method based on the currently selected analytics mode.
  void _processStatistics(List<MoodRecord> filteredRecords) {
    if (_selectedStatisticType == 'Average Signals') {
      _calculateAverageSignals(filteredRecords);
    } else if (_selectedStatisticType == 'Top Prediction Count') {
      _calculateTopPredictionStats(filteredRecords);
    } else if (_selectedStatisticType == 'User vs Model Agreement') {
      _calculateAgreementStats(filteredRecords);
    }
  }

  /// Calculates cumulative emotion signals using either all stored emotion scores or the available top-3 predictions.
  void _calculateAverageSignals(List<MoodRecord> records) {
    Map<String, double> weights = {};

    // Aggregate emotion contributions from each stored mood record.
    for (var record in records) {
      if (record.allEmotionScores != null && record.allEmotionScores!.isNotEmpty) {

        // New records contain confidence values for all seven emotions.
        record.allEmotionScores!.forEach((emotion, score) {
          weights[emotion] = (weights[emotion] ?? 0) + score;
        });
      }

      // Fallback for older records containing only top-3 predictions.
      else {
        weights[record.primaryEmotion] =
            (weights[record.primaryEmotion] ?? 0) + record.confidence;
        if (record.secondEmotion != null && record.secondConfidence != null) {
          weights[record.secondEmotion!] =
              (weights[record.secondEmotion!] ?? 0) + record.secondConfidence!;
        }
        if (record.thirdEmotion != null && record.thirdConfidence != null) {
          weights[record.thirdEmotion!] =
              (weights[record.thirdEmotion!] ?? 0) + record.thirdConfidence!;
        }
      }
    }

    // Sort emotions by importance for a consistent chart legend.
    var sortedEntries = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    setState(() {
      _chartData = Map.fromEntries(sortedEntries);
    });
  }


  /// Counts how frequently each emotion appears as the primary prediction.
  void _calculateTopPredictionStats(List<MoodRecord> records) {
    Map<String, double> counts = {};
    for (var record in records) {
      counts[record.primaryEmotion] =
          (counts[record.primaryEmotion] ?? 0) + 1.0;
    }
    setState(() {
      _chartData = counts;
    });
  }


  /// Measures agreement between the user's selected emotion and the model's top-3 predictions.
  void _calculateAgreementStats(List<MoodRecord> records) {
    double agreement = 0;
    double partialAgreement = 0;
    double disagreement = 0;

    for (var record in records) {
      final userEmotion = record.userDominantEmotion;

      if (userEmotion != null && userEmotion.isNotEmpty) {
        final user = userEmotion.toLowerCase().trim();

        final top1 = record.primaryEmotion.toLowerCase().trim();
        final top2 = record.secondEmotion?.toLowerCase().trim();
        final top3 = record.thirdEmotion?.toLowerCase().trim();

        // Exact agreement with the primary model prediction.
        if (user == top1) {
          agreement += 1.0;

          // Partial agreement with secondary predictions.
        } else if (user == top2 || user == top3) {
          partialAgreement += 1.0;
        }
        // disagreement with model prediction
        else {
          disagreement += 1.0;
        }
      }
    }

    setState(() {
      _chartData = {
        'Agree:': agreement,
        'Partial agree:': partialAgreement,
        'Disagree:': disagreement,
      };
    });
  }


  /// Maps emotions to their associated visualization colors.
  Color _getEmotionColor(String emotion) {
    if (emotion.isEmpty) return Colors.grey;
    switch (emotion.toLowerCase().trim()) {
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
      case 'agree:':
        return const Color(0xFF4CAF50);
      case 'disagree:':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }


  /// Builds the complete Statistics dashboard interface.
  @override
  Widget build(BuildContext context) {
    super.build(context);


    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.refresh),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty && _selectedPerson == 'All' &&
          _selectedTimeRange == 'all' &&
          _selectedStatisticType == 'Average Signals'
          ? const EmptyStatsState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsHeader(
              selectedStatisticType: _selectedStatisticType,
            ),
            const SizedBox(height: 32),

            if (_history.isEmpty)
              const EmptyFilterState()
            else

            // Visual representation of the currently selected statistics.
              StatsPieChart(
                chartData: _chartData,
                getEmotionColor: _getEmotionColor,
                capitalize: _capitalize,
              ),

            const SizedBox(height: 32),

            // Filtering controls affecting statistics and history records.
            StatsFilterBar(
              selectedPerson: _selectedPerson,
              selectedTimeRange: _selectedTimeRange,
              selectedStatisticType: _selectedStatisticType,
              availablePeople: _availablePeople,
              statisticTypes: _statisticTypes,
              onPersonChanged: (value) {
                setState(() {
                  _selectedPerson = value;
                });
                _loadData();
              },
              onTimeRangeChanged: (value) {
                setState(() {
                  _selectedTimeRange = value;
                });
                _loadData();
              },
              onStatisticTypeChanged: (value) {
                setState(() {
                  _selectedStatisticType = value;
                });
                _loadData();
              },
              onResetFilters: _resetFilters,
            ),

            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _history.isEmpty
                      ? 'No mood scans available'
                      : 'Based on ${_history.length} mood scans',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of mood records matching the selected filters.
            MoodHistoryList(
              history: _history,
              expandedItems: _expandedItems,
              onToggleExpanded: _toggleExpandedItem,
              onDeleteRecord: _deleteMoodRecord,
              getEmotionColor: _getEmotionColor,
              getSafeColor: _getSafeColor,
              capitalize: _capitalize,
            ),
          ],
        ),
      ),
    );
  }


  /// Expands or collapses an individual mood history card.
  void _toggleExpandedItem(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }


  /// Safely converts a stored hexadecimal color into a Flutter Color.
  Color _getSafeColor(String? hex) {
    try {
      if (hex == null || hex.isEmpty || !hex.contains('#'))
        return Colors.blueGrey;
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blueGrey;
    }
  }


  /// Deletes a mood record and refreshes the statistics dashboard.
  Future<void> _deleteMoodRecord(MoodRecord record) async {
    if (record.id == null) return;

    try {
      await _dbService.deleteMood(record.id!);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood record deleted'),
        ),
      );

      _loadData();

    } catch (e) {
      debugPrint('Error deleting mood: $e');
    }
  }

}