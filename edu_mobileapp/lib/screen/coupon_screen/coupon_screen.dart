import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/model/general/coupon_model.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:get/get.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  List<Coupon> coupons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final result = await CommonService.instance.fetchCoupons();
      if (result.status == true && result.data != null) {
        setState(() {
          coupons = result.data!.where((c) => c.isActive == 1).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kAppBarGradient),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: const Text(
          "My Coupons",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white38, strokeWidth: 2))
          : coupons.isEmpty
              ? const Center(
                  child: Text(
                    'No coupons available',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: coupons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _CouponCard(coupon: coupons[index]),
                ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _isExpired();
    final bool isFullyUsed =
        (coupon.maxUses ?? 0) > 0 && (coupon.usedCount ?? 0) >= (coupon.maxUses ?? 0);
    final bool isAvailable = !isExpired && !isFullyUsed;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isAvailable
              ? [ColorRes.cardBackground, ColorRes.surfaceBackground]
              : [const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)],
        ),
        border: Border.all(
          color: isAvailable
              ? ColorRes.green1.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          /// Left: Discount badge
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isAvailable
                  ? ColorRes.green1.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/discount.png",
                    width: 32, height: 32),
                const SizedBox(height: 6),
                Text(
                  coupon.displayValue,
                  style: TextStyle(
                    color: isAvailable
                        ? ColorRes.green1
                        : Colors.white38,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  coupon.type == 'percentage' ? 'OFF' : 'FLAT',
                  style: TextStyle(
                    color: isAvailable ? Colors.white70 : Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          /// Dashed divider
          _dashedDivider(isAvailable),

          /// Right: Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Code row + copy
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          coupon.code ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: coupon.code ?? ''));
                          BaseController.share.showSnackBar('Coupon code copied!');
                        },
                        child: Icon(
                          Icons.copy_rounded,
                          color: isAvailable
                              ? ColorRes.green1
                              : Colors.white30,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Expiry
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: isExpired
                              ? Colors.redAccent
                              : Colors.white38,
                          size: 14),
                      const SizedBox(width: 4),
                      Text(
                        isExpired
                            ? 'Expired'
                            : 'Expires: ${coupon.expiryDate ?? 'N/A'}',
                        style: TextStyle(
                          color: isExpired
                              ? Colors.redAccent
                              : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// Usage
                  if ((coupon.maxUses ?? 0) > 0)
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            color: isFullyUsed
                                ? Colors.redAccent
                                : Colors.white38,
                            size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isFullyUsed
                              ? 'Fully redeemed'
                              : '${coupon.usedCount ?? 0}/${coupon.maxUses} used',
                          style: TextStyle(
                            color: isFullyUsed
                                ? Colors.redAccent
                                : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isExpired() {
    if (coupon.expiryDate == null) return false;
    try {
      final expiry = DateTime.parse(coupon.expiryDate!);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }

  Widget _dashedDivider(bool isAvailable) {
    return SizedBox(
      width: 1,
      height: 100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxHeight / 6).floor();
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(dashCount, (_) {
              return Container(
                width: 1,
                height: 3,
                color: isAvailable
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
              );
            }),
          );
        },
      ),
    );
  }
}
