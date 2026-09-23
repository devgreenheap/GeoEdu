<?php

use App\Http\Controllers\CategoryController;
use App\Http\Controllers\CategoryModuleController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\CouponController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FirebaseAudioRoomController;
use App\Http\Controllers\FirebaseChatController;
use App\Http\Controllers\FirebasePkBattleController;
use App\Http\Controllers\HashtagController;
use App\Http\Controllers\InterestController;
use App\Http\Controllers\LanguageController;
use App\Http\Controllers\LiveStreamController;
use App\Http\Controllers\LoginController;
use App\Http\Controllers\MusicController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\PostsController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\RestrictionsController;
use App\Http\Controllers\SettingsController;
use App\Http\Controllers\ShareLinkController;
use App\Http\Controllers\ShopCategoryController;
use App\Http\Controllers\StoryController;
use App\Http\Controllers\SupportController;
use App\Http\Controllers\TopicController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Response;
use Illuminate\Support\Facades\Route;
/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/linkstorage', function () {
    Artisan::call('storage:link');
});

// Public website (admin-manageable content)
Route::get('/', [App\Http\Controllers\WebsiteController::class, 'home'])->name('home');
Route::get('about-us', [App\Http\Controllers\WebsiteController::class, 'about'])->name('about_us');
Route::get('contact-us', [App\Http\Controllers\WebsiteController::class, 'contact'])->name('contact_us');

// Admin login entry point
Route::get('/admin', [LoginController::class, 'login'])->name('admin');
Route::post('loginForm', [LoginController::class, 'checkLogin'])->name('loginForm');
Route::get('logout', [LoginController::class, 'logout'])->middleware(['checkLogin'])->name('logout');

Route::post('forgotPasswordForm', [LoginController::class, 'forgotPasswordForm'])->name('forgotPasswordForm');

Route::get('privacy_policy', [SettingsController::class, 'privacy_policy'])->name('privacy_policy');
Route::get('terms_of_uses', [SettingsController::class, 'terms_of_uses'])->name('terms_of_uses');

// Test
Route::get('testingRoute', [SettingsController::class, 'testingRoute'])->name('testingRoute');

// Deeplink
Route::get('s/{encryptedId}', [ShareLinkController::class, 'encryptedId'])->name('encryptedId');

Route::get('/.well-known/apple-app-site-association', function () {
    $file = public_path('assets/apple-app-site-association');
    if (!File::exists($file)) {
        abort(404, 'File not found');
    }

    return Response::file($file, [
        'Content-Type' => 'application/json', // Force JSON
        'Cache-Control' => 'no-cache, no-store, must-revalidate',
        'Pragma' => 'no-cache',
        'Expires' => '0',
    ]);
});

Route::get('/.well-known/assetlinks.json', function () {
    $file = public_path('assets/assetlinks.json');
    if (!File::exists($file)) {
        abort(404, 'File not found');
    }

    return Response::file($file, [
        'Content-Type' => 'application/json', // Force JSON
        'Cache-Control' => 'no-cache, no-store, must-revalidate',
        'Pragma' => 'no-cache',
        'Expires' => '0',
    ]);
});

