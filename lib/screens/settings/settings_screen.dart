import 'package:flutter/material.dart';
import '../../services/settings/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _unit = 'KG';
  double _increment = 2.5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final unit = await SettingsService.getUnit();
    final increment = await SettingsService.getIncrement();
    setState(() {
      _unit = unit;
      _increment = increment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Preferences'),
          _buildUnitToggle(),
          _buildIncrementPicker(),
          const SizedBox(height: 30),
          _buildSection('Account'),
          _buildSettingsTile(
            Icons.person_outline,
            'Personal Information',
            'Change your name and goals',
          ),
          _buildSettingsTile(
            Icons.notifications_none,
            'Notifications',
            'Manage alerts and reminders',
          ),
          const SizedBox(height: 30),
          _buildSection('Support'),
          _buildSettingsTile(
            Icons.help_outline,
            'Help Center',
            'FAQs and troubleshooting',
          ),
          _buildSettingsTile(
            Icons.info_outline,
            'About Roo Fitness',
            'Version 1.0.0',
          ),
          const SizedBox(height: 50),
          TextButton(
            onPressed: () {},
            child: const Text(
              'LOG OUT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Weight Units',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'KG', label: Text('KG')),
              ButtonSegment(value: 'LBS', label: Text('LBS')),
            ],
            selected: {_unit},
            onSelectionChanged: (newSelection) async {
              final newUnit = newSelection.first;
              await SettingsService.setUnit(newUnit);
              setState(() => _unit = newUnit);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementPicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Weight Increment',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          DropdownButton<double>(
            value: _increment,
            underline: const SizedBox(),
            items: [1.0, 2.5, 5.0]
                .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                .toList(),
            onChanged: (val) async {
              if (val != null) {
                await SettingsService.setIncrement(val);
                setState(() => _increment = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF003CCF), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
