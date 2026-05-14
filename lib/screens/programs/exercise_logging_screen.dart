import 'package:flutter/material.dart';
import '../../models/program/exercise_template.dart';
import '../../services/settings/settings_service.dart';

class ExerciseLoggingScreen extends StatefulWidget {
  final ExerciseTemplate exercise;

  const ExerciseLoggingScreen({super.key, required this.exercise});

  @override
  State<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends State<ExerciseLoggingScreen> {
  final List<SetControllers> _sets = [];
  String _unit = 'KG';
  double _weightIncrement = 2.5;
  final List<bool> _completedSets = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    for (int i = 0; i < widget.exercise.targetSets; i++) {
      _sets.add(SetControllers(
        weight: TextEditingController(text: '0.0'),
        reps: TextEditingController(text: widget.exercise.targetReps.toString()),
      ));
      _completedSets.add(false);
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

  void _addSet() {
    setState(() {
      _sets.add(SetControllers(
        weight: TextEditingController(text: '0.0'),
        reps: TextEditingController(text: widget.exercise.targetReps.toString()),
      ));
      _completedSets.add(false);
    });
  }

  void _removeSet() {
    if (_sets.length > 1) {
      setState(() {
        _sets.last.dispose();
        _sets.removeLast();
        _completedSets.removeLast();
      });
    }
  }

  void _adjustWeight(int sIndex, double delta) {
    final controller = _sets[sIndex].weight;
    double current = double.tryParse(controller.text) ?? 0.0;
    setState(() {
      controller.text = (current + delta).clamp(0.0, 1000.0).toStringAsFixed(1);
    });
  }

  void _adjustReps(int sIndex, int delta) {
    final controller = _sets[sIndex].reps;
    int current = int.tryParse(controller.text) ?? 0;
    setState(() {
      controller.text = (current + delta).clamp(0, 1000).toString();
    });
  }

  void _toggleSetComplete(int sIndex) {
    setState(() {
      _completedSets[sIndex] = !_completedSets[sIndex];
    });
  }

  @override
  void dispose() {
    for (var s in _sets) {
      s.dispose();
    }
    super.dispose();
  }

  void _saveExercise() {
    // Collect set data and return it to the parent screen
    final List<Map<String, dynamic>> setData = [];
    for (int i = 0; i < _sets.length; i++) {
      setData.add({
        'weight': double.tryParse(_sets[i].weight.text) ?? 0.0,
        'reps': int.tryParse(_sets[i].reps.text) ?? 0,
        'completed': _completedSets[i],
      });
    }
    Navigator.pop(context, setData);
  }

  int get _completedCount => _completedSets.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          widget.exercise.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${widget.exercise.targetSets} × ${widget.exercise.targetReps}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      '$_completedCount / ${_sets.length} sets done',
                      style: TextStyle(
                        color: _completedCount == _sets.length
                            ? Colors.green
                            : const Color(0xFF003CCF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _sets.isEmpty ? 0 : _completedCount / _sets.length,
                    backgroundColor: const Color(0xFFF0F4FF),
                    color: _completedCount == _sets.length
                        ? Colors.green
                        : const Color(0xFF003CCF),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Set / Remove controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SETS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _removeSet,
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 22),
                    ),
                    Text(
                      '${_sets.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      onPressed: _addSet,
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.green, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _sets.length,
              itemBuilder: (context, index) => _buildSetCard(index),
            ),
          ),

          // Save button
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSetCard(int sIndex) {
    final controllers = _sets[sIndex];
    final isComplete = _completedSets[sIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.green.shade300 : Colors.grey.shade200,
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Set header
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isComplete
                    ? Colors.green
                    : const Color(0xFFF0F4FF),
                child: isComplete
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${sIndex + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003CCF),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Text(
                'Set ${sIndex + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _toggleSetComplete(sIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isComplete ? 'DONE ✓' : 'MARK DONE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.white : const Color(0xFF003CCF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weight row
          _buildControlRow(
            'Weight ($_unit)',
            controllers.weight,
            () => _adjustWeight(sIndex, -_weightIncrement),
            () => _adjustWeight(sIndex, _weightIncrement),
          ),
          const Divider(height: 24),

          // Reps row
          _buildControlRow(
            'Reps',
            controllers.reps,
            () => _adjustReps(sIndex, -1),
            () => _adjustReps(sIndex, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(String label, TextEditingController controller,
      VoidCallback onMinus, VoidCallback onPlus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Row(
          children: [
            _circleButton(Icons.remove, onMinus),
            SizedBox(
              width: 70,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero),
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
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF003CCF)),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveExercise,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003CCF),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'SAVE EXERCISE',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
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
