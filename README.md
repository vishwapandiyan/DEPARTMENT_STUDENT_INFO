# Student Records Webapp

A professional, lightweight web application built with Flutter Web and Supabase for the Department of Artificial Intelligence & Data Science. This application allows first-year students (Classes A–E) to upload personal details and scanned documents, while staff can view, filter, and export student data.

## Features

### For Students
- **Authentication**: Sign up/sign in using college email with enrollment number verification
- **Profile Management**: Create and edit comprehensive student profiles
- **Document Upload**: Upload and manage documents (Aadhaar, 10th/12th mark sheets, certificates)
- **File Compression**: Automatic client-side compression to ensure files stay under 210 KB
- **Data Privacy**: Students can only view and download their own data
- **Profile Download**: Export personal profile as CSV

### For Staff
- **Dashboard**: Overview of student statistics and recent activity
- **Student Management**: View all students with advanced filtering options
- **Search & Filter**: Filter by class, gender, enrollment number
- **Data Export**: Export student data as CSV (all students, by class, or individual)
- **Document Access**: View and download student documents
- **Statistics**: Real-time statistics on student enrollment and demographics

## Technology Stack

- **Frontend**: Flutter Web
- **Backend**: Supabase (PostgreSQL + Storage + Auth)
- **State Management**: Provider
- **Architecture**: MVC (Model-View-Controller)
- **File Processing**: Image compression, CSV generation
- **UI**: Material Design with custom professional theme

## Prerequisites

Before running the application, ensure you have:

1. **Flutter SDK** (3.8.1 or higher)
2. **Supabase Account** and project
3. **Web Browser** (Chrome, Firefox, Safari, Edge)

## Setup Instructions

### 1. Supabase Configuration

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new account
2. Create a new project
3. Note down your project URL and anon key from Settings > API

#### Database Schema Setup
Run the following SQL commands in your Supabase SQL Editor:

```sql
-- Create enums
CREATE TYPE student_class AS ENUM ('A','B','C','D','E');
CREATE TYPE student_gender AS ENUM ('male','female','other');

-- Create profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL,
  enrollment_no TEXT NOT NULL UNIQUE,
  is_staff BOOLEAN DEFAULT FALSE,
  class student_class,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create students table (profile details)
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) NOT NULL,
  aadhaar TEXT,
  dob DATE,
  address TEXT,
  guardian_name TEXT,
  mother_name TEXT,
  father_name TEXT,
  mother_name TEXT,
  siblings BOOLEAN DEFAULT FALSE,
  community TEXT,
  tenth_percent NUMERIC(5,2),
  twelfth_percent NUMERIC(5,2),
  father_income NUMERIC,
  mother_income NUMERIC,
  gender student_gender,
  class student_class,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create documents metadata table
CREATE TABLE student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  doc_type TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  uploaded_by UUID REFERENCES profiles(id),
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  file_name TEXT,
  file_size INTEGER
);

-- Create indexes for better performance
CREATE INDEX ON students (enrollment_no);
CREATE INDEX ON students (class);
CREATE INDEX ON students (gender);
CREATE INDEX ON student_documents (student_id);
CREATE INDEX ON student_documents (doc_type);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Allow authenticated users to insert their profile" ON profiles
  FOR INSERT USING (auth.role() = 'authenticated') WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to view their own profile" ON profiles
  FOR SELECT USING (
    auth.uid() = id OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_staff = true)
  );

CREATE POLICY "Allow users to update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- RLS Policies for students
CREATE POLICY "Allow users to insert their student record" ON students
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Allow users to view their own student record" ON students
  FOR SELECT USING (
    auth.uid() = profile_id OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_staff = true)
  );

CREATE POLICY "Allow users to update their own student record" ON students
  FOR UPDATE USING (auth.uid() = profile_id);

-- RLS Policies for student_documents
CREATE POLICY "Allow users to insert documents for their student record" ON student_documents
  FOR INSERT WITH CHECK (
    auth.uid() = uploaded_by AND
    EXISTS (SELECT 1 FROM students WHERE id = student_id AND profile_id = auth.uid())
  );

CREATE POLICY "Allow users to view documents for their student record" ON student_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM students s 
      WHERE s.id = student_id AND 
      (s.profile_id = auth.uid() OR 
       EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_staff = true))
    )
  );

CREATE POLICY "Allow users to delete their own documents" ON student_documents
  FOR DELETE USING (auth.uid() = uploaded_by);
```

#### Storage Setup
1. Go to Storage in your Supabase dashboard
2. Create a new bucket named `student-docs`
3. Set the bucket to **Private** (not public)
4. The bucket will store student documents with the path structure: `student-docs/{student_id}/{doc_type}.{ext}`

#### Seed Staff User
To create a staff account, run this SQL command (replace with actual values):

```sql
-- First, you'll need to create the user through Supabase Auth
-- Then update their profile to mark them as staff
UPDATE profiles 
SET is_staff = true 
WHERE enrollment_no = 'STAFF-001'; -- Replace with actual enrollment number
```

### 2. Flutter Configuration

