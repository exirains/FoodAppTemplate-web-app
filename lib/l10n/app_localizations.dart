import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_tr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Babka'**
  String get appName;

  /// No description provided for @bakerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'AUTHENTIC ARTISAN BAKERY'**
  String get bakerySubtitle;

  /// No description provided for @welcomeToBabka.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Babka'**
  String get welcomeToBabka;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @pleaseSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select your preferred language to continue.'**
  String get pleaseSelectLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue where you left off.'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterPassword;

  /// No description provided for @iAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get iAgreeToTerms;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get goodEvening;

  /// No description provided for @welcomeToBabkaGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Babka,'**
  String get welcomeToBabkaGuest;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @popularToday.
  ///
  /// In en, this message translates to:
  /// **'Popular Today'**
  String get popularToday;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @traditionalFavorites.
  ///
  /// In en, this message translates to:
  /// **'Traditional Favorites'**
  String get traditionalFavorites;

  /// No description provided for @addToBasket.
  ///
  /// In en, this message translates to:
  /// **'Add to Basket'**
  String get addToBasket;

  /// No description provided for @updateBasket.
  ///
  /// In en, this message translates to:
  /// **'Update Basket'**
  String get updateBasket;

  /// No description provided for @addedToBasket.
  ///
  /// In en, this message translates to:
  /// **'{title} added to basket!'**
  String addedToBasket(String title);

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Successfully logged in.'**
  String get loginSuccessful;

  /// No description provided for @registeredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the family! Account created successfully.'**
  String get registeredSuccessfully;

  /// No description provided for @addPhoneToOrder.
  ///
  /// In en, this message translates to:
  /// **'Please add your phone number to place orders.'**
  String get addPhoneToOrder;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for delivery.'**
  String get phoneNumberRequired;

  /// No description provided for @buildYourBabka.
  ///
  /// In en, this message translates to:
  /// **'Build Your Babka'**
  String get buildYourBabka;

  /// No description provided for @base.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get base;

  /// No description provided for @seeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seeds;

  /// No description provided for @extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @customizeYourBabka.
  ///
  /// In en, this message translates to:
  /// **'Customize Your Order'**
  String get customizeYourBabka;

  /// No description provided for @addedCustomBabka.
  ///
  /// In en, this message translates to:
  /// **'Added your custom creation to basket!'**
  String get addedCustomBabka;

  /// No description provided for @saveYourFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save your favorites'**
  String get saveYourFavorites;

  /// No description provided for @saveFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save your favorite artisan breads and access them anytime.'**
  String get saveFavoritesMessage;

  /// No description provided for @yourBasketIsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your basket is waiting'**
  String get yourBasketIsWaiting;

  /// No description provided for @basketGuestMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save your items, track orders, and complete your checkout effortlessly.'**
  String get basketGuestMessage;

  /// No description provided for @joinTheFamily.
  ///
  /// In en, this message translates to:
  /// **'Join the Babka family'**
  String get joinTheFamily;

  /// No description provided for @profileGuestMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your profile, view order history, and access exclusive bakery offers.'**
  String get profileGuestMessage;

  /// No description provided for @signInRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign In / Register'**
  String get signInRegister;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @basket.
  ///
  /// In en, this message translates to:
  /// **'Basket'**
  String get basket;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @newUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Update Available'**
  String get newUpdateAvailable;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Babka is available. Update now to enjoy the latest features and improvements.'**
  String get updateAvailableMessage;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New:'**
  String get whatsNew;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @newVersion.
  ///
  /// In en, this message translates to:
  /// **'New Version'**
  String get newVersion;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @orderAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order assigned successfully.'**
  String get orderAssignedSuccessfully;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @noAddressSelected.
  ///
  /// In en, this message translates to:
  /// **'No address selected'**
  String get noAddressSelected;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @cashOnDeliveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Pay with cash when your order arrives.'**
  String get cashOnDeliveryDescription;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @addDeliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Add delivery note'**
  String get addDeliveryNote;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @door.
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get door;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @orderReceived.
  ///
  /// In en, this message translates to:
  /// **'Your order has been received'**
  String get orderReceived;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// No description provided for @newOrders.
  ///
  /// In en, this message translates to:
  /// **'New Orders'**
  String get newOrders;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark Ready'**
  String get markReady;

  /// No description provided for @waitingForPickup.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Pickup'**
  String get waitingForPickup;

  /// No description provided for @newOrderNotification.
  ///
  /// In en, this message translates to:
  /// **'New order notification'**
  String get newOrderNotification;

  /// No description provided for @ordersHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get ordersHistory;

  /// No description provided for @staffProfile.
  ///
  /// In en, this message translates to:
  /// **'Staff Profile'**
  String get staffProfile;

  /// No description provided for @newOrderAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new order is available!'**
  String get newOrderAvailable;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Approximate preparation time'**
  String get estimatedTime;

  /// No description provided for @estimatedDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Approximate delivery time'**
  String get estimatedDeliveryTime;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @searchBreads.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchBreads;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @errorLoadingBreads.
  ///
  /// In en, this message translates to:
  /// **'Error loading breads'**
  String get errorLoadingBreads;

  /// No description provided for @freshlyBakedArtisan.
  ///
  /// In en, this message translates to:
  /// **'Freshly Baked Products'**
  String get freshlyBakedArtisan;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Premium artisan breads, delivered to your door.'**
  String get heroSubtitle;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms'**
  String get pleaseAgreeToTerms;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(num count);

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String mins(num count);

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'{count} kcal'**
  String kcal(num count);

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organic;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordTooShort;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter, one lowercase letter, and one number'**
  String get passwordRequirements;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get invalidCredentials;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection problem. Please try again.'**
  String get networkError;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many login attempts. Please try again later.'**
  String get tooManyAttempts;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailAlreadyInUse;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first'**
  String get emailNotVerified;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password Strength'**
  String get passwordStrength;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePassword;

  /// No description provided for @saveYourFavoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save your favorite breads across devices.'**
  String get saveYourFavoritesDescription;

  /// No description provided for @continueWithEmailOrGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email or Google'**
  String get continueWithEmailOrGoogle;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add Phone Number'**
  String get addPhoneNumber;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @syncBasket.
  ///
  /// In en, this message translates to:
  /// **'Sync Basket'**
  String get syncBasket;

  /// No description provided for @syncingBasket.
  ///
  /// In en, this message translates to:
  /// **'Syncing your items...'**
  String get syncingBasket;

  /// No description provided for @basketSynced.
  ///
  /// In en, this message translates to:
  /// **'Your basket has been saved!'**
  String get basketSynced;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue with checkout'**
  String get loginToContinue;

  /// No description provided for @loginToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Sign in to place your order.'**
  String get loginToPlaceOrder;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be less than 100 characters'**
  String get nameTooLong;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your Babka account?'**
  String get signOutConfirmation;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// No description provided for @failedToUpdateProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile picture'**
  String get failedToUpdateProfilePicture;

  /// No description provided for @locationCaptured.
  ///
  /// In en, this message translates to:
  /// **'Location captured successfully'**
  String get locationCaptured;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Please enter manually.'**
  String get locationError;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get creditCard;

  /// No description provided for @payWithCardOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pay with card upon delivery (Coming Soon)'**
  String get payWithCardOnDelivery;

  /// No description provided for @thankYouBabka.
  ///
  /// In en, this message translates to:
  /// **'Thank you for choosing Babka! Your fresh bread is being prepared.'**
  String get thankYouBabka;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @paymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment Info'**
  String get paymentInfo;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @removeItemFromBasket.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item from your basket?'**
  String get removeItemFromBasket;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @roleSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch Role'**
  String get roleSwitch;

  /// No description provided for @lastUsedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Last used addresses'**
  String get lastUsedAddresses;

  /// No description provided for @customerApp.
  ///
  /// In en, this message translates to:
  /// **'Customer App'**
  String get customerApp;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @kitchenPanel.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Panel'**
  String get kitchenPanel;

  /// No description provided for @deliveryPanel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Panel'**
  String get deliveryPanel;

  /// No description provided for @changeSettingAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get changeSettingAnytime;

  /// No description provided for @addressName.
  ///
  /// In en, this message translates to:
  /// **'Address Name'**
  String get addressName;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @customName.
  ///
  /// In en, this message translates to:
  /// **'Custom Name'**
  String get customName;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @confirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get confirmPickup;

  /// No description provided for @openDetails.
  ///
  /// In en, this message translates to:
  /// **'Open Details'**
  String get openDetails;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @editPrice.
  ///
  /// In en, this message translates to:
  /// **'Edit Price'**
  String get editPrice;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @productManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @todaysRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todaysRevenue;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @manageOrders.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get manageOrders;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get statusShipping;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumberLabel;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @deliveryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressLabel;

  /// No description provided for @orderItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItemsLabel;

  /// No description provided for @placedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Placed at'**
  String get placedAtLabel;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// No description provided for @noOrdersInStatus.
  ///
  /// In en, this message translates to:
  /// **'No orders in this status'**
  String get noOrdersInStatus;

  /// No description provided for @pickupOrder.
  ///
  /// In en, this message translates to:
  /// **'Pick Up Order'**
  String get pickupOrder;

  /// No description provided for @confirmPickupMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to take this order. Once confirmed, you will be responsible for the delivery.'**
  String get confirmPickupMessage;

  /// No description provided for @acceptAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept & Confirm'**
  String get acceptAndConfirm;

  /// No description provided for @startPreparing.
  ///
  /// In en, this message translates to:
  /// **'Start Preparing'**
  String get startPreparing;

  /// No description provided for @markAsReady.
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready'**
  String get markAsReady;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noOrdersToPrepare.
  ///
  /// In en, this message translates to:
  /// **'No orders to prepare right now.'**
  String get noOrdersToPrepare;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @productActivated.
  ///
  /// In en, this message translates to:
  /// **'Product Activated'**
  String get productActivated;

  /// No description provided for @productDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Product Deactivated'**
  String get productDeactivated;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @newPrice.
  ///
  /// In en, this message translates to:
  /// **'New Price'**
  String get newPrice;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @assignToDelivery.
  ///
  /// In en, this message translates to:
  /// **'Assign to Delivery'**
  String get assignToDelivery;

  /// No description provided for @originalName.
  ///
  /// In en, this message translates to:
  /// **'Original Name (Default)'**
  String get originalName;

  /// No description provided for @originalDescription.
  ///
  /// In en, this message translates to:
  /// **'Original Description'**
  String get originalDescription;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @turkishTranslations.
  ///
  /// In en, this message translates to:
  /// **'Turkish Translations'**
  String get turkishTranslations;

  /// No description provided for @persianTranslations.
  ///
  /// In en, this message translates to:
  /// **'Persian Translations'**
  String get persianTranslations;

  /// No description provided for @nameTR.
  ///
  /// In en, this message translates to:
  /// **'Name (TR)'**
  String get nameTR;

  /// No description provided for @descriptionTR.
  ///
  /// In en, this message translates to:
  /// **'Description (TR)'**
  String get descriptionTR;

  /// No description provided for @nameFA.
  ///
  /// In en, this message translates to:
  /// **'Name (FA)'**
  String get nameFA;

  /// No description provided for @descriptionFA.
  ///
  /// In en, this message translates to:
  /// **'Description (FA)'**
  String get descriptionFA;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get openMap;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get roleUpdated;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product?'**
  String get confirmDeleteProduct;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clearBasket.
  ///
  /// In en, this message translates to:
  /// **'Clear Basket'**
  String get clearBasket;

  /// No description provided for @confirmClearBasket.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your entire basket?'**
  String get confirmClearBasket;

  /// No description provided for @passwordRequirementLength.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters'**
  String get passwordRequirementLength;

  /// No description provided for @passwordRequirementUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter (A-Z)'**
  String get passwordRequirementUppercase;

  /// No description provided for @passwordRequirementLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least one lowercase letter (a-z)'**
  String get passwordRequirementLowercase;

  /// No description provided for @passwordRequirementNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number (0-9)'**
  String get passwordRequirementNumber;

  /// No description provided for @passwordRequirementSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special characters (!@#\$%^&*) - Recommended'**
  String get passwordRequirementSpecial;

  /// No description provided for @accountDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Disabled'**
  String get accountDisabledTitle;

  /// No description provided for @accountDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been disabled for violating the rules and guidelines. You are only permitted to use the app as a viewer. Actions such as placing orders, updating your profile, or adding favorites are restricted.'**
  String get accountDisabledMessage;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @searchByPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByPlaceholder;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get filterAdmins;

  /// No description provided for @filterStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get filterStaff;

  /// No description provided for @filterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get filterDelivery;

  /// No description provided for @filterDisabledOnly.
  ///
  /// In en, this message translates to:
  /// **'Disabled Only'**
  String get filterDisabledOnly;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// No description provided for @enableAccount.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableAccount;

  /// No description provided for @disableAccount.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableAccount;

  /// No description provided for @userStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'User status updated'**
  String get userStatusUpdated;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @editUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit User Profile'**
  String get editUserProfile;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard all unsaved changes?'**
  String get discardChanges;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @confirmSaveProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to save this product?'**
  String get confirmSaveProduct;

  /// No description provided for @productSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully'**
  String get productSavedSuccess;

  /// No description provided for @productTagBestseller.
  ///
  /// In en, this message translates to:
  /// **'Best seller'**
  String get productTagBestseller;

  /// No description provided for @productTagSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get productTagSpecial;

  /// No description provided for @productTagNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get productTagNew;

  /// No description provided for @productTagLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get productTagLimited;

  /// No description provided for @productTagPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get productTagPopular;

  /// No description provided for @productTagTraditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get productTagTraditional;

  /// No description provided for @productTagRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get productTagRecommended;

  /// No description provided for @productTagSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get productTagSeasonal;

  /// No description provided for @productTagNone.
  ///
  /// In en, this message translates to:
  /// **'No Tag'**
  String get productTagNone;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirmStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to {status} account for {name}?'**
  String confirmStatusChange(String status, String name);

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'disable'**
  String get disable;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get statusDisabled;

  /// No description provided for @minOrderLimitError.
  ///
  /// In en, this message translates to:
  /// **'Minimum order amount is {limit} TL'**
  String minOrderLimitError(num limit);

  /// No description provided for @deliveryVerification.
  ///
  /// In en, this message translates to:
  /// **'Delivery Verification'**
  String get deliveryVerification;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 2-digit verification code'**
  String get enterVerificationCode;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN, please verify with customer'**
  String get invalidVerificationCode;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation'**
  String get cancellationReason;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get orderCancelled;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFeeLabel;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}x items'**
  String itemsCount(num count);

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @confirmRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'Slide to confirm rejection of this order. This action cannot be undone.'**
  String get confirmRejectMessage;

  /// No description provided for @slidetoReject.
  ///
  /// In en, this message translates to:
  /// **'Slide to Reject'**
  String get slidetoReject;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Order Tracking'**
  String get orderTracking;

  /// No description provided for @orderConfirmedStep.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderConfirmedStep;

  /// No description provided for @orderConfirmedDesc.
  ///
  /// In en, this message translates to:
  /// **'Store received the order'**
  String get orderConfirmedDesc;

  /// No description provided for @preparingStep.
  ///
  /// In en, this message translates to:
  /// **'Preparing Order'**
  String get preparingStep;

  /// No description provided for @preparingDesc.
  ///
  /// In en, this message translates to:
  /// **'Kitchen is preparing items'**
  String get preparingDesc;

  /// No description provided for @readyStep.
  ///
  /// In en, this message translates to:
  /// **'Ready for Pick-Up'**
  String get readyStep;

  /// No description provided for @readyDesc.
  ///
  /// In en, this message translates to:
  /// **'Waiting for courier allocation'**
  String get readyDesc;

  /// No description provided for @outForDeliveryStep.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDeliveryStep;

  /// No description provided for @outForDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Courier is on the way'**
  String get outForDeliveryDesc;

  /// No description provided for @deliveredStep.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredStep;

  /// No description provided for @deliveredDesc.
  ///
  /// In en, this message translates to:
  /// **'Order completed'**
  String get deliveredDesc;

  /// No description provided for @givePinToDriver.
  ///
  /// In en, this message translates to:
  /// **'Give this PIN to your driver:'**
  String get givePinToDriver;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @noDeliveryPersonFound.
  ///
  /// In en, this message translates to:
  /// **'No delivery person found'**
  String get noDeliveryPersonFound;

  /// No description provided for @totalToCollect.
  ///
  /// In en, this message translates to:
  /// **'Total to Collect'**
  String get totalToCollect;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @productStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully'**
  String get productStatusUpdated;

  /// No description provided for @successfullySelected.
  ///
  /// In en, this message translates to:
  /// **'Successfully selected {name}!'**
  String successfullySelected(String name);

  /// No description provided for @viewInformation.
  ///
  /// In en, this message translates to:
  /// **'View Information'**
  String get viewInformation;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDate;

  /// No description provided for @userOrders.
  ///
  /// In en, this message translates to:
  /// **'User Orders'**
  String get userOrders;

  /// No description provided for @userAddresses.
  ///
  /// In en, this message translates to:
  /// **'User Addresses'**
  String get userAddresses;

  /// No description provided for @userFavorites.
  ///
  /// In en, this message translates to:
  /// **'User Favorites'**
  String get userFavorites;

  /// No description provided for @noFavoritesFound.
  ///
  /// In en, this message translates to:
  /// **'No favorites found'**
  String get noFavoritesFound;

  /// No description provided for @noAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get noAddressesFound;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @noPhoneNumberAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get noPhoneNumberAvailable;

  /// No description provided for @couldNotOpenPhoneDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone dialer'**
  String get couldNotOpenPhoneDialer;

  /// No description provided for @orderNotAssignedError.
  ///
  /// In en, this message translates to:
  /// **'This order is not assigned to you in the database. Please try picking it up again.'**
  String get orderNotAssignedError;

  /// No description provided for @orderAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this order has already been assigned to another delivery person.'**
  String get orderAlreadyAssigned;

  /// No description provided for @noOrdersForPickup.
  ///
  /// In en, this message translates to:
  /// **'No orders ready for pickup'**
  String get noOrdersForPickup;

  /// No description provided for @noActiveDeliveries.
  ///
  /// In en, this message translates to:
  /// **'You have no active deliveries'**
  String get noActiveDeliveries;

  /// No description provided for @syncingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Syncing permissions...'**
  String get syncingPermissions;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note: '**
  String get noteLabel;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @locationServiceOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Service turned OFF'**
  String get locationServiceOffTitle;

  /// No description provided for @locationServiceOffMessage.
  ///
  /// In en, this message translates to:
  /// **'We need your location to find your address automatically. Please turn on Location Services in your system settings.'**
  String get locationServiceOffMessage;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn ON'**
  String get turnOn;

  /// No description provided for @nevermind.
  ///
  /// In en, this message translates to:
  /// **'Nevermind'**
  String get nevermind;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your location because your phone\'s location service is turned off. Please turn it on.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied, we cannot request permissions.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @errorVerifyingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error verifying profile'**
  String get errorVerifyingProfile;

  /// No description provided for @errorCreatingInitialProfile.
  ///
  /// In en, this message translates to:
  /// **'Error creating initial profile'**
  String get errorCreatingInitialProfile;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShort;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsShort;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejected;

  /// No description provided for @prepTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Prep Time (mins)'**
  String get prepTimeLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get caloriesLabel;

  /// No description provided for @freshToday.
  ///
  /// In en, this message translates to:
  /// **'Fresh Today'**
  String get freshToday;

  /// No description provided for @outOfOven.
  ///
  /// In en, this message translates to:
  /// **'Just Out of Oven'**
  String get outOfOven;

  /// No description provided for @limitedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Limited Quantity'**
  String get limitedQuantity;

  /// No description provided for @pleaseFillFloorDoor.
  ///
  /// In en, this message translates to:
  /// **'Please fill these out to continue'**
  String get pleaseFillFloorDoor;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by Order # or Customer'**
  String get searchPlaceholder;

  /// No description provided for @filterDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get filterDelivered;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get adjustFilters;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access'**
  String get unauthorized;

  /// No description provided for @appStartFailed.
  ///
  /// In en, this message translates to:
  /// **'App failed to start'**
  String get appStartFailed;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// No description provided for @errorLoadingStaff.
  ///
  /// In en, this message translates to:
  /// **'Error loading staff'**
  String get errorLoadingStaff;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @totalOrdersToday.
  ///
  /// In en, this message translates to:
  /// **'Total Orders Today'**
  String get totalOrdersToday;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @unlockCancellation.
  ///
  /// In en, this message translates to:
  /// **'Slide to unlock cancellation input'**
  String get unlockCancellation;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason here...'**
  String get enterReason;

  /// No description provided for @cancelReasonBusy.
  ///
  /// In en, this message translates to:
  /// **'Store too busy'**
  String get cancelReasonBusy;

  /// No description provided for @cancelReasonStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get cancelReasonStock;

  /// No description provided for @cancelReasonCourier.
  ///
  /// In en, this message translates to:
  /// **'No courier available'**
  String get cancelReasonCourier;

  /// No description provided for @cancelReasonTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical issue'**
  String get cancelReasonTechnical;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other (write below)'**
  String get cancelReasonOther;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String assignedTo(String name);

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettings;

  /// No description provided for @customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// No description provided for @customBabka.
  ///
  /// In en, this message translates to:
  /// **'Custom Babka'**
  String get customBabka;

  /// No description provided for @customBabkaDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable the Make Your Own Babka feature for customers.'**
  String get customBabkaDescription;

  /// No description provided for @minOrderLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Limit (TL)'**
  String get minOrderLimitLabel;

  /// No description provided for @deliveryFeeSettingLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee (TL)'**
  String get deliveryFeeSettingLabel;

  /// No description provided for @pointsPerOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Points Per Order'**
  String get pointsPerOrderLabel;

  /// No description provided for @pointsPerCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Points Per Currency Unit'**
  String get pointsPerCurrencyLabel;

  /// No description provided for @pointsEarningRule.
  ///
  /// In en, this message translates to:
  /// **'Points Earning Rule'**
  String get pointsEarningRule;

  /// No description provided for @totalSpentRule.
  ///
  /// In en, this message translates to:
  /// **'Points = Total Spent (1:1)'**
  String get totalSpentRule;

  /// No description provided for @totalSpentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1 TL = 1 Point'**
  String get totalSpentSubtitle;

  /// No description provided for @fixedPointsRule.
  ///
  /// In en, this message translates to:
  /// **'Fixed Points per Order'**
  String get fixedPointsRule;

  /// No description provided for @streakBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak Bonus Points'**
  String get streakBonusLabel;

  /// No description provided for @streakThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak Threshold (Days)'**
  String get streakThresholdLabel;

  /// No description provided for @loyaltySettings.
  ///
  /// In en, this message translates to:
  /// **'Loyalty & Streak Settings'**
  String get loyaltySettings;

  /// No description provided for @rewardsManagement.
  ///
  /// In en, this message translates to:
  /// **'Rewards Management'**
  String get rewardsManagement;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get freeDelivery;

  /// No description provided for @loyaltyCenter.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Center'**
  String get loyaltyCenter;

  /// No description provided for @loyaltySystemDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The loyalty and rewards system is currently under development. Points earned now will be valid when the system is fully launched.'**
  String get loyaltySystemDisclaimer;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @streakDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Day Streak} other{{count} Day Streak}}'**
  String streakDay(num count);

  /// No description provided for @memberLevel.
  ///
  /// In en, this message translates to:
  /// **'{level} Member'**
  String memberLevel(Object level);

  /// No description provided for @pointsUntilLevel.
  ///
  /// In en, this message translates to:
  /// **'{count} points until {level}'**
  String pointsUntilLevel(Object count, Object level);

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeem;

  /// No description provided for @redeemReward.
  ///
  /// In en, this message translates to:
  /// **'Redeem Reward'**
  String get redeemReward;

  /// No description provided for @confirmRedeem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to spend {points} points for {reward}?'**
  String confirmRedeem(Object points, Object reward);

  /// No description provided for @rewardRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed successfully!'**
  String get rewardRedeemed;

  /// No description provided for @rateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateExperience;

  /// No description provided for @rateOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'How was your order from Babka?'**
  String get rateOrderMessage;

  /// No description provided for @overallSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Overall Satisfaction'**
  String get overallSatisfaction;

  /// No description provided for @breadQuality.
  ///
  /// In en, this message translates to:
  /// **'Bread Quality'**
  String get breadQuality;

  /// No description provided for @freshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get freshness;

  /// No description provided for @packaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get packaging;

  /// No description provided for @deliveryService.
  ///
  /// In en, this message translates to:
  /// **'Delivery Service'**
  String get deliveryService;

  /// No description provided for @writtenReview.
  ///
  /// In en, this message translates to:
  /// **'Written Review (Optional)'**
  String get writtenReview;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about your experience...'**
  String get reviewHint;

  /// No description provided for @feedbackThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback! +{points} Pts'**
  String feedbackThankYou(Object points);

  /// No description provided for @promotionsBanners.
  ///
  /// In en, this message translates to:
  /// **'Promotions & Banners'**
  String get promotionsBanners;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @noPromotions.
  ///
  /// In en, this message translates to:
  /// **'No promotions found'**
  String get noPromotions;

  /// No description provided for @addPromotion.
  ///
  /// In en, this message translates to:
  /// **'Add Promotion'**
  String get addPromotion;

  /// No description provided for @editPromotion.
  ///
  /// In en, this message translates to:
  /// **'Edit Promotion'**
  String get editPromotion;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @rewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Title'**
  String get rewardTitle;

  /// No description provided for @pointsCost.
  ///
  /// In en, this message translates to:
  /// **'Points Cost'**
  String get pointsCost;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get pts;

  /// No description provided for @ptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get ptsLabel;

  /// No description provided for @noRewards.
  ///
  /// In en, this message translates to:
  /// **'No rewards available'**
  String get noRewards;

  /// No description provided for @addReward.
  ///
  /// In en, this message translates to:
  /// **'Add Reward'**
  String get addReward;

  /// No description provided for @editReward.
  ///
  /// In en, this message translates to:
  /// **'Edit Reward'**
  String get editReward;

  /// No description provided for @rateOrder.
  ///
  /// In en, this message translates to:
  /// **'Rate Order'**
  String get rateOrder;

  /// No description provided for @rated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get rated;

  /// No description provided for @confirmChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change this user\'s profile picture?'**
  String get confirmChangeAvatar;

  /// No description provided for @reviewManagement.
  ///
  /// In en, this message translates to:
  /// **'Review Management'**
  String get reviewManagement;

  /// No description provided for @noReviewsFound.
  ///
  /// In en, this message translates to:
  /// **'No reviews found'**
  String get noReviewsFound;

  /// No description provided for @reviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Review approved'**
  String get reviewApproved;

  /// No description provided for @reviewDeleted.
  ///
  /// In en, this message translates to:
  /// **'Review deleted'**
  String get reviewDeleted;

  /// No description provided for @deleteReview.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get deleteReview;

  /// No description provided for @confirmDeleteReview.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this review?'**
  String get confirmDeleteReview;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderIdLabel(String id);

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @statusPendingCaps.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get statusPendingCaps;

  /// No description provided for @statusApprovedCaps.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get statusApprovedCaps;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code'**
  String get invitationCode;

  /// No description provided for @invitationCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code (Optional)'**
  String get invitationCodeOptional;

  /// No description provided for @invitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String invitedBy(Object name);

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCode;

  /// No description provided for @referralReward.
  ///
  /// In en, this message translates to:
  /// **'Referral Reward'**
  String get referralReward;

  /// No description provided for @successfulReferrals.
  ///
  /// In en, this message translates to:
  /// **'Successful Referrals'**
  String get successfulReferrals;

  /// No description provided for @friendsInvited.
  ///
  /// In en, this message translates to:
  /// **'Friends Invited'**
  String get friendsInvited;

  /// No description provided for @referralPoints.
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get referralPoints;

  /// No description provided for @invalidInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invitation code'**
  String get invalidInvitationCode;

  /// No description provided for @invitationCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Invitation code applied!'**
  String get invitationCodeApplied;

  /// No description provided for @invitationReward.
  ///
  /// In en, this message translates to:
  /// **'Invitation Reward'**
  String get invitationReward;

  /// No description provided for @referralRewardNotification.
  ///
  /// In en, this message translates to:
  /// **'Your referral reward has been added!'**
  String get referralRewardNotification;

  /// No description provided for @inviteFriendMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing beats fresh, hot Babka straight from the oven! 🍞🔥\n\nSign up with my invite link:\nhttps://app.Babka.tr/?ref={code}'**
  String inviteFriendMessage(Object code);

  /// No description provided for @copySuccess.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard!'**
  String get copySuccess;

  /// No description provided for @selfReferralError.
  ///
  /// In en, this message translates to:
  /// **'You cannot use your own referral code'**
  String get selfReferralError;

  /// No description provided for @inactiveReferralCodeError.
  ///
  /// In en, this message translates to:
  /// **'This referral code is no longer active'**
  String get inactiveReferralCodeError;

  /// No description provided for @featureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This feature is temporarily unavailable.'**
  String get featureUnavailable;

  /// No description provided for @referralSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referralSystemTitle;

  /// No description provided for @referralSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend to Babka and earn Loyalty Points.'**
  String get referralSystemDesc;

  /// No description provided for @referralStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get referralStatusPending;

  /// No description provided for @referralStatusRewarded.
  ///
  /// In en, this message translates to:
  /// **'Rewarded'**
  String get referralStatusRewarded;

  /// No description provided for @referralStats.
  ///
  /// In en, this message translates to:
  /// **'Referral Stats'**
  String get referralStats;

  /// No description provided for @referralSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards'**
  String get referralSectionTitle;

  /// No description provided for @invitationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your invitation code'**
  String get invitationCodeLabel;

  /// No description provided for @newOrdersAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 NEW ORDER AVAILABLE} other{{count} NEW ORDERS AVAILABLE}}'**
  String newOrdersAvailable(num count);

  /// No description provided for @pickUpOrder.
  ///
  /// In en, this message translates to:
  /// **'Pick Up Order'**
  String get pickUpOrder;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @newBabkaOrder.
  ///
  /// In en, this message translates to:
  /// **'New Babka Order'**
  String get newBabkaOrder;

  /// No description provided for @orderIsReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Order #{number} is ready for pickup.'**
  String orderIsReadyForPickup(Object number);

  /// No description provided for @deliverySuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered successfully! Enjoy your fresh bread.'**
  String get deliverySuccessMessage;

  /// No description provided for @orderInformation.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderInformation;

  /// No description provided for @ratingValue.
  ///
  /// In en, this message translates to:
  /// **'{value}.0'**
  String ratingValue(num value);

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @assignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to You'**
  String get assignedToYou;

  /// No description provided for @agreeToTermsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms & Privacy Policy.'**
  String get agreeToTermsAndPrivacy;

  /// No description provided for @haveInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invitation code?'**
  String get haveInvitationCode;

  /// No description provided for @noOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'No order history yet'**
  String get noOrderHistory;

  /// No description provided for @noCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'No completed orders yet'**
  String get noCompletedOrders;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @averageOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order Value'**
  String get averageOrderValue;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top Products'**
  String get topProducts;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @revenueDashboard.
  ///
  /// In en, this message translates to:
  /// **'Revenue Dashboard'**
  String get revenueDashboard;

  /// No description provided for @weeklySalesTrends.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sales Trends'**
  String get weeklySalesTrends;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// No description provided for @avgDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. Delivery Time'**
  String get avgDeliveryTime;

  /// No description provided for @liveOrderProgress.
  ///
  /// In en, this message translates to:
  /// **'Live Order Progress'**
  String get liveOrderProgress;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @appDomain.
  ///
  /// In en, this message translates to:
  /// **'App Domain'**
  String get appDomain;
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
      <String>['en', 'fa', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
