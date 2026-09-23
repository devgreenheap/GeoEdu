import 'package:geoedu/utilities/const_res.dart';

class WebService {
  static var user = _User();
  static var setting = _Setting();
  static var addPostStory = _AddPostStory();
  static var post = _Post();
  static var google = _Google();
  static var notification = _Notification();
  static var giftWallet = _GiftWallet();
  static var search = _Search();
  static var moderation = _Moderation();
  static var common = _Common();
  static var course = _Course();
}

class _Course {
  String fetchCourses = "${apiURL}course/fetchCourses";
  String fetchCourseDetail = "${apiURL}course/fetchCourseDetail";
  String fetchPopularTrainers = "${apiURL}course/fetchPopularTrainers";
  String enrollCourse = "${apiURL}course/enrollCourse";
  String markLessonComplete = "${apiURL}course/markLessonComplete";
  String rateCourse = "${apiURL}course/rateCourse";
  String fetchMyEnrolledCourses = "${apiURL}course/fetchMyEnrolledCourses";
}

class _Common {
  String ipApi = "http://ip-api.com/json/";
  String fetchBanners = "${apiURL}misc/fetchBanners";
  String createSupport = "${apiURL}misc/createSupport";
  String fetchMySupports = "${apiURL}misc/fetchMySupports";
}

class _Moderation {
  String moderatorDeletePost = "${apiURL}moderator/moderator_deletePost";
  String moderatorUnFreezeUser = "${apiURL}moderator/moderator_unFreezeUser";
  String moderatorFreezeUser = "${apiURL}moderator/moderator_freezeUser";
  String moderatorDeleteStory = "${apiURL}moderator/moderator_deleteStory";
}

class _Notification {
  String fetchAdminNotifications = "${apiURL}misc/fetchAdminNotifications";
  String fetchActivityNotifications = "${apiURL}misc/fetchActivityNotifications";
  String pushNotificationToSingleUser = "${apiURL}misc/pushNotificationToSingleUser";
}

class _GiftWallet {
  String sendGift = "${apiURL}misc/sendGift";
  String fetchMyWithdrawalRequest = "${apiURL}misc/fetchMyWithdrawalRequest";
  String submitWithdrawalRequest = "${apiURL}misc/submitWithdrawalRequest";
  String buyCoins = "${apiURL}misc/buyCoins";
  String fetchDiamondPackages = "${apiURL}misc/fetchDiamondPackages";
  String verifyDiamondPurchase = "${apiURL}misc/verifyDiamondPurchase";
  String fetchDiamondTransactions = "${apiURL}misc/fetchDiamondTransactions";
  String fetchMyDiamondWallet = "${apiURL}misc/fetchMyDiamondWallet";
  String fetchMyDiamondTransactions = "${apiURL}misc/fetchMyDiamondTransactions";
  String fetchMyDiamondSpendHistory = "${apiURL}misc/fetchMyDiamondSpendHistory";
  String spendDiamonds = "${apiURL}misc/spendDiamonds";
  String fetchEntryEffects = "${apiURL}misc/fetchEntryEffects";
  String buyEntryEffect = "${apiURL}misc/buyEntryEffect";
  String fetchMyEntryEffects = "${apiURL}misc/fetchMyEntryEffects";
  String requestBecomeHost = "${apiURL}misc/requestBecomeHost";
  String requestBecomeAgent = "${apiURL}misc/requestBecomeAgent";
  String startLiveStream = "${apiURL}misc/startLiveStream";
  String endLiveStream = "${apiURL}misc/endLiveStream";
  String uploadLiveStreamRecording = "${apiURL}misc/uploadLiveStreamRecording";
  String fetchTopGifters = "${apiURL}misc/fetchTopGifters";
  String fetchTopHosts = "${apiURL}misc/fetchTopHosts";
  String fetchTopPkBattlePlayers = "${apiURL}misc/fetchTopPkBattlePlayers";
  String saveBattleResult = "${apiURL}misc/saveBattleResult";
  String startAudioRoom = "${apiURL}misc/startAudioRoom";
  String endAudioRoom = "${apiURL}misc/endAudioRoom";
  String saveLiveStreamComment = "${apiURL}misc/saveLiveStreamComment";
  String fetchDiamondBuyingInformation = "${apiURL}misc/fetchDiamondBuyingInformation";
  String fetchStarTransactions = "${apiURL}misc/fetchStarTransactions";
  String fetchCoupons = "${apiURL}misc/fetchCoupons";
  String fetchAgentUsers = "${apiURL}misc/fetchAgentUsers";
  String fetchAgentCommission = "${apiURL}misc/fetchAgentCommission";
  String approveHost = "${apiURL}misc/approveHost";
  String fetchMyLives = "${apiURL}misc/fetchMyLives";
  String deleteLiveHistory = "${apiURL}misc/deleteLiveHistory";
  String fetchRecordedLives = "${apiURL}misc/fetchRecordedLives";
  String fetchGiftProfit = "${apiURL}misc/fetchGiftProfit";
  String fetchDiamondFaqs = "${apiURL}misc/fetchDiamondFaqs";
  String requestScreenshotDisable = "${apiURL}misc/requestScreenshotDisable";
  String approveScreenshotDisable = "${apiURL}misc/approveScreenshotDisableRequest";
}

