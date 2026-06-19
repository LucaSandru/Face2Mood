import 'package:flutter/material.dart';

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

class SaveMoodDetailsSheet extends StatefulWidget {
  final List<String> people;
  final List<String> emotionOptions;
  final Color Function(String emotion) emotionColor;

  const SaveMoodDetailsSheet({
    super.key,
    required this.people,
    required this.emotionOptions,
    required this.emotionColor,
  });

  @override
  State<SaveMoodDetailsSheet> createState() => _SaveMoodDetailsSheetState();
}

class _SaveMoodDetailsSheetState extends State<SaveMoodDetailsSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _newPersonController = TextEditingController();

  String? _selectedEmotion;
  bool _emotionError = false;

  late String _selectedPerson;
  bool _addingNewPerson = false;

  int _wordCount = 0;
  bool _personError = false;

  @override
  void initState() {
    super.initState();
    _selectedPerson = widget.people.isNotEmpty
        ? widget.people.first
        : 'You - Main User';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _newPersonController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    int count = 0;

    for (final word in text.trim().split(' ')) {
      if (word.isNotEmpty) count++;
    }

    return count;
  }

  void _confirmSave() {
    final finalPersonName = _addingNewPerson
        ? _newPersonController.text.trim()
        : _selectedPerson;

    if (finalPersonName.isEmpty) {
      setState(() {
        _personError = true;
      });
      return;
    }

    if (_selectedEmotion == null) {
      setState(() {
        _emotionError = true;
      });
      return;
    }

    Navigator.of(context).pop(
      MoodSaveDetails(
        personName: finalPersonName,
        userDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        userDominantEmotion: _selectedEmotion!,
      ),
    );
  }

  Widget _selectablePill({
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withOpacity(0.28)
              : const Color(0xFF20202C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? selectedColor : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
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
                ...widget.people.map((person) {
                  final selected = !_addingNewPerson && _selectedPerson == person;

                  return _selectablePill(
                    label: person,
                    selected: selected,
                    selectedColor: Colors.greenAccent,
                    onTap: () {
                      setState(() {
                        _addingNewPerson = false;
                        _selectedPerson = person;
                        _newPersonController.clear();
                        _personError = false;
                      });
                    },
                  );
                }),

                _selectablePill(
                  label: '+ Add new person',
                  selected: _addingNewPerson,
                  selectedColor: Colors.purpleAccent,
                  onTap: () {
                    setState(() {
                      _addingNewPerson = true;
                      _selectedPerson = '';
                      _personError = false;
                    });
                  },
                ),
              ],
            ),

            if (_addingNewPerson) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _newPersonController,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) {
                  if (_personError) {
                    setState(() {
                      _personError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'New person name',
                  hintText: 'Example: Mum, Dad, Brother',
                  errorText: _personError ? 'Please enter a person name.' : null,
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
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _wordCount = _countWords(value);
                });
              },
              decoration: InputDecoration(
                labelText: 'Short description',
                hintText: 'Maximum 30 words...',
                errorText: _wordCount > 30 ? 'Maximum 30 words allowed' : null,
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
              '$_wordCount / 30 words',
              style: TextStyle(
                color: _wordCount > 30 ? Colors.redAccent : Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Your believed dominant emotion',
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
              children: widget.emotionOptions.map((emotion) {
                final selected = _selectedEmotion == emotion;
                final color = widget.emotionColor(emotion);

                return _selectablePill(
                  label: emotion.toUpperCase(),
                  selected: selected,
                  selectedColor: color,
                  onTap: () {
                    setState(() {
                      _selectedEmotion = emotion;
                      _emotionError = false;
                    });
                  },
                );
              }).toList(),
            ),

            if (_emotionError) ...[
              const SizedBox(height: 8),
              const Text(
                'Please select your believed emotion before saving.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _wordCount > 30 ? null : _confirmSave,
                    child: const Text('Confirm Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}