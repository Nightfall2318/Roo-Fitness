import 'package:flutter/material.dart';
import '../../models/user/user_profile.dart';
import '../../services/database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _dbHelper.getProfile();
    setState(() => _profile = profile);
  }

  void _showEditDialog() {
    if (_profile == null) return;
    
    final weightController = TextEditingController(text: _profile!.weight.toString());
    final heightController = TextEditingController(text: _profile!.height.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
            TextField(controller: heightController, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedProfile = UserProfile(
                id: _profile!.id,
                name: _profile!.name,
                weight: double.tryParse(weightController.text) ?? _profile!.weight,
                height: double.tryParse(heightController.text) ?? _profile!.height,
                goal: _profile!.goal,
              );
              await _dbHelper.updateProfile(updatedProfile);
              _loadProfile();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateProfileDialog() {
    final nameController = TextEditingController();
    final goalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: goalController, decoration: const InputDecoration(labelText: 'Primary Goal (e.g. Build Muscle)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newProfile = UserProfile(
                name: nameController.text,
                weight: 0,
                height: 0,
                goal: goalController.text,
              );
              // Since we only want one user for now, we'll just insert it.
              // We need an insertProfile method in DatabaseHelper.
              await _dbHelper.insertProfile(newProfile);
              _loadProfile();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_outlined, size: 100, color: Color(0xFF003CCF)),
                const SizedBox(height: 24),
                const Text('Welcome to Roo Fitness!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Set up your profile to start tracking your progress.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _showCreateProfileDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003CCF),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CREATE MY PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Color(0xFF003CCF)), onPressed: _showEditDialog),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFFF0F4FF), child: Icon(Icons.person, size: 50, color: Color(0xFF003CCF))),
            const SizedBox(height: 16),
            Text(_profile!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(_profile!.goal, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Weight', '${_profile!.weight} kg'),
                _buildStatCard('Height', '${_profile!.height} cm'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
