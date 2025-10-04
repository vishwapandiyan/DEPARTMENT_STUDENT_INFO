class Validators {
  /// Validate Aadhaar number (12 digits)
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }
    
    // Remove spaces and hyphens
    final cleanAadhaar = value.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleanAadhaar.length != 12) {
      return 'Aadhaar number must be exactly 12 digits';
    }
    
    if (!RegExp(r'^\d{12}$').hasMatch(cleanAadhaar)) {
      return 'Aadhaar number must contain only digits';
    }
    
    return null;
  }

  /// Validate enrollment number
  static String? validateEnrollmentNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enrollment number is required';
    }
    
    if (value.length < 5) {
      return 'Enrollment number must be at least 5 characters';
    }
    
    return null;
  }

  /// Validate full name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Full name can only contain letters and spaces';
    }
    
    return null;
  }

  /// Validate date of birth
  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    
    final now = DateTime.now();
    final age = now.year - value.year;
    
    if (age < 15 || age > 25) {
      return 'Age must be between 15 and 25 years';
    }
    
    if (value.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    
    return null;
  }

  /// Validate percentage (0-100)
  static String? validatePercentage(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final percentage = double.tryParse(value);
    if (percentage == null) {
      return 'Please enter a valid percentage';
    }
    
    if (percentage < 0 || percentage > 100) {
      return 'Percentage must be between 0 and 100';
    }
    
    return null;
  }

  /// Validate income amount
  static String? validateIncome(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final income = double.tryParse(value);
    if (income == null) {
      return 'Please enter a valid income amount';
    }
    
    if (income < 0) {
      return 'Income cannot be negative';
    }
    
    return null;
  }

  /// Validate required text field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate email address
  static String? validateCollegeEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    // Add domain validation if needed
    // if (!value.toLowerCase().endsWith('@college.edu')) {
    //   return 'Please use your college email address';
    // }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      return 'Phone number must be exactly 10 digits';
    }
    
    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 10) {
      return 'Please provide a complete address (at least 10 characters)';
    }
    
    return null;
  }

  /// Sanitize Aadhaar number (remove spaces and hyphens)
  static String sanitizeAadhaar(String aadhaar) {
    return aadhaar.replaceAll(RegExp(r'[\s-]'), '');
  }

  /// Format Aadhaar number for display (add hyphens)
  static String formatAadhaarForDisplay(String aadhaar) {
    final cleanAadhaar = sanitizeAadhaar(aadhaar);
    if (cleanAadhaar.length == 12) {
      return '${cleanAadhaar.substring(0, 4)}-${cleanAadhaar.substring(4, 8)}-${cleanAadhaar.substring(8, 12)}';
    }
    return cleanAadhaar;
  }
}
