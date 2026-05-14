import 'package:flutter/material.dart';
import '../../models/workout/workout.dart';
import '../../models/workout/exercise.dart';
import '../../models/exercise/exercise_library.dart';
import '../../services/database/database_helper.dart';
import 'package:intl/intl.dart';

class QuickWorkoutScreen extends StatefulWidget {
  const QuickWorkoutScreen({super.key});

  @override
  State<QuickWorkoutScreen> createState() => _QuickWorkoutScreenState();
}

class _QuickWorkoutScreenState extends State<QuickWorkoutScreen> {
  final _dbHelper = DatabaseHelper();
  final _titleController = TextEditingController(text: 'Quick Workout');
  final List<Exercise> _loggedExercises = [];
  List<ExerciseLibrary> _library = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final library = await _dbHelper.getLibraryExercises();
    setState(() => _library = library);
  }

  void _addCustomExercise() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Exercise'),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: 'e.g., Diamond Pushups')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final exercise = ExerciseLibrary(name: nameController.text, category: 'Custom', isCustom: true);
                await _dbHelper.insertLibraryExercise(exercise);
                _loadLibrary();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _logExercise(ExerciseLibrary libItem) {
    setState(() {
      _loggedExercises.add(Exercise(
        workoutId: 0, // Temporary
        name: libItem.name,
        sets: 3,
        reps: 10,
        weight: 0,
      ));
    });
  }

  Future<void> _saveWorkout() async {
    final workout = Workout(
      title: _titleController.text,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      durationMinutes: 45,
      type: 'Quick Session',
    );

    try {
      final workoutId = await _dbHelper.insertWorkout(workout);

      for (var ex in _loggedExercises) {
        final finalEx = Exercise(
          workoutId: workoutId,
          name: ex.name,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
        );
        await _dbHelper.insertExercise(finalEx);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout Logged!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Quick Workout'), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(controller: _titleController, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _loggedExercises.length,
              itemBuilder: (context, index) {
                final ex = _loggedExercises[index];
                return ListTile(title: Text(ex.name), subtitle: Text('${ex.sets} sets x ${ex.reps} reps'), trailing: const Icon(Icons.check, color: Colors.green));
              },
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ADD EXERCISES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextButton(onPressed: _addCustomExercise, child: const Text('+ ADD CUSTOM', style: TextStyle(fontSize: 10))),
                  ],
                ),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _library.map((item) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ActionChip(label: Text(item.name), onPressed: () => _logExercise(item)),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveWorkout,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003CCF), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('FINISH WORKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
