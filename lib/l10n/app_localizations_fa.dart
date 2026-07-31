// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'Sangak';

  @override
  String get bakerySubtitle => 'نانوایی سنتی سنگک';

  @override
  String get welcomeToSangak => 'به سنگک خوش آمدید';

  @override
  String get chooseLanguage => 'زبان خود را انتخاب کنید';

  @override
  String get pleaseSelectLanguage =>
      'لطفاً برای ادامه، زبان مورد نظر خود را انتخاب کنید.';

  @override
  String get continueButton => 'ادامه';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get email => 'ایمیل';

  @override
  String get enterEmail => 'ایمیل خود را وارد کنید';

  @override
  String get password => 'رمز عبور';

  @override
  String get enterPassword => 'رمز عبور خود را وارد کنید';

  @override
  String get forgotPassword => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get login => 'ورود';

  @override
  String get signIn => 'ورود به حساب';

  @override
  String get or => 'یا';

  @override
  String get continueWithGoogle => 'ادامه با گوگل';

  @override
  String get dontHaveAccount => 'حساب کاربری ندارید؟ ';

  @override
  String get createOne => 'یکی بسازید';

  @override
  String get createAccount => 'ساخت حساب کاربری';

  @override
  String get fullName => 'نام و نام خانوادگی';

  @override
  String get enterFullName => 'نام کامل خود را وارد کنید';

  @override
  String get phoneNumber => 'شماره تلفن';

  @override
  String get enterPhoneNumber => 'شماره تلفن خود را وارد کنید';

  @override
  String get confirmPassword => 'تأیيد رمز عبور';

  @override
  String get reEnterPassword => 'رمز عبور را دوباره وارد کنید';

  @override
  String get iAgreeToTerms => 'با شرایط و قوانین موافقم';

  @override
  String get verificationEmailSent => 'ایمیل تأیید ارسال شد!';

  @override
  String get goodMorning => 'صبح بخیر،';

  @override
  String get welcomeToSangakGuest => 'به سنگک خوش آمدید،';

  @override
  String get guest => 'مهمان';

  @override
  String get popularToday => 'محبوب‌های امروز';

  @override
  String get seeAll => 'مشاهده همه';

  @override
  String get categories => 'دسته‌بندی‌ها';

  @override
  String get traditionalFavorites => 'محبوب‌های سنتی';

  @override
  String get addToBasket => 'افزودن به سبد';

  @override
  String addedToBasket(Object title) {
    return '$title به سبد خرید اضافه شد!';
  }

  @override
  String get saveYourFavorites => 'علاقه‌مندی‌های خود را ذخیره کنید';

  @override
  String get saveFavoritesMessage =>
      'برای ذخیره نان‌های مورد علاقه خود و دسترسی همیشگی به آن‌ها، یک حساب کاربری بسازید.';

  @override
  String get yourBasketIsWaiting => 'سبد خرید شما منتظر است';

  @override
  String get cartGuestMessage =>
      'برای ذخیره اقلام، پیگیری سفارشات و تکمیل خرید خود، یک حساب کاربری بسازید.';

  @override
  String get joinTheFamily => 'به خانواده سنگک بپیوندید';

  @override
  String get profileGuestMessage =>
      'برای مدیریت پروفایل، مشاهده سوابق سفارش و دسترسی به پیشنهادهای ویژه، وارد شوید.';

  @override
  String get signInRegister => 'ورود / ثبت‌نام';

  @override
  String get home => 'خانه';

  @override
  String get explore => 'جستجو';

  @override
  String get cart => 'سبد خرید';

  @override
  String get profile => 'پروفایل';

  @override
  String get newUpdateAvailable => 'نسخه جدید در دسترس است';

  @override
  String updateAvailableMessage(Object version) {
    return 'نسخه جدید ($version) سنگک در دسترس است. برای بهره‌مندی از آخرین ویژگی‌ها و بهبودها، همین حالا بروزرسانی کنید.';
  }

  @override
  String get whatsNew => 'موارد جدید:';

  @override
  String get updateNow => 'بروزرسانی';

  @override
  String get later => 'بعداً';
}
