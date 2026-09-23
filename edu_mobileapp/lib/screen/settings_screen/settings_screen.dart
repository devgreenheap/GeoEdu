import 'package:flutter/material.dart';
import 'package:geoedu/screen/help_and_support/help_and_support.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/common/widget/custom_toggle.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/blocked_user_screen/blocked_user_screen.dart';
import 'package:geoedu/screen/diamond_purchase/diamond_purchase_screen.dart';
import 'package:geoedu/screen/agent_commission_screen/agent_commission_screen.dart';
import 'package:geoedu/screen/agent_users_screen/agent_users_screen.dart';
import 'package:geoedu/screen/coupon_screen/coupon_screen.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen.dart';
import 'package:geoedu/screen/profile_screen/widget/profile_information_screen.dart';
import 'package:geoedu/screen/leader_board/top_gifters_screen.dart';
import 'package:geoedu/screen/star_wallet_screen/star_wallet_screen.dart';
import 'package:geoedu/screen/qr_code_screen/qr_code_screen.dart';
import 'package:geoedu/screen/select_language_screen/select_language_screen.dart';
import 'package:geoedu/screen/settings_screen/settings_screen_controller.dart';
import 'package:geoedu/screen/settings_screen/widget/setting_icon_text_with_arrow.dart';
import 'package:geoedu/screen/term_and_privacy_screen/term_and_privacy_screen.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../my_effects_screen/my_effects_screen.dart';
import '../star_score/star_score_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Function(User? user)? onUpdateUser;

  const SettingsScreen({super.key, this.onUpdateUser});

  Future<void> launchApp(String url)
  async {
    if(url.isEmpty)
      {
        throw Exception('Could not launch $url');
      }
    else if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
    else{
      await launchUrl(Uri.parse(url));
    }
  }

  void Sharefunc(){
    final user = SessionManager.instance.getUser();
    final referId = '${user?.fullname?.replaceAll(' ', '') ?? ''}${user?.id ?? ''}';
    Share.share(
      'Join GeoEdu & Win prizes! Use my referral code: $referId\n\nDownload now:\nAndroid: https://play.google.com/store/apps/details?id=com.geoedu.app\niOS: https://apps.apple.com/app/id=com.geoedu.app',
      subject: "Download GeoEdu",
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsScreenController());
    return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
      children: [
        Container(
          decoration: const BoxDecoration(gradient: kAppBarGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    LKey.settings.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
            child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: AppBar().preferredSize.height),
                          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SubscriptionCard(
                  //     controller: controller, onUpdateUser: onUpdateUser),
                  SettingLabel(title: LKey.personal.toUpperCase()),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icEdit,
                    title: LKey.editProfile,
                    onTap: () {
                      Get.to(() => EditProfileScreen(onUpdateUser: onUpdateUser));
                    },
                  ),
                  // SettingIconTextWithArrow(
                  //   icon: AssetRes.icPostBookmark,
                  //   title: LKey.savedPosts,
                  //   onTap: () {
                  //     Get.to(() => const SavedPostScreen());
                  //   },
                  // ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icProfile,
                    title: 'Profile Information',
                    onTap: () {
                      Get.to(() => const ProfileInformationScreen());
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.editStar,
                    title: LKey.coinWallet,
                    onTap: () {
                      Get.to(() => const StarWalletScreen());
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.medalIcon,
                    title: 'Leader Board',
                    onTap: () {
                      Get.to(() => const TopGiftersScreen());
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icLanguage_1,
                    title: LKey.languages,
                    onTap: () {
                      Get.to(() => const SelectLanguageScreen(
                          languageNavigationType: LanguageNavigationType.fromSetting));
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icBlock,
                    title: LKey.blockedUsers,
                    onTap: () {
                      Get.to(() => const BlockedUserScreen());
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icQrCode_1,
                    title: LKey.myQrCode,
                    onTap: () {
                      Get.to(() => const QrCodeScreen());
                    },
                  ),
                  Obx(() {
                    final status =
                        controller.myUser.value?.disableScreenshotStatus;
                    final isPending = status == 1;
                    final isApproved = status == 2;
                    return SettingIconTextWithArrow(
                      icon: AssetRes.icBlock,
                      title: 'Disable Screenshot',
                      onTap: isPending || isApproved
                          ? null
                          : () => _showDisableScreenshotDialog(
                              context, controller),
                      widget: isPending
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Pending',
                                  style: TextStyle(
                                      color: Colors.orange, fontSize: 12)),
                            )
                          : isApproved
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Approved',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12)),
                                )
                              : null,
                    );
                  }),
                  Obx(() {
                    if (controller.myUser.value?.isAgent == 1) {
                      return Column(
                        children: [
                          SettingIconTextWithArrow(
                            icon: AssetRes.icProfile,
                            title: 'My Users',
                            onTap: () {
                              Get.to(() => const AgentUsersScreen());
                            },
                          ),
                          SettingIconTextWithArrow(
                            icon: AssetRes.editDiamond,
                            title: 'My Commission',
                            onTap: () {
                              Get.to(() => const AgentCommissionScreen());
                            },
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  }),
                  SettingLabel(title: "Transactions"),
                  Obx(() => SettingIconTextWithArrow(
                    count: '${controller.diamondCount.value}',
                    icon: AssetRes.editDiamond,
                    title: "Diamond",
                    onTap: () {
                      Get.to(() => DiamondPurchaseScreen());
                    },
                  )),
                  Obx(() {
                    if (controller.myUser.value?.isHost != 1) return const SizedBox();
                    return Obx(() => SettingIconTextWithArrow(
                      count: '${controller.starCount.value}',
                      icon: AssetRes.editStar,
                      title: "Stars",
                      onTap: () {
                        Get.to(() => StarScoreScreen());
                      },
                    ));
                  }),
                  Obx(() => SettingIconTextWithArrow(
                    count: '${controller.myEffectsCount.value}',
                    icon: AssetRes.editRocket,
                    title: "My Effects",
                    onTap: () {
                      Get.to(() => const MyEffectsScreen());
                    },
                  )),
                  SettingIconTextWithArrow(
                    icon: AssetRes.editSupport,
                    title: "Payment Support",
                    onTap: () {
                      Get.to(() => HelpAndSupportScreen());
                    },
                  ),


                  SettingLabel(title: LKey.privacy.toUpperCase()),
                  // Obx(
                  //   () => SettingIconTextWithArrow(
                  //     icon: AssetRes.icEye_1,
                  //     title: LKey.whoCanSeePosts,
                  //     widget: CustomDropDownBtn<WhoCanSeePost>(
                  //       // gradient: true,
                  //       items: WhoCanSeePost.values,
                  //       onChanged: controller.isUpdateApiCalled.value
                  //           ? null
                  //           : controller.onChangedWhoCanSeePost,
                  //       selectedValue: controller.selectedWhoCanSeePost.value,
                  //       style: TextStyleCustom.outFitRegular400(
                  //         fontSize: 15,
                  //         color: textLightGrey(context),
                  //       ),
                  //       getTitle: (value) => value.title,
                  //     ),
                  //
                  //   ),
                  // ),
                  Obx(
                    () {
                      return SettingIconTextWithArrow(
                        icon: AssetRes.icEye_1,
                        title: LKey.showMyFollowings,
                        widget: CustomToggle(
                          isOn: (controller.myUser.value?.showMyFollowing == 1).obs,
                          onChanged: (value) {
                            controller.onChangedToggle(
                                value, SettingToggle.showMyFollowings);
                          },
                        ),
                      );
                    },
                  ),
                  Obx(
                    () {
                      return SettingIconTextWithArrow(
                        icon: AssetRes.icMessage,
                        title: LKey.showChatBtn,
                        widget: CustomToggle(
                          isOn: (controller.myUser.value?.receiveMessage == 1).obs,
                          onChanged: (value) async {
                            controller.onChangedToggle(
                                value, SettingToggle.receiveMessage);
                          },
                        ),
                      );
                    },
                  ),
                  // SettingIconTextWithArrow(
                  //   icon: AssetRes.icNotification_1,
                  //   title: LKey.notifications,
                  //   onTap: () {
                  //     Get.to(() => const NotificationsPage());
                  //   },
                  // ),
                  SettingLabel(title: LKey.general.toUpperCase()),
                  SettingIconTextWithArrow(
                    height: 20,
                    width: 20,
                    icon: AssetRes.instagramIcon,
                    title: 'Follow us on Instagram',
                    onTap: () {
                      launchApp("https://instagram.com");
                    },
                  ),
                  SettingIconTextWithArrow(
                    height: 20,
                    width: 20,
                    icon: AssetRes.starSettings,
                    title: 'Rate Us',
                    onTap: () {
                      launchApp("https://play.google.com/");
                    },
                  ),
                  SettingIconTextWithArrow(
                    height: 20,
                    width: 20,
                    icon: AssetRes.addPlusIcon,
                    title: 'Refer & Earn',
                    onTap: Sharefunc,
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icGift,
                    title: 'View Coupons',
                    onTap: () {
                      Get.to(() => const CouponScreen());
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icReport,
                    title: LKey.termsOfUse,
                    onTap: () {
                      Get.to(() => const TermAndPrivacyScreen(
                          type: TermAndPrivacyType.termAndCondition));
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icReport,
                    title: LKey.privacyPolicy,
                    onTap: () {
                      Get.to(() => const TermAndPrivacyScreen(
                          type: TermAndPrivacyType.privacyPolicy));
                    },
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icLogout,
                    title: LKey.logOut,
                    onTap: controller.onLogout,
                    widget: const SizedBox(),
                  ),
                  SettingIconTextWithArrow(
                    icon: AssetRes.icDelete2,
                    title: LKey.deleteAccount,
                    onTap: controller.onDeleteAccount,
                    widget: const SizedBox(),
                  ),

                ],
                          ),
                        ),
            )
      ],
    ));
  }

  void _showDisableScreenshotDialog(
      BuildContext context, SettingsScreenController controller) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorRes.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disable Screenshot',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for disabling screenshot. Your request will be reviewed by admin.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                controller.showSnackBar('Please enter a reason');
                return;
              }
              Navigator.pop(ctx);
              controller.requestDisableScreenshot(reason);
            },
            child: const Text('Submit',
                style: TextStyle(color: Color(0xFFB6FF52))),
          ),
        ],
      ),
    );
  }
}

class SettingLabel extends StatelessWidget {
  final String title;

  const SettingLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 22, bottom: 8),
      child: Text(
        title.tr.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF7A00),
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}
