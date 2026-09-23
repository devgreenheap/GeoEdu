import 'package:flutter/material.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/general/coupon_model.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/const_res.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DiamondPurchaseBottom extends StatefulWidget {
  final String diamonds;
  final String price;
  final String offerPrice;
  final int? diamondPackId;
  final VoidCallback? onPurchaseSuccess;
  final bool isOfferPopup;
  const DiamondPurchaseBottom({
    super.key,
    required this.diamonds,
    required this.price,
    required this.offerPrice,
    this.diamondPackId,
    this.onPurchaseSuccess,
    this.isOfferPopup = false,
  });

  @override
  State<DiamondPurchaseBottom> createState() => _DiamondPurchaseBottomState();
}

class _DiamondPurchaseBottomState extends State<DiamondPurchaseBottom> {
  late Razorpay _razorpay;
  Coupon? _availableCoupon;
  Coupon? _appliedCoupon;
  double _finalPrice = 0;
  bool _couponLoading = true;

  @override
  void initState() {
    super.initState();
    _finalPrice = double.tryParse(widget.offerPrice) ?? 0;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchCoupon();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchCoupon() async {
    try {
      final result = await CommonService.instance.fetchCoupons(limit: 10);
      if (result.status == true && result.data != null) {
        final now = DateTime.now();
        final activeCoupons = result.data!.where((c) {
          if (c.isActive != 1) return false;
          if (c.expiryDate != null && c.expiryDate!.isNotEmpty) {
            try {
              final expiry = DateTime.parse(c.expiryDate!);
              if (expiry.isBefore(now)) return false;
            } catch (_) {}
          }
          if (c.maxUses != null && c.maxUses! > 0 && (c.usedCount ?? 0) >= c.maxUses!) return false;
          return true;
        }).toList();
        if (activeCoupons.isNotEmpty) {
          setState(() {
            _availableCoupon = activeCoupons.first;
            _couponLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _couponLoading = false);
  }

  void _applyCoupon() {
    if (_availableCoupon == null || _appliedCoupon != null) return;
    final basePrice = double.tryParse(widget.offerPrice) ?? 0;
    double discount = 0;
    if (_availableCoupon!.type == 'percentage') {
      discount = basePrice * (_availableCoupon!.value ?? 0) / 100;
    } else {
      discount = (_availableCoupon!.value ?? 0).toDouble();
    }
    setState(() {
      _appliedCoupon = _availableCoupon;
      _finalPrice = (basePrice - discount).clamp(0, basePrice);
    });
    Get.snackbar(
      'Coupon Applied',
      '${_availableCoupon!.displayValue} off with "${_availableCoupon!.code}"',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _finalPrice = double.tryParse(widget.offerPrice) ?? 0;
    });
  }

  void _openRazorpay() {
    final user = SessionManager.instance.getUser();

    var options = {
      'key': razorpayKeyId,
      'amount': (_finalPrice * 100).toInt(),
      'name': 'GeoEdu',
      'description': '${widget.diamonds} Diamonds',
      'prefill': {
        'email': user?.userEmail ?? '',
        'contact': user?.userMobileNo ?? '',
      },
      'theme': {
        'color': '#214f86',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Loggers.error('Razorpay Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Loggers.success('Payment Success: ${response.paymentId}');
    try {
      final result = await GiftWalletService.instance.verifyDiamondPurchase(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId,
        signature: response.signature,
        diamondPackId: widget.diamondPackId ?? 0,
        amount: _finalPrice,
        couponCode: _appliedCoupon?.code,
      );
      if (result.status == true && result.data != null) {
        SessionManager.instance.setUser(result.data);
      }
      Get.back();
      widget.onPurchaseSuccess?.call();
      Get.snackbar(
        'Payment Successful',
        '${widget.diamonds} Diamonds added to your account',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Loggers.error('Verify diamond purchase failed: $e');
      Get.back();
      Get.snackbar(
        'Payment Received',
        'Diamonds will be credited shortly',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Loggers.error('Payment Failed: ${response.code} - ${response.message}');
    final message = (response.message != null && response.message!.isNotEmpty && response.message != 'undefined')
        ? response.message!
        : 'Payment was cancelled';
    Get.snackbar(
      'Payment Cancelled',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Loggers.info('External Wallet: ${response.walletName}');
  }

  @override
  Widget build(BuildContext context) {
    double price = double.parse(widget.price);
    int saved = (price - _finalPrice).toInt();
    int savedPercent = price > 0 ? (((price - _finalPrice) / price) * 100).round() : 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(
            colors: [
              Color(0xFF313131),
              Color(0xFF060d14),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isOfferPopup) topSection(),
            if (!widget.isOfferPopup) const SizedBox(height: 10),
            if (widget.isOfferPopup)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Best Offer for you",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                      SizedBox(width: 5),
                      Text(
                        "Safe Payments",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              )
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Buy Diamonds",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 10),
            if (!widget.isOfferPopup) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Trusted by 10 crore+ Indians 🇮🇳",
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
            diamondCard(
              diamonds: widget.diamonds,
              price: widget.price,
              finalPrice: _finalPrice.toStringAsFixed(
                  _finalPrice.truncateToDouble() == _finalPrice ? 0 : 2),
            ),
            const SizedBox(height: 10),
            if (!_couponLoading && _availableCoupon != null)
              _DynamicOfferCard(
                coupon: _availableCoupon!,
                isApplied: _appliedCoupon != null,
                onApply: _applyCoupon,
                onRemove: _removeCoupon,
              ),
            if (!_couponLoading && _availableCoupon != null)
              const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.isOfferPopup ? "$savedPercent% Discount Applied" : "$saved ₹ Saved",
                style: const TextStyle(
                    color: Colors.green, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            buyBtn(),
            if (widget.isOfferPopup) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  "No, cancel",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  void _applyAndPay() {
    if (_availableCoupon != null && _appliedCoupon == null) {
      _applyCoupon();
    }
    _openRazorpay();
  }

  Widget buyBtn() {
    final isOffer = widget.isOfferPopup;
    return InkWell(
      onTap: isOffer ? _applyAndPay : _openRazorpay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: ColorRes.primaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          isOffer
              ? "I want this Offer"
              : "Buy for ${_finalPrice.toStringAsFixed(_finalPrice.truncateToDouble() == _finalPrice ? 0 : 2)} ₹",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget diamondCard({
    required String diamonds,
    required String price,
    required String finalPrice,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: .5, color: Colors.white24),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(spacing: 5, children: [
            Image.asset(AssetRes.starstoreDiamond, width: 32, height: 32),
            Text(
              diamonds,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ]),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (price != finalPrice) ...[
                Text("₹$price",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                      decoration: TextDecoration.lineThrough,
                    )),
                const SizedBox(width: 8),
              ],
              Text("₹$finalPrice",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          )
        ],
      ),
    );
  }

  Widget topSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2b2c2b),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            spacing: 5,
            children: [
              Icon(Icons.star_border, color: Colors.white60, size: 25),
              Text("4.8 ratings",
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          Column(
            spacing: 5,
            children: [
              Icon(Icons.verified, color: Colors.white60, size: 25),
              Text("Verified Hosts",
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          Column(
            spacing: 5,
            children: [
              Icon(Icons.castle, color: Colors.white60, size: 25),
              Text("Bank Approved",
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DynamicOfferCard extends StatefulWidget {
  final Coupon coupon;
  final bool isApplied;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _DynamicOfferCard({
    required this.coupon,
    required this.isApplied,
    required this.onApply,
    required this.onRemove,
  });

  @override
  State<_DynamicOfferCard> createState() => _DynamicOfferCardState();
}

class _DynamicOfferCardState extends State<_DynamicOfferCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-6, -6)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-6, -6), end: const Offset(6, 6)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(6, 6), end: const Offset(-5, 5)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-5, 5), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (!widget.isApplied) _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;
    final isApplied = widget.isApplied;

    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        return Transform.translate(
          offset: isApplied ? Offset.zero : _offset.value,
          child: child,
        );
      },
      child: InkWell(
        onTap: isApplied ? widget.onRemove : widget.onApply,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: isApplied
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF3A3D5C), Color(0xFF2B2C2B)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: isApplied ? const Color(0xFF1B3B24) : null,
            borderRadius: BorderRadius.circular(12),
            border: isApplied
                ? Border.all(color: Colors.green.shade400, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                isApplied ? Icons.check_circle : Icons.local_offer,
                color: isApplied ? Colors.green.shade400 : Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isApplied
                          ? '"${coupon.code}" applied - ${coupon.displayValue} off'
                          : 'Extra ${coupon.displayValue} Off with "${coupon.code}"',
                      style: TextStyle(
                        color: isApplied ? Colors.green.shade300 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isApplied) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'View all coupons >',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isApplied ? Colors.red.shade400 : ColorRes.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isApplied ? "Remove" : "Apply",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
