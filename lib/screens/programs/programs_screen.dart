import 'package:flutter/material.dart';
import '../../services/database/database_helper.dart';
import '../../models/program/active_program.dart';
import '../../models/program/program.dart';
import 'program_details_screen.dart';
import 'browse_templates_screen.dart';
import '../settings/settings_screen.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('My Programs', style: TextStyle(color: Color(0xFF003CCF), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBrowseHeader(),
          Expanded(
            child: FutureBuilder<List<ActiveProgram>>(
              future: _dbHelper.getActivePrograms(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final activePrograms = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: activePrograms.length,
                  itemBuilder: (context, index) {
                    return _buildActiveProgramCard(activePrograms[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BrowseTemplatesScreen())).then((_) => setState(() {}));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF003CCF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.explore_outlined, color: Colors.white),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Browse Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Start a new training program', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No active programs', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Browse the library to start one!', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActiveProgramCard(ActiveProgram active) {
    return FutureBuilder<Program?>(
      future: _dbHelper.getProgramById(active.templateId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final template = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Week ${active.currentWeek} of ${template.durationWeeks}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: active.currentWeek / template.durationWeeks,
                  backgroundColor: const Color(0xFFF0F4FF),
                  color: const Color(0xFF003CCF),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProgramDetailsScreen(program: template)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F4FF),
                  foregroundColor: const Color(0xFF003CCF),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('CONTINUE TRAINING', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}