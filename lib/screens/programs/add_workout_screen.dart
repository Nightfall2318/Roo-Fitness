import 'package:flutter/material.dart';
import '../../models/program/program.dart';
import '../../models/program/day_template.dart';
import '../../models/program/exercise_template.dart';
import '../../models/exercise/exercise_library.dart';
import '../../services/database/database_helper.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  int _currentStep = 0;
  final _dbHelper = DatabaseHelper();
  
  // Step 1 Data
  final _nameController = TextEditingController();
  final _weeksController = TextEditingController(text: '12');
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _selectedDays = {};
  
  // Step 2 Data
  final Map<String, TextEditingController> _routineControllers = {};
  
  // Step 3 Data
  final Map<String, List<ExerciseTemplate>> _dayExercises = {};
  List<ExerciseLibrary> _library = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final lib = await _dbHelper.getLibraryExercises();
    setState(() => _library = lib);
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

  void _onDayToggled(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
        _routineControllers.remove(day);
        _dayExercises.remove(day);
      } else {
        _selectedDays.add(day);
        _routineControllers[day] = TextEditingController();
        _dayExercises[day] = [];
      }
    });
  }

  void _addExerciseToDay(String day, ExerciseLibrary libItem) {
    setState(() {
      _dayExercises[day]!.add(ExerciseTemplate(
        dayTemplateId: 0, // Temporary
        exerciseName: libItem.name,
        targetSets: 3,
        targetReps: 10,
      ));
    });
  }

  Future<void> _saveProgram() async {
    try {
      final program = Program(
        name: _nameController.text,
        durationWeeks: int.tryParse(_weeksController.text) ?? 12,
      );

      final programId = await _dbHelper.insertProgram(program);

      for (var day in _selectedDays) {
        final dayId = await _dbHelper.insertDayTemplate(DayTemplate(
          programId: programId,
          dayOfWeek: day,
          routineName: _routineControllers[day]?.text ?? 'Workout',
        ));

        for (var ex in _dayExercises[day]!) {
          await _dbHelper.insertExerciseTemplate(ExerciseTemplate(
            dayTemplateId: dayId,
            exerciseName: ex.exerciseName,
            targetSets: ex.targetSets,
            targetReps: ex.targetReps,
          ));
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full Program Saved!'), backgroundColor: Colors.green));
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
      appBar: AppBar(
        title: Text(_getStepTitle(), style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(_currentStep == 0 ? Icons.close : Icons.arrow_back),
          onPressed: () => _currentStep == 0 ? Navigator.pop(context) : setState(() => _currentStep--),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildCurrentStep())),
          _buildFooter(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    if (_currentStep == 0) return 'Design Program';
    if (_currentStep == 1) return 'Routines';
    return 'Exercises';
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        children: [
          _buildStepDot(0, 'Basics'),
          _buildLine(0),
          _buildStepDot(1, 'Days'),
          _buildLine(1),
          _buildStepDot(2, 'Exercises'),
        ],
      ),
    );
  }

  Widget _buildLine(int afterStep) {
    return Expanded(child: Container(height: 2, color: _currentStep > afterStep ? const Color(0xFF003CCF) : Colors.grey.shade200));
  }

  Widget _buildStepDot(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(children: [
      CircleAvatar(radius: 12, backgroundColor: isActive ? const Color(0xFF003CCF) : Colors.grey.shade200, 
      child: Text('${step + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF003CCF) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) return _buildStep1();
    if (_currentStep == 1) return _buildStep2();
    return _buildStep3();
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PROGRAM NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g., Push Pull Legs')),
      const SizedBox(height: 30),
      const Text('DURATION (WEEKS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      TextField(controller: _weeksController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '12')),
      const SizedBox(height: 40),
      const Text('CHOOSE YOUR TRAINING DAYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _days.map((day) {
        bool isSelected = _selectedDays.contains(day);
        return GestureDetector(onTap: () => _onDayToggled(day),
          child: CircleAvatar(radius: 22, backgroundColor: isSelected ? const Color(0xFF003CCF) : const Color(0xFFF0F4FF),
            child: Text(day[0], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))));
      }).toList()),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('NAME YOUR ROUTINES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      ..._selectedDays.map((day) => Padding(padding: const EdgeInsets.only(bottom: 20),
        child: Row(children: [
          SizedBox(width: 60, child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: TextField(controller: _routineControllers[day], decoration: InputDecoration(hintText: 'e.g., Push Day', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
        ])))
    ]);
  }

  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ASSIGN EXERCISES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      ..._selectedDays.map((day) => _buildDayExercisePicker(day)),
    ]);
  }

  Widget _buildDayExercisePicker(String day) {
    final exercises = _dayExercises[day]!;
    final routineName = _routineControllers[day]?.text ?? 'Workout';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$day: $routineName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003CCF))),
        const SizedBox(height: 15),
        ...exercises.map((ex) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('• ${ex.exerciseName} (${ex.targetSets}x${ex.targetReps})', style: const TextStyle(fontSize: 13)),
        )),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => _showExercisePicker(day),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Exercise', style: TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }

  void _showExercisePicker(String day) {
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
                              _addExerciseToDay(day, item);
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

  Widget _buildFooter() {
    bool canProceed = _currentStep == 0 ? (_nameController.text.isNotEmpty && _selectedDays.isNotEmpty) : true;
    String label = _currentStep < 2 ? 'NEXT STEP' : 'SAVE FULL PROGRAM';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
      child: ElevatedButton(
        onPressed: canProceed ? (_currentStep < 2 ? () => setState(() => _currentStep++) : _saveProgram) : null,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003CCF), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}