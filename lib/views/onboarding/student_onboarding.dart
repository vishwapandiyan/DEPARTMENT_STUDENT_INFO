import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../constants/enums.dart';
import '../../providers/onboarding_provider.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: "Welcome to Student Records",
      subtitle: "Department of Artificial Intelligence & Data Science",
      description: "Your secure portal for managing academic documents and profile information.",
      icon: Icons.school,
      color: AppTheme.primaryBlue,
    ),
    OnboardingStep(
      title: "Document Requirements",
      subtitle: "Required Documents for Upload",
      description: "Please prepare the following documents in digital format (JPG, PNG, or PDF):",
      icon: Icons.description,
      color: AppTheme.secondaryGold,
      items: [
        "Aadhaar Card (Government ID)",
        "10th Mark Sheet",
        "12th Mark Sheet", 
        "Birth Certificate",
        "Community Certificate",
        "Income Certificate",
      ],
    ),
    OnboardingStep(
      title: "File Size & Quality",
      subtitle: "Document Specifications",
      description: "To ensure smooth processing, please note the following requirements:",
      icon: Icons.compress,
      color: AppTheme.infoColor,
      items: [
        "Maximum file size: 210 KB per document",
        "Supported formats: JPG, PNG, PDF",
        "Clear, readable images with good contrast",
        "All text should be clearly visible",
        "Files will be automatically compressed if needed",
      ],
    ),
    OnboardingStep(
      title: "Privacy & Security",
      subtitle: "Your Data is Protected",
      description: "We take your privacy and data security seriously:",
      icon: Icons.security,
      color: AppTheme.successColor,
      items: [
        "Your documents are encrypted and securely stored",
        "Only you and authorized staff can access your data",
        "Data is used solely for academic purposes",
        "Department of AI & Data Science maintains strict confidentiality",
        "Your information is never shared with third parties",
      ],
    ),
    OnboardingStep(
      title: "Get Started",
      subtitle: "Complete Your Profile",
      description: "You're all set! Complete your profile and upload your documents to get started.",
      icon: Icons.rocket_launch,
      color: AppTheme.primaryBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlueTint,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: _buildStepContent(_steps[index]),
                  );
                },
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Step ${_currentStep + 1} of ${_steps.length}",
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${((_currentStep + 1) / _steps.length * 100).round()}%",
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: AppTheme.lightGray,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: step.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: step.color,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Title
          Text(
            step.title,
            style: AppTheme.heading1.copyWith(
              color: AppTheme.primaryBlueDark,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Subtitle
          Text(
            step.subtitle,
            style: AppTheme.heading3.copyWith(
              color: AppTheme.secondaryGold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Description
          Text(
            step.description,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (step.items != null) ...[
            const SizedBox(height: AppTheme.spacingXL),
            _buildItemsList(step.items!),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => _buildListItem(item)).toList(),
      ),
    );
  }

  Widget _buildListItem(String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: AppTheme.spacingM),
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryBlueDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          
          // Next/Complete button
          ElevatedButton.icon(
            onPressed: () {
              if (_currentStep < _steps.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // Complete onboarding
                _completeOnboarding();
              }
            },
            icon: Icon(_currentStep < _steps.length - 1 ? Icons.arrow_forward : Icons.check),
            label: Text(_currentStep < _steps.length - 1 ? 'Next' : 'Get Started'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep < _steps.length - 1 
                  ? AppTheme.primaryBlue 
                  : AppTheme.secondaryGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
                vertical: AppTheme.spacingM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    // Mark onboarding as completed
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.completeOnboarding();
    
    // Navigate to student dashboard
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/student-dashboard');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String>? items;

  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.items,
  });
}
