import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Peptilog'**
  String get appName;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Track your peptides'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Log every injection with dose, compound, and site. Your protocol, perfectly recorded.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Monitor your progress'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Chart weight trends, body metrics, and health markers over time — all in one place.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on-device first. End-to-end encrypted sync. PIN and biometric lock.'**
  String get onboardingSlide3Body;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @signInContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get signInContinueWithApple;

  /// No description provided for @signInContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInContinueWithGoogle;

  /// No description provided for @signInOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get signInOr;

  /// No description provided for @signInEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmailLabel;

  /// No description provided for @signInPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signInPasswordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signInForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get signInForgotPassword;

  /// No description provided for @signInNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get signInNoAccount;

  /// No description provided for @signInGoSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signInGoSignUp;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your peptide journey.'**
  String get signUpSubtitle;

  /// No description provided for @signUpEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signUpEmailLabel;

  /// No description provided for @signUpPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signUpPasswordLabel;

  /// No description provided for @signUpConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signUpConfirmPasswordLabel;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// No description provided for @signUpAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signUpAlreadyHaveAccount;

  /// No description provided for @signUpGoSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signUpGoSignIn;

  /// No description provided for @signUpPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get signUpPasswordTooShort;

  /// No description provided for @signUpPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signUpPasswordsDoNotMatch;

  /// No description provided for @pinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your PIN'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 6-digit PIN to secure the app'**
  String get pinSetupSubtitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get pinConfirmTitle;

  /// No description provided for @pinConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get pinConfirmSubtitle;

  /// No description provided for @pinEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get pinEntryTitle;

  /// No description provided for @pinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'PINs did not match — try again'**
  String get pinMismatchError;

  /// No description provided for @pinIncorrectError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN — try again'**
  String get pinIncorrectError;

  /// No description provided for @biometricUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Peptilog'**
  String get biometricUnlockReason;

  /// No description provided for @gdprTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get gdprTitle;

  /// No description provided for @gdprBody.
  ///
  /// In en, this message translates to:
  /// **'Peptilog stores health data about peptide injections and body metrics. Before you continue, please review how we handle your information.'**
  String get gdprBody;

  /// No description provided for @gdprBullet1.
  ///
  /// In en, this message translates to:
  /// **'Data is stored locally on your device first.'**
  String get gdprBullet1;

  /// No description provided for @gdprBullet2.
  ///
  /// In en, this message translates to:
  /// **'Optional encrypted sync to our secure cloud (Supabase).'**
  String get gdprBullet2;

  /// No description provided for @gdprBullet3.
  ///
  /// In en, this message translates to:
  /// **'We never sell or share your data with third parties.'**
  String get gdprBullet3;

  /// No description provided for @gdprBullet4.
  ///
  /// In en, this message translates to:
  /// **'You can delete your account and all data at any time.'**
  String get gdprBullet4;

  /// No description provided for @gdprDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app is not a medical device. Do not use it as a substitute for professional medical advice. Always consult a qualified healthcare provider before beginning or modifying any peptide protocol.'**
  String get gdprDisclaimer;

  /// No description provided for @gdprAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'I understand — continue'**
  String get gdprAcceptButton;

  /// No description provided for @gdprPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our full Privacy Policy'**
  String get gdprPrivacyPolicy;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardTitle;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutButton;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get remindersEmpty;

  /// No description provided for @remindersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to schedule injection reminders'**
  String get remindersEmptyHint;

  /// No description provided for @reminderFormNew.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get reminderFormNew;

  /// No description provided for @reminderFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get reminderFormEdit;

  /// No description provided for @reminderFormPeptideLabel.
  ///
  /// In en, this message translates to:
  /// **'Peptide'**
  String get reminderFormPeptideLabel;

  /// No description provided for @reminderFormPeptidePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select peptide'**
  String get reminderFormPeptidePlaceholder;

  /// No description provided for @reminderFormNoPeptides.
  ///
  /// In en, this message translates to:
  /// **'No active peptides found. Add peptides first.'**
  String get reminderFormNoPeptides;

  /// No description provided for @reminderFormDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get reminderFormDaysLabel;

  /// No description provided for @reminderFormTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderFormTimeLabel;

  /// No description provided for @reminderFormActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get reminderFormActiveLabel;

  /// No description provided for @reminderFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get reminderFormSave;

  /// No description provided for @reminderFormDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get reminderFormDelete;

  /// No description provided for @reminderDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder?'**
  String get reminderDeleteConfirmTitle;

  /// No description provided for @reminderDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This reminder and its notifications will be removed.'**
  String get reminderDeleteConfirmBody;

  /// No description provided for @reminderErrorSelectPeptide.
  ///
  /// In en, this message translates to:
  /// **'Select a peptide'**
  String get reminderErrorSelectPeptide;

  /// No description provided for @reminderErrorSelectDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day'**
  String get reminderErrorSelectDay;

  /// No description provided for @healthTabSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get healthTabSleep;

  /// No description provided for @healthTabBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get healthTabBloodPressure;

  /// No description provided for @medicalDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get medicalDisclaimerTitle;

  /// No description provided for @medicalDisclaimerIntro.
  ///
  /// In en, this message translates to:
  /// **'Peptilog is a personal tracking tool, not a medical device or clinical service.'**
  String get medicalDisclaimerIntro;

  /// No description provided for @medicalDisclaimerBullet1.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this app constitutes medical advice, diagnosis, or treatment.'**
  String get medicalDisclaimerBullet1;

  /// No description provided for @medicalDisclaimerBullet2.
  ///
  /// In en, this message translates to:
  /// **'Always consult a qualified healthcare provider before starting or changing any protocol.'**
  String get medicalDisclaimerBullet2;

  /// No description provided for @medicalDisclaimerBullet3.
  ///
  /// In en, this message translates to:
  /// **'Peptide compounds may be regulated or restricted in your jurisdiction. You are solely responsible for legal compliance.'**
  String get medicalDisclaimerBullet3;

  /// No description provided for @medicalDisclaimerBullet4.
  ///
  /// In en, this message translates to:
  /// **'In a medical emergency call your local emergency services immediately.'**
  String get medicalDisclaimerBullet4;

  /// No description provided for @medicalDisclaimerFinePrint.
  ///
  /// In en, this message translates to:
  /// **'By tapping \"I understand\" you acknowledge that you have read this disclaimer and accept sole responsibility for your use of this application.'**
  String get medicalDisclaimerFinePrint;

  /// No description provided for @medicalDisclaimerAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'I understand — continue'**
  String get medicalDisclaimerAcceptButton;

  /// No description provided for @editInjectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Injection'**
  String get editInjectionTitle;

  /// No description provided for @editInjectionSave.
  ///
  /// In en, this message translates to:
  /// **'Save injection'**
  String get editInjectionSave;

  /// No description provided for @editInjectionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get editInjectionDelete;

  /// No description provided for @editInjectionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editInjectionCancel;

  /// No description provided for @editInjectionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Injection updated'**
  String get editInjectionUpdated;

  /// No description provided for @editInjectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Injection deleted'**
  String get editInjectionDeleted;

  /// No description provided for @editInjectionDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete injection?'**
  String get editInjectionDeleteConfirmTitle;

  /// No description provided for @editInjectionDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this log entry.'**
  String get editInjectionDeleteConfirmBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
