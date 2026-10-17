// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Compare prices. Save every day.';

  @override
  String get splashConnecting => 'Connecting to PriceCatcher dataâ€¦';

  @override
  String get splashErrorTitle => 'We could not connect';

  @override
  String get splashErrorMessage =>
      'Price data is temporarily unavailable. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navPlanner => 'Planner';

  @override
  String get navNearby => 'Nearby';

  @override
  String get navProfile => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLocationSection => 'Location';

  @override
  String get settingsSelectedArea => 'Selected area';

  @override
  String get settingsUseDeviceLocation => 'Use device location';

  @override
  String get settingsPermissionActive =>
      'Location permission is active for this session.';

  @override
  String get settingsPermissionRequested =>
      'Requested only when you choose to enable it.';

  @override
  String get settingsLocationEnabled => 'Location enabled.';

  @override
  String get settingsLocationFailed =>
      'Location could not be enabled. You can choose an area manually.';

  @override
  String get settingsAppInfoSection => 'App information';

  @override
  String get settingsVersion => 'Version 1.0.0';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Choose the language shown in the app.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get languageChinese => 'ä¸­æ–‡';

  @override
  String get priceUnavailable => 'Price unavailable';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get noCurrentPremise => 'No current premise';

  @override
  String get priceComparison => 'Price Comparison';

  @override
  String get priceTrend => 'Price Trend';

  @override
  String get itemDetailTitle => 'Item details';

  @override
  String get detailsUnavailable => 'Details unavailable';

  @override
  String get itemLoadFailed => 'The item could not be loaded.';

  @override
  String get dailyPrice => 'Daily price';

  @override
  String get summaryLowest => 'Lowest';

  @override
  String get summaryPremises => 'Premises';

  @override
  String get summaryAverage => 'Average';

  @override
  String get latestPrices => 'Latest prices';

  @override
  String get latestPricesSubtitle =>
      'Most recent imported price at each premise';

  @override
  String get noPricesYet => 'No prices yet';

  @override
  String get noPricesMessage =>
      'No imported premise prices are available for this item.';

  @override
  String get addToFavourites => 'Add to favourites';

  @override
  String get removeFromFavourites => 'Remove from favourites';

  @override
  String get notNow => 'Not now';

  @override
  String get login => 'Log in';

  @override
  String get cancel => 'Cancel';

  @override
  String get homeSearchHint => 'Search chicken, rice, milk...';

  @override
  String get homeSearchSemantics => 'Open grocery search';

  @override
  String get homeSearchNoResults => 'No matching items';

  @override
  String get homeChooseLocation => 'Choose your location';

  @override
  String get homeSelectLocation => 'Select location';

  @override
  String get homeLowestPricesTitle => 'Lowest Prices Today';

  @override
  String get homePopularCategories => 'Popular Categories';

  @override
  String get homeWeeklyBasketTitle => 'Start with a weekly basket';

  @override
  String get homeWeeklyBasketSubtitle =>
      'Real PriceCatcher estimates for students, couples and families.';

  @override
  String get homeNoPrices => 'Current featured prices are unavailable.';

  @override
  String homeBasketIntro(String household) {
    return 'A one-week basket for $household. Quantities remain editable.';
  }

  @override
  String homeCreateBasket(String total) {
    return 'Create basket Â· RM $total';
  }

  @override
  String get homeBasketCreateFailed => 'Basket could not be created.';

  @override
  String get homeInsightTitle => 'JimatMY Insight';

  @override
  String get homeInsightStable => 'remained stable';

  @override
  String homeInsightDecreased(String percent) {
    return 'decreased $percent%';
  }

  @override
  String homeInsightIncreased(String percent) {
    return 'increased $percent%';
  }

  @override
  String get homeCategoryFreshFood => 'Fresh Food';

  @override
  String get homeCategoryVegetables => 'Vegetables';

  @override
  String get homeCategoryFruits => 'Fruits';

  @override
  String get homeCategoryEggs => 'Eggs';

  @override
  String get homeCategoryDrinks => 'Drinks';

  @override
  String get homeCategoryDryGoods => 'Dry Goods';

  @override
  String get homeCategoryBaby => 'Baby Products';

  @override
  String get homeCategoryHousehold => 'Household';

  @override
  String get homeQuickCompare => 'Price Comparison';

  @override
  String get homeQuickPlanner => 'Shopping Planner';

  @override
  String get homeQuickTrends => 'Price Trends';

  @override
  String homeInsightSentence(String itemName, String direction) {
    return '$itemName prices $direction.';
  }

  @override
  String get homeQuickNearby => 'Nearby Stores';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get createAccount => 'Create an account';

  @override
  String get createAccountShort => 'Create account';

  @override
  String get passwordRequirementLength => 'At least 10 characters';

  @override
  String get passwordRequirementUpper => 'An uppercase letter (A-Z)';

  @override
  String get passwordRequirementLower => 'A lowercase letter (a-z)';

  @override
  String get passwordRequirementNumber => 'A number (0-9)';

  @override
  String get passwordStrong => 'Strong password';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginSubtitle =>
      'Log in to continue planning smarter grocery trips.';

  @override
  String get registerTitle => 'Create your JimatMY account';

  @override
  String get registerSubtitle =>
      'Save favourites, shopping lists, and your monthly budget.';

  @override
  String get passwordHelper =>
      '10+ characters with uppercase, lowercase, and a number.';

  @override
  String get enterName => 'Enter at least 2 characters.';

  @override
  String get weakPassword => 'Use a stronger password.';

  @override
  String get passwordsMismatch => 'Passwords do not match.';

  @override
  String get backToLogin => 'Back to Log in';

  @override
  String get priceComparisonTitle => 'Price comparison';

  @override
  String get state => 'State';

  @override
  String get pricesUnavailable => 'Prices unavailable';

  @override
  String get noPricesFound => 'No prices found';

  @override
  String get noPricesMatchFilters =>
      'No current premise prices match these filters.';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String premisePricesCount(int count) {
    return '$count premise prices';
  }

  @override
  String get allStates => 'All states';

  @override
  String get allDistricts => 'All districts';

  @override
  String get district => 'District';

  @override
  String get addToPlanner => 'Add to Planner';

  @override
  String get loginToUsePlanner => 'Log in to use Planner';

  @override
  String get plannerSaveNote =>
      'Save this item to a shopping list after logging in.';

  @override
  String get createListFirst => 'Create a shopping list first';

  @override
  String get plannerNeedsList =>
      'Planner needs a shopping list before this item can be added.';

  @override
  String get openPlanner => 'Open Planner';

  @override
  String get chooseShoppingList => 'Choose a shopping list';

  @override
  String get addedToShoppingList => 'Added to your shopping list';

  @override
  String get priceTrendTitle => 'Price trend';

  @override
  String get trendUnavailable => 'Trend unavailable';

  @override
  String get noTrendData => 'No trend data';

  @override
  String get noTrendMessage => 'No daily prices are available for this period.';

  @override
  String get moreHistoryTitle => 'More history needed';

  @override
  String get moreHistoryMessage =>
      'At least two daily prices are needed to show a trend.';

  @override
  String get searchTitle => 'Search items';

  @override
  String get browseItems => 'Browse items';

  @override
  String get results => 'Results';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filterItems => 'Filter items';

  @override
  String get pricesAvailable => 'Prices available';

  @override
  String get itemsUnavailable => 'Items unavailable';

  @override
  String get noGroceries => 'No groceries available';

  @override
  String get noMatchingGroceries => 'No matching groceries';

  @override
  String get searchEmptyMessage => 'Try another search or reset your filters.';

  @override
  String get loadMore => 'Load more';

  @override
  String get category => 'Category';

  @override
  String get locationFiltersUnavailable =>
      'Location filters are temporarily unavailable.';

  @override
  String get hasAvailablePricesTitle => 'Has available prices';

  @override
  String get hasAvailablePricesSubtitle =>
      'Only show items priced by a premise';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String openShoppingList(String name) {
    return 'Open $name';
  }

  @override
  String get searchAll => 'All';

  @override
  String get searchChicken => 'Chicken';

  @override
  String get searchMeat => 'Meat';

  @override
  String get searchEggs => 'Eggs';

  @override
  String get searchVegetables => 'Vegetables';

  @override
  String get searchFruits => 'Fruits';

  @override
  String get searchDrinks => 'Drinks';

  @override
  String get searchDryGoods => 'Dry Goods';

  @override
  String get searchBaby => 'Baby';

  @override
  String get searchHousehold => 'Household';

  @override
  String get plannerTitle => 'Shopping planner';

  @override
  String get createShoppingList => 'Create shopping list';

  @override
  String get listName => 'List name';

  @override
  String get createListShort => 'Create list';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String weeklyBasketSubtitle(String household) {
    return '$household â€¢ weekly basket';
  }

  @override
  String createListWithTotal(String total) {
    return 'Create list â€¢ RM $total';
  }

  @override
  String get basketCreateFailed => 'The basket could not be created.';

  @override
  String get setMonthlyBudget => 'Set monthly budget';

  @override
  String get editMonthlyBudget => 'Edit monthly budget';

  @override
  String get budgetAmountLabel => 'Amount (RM)';

  @override
  String get enterPositiveAmount => 'Enter a positive RM amount.';

  @override
  String get enterListName => 'Enter a list name.';

  @override
  String get renameShoppingList => 'Rename shopping list';

  @override
  String get deleteShoppingListQuestion => 'Delete shopping list?';

  @override
  String deleteListConfirm(String name) {
    return 'Delete \"$name\" and all its items?';
  }

  @override
  String get signInToPlan => 'Sign in to create shopping lists';

  @override
  String get plannerSignInMessage =>
      'Save products, track your grocery budget, and compare your planned shopping trip.';

  @override
  String get plannerUnavailable => 'Planner unavailable';

  @override
  String get startWithBasket => 'Start with a basket';

  @override
  String get reviewedWeeklyEssentials =>
      'Reviewed weekly essentials with real current estimates.';

  @override
  String get yourShoppingLists => 'Your shopping lists';

  @override
  String get noShoppingListsYet => 'No shopping lists yet';

  @override
  String get startPlanningMessage =>
      'Start planning groceries and track the estimated total.';

  @override
  String get createYourFirstList => 'Create your first list';

  @override
  String templateItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String templateUnavailableCount(int count) {
    return ' â€¢ $count unavailable';
  }

  @override
  String get shoppingListTitle => 'Shopping list';

  @override
  String get myList => 'My list';

  @override
  String get completed => 'Completed';

  @override
  String completedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed',
      one: '1 completed',
    );
    return '$_temp0';
  }

  @override
  String get renameListDialog => 'Rename list';

  @override
  String get removeItemQuestion => 'Remove item?';

  @override
  String removeItemConfirm(String name) {
    return 'Remove $name from this list?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get shoppingListNotFound => 'Shopping list not found.';

  @override
  String get listDeletedMessage =>
      'It may have been deleted by you or another device.';

  @override
  String get backToPlanner => 'Back to planner';

  @override
  String get couldntLoadList => 'Couldn\'t load this shopping list.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get addItem => 'Add item';

  @override
  String get yourListIsEmpty => 'Your list is empty';

  @override
  String get emptyListMessage => 'Add items to start planning your trip.';

  @override
  String get everythingCompleted => 'Everything is completed';

  @override
  String get noCompletedYet => 'No completed items yet';

  @override
  String get completedHint => 'Open Completed to review checked items.';

  @override
  String get completedEmptyHint => 'Items you check off will appear here.';

  @override
  String get estimatedTotal => 'Estimated total';

  @override
  String get noBudgetSet => 'No monthly budget set';

  @override
  String overBudget(String amount) {
    return 'RM $amount over budget';
  }

  @override
  String withinBudget(String amount) {
    return 'RM $amount within budget';
  }

  @override
  String get findBestPlaces => 'Find best places';

  @override
  String profileGreeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get profileSubtitle => 'Compare smarter and save more.';

  @override
  String get myProfile => 'My Profile';

  @override
  String get budgetPlanner => 'Budget Planner';

  @override
  String get myFavourites => 'My Favourites';

  @override
  String get recentViews => 'Recent views';

  @override
  String get recentViewsMenu => 'Recent Views';

  @override
  String get shoppingLists => 'Shopping lists';

  @override
  String get settings => 'Settings';

  @override
  String get aboutJimatmy => 'About JimatMY';

  @override
  String get logout => 'Log out';

  @override
  String get logoutQuestion => 'Log out?';

  @override
  String get logoutMessage =>
      'Your saved account data will remain available the next time you log in.';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get openSettings => 'Open settings';

  @override
  String get changeProfilePicture => 'Change profile picture';

  @override
  String get guestTitle => 'Save your shopping plans';

  @override
  String get guestMessage =>
      'Log in to keep favourites, recent items, shopping lists and your monthly budget together.';

  @override
  String get countUnavailable => 'Count unavailable. Pull down to retry.';

  @override
  String get favourites => 'Favourites';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your registered email to receive a six-digit reset code.';

  @override
  String get registeredEmail => 'Registered email';

  @override
  String get sendResetCode => 'Send reset code';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the six-digit code sent to your email and choose a new password.';

  @override
  String get resetCode => 'Reset code';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get passwordResetSuccess => 'Password reset. Please log in.';

  @override
  String get invalidResetCode => 'Enter the six-digit code.';

  @override
  String get resetCodeGenericError =>
      'That reset code is invalid or has expired.';
}
