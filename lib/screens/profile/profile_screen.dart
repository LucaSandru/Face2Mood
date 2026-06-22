import 'package:flutter/material.dart';
import '../../services/database_service.dart';


/// Profile and application information screen.
/// Displays privacy, app information, and local data controls.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Database service used only for clearing locally stored mood records.
  final DatabaseService _dbService = DatabaseService();


  /// Shows a confirmation pop-up before permanently deleting all mood records.
  void _clearData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171522),
        title: const Text(
          'Clear All Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete your entire mood history. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.clearAllMoods();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared.')),
                );
              }
            },
            child: const Text(
              'Delete Everything',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a reusable section title for profile information groups.
  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }


  /// Builds a reusable card container for grouped profile information.
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF4CAF50),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You - Main User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Private Local Profile',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildSectionTitle('PRIVACY & DATA', const Color(0xFF4CAF50)),
            const SizedBox(height: 16),

            _buildCard(
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.shield_outlined, color: Colors.white70),
                  title: Text(
                    'On-Device Processing',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Photos and emotion records are never sent to a server.",
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                Divider(color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.storage_outlined, color: Colors.white70),
                  title: Text(
                    'Local Storage',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Mood history is stored only in this phone\'s database.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('APP INFORMATION', const Color(0xFF4CAF50)),
            const SizedBox(height: 16),

            _buildCard(
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.psychology_alt_outlined,
                      color: Colors.white70),
                  title: Text(
                    'Smart Emotion Analysis',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Analyzes facial expressions in real time.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                Divider(color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                  Icon(Icons.emoji_emotions_outlined, color: Colors.white70),
                  title: Text(
                    '7 Emotion Classes',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Angry, disgust, fear, happy, neutral, sad, and surprise.',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                Divider(color: Colors.white10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.phone_android, color: Colors.white70),
                  title: Text(
                    'Face2Mood v1.0.0',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Mobile emotion recognition and mood tracking app.",
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('DANGER ZONE', Colors.redAccent),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _clearData,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Mood History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}