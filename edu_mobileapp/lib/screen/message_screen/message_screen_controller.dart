import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/controller/firebase_firestore_controller.dart';
import 'package:geoedu/common/enum/chat_enum.dart';
import 'package:geoedu/common/extensions/list_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/chat/chat_thread.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/chat_screen/chat_screen.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:geoedu/utilities/firebase_const.dart';

class MessageScreenController extends BaseController {
  List<String> chatCategories = [LKey.chats.tr, LKey.requests.tr];
  RxInt selectedChatCategory = 0.obs;
  FirebaseFirestore db = FirebaseFirestore.instance;
  PageController pageController = PageController();
  User? myUser = SessionManager.instance.getUser();
  RxList<ChatThread> chatsUsers = <ChatThread>[].obs;
  RxList<ChatThread> requestsUsers = <ChatThread>[].obs;
  RxList<AppUser> suggestedUsers = <AppUser>[].obs;
  final dashboardController = Get.find<DashboardScreenController>();
  final firebaseFirestoreController = Get.find<FirebaseFirestoreController>();

  // Search
  TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;

  RxList<AppUser> get filteredSuggestedUsers {
    if (searchQuery.value.isEmpty) return suggestedUsers;
    final query = searchQuery.value.toLowerCase();
    return suggestedUsers
        .where((user) {
          final name = user.fullname?.toLowerCase() ?? '';
          final username = user.username?.toLowerCase() ?? '';
          return name.contains(query) || username.contains(query);
        })
        .toList()
        .obs;
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
  }

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: selectedChatCategory.value);
    _listenToUserChatsAndRequests();
    fetchSuggestedUsers();
  }

  void onPageChanged(int index) {
    selectedChatCategory.value = index;
  }

  Future<void> _listenToUserChatsAndRequests() async {
    isLoading.value = true;
    db
        .collection(FirebaseConst.users)
        .doc(myUser?.id.toString())
        .collection(FirebaseConst.usersList)
        .withConverter(
            fromFirestore: (snapshot, options) => ChatThread.fromJson(snapshot.data()!),
            toFirestore: (ChatThread value, options) => value.toJson())
        .where(FirebaseConst.isDeleted, isEqualTo: false)
        .orderBy(FirebaseConst.id, descending: true)
        .snapshots()
        .listen((event) {
      isLoading.value = false;
      for (var change in event.docChanges) {
        final ChatThread? chatUser = change.doc.data();
        if (chatUser == null) continue;

        switch (change.type) {
          case DocumentChangeType.added:
            if (chatUser.userId != -1) {
              firebaseFirestoreController.fetchUserIfNeeded(chatUser.userId ?? -1);
            }
            if (chatUser.chatType == ChatType.approved) {
              chatsUsers.add(chatUser);
            } else {
              requestsUsers.add(chatUser);
            }

            break;
          case DocumentChangeType.modified:
            // Remove the user from their current list
            final userId = chatUser.userId;
            chatsUsers.removeWhere((user) => user.userId == userId);
            requestsUsers.removeWhere((user) => user.userId == userId);

            (chatUser.chatType == ChatType.approved ? chatsUsers : requestsUsers).add(chatUser);
          case DocumentChangeType.removed:
            // Remove the user from their current list
            final userId = chatUser.userId;
            chatsUsers.removeWhere((user) => user.userId == userId);
            requestsUsers.removeWhere((user) => user.userId == userId);
            break;
        }
      }

      chatsUsers.sort(
        (a, b) {
          return (b.id ?? '0').compareTo(a.id ?? '0');
        },
      );
      requestsUsers.sort(
        (a, b) {
          return (b.id ?? '0').compareTo(a.id ?? '0');
        },
      );

      // Loggers.success('CHAT USER: ${chatsUsers.length}');
      // Loggers.success('REQUEST USER: ${requestsUsers.length}');
    });
  }

  Future<void> fetchSuggestedUsers() async {
    try {
      final snapshot = await db
          .collection(FirebaseConst.appUsers)
          .limit(20)
          .get();

      final currentUserId = myUser?.id;
      final existingChatUserIds =
          chatsUsers.map((c) => c.userId).toSet();

      final users = snapshot.docs
          .map((doc) => AppUser.fromJson(doc.data()))
          .where((user) =>
              user.userId != currentUserId &&
              !existingChatUserIds.contains(user.userId))
          .toList();

      suggestedUsers.assignAll(users);
    } catch (e) {
      Loggers.error('fetchSuggestedUsers error: $e');
    }
  }

  void startChat(AppUser user) {
    ChatThread conversation = ChatThread(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lastMsg: '',
      msgCount: 0,
      isDeleted: false,
      deletedId: 0,
      iAmBlocked: false,
      iBlocked: false,
      requestType: UserRequestAction.accept.title,
      chatType: ChatType.approved,
      conversationId: [
        SessionManager.instance.getUserID(),
        user.userId,
      ].conversationId,
      userId: user.userId,
    );
    conversation.chatUser = user;
    Get.to(() => ChatScreen(
          conversationUser: conversation,
          user: User(id: user.userId),
        ));
  }

  void onLongPress(ChatThread chatConversation) {
    Get.bottomSheet(ConfirmationSheet(
      title: LKey.deleteChatUserTitle.trParams({'user_name': chatConversation.chatUser?.username ?? ''}),
      description: LKey.deleteChatUserDescription.tr,
      onTap: () async {
        int time = DateTime.now().millisecondsSinceEpoch;
        showLoader();
        await db
            .collection(FirebaseConst.users)
            .doc(myUser?.id.toString())
            .collection(FirebaseConst.usersList)
            .doc(chatConversation.userId.toString())
            .update({
          FirebaseConst.deletedId: time,
          FirebaseConst.isDeleted: true,
        }).catchError((error) {
          Loggers.error('USER NOT DELETE : $error');
        });
        stopLoader();
      },
    ));
  }
}
