-- Student Records Webapp - Complete Supabase Database Schema
-- Final Version - Run this SQL script in your Supabase SQL Editor
-- This includes all features: profiles, students, documents, and profile photos

-- ============================================
-- 1. CREATE ENUMS
-- ============================================

-- Create enums
CREATE TYPE student_class AS ENUM ('A','B','C','D','E');
CREATE TYPE student_gender AS ENUM ('male','female','other');
CREATE TYPE document_type AS ENUM ('aadhaar','tenth','twelfth','birthCert','community','income');

-- ============================================
-- 2. CREATE TABLES
-- ============================================

-- Create profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL,
  enrollment_no TEXT NOT NULL UNIQUE,
  is_staff BOOLEAN DEFAULT FALSE,
  class student_class,
  profile_photo_path TEXT, -- Added for profile photo support
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create students table (profile details)
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  aadhaar TEXT NOT NULL,
  dob DATE NOT NULL,
  address TEXT NOT NULL,
  guardian_name TEXT NOT NULL,
  mother_name TEXT NOT NULL,
  father_name TEXT NOT NULL,
  siblings BOOLEAN NOT NULL DEFAULT FALSE,
  community TEXT NOT NULL,
  tenth_percent DECIMAL(5,2) NOT NULL,
  twelfth_percent DECIMAL(5,2) NOT NULL,
  father_income DECIMAL(10,2) NOT NULL,
  mother_income DECIMAL(10,2) NOT NULL,
  gender student_gender NOT NULL,
  class student_class NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create student_documents table
CREATE TABLE student_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  document_type document_type NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, document_type)
);

-- ============================================
-- 3. CREATE INDEXES
-- ============================================

-- Indexes for better performance
CREATE INDEX idx_profiles_enrollment_no ON profiles(enrollment_no);
CREATE INDEX idx_profiles_is_staff ON profiles(is_staff);
CREATE INDEX idx_profiles_class ON profiles(class);
CREATE INDEX idx_profiles_profile_photo_path ON profiles(profile_photo_path);

CREATE INDEX idx_students_profile_id ON students(profile_id);
CREATE INDEX idx_students_class ON students(class);
CREATE INDEX idx_students_gender ON students(gender);
CREATE INDEX idx_students_created_at ON students(created_at);

CREATE INDEX idx_student_documents_student_id ON student_documents(student_id);
CREATE INDEX idx_student_documents_type ON student_documents(document_type);

-- ============================================
-- 4. CREATE FUNCTIONS
-- ============================================

-- Function to generate profile photo storage path
CREATE OR REPLACE FUNCTION generate_profile_photo_path(user_id UUID, file_name TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN 'profile-photos/' || user_id || '/' || extract(epoch from now()) || '_' || file_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is staff
CREATE OR REPLACE FUNCTION is_current_user_staff()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND is_staff = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create profile for new user
CREATE OR REPLACE FUNCTION create_profile_for_user(
  user_id UUID,
  user_full_name TEXT,
  user_enrollment_no TEXT,
  user_is_staff BOOLEAN DEFAULT FALSE,
  user_class student_class DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO profiles (id, full_name, enrollment_no, is_staff, class)
  VALUES (user_id, user_full_name, user_enrollment_no, user_is_staff, user_class);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. ENABLE ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. CREATE RLS POLICIES
-- ============================================

-- Profiles table policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Staff can view all profiles" ON profiles
  FOR SELECT USING (is_current_user_staff());

CREATE POLICY "Staff can update all profiles" ON profiles
  FOR UPDATE USING (is_current_user_staff());

-- Students table policies
CREATE POLICY "Students can view own student record" ON students
  FOR SELECT USING (profile_id = auth.uid());

CREATE POLICY "Students can insert own student record" ON students
  FOR INSERT WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Students can update own student record" ON students
  FOR UPDATE USING (profile_id = auth.uid());

CREATE POLICY "Staff can view all students" ON students
  FOR SELECT USING (is_current_user_staff());

CREATE POLICY "Staff can insert students" ON students
  FOR INSERT WITH CHECK (is_current_user_staff());

CREATE POLICY "Staff can update all students" ON students
  FOR UPDATE USING (is_current_user_staff());

-- Student documents table policies
CREATE POLICY "Students can view own documents" ON student_documents
  FOR SELECT USING (
    student_id IN (
      SELECT id FROM students WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "Students can insert own documents" ON student_documents
  FOR INSERT WITH CHECK (
    student_id IN (
      SELECT id FROM students WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "Students can update own documents" ON student_documents
  FOR UPDATE USING (
    student_id IN (
      SELECT id FROM students WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "Students can delete own documents" ON student_documents
  FOR DELETE USING (
    student_id IN (
      SELECT id FROM students WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "Staff can view all documents" ON student_documents
  FOR SELECT USING (is_current_user_staff());

CREATE POLICY "Staff can insert documents" ON student_documents
  FOR INSERT WITH CHECK (is_current_user_staff());

CREATE POLICY "Staff can update all documents" ON student_documents
  FOR UPDATE USING (is_current_user_staff());

CREATE POLICY "Staff can delete all documents" ON student_documents
  FOR DELETE USING (is_current_user_staff());

-- ============================================
-- 7. GRANT PERMISSIONS
-- ============================================

-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON students TO authenticated;
GRANT ALL ON student_documents TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION generate_profile_photo_path(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_current_user_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION create_profile_for_user(UUID, TEXT, TEXT, BOOLEAN, student_class) TO authenticated;

-- ============================================
-- 8. CREATE STORAGE BUCKET
-- ============================================

-- Create storage bucket for student documents and profile photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'student-docs',
  'student-docs',
  false,
  215040, -- 210 KB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'application/pdf']
);

-- ============================================
-- 9. STORAGE RLS POLICIES
-- ============================================

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Storage policies for student documents
CREATE POLICY "Students can upload own documents" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'student-docs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Students can view own documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'student-docs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Students can update own documents" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'student-docs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Students can delete own documents" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'student-docs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Staff can access all documents
CREATE POLICY "Staff can upload documents" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'student-docs' AND
    is_current_user_staff()
  );

CREATE POLICY "Staff can view all documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'student-docs' AND
    is_current_user_staff()
  );

CREATE POLICY "Staff can update all documents" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'student-docs' AND
    is_current_user_staff()
  );

CREATE POLICY "Staff can delete all documents" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'student-docs' AND
    is_current_user_staff()
  );

-- ============================================
-- 10. VERIFICATION QUERIES
-- ============================================

-- Verify tables were created
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'students', 'student_documents')
ORDER BY table_name;

-- Verify RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'students', 'student_documents');

-- Verify storage bucket was created
SELECT name, public, file_size_limit 
FROM storage.buckets 
WHERE name = 'student-docs';

-- Verify functions were created
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('generate_profile_photo_path', 'is_current_user_staff', 'create_profile_for_user');

-- ============================================
-- SETUP COMPLETE!
-- ============================================

-- Next steps:
-- 1. Create a staff user account through Supabase Auth
-- 2. Run the following query to make the user staff:
--    UPDATE profiles SET is_staff = true, full_name = 'Staff Administrator', enrollment_no = 'STAFF-001' 
--    WHERE id = 'YOUR_STAFF_USER_ID';
-- 3. Test the application with both student and staff accounts
