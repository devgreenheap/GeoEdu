import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../common/manager/session_manager.dart';
import '../../common/service/navigation/navigate_with_controller.dart';
import '../../common/widget/custom_divider.dart';
import '../../common/widget/custom_image.dart';
import '../../common/widget/full_name_with_blue_tick.dart';
import '../../common/widget/load_more_widget.dart';
import '../../common/widget/loader_widget.dart';
import '../../common/widget/no_data_widget.dart';
import '../../common/widget/text_button_custom.dart';
import '../../languages/languages_keys.dart';
import '../../model/user_model/user_model.dart';
import '../../utilities/text_style_custom.dart';
import '../../utilities/theme_res.dart';
import 'follow_following_screen.dart';
import 'follow_following_screen_controller.dart';

class FollowingsScreen extends StatelessWidget {
  final User? user;

  const FollowingsScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      FollowFollowingScreenController(
          FollowFollowingType.following, user, context),
      tag: '${user?.id}_following',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(LKey.following.tr),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/following_appbar.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: Obx(() {
        final isEmpty = controller.followings.isEmpty;
        final showLoader =
            controller.isFollowings.value && isEmpty;
        final showNoData =
            !controller.isFollowings.value && isEmpty;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xFF000000),
                    Color(0xFF023341),
                    Color(0xFF023436),
                    Color(0xFF000000),
                  ],
                      begin: AlignmentGeometry.topRight,
                      end: AlignmentGeometry.bottomLeft
                  ),
                ),
              ),
            ),
            // Positioned.fill(
            //     child: Image.asset("assets/images/following_bg.png",fit: BoxFit.cover,)),
            _buildUserList(
              showLoader: showLoader,
              showNoData: showNoData,
              noDataTitle: user?.showMyFollowing == 1
                  ? LKey.nothingToShowHere.tr
                  : null,
              noDataDescription: user?.showMyFollowing == 1
                  ? LKey.userHidFollowings.tr
                  : null,
              users: controller.followings,
              userExtractor: (item) => item.toUser,
              onItemTap: controller.onFollowUnFollow,
              loadMore: controller.fetchFollowings,
              controller: controller.followingController,
            ),
          ],
        );
      }),
    );
  }
}
Widget _buildUserList({
  required bool showLoader,
  required bool showNoData,
  required String? noDataTitle,
  required String? noDataDescription,
  required List<dynamic> users,
  required User? Function(dynamic) userExtractor,
  required Future Function(dynamic) onItemTap,
  required Future Function()? loadMore,
  required ScrollController controller,
}) {
  if (showLoader) return const LoaderWidget();

  return NoDataView(
    showShow: showNoData,
    title: noDataTitle,
    description: noDataDescription,
    child: ListView.builder(
      controller: controller,
      itemCount: users.length,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) {
        final item = users[index];
        final user = userExtractor(item);
        final isFollow =
        user?.isFollowing == null ? true : user?.isFollowing ?? false;

        return UserProfileTile(
          actionName: ActionName.follow,
          onTap: () => onItemTap(item),
          isFollowOrIsBlock: isFollow,
          user: user,
          loadMore: index == users.length - 1 ? loadMore : null,
        );
      },
    ),
  );
}


enum ActionName { follow, block }

class UserProfileTile extends StatefulWidget {
  final ActionName actionName;
  final bool isFollowOrIsBlock;
  final Future Function() onTap;
  final User? user;
  final Future<void> Function()? loadMore;

  const UserProfileTile(
      {super.key,
        required this.actionName,
        required this.isFollowOrIsBlock,
        required this.onTap,
        this.user,
        this.loadMore});

  @override
  State<UserProfileTile> createState() => _UserProfileTileState();
}

class _UserProfileTileState extends State<UserProfileTile> {
  RxBool isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return LoadMoreWidget(
      loadMore: widget.loadMore ?? () async {},
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      NavigationService.shared.openProfileScreen(widget.user);
                    },
                    child: Row(
                      children: [
                        CustomImage(
                            size: const Size(40, 40),
                            fullName: widget.user?.fullname,
                            image: widget.user?.profilePhoto?.addBaseURL()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FullNameWithBlueTick(
                                fontColor: whitePure(context),
                                username: widget.user?.username ?? '',
                                isVerify: widget.user?.isVerify,
                                fontSize: 13,
                                iconSize: 14,
                              ),
                              Text(
                                widget.user?.fullname ?? '',
                                style: TextStyleCustom.outFitLight300(
                                    color: whitePure(context)),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.user?.id != SessionManager.instance.getUserID())
                  Obx(() {
                    Color textColor = widget.isFollowOrIsBlock
                        ? whitePure(context)
                        : whitePure(context);
                    return TextButtonCustom(
                      onTap: () async {
                        if (isLoading.value) return;
                        isLoading.value = true;
                        await widget.onTap();
                        isLoading.value = false;
                      },
                      title: widget.actionName == ActionName.follow
                          ? (widget.isFollowOrIsBlock
                          ? LKey.unFollow.tr
                          : LKey.follow.tr)
                          : (widget.isFollowOrIsBlock
                          ? LKey.unBlock.tr
                          : LKey.block.tr),
                      btnWidth: 80,
                      fontSize: 10,
                      horizontalMargin: 0,
                      btnHeight: 20,
                      titleColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      radius: 50,
                      backgroundColor: widget.isFollowOrIsBlock
                          ? whitePure(context).withOpacity(0.50)
                          : blueFollow(context).withOpacity(0.50),
                      // borderSide: widget.isFollowOrIsBlock
                      //     ? BorderSide(color: bgGrey(context))
                      //     : BorderSide.none,
                      child: isLoading.value
                          ? CircularProgressIndicator(
                          strokeWidth: 1,
                          color: textColor)
                          : null,
                    );
                  })
              ],
            ),
            const SizedBox(height: 10),
            const CustomDivider()
          ],
        ),
      ),
    );
  }
}
