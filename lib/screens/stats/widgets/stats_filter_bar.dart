import 'package:flutter/material.dart';

import 'reset_filters_button.dart';

class StatsFilterBar extends StatelessWidget {
  final String selectedPerson;
  final String selectedTimeRange;
  final String selectedStatisticType;
  final List<String> availablePeople;
  final List<String> statisticTypes;

  final ValueChanged<String> onPersonChanged;
  final ValueChanged<String> onTimeRangeChanged;
  final ValueChanged<String> onStatisticTypeChanged;
  final VoidCallback onResetFilters;

  const StatsFilterBar({
    super.key,
    required this.selectedPerson,
    required this.selectedTimeRange,
    required this.selectedStatisticType,
    required this.availablePeople,
    required this.statisticTypes,
    required this.onPersonChanged,
    required this.onTimeRangeChanged,
    required this.onStatisticTypeChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildUserFilter()),
            const SizedBox(width: 8),
            Expanded(child: _buildDateFilter()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatisticTypeFilter()),
            const SizedBox(width: 8),
            Expanded(
              child: ResetFiltersButton(
                onReset: onResetFilters,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserFilter() {
    return PopupMenuButton<String>(
      initialValue: selectedPerson,
      onSelected: onPersonChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Person: ',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Flexible(
              child: Text(
                selectedPerson == 'All' ? 'All users' : selectedPerson,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return availablePeople.map((String person) {
          return PopupMenuItem<String>(
            value: person,
            child: Text(person == 'All' ? 'All users' : person),
          );
        }).toList();
      },
    );
  }

  Widget _buildDateFilter() {
    const Map<String, String> options = {
      'all': 'All time',
      '1 Day': '1 Day',
      '1 Week': '1 Week',
      '1 Month': '1 Month',
      '1 Year': '1 Year',
    };

    return PopupMenuButton<String>(
      initialValue: selectedTimeRange,
      onSelected: onTimeRangeChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Time: ',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              options[selectedTimeRange] ?? selectedTimeRange,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white54,
              size: 14,
            ),
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
      initialValue: selectedStatisticType,
      onSelected: onStatisticTypeChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Type: ',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Expanded(
              child: Text(
                selectedStatisticType,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return statisticTypes.map((String type) {
          return PopupMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList();
      },
    );
  }
}