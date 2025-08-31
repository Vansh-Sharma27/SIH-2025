import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider_minimal.dart';
import '../theme/app_theme.dart';
import 'demo_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppStateProviderMinimal>(
        builder: (context, appState, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and title
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'YatraLive',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            '🏆 Smart India Hackathon 2025',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Real-time Bus Tracking System',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Demo buttons
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => _navigateToDemo('passenger'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.blue.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 56,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Passenger Interface',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '📱 Live Bus Tracking\n🔔 Arrival Notifications\n🗺️ Interactive Maps\n👥 Crowd Indicators',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => _navigateToDemo('driver'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade50,
                              Colors.teal.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.drive_eta_rounded,
                              size: 56,
                              color: AppTheme.accentColor,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Driver Interface',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '📍 GPS Location Sharing\n📊 Performance Analytics\n🎯 Route Management\n⚡ Emergency Features',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Project status
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.accentColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🚀 Development Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildStatusItem('✅', 'Phase 1: Foundation & Setup', true),
                        _buildStatusItem('✅', 'Phase 2: Backend Development', true),
                        _buildStatusItem('✅', 'Phase 3: Frontend Development', true),
                        _buildStatusItem('✅', 'Phase 4: Integration & Testing', true),
                        _buildStatusItem('🎯', 'Phase 5: Demo Preparation', true),
                        _buildStatusItem('🏆', 'Phase 6: Final Presentation', false),
                        
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '80% Complete - Ready for Hackathon!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusItem(String emoji, String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                color: isComplete ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
              ),
            ),
          ),
          if (isComplete)
            const Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 18,
            ),
        ],
      ),
    );
  }

  void _navigateToDemo(String userType) {
    final appState = Provider.of<AppStateProviderMinimal>(context, listen: false);
    appState.setUserType(userType);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DemoDashboard(userType: userType),
      ),
    );
  }
}
