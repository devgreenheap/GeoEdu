import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/api_service.dart';
import 'package:geoedu/common/service/utils/params.dart';
import 'package:geoedu/common/service/utils/web_service.dart';
import 'package:geoedu/model/general/interest_model.dart';
import 'package:geoedu/model/general/status_model.dart';
import 'package:geoedu/model/user_model/block_user_model.dart';
import 'package:geoedu/model/user_model/follower_model.dart';
import 'package:geoedu/model/user_model/following_model.dart';
import 'package:geoedu/model/user_model/links_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/model/user_model/favorite_user_model.dart';
import 'package:geoedu/model/user_model/users_model.dart';
import 'package:geoedu/screen/edit_profile_screen/widget/add_edit_link_sheet.dart';
import 'package:geoedu/utilities/app_res.dart';

enum LoginMethod {
  email,
  google,
  apple,
  mobile;

  String title() {
    switch (this) {
      case LoginMethod.email:
        return 'email';
      case LoginMethod.google:
        return 'google';
      case LoginMethod.apple:
        return 'apple';
      case LoginMethod.mobile:
        return 'mobile';
    }
  }
}

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  Future<User?> logInUser({
    String? fullName,
    required String identity,
    String? deviceToken,
    required LoginMethod loginMethod,
    int? categoryId,
    int? subCategoryId,
    int? topicId,
    int? languageId,
    String? categoryName,
    String? subCategoryName,
    String? topicName,
    String? languageName,
    bool? isAdult,
    String? referId,
    String? mobile,
    String? mobileCountryCode,
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? country,
    String? zipcode,
  }) async {
    UserModel model = await ApiService.instance.call(
        url: WebService.user.loginInUser,
        param: {
          Params.fullname: fullName,
          Params.identity: identity,
          Params.deviceToken: deviceToken,
          Params.device: Platform.isAndroid ? 0 : 1,
          Params.loginMethod: loginMethod.title(),
          if (categoryId != null) Params.categoryId: categoryId,
          if (subCategoryId != null) Params.subCategoryId: subCategoryId,
          if (topicId != null) Params.topicId: topicId,
          if (languageId != null) Params.languageId: languageId,
          if (categoryName != null) Params.categoryName: categoryName,
          if (subCategoryName != null) Params.subCategoryName: subCategoryName,
          if (topicName != null) Params.topicName: topicName,
          if (languageName != null) 'language_name': languageName,
          if (isAdult != null) Params.isAdult: isAdult ? 1 : 0,
          if (referId != null && referId.isNotEmpty) Params.referId: referId,
          if (mobile != null && mobile.isNotEmpty) Params.userMobileNo: mobile,
          if (mobileCountryCode != null && mobileCountryCode.isNotEmpty) Params.mobileCountryCode: mobileCountryCode,
          if (address1 != null && address1.isNotEmpty) Params.address1: address1,
          if (address2 != null && address2.isNotEmpty) Params.address2: address2,
          if (city != null && city.isNotEmpty) Params.city: city,
          if (state != null && state.isNotEmpty) Params.state: state,
          if (country != null && country.isNotEmpty) Params.country: country,
          if (zipcode != null && zipcode.isNotEmpty) Params.zipcode: zipcode,
        },
        fromJson: UserModel.fromJson);

    if (model.status == true) {
      Future.delayed(const Duration(milliseconds: 100), () {
        SessionManager.instance.setUser(model.data);
        SessionManager.instance.setAuthToken(model.data?.token);
      });
    }
    return model.data;
  }

  Future<User?> logInFakeUser({
    required String identity,
    required String? password,
    String? deviceToken,
    required LoginMethod loginMethod,
  }) async {
    UserModel model = await ApiService.instance.call(
        url: WebService.user.logInFakeUser,
        param: {
          Params.identity: identity,
          Params.password: password,
          Params.deviceToken: deviceToken,
          Params.device: Platform.isAndroid ? 0 : 1,
          Params.loginMethod: loginMethod.title()
        },
        fromJson: UserModel.fromJson);

    if (model.status == true) {
      Future.delayed(const Duration(milliseconds: 100), () {
        SessionManager.instance.setUser(model.data);
        SessionManager.instance.setAuthToken(model.data?.token);
      });
    } else {
      BaseController.share.stopLoader();
      BaseController.share.showSnackBar(model.message);
    }
    return model.data;
  }

  Future<StatusModel> deleteMyAccount() async {
    StatusModel response = await ApiService.instance.call(
        url: WebService.user.deleteMyAccount, fromJson: StatusModel.fromJson);
    return response;
  }

  Future<StatusModel> logoutUser() async {
    StatusModel response = await ApiService.instance
        .call(url: WebService.user.logOutUser, fromJson: StatusModel.fromJson);
    return response;
  }

  Future<User?> fetchUserDetails({int? userId, Function()? onError}) async {
    UserModel userModel = await ApiService.instance.call(
        url: WebService.user.fetchUserDetails,
        param: {Params.userId: userId ?? SessionManager.instance.getUserID()},
        fromJson: UserModel.fromJson,
        onError: onError);
    if (userModel.status == true &&
        userId == SessionManager.instance.getUserID()) {
      SessionManager.instance.setUser(userModel.data);
    }
    return userModel.data;
  }

  Future<User?> updateUserDetails(
      {XFile? profilePhoto,
      String? fullname,
      String? userName,
      String? bio,
      String? instagramHandle,
      String? email,
      String? phoneNumber,
      int? mobileCountryCode,
      String? countryCode,
      String? country,
      String? appLanguage,
      bool? showMyFollowing,
      bool? receiveMessage,
      bool? notifyPostLike,
      bool? notifyPostComment,
      bool? notifyFollow,
      bool? notifyMention,
      bool? notifyGiftReceived,
      bool? notifyChat,
      List<int>? savedMusicIds,
      double? lat,
      double? lon,
      String? whoCanSeePost,
      String? appLastUsed,
      String? region,
      String? regionName,
      String? timezone,
      int? isVerify,
      int? categoryId,
      int? subCategoryId,
      int? topicId,
      int? languageId,
      String? categoryName,
      String? subCategoryName,
      String? topicName,
      String? languageName,
      String? firstName,
      String? lastName,
      String? gender,
      String? dateOfBirth,
      String? collegeName,
      String? degree,
      String? fullQualification,
      String? userRole,
      String? highestDegree,
      String? bankName,
      String? accountNumber,
      String? ifscCode,
      String? branchName,
      String? address1,
      String? address2,
      String? city,
      String? state,
      String? zipcode}) async {
    UserModel userModel = await ApiService.instance.multiPartCallApi(
        url: WebService.user.updateUserDetails,
        filesMap: {
          Params.profilePhoto: [profilePhoto]
        },
        param: {
          Params.fullname: fullname,
          Params.username: userName,
          Params.bio: bio,
          if (instagramHandle != null) Params.instagramHandle: instagramHandle,
          Params.userEmail: email,
          Params.userMobileNo: phoneNumber,
          Params.country: country,
          Params.countryCode: countryCode,
          Params.whoCanViewPost: whoCanSeePost,
          Params.mobileCountryCode: mobileCountryCode,
          if (isVerify != null) Params.isVerify: isVerify,
          if (receiveMessage != null)
            Params.receiveMessage: receiveMessage ? 1 : 0,
          if (showMyFollowing != null)
            Params.showMyFollowing: showMyFollowing ? 1 : 0,
          if (notifyPostLike != null)
            Params.notifyPostLike: notifyPostLike ? 1 : 0,
          if (notifyPostComment != null)
            Params.notifyPostComment: notifyPostComment ? 1 : 0,
          if (notifyFollow != null) Params.notifyFollow: notifyFollow ? 1 : 0,
          if (notifyMention != null)
            Params.notifyMention: notifyMention ? 1 : 0,
          if (notifyGiftReceived != null)
            Params.notifyGiftReceived: notifyGiftReceived ? 1 : 0,
          if (notifyChat != null) Params.notifyChat: notifyChat ? 1 : 0,
          if (savedMusicIds != null)
            Params.savedMusicIds: savedMusicIds.join(','),
          if (appLanguage != null) Params.appLanguage: appLanguage,
          if (lat != null) Params.lat: lat,
          if (lon != null) Params.lon: lon,
          if (appLastUsed != null) Params.appLastUsedAt: appLastUsed,
          if (region != null) Params.region: region,
          if (regionName != null) Params.regionName: regionName,
          if (timezone != null) Params.timezone: timezone,
          if (categoryId != null) Params.categoryId: categoryId,
          if (subCategoryId != null) Params.subCategoryId: subCategoryId,
          if (topicId != null) Params.topicId: topicId,
          if (languageId != null) Params.languageId: languageId,
          if (categoryName != null) Params.categoryName: categoryName,
          if (subCategoryName != null) Params.subCategoryName: subCategoryName,
          if (topicName != null) Params.topicName: topicName,
          if (languageName != null) Params.languageName: languageName,
          if (firstName != null) Params.firstName: firstName,
          if (lastName != null) Params.lastName: lastName,
          if (gender != null) Params.gender: gender,
          if (dateOfBirth != null) Params.dateOfBirth: dateOfBirth,
          if (collegeName != null) Params.collegeName: collegeName,
          if (degree != null) Params.degree: degree,
          if (fullQualification != null) Params.fullQualification: fullQualification,
          if (userRole != null) Params.userRole: userRole,
          if (highestDegree != null) Params.highestDegree: highestDegree,
          if (bankName != null) Params.bankName: bankName,
          if (accountNumber != null) Params.accountNumber: accountNumber,
          if (ifscCode != null) Params.ifscCode: ifscCode,
          if (branchName != null) Params.branchName: branchName,
          if (address1 != null) Params.address1: address1,
          if (address2 != null) Params.address2: address2,
          if (city != null) Params.city: city,
          if (state != null) Params.state: state,
          if (zipcode != null) Params.zipcode: zipcode,
        },
        fromJson: UserModel.fromJson);
    if (userModel.status == true) {
      SessionManager.instance.setUser(userModel.data);
      FirebaseFirestoreController.instance.updateUser(userModel.data);
    }
    return userModel.data;
  }

  Future<StatusModel> checkUsernameAvailability(
      {required String userName}) async {
    return await ApiService.instance.call(
        url: WebService.user.checkUsernameAvailability,
        param: {Params.username: userName},
        fromJson: StatusModel.fromJson);
  }

  Future<LinksModel> addEditDeleteUserLink(
      {String? title,
      String? urlLink,
      int? linkId,
      required LinkType linkType}) async {
    String url;

    switch (linkType) {
      case LinkType.add:
        url = WebService.user.addUserLink;
      case LinkType.edit:
        url = WebService.user.editeUserLink;
      case LinkType.delete:
        url = WebService.user.deleteUserLink;
    }

    LinksModel model = await ApiService.instance.call(
        url: url,
        fromJson: LinksModel.fromJson,
        param: {
          Params.linkId: linkId,
          Params.title: title,
          Params.url: urlLink
        });
    return model;
  }

  Future<InterestsModel> fetchMyInterests() async {
    InterestsModel model = await ApiService.instance.call(
      url: WebService.user.fetchMyInterests,
      fromJson: InterestsModel.fromJson,
    );
    return model;
  }

  Future<InterestsModel> updateMyInterests({required List<int> interestIds}) async {
    InterestsModel model = await ApiService.instance.call(
      url: WebService.user.updateMyInterests,
      fromJson: InterestsModel.fromJson,
      param: {Params.interestIds: interestIds.join(',')},
    );
    return model;
  }

  Future<List<User>> searchUsers(
      {int? lastItemId, String keyWord = '', required int limit}) async {
    UsersModel model = await ApiService.instance.call(
        url: WebService.user.searchUsers,
        param: {
          if (lastItemId != null) Params.lastItemId: lastItemId,
          Params.limit: limit,
          if (keyWord.isNotEmpty) Params.keyword: keyWord,
        },
        fromJson: UsersModel.fromJson);
    return model.data ?? [];
  }

  Future<List<Follower>> fetchMyFollowers(
      {required int lastItemId, required int? userId}) async {
    bool isMe = userId == SessionManager.instance.getUserID();
    String url = isMe
        ? WebService.user.fetchMyFollowers
        : WebService.user.fetchUserFollowers;

    FollowerModel model = await ApiService.instance.call(
        url: url,
        param: {
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != -1) Params.lastItemId: lastItemId,
          if (!isMe) Params.userId: userId,
        },
        fromJson: FollowerModel.fromJson);
    return model.data ?? [];
  }

  Future<List<Following>> fetchMyFollowing(
      {required int lastItemId, required int? userId}) async {
    bool isMe = userId == SessionManager.instance.getUserID();
    String url = isMe
        ? WebService.user.fetchMyFollowings
        : WebService.user.fetchUserFollowings;

    FollowingModel model = await ApiService.instance.call(
        url: url,
        param: {
          Params.limit: AppRes.paginationLimit,
          if (lastItemId != -1) Params.lastItemId: lastItemId,
          if (!isMe) Params.userId: userId,
        },
        fromJson: FollowingModel.fromJson);
    return model.data ?? [];
  }

  Future<StatusModel> followUser({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.user.followUser,
      param: {Params.userId: userId},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<StatusModel> unFollowUser({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.user.unFollowUser,
      param: {Params.userId: userId},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<StatusModel> unBlockUser({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
        url: WebService.user.unBlockUser,
        param: {Params.userId: userId},
        fromJson: StatusModel.fromJson);

    return model;
  }

  Future<StatusModel> blockUser({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
        url: WebService.user.blockUser,
        param: {Params.userId: userId},
        fromJson: StatusModel.fromJson);
    return model;
  }

  Future<StatusModel> reportPost(
      {required int userId,
      required String reason,
      required String description}) async {
    StatusModel model = await ApiService.instance.call(
        url: WebService.user.reportUser,
        param: {
          Params.userId: userId,
          Params.reason: reason,
          Params.description: description,
        },
        fromJson: StatusModel.fromJson);
    return model;
  }

  Future<List<BlockUsers>> fetchMyBlockedUsers() async {
    BlockUserModel response = await ApiService.instance.call(
      url: WebService.user.fetchMyBlockedUsers,
      fromJson: BlockUserModel.fromJson,
    );
    return response.data ?? [];
  }

  Future<void> updateLastUsedAt() async {
    await ApiService.instance.call(url: WebService.user.updateLastUsedAt);
  }

  Future<StatusModel> sendSignupOtp({
    String? mobileCountryCode,
    String? mobile,
    String? email,
  }) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.user.sendSignupOtp,
      param: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (email == null || email.isEmpty) ...{
          Params.mobileCountryCode: mobileCountryCode,
          Params.userMobileNo: mobile,
        },
      },
      fromJson: StatusModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<StatusModel> verifySignupOtp({
    String? mobile,
    String? email,
    required String otp,
  }) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.user.verifySignupOtp,
      param: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (email == null || email.isEmpty) Params.userMobileNo: mobile,
        'otp': otp,
      },
      fromJson: StatusModel.fromJson,
      cancelAuthToken: true,
    );
    return model;
  }

  Future<User?> logInWithVerifiedOtp({
    String? mobile,
    String? email,
    String? deviceToken,
  }) async {
    final bool isEmail = email != null && email.isNotEmpty;
    UserModel model = await ApiService.instance.call(
        url: WebService.user.logInWithVerifiedOtp,
        param: {
          if (isEmail) 'email': email else Params.userMobileNo: mobile,
          Params.deviceToken: deviceToken,
          Params.device: Platform.isAndroid ? 0 : 1,
          Params.loginMethod: isEmail ? LoginMethod.email.title() : LoginMethod.mobile.title(),
        },
        fromJson: UserModel.fromJson,
        cancelAuthToken: true);

    if (model.status == true) {
      Future.delayed(const Duration(milliseconds: 100), () {
        SessionManager.instance.setUser(model.data);
        SessionManager.instance.setAuthToken(model.data?.token);
      });
    } else {
      BaseController.share.stopLoader();
      BaseController.share.showSnackBar(isEmail
          ? 'No account found for this email. Please create an account first.'
          : 'No account found for this mobile number. Please create an account first.');
    }
    return model.data;
  }

  Future<StatusModel> favoriteUser({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.user.favoriteUser,
      param: {Params.userId: userId},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<StatusModel> unFavoriteUser({required int userId}) async {
    StatusModel model = await ApiService.instance.call(
      url: WebService.user.unFavoriteUser,
      param: {Params.userId: userId},
      fromJson: StatusModel.fromJson,
    );
    return model;
  }

  Future<List<FavoriteUser>> fetchMyFavoriteUsers({int? lastItemId, int limit = 50}) async {
    FavoriteUserModel model = await ApiService.instance.call(
      url: WebService.user.fetchMyFavoriteUsers,
      param: {
        Params.limit: limit,
        if (lastItemId != null) Params.lastItemId: lastItemId,
      },
      fromJson: FavoriteUserModel.fromJson,
    );
    return model.data ?? [];
  }
}
