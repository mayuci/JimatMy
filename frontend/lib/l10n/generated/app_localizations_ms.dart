// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTagline => 'Bandingkan harga. Jimat setiap hari.';

  @override
  String get splashConnecting => 'Menyambung ke data PriceCatcherâ€¦';

  @override
  String get splashErrorTitle => 'Kami tidak dapat menyambung';

  @override
  String get splashErrorMessage =>
      'Data harga tidak tersedia buat sementara. Semak sambungan anda dan cuba lagi.';

  @override
  String get retry => 'Cuba lagi';

  @override
  String get navHome => 'Utama';

  @override
  String get navSearch => 'Carian';

  @override
  String get navPlanner => 'Pelan';

  @override
  String get navNearby => 'Berdekatan';

  @override
  String get navProfile => 'Profil';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsLocationSection => 'Lokasi';

  @override
  String get settingsSelectedArea => 'Kawasan dipilih';

  @override
  String get settingsUseDeviceLocation => 'Gunakan lokasi peranti';

  @override
  String get settingsPermissionActive =>
      'Kebenaran lokasi aktif untuk sesi ini.';

  @override
  String get settingsPermissionRequested =>
      'Diminta hanya apabila anda memilih untuk mengaktifkannya.';

  @override
  String get settingsLocationEnabled => 'Lokasi diaktifkan.';

  @override
  String get settingsLocationFailed =>
      'Lokasi tidak dapat diaktifkan. Anda boleh memilih kawasan secara manual.';

  @override
  String get settingsAppInfoSection => 'Maklumat aplikasi';

  @override
  String get settingsVersion => 'Versi 1.0.0';

  @override
  String get settingsLanguageSection => 'Bahasa';

  @override
  String get settingsLanguageSubtitle =>
      'Pilih bahasa yang dipaparkan dalam aplikasi.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get languageChinese => 'ä¸­æ–‡';

  @override
  String get priceUnavailable => 'Harga tidak tersedia';

  @override
  String get unavailable => 'Tidak tersedia';

  @override
  String get noCurrentPremise => 'Tiada premis semasa';

  @override
  String get priceComparison => 'Perbandingan Harga';

  @override
  String get priceTrend => 'Trend Harga';

  @override
  String get itemDetailTitle => 'Butiran Item';

  @override
  String get detailsUnavailable => 'Butiran tidak tersedia';

  @override
  String get itemLoadFailed => 'Item tidak dapat dimuatkan.';

  @override
  String get dailyPrice => 'Harga harian';

  @override
  String get summaryLowest => 'Terendah';

  @override
  String get summaryPremises => 'Premis';

  @override
  String get summaryAverage => 'Purata';

  @override
  String get latestPrices => 'Harga terkini';

  @override
  String get latestPricesSubtitle => 'Harga import terkini di setiap premis';

  @override
  String get noPricesYet => 'Tiada harga lagi';

  @override
  String get noPricesMessage => 'Tiada harga premis diimport untuk item ini.';

  @override
  String get addToFavourites => 'Tambah ke kegemaran';

  @override
  String get removeFromFavourites => 'Buang dari kegemaran';

  @override
  String get notNow => 'Tidak sekarang';

  @override
  String get login => 'Log masuk';

  @override
  String get cancel => 'Batal';

  @override
  String get homeSearchHint => 'Cari ayam, beras, susu...';

  @override
  String get homeSearchSemantics => 'Buka carian barangan runcit';

  @override
  String get homeSearchNoResults => 'Tiada item sepadan';

  @override
  String get homeChooseLocation => 'Pilih lokasi anda';

  @override
  String get homeSelectLocation => 'Pilih lokasi';

  @override
  String get homeLowestPricesTitle => 'Harga Terendah Hari Ini';

  @override
  String get homePopularCategories => 'Kategori Popular';

  @override
  String get homeWeeklyBasketTitle => 'Mulakan dengan bakul mingguan';

  @override
  String get homeWeeklyBasketSubtitle =>
      'Anggaran PriceCatcher sebenar untuk pelajar, pasangan dan keluarga.';

  @override
  String get homeNoPrices => 'Harga pilihan semasa tidak tersedia.';

  @override
  String homeBasketIntro(String household) {
    return 'Bakul seminggu untuk $household. Kuantiti masih boleh disunting.';
  }

  @override
  String homeCreateBasket(String total) {
    return 'Cipta bakul Â· RM $total';
  }

  @override
  String get homeBasketCreateFailed => 'Bakul tidak dapat dicipta.';

  @override
  String get homeInsightTitle => 'Wawasan JimatMY';

  @override
  String get homeInsightStable => 'kekal stabil';

  @override
  String homeInsightDecreased(String percent) {
    return 'menurun $percent%';
  }

  @override
  String homeInsightIncreased(String percent) {
    return 'meningkat $percent%';
  }

  @override
  String get homeCategoryFreshFood => 'Makanan Segar';

  @override
  String get homeCategoryVegetables => 'Sayur-sayuran';

  @override
  String get homeCategoryFruits => 'Buah-buahan';

  @override
  String get homeCategoryEggs => 'Telur';

  @override
  String get homeCategoryDrinks => 'Minuman';

  @override
  String get homeCategoryDryGoods => 'Barangan Kering';

  @override
  String get homeCategoryBaby => 'Produk Bayi';

  @override
  String get homeCategoryHousehold => 'Rumah Tangga';

  @override
  String get homeQuickCompare => 'Perbandingan Harga';

  @override
  String get homeQuickPlanner => 'Pelan Membeli-belah';

  @override
  String get homeQuickTrends => 'Trend Harga';

  @override
  String homeInsightSentence(String itemName, String direction) {
    return 'Harga $itemName $direction.';
  }

  @override
  String get homeQuickNearby => 'Kedai Berdekatan';

  @override
  String get email => 'E-mel';

  @override
  String get password => 'Kata laluan';

  @override
  String get name => 'Nama';

  @override
  String get confirmPassword => 'Sahkan kata laluan';

  @override
  String get invalidEmail => 'Masukkan alamat e-mel yang sah.';

  @override
  String get enterPassword => 'Masukkan kata laluan anda.';

  @override
  String get showPassword => 'Tunjuk kata laluan';

  @override
  String get hidePassword => 'Sembunyi kata laluan';

  @override
  String get createAccount => 'Buat akaun';

  @override
  String get createAccountShort => 'Buat akaun';

  @override
  String get passwordRequirementLength => 'Sekurang-kurangnya 10 aksara';

  @override
  String get passwordRequirementUpper => 'Satu huruf besar (A-Z)';

  @override
  String get passwordRequirementLower => 'Satu huruf kecil (a-z)';

  @override
  String get passwordRequirementNumber => 'Satu nombor (0-9)';

  @override
  String get passwordStrong => 'Kata laluan kukuh';

  @override
  String get loginWelcome => 'Selamat kembali';

  @override
  String get loginSubtitle =>
      'Log masuk untuk terus merancang perjalanan membeli-belah dengan lebih bijak.';

  @override
  String get registerTitle => 'Cipta akaun JimatMY anda';

  @override
  String get registerSubtitle =>
      'Simpan kegemaran, senarai beli-belah, dan bajet bulanan anda.';

  @override
  String get passwordHelper =>
      '10+ aksara dengan huruf besar, huruf kecil, dan nombor.';

  @override
  String get enterName => 'Masukkan sekurang-kurangnya 2 aksara.';

  @override
  String get weakPassword => 'Gunakan kata laluan yang lebih kukuh.';

  @override
  String get passwordsMismatch => 'Kata laluan tidak sepadan.';

  @override
  String get backToLogin => 'Kembali ke Log masuk';

  @override
  String get priceComparisonTitle => 'Perbandingan harga';

  @override
  String get state => 'Negeri';

  @override
  String get pricesUnavailable => 'Harga tidak tersedia';

  @override
  String get noPricesFound => 'Tiada harga ditemui';

  @override
  String get noPricesMatchFilters =>
      'Tiada harga premis semasa yang sepadan dengan penapis ini.';

  @override
  String get resetFilters => 'Set semula penapis';

  @override
  String premisePricesCount(int count) {
    return '$count harga premis';
  }

  @override
  String get allStates => 'Semua negeri';

  @override
  String get allDistricts => 'Semua daerah';

  @override
  String get district => 'Daerah';

  @override
  String get addToPlanner => 'Tambah ke Pelan';

  @override
  String get loginToUsePlanner => 'Log masuk untuk menggunakan Pelan';

  @override
  String get plannerSaveNote =>
      'Simpan item ini ke senarai beli-belah selepas log masuk.';

  @override
  String get createListFirst => 'Cipta senarai beli-belah dahulu';

  @override
  String get plannerNeedsList =>
      'Pelan memerlukan senarai beli-belah sebelum item ini boleh ditambah.';

  @override
  String get openPlanner => 'Buka Pelan';

  @override
  String get chooseShoppingList => 'Pilih senarai beli-belah';

  @override
  String get addedToShoppingList => 'Ditambah ke senarai beli-belah anda';

  @override
  String get priceTrendTitle => 'Trend harga';

  @override
  String get trendUnavailable => 'Trend tidak tersedia';

  @override
  String get noTrendData => 'Tiada data trend';

  @override
  String get noTrendMessage => 'Tiada harga harian untuk tempoh ini.';

  @override
  String get moreHistoryTitle => 'Perlu lebih banyak sejarah';

  @override
  String get moreHistoryMessage =>
      'Sekurang-kurangnya dua harga harian diperlukan untuk menunjukkan trend.';

  @override
  String get searchTitle => 'Cari item';

  @override
  String get browseItems => 'Semak imbas item';

  @override
  String get results => 'Keputusan';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Kosongkan carian';

  @override
  String get filterItems => 'Tapis item';

  @override
  String get pricesAvailable => 'Harga tersedia';

  @override
  String get itemsUnavailable => 'Item tidak tersedia';

  @override
  String get noGroceries => 'Tiada barangan runcit tersedia';

  @override
  String get noMatchingGroceries => 'Tiada barangan runcit sepadan';

  @override
  String get searchEmptyMessage =>
      'Cuba carian lain atau set semula penapis anda.';

  @override
  String get loadMore => 'Muat lagi';

  @override
  String get category => 'Kategori';

  @override
  String get locationFiltersUnavailable =>
      'Penapis lokasi tidak tersedia buat sementara.';

  @override
  String get hasAvailablePricesTitle => 'Mempunyai harga tersedia';

  @override
  String get hasAvailablePricesSubtitle =>
      'Hanya tunjukkan item yang dihargai oleh premis';

  @override
  String get applyFilters => 'Guna penapis';

  @override
  String openShoppingList(String name) {
    return 'Buka $name';
  }

  @override
  String get searchAll => 'Semua';

  @override
  String get searchChicken => 'Ayam';

  @override
  String get searchMeat => 'Daging';

  @override
  String get searchEggs => 'Telur';

  @override
  String get searchVegetables => 'Sayur-sayuran';

  @override
  String get searchFruits => 'Buah-buahan';

  @override
  String get searchDrinks => 'Minuman';

  @override
  String get searchDryGoods => 'Barangan Kering';

  @override
  String get searchBaby => 'Bayi';

  @override
  String get searchHousehold => 'Rumah Tangga';

  @override
  String get plannerTitle => 'Pelan Membeli-belah';

  @override
  String get createShoppingList => 'Cipta senarai beli-belah';

  @override
  String get listName => 'Nama senarai';

  @override
  String get createListShort => 'Cipta senarai';

  @override
  String get create => 'Cipta';

  @override
  String get rename => 'Nama semula';

  @override
  String get delete => 'Padam';

  @override
  String get save => 'Simpan';

  @override
  String weeklyBasketSubtitle(String household) {
    return '$household â€¢ bakul mingguan';
  }

  @override
  String createListWithTotal(String total) {
    return 'Cipta senarai â€¢ RM $total';
  }

  @override
  String get basketCreateFailed => 'Bakul tidak dapat dicipta.';

  @override
  String get setMonthlyBudget => 'Tetapkan bajet bulanan';

  @override
  String get editMonthlyBudget => 'Sunting bajet bulanan';

  @override
  String get budgetAmountLabel => 'Jumlah (RM)';

  @override
  String get enterPositiveAmount => 'Masukkan jumlah RM yang positif.';

  @override
  String get enterListName => 'Masukkan nama senarai.';

  @override
  String get renameShoppingList => 'Nama semula senarai beli-belah';

  @override
  String get deleteShoppingListQuestion => 'Padam senarai beli-belah?';

  @override
  String deleteListConfirm(String name) {
    return 'Padam \"$name\" dan semua itemnya?';
  }

  @override
  String get signInToPlan => 'Log masuk untuk mencipta senarai beli-belah';

  @override
  String get plannerSignInMessage =>
      'Simpan produk, jejak bajet barangan runcit, dan bandingkan perjalanan membeli-belah yang dirancang.';

  @override
  String get plannerUnavailable => 'Pelan tidak tersedia';

  @override
  String get startWithBasket => 'Mulakan dengan bakul';

  @override
  String get reviewedWeeklyEssentials =>
      'Keperluan mingguan yang disemak dengan anggaran semasa sebenar.';

  @override
  String get yourShoppingLists => 'Senarai beli-belah anda';

  @override
  String get noShoppingListsYet => 'Tiada senarai beli-belah lagi';

  @override
  String get startPlanningMessage =>
      'Mula merancang barangan runcit dan jejak jumlah anggaran.';

  @override
  String get createYourFirstList => 'Cipta senarai pertama anda';

  @override
  String templateItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String templateUnavailableCount(int count) {
    return ' â€¢ $count tidak tersedia';
  }

  @override
  String get shoppingListTitle => 'Senarai beli-belah';

  @override
  String get myList => 'Senarai saya';

  @override
  String get completed => 'Selesai';

  @override
  String completedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selesai',
      one: '1 selesai',
    );
    return '$_temp0';
  }

  @override
  String get renameListDialog => 'Nama semula senarai';

  @override
  String get removeItemQuestion => 'Buang item?';

  @override
  String removeItemConfirm(String name) {
    return 'Buang $name daripada senarai ini?';
  }

  @override
  String get remove => 'Buang';

  @override
  String get shoppingListNotFound => 'Senarai beli-belah tidak ditemui.';

  @override
  String get listDeletedMessage =>
      'Ia mungkin telah dipadam oleh anda atau peranti lain.';

  @override
  String get backToPlanner => 'Kembali ke pelan';

  @override
  String get couldntLoadList => 'Tidak dapat memuatkan senarai beli-belah ini.';

  @override
  String get tryAgain => 'Cuba lagi';

  @override
  String get addItem => 'Tambah item';

  @override
  String get yourListIsEmpty => 'Senarai anda kosong';

  @override
  String get emptyListMessage =>
      'Tambah item untuk mula merancang perjalanan anda.';

  @override
  String get everythingCompleted => 'Semuanya selesai';

  @override
  String get noCompletedYet => 'Tiada item selesai lagi';

  @override
  String get completedHint =>
      'Buka Selesai untuk menyemak item yang ditandakan.';

  @override
  String get completedEmptyHint =>
      'Item yang anda tandakan akan muncul di sini.';

  @override
  String get estimatedTotal => 'Jumlah anggaran';

  @override
  String get noBudgetSet => 'Tiada bajet bulanan ditetapkan';

  @override
  String overBudget(String amount) {
    return 'RM $amount melebihi bajet';
  }

  @override
  String withinBudget(String amount) {
    return 'RM $amount dalam bajet';
  }

  @override
  String get findBestPlaces => 'Cari kedai terbaik';

  @override
  String profileGreeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get profileSubtitle =>
      'Bandingkan dengan lebih bijak dan jimat lebih.';

  @override
  String get myProfile => 'Profil Saya';

  @override
  String get budgetPlanner => 'Pelan Bajet';

  @override
  String get myFavourites => 'Kegemaran Saya';

  @override
  String get recentViews => 'Lihat Terkini';

  @override
  String get recentViewsMenu => 'Lihat Terkini';

  @override
  String get shoppingLists => 'Senarai beli-belah';

  @override
  String get settings => 'Tetapan';

  @override
  String get aboutJimatmy => 'Tentang JimatMY';

  @override
  String get logout => 'Log keluar';

  @override
  String get logoutQuestion => 'Log keluar?';

  @override
  String get logoutMessage =>
      'Data akaun yang disimpan akan kekal tersedia pada log masuk seterusnya.';

  @override
  String get loggingOut => 'Sedang log keluar...';

  @override
  String get openSettings => 'Buka tetapan';

  @override
  String get changeProfilePicture => 'Tukar gambar profil';

  @override
  String get guestTitle => 'Simpan rancangan membeli-belah anda';

  @override
  String get guestMessage =>
      'Log masuk untuk menyimpan kegemaran, item terkini, senarai beli-belah dan bajet bulanan anda bersama.';

  @override
  String get countUnavailable =>
      'Kiraan tidak tersedia. Tarik ke bawah untuk cuba lagi.';

  @override
  String get favourites => 'Kegemaran';

  @override
  String get forgotPassword => 'Terlupa kata laluan?';

  @override
  String get forgotPasswordTitle => 'Lupa kata laluan';

  @override
  String get forgotPasswordSubtitle =>
      'Masukkan e-mel berdaftar anda untuk menerima kod set semula enam digit.';

  @override
  String get registeredEmail => 'E-mel berdaftar';

  @override
  String get sendResetCode => 'Hantar kod set semula';

  @override
  String get resetPasswordTitle => 'Tetapkan semula kata laluan';

  @override
  String get resetPasswordSubtitle =>
      'Masukkan kod enam digit yang dihantar ke e-mel anda dan pilih kata laluan baharu.';

  @override
  String get resetCode => 'Kod set semula';

  @override
  String get newPassword => 'Kata laluan baharu';

  @override
  String get confirmNewPassword => 'Sahkan kata laluan baharu';

  @override
  String get resetPasswordButton => 'Tetapkan semula kata laluan';

  @override
  String get passwordResetSuccess =>
      'Kata laluan telah ditetapkan semula. Sila log masuk.';

  @override
  String get invalidResetCode => 'Masukkan kod enam digit.';

  @override
  String get resetCodeGenericError =>
      'Kod set semula ini tidak sah atau telah tamat tempoh.';
}
