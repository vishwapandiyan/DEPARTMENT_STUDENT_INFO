# Quick Setup Guide - Student Records Webapp

This guide will help you get the Student Records Webapp up and running quickly.

## Prerequisites Checklist

- [ ] Flutter SDK 3.8.1+ installed
- [ ] Supabase account created
- [ ] Modern web browser (Chrome recommended)

## Step-by-Step Setup

### 1. Supabase Setup (5 minutes)

#### Create Project
1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Choose your organization
4. Enter project name: `student-records`
5. Enter database password (save this!)
6. Choose region closest to your users
7. Click "Create new project"

#### Configure Database
1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste the entire contents of `FINAL_DATABASE_SCHEMA.sql`
4. Click "Run" to execute the schema

#### Setup Storage
1. Go to **Storage** in your Supabase dashboard
2. Click "Create Bucket"
3. Name: `student-docs`
4. Set to **Private** (important for security)
5. Click "Create bucket"

#### Get API Credentials
1. Go to **Settings** > **API**
2. Copy your **Project URL**
3. Copy your **anon public** key

### 2. Flutter Configuration (2 minutes)

#### Update Credentials
1. Open `lib/main.dart`
2. Find lines 18-19:
   ```dart
   url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
   anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
   ```
3. Replace with your actual Supabase credentials

#### Install Dependencies
```bash
flutter pub get
```

### 3. Create Staff Account (3 minutes)

#### Method 1: Through the App (Recommended)
1. Run the app: `flutter run -d chrome`
2. Go to Sign Up page
3. Register with:
   - Full Name: `Admin User`
   - Enrollment: `STAFF-001`
   - Email: `admin@college.edu`
   - Password: `admin123`

#### Method 2: Through Supabase Dashboard
1. Go to **Authentication** > **Users**
2. Click "Add User"
3. Enter email and password
4. Go to **SQL Editor** and run:
   ```sql
   UPDATE profiles 
   SET is_staff = true 
   WHERE enrollment_no = 'STAFF-001';
   ```

### 4. Test the Application (2 minutes)

#### Test Student Registration
1. Go to Sign Up page
2. Register a test student:
   - Full Name: `Test Student`
   - Enrollment: `2024AI001`
   - Email: `test@college.edu`
   - Password: `test123`

#### Test Staff Login
1. Sign out and go to Login page
2. Login with staff credentials
3. Verify you can see the staff dashboard

#### Test Student Login
1. Sign out and login with student credentials
2. Complete the student profile form
3. Upload a test document (any image under 1MB)

## Verification Checklist

- [ ] Supabase project created and schema loaded
- [ ] Storage bucket `student-docs` created (private)
- [ ] Flutter app runs without errors
- [ ] Staff account can login and see dashboard
- [ ] Student can register and login
- [ ] Student can create profile
- [ ] File upload works (compression under 210KB)
- [ ] Staff can view student list
- [ ] CSV export works

## Common Issues & Solutions

### "Supabase connection failed"
- ✅ Check your URL and anon key are correct
- ✅ Verify your Supabase project is active
- ✅ Check browser console for detailed errors

### "Permission denied" errors
- ✅ Ensure RLS policies are properly set up
- ✅ Verify staff account has `is_staff = true`
- ✅ Check if user is properly authenticated

### "File upload failed"
- ✅ Check file size (must be under 210KB after compression)
- ✅ Verify file type (JPG, PNG, PDF only)
- ✅ Ensure storage bucket exists and is accessible

### "Build errors"
- ✅ Run `flutter clean && flutter pub get`
- ✅ Check Flutter SDK version: `flutter --version`
- ✅ Ensure all dependencies are compatible

## Production Deployment

### Build for Production
```bash
flutter build web --release
```

### Deploy to Netlify (Free)
1. Zip the `build/web` folder
2. Go to [netlify.com](https://netlify.com)
3. Drag and drop the zip file
4. Your app will be live at a random URL

### Deploy to Vercel (Free)
1. Push your code to GitHub
2. Go to [vercel.com](https://vercel.com)
3. Import your GitHub repository
4. Deploy automatically

## Security Checklist for Production

- [ ] Use strong passwords for staff accounts
- [ ] Enable email verification in Supabase Auth settings
- [ ] Set up proper CORS policies
- [ ] Configure backup and monitoring
- [ ] Review RLS policies for your specific requirements
- [ ] Set up proper error logging
- [ ] Configure HTTPS (automatic with most hosting platforms)

## Support

If you encounter issues:

1. **Check the main README.md** for detailed documentation
2. **Review Supabase logs** in your dashboard
3. **Check Flutter logs** in browser console
4. **Verify your setup** against this checklist

## Next Steps

Once your app is running:

1. **Customize the theme** in `lib/constants/theme.dart`
2. **Add your college branding** and logo
3. **Configure email templates** in Supabase Auth settings
4. **Set up automated backups** for your database
5. **Train your staff** on using the admin features
6. **Create user documentation** for students

---

**Total Setup Time**: ~15 minutes for basic setup, ~30 minutes including testing and customization.

**Ready to go live?** Follow the production deployment steps and you'll have a professional student records system running in under an hour!
