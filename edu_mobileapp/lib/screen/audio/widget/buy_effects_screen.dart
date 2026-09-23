import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../utilities/asset_res.dart';

class BuyCoinsBottomSheet extends StatefulWidget {
  final String image;
  const BuyCoinsBottomSheet({super.key,required this.image});

  @override
  State<BuyCoinsBottomSheet> createState() => _BuyCoinsBottomSheetState();
}

class _BuyCoinsBottomSheetState extends State<BuyCoinsBottomSheet> with TickerProviderStateMixin{

  late SVGAAnimationController _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = SVGAAnimationController(vsync: this);

    if(widget.image.endsWith('.svga'))
      {
        _loadSVGA();
      }

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSVGA() async {
    final videoItem = await SVGAParser.shared.decodeFromAssets(widget.image);
    videoItem.audios.clear();
    _controller.videoItem = videoItem;

    _controller..reset()..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF071B3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// CLOSE BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gold Stars",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            ],
          ),

          const SizedBox(height: 10),

          /// COIN IMAGE
          widget.image.endsWith(".svga")
              ? SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            width: MediaQuery.of(context).size.width,
            child: SVGAImage(_controller),
          )
              : Image.asset(widget.image, height: 80),

          const SizedBox(height: 20),

          /// TITLE
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Choose Validity",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 15),

          /// GRID OPTIONS
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.3,
            children: const [
              _CoinCard("399", "679", "For 6 hours"),
              _CoinCard("1000", "1200", "For 1 Day"),
              _CoinCard("2599", "2679", "For 3 Days"),
              _CoinCard("3999", "6799", "For 4 Days"),
            ],
          ),

          const SizedBox(height: 25),
          /// BUY BUTTON
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF5C6BC0)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Buy For",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(width: 10),
                Image.asset(AssetRes.coinIcon, height: 18),
                const SizedBox(width: 10),
                const Text(
                  "399",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _CoinCard extends StatelessWidget {
  final String price;
  final String oldPrice;
  final String duration;

  const _CoinCard(this.price, this.oldPrice, this.duration);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF200F5A), Color(0xFF000000)],
        ),
        border: Border.all(color: Colors.purpleAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(AssetRes.coinIcon, height: 18),
            const SizedBox(width: 5),
            Text(price,
                style: const TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text(oldPrice,
                style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.white70,
                    fontSize: 12)),
          ]),
          const SizedBox(height: 5),
          Text(duration,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
