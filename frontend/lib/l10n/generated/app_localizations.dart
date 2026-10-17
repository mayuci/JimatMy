import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ms'),
    Locale('zh'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Compare prices. Save every day.'**
  String get appTagline;

  /// No description provided for @splashConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to PriceCatcher dataâ€¦'**
  String get splashConnecting;

  /// No description provided for @splashErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not connect'**
  String get splashErrorTitle;

  /// No description provided for @splashErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Price data is temporarily unavailable. Check your connection and try again.'**
  String get splashErrorMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navPlanner;

  /// No description provided for @navNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get navNearby;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocationSection;

  /// No description provided for @settingsSelectedArea.
  ///
  /// In en, this message translates to:
  /// **'Selected area'**
  String get settingsSelectedArea;

  /// No description provided for @settingsUseDeviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Use device location'**
  String get settingsUseDeviceLocation;

  /// No description provided for @settingsPermissionActive.
  ///
  /// In en, this message translates to:
  /// **'Location permission is active for this session.'**
  String get settingsPermissionActive;

  /// No description provided for @settingsPermissionRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested only when you choose to enable it.'**
  String get settingsPermissionRequested;

  /// No description provided for @settingsLocationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Location enabled.'**
  String get settingsLocationEnabled;

  /// No description provided for @settingsLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Location could not be enabled. You can choose an area manually.'**
  String get settingsLocationFailed;

  /// No description provided for @settingsAppInfoSection.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get settingsAppInfoSection;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsVersion;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language shown in the app.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get languageMalay;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'ä¸­æ–‡'**
  String get languageChinese;

  /// No description provided for @priceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Price unavailable'**
  String get priceUnavailable;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @noCurrentPremise.
  ///
  /// In en, this message translates to:
  /// **'No current premise'**
  String get noCurrentPremise;

  /// No description provided for @priceComparison.
  ///
  /// In en, this message translates to:
  /// **'Price Comparison'**
  String get priceComparison;

  /// No description provided for @priceTrend.
  ///
  /// In en, this message translates to:
  /// **'Price Trend'**
  String get priceTrend;

  /// No description provided for @itemDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get itemDetailTitle;

  /// No description provided for @detailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Details unavailable'**
  String get detailsUnavailable;

  /// No description provided for @itemLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The item could not be loaded.'**
  String get itemLoadFailed;

  /// No description provided for @dailyPrice.
  ///
  /// In en, this message translates to:
  /// **'Daily price'**
  String get dailyPrice;

  /// No description provided for @summaryLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get summaryLowest;

  /// No description provided for @summaryPremises.
  ///
  /// In en, this message translates to:
  /// **'Premises'**
  String get summaryPremises;

  /// No description provided for @summaryAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get summaryAverage;

  /// No description provided for @latestPrices.
  ///
  /// In en, this message translates to:
  /// **'Latest prices'**
  String get latestPrices;

  /// No description provided for @latestPricesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most recent imported price at each premise'**
  String get latestPricesSubtitle;

  /// No description provided for @noPricesYet.
  ///
  /// In en, this message translates to:
  /// **'No prices yet'**
  String get noPricesYet;

  /// No description provided for @noPricesMessage.
  ///
  /// In en, this message translates to:
  /// **'No imported premise prices are available for this item.'**
  String get noPricesMessage;

  /// No description provided for @addToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addToFavourites;

  /// No description provided for @removeFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFromFavourites;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chicken, rice, milk...'**
  String get homeSearchHint;

  /// No description provided for @homeSearchSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open grocery search'**
  String get homeSearchSemantics;

  /// No description provided for @homeSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get homeSearchNoResults;

  /// No description provided for @homeChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose your location'**
  String get homeChooseLocation;

  /// No description provided for @homeSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get homeSelectLocation;

  /// No description provided for @homeLowestPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lowest Prices Today'**
  String get homeLowestPricesTitle;

  /// No description provided for @homePopularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Categories'**
  String get homePopularCategories;

  /// No description provided for @homeWeeklyBasketTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a weekly basket'**
  String get homeWeeklyBasketTitle;

  /// No description provided for @homeWeeklyBasketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real PriceCatcher estimates for students, couples and families.'**
  String get homeWeeklyBasketSubtitle;

  /// No description provided for @homeNoPrices.
  ///
  /// In en, this message translates to:
  /// **'Current featured prices are unavailable.'**
  String get homeNoPrices;

  /// No description provided for @homeBasketIntro.
  ///
  /// In en, this message translates to:
  /// **'A one-week basket for {household}. Quantities remain editable.'**
  String homeBasketIntro(String household);

  /// No description provided for @homeCreateBasket.
  ///
  /// In en, this message translates to:
  /// **'Create basket Â· RM {total}'**
  String homeCreateBasket(String total);

  /// No description provided for @homeBasketCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Basket could not be created.'**
  String get homeBasketCreateFailed;

  /// No description provided for @homeInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'JimatMY Insight'**
  String get homeInsightTitle;

  /// No description provided for @homeInsightStable.
  ///
  /// In en, this message translates to:
  /// **'remained stable'**
  String get homeInsightStable;

  /// No description provided for @homeInsightDecreased.
  ///
  /// In en, this message translates to:
  /// **'decreased {percent}%'**
  String homeInsightDecreased(String percent);

  /// No description provided for @homeInsightIncreased.
  ///
  /// In en, this message translates to:
  /// **'increased {percent}%'**
  String homeInsightIncreased(String percent);

  /// No description provided for @homeCategoryFreshFood.
  ///
  /// In en, this message translates to:
  /// **'Fresh Food'**
  String get homeCategoryFreshFood;

  /// No description provided for @homeCategoryVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get homeCategoryVegetables;

  /// No description provided for @homeCategoryFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get homeCategoryFruits;

  /// No description provided for @homeCategoryEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get homeCategoryEggs;

  /// No description provided for @homeCategoryDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get homeCategoryDrinks;

  /// No description provided for @homeCategoryDryGoods.
  ///
  /// In en, this message translates to:
  /// **'Dry Goods'**
  String get homeCategoryDryGoods;

  /// No description provided for @homeCategoryBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby Products'**
  String get homeCategoryBaby;

  /// No description provided for @homeCategoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get homeCategoryHousehold;

  /// No description provided for @homeQuickCompare.
  ///
  /// In en, this message translates to:
  /// **'Price Comparison'**
  String get homeQuickCompare;

  /// No description provided for @homeQuickPlanner.
  ///
  /// In en, this message translates to:
  /// **'Shopping Planner'**
  String get homeQuickPlanner;

  /// No description provided for @homeQuickTrends.
  ///
  /// In en, this message translates to:
  /// **'Price Trends'**
  String get homeQuickTrends;

  /// No description provided for @homeInsightSentence.
  ///
  /// In en, this message translates to:
  /// **'{itemName} prices {direction}.'**
  String homeInsightSentence(String itemName, String direction);

  /// No description provided for @homeQuickNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby Stores'**
  String get homeQuickNearby;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @createAccountShort.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountShort;

  /// No description provided for @passwordRequirementLength.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters'**
  String get passwordRequirementLength;

  /// No description provided for @passwordRequirementUpper.
  ///
  /// In en, this message translates to:
  /// **'An uppercase letter (A-Z)'**
  String get passwordRequirementUpper;

  /// No description provided for @passwordRequirementLower.
  ///
  /// In en, this message translates to:
  /// **'A lowercase letter (a-z)'**
  String get passwordRequirementLower;

  /// No description provided for @passwordRequirementNumber.
  ///
  /// In en, this message translates to:
  /// **'A number (0-9)'**
  String get passwordRequirementNumber;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong password'**
  String get passwordStrong;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue planning smarter grocery trips.'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your JimatMY account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save favourites, shopping lists, and your monthly budget.'**
  String get registerSubtitle;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'10+ characters with uppercase, lowercase, and a number.'**
  String get passwordHelper;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters.'**
  String get enterName;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a stronger password.'**
  String get weakPassword;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsMismatch;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Log in'**
  String get backToLogin;

  /// No description provided for @priceComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Price comparison'**
  String get priceComparisonTitle;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @pricesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prices unavailable'**
  String get pricesUnavailable;

  /// No description provided for @noPricesFound.
  ///
  /// In en, this message translates to:
  /// **'No prices found'**
  String get noPricesFound;

  /// No description provided for @noPricesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No current premise prices match these filters.'**
  String get noPricesMatchFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @premisePricesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} premise prices'**
  String premisePricesCount(int count);

  /// No description provided for @allStates.
  ///
  /// In en, this message translates to:
  /// **'All states'**
  String get allStates;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All districts'**
  String get allDistricts;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @addToPlanner.
  ///
  /// In en, this message translates to:
  /// **'Add to Planner'**
  String get addToPlanner;

  /// No description provided for @loginToUsePlanner.
  ///
  /// In en, this message translates to:
  /// **'Log in to use Planner'**
  String get loginToUsePlanner;

  /// No description provided for @plannerSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save this item to a shopping list after logging in.'**
  String get plannerSaveNote;

  /// No description provided for @createListFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a shopping list first'**
  String get createListFirst;

  /// No description provided for @plannerNeedsList.
  ///
  /// In en, this message translates to:
  /// **'Planner needs a shopping list before this item can be added.'**
  String get plannerNeedsList;

  /// No description provided for @openPlanner.
  ///
  /// In en, this message translates to:
  /// **'Open Planner'**
  String get openPlanner;

  /// No description provided for @chooseShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Choose a shopping list'**
  String get chooseShoppingList;

  /// No description provided for @addedToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Added to your shopping list'**
  String get addedToShoppingList;

  /// No description provided for @priceTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Price trend'**
  String get priceTrendTitle;

  /// No description provided for @trendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trend unavailable'**
  String get trendUnavailable;

  /// No description provided for @noTrendData.
  ///
  /// In en, this message translates to:
  /// **'No trend data'**
  String get noTrendData;

  /// No description provided for @noTrendMessage.
  ///
  /// In en, this message translates to:
  /// **'No daily prices are available for this period.'**
  String get noTrendMessage;

  /// No description provided for @moreHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'More history needed'**
  String get moreHistoryTitle;

  /// No description provided for @moreHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'At least two daily prices are needed to show a trend.'**
  String get moreHistoryMessage;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get searchTitle;

  /// No description provided for @browseItems.
  ///
  /// In en, this message translates to:
  /// **'Browse items'**
  String get browseItems;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filterItems.
  ///
  /// In en, this message translates to:
  /// **'Filter items'**
  String get filterItems;

  /// No description provided for @pricesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Prices available'**
  String get pricesAvailable;

  /// No description provided for @itemsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Items unavailable'**
  String get itemsUnavailable;

  /// No description provided for @noGroceries.
  ///
  /// In en, this message translates to:
  /// **'No groceries available'**
  String get noGroceries;

  /// No description provided for @noMatchingGroceries.
  ///
  /// In en, this message translates to:
  /// **'No matching groceries'**
  String get noMatchingGroceries;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another search or reset your filters.'**
  String get searchEmptyMessage;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @locationFiltersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location filters are temporarily unavailable.'**
  String get locationFiltersUnavailable;

  /// No description provided for @hasAvailablePricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Has available prices'**
  String get hasAvailablePricesTitle;

  /// No description provided for @hasAvailablePricesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only show items priced by a premise'**
  String get hasAvailablePricesSubtitle;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @openShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String openShoppingList(String name);

  /// No description provided for @searchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchAll;

  /// No description provided for @searchChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get searchChicken;

  /// No description provided for @searchMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get searchMeat;

  /// No description provided for @searchEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get searchEggs;

  /// No description provided for @searchVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get searchVegetables;

  /// No description provided for @searchFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get searchFruits;

  /// No description provided for @searchDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get searchDrinks;

  /// No description provided for @searchDryGoods.
  ///
  /// In en, this message translates to:
  /// **'Dry Goods'**
  String get searchDryGoods;

  /// No description provided for @searchBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get searchBaby;

  /// No description provided for @searchHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get searchHousehold;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping planner'**
  String get plannerTitle;

  /// No description provided for @createShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Create shopping list'**
  String get createShoppingList;

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// No description provided for @createListShort.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get createListShort;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @weeklyBasketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{household} â€¢ weekly basket'**
  String weeklyBasketSubtitle(String household);

  /// No description provided for @createListWithTotal.
  ///
  /// In en, this message translates to:
  /// **'Create list â€¢ RM {total}'**
  String createListWithTotal(String total);

  /// No description provided for @basketCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'The basket could not be created.'**
  String get basketCreateFailed;

  /// No description provided for @setMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Set monthly budget'**
  String get setMonthlyBudget;

  /// No description provided for @editMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit monthly budget'**
  String get editMonthlyBudget;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (RM)'**
  String get budgetAmountLabel;

  /// No description provided for @enterPositiveAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive RM amount.'**
  String get enterPositiveAmount;

  /// No description provided for @enterListName.
  ///
  /// In en, this message translates to:
  /// **'Enter a list name.'**
  String get enterListName;

  /// No description provided for @renameShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Rename shopping list'**
  String get renameShoppingList;

  /// No description provided for @deleteShoppingListQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete shopping list?'**
  String get deleteShoppingListQuestion;

  /// No description provided for @deleteListConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its items?'**
  String deleteListConfirm(String name);

  /// No description provided for @signInToPlan.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create shopping lists'**
  String get signInToPlan;

  /// No description provided for @plannerSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Save products, track your grocery budget, and compare your planned shopping trip.'**
  String get plannerSignInMessage;

  /// No description provided for @plannerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Planner unavailable'**
  String get plannerUnavailable;

  /// No description provided for @startWithBasket.
  ///
  /// In en, this message translates to:
  /// **'Start with a basket'**
  String get startWithBasket;

  /// No description provided for @reviewedWeeklyEssentials.
  ///
  /// In en, this message translates to:
  /// **'Reviewed weekly essentials with real current estimates.'**
  String get reviewedWeeklyEssentials;

  /// No description provided for @yourShoppingLists.
  ///
  /// In en, this message translates to:
  /// **'Your shopping lists'**
  String get yourShoppingLists;

  /// No description provided for @noShoppingListsYet.
  ///
  /// In en, this message translates to:
  /// **'No shopping lists yet'**
  String get noShoppingListsYet;

  /// No description provided for @startPlanningMessage.
  ///
  /// In en, this message translates to:
  /// **'Start planning groceries and track the estimated total.'**
  String get startPlanningMessage;

  /// No description provided for @createYourFirstList.
  ///
  /// In en, this message translates to:
  /// **'Create your first list'**
  String get createYourFirstList;

  /// No description provided for @templateItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String templateItemsCount(int count);

  /// No description provided for @templateUnavailableCount.
  ///
  /// In en, this message translates to:
  /// **' â€¢ {count} unavailable'**
  String templateUnavailableCount(int count);

  /// No description provided for @shoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingListTitle;

  /// No description provided for @myList.
  ///
  /// In en, this message translates to:
  /// **'My list'**
  String get myList;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed} other{{count} completed}}'**
  String completedItemsCount(int count);

  /// No description provided for @renameListDialog.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get renameListDialog;

  /// No description provided for @removeItemQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get removeItemQuestion;

  /// No description provided for @removeItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this list?'**
  String removeItemConfirm(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @shoppingListNotFound.
  ///
  /// In en, this message translates to:
  /// **'Shopping list not found.'**
  String get shoppingListNotFound;

  /// No description provided for @listDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted by you or another device.'**
  String get listDeletedMessage;

  /// No description provided for @backToPlanner.
  ///
  /// In en, this message translates to:
  /// **'Back to planner'**
  String get backToPlanner;

  /// No description provided for @couldntLoadList.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this shopping list.'**
  String get couldntLoadList;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @yourListIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get yourListIsEmpty;

  /// No description provided for @emptyListMessage.
  ///
  /// In en, this message translates to:
  /// **'Add items to start planning your trip.'**
  String get emptyListMessage;

  /// No description provided for @everythingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Everything is completed'**
  String get everythingCompleted;

  /// No description provided for @noCompletedYet.
  ///
  /// In en, this message translates to:
  /// **'No completed items yet'**
  String get noCompletedYet;

  /// No description provided for @completedHint.
  ///
  /// In en, this message translates to:
  /// **'Open Completed to review checked items.'**
  String get completedHint;

  /// No description provided for @completedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Items you check off will appear here.'**
  String get completedEmptyHint;

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get estimatedTotal;

  /// No description provided for @noBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No monthly budget set'**
  String get noBudgetSet;

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'RM {amount} over budget'**
  String overBudget(String amount);

  /// No description provided for @withinBudget.
  ///
  /// In en, this message translates to:
  /// **'RM {amount} within budget'**
  String withinBudget(String amount);

  /// No description provided for @findBestPlaces.
  ///
  /// In en, this message translates to:
  /// **'Find best places'**
  String get findBestPlaces;

  /// No description provided for @profileGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String profileGreeting(String name);

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare smarter and save more.'**
  String get profileSubtitle;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @budgetPlanner.
  ///
  /// In en, this message translates to:
  /// **'Budget Planner'**
  String get budgetPlanner;

  /// No description provided for @myFavourites.
  ///
  /// In en, this message translates to:
  /// **'My Favourites'**
  String get myFavourites;

  /// No description provided for @recentViews.
  ///
  /// In en, this message translates to:
  /// **'Recent views'**
  String get recentViews;

  /// No description provided for @recentViewsMenu.
  ///
  /// In en, this message translates to:
  /// **'Recent Views'**
  String get recentViewsMenu;

  /// No description provided for @shoppingLists.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get shoppingLists;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @aboutJimatmy.
  ///
  /// In en, this message translates to:
  /// **'About JimatMY'**
  String get aboutJimatmy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutQuestion;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Your saved account data will remain available the next time you log in.'**
  String get logoutMessage;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get changeProfilePicture;

  /// No description provided for @guestTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your shopping plans'**
  String get guestTitle;

  /// No description provided for @guestMessage.
  ///
  /// In en, this message translates to:
  /// **'Log in to keep favourites, recent items, shopping lists and your monthly budget together.'**
  String get guestMessage;

  /// No description provided for @countUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Count unavailable. Pull down to retry.'**
  String get countUnavailable;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email to receive a six-digit reset code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @registeredEmail.
  ///
  /// In en, this message translates to:
  /// **'Registered email'**
  String get registeredEmail;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get sendResetCode;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit code sent to your email and choose a new password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Please log in.'**
  String get passwordResetSuccess;

  /// No description provided for @invalidResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit code.'**
  String get invalidResetCode;

  /// No description provided for @resetCodeGenericError.
  ///
  /// In en, this message translates to:
  /// **'That reset code is invalid or has expired.'**
  String get resetCodeGenericError;
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
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
