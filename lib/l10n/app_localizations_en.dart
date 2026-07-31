// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sangak';

  @override
  String get bakerySubtitle => 'Artisan Persian Bakery';

  @override
  String get welcomeToSangak => 'Welcome to Sangak';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get pleaseSelectLanguage =>
      'Please select your preferred language to continue.';

  @override
  String get continueButton => 'Continue';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Login';

  @override
  String get signIn => 'Sign In';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get createOne => 'Create one';

  @override
  String get createAccount => 'Create Account';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reEnterPassword => 'Re-enter your password';

  @override
  String get iAgreeToTerms => 'I agree to the Terms & Conditions';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String get goodMorning => 'Good Morning,';

  @override
  String get welcomeToSangakGuest => 'Welcome to Sangak,';

  @override
  String get guest => 'Guest';

  @override
  String get popularToday => 'Popular Today';

  @override
  String get seeAll => 'See All';

  @override
  String get categories => 'Categories';

  @override
  String get traditionalFavorites => 'Traditional Favorites';

  @override
  String get addToBasket => 'Add to Basket';

  @override
  String addedToBasket(Object title) {
    return '$title added to basket!';
  }

  @override
  String get saveYourFavorites => 'Save your favorites';

  @override
  String get saveFavoritesMessage =>
      'Create an account to save your favorite artisan breads and access them anytime.';

  @override
  String get yourBasketIsWaiting => 'Your basket is waiting';

  @override
  String get cartGuestMessage =>
      'Create an account to save your items, track orders, and complete your checkout effortlessly.';

  @override
  String get joinTheFamily => 'Join the Sangak family';

  @override
  String get profileGuestMessage =>
      'Sign in to manage your profile, view order history, and access exclusive bakery offers.';

  @override
  String get signInRegister => 'Sign In / Register';

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get cart => 'Cart';

  @override
  String get profile => 'Profile';

  @override
  String get newUpdateAvailable => 'New Update Available';

  @override
  String updateAvailableMessage(Object version) {
    return 'A new version ($version) of Sangak is available. Update now to enjoy the latest features and improvements.';
  }

  @override
  String get whatsNew => 'What\'s New:';

  @override
  String get updateNow => 'Update Now';

  @override
  String get later => 'Later';
}
