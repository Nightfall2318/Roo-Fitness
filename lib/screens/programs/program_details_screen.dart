import 'package:flutter/material.dart';
import '../../models/program/program.dart';
import '../../models/program/day_template.dart';
import '../../models/program/exercise_template.dart';
import '../../models/workout/workout.dart';
import '../../models/workout/exercise.dart';
import '../../services/database/database_helper.dart';
import 'exercise_logging_screen.dart';
import 'package:intl/intl.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final Program program;
  final bool isPreview;

  const ProgramDetailsScreen({
    super.key,
    required this.program,
    this.isPreview = false,
  });

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  final _dbHelper = DatabaseHelper();
  List<DayTemplate> _days = [];
  Map<int, List<ExerciseTemplate>> _dayExercises = {};
  bool _isLoading = true;

  // Tracks completed exercise data per day during active workout
  // Key: "dayId-exerciseIndex", Value: list of set data
  final Map<String, List<Map<String, dynamic>>> _exerciseResults = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final days = await _dbHelper.getDayTemplatesForProgram(widget.program.id!);
    Map<int, List<ExerciseTemplate>> dayEx = {};

    for (var day in days) {
      final exercises = await _dbHelper.getExerciseTemplatesForDay(day.id!);
      dayEx[day.id!] = exercises;
    }

    setState(() {
      _days = days;
      _dayExercises = dayEx;
      _isLoading = false;
    });
  }

  bool _isExerciseLogged(int dayId, int exIndex) {
    return _exerciseResults.containsKey('$dayId-$exIndex');
  }

  Future<void> _openExerciseLogger(
      DayTemplate day, ExerciseTemplate exercise, int exIndex) async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseLoggingScreen(exercise: exercise),
      ),
    );

    if (result != null) {
      setState(() {
        _exerciseResults['${day.id}-$exIndex'] = result;
      });
    }
  }

  Future<void> _finishDayWorkout(
      DayTemplate day, List<ExerciseTemplate> exercises) async {
    // Check if any exercises have been logged for this day
    bool hasLoggedExercises = false;
    for (int i = 0; i < exercises.length; i++) {
      if (_isExerciseLogged(day.id!, i)) {
        hasLoggedExercises = true;
        break;
      }
    }

    if (!hasLoggedExercises) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log at least one exercise before finishing!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final workout = Workout(
        title: day.routineName,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        durationMinutes: 60,
        type: day.dayOfWeek,
      );

      final workoutId = await _dbHelper.insertWorkout(workout);

      for (int i = 0; i < exercises.length; i++) {
        final key = '${day.id}-$i';
        if (_exerciseResults.containsKey(key)) {
          final sets = _exerciseResults[key]!;
          for (var set in sets) {
            if (set['completed'] == true) {
              final actualEx = Exercise(
                workoutId: workoutId,
                name: exercises[i].exerciseName,
                sets: 1,
                reps: set['reps'] as int,
                weight: set['weight'] as double,
              );
              await _dbHelper.insertExercise(actualEx);
            }
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Workout Logged! 💪'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          widget.program.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: widget.isPreview
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF003CCF)),
                  tooltip: 'Edit Program',
                  onPressed: () => _editProgram(),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final exercises = _dayExercises[day.id!] ?? [];
                    return _buildDayCard(day, exercises);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No routines set up yet.',
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Edit this program to add training days.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDayCard(DayTemplate day, List<ExerciseTemplate> exercises) {
    // Count completed exercises for this day
    int completedCount = 0;
    for (int i = 0; i < exercises.length; i++) {
      if (_isExerciseLogged(day.id!, i)) completedCount++;
    }
    bool allDone = exercises.isNotEmpty && completedCount == exercises.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone ? Colors.green.shade300 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isPreview
                  ? const Color(0xFFF8F9FB)
                  : allDone
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF0F4FF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.dayOfWeek.toUpperCase(),
                      style: TextStyle(
                        color: allDone
                            ? Colors.green
                            : const Color(0xFF003CCF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.routineName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (!widget.isPreview && exercises.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: allDone ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      allDone
                          ? 'COMPLETE ✓'
                          : '$completedCount / ${exercises.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: allDone
                            ? Colors.white
                            : const Color(0xFF003CCF),
                      ),
                    ),
                  ),
                if (widget.isPreview)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${exercises.length} exercises',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Exercise list
          if (exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No exercises added to this routine.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ...List.generate(exercises.length, (exIndex) {
              final ex = exercises[exIndex];
              final isLogged = _isExerciseLogged(day.id!, exIndex);

              if (widget.isPreview) {
                // Preview mode: read-only exercise row
                return _buildPreviewExerciseRow(ex, exIndex == exercises.length - 1);
              } else {
                // Active mode: clickable exercise card
                return _buildActiveExerciseCard(day, ex, exIndex,
                    isLogged, exIndex == exercises.length - 1);
              }
            }),

          // Finish day button (active mode only)
          if (!widget.isPreview && exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () => _finishDayWorkout(day, exercises),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allDone
                      ? Colors.green
                      : const Color(0xFF003CCF),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  allDone ? 'SAVE WORKOUT ✓' : 'FINISH & LOG',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewExerciseRow(ExerciseTemplate ex, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center,
                size: 16, color: Color(0xFF003CCF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              ex.exerciseName,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ex.targetSets} × ${ex.targetReps}',
              style: const TextStyle(
                color: Color(0xFF003CCF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveExerciseCard(DayTemplate day, ExerciseTemplate ex,
      int exIndex, bool isLogged, bool isLast) {
    return GestureDetector(
      onTap: () => _openExerciseLogger(day, ex, exIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 16 : 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLogged ? const Color(0xFFE8F5E9) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLogged ? Colors.green.shade300 : Colors.grey.shade200,
            width: isLogged ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Exercise icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLogged ? Colors.green : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLogged ? Icons.check : Icons.fitness_center,
                size: 20,
                color: isLogged ? Colors.white : const Color(0xFF003CCF),
              ),
            ),
            const SizedBox(width: 14),

            // Exercise name + target
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.exerciseName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: isLogged
                          ? TextDecoration.lineThrough
                          : null,
                      color: isLogged ? Colors.green.shade700 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLogged
                        ? _getLoggedSummary(day.id!, exIndex)
                        : '${ex.targetSets} sets × ${ex.targetReps} reps',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLogged
                          ? Colors.green.shade600
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Tap indicator
            Icon(
              isLogged ? Icons.edit_outlined : Icons.chevron_right,
              color: isLogged ? Colors.green : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getLoggedSummary(int dayId, int exIndex) {
    final key = '$dayId-$exIndex';
    final sets = _exerciseResults[key];
    if (sets == null) return '';

    final completedSets = sets.where((s) => s['completed'] == true).toList();
    if (completedSets.isEmpty) return 'No sets completed';

    return '${completedSets.length} sets logged ✓';
  }

  void _editProgram() {
    // Navigate to the edit/add workout screen with the existing program data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Color(0xFF003CCF),
      ),
    );
  }
}
