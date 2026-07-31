// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Sangak';

  @override
  String get bakerySubtitle => 'Artizan Pers Fırını';

  @override
  String get welcomeToSangak => 'Sangak\'a Hoş Geldiniz';

  @override
  String get chooseLanguage => 'Dilinizi seçin';

  @override
  String get pleaseSelectLanguage =>
      'Devam etmek için lütfen tercih ettiğiniz dili seçin.';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get welcomeBack => 'Tekrar Hoş Geldiniz';

  @override
  String get email => 'E-posta';

  @override
  String get enterEmail => 'E-postanızı girin';

  @override
  String get password => 'Şifre';

  @override
  String get enterPassword => 'Şifrenizi girin';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signIn => 'Oturum Aç';

  @override
  String get or => 'VEYA';

  @override
  String get continueWithGoogle => 'Google ile Devam Et';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu? ';

  @override
  String get createOne => 'Yeni bir tane oluştur';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get enterFullName => 'Adınızı ve soyadınızı girin';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String get enterPhoneNumber => 'Telefon numaranızı girin';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get reEnterPassword => 'Şifrenizi tekrar girin';

  @override
  String get iAgreeToTerms => 'Şartlar ve Koşulları kabul ediyorum';

  @override
  String get verificationEmailSent => 'Doğrulama e-postası gönderildi!';

  @override
  String get goodMorning => 'Günaydın,';

  @override
  String get welcomeToSangakGuest => 'Sangak\'a Hoş Geldiniz,';

  @override
  String get guest => 'Misafir';

  @override
  String get popularToday => 'Bugün Popüler';

  @override
  String get seeAll => 'Hepsini Gör';

  @override
  String get categories => 'Kategoriler';

  @override
  String get traditionalFavorites => 'Geleneksel Favoriler';

  @override
  String get addToBasket => 'Sepete Ekle';

  @override
  String addedToBasket(Object title) {
    return '$title sepete eklendi!';
  }

  @override
  String get saveYourFavorites => 'Favorilerinizi kaydedin';

  @override
  String get saveFavoritesMessage =>
      'Favori artizan ekmeklerinizi kaydetmek ve istediğiniz zaman erişmek için bir hesap oluşturun.';

  @override
  String get yourBasketIsWaiting => 'Sepetiniz sizi bekliyor';

  @override
  String get cartGuestMessage =>
      'Ürünlerinizi kaydetmek, siparişlerinizi takip etmek ve ödemenizi zahmetsizce tamamlamak için bir hesap oluşturun.';

  @override
  String get joinTheFamily => 'Sangak ailesine katılın';

  @override
  String get profileGuestMessage =>
      'Profilinizi yönetmek, sipariş geçmişini görüntülemek ve özel fırın tekliflerine erişmek için oturum açın.';

  @override
  String get signInRegister => 'Giriş Yap / Kayıt Ol';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get explore => 'Keşfet';

  @override
  String get cart => 'Sepet';

  @override
  String get profile => 'Profil';

  @override
  String get newUpdateAvailable => 'Yeni Güncelleme Mevcut';

  @override
  String updateAvailableMessage(Object version) {
    return 'Sangak\'ın yeni bir versiyonu ($version) mevcut. En yeni özelliklerin ve iyileştirmelerin keyfini çıkarmak için şimdi güncelleyin.';
  }

  @override
  String get whatsNew => 'Yenilikler:';

  @override
  String get updateNow => 'Şimdi Güncelle';

  @override
  String get later => 'Sonra';
}
