import 'package:flutter/material.dart';
import 'screens/programs/add_workout_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/programs/programs_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/logging/quick_workout_screen.dart';
import 'services/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-initialize the database
  await DatabaseHelper().database;
  
  runApp(const RooFitnessApp());
}

class RooFitnessApp extends StatelessWidget {
  const RooFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roo Fitness',
      theme: ThemeData(
        primaryColor: const Color(0xFF003CCF),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // 0: Dashboard, 1: Programs, 2: Progress, 3: Profile, 4: Add Workout
  int _selectedIndex = 0; 

  final List<Widget> _pages = [
    const DashboardScreen(),
    const ProgramsScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildOption(
                        context, 
                        Icons.auto_awesome, 
                        'Design Program Template', 
                        'Create a multi-week schedule like PPL.',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => const AddWorkoutScreen(),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 20),
                      _buildOption(
                        context, 
                        Icons.flash_on, 
                        'Log Quick Workout', 
                        'Track a spontaneous, single session.',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QuickWorkoutScreen()),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF003CCF),
            shape: const CircleBorder(),
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
      bottomNavigationBar: BottomAppBar(
        height: 70,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: Colors.white,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // LEFT SIDE
            Expanded(child: _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard')),
            Expanded(child: _buildNavItem(1, Icons.fitness_center, 'Programs')),
            
            // THE CENTER GAP
            const SizedBox(width: 65), 
            
            // RIGHT SIDE
            Expanded(child: _buildNavItem(2, Icons.show_chart, 'Progress')),
            Expanded(child: _buildNavItem(3, Icons.person, 'Profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF003CCF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: isSelected ? const Color(0xFF003CCF) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: isSelected ? const Color(0xFF003CCF) : Colors.grey.shade400, 
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}