import 'package:flutter/material.dart';
import '../../services/database/database_helper.dart';
import '../../models/program/program.dart';
import '../../models/program/active_program.dart';
import 'program_details_screen.dart';
import 'add_workout_screen.dart';
import 'package:intl/intl.dart';

class BrowseTemplatesScreen extends StatefulWidget {
  const BrowseTemplatesScreen({super.key});

  @override
  State<BrowseTemplatesScreen> createState() => _BrowseTemplatesScreenState();
}

class _BrowseTemplatesScreenState extends State<BrowseTemplatesScreen> {
  final _dbHelper = DatabaseHelper();

  Future<void> _startProgram(Program template) async {
    final active = ActiveProgram(
      templateId: template.id!,
      startDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    await _dbHelper.enrollInProgram(active);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Started ${template.name}!'), backgroundColor: Colors.green));
    Navigator.pop(context); // Close browse
  }

  Future<void> _deleteProgram(Program program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Are you sure you want to delete "${program.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteProgram(program.id!);
      if (!mounted) return;
      setState(() {}); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${program.name} deleted'), backgroundColor: Colors.grey.shade800),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Program Templates', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF003CCF)),
            tooltip: 'Create New Program',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Program>>(
        future: _dbHelper.getPrograms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No templates found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Program'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003CCF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final program = snapshot.data![index];
              return _buildTemplateCard(program);
            },
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(Program program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003CCF), Color(0xFF00298A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003CCF).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${program.durationWeeks} Weeks',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editProgram(program);
                    } else if (value == 'delete') {
                      _deleteProgram(program);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF003CCF)),
                          SizedBox(width: 10),
                          Text('Edit Program'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProgramDetailsScreen(
                            program: program,
                            isPreview: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('PREVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startProgram(program),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF003CCF),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('START', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProgram(Program program) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Color(0xFF003CCF),
      ),
    );
  }
}
