import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/coupon_model.dart';
import 'package:geoedu/utilities/asset_res.dart';

class OfferCardBottom extends StatefulWidget {
  final String diamonds;
  final String price;
  final String offerPrice;
  const OfferCardBottom({
    super.key,
    required this.diamonds,
    required this.price,
    required this.offerPrice,
  });

  @override
  State<OfferCardBottom> createState() => _OfferCardBottomState();
}

class _OfferCardBottomState extends State<OfferCardBottom> {
  Coupon? _coupon;

  @override
  void initState() {
    super.initState();
    _fetchCoupon();
  }

  Future<void> _fetchCoupon() async {
    try {
      final result = await CommonService.instance.fetchCoupons(limit: 5);
      if (result.status == true && result.data != null) {
        final now = DateTime.now();
        final active = result.data!.where((c) {
          if (c.isActive != 1) return false;
          if (c.expiryDate != null && c.expiryDate!.isNotEmpty) {
            try {
              if (DateTime.parse(c.expiryDate!).isBefore(now)) return false;
            } catch (_) {}
          }
          if (c.maxUses != null && c.maxUses! > 0 && (c.usedCount ?? 0) >= c.maxUses!) return false;
          return true;
        }).toList();
        if (active.isNotEmpty && mounted) {
          setState(() => _coupon = active.first);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    double price = double.parse(widget.price);
    double offerPrice = double.parse(widget.offerPrice);
    int saved = (price - offerPrice).toInt();

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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Best offer for you",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Safe payments",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            diamondCard(
              diamonds: widget.diamonds,
              price: widget.price,
              offerPrice: widget.offerPrice,
            ),
            const SizedBox(height: 10),
            if (_coupon != null) _DynamicOfferCardDisplay(coupon: _coupon!),
            if (_coupon != null) const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "$saved ₹ Discount applied",
                style: const TextStyle(color: Colors.green, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            buyBtn(widget.offerPrice),
          ],
        ),
      ),
    );
  }

  Widget buyBtn(String price) {
    return Column(
      spacing: 10,
      children: [
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFffc420),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            "I want this offer",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Text(
            "No,cancel",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget diamondCard({
    required String diamonds,
    required String price,
    required String offerPrice,
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
            Image.asset(AssetRes.starstoreDiamond, width: 40, height: 40),
            Text(
              diamonds,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ]),
          Column(
            children: [
              Text("₹ $offerPrice",
                  style:
                      const TextStyle(color: Colors.white, fontSize: 16)),
              Text("₹ $price",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  )),
            ],
          )
        ],
      ),
    );
  }
}

class _DynamicOfferCardDisplay extends StatefulWidget {
  final Coupon coupon;

  const _DynamicOfferCardDisplay({required this.coupon});

  @override
  State<_DynamicOfferCardDisplay> createState() =>
      _DynamicOfferCardDisplayState();
}

class _DynamicOfferCardDisplayState extends State<_DynamicOfferCardDisplay>
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
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _loop();
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
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        return Transform.translate(offset: _offset.value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFfeedbf),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Extra ${widget.coupon.displayValue} off with "${widget.coupon.code}"',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
