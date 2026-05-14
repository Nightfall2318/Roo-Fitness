import 'package:flutter/material.dart';
import '../../models/workout/workout.dart';
import '../../models/workout/exercise.dart';
import '../../models/program/day_template.dart';
import '../../models/program/exercise_template.dart';
import '../../services/database/database_helper.dart';
import '../../services/settings/settings_service.dart';
import 'package:intl/intl.dart';

class LoggingScreen extends StatefulWidget {
  final DayTemplate dayTemplate;
  final List<ExerciseTemplate> exerciseTemplates;

  const LoggingScreen({
    super.key,
    required this.dayTemplate,
    required this.exerciseTemplates,
  });

  @override
  State<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends State<LoggingScreen> {
  final _dbHelper = DatabaseHelper();
  final List<List<SetControllers>> _exerciseSets = [];
  String _unit = 'KG';
  double _weightIncrement = 2.5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    for (var template in widget.exerciseTemplates) {
      final sets = <SetControllers>[];
      for (int i = 0; i < template.targetSets; i++) {
        sets.add(SetControllers(
          weight: TextEditingController(text: '0.0'),
          reps: TextEditingController(text: template.targetReps.toString()),
        ));
      }
      _exerciseSets.add(sets);
    }
  }

  Future<void> _loadSettings() async {
    final unit = await SettingsService.getUnit();
    final inc = await SettingsService.getIncrement();
    setState(() {
      _unit = unit;
      _weightIncrement = inc;
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final template = widget.exerciseTemplates[exerciseIndex];
      _exerciseSets[exerciseIndex].add(SetControllers(
        weight: TextEditingController(text: '0.0'),
        reps: TextEditingController(text: template.targetReps.toString()),
      ));
    });
  }

  void _removeSet(int exerciseIndex) {
    if (_exerciseSets[exerciseIndex].length > 1) {
      setState(() {
        _exerciseSets[exerciseIndex].last.dispose();
        _exerciseSets[exerciseIndex].removeLast();
      });
    }
  }

  void _adjustWeight(int exIndex, int sIndex, double delta) {
    final controller = _exerciseSets[exIndex][sIndex].weight;
    double current = double.tryParse(controller.text) ?? 0.0;
    setState(() {
      controller.text = (current + delta).clamp(0.0, 1000.0).toStringAsFixed(1);
    });
  }

  void _adjustReps(int exIndex, int sIndex, int delta) {
    final controller = _exerciseSets[exIndex][sIndex].reps;
    int current = int.tryParse(controller.text) ?? 0;
    setState(() {
      controller.text = (current + delta).clamp(0, 1000).toString();
    });
  }

  @override
  void dispose() {
    for (var sets in _exerciseSets) {
      for (var s in sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _finishWorkout() async {
    try {
      final workout = Workout(
        title: widget.dayTemplate.routineName,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        durationMinutes: 60,
        type: widget.dayTemplate.dayOfWeek,
      );

      final workoutId = await _dbHelper.insertWorkout(workout);

      for (int i = 0; i < widget.exerciseTemplates.length; i++) {
        final sets = _exerciseSets[i];
        for (var set in sets) {
          final actualEx = Exercise(
            workoutId: workoutId,
            name: widget.exerciseTemplates[i].exerciseName,
            sets: 1,
            reps: int.tryParse(set.reps.text) ?? 0,
            weight: double.tryParse(set.weight.text) ?? 0.0,
          );
          await _dbHelper.insertExercise(actualEx);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout Logged!'), backgroundColor: Colors.green));
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Log Performance'), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: widget.exerciseTemplates.length,
              itemBuilder: (context, index) => _buildExerciseCard(index),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int exIndex) {
    final template = widget.exerciseTemplates[exIndex];
    final sets = _exerciseSets[exIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(template.exerciseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Row(
                children: [
                  IconButton(onPressed: () => _removeSet(exIndex), icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
                  Text('${sets.length} Sets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  IconButton(onPressed: () => _addSet(exIndex), icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...List.generate(sets.length, (sIndex) => _buildSetSection(exIndex, sIndex)),
        ],
      ),
    );
  }

  Widget _buildSetSection(int exIndex, int sIndex) {
    final controllers = _exerciseSets[exIndex][sIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, backgroundColor: const Color(0xFFF0F4FF), child: Text('${sIndex + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF003CCF)))),
              const SizedBox(width: 10),
              const Text('SET DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          _buildControlRow('Weight ($_unit)', controllers.weight, () => _adjustWeight(exIndex, sIndex, -_weightIncrement), () => _adjustWeight(exIndex, sIndex, _weightIncrement)),
          const Divider(height: 30),
          _buildControlRow('Reps', controllers.reps, () => _adjustReps(exIndex, sIndex, -1), () => _adjustReps(exIndex, sIndex, 1)),
        ],
      ),
    );
  }

  Widget _buildControlRow(String label, TextEditingController controller, VoidCallback onMinus, VoidCallback onPlus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Row(
          children: [
            _circleButton(Icons.remove, onMinus),
            SizedBox(
              width: 70,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              ),
            ),
            _circleButton(Icons.add, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF0F4FF), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: const Color(0xFF003CCF)),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: ElevatedButton(
        onPressed: _finishWorkout,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003CCF), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('SAVE SESSION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SetControllers {
  final TextEditingController weight;
  final TextEditingController reps;
  SetControllers({required this.weight, required this.reps});
  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}
