// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Peptilog';

  @override
  String get onboardingSlide1Title => 'Track your peptides';

  @override
  String get onboardingSlide1Body =>
      'Log every injection with dose, compound, and site. Your protocol, perfectly recorded.';

  @override
  String get onboardingSlide2Title => 'Monitor your progress';

  @override
  String get onboardingSlide2Body =>
      'Chart weight trends, body metrics, and health markers over time — all in one place.';

  @override
  String get onboardingSlide3Title => 'Private by design';

  @override
  String get onboardingSlide3Body =>
      'Your data stays on-device first. End-to-end encrypted sync. PIN and biometric lock.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInContinueWithApple => 'Continue with Apple';

  @override
  String get signInContinueWithGoogle => 'Continue with Google';

  @override
  String get signInOr => 'or';

  @override
  String get signInEmailLabel => 'Email';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInForgotPassword => 'Forgot password?';

  @override
  String get signInNoAccount => 'Don\'t have an account?';

  @override
  String get signInGoSignUp => 'Sign up';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signUpSubtitle => 'Start tracking your peptide journey.';

  @override
  String get signUpEmailLabel => 'Email';

  @override
  String get signUpPasswordLabel => 'Password';

  @override
  String get signUpConfirmPasswordLabel => 'Confirm password';

  @override
  String get signUpButton => 'Create account';

  @override
  String get signUpAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signUpGoSignIn => 'Sign in';

  @override
  String get signUpPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get signUpPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get pinSetupTitle => 'Set your PIN';

  @override
  String get pinSetupSubtitle => 'Choose a 6-digit PIN to secure the app';

  @override
  String get pinConfirmTitle => 'Confirm your PIN';

  @override
  String get pinConfirmSubtitle => 'Enter the same PIN again';

  @override
  String get pinEntryTitle => 'Enter your PIN';

  @override
  String get pinMismatchError => 'PINs did not match — try again';

  @override
  String get pinIncorrectError => 'Incorrect PIN — try again';

  @override
  String get biometricUnlockReason => 'Unlock Peptilog';

  @override
  String get gdprTitle => 'Your privacy matters';

  @override
  String get gdprBody =>
      'Peptilog stores health data about peptide injections and body metrics. Before you continue, please review how we handle your information.';

  @override
  String get gdprBullet1 => 'Data is stored locally on your device first.';

  @override
  String get gdprBullet2 =>
      'Optional encrypted sync to our secure cloud (Supabase).';

  @override
  String get gdprBullet3 =>
      'We never sell or share your data with third parties.';

  @override
  String get gdprBullet4 =>
      'You can delete your account and all data at any time.';

  @override
  String get gdprDisclaimer =>
      'This app is not a medical device. Do not use it as a substitute for professional medical advice. Always consult a qualified healthcare provider before beginning or modifying any peptide protocol.';

  @override
  String get gdprAcceptButton => 'I understand — continue';

  @override
  String get gdprPrivacyPolicy => 'Read our full Privacy Policy';

  @override
  String get dashboardTitle => 'Today';

  @override
  String get logoutButton => 'Sign out';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersEmpty => 'No reminders yet';

  @override
  String get remindersEmptyHint => 'Tap + to schedule injection reminders';

  @override
  String get reminderFormNew => 'New Reminder';

  @override
  String get reminderFormEdit => 'Edit Reminder';

  @override
  String get reminderFormPeptideLabel => 'Peptide';

  @override
  String get reminderFormPeptidePlaceholder => 'Select peptide';

  @override
  String get reminderFormNoPeptides =>
      'No active peptides found. Add peptides first.';

  @override
  String get reminderFormDaysLabel => 'Days';

  @override
  String get reminderFormTimeLabel => 'Time';

  @override
  String get reminderFormActiveLabel => 'Active';

  @override
  String get reminderFormSave => 'Save';

  @override
  String get reminderFormDelete => 'Delete Reminder';

  @override
  String get reminderDeleteConfirmTitle => 'Delete reminder?';

  @override
  String get reminderDeleteConfirmBody =>
      'This reminder and its notifications will be removed.';

  @override
  String get reminderErrorSelectPeptide => 'Select a peptide';

  @override
  String get reminderErrorSelectDay => 'Select at least one day';

  @override
  String get healthTabSleep => 'Sleep';

  @override
  String get healthTabBloodPressure => 'Blood Pressure';
}