class _User {
  String loginInUser = "${apiURL}user/logInUser";
  String logInFakeUser = "${apiURL}user/logInFakeUser";
  String deleteMyAccount = "${apiURL}user/deleteMyAccount";
  String logOutUser = "${apiURL}user/logOutUser";
  String fetchUserDetails = "${apiURL}user/fetchUserDetails";
  String updateUserDetails = "${apiURL}user/updateUserDetails";
  String checkUsernameAvailability = "${apiURL}user/checkUsernameAvailability";
  String addUserLink = "${apiURL}user/addUserLink";
  String editeUserLink = "${apiURL}user/editeUserLink";
  String deleteUserLink = "${apiURL}user/deleteUserLink";
  String searchUsers = "${apiURL}user/searchUsers";
  String fetchMyFollowers = "${apiURL}user/fetchMyFollowers";
  String fetchUserFollowers = "${apiURL}user/fetchUserFollowers";
  String fetchUserFollowings = "${apiURL}user/fetchUserFollowings";
  String fetchMyFollowings = "${apiURL}user/fetchMyFollowings";
  String followUser = "${apiURL}user/followUser";
  String unFollowUser = "${apiURL}user/unFollowUser";
  String blockUser = "${apiURL}user/blockUser";
  String unBlockUser = "${apiURL}user/unBlockUser";
  String reportUser = "${apiURL}misc/reportUser";
  String fetchMyBlockedUsers = "${apiURL}user/fetchMyBlockedUsers";
  String updateLastUsedAt = "${apiURL}user/updateLastUsedAt";
  String favoriteUser = "${apiURL}user/favoriteUser";
  String fetchMyFavoriteUsers = "${apiURL}user/fetchMyFavoriteUsers";
  String unFavoriteUser = "${apiURL}user/unFavoriteUser";
  String sendSignupOtp = "${apiURL}user/sendSignupOtp";
  String verifySignupOtp = "${apiURL}user/verifySignupOtp";
  String logInWithVerifiedOtp = "${apiURL}user/logInWithVerifiedOtp";
  String fetchMyInterests = "${apiURL}user/fetchMyInterests";
  String updateMyInterests = "${apiURL}user/updateMyInterests";
}

class _AddPostStory {
  String addPostFeedText = "${apiURL}post/addPost_Feed_Text";
  String searchHashtags = "${apiURL}post/searchHashtags";
  String addPostFeedImage = "${apiURL}post/addPost_Feed_Image";
  String addPostFeedVideo = "${apiURL}post/addPost_Feed_Video";
  String addPostReel = "${apiURL}post/addPost_Reel";
}

