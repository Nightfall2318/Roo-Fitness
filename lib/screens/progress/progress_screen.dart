import 'package:flutter/material.dart';
import '../../services/database/database_helper.dart';
import '../../models/workout/workout.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Journey', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _buildSummaryCard(),
            const SizedBox(height: 30),
            
            const Text('Activity Heatmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: const Center(child: Text('Chart Placeholder', style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: 30),
            
            const Text('Workout History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildWorkoutList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return FutureBuilder<int>(
      future: _dbHelper.getWorkoutCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF003CCF), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Sessions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('$count', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.trending_up, color: Colors.white, size: 40),
            ],
          ),
        );
      }
    );
  }

  Widget _buildWorkoutList() {
    return FutureBuilder<List<Workout>>(
      future: _dbHelper.getWorkouts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No workouts logged yet.'));
        }
        final workouts = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(workout.date, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  Text('${workout.durationMinutes}m', style: const TextStyle(color: Color(0xFF003CCF), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      }
    );
  }
}
