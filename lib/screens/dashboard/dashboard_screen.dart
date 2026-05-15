import 'package:flutter/material.dart';
import '../../services/database/database_helper.dart';
import '../../models/workout/workout.dart';
import '../settings/settings_screen.dart';
import '../programs/program_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Roo Fitness', style: TextStyle(color: Color(0xFF003CCF), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundColor: Colors.grey.shade200, radius: 18, child: const Icon(Icons.person, size: 20, color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('Your progress at a glance.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            
            // Primary Blue Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF003CCF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fitness_center, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text('TOTAL WORKOUTS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: _dbHelper.getWorkoutCount(),
                    builder: (context, snapshot) {
                      String count = snapshot.hasData ? snapshot.data.toString() : '...';
                      return Text(count, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold));
                    }
                  ),
                  const SizedBox(height: 8),
                  const Text('FROM YOUR LOCAL DATABASE', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Last Workout Card
            FutureBuilder<Workout?>(
              future: _dbHelper.getLastWorkout(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink(); // Hide if no workouts yet
                }
                final workout = snapshot.data!;
                return GestureDetector(
                  onTap: () => _navigateToActiveProgram(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('● LAST WORKOUT', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                            Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(workout.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${workout.type} • ${workout.durationMinutes} mins', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildChip(workout.type),
                            const SizedBox(width: 8),
                            _buildChip(workout.date),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003CCF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VIEW MAIN DASHBOARD →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToActiveProgram() async {
    final activePrograms = await _dbHelper.getActivePrograms();
    if (activePrograms.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active program. Start one from the library!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final active = activePrograms.first;
    final program = await _dbHelper.getProgramById(active.templateId);
    if (program == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailsScreen(program: program),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}