class _Post {
  String fetchPostsDiscover = "${apiURL}post/fetchPostsDiscover";
  String fetchPostById = "${apiURL}post/fetchPostById";
  String fetchPostsByLocation = "${apiURL}post/fetchPostsByLocation";
  String fetchPostsNearBy = "${apiURL}post/fetchPostsNearBy";
  String fetchPostsFollowing = "${apiURL}post/fetchPostsFollowing";
  String fetchReelPostsByMusic = "${apiURL}post/fetchReelPostsByMusic";
  String fetchUserPosts = "${apiURL}post/fetchUserPosts";
  String fetchPostsByHashtag = "${apiURL}post/fetchPostsByHashtag";
  String fetchSavedPosts = "${apiURL}post/fetchSavedPosts";
  String deletePost = "${apiURL}post/deletePost";
  String increaseShareCount = "${apiURL}post/increaseShareCount";
  String increaseViewsCount = "${apiURL}post/increaseViewsCount";
  String pinPost = "${apiURL}post/pinPost";
  String unpinPost = "${apiURL}post/unpinPost";
  String likePost = "${apiURL}post/likePost";
  String disLikePost = "${apiURL}post/disLikePost";
  String savePost = "${apiURL}post/savePost";
  String unSavePost = "${apiURL}post/unSavePost";
  String reportPost = "${apiURL}misc/reportPost";
  String addPostComment = "${apiURL}post/addPostComment";
  String likeComment = "${apiURL}post/likeComment";
  String fetchPostComments = "${apiURL}post/fetchPostComments";
  String fetchPostCommentReplies = "${apiURL}post/fetchPostCommentReplies";
  String deleteComment = "${apiURL}post/deleteComment";
  String deleteCommentReply = "${apiURL}post/deleteCommentReply";
  String pinComment = "${apiURL}post/pinComment";
  String unPinComment = "${apiURL}post/unPinComment";
  String disLikeComment = "${apiURL}post/disLikeComment";
  String replyToComment = "${apiURL}post/replyToComment";
  String fetchMusicExplore = "${apiURL}post/fetchMusicExplore";
  String fetchMusicByCategories = "${apiURL}post/fetchMusicByCategories";
  String fetchSavedMusics = "${apiURL}post/fetchSavedMusics";
  String serchMusic = "${apiURL}post/serchMusic";
  String createStory = "${apiURL}post/createStory";
  String viewStory = "${apiURL}post/viewStory";
  String deleteStory = "${apiURL}post/deleteStory";
  String addUserMusic = "${apiURL}post/addUserMusic";
  String fetchStory = "${apiURL}post/fetchStory";
  String fetchStoryByID = "${apiURL}post/fetchStoryByID";
  String fetchExplorePageData = "${apiURL}post/fetchExplorePageData";
}

class _Setting {
  String fetchSettings = "${apiURL}settings/fetchSettings";
  String uploadFileGivePath = "${apiURL}settings/uploadFileGivePath";
  String deleteFile = "${apiURL}settings/deleteFile";
  String fetchCategorySubCategoryTopic = "${apiURL}settings/fetchCategorySubCategoryTopic";
  String fetchLanguages = "${apiURL}settings/fetchLanguages";
  String fetchLevelBadges = "${apiURL}settings/fetchLevelBadges";
  String fetchCountryStateList = "${apiURL}settings/fetchCountryStateList";
  String fetchCityList = "${apiURL}settings/fetchCityList";
  String fetchInterests = "${apiURL}settings/fetchInterests";
}

class _Google {
  String get searchTextByPlace {
    return "https://places.googleapis.com/v1/places:searchText?fields=*";
  }

  String searchNearByPlace(double lat, double lon) {
    return 'https://places.googleapis.com/v1/places:searchNearby?fields=*';
  }
}

class _Search {
  String searchPosts = "${apiURL}post/searchPosts";
}
