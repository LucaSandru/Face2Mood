import 'package:flutter/material.dart';
import 'services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;

  final DatabaseService _dbService = DatabaseService();

  void _clearData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171522),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete your entire mood history. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
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
            child: const Text('Delete Everything', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
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
                    'Your Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Local User',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'PRIVACY & DATA',
              style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF171522),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.shield_outlined, color: Colors.white70),
                    title: Text('On-Device Processing', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Your photos and emotions are never sent to a server.', style: TextStyle(color: Colors.white60)),
                  ),
                  Divider(color: Colors.white10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.storage_outlined, color: Colors.white70),
                    title: Text('Local Storage', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Mood history is stored only in this phone\'s database.', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'DANGER ZONE',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Face2Mood v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
