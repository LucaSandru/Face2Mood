import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'services/database_service.dart';
import 'services/mood_record_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final DatabaseService _dbService = DatabaseService();
  List<MoodRecord> _history = [];
  Map<String, double> _chartData = {};
  double _minorSignalsWeight = 0;
  bool _isLoading = true;

  final Set<int> _expandedItems = {};

  String _selectedPerson = 'All';
  String _selectedTimeRange = 'all';
  List<String> _availablePeople = ['All'];

  String _selectedStatisticType = 'Average Signals';
  final List<String> _statisticTypes = [
    'Average Signals',
    'Top Prediction Count',
    'User vs Model Agreement',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildUserFilter() {
    return PopupMenuButton<String>(
      initialValue: _selectedPerson,
      onSelected: (String value) {
        setState(() {
          _selectedPerson = value;
          _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Person: ",
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            Flexible(
              child: Text(
                _selectedPerson == 'All' ? 'All users' : _selectedPerson,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return _availablePeople.map((String person) {
          return PopupMenuItem<String>(
            value: person,
            child: Text(person == 'All' ? 'All users' : person),
          );
        }).toList();
      },
    );
  }

  Widget _buildDateFilter() {
    final Map<String, String> options = {
      'all': 'All time',
      '1 Day': '1 Day',
      '1 Week': '1 Week',
      '1 Month': '1 Month',
      '1 Year': '1 Year',
    };

    return PopupMenuButton<String>(
      initialValue: _selectedTimeRange,
      onSelected: (String value) {
        setState(() {
          _selectedTimeRange = value;
          _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Time: ",
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            Text(
              options[_selectedTimeRange] ?? _selectedTimeRange,
              style: const TextStyle(color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return options.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList();
      },
    );
  }

  Widget _buildStatisticTypeFilter() {
    return PopupMenuButton<String>(
      initialValue: _selectedStatisticType,
      onSelected: (String value) {
        setState(() {
          _selectedStatisticType = value;
          _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Type: ",
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            Text(
              _selectedStatisticType,
              style: const TextStyle(color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return _statisticTypes.map((String type) {
          return PopupMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList();
      },
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    if (text.length < 2) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _loadData() async {
    try {
      setState(() => _isLoading = true);
      final allHistory = await _dbService.getAllMoods();

      if (allHistory.isEmpty) {
        setState(() {
          _history = [];
          _chartData = {};
          _minorSignalsWeight = 0;
          _availablePeople = ['All'];
          _isLoading = false;
        });
        return;
      }

      final names = allHistory
          .map((e) => e.personName)
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      names.sort();
      List<String> updatedPeopleList = ['All', ...names];

      final now = DateTime.now();
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

      if (filteredHistory.isEmpty) {
        setState(() {
          _history = [];
          _chartData = {};
          _minorSignalsWeight = 0;
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

  void _processStatistics(List<MoodRecord> filteredRecords) {
    if (_selectedStatisticType == 'Average Signals') {
      _calculateAverageSignals(filteredRecords);
    } else if (_selectedStatisticType == 'Top Prediction Count') {
      _calculateTopPredictionStats(filteredRecords);
    } else if (_selectedStatisticType == 'User vs Model Agreement') {
      _calculateAgreementStats(filteredRecords);
    }
  }

  void _calculateAverageSignals(List<MoodRecord> records) {
    Map<String, double> weights = {};
    double totalMinorAccumulated = 0;

    for (var record in records) {
      double recordTrackedConfidence = 0;
      weights[record.primaryEmotion] =
          (weights[record.primaryEmotion] ?? 0) + record.confidence;
      recordTrackedConfidence += record.confidence;
      if (record.secondEmotion != null && record.secondConfidence != null) {
        weights[record.secondEmotion!] =
            (weights[record.secondEmotion!] ?? 0) + record.secondConfidence!;
        recordTrackedConfidence += record.secondConfidence!;
      }
      if (record.thirdEmotion != null && record.thirdConfidence != null) {
        weights[record.thirdEmotion!] =
            (weights[record.thirdEmotion!] ?? 0) + record.thirdConfidence!;
        recordTrackedConfidence += record.thirdConfidence!;
      }
      double recordMinor = 1.0 - recordTrackedConfidence;
      totalMinorAccumulated += (recordMinor > 0 ? recordMinor : 0);
    }

    setState(() {
      _chartData = weights;
      _minorSignalsWeight = totalMinorAccumulated;
    });
  }

  void _calculateTopPredictionStats(List<MoodRecord> records) {
    Map<String, double> counts = {};
    for (var record in records) {
      counts[record.primaryEmotion] =
          (counts[record.primaryEmotion] ?? 0) + 1.0;
    }
    setState(() {
      _chartData = counts;
      _minorSignalsWeight = 0;
    });
  }

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

        if (user == top1) {
          agreement += 1.0;
        } else if (user == top2 || user == top3) {
          partialAgreement += 1.0;
        } else {
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

      _minorSignalsWeight = 0;
    });
  }

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
      case 'minor signals':
        return Colors.white24;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String subtitle = 'Weighted average of Top-3 signals across scans';
    if (_selectedStatisticType == 'Top Prediction Count') {
      subtitle = 'Distribution of primary emotion predictions';
    } else if (_selectedStatisticType == 'User vs Model Agreement') {
      subtitle = 'Comparison between AI prediction and your feedback';
    }

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
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emotional Presence',
              style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 32),
            _buildPieChart(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildUserFilter()),
                const SizedBox(width: 8),
                Expanded(child: _buildDateFilter()),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity, child: _buildStatisticTypeFilter()),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent History',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  'Based on ${_history.length} mood scans',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No mood data yet',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const Text('Start capturing on the Home tab!',
              style: TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    List<PieChartSectionData> sections = [];
    _chartData.forEach((key, value) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          color: _getEmotionColor(key),
          value: value,
          title: '',
          radius: 55,
        ));
      }
    });

    if (_minorSignalsWeight > 0) {
      sections.add(PieChartSectionData(
        color: _getEmotionColor('minor signals'),
        value: _minorSignalsWeight,
        title: '',
        radius: 50,
      ));
    }

    double total = _chartData.values.fold<double>(0.0, (a, b) => a + b) +
        _minorSignalsWeight;

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 45,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._chartData.entries.map((entry) {
                double percentage = total > 0 ? (entry.value / total) * 100 : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: _getEmotionColor(
                              entry.key), borderRadius: BorderRadius.circular(
                              2))),
                      const SizedBox(width: 8),
                      Text(
                        '${_capitalize(entry.key)} ${percentage.toStringAsFixed(
                            1)}%',
                        style: const TextStyle(color: Colors.white70,
                            fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
              if (_minorSignalsWeight > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: _getEmotionColor('minor signals'),
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(
                        'Minor Signals ${((_minorSignalsWeight / total) * 100)
                            .toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white38,
                            fontSize: 9,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  Color _getSafeColor(String? hex) {
    try {
      if (hex == null || hex.isEmpty || !hex.contains('#'))
        return Colors.blueGrey;
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blueGrey;
    }
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final record = _history[index];
        final dateStr = DateFormat('MMM dd, HH:mm').format(record.timestamp);
        final contextName = record.personName;
        final description = record.userDescription;
        final userEmotion = record.userDominantEmotion;
        final isExpanded = _expandedItems.contains(index);
        final displayName =
        contextName != null && contextName.isNotEmpty
            ? contextName
            : 'Mood entry';
        final feltEmotion =
        userEmotion != null && userEmotion.isNotEmpty ? userEmotion : record
            .primaryEmotion;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_expandedItems.contains(index)) {
                _expandedItems.remove(index);
              } else {
                _expandedItems.add(index);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF171522),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: emotion avatar only
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _getSafeColor(record.blendedColorHex),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.face, color: Colors.white70),
                ),

                const SizedBox(width: 14),

                // MIDDLE + RIGHT
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT TEXT CONTENT
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'You felt: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _capitalize(feltEmotion),
                                    style: TextStyle(
                                      color: _getEmotionColor(feltEmotion),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (description != null &&
                                description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                description,
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // RIGHT: delete button + lowered results
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // DELETE BUTTON TOP-RIGHT
                            InkWell(
                            onTap: () {
                      showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF171522),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                      'Delete this mood record?',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                      content: const Text(
                      'This record will be permanently removed from your mood history.',
                      style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                      TextButton(
                      onPressed: () {
                      Navigator.pop(context);
                      },
                      child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white60),
                      ),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteMoodRecord(record);
                        },
                      child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                      ),
                      ),
                      ],
                      ),
                      );
                      },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.55),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // RESULTS LOWERED A LITTLE
                            const Text(
                              'Results:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),

                            Text(
                              '${_capitalize(record.primaryEmotion)} ${(record
                                  .confidence * 100).toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _getEmotionColor(record.primaryEmotion),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (record.secondEmotion != null &&
                                record.secondConfidence != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                '${_capitalize(record.secondEmotion!)} ${(record
                                    .secondConfidence! * 100).toStringAsFixed(
                                    0)}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: _getEmotionColor(
                                      record.secondEmotion!).withOpacity(0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],

                            if (record.thirdEmotion != null &&
                                record.thirdConfidence != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${_capitalize(record.thirdEmotion!)} ${(record
                                    .thirdConfidence! * 100).toStringAsFixed(
                                    0)}%',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: _getEmotionColor(record.thirdEmotion!).withOpacity(0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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