#### Update Supabase Credentials
1. Open `lib/main.dart`
2. Replace the placeholder values:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
     anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
   );
   ```

#### Install Dependencies
```bash
flutter pub get
```

#### Run the Application
```bash
flutter run -d chrome
```

## Project Structure

```
lib/
├── constants/
│   ├── enums.dart          # Student class, gender, document type enums
│   └── theme.dart          # App theme and styling constants
├── controllers/
│   ├── auth_controller.dart    # Authentication logic
│   └── student_controller.dart # Student data management
├── models/
│   ├── profile.dart        # User profile model
│   ├── student.dart        # Student data model
│   └── document.dart       # Document metadata model
├── providers/
│   ├── auth_provider.dart     # Authentication state management
│   └── student_provider.dart  # Student data state management
├── utils/
│   ├── compress_util.dart  # File compression utilities
│   ├── csv_util.dart       # CSV generation and download
│   └── validators.dart     # Form validation helpers
├── views/
│   ├── auth/
│   │   ├── login_page.dart     # Student/staff login
│   │   └── signup_page.dart    # Student registration
│   ├── student/
│   │   ├── student_dashboard.dart   # Student home page
│   │   ├── student_form.dart        # Profile creation/editing
│   │   └── student_profile_view.dart # Profile viewing
│   └── staff/
│       ├── staff_dashboard.dart     # Staff home page
│       └── student_list_view.dart   # Student management
└── main.dart               # App entry point and routing
```

## Usage Guide

### Student Workflow

1. **Registration**
   - Navigate to the sign-up page
   - Enter full name, enrollment number, college email, and password
   - Verify email address (check your inbox)

2. **Profile Creation**
   - Sign in with your credentials
   - Complete the multi-step profile form:
     - Personal Information (Aadhaar, DOB, gender, class, address)
     - Family Information (parents' names, income, community)
     - Academic Information (10th/12th percentages)
     - Document Upload (Aadhaar, certificates, mark sheets)

3. **Document Upload**
   - Select files (JPG, PNG, PDF supported)
   - Files are automatically compressed to under 210 KB
   - Upload and manage your documents

4. **Profile Management**
   - View your complete profile
   - Edit information as needed
   - Download your profile as CSV

### Staff Workflow

1. **Dashboard Overview**
   - View student statistics and recent activity
   - Access quick actions for student management

2. **Student Management**
   - View all students in a searchable, filterable list
   - Filter by class, gender, or search by enrollment number
   - View individual student details

3. **Data Export**
   - Export all students data as CSV
   - Export data by specific class
   - Export individual student records

## File Compression

The application automatically compresses uploaded images to ensure they stay under the 210 KB limit:

- **Supported Formats**: JPG, JPEG, PNG, PDF
- **Compression**: Images are resized and compressed with quality adjustment
- **Validation**: Files are validated before and after compression
- **Error Handling**: Clear error messages if compression fails

## Security Features

- **Row Level Security (RLS)**: Database-level access control
- **Authentication**: Supabase Auth with email verification
- **Role-based Access**: Students can only access their own data
- **File Validation**: Client and server-side file validation
- **Data Masking**: Sensitive data (Aadhaar) is masked in UI

## Troubleshooting

### Common Issues

1. **Supabase Connection Error**
   - Verify your Supabase URL and anon key
   - Check if your Supabase project is active
   - Ensure RLS policies are properly configured

2. **File Upload Issues**
   - Check file size (must be under 210 KB after compression)
   - Verify file format (JPG, PNG, PDF only)
   - Ensure stable internet connection

3. **Authentication Problems**
   - Verify email confirmation
   - Check enrollment number uniqueness
   - Ensure proper RLS policies are in place

4. **Build Issues**
   - Run `flutter clean` and `flutter pub get`
   - Ensure Flutter SDK version compatibility
   - Check for any missing dependencies

### Performance Optimization

- **Pagination**: Student lists are paginated for better performance
- **Lazy Loading**: Images and documents are loaded on demand
- **Caching**: Supabase handles caching automatically
- **Compression**: Files are compressed to reduce storage and bandwidth

## Development

### Adding New Features

1. **New Document Types**: Update `DocumentType` enum in `constants/enums.dart`
2. **New Student Fields**: Update `Student` model and database schema
3. **New Validation Rules**: Add to `utils/validators.dart`
4. **New UI Components**: Follow the existing theme in `constants/theme.dart`

### Testing

- **Unit Tests**: Test individual functions and utilities
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user workflows

## Deployment

### Web Deployment

1. **Build for Production**
   ```bash
   flutter build web --release
   ```

2. **Deploy Options**
   - **Netlify**: Drag and drop the `build/web` folder
   - **Vercel**: Connect your GitHub repository
   - **Firebase Hosting**: Use Firebase CLI
   - **GitHub Pages**: Push to gh-pages branch

3. **Environment Variables**
   - Ensure Supabase credentials are properly configured
   - Use production Supabase project for live deployment

## Support

For technical support or feature requests:

1. Check this README for common solutions
2. Review the code documentation
3. Check Supabase documentation for backend issues
4. Review Flutter Web documentation for frontend issues

## License

This project is developed for the Department of Artificial Intelligence & Data Science. Please ensure compliance with your institution's data privacy and security policies.

---

**Note**: This application handles sensitive student data. Ensure proper security measures, regular backups, and compliance with data protection regulations in your jurisdiction.