Route::middleware(['checkLogin'])->group(function () {
    // Dashboard
    Route::get('dashboard', [DashboardController::class, 'dashboard'])->name('dashboard');
    Route::post('fetchChartData', [DashboardController::class, 'fetchChartData'])->name('fetchChartData');

    // Settings
    Route::get('setting', [SettingsController::class, 'settings'])->name('setting');
    Route::get('levelDetails', [SettingsController::class, 'levelDetails'])->name('levelDetails');
    Route::get('levels', [SettingsController::class, 'levels'])->name('levels');
    Route::get('xpPointsSettings', [SettingsController::class, 'xpPointsSettings'])->name('xpPointsSettings');
    Route::get('agentSettings', [SettingsController::class, 'agentSettings'])->name('agentSettings');
    Route::get('levelBadges', [SettingsController::class, 'levelBadges'])->name('levelBadges');
    Route::post('saveSettings', [SettingsController::class, 'saveSettings'])->name('saveSettings');
    Route::post('saveXpPointsSettings', [SettingsController::class, 'saveXpPointsSettings'])->name('saveXpPointsSettings');
    Route::post('saveAgentSettings', [SettingsController::class, 'saveAgentSettings'])->name('saveAgentSettings');

    Route::post('saveContentModerationSettings', [SettingsController::class, 'saveContentModerationSettings'])->name('saveContentModerationSettings');
    Route::post('saveGIFSettings', [SettingsController::class, 'saveGIFSettings'])->name('saveGIFSettings');
    Route::post('saveDeepARSettings', [SettingsController::class, 'saveDeepARSettings'])->name('saveDeepARSettings');
    Route::post('saveBasicSettings', [SettingsController::class, 'saveBasicSettings'])->name('saveBasicSettings');
    Route::post('saveLimitSettings', [SettingsController::class, 'saveLimitSettings'])->name('saveLimitSettings');
    Route::post('saveLiveStreamSettings', [SettingsController::class, 'saveLiveStreamSettings'])->name('saveLiveStreamSettings');
    Route::post('saveDeeplinkSettings', [SettingsController::class, 'saveDeeplinkSettings'])->name('saveDeeplinkSettings');
    Route::post('androidDeepLinking', [SettingsController::class, 'androidDeepLinking'])->name('androidDeepLinking');
    Route::post('iOSDeepLinking', [SettingsController::class, 'iOSDeepLinking'])->name('iOSDeepLinking');

    Route::post('changePassword', [SettingsController::class, 'changePassword'])->name('changePassword');
    Route::post('updatePrivacyAndTerms', [SettingsController::class, 'updatePrivacyAndTerms'])->name('updatePrivacyAndTerms');

    // Website (public site) content management
    Route::get('websitePages', [App\Http\Controllers\WebsiteContentController::class, 'index'])->name('websitePages');
    Route::post('saveHomeContent', [App\Http\Controllers\WebsiteContentController::class, 'saveHomeContent'])->name('saveHomeContent');
    Route::post('saveAboutContent', [App\Http\Controllers\WebsiteContentController::class, 'saveAboutContent'])->name('saveAboutContent');
    Route::post('saveContactContent', [App\Http\Controllers\WebsiteContentController::class, 'saveContactContent'])->name('saveContactContent');
    Route::post('listHomeFeatures', [App\Http\Controllers\WebsiteContentController::class, 'listFeatures'])->name('listHomeFeatures');
    Route::post('addHomeFeature', [App\Http\Controllers\WebsiteContentController::class, 'addFeature'])->name('addHomeFeature');
    Route::post('editHomeFeature', [App\Http\Controllers\WebsiteContentController::class, 'editFeature'])->name('editHomeFeature');
    Route::post('deleteHomeFeature', [App\Http\Controllers\WebsiteContentController::class, 'deleteFeature'])->name('deleteHomeFeature');
    Route::post('listHomeScreenshots', [App\Http\Controllers\WebsiteContentController::class, 'listScreenshots'])->name('listHomeScreenshots');
    Route::post('addHomeScreenshot', [App\Http\Controllers\WebsiteContentController::class, 'addScreenshot'])->name('addHomeScreenshot');
    Route::post('deleteHomeScreenshot', [App\Http\Controllers\WebsiteContentController::class, 'deleteScreenshot'])->name('deleteHomeScreenshot');

    Route::post('imageUploadInEditor', [SettingsController::class, 'imageUploadInEditor'])->name('imageUploadInEditor');

    // Onboarding Screens
    Route::post('addOnBoardingScreen', [SettingsController::class, 'addOnBoardingScreen'])->name('addOnBoardingScreen');
    Route::post('onboardingScreensList', [SettingsController::class, 'onboardingScreensList'])->name('onboardingScreensList');
    Route::post('deleteOnboardingScreen', [SettingsController::class, 'deleteOnboardingScreen'])->name('deleteOnboardingScreen');
    Route::post('updateOnboardingScreen', [SettingsController::class, 'updateOnboardingScreen'])->name('updateOnboardingScreen');
    Route::post('updateOnboardingOrder', [SettingsController::class, 'updateOnboardingOrder'])->name('updateOnboardingOrder');

    // Report Reason & Withdrawal Gateways & User Level

    Route::post('addDeepARFilter', [SettingsController::class, 'addDeepARFilter'])->name('addDeepARFilter');
    Route::post('listDeepARFilters', [SettingsController::class, 'listDeepARFilters'])->name('listDeepARFilters');
    Route::post('deleteDeepARFilter', [SettingsController::class, 'deleteDeepARFilter'])->name('deleteDeepARFilter');
    Route::post('editDeepARFilter', [SettingsController::class, 'editDeepARFilter'])->name('editDeepARFilter');

    Route::post('addReportReason', [SettingsController::class, 'addReportReason'])->name('addReportReason');
    Route::post('listReportReasons', [SettingsController::class, 'listReportReasons'])->name('listReportReasons');
    Route::post('editReportReason', [SettingsController::class, 'editReportReason'])->name('editReportReason');
    Route::post('deleteReportReason', [SettingsController::class, 'deleteReportReason'])->name('deleteReportReason');

    Route::post('deleteWithdrawalGateway', [SettingsController::class, 'deleteWithdrawalGateway'])->name('deleteWithdrawalGateway');
    Route::post('listWithdrawalGateways', [SettingsController::class, 'listWithdrawalGateways'])->name('listWithdrawalGateways');
    Route::post('editWithdrawalGateway', [SettingsController::class, 'editWithdrawalGateway'])->name('editWithdrawalGateway');
    Route::post('addWithdrawalGateway', [SettingsController::class, 'addWithdrawalGateway'])->name('addWithdrawalGateway');

    Route::post('listUserLevels', [SettingsController::class, 'listUserLevels'])->name('listUserLevels');
    Route::post('addUserLevel', [SettingsController::class, 'addUserLevel'])->name('addUserLevel');
    Route::post('deleteUserLevel', [SettingsController::class, 'deleteUserLevel'])->name('deleteUserLevel');
    Route::post('editUserLevel', [SettingsController::class, 'editUserLevel'])->name('editUserLevel');
    Route::post('listLevelBadges', [SettingsController::class, 'listLevelBadges'])->name('listLevelBadges');
    Route::post('addLevelBadge', [SettingsController::class, 'addLevelBadge'])->name('addLevelBadge');
    Route::post('deleteLevelBadge', [SettingsController::class, 'deleteLevelBadge'])->name('deleteLevelBadge');
    Route::post('editLevelBadge', [SettingsController::class, 'editLevelBadge'])->name('editLevelBadge');

    // Users
    Route::get('users', [UserController::class, 'users'])->name('users');
    Route::post('listAllUsers', [UserController::class, 'listAllUsers'])->name('listAllUsers');
    Route::post('searchUsersForFilter', [UserController::class, 'searchUsersForFilter'])->name('searchUsersForFilter');
    Route::post('listAllModerators', [UserController::class, 'listAllModerators'])->name('listAllModerators');
    Route::get('stateAgentMappings', [UserController::class, 'stateAgentMappings'])->name('stateAgentMappings');
    Route::post('listStateAgentMappings', [UserController::class, 'listStateAgentMappings'])->name('listStateAgentMappings');
    Route::post('saveStateAgentMapping', [UserController::class, 'saveStateAgentMapping'])->name('saveStateAgentMapping');
    Route::get('screenshotDisableRequests', [UserController::class, 'screenshotDisableRequests'])->name('screenshotDisableRequests');
    Route::post('listScreenshotDisableRequests', [UserController::class, 'listScreenshotDisableRequests'])->name('listScreenshotDisableRequests');
    Route::post('approveScreenshotDisableRequest', [UserController::class, 'approveScreenshotDisableRequest'])->name('approveScreenshotDisableRequest');
    Route::post('userFreezeUnfreeze', [UserController::class, 'userFreezeUnfreeze'])->name('userFreezeUnfreeze');

    Route::get('viewUserDetails/{id}', [UserController::class, 'viewUserDetails'])->name('viewUserDetails');
    Route::post('deleteUserLink_Admin', [UserController::class, 'deleteUserLink_Admin'])->name('deleteUserLink_Admin');
    Route::post('changeUserModeratorStatus', [UserController::class, 'changeUserModeratorStatus'])->name('changeUserModeratorStatus');
    Route::post('listUserPosts', [PostsController::class, 'listUserPosts'])->name('listUserPosts');
    Route::post('listUserStories', [StoryController::class, 'listUserStories'])->name('listUserStories');
    Route::post('deleteStory_Admin', [StoryController::class, 'deleteStory_Admin'])->name('deleteStory_Admin');
    Route::post('deletePost_Admin', [PostsController::class, 'deletePost_Admin'])->name('deletePost_Admin');
    Route::get('editUser/{id}', [UserController::class, 'editUser'])->name('editUser');
    Route::post('updateUser', [UserController::class, 'updateUser'])->name('updateUser');
    Route::post('addCoinsToUserWallet_FromAdmin', [WalletController::class, 'addCoinsToUserWallet_FromAdmin'])->name('addCoinsToUserWallet_FromAdmin');
    Route::post('addDiamondsToUserWallet_FromAdmin', [WalletController::class, 'addDiamondsToUserWallet_FromAdmin'])->name('addDiamondsToUserWallet_FromAdmin');

    Route::get('createDummyUser', [UserController::class, 'createDummyUser'])->name('createDummyUser');
    Route::post('addDummyUser', [UserController::class, 'addDummyUser'])->name('addDummyUser');
    Route::post('updateDummyUser', [UserController::class, 'updateUser'])->name('updateDummyUser');
    Route::post('listDummyUsers', [UserController::class, 'listDummyUsers'])->name('listDummyUsers');
    Route::get('editDummyUser/{id}', [UserController::class, 'editDummyUser'])->name('editDummyUser');
    Route::post('deleteDummyUser', [UserController::class, 'deleteDummyUser'])->name('deleteDummyUser');

    // Music
    Route::get('music', [MusicController::class, 'music'])->name('music');
    Route::post('addMusicCategory', [MusicController::class, 'addMusicCategory'])->name('addMusicCategory');
    Route::post('listMusicCategories', [MusicController::class, 'listMusicCategories'])->name('listMusicCategories');
    Route::post('deleteMusicCategory', [MusicController::class, 'deleteMusicCategory'])->name('deleteMusicCategory');
    Route::post('editMusicCategory', [MusicController::class, 'editMusicCategory'])->name('editMusicCategory');
    Route::post('addMusic', [MusicController::class, 'addMusic'])->name('addMusic');
    Route::post('listMusics', [MusicController::class, 'listMusics'])->name('listMusics');
    Route::post('editMusic', [MusicController::class, 'editMusic'])->name('editMusic');
    Route::post('deleteMusic', [MusicController::class, 'deleteMusic'])->name('deleteMusic');

    // Categories
    Route::get('categoryDetails', [CategoryModuleController::class, 'categoryDetails'])->name('categoryDetails');
    Route::get('categories', [CategoryModuleController::class, 'categories'])->name('categories');
    Route::post('listCategories', [CategoryModuleController::class, 'listCategories'])->name('listCategories');
    Route::post('addCategory', [CategoryModuleController::class, 'addCategory'])->name('addCategory');
    Route::post('editCategory', [CategoryModuleController::class, 'editCategory'])->name('editCategory');
    Route::post('deleteCategory', [CategoryModuleController::class, 'deleteCategory'])->name('deleteCategory');
    Route::post('changeCategoryStatus', [CategoryModuleController::class, 'changeCategoryStatus'])->name('changeCategoryStatus');
    Route::post('listSubCategories', [CategoryModuleController::class, 'listSubCategories'])->name('listSubCategories');
    Route::post('addSubCategory', [CategoryModuleController::class, 'addSubCategory'])->name('addSubCategory');
    Route::post('editSubCategory', [CategoryModuleController::class, 'editSubCategory'])->name('editSubCategory');
    Route::post('deleteSubCategory', [CategoryModuleController::class, 'deleteSubCategory'])->name('deleteSubCategory');
    Route::post('changeSubCategoryStatus', [CategoryModuleController::class, 'changeSubCategoryStatus'])->name('changeSubCategoryStatus');
    Route::get('countries', [CategoryModuleController::class, 'countries'])->name('countries');
    Route::post('listCountries', [CategoryModuleController::class, 'listCountries'])->name('listCountries');
    Route::post('addCountry', [CategoryModuleController::class, 'addCountry'])->name('addCountry');
    Route::post('editCountry', [CategoryModuleController::class, 'editCountry'])->name('editCountry');
    Route::post('deleteCountry', [CategoryModuleController::class, 'deleteCountry'])->name('deleteCountry');
    Route::get('statesMaster', [CategoryModuleController::class, 'statesMaster'])->name('statesMaster');
    Route::post('listStatesMaster', [CategoryModuleController::class, 'listStatesMaster'])->name('listStatesMaster');
    Route::post('addStateMaster', [CategoryModuleController::class, 'addStateMaster'])->name('addStateMaster');
    Route::post('editStateMaster', [CategoryModuleController::class, 'editStateMaster'])->name('editStateMaster');
    Route::post('deleteStateMaster', [CategoryModuleController::class, 'deleteStateMaster'])->name('deleteStateMaster');

    // Interests
    Route::get('interests', [InterestController::class, 'interests'])->name('interests');
    Route::post('listInterests', [InterestController::class, 'listInterests'])->name('listInterests');
    Route::post('addInterest', [InterestController::class, 'addInterest'])->name('addInterest');
    Route::post('editInterest', [InterestController::class, 'editInterest'])->name('editInterest');
    Route::post('deleteInterest', [InterestController::class, 'deleteInterest'])->name('deleteInterest');
    Route::post('changeInterestStatus', [InterestController::class, 'changeInterestStatus'])->name('changeInterestStatus');

    // Topics
    Route::get('topics', [TopicController::class, 'topics'])->name('topics');
    Route::post('listTopics', [TopicController::class, 'listTopics'])->name('listTopics');
    Route::post('addTopic', [TopicController::class, 'addTopic'])->name('addTopic');
    Route::post('editTopic', [TopicController::class, 'editTopic'])->name('editTopic');
    Route::post('deleteTopic', [TopicController::class, 'deleteTopic'])->name('deleteTopic');
    Route::post('changeTopicStatus', [TopicController::class, 'changeTopicStatus'])->name('changeTopicStatus');
    Route::post('listSubCategoriesByCategory', [TopicController::class, 'listSubCategoriesByCategory'])->name('listSubCategoriesByCategory');

    // withdrawals
    Route::get('withdrawals', [WalletController::class, 'withdrawals'])->name('withdrawals');
    Route::post('listPendingWithdrawals', [WalletController::class, 'listPendingWithdrawals'])->name('listPendingWithdrawals');
    Route::post('listCompletedWithdrawals', [WalletController::class, 'listCompletedWithdrawals'])->name('listCompletedWithdrawals');
    Route::post('listRejectedWithdrawals', [WalletController::class, 'listRejectedWithdrawals'])->name('listRejectedWithdrawals');
    Route::post('completeWithdrawal', [WalletController::class, 'completeWithdrawal'])->name('completeWithdrawal');
    Route::post('rejectWithdrawal', [WalletController::class, 'rejectWithdrawal'])->name('rejectWithdrawal');
    Route::get('manualPayouts', [WalletController::class, 'manualPayouts'])->name('manualPayouts');
    Route::post('listTodayRealUsersPayout', [WalletController::class, 'listTodayRealUsersPayout'])->name('listTodayRealUsersPayout');
    Route::post('listManualPayouts', [WalletController::class, 'listManualPayouts'])->name('listManualPayouts');
    Route::post('addManualPayout', [WalletController::class, 'addManualPayout'])->name('addManualPayout');
    Route::post('listTodayAgentCommissionPayout', [WalletController::class, 'listTodayAgentCommissionPayout'])->name('listTodayAgentCommissionPayout');
    Route::post('listManualAgentPayouts', [WalletController::class, 'listManualAgentPayouts'])->name('listManualAgentPayouts');
    Route::post('addManualAgentPayout', [WalletController::class, 'addManualAgentPayout'])->name('addManualAgentPayout');
    Route::post('listTodayAdminPayout', [WalletController::class, 'listTodayAdminPayout'])->name('listTodayAdminPayout');
    Route::post('listManualAdminPayouts', [WalletController::class, 'listManualAdminPayouts'])->name('listManualAdminPayouts');
    Route::post('addManualAdminPayout', [WalletController::class, 'addManualAdminPayout'])->name('addManualAdminPayout');
    Route::post('listTodayStateAgentPayout', [WalletController::class, 'listTodayStateAgentPayout'])->name('listTodayStateAgentPayout');
    Route::post('listManualStateAgentPayouts', [WalletController::class, 'listManualStateAgentPayouts'])->name('listManualStateAgentPayouts');
    Route::post('addManualStateAgentPayout', [WalletController::class, 'addManualStateAgentPayout'])->name('addManualStateAgentPayout');
    Route::post('listTodayGifterWalletPayout', [WalletController::class, 'listTodayGifterWalletPayout'])->name('listTodayGifterWalletPayout');
    Route::post('listManualGifterWalletPayouts', [WalletController::class, 'listManualGifterWalletPayouts'])->name('listManualGifterWalletPayouts');
    Route::post('addManualGifterWalletPayout', [WalletController::class, 'addManualGifterWalletPayout'])->name('addManualGifterWalletPayout');

    // Diamond Packages
    Route::get('packageDetails', [WalletController::class, 'packageDetails'])->name('packageDetails');
    Route::get('diamondPackages', [WalletController::class, 'diamondPackages'])->name('diamondPackages');
    Route::post('addDiamondPackage', [WalletController::class, 'addDiamondPackage'])->name('addDiamondPackage');
    Route::post('deleteDiamondPackage', [WalletController::class, 'deleteDiamondPackage'])->name('deleteDiamondPackage');
    Route::post('editDiamondPackage', [WalletController::class, 'editDiamondPackage'])->name('editDiamondPackage');
    Route::post('changeDiamondPackageStatus', [WalletController::class, 'changeDiamondPackageStatus'])->name('changeDiamondPackageStatus');
    Route::post('listDiamondPackages', [WalletController::class, 'listDiamondPackages'])->name('listDiamondPackages');
    Route::get('diamondBuyingInformation', [WalletController::class, 'diamondBuyingInformation'])->name('diamondBuyingInformation');
    Route::post('addDiamondBuyingInformation', [WalletController::class, 'addDiamondBuyingInformation'])->name('addDiamondBuyingInformation');
    Route::post('editDiamondBuyingInformation', [WalletController::class, 'editDiamondBuyingInformation'])->name('editDiamondBuyingInformation');
    Route::post('deleteDiamondBuyingInformation', [WalletController::class, 'deleteDiamondBuyingInformation'])->name('deleteDiamondBuyingInformation');
    Route::get('diamondFaqs', [WalletController::class, 'diamondFaqs'])->name('diamondFaqs');
    Route::post('addDiamondFaq', [WalletController::class, 'addDiamondFaq'])->name('addDiamondFaq');
    Route::post('editDiamondFaq', [WalletController::class, 'editDiamondFaq'])->name('editDiamondFaq');
    Route::post('deleteDiamondFaq', [WalletController::class, 'deleteDiamondFaq'])->name('deleteDiamondFaq');
    Route::get('diamondTransactions', [WalletController::class, 'diamondTransactions'])->name('diamondTransactions');
    Route::post('listDiamondTransactions', [WalletController::class, 'listDiamondTransactions'])->name('listDiamondTransactions');
    Route::get('coupons', [CouponController::class, 'coupons'])->name('coupons');
    Route::post('listCoupons', [CouponController::class, 'listCoupons'])->name('listCoupons');
    Route::post('addCoupon', [CouponController::class, 'addCoupon'])->name('addCoupon');
    Route::post('editCoupon', [CouponController::class, 'editCoupon'])->name('editCoupon');
    Route::post('deleteCoupon', [CouponController::class, 'deleteCoupon'])->name('deleteCoupon');
    Route::post('changeCouponStatus', [CouponController::class, 'changeCouponStatus'])->name('changeCouponStatus');
    Route::get('hostAgentRequests', [WalletController::class, 'hostAgentRequests'])->name('hostAgentRequests');
    Route::post('listPendingHostAgentRequests', [WalletController::class, 'listPendingHostAgentRequests'])->name('listPendingHostAgentRequests');
    Route::post('listAcceptedHostAgentRequests', [WalletController::class, 'listAcceptedHostAgentRequests'])->name('listAcceptedHostAgentRequests');
    Route::post('listRejectedHostAgentRequests', [WalletController::class, 'listRejectedHostAgentRequests'])->name('listRejectedHostAgentRequests');
    Route::post('acceptHostAgentRequest', [WalletController::class, 'acceptHostAgentRequest'])->name('acceptHostAgentRequest');
    Route::post('rejectHostAgentRequest', [WalletController::class, 'rejectHostAgentRequest'])->name('rejectHostAgentRequest');

    // Dummy Lives
    Route::get('liveDetails', [LiveStreamController::class, 'liveDetails'])->name('liveDetails');
    Route::get('liveStreams', [LiveStreamController::class, 'liveStreamingList'])->name('liveStreams');
    Route::post('listLiveStreams', [LiveStreamController::class, 'listLiveStreams'])->name('listLiveStreams');
    Route::get('liveStreamActivities/{liveStreamId}', [LiveStreamController::class, 'liveStreamActivities'])->name('liveStreamActivities');
    Route::post('listLiveStreamActivities', [LiveStreamController::class, 'listLiveStreamActivities'])->name('listLiveStreamActivities');
    Route::get('firebaseChats', [FirebaseChatController::class, 'firebaseChats'])->name('firebaseChats');
    Route::post('listFirebaseChats', [FirebaseChatController::class, 'listFirebaseChats'])->name('listFirebaseChats');
    Route::get('firebasePkBattles', [FirebasePkBattleController::class, 'firebasePkBattles'])->name('firebasePkBattles');
    Route::post('listFirebasePkBattles', [FirebasePkBattleController::class, 'listFirebasePkBattles'])->name('listFirebasePkBattles');
    Route::get('firebaseAudioRooms', [FirebaseAudioRoomController::class, 'firebaseAudioRooms'])->name('firebaseAudioRooms');
    Route::post('listFirebaseAudioRooms', [FirebaseAudioRoomController::class, 'listFirebaseAudioRooms'])->name('listFirebaseAudioRooms');
    Route::get('dummyLives', [LiveStreamController::class, 'dummyLives'])->name('dummyLives');
    Route::post('addDummyLive', [LiveStreamController::class, 'addDummyLive'])->name('addDummyLive');
    Route::post('listDummyLives', [LiveStreamController::class, 'listDummyLives'])->name('listDummyLives');
    Route::post('deleteDummyLive', [LiveStreamController::class, 'deleteDummyLive'])->name('deleteDummyLive');
    Route::post('changeDummyLiveStatus', [LiveStreamController::class, 'changeDummyLiveStatus'])->name('changeDummyLiveStatus');
    Route::post('editDummyLive', [LiveStreamController::class, 'editDummyLive'])->name('editDummyLive');

    // restrictions
    Route::get('restrictions', [RestrictionsController::class, 'restrictions'])->name('restrictions');
    Route::post('listUsernameRestrictions', [RestrictionsController::class, 'listUsernameRestrictions'])->name('listUsernameRestrictions');
    Route::post('addUsernameRestriction', [RestrictionsController::class, 'addUsernameRestriction'])->name('addUsernameRestriction');
    Route::post('deleteUsernameRestriction', [RestrictionsController::class, 'deleteUsernameRestriction'])->name('deleteUsernameRestriction');
    Route::post('editUsernameRestriction', [RestrictionsController::class, 'editUsernameRestriction'])->name('editUsernameRestriction');

    // notifications
    Route::get('notifications', [NotificationController::class, 'notifications'])->name('notifications');
    Route::post('listAdminNotifications', [NotificationController::class, 'listAdminNotifications'])->name('listAdminNotifications');
    Route::post('addAdminNotification', [NotificationController::class, 'addAdminNotification'])->name('addAdminNotification');
    Route::post('deleteAdminNotification', [NotificationController::class, 'deleteAdminNotification'])->name('deleteAdminNotification');
    Route::post('editAdminNotification', [NotificationController::class, 'editAdminNotification'])->name('editAdminNotification');
    Route::post('repeatAdminNotification', [NotificationController::class, 'repeatAdminNotification'])->name('repeatAdminNotification');

    // Support
    Route::get('supports', [SupportController::class, 'supports'])->name('supports');
    Route::post('listSupports', [SupportController::class, 'listSupports'])->name('listSupports');
    Route::post('replySupport', [SupportController::class, 'replySupport'])->name('replySupport');
    Route::post('closeSupport', [SupportController::class, 'closeSupport'])->name('closeSupport');
    Route::post('reopenSupport', [SupportController::class, 'reopenSupport'])->name('reopenSupport');

    // Reports
    Route::get('reports', [ReportController::class, 'reports'])->name('reports');
    Route::get('reportRevenueCommission', [ReportController::class, 'reportRevenueCommission'])->name('reportRevenueCommission');
    Route::get('reportPayoutControl', [ReportController::class, 'reportPayoutControl'])->name('reportPayoutControl');
    Route::get('reportLivePerformance', [ReportController::class, 'reportLivePerformance'])->name('reportLivePerformance');
    Route::get('reportUserGrowthQuality', [ReportController::class, 'reportUserGrowthQuality'])->name('reportUserGrowthQuality');
    Route::get('reportGiftAnalytics', [ReportController::class, 'reportGiftAnalytics'])->name('reportGiftAnalytics');
    Route::get('reportAgentStatePerformance', [ReportController::class, 'reportAgentStatePerformance'])->name('reportAgentStatePerformance');
    Route::get('reportModerationRisk', [ReportController::class, 'reportModerationRisk'])->name('reportModerationRisk');
    Route::post('listPostReports', [ReportController::class, 'listPostReports'])->name('listPostReports');
    Route::post('rejectPostReport', [ReportController::class, 'rejectPostReport'])->name('rejectPostReport');
    Route::post('acceptPostReport', [ReportController::class, 'acceptPostReport'])->name('acceptPostReport');
    Route::post('listUserReports', [ReportController::class, 'listUserReports'])->name('listUserReports');
    Route::post('acceptUserReport', [ReportController::class, 'acceptUserReport'])->name('acceptUserReport');
    Route::post('rejectUserReport', [ReportController::class, 'rejectUserReport'])->name('rejectUserReport');
    Route::post('listRevenueCommissionReport', [ReportController::class, 'listRevenueCommissionReport'])->name('listRevenueCommissionReport');
    Route::post('listPayoutControlReport', [ReportController::class, 'listPayoutControlReport'])->name('listPayoutControlReport');
    Route::post('listLivePerformanceReport', [ReportController::class, 'listLivePerformanceReport'])->name('listLivePerformanceReport');
    Route::post('listUserGrowthQualityReport', [ReportController::class, 'listUserGrowthQualityReport'])->name('listUserGrowthQualityReport');
    Route::post('listGiftAnalyticsReport', [ReportController::class, 'listGiftAnalyticsReport'])->name('listGiftAnalyticsReport');
    Route::post('listAgentStatePerformanceReport', [ReportController::class, 'listAgentStatePerformanceReport'])->name('listAgentStatePerformanceReport');
    Route::post('listModerationRiskReport', [ReportController::class, 'listModerationRiskReport'])->name('listModerationRiskReport');

    // posts
    Route::get('posts', [PostsController::class, 'posts'])->name('posts');
    Route::post('listAllPosts', [PostsController::class, 'listAllPosts'])->name('listAllPosts');
    Route::post('listReelPosts', [PostsController::class, 'listReelPosts'])->name('listReelPosts');
    Route::post('listVideoPosts', [PostsController::class, 'listVideoPosts'])->name('listVideoPosts');
    Route::post('listImagePosts', [PostsController::class, 'listImagePosts'])->name('listImagePosts');
    Route::post('listTextPosts', [PostsController::class, 'listTextPosts'])->name('listTextPosts');
    Route::post('fetchFormattedPostDesc', [PostsController::class, 'fetchFormattedPostDesc'])->name('fetchFormattedPostDesc');

    // Post Details
    Route::get('postDetails/{id}', [PostsController::class, 'postDetails'])->name('postDetails');
    Route::post('listPostComments', [CommentController::class, 'listPostComments'])->name('listPostComments');
    Route::post('listCommentReplies', [CommentController::class, 'listCommentReplies'])->name('listCommentReplies');
    Route::post('deleteCommentReply_Admin', [CommentController::class, 'deleteCommentReply_Admin'])->name('deleteCommentReply_Admin');
    Route::post('deleteComment_Admin', [CommentController::class, 'deleteComment_Admin'])->name('deleteComment_Admin');

    // Hashtags
    Route::get('hashtags', [HashtagController::class, 'hashtags'])->name('hashtags');
    Route::post('listAllHashtags', [HashtagController::class, 'listAllHashtags'])->name('listAllHashtags');
    Route::post('addHashtag_Admin', [HashtagController::class, 'addHashtag_Admin'])->name('addHashtag_Admin');
    Route::post('deleteHashtag', [HashtagController::class, 'deleteHashtag'])->name('deleteHashtag');
    // Hashtag Details
    Route::get('hashtagDetails/{hashtag}', [HashtagController::class, 'hashtagDetails'])->name('hashtagDetails');
    Route::post('listHashtagPosts', [PostsController::class, 'listHashtagPosts'])->name('listHashtagPosts');

    // Gifts
    Route::get('giftDetails', [WalletController::class, 'giftDetails'])->name('giftDetails');
    Route::get('gifts', [WalletController::class, 'gifts'])->name('gifts');
    Route::get('giftCategories', [WalletController::class, 'giftCategories'])->name('giftCategories');
    Route::get('banners', [WalletController::class, 'banners'])->name('banners');
    Route::post('addGiftCategory', [WalletController::class, 'addGiftCategory'])->name('addGiftCategory');
    Route::post('editGiftCategory', [WalletController::class, 'editGiftCategory'])->name('editGiftCategory');
    Route::post('deleteGiftCategory', [WalletController::class, 'deleteGiftCategory'])->name('deleteGiftCategory');
    Route::post('addGift', [WalletController::class, 'addGift'])->name('addGift');
    Route::post('editGift', [WalletController::class, 'editGift'])->name('editGift');
    Route::post('deleteGift', [WalletController::class, 'deleteGift'])->name('deleteGift');
    Route::post('addBanner', [WalletController::class, 'addBanner'])->name('addBanner');
    Route::post('editBanner', [WalletController::class, 'editBanner'])->name('editBanner');
    Route::post('deleteBanner', [WalletController::class, 'deleteBanner'])->name('deleteBanner');

    // Entry Effects
    Route::get('entryEffects', [WalletController::class, 'entryEffects'])->name('entryEffects');
    Route::post('addEntryEffect', [WalletController::class, 'addEntryEffect'])->name('addEntryEffect');
    Route::post('editEntryEffect', [WalletController::class, 'editEntryEffect'])->name('editEntryEffect');
    Route::post('deleteEntryEffect', [WalletController::class, 'deleteEntryEffect'])->name('deleteEntryEffect');

    // App Languages
    Route::get('languages', [LanguageController::class, 'languages'])->name('language/index');
    Route::post('languageList', [LanguageController::class, 'languageList'])->name('languageList');
    Route::post('addLanguage', [LanguageController::class, 'addLanguage'])->name('addLanguage');
    Route::post('updateLanguage', [LanguageController::class, 'updateLanguage'])->name('updateLanguage');
    Route::post('deleteLanguage', [LanguageController::class, 'deleteLanguage'])->name('deleteLanguage');
    Route::post('makeDefaultLanguage', [LanguageController::class, 'makeDefaultLanguage'])->name('makeDefaultLanguage');
    Route::post('languageEnableDisable', [LanguageController::class, 'languageEnableDisable'])->name('languageEnableDisable');
    Route::get('edit_csv/{id}', [LanguageController::class, 'edit_csv'])->name('edit_csv');
});
