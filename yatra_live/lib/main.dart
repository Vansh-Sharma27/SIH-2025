import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider_minimal.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/demo_initializer.dart';
import 'services/location_service_demo.dart';
import 'services/database_service_demo.dart';
import 'services/notification_service_demo.dart';
import 'services/api_service_demo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 YatraLive - Real-time Bus Tracking System');
  print('✅ Phase 1-4 Complete | Ready for SIH 2025 Demo!');
  
  // Initialize demo services
  await DemoInitializer.initialize();
  
  runApp(const YatraLiveApp());
}

class YatraLiveApp extends StatelessWidget {
  const YatraLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProviderMinimal()),
        Provider(create: (_) => LocationServiceDemo()),
        Provider(create: (_) => DatabaseServiceDemo()),
        Provider(create: (_) => NotificationServiceDemo()),
        Provider(create: (_) => ApiServiceDemo()),
      ],
      child: MaterialApp(
        title: 'YatraLive - Smart India Hackathon 2025',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
