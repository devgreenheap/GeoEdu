import 'package:flutter/material.dart';
import 'package:geoedu/model/star_store/effects_model.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../../utilities/asset_res.dart';
import 'buy_effects_screen.dart';

class GiftBottomSheet extends StatefulWidget {
  const GiftBottomSheet({super.key});

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  int selectedIndex = 0;

  final List<Map<String, String>> gift = [
    {"value": "10", "image": "assets/images/gift-1.png"},
    {"value": "20", "image": "assets/images/gift-2.png"},
    {"value": "30", "image": "assets/images/gift-3.png"},
    {"value": "40", "image": "assets/images/gift-4.png"},
    {"value": "60", "image": "assets/images/gift-5.png"},
    {"value": "100", "image": "assets/images/gift-1.png"},
  ];

  int selectedTab = 0;
  final List<Map<String, String>> effects = [
    {"value": "100", "image": "assets/images/gift-1.png"},
    {"value": "150", "image": "assets/images/gift-2.png"},
    {"value": "200", "image": "assets/images/gift-3.png"},
  ];

  List<EntryEffectModel> entryEffects = [

    EntryEffectModel(
      image: AssetRes.effectFlash,
      title: "VIP entry effect",
      currentPrice: 599,
      originalPrice: 999,
      discountPercent: 40,
      duration: "For 12 hours",
      buttonText: "Buy",
      videoPath: AssetRes.carEffectVideo,
    ),EntryEffectModel(
      image: AssetRes.effectGift,
      title: "VIP entry effect",
      currentPrice: 599,
      originalPrice: 999,
      discountPercent: 40,
      duration: "For 12 hours",
      buttonText: "Buy",
      videoPath: AssetRes.carEffectVideo,

    ),EntryEffectModel(
      image: AssetRes.effectRocket,
      title: "VIP entry effect",
      currentPrice: 599,
      originalPrice: 999,
      discountPercent: 40,
      duration: "For 12 hours",
      buttonText: "Buy",
      videoPath: AssetRes.carEffectVideo,

    ),EntryEffectModel(
      image: AssetRes.effectMusic,
      title: "VIP entry effect",
      currentPrice: 599,
      originalPrice: 999,
      discountPercent: 40,
      duration: "For 12 hours",
      buttonText: "Buy",
      videoPath: AssetRes.carEffectVideo,

    ),
    EntryEffectModel(
      image: AssetRes.effectCoffee,
      title: "Premium entry effect",
      currentPrice: 399,
      originalPrice: 679,
      discountPercent: 50,
      duration: "For 6 hours",
      buttonText: "Buy",
      videoPath: AssetRes.carEffectVideo,

    ),EntryEffectModel(
      image: AssetRes.effectCoffee,
      title: "Premium entry effect",
      currentPrice: 399,
      originalPrice: 679,
      discountPercent: 50,
      duration: "For 6 hours",
      buttonText: "Buy",
      videoPath: AssetRes.carEffectVideo,

    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff021A3B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          /// DRAG HANDLE
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10)),
          ),

          const SizedBox(height: 15),

          /// HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Gift & Effects",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Row(
                      children: [
                        const Text("100", style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 5,),
                        Image.asset(AssetRes.coinIcon,height: 16,),
                      ],
                    ),
                    const SizedBox(width: 15,),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xff565ADC),
                            borderRadius: BorderRadius.circular(30),
                          ),child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Recharge',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600,fontSize: 12),),
                            SizedBox(width: 5,),
                            Icon(Icons.arrow_forward_ios,color: Colors.white,size: 12)
                          ],
                        ),
                        )
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          /// TABS
         const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _tabButton("Gift", 0)),
                  const SizedBox(width: 30),
                  Expanded(child: _tabButton("Entry Effects", 1)),
                ],
              ),
            ),
          /// GRID
          if(selectedTab == 0)
            ...[
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: gift.length,
                  shrinkWrap: true,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: .9,
                  ),
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedIndex = index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected ? const Color(0xff252525) : Colors.transparent,
                          border: Border.all(
                              color: isSelected
                                  ? const Color(0xff97F31A)
                                  : Colors.transparent,
                              width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(gift[index]["image"]!, height: 50),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(gift[index]["value"]!,
                                    style:
                                    const TextStyle(color: Colors.white)),
                                const SizedBox(width: 5,),
                                Image.asset(AssetRes.coinIcon,height: 16,),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              /// SEND BAR
              _sendBar(),
            ],
          if(selectedTab == 1)
            ...[
              Container(
                color: Colors.black,
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    _effectsGrid(),
                    const SizedBox(height: 25),
                  ],
                ),
              )
            ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
  int quantity = 2;

  Widget _effectsGrid() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: entryEffects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entryEffect = entryEffects[index];

          return SizedBox(
            width: 170,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFC5246D),
                    Color(0xFF565ADC),
                    Color(0xFF8D466B),
                    Color(0xFFFFC727),
                  ],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF110936),
                      Color(0xFF000000),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2,horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ColorRes.likeRed,
                        ),
                        child: Text(
                          "${entryEffect.discountPercent}% off",
                          style: const TextStyle(fontSize: 7, color: Colors.white),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(entryEffect.image,
                            width: 60, height: 60),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(AssetRes.coinIcon, height: 18),
                            const SizedBox(width: 5),
                            Text(
                              "${entryEffect.currentPrice}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.yellow),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${entryEffect.originalPrice}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          entryEffect.duration,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: (){
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              barrierColor: Colors.transparent,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BuyCoinsBottomSheet(image: entryEffect.image,),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 15,),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 1, color: ColorRes.whitePure),
                              borderRadius: BorderRadius.circular(18),
                              color: ColorRes.whitePure.withOpacity(.40),
                            ),
                            child: const Center(
                              child: Text(
                                "Buy >",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _sendBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [

          /// GOLD BAG DROPDOWN
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: const Color(0xff252525),
              border: Border.all(color: const Color(0xff969696)),
            ),
            child: Row(
              children: [
                Image.asset(
                  "assets/images/gift-1.png",
                  height: 24,
                ),
                const SizedBox(width: 2),
                const Text(
                  "Gold Bag",
                  style: TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// QUANTITY STEPPER
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xff969696)),
              gradient: const LinearGradient(
                colors: [Color(0xff5B6BFF), Color(0xff3C4EC7)],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (quantity > 1) {
                      setState(() => quantity--);
                    }
                  },
                  child: const Icon(Icons.remove, color: Colors.white),
                ),

                const SizedBox(width: 16),

                Text(
                  quantity.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),

                const SizedBox(width: 16),

                GestureDetector(
                  onTap: () {
                    setState(() => quantity++);
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          const Spacer(),

          /// SEND BUTTON
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff78C34C),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xff969696)),
              gradient:  LinearGradient(
                colors: [const Color(0xffB6FF52), const Color(0xff0E131A).withOpacity(0.98)],
              ),
            ),
            child: const Row(
              children: [
                Text(
                  "Send",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,fontSize: 13),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    bool isActive = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
          selectedIndex = 0;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xff97F31A) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (isActive)
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
            )
        ],
      ),
    );
  }

}
