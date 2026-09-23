import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_search_text_field.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/screen/search_screen/search_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_divider.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/full_name_with_blue_tick.dart';
import 'package:geoedu/common/widget/load_more_widget.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/common/widget/no_data_widget.dart';
import '../../common/widget/custom_app_bar.dart';
import '../../model/user_model/user_model.dart';
import '../../utilities/color_res.dart';
import '../live_stream/livestream_screen/widget/live_stream_background_blur_image.dart';


class SearchUserListScreen extends StatelessWidget {
  const SearchUserListScreen({super.key,this.myUser,});
  final User? myUser;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchScreenController());
    controller.searchUsers(reset: true);
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: NewCustomAppBar(title: "Search"),
      ),
      body: Stack(
        children: [
          const LiveStreamBlurBackgroundImage(),
          Column(
            children: [
              Obx(
                    () => CustomSearchTextField(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  gradient: true,
                  searchTextColor: Colors.white,
                  controller: controller.searchKeyword,
                  onChanged: (value) => controller.onChanged2(600),
                  suffixIcon: controller.isTextEmpty.value
                      ? null
                      : InkWell(
                    onTap: () {
                      controller.searchKeyword.clear();
                      controller.onChanged(0);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset(AssetRes.icClose,
                          width: 20,
                          height: 20,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: UserList(
                  onTap: controller.onUserTap,
                  users: controller.users,
                  isLoading: controller.isUsersLoading,
                  loadMore: controller.searchUsers,
                  getFullName: (p0) => p0.fullname ?? '',
                  getProfilePhoto: (p0) => p0.profilePhoto ?? '',
                  getUserName: (p0) => p0.username ?? '',
                  getVerified: (p0) => p0.isVerify ?? 0,
                  getIsFollow: (p0) => p0.isFollowing ?? false,
                  getFollowerCount: (p0) => p0.followerCount?.toInt() ?? 0,
                  getBio: (p0) => p0.bio ?? '',
                  controller: controller,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class UserList<T> extends StatelessWidget {
  final RxList<T> users;
  final Function(T user) onTap;
  final Future<void> Function()? loadMore;
  final String Function(T) getProfilePhoto;
  final String Function(T) getUserName;
  final String Function(T) getFullName;
  final int Function(T) getVerified;
  final bool Function(T) getIsFollow;
  final int Function(T)? getFollowerCount;
  final String Function(T)? getBio;
  final RxBool isLoading;
  final SearchScreenController controller;


  const UserList(
      {super.key,
      required this.onTap,
      this.loadMore,
      required this.users,
      required this.isLoading,
      required this.getProfilePhoto,
      required this.getUserName,
      required this.getFullName,
        required this.getIsFollow,
        required this.getVerified,
      this.getFollowerCount,
      this.getBio,
      required this.controller,
      });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => isLoading.value && users.isEmpty
          ? const LoaderWidget(
              color: Colors.white,
            )
          : LoadMoreWidget(
              loadMore: loadMore ?? () async {},
              child: NoDataView(
                showShow: !isLoading.value && users.isEmpty,
                title: LKey.userListEmptyTitle.tr,
                description: LKey.userListEmptyDescription.tr,
                child: RefreshIndicator(
                  color: Colors.white,
                  onRefresh: () async => controller.searchUsers(reset: true),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                      separatorBuilder: (context, index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          height: .5,
                          color: textLightGrey(context)),
                      itemCount: users.length,
                      padding:
                          const EdgeInsets.only(bottom: 30, left: 10, right: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = (user as dynamic).id ?? -1;
                        return Obx(() => UserCard(
                          onTap: () => onTap(user),
                          fullName: getFullName(user),
                          profilePhoto: getProfilePhoto(user),
                          userName: getUserName(user),
                          isVerified: getVerified(user),
                          isFollow: getIsFollow(user),
                          followerCount: getFollowerCount?.call(user),
                          bio: getBio?.call(user),
                          onFollowTap: () => controller.toggleFollow(index),
                          isLoading: controller.followLoadingIds.contains(userId),
                        ));
                      }),
                ),
              ),
            ),
    );
  }
}

class UserCard<T> extends StatelessWidget {
  final VoidCallback onTap;
  final String? profilePhoto;
  final String? userName;
  final String? fullName;
  final int isVerified;
  final VoidCallback onFollowTap;
  final bool isFollow;
  final bool isLoading;
  final int? followerCount;
  final String? bio;


  const UserCard(
      {super.key,
      required this.onTap,
      required this.profilePhoto,
      required this.userName,
      required this.fullName,
        required this.onFollowTap,
        this.isFollow = false,
        this.isLoading = false,
      this.isVerified = 0,
      this.followerCount,
      this.bio});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CustomImage(
                    size: const Size(40, 40),
                    image: profilePhoto?.addBaseURL(),
                    fullName: fullName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FullNameWithBlueTick(
                          username: userName,
                          fontSize: 13,
                          fontColor: Colors.white,
                          iconSize: 14,
                          isVerify: isVerified),
                      Text(
                        fullName ?? '',
                        style:
                            TextStyleCustom.outFitLight300(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${followerCount ?? 0} followers',
                            style: TextStyleCustom.outFitLight300(
                                color: Colors.white54, fontSize: 11),
                          ),
                          if (bio != null && bio!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '• $bio',
                                style: TextStyleCustom.outFitLight300(
                                    color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: isLoading ? null : onFollowTap,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isFollow == true
                          ? Colors.transparent
                          : ColorRes.primaryColor,
                    ),
                    child:  isLoading
                        ?  SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isFollow == true ? Colors.white : Colors.black,
                      ),
                    )
                        : Row(
                      children: [
                         Icon(isFollow == true ? Icons.done : Icons.add,color: isFollow == true ? Colors.white: Colors.black,size: 15,),
                        const SizedBox(width: 5,),
                        Text(
                          isFollow == true ? "Unfollow" : "Follow",
                          style:  TextStyle(
                              color:isFollow == true ? Colors.white : Colors.black, fontSize: 12,fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        const CustomDivider(color: Colors.transparent)
      ],
    );
  }
}
