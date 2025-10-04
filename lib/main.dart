import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/onboarding_provider.dart';
import 'constants/theme.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/student/student_dashboard.dart';
import 'views/staff/staff_dashboard.dart';
import 'views/student/student_form.dart';
import 'views/onboarding/student_onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rwwdulvnegtdgsqysemi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3d2R1bHZuZWd0ZGdzcXlzZW1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NTM0NTQsImV4cCI6MjA3NTEyOTQ1NH0.-_X84ZAl9DPS7uAVVcMYLhTMtHq9OMaWt4Ci7OsRRgQ',
  );

  runApp(const StudentRecordsApp());
}

class StudentRecordsApp extends StatelessWidget {
  const StudentRecordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp(
        title: 'Student Records - AI & Data Science',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/student-dashboard': (context) => const StudentDashboard(),
          '/staff-dashboard': (context) => const StaffDashboard(),
          '/student-form': (context) => const StudentForm(),
          '/onboarding': (context) => const StudentOnboardingScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OnboardingProvider>(
      builder: (context, authProvider, onboardingProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading && authProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // If user is authenticated
        if (authProvider.isAuthenticated) {
          // Check if user profile is loaded
          if (authProvider.profile == null) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading profile...'),
                  ],
                ),
              ),
            );
          }

          // Route based on user role
          if (authProvider.isStaff) {
            return const StaffDashboard();
          } else {
            // Check if student has completed onboarding
            if (onboardingProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              );
            }
            
            if (!onboardingProvider.isOnboardingCompleted) {
              return const StudentOnboardingScreen();
            }
            
            return const StudentDashboard();
          }
        }

        // User is not authenticated, show login page
        return const LoginPage();
      },
    );
  }
}
