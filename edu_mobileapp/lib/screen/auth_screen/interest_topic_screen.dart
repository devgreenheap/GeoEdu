import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';
import 'package:geoedu/screen/dashboard_screen/dashboard_screen.dart';

/// Interest Screen 3 of 3 — Topic selection.
/// Final step before the user enters the main app / home screen.
class InterestTopicScreen extends StatefulWidget {
  final User? userData;
  final List<Category> selectedCategories;
  final List<SubCategory> selectedSubCategories;
  final List<Topic> allTopics;

  const InterestTopicScreen({
    super.key,
    this.userData,
    required this.selectedCategories,
    required this.selectedSubCategories,
    required this.allTopics,
  });

  @override
  State<InterestTopicScreen> createState() => _InterestTopicScreenState();
}

class _InterestTopicScreenState extends State<InterestTopicScreen>
    with SingleTickerProviderStateMixin {
  final Set<Topic> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _finish() {
    // Persist the user's selected category interests so they appear in Edit Profile
    try {
      final categoryIds = widget.selectedCategories
          .map((c) => c.id)
          .whereType<int>()
          .toList();
      if (categoryIds.isNotEmpty) {
        UserService.instance.updateMyInterests(interestIds: categoryIds);
      }
    } catch (_) {}

    // Show Lottie success animation then navigate to dashboard
    Get.to(
      () => _InterestSuccessScreen(userData: widget.userData),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 400),
      fullscreenDialog: true,
    );
  }

  static const List<Color> _chipColors = [
    Color(0xFFFF6A00),
    Color(0xFF39A852),
    Color(0xFF3B82F6),
    Color(0xFFEAB308),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFE11D48),
  ];

  Color _colorFor(int index) =>
      _chipColors[index % _chipColors.length];

  List<Topic> get _filteredTopics {
    if (_searchQuery.isEmpty) return widget.allTopics;
    final q = _searchQuery.toLowerCase();
    return widget.allTopics.where((topic) {
      final name = topic.name?.toLowerCase() ?? '';
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              if (widget.allTopics.isNotEmpty) _buildSearchBar(),
              Expanded(
                child: widget.allTopics.isEmpty
                    ? _buildEmpty()
                    : _filteredTopics.isEmpty
                        ? _buildNoSearchResults()
                        : _buildTopicCloud(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AuthColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? AuthColors.primaryOrange.withValues(alpha: 0.6)
                : AuthColors.border.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
          style: const TextStyle(
            color: AuthColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search topics...',
            hintStyle: TextStyle(
              color: AuthColors.textSecondary.withValues(alpha: 0.55),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AuthColors.textSecondary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AuthColors.textSecondary,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                color: AuthColors.textSecondary.withValues(alpha: 0.6), size: 44),
            const SizedBox(height: 12),
            Text(
              'No topics match "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuthColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear search',
                  style: TextStyle(
                      color: AuthColors.primaryOrange,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AuthColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AuthColors.border.withValues(alpha: 0.6)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AuthColors.textPrimary, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    _progressPill(active: false, done: true),
                    const SizedBox(width: 6),
                    _progressPill(active: false, done: true),
                    const SizedBox(width: 6),
                    _progressPill(active: true, done: false),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            AuthColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('3 of 3',
                          style: TextStyle(
                              color: AuthColors.primaryOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Pick your\nFavourite Topics',
              style: TextStyle(
                  color: AuthColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25)),
          const SizedBox(height: 8),
          const Text(
            'Fine-tune your feed by selecting the exact\ntopics you love.',
            style: TextStyle(
                color: AuthColors.textSecondary,
                fontSize: 13,
                height: 1.5),
          ),
          const SizedBox(height: 12),
          // Breadcrumb trail
          if (widget.selectedCategories.isNotEmpty ||
              widget.selectedSubCategories.isNotEmpty)
            _buildBreadcrumb(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final crumbs = <String>[
      ...widget.selectedCategories.map((c) => c.name ?? '').where((n) => n.isNotEmpty),
      ...widget.selectedSubCategories.map((s) => s.name ?? '').where((n) => n.isNotEmpty),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: crumbs.asMap().entries.map((e) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (e.key > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AuthColors.textSecondary, size: 14),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AuthColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AuthColors.border.withValues(alpha: 0.5)),
                ),
                child: Text(e.value,
                    style: const TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _progressPill({required bool active, required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 6,
      width: active ? 40 : 20,
      decoration: BoxDecoration(
        color: done
            ? AuthColors.gioGreen
            : active
                ? AuthColors.primaryOrange
                : AuthColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTopicCloud() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _filteredTopics.asMap().entries.map((e) {
          final idx = e.key;
          final topic = e.value;
          final isSelected = _selected.contains(topic);
          final color = _colorFor(idx);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(topic);
                } else {
                  _selected.add(topic);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.18)
                    : AuthColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : AuthColors.border.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    topic.name ?? '',
                    style: TextStyle(
                      color:
                          isSelected ? color : AuthColors.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 5),
                    Icon(Icons.check_circle_rounded, color: color, size: 14),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AuthColors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore_rounded,
                color: AuthColors.primaryOrange, size: 38),
          ),
          const SizedBox(height: 16),
          const Text('No topics available',
              style: TextStyle(
                  color: AuthColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Your personalised feed is ready.\nTap Finish to start exploring!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AuthColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: BoxDecoration(
        color: AuthColors.background,
        border: Border(
            top: BorderSide(
                color: AuthColors.border.withValues(alpha: 0.4), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: AuthColors.gioGreen, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${_selected.length} topic${_selected.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                        color: AuthColors.gioGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          // 🎉 Finish / Let's Go button
          AuthPrimaryButton(
            text: '🎉  Let\'s Explore!',
            onTap: _finish,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _finish,
            child: const Text('Skip for now',
                style: TextStyle(
                    color: AuthColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// Full-screen Lottie success animation shown after interest selection.
/// Auto-navigates to the Dashboard after the animation completes.
class _InterestSuccessScreen extends StatefulWidget {
  final User? userData;
  const _InterestSuccessScreen({this.userData});

  @override
  State<_InterestSuccessScreen> createState() => _InterestSuccessScreenState();
}

class _InterestSuccessScreenState extends State<_InterestSuccessScreen> {
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _playSound();
    // Auto navigate after animation duration (2.5s)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Get.offAll(() => DashboardScreen(myUser: widget.userData));
      }
    });
  }

  Future<void> _playSound() async {
    try {
      _player = AudioPlayer();
      await _player?.setAsset('assets/interest/Success.mp3');
      await _player?.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A0F), // deep dark green
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing circle with Lottie
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuthColors.gioGreen.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: AuthColors.gioGreen.withValues(alpha: 0.3),
                        blurRadius: 70,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    'assets/interest/success.json',
                    fit: BoxFit.contain,
                    repeat: false,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.check_circle_rounded,
                      color: AuthColors.gioGreen,
                      size: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'All Set! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AuthColors.gioGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your interests have been saved.\nWelcome to GeoEdu!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

