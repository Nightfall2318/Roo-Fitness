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
    String selectedCat = 'Chest';
    String selectedEquip = 'dumbbells';
    String selectedType = 'isolation';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Exercise Name', hintText: 'e.g., Diamond Pushups')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Abs', 'Cardio', 'Custom'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedCat = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedEquip,
                  decoration: const InputDecoration(labelText: 'Equipment'),
                  items: ['barbell', 'dumbbells', 'cable', 'machine', 'bodyweight', 'plate', 'ez-bar', 'none'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedEquip = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Kinetic Type'),
                  items: ['compound', 'isolation'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final exercise = ExerciseLibrary(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    cat: selectedCat.toLowerCase(),
                    equip: selectedEquip,
                    type: selectedType,
                    isCustom: true,
                  );
                  await _dbHelper.insertLibraryExercise(exercise);
                  _loadLibrary();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _logExercise(ExerciseLibrary libItem) {
    setState(() {
      _loggedExercises.add(Exercise(
        workoutId: 0, // Temporary
        name: libItem.name,
        sets: 1,
        reps: 0,
        weight: 0,
      ));
    });
  }

  void _showExercisePicker() {
    // Group exercises by category
    final Map<String, List<ExerciseLibrary>> grouped = {};
    for (var ex in _library) {
      final cat = ex.cat[0].toUpperCase() + ex.cat.substring(1);
      grouped.putIfAbsent(cat, () => []).add(ex);
    }
    final categories = grouped.keys.toList()..sort();

    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCategory == null ? 'Categories' : selectedCategory!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (selectedCategory == null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _addCustomExercise();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: () => setModalState(() => selectedCategory = null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedCategory == null
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return InkWell(
                            onTap: () => setModalState(() => selectedCategory = cat),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF003CCF).withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getCategoryIcon(cat), color: const Color(0xFF003CCF), size: 32),
                                  const SizedBox(height: 8),
                                  Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('${grouped[cat]!.length} exercises', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        itemCount: grouped[selectedCategory]!.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = grouped[selectedCategory]![index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text('${item.equip} • ${item.type}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF003CCF)),
                            onTap: () {
                              _logExercise(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('chest')) return Icons.fitness_center;
    if (category.contains('back')) return Icons.reorder;
    if (category.contains('shoulders')) return Icons.architecture;
    if (category.contains('arms')) return Icons.shutter_speed;
    if (category.contains('legs')) return Icons.directions_walk;
    if (category.contains('abs')) return Icons.grid_view;
    return Icons.fitness_center;
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
                InkWell(
                  onTap: _showExercisePicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF003CCF).withValues(alpha: 0.1)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.add_circle_outline, color: Color(0xFF003CCF)),
                        SizedBox(height: 8),
                        Text('TAP TO ADD EXERCISES', style: TextStyle(color: Color(0xFF003CCF), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
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
