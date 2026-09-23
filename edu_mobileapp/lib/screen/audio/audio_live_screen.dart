import 'package:flutter/material.dart';
import 'package:geoedu/screen/audio/widget/audio_background_imge.dart';
import 'package:geoedu/screen/audio/widget/gift_bottom_sheet.dart';

import '../../utilities/asset_res.dart';

class AudioLiveScreen extends StatelessWidget {
  const AudioLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AudioBackgroundImage(),
          Container(color: Colors.black.withOpacity(.15)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _header(),
                const SizedBox(height: 20),
                _hostAvatar(),
                const SizedBox(height: 20),
                _guestGrid(),
                Expanded(child: chatSection()),
                const SizedBox(height: 20),
                giftWidget(),
                _bottomBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5")),
          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nivatha Renu",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _smallTag("Follow"),
                  const SizedBox(width: 6),
                  _smallTag("00:01:24"),
                ],
              ),
            ],
          ),

          const Spacer(),

          Row(
            spacing: 7,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backBtn(),
              Column(
                spacing: 2,
                children: [
                  Image.asset(AssetRes.livestream),
                  // _liveBadge(),
                  const SizedBox(width: 10),

                  _viewerCount()
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _backBtn(){
    return Container(
      padding: const EdgeInsets.all(6),
      decoration:  BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(.40),
      ),
      child: const Text("x",style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold
      ),),
    );
  }


  Widget _viewerCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          border: Border.all(
            width: .5,
            style: BorderStyle.solid,
            color: Colors.white,
          ),
          color: Colors.black54.withOpacity(.5), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.remove_red_eye, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text("33K", style: TextStyle(color: Colors.white,fontSize: 10)),
        ],
      ),
    );
  }

  // ================= HOST =================

  Widget _hostAvatar() {
    return     Stack(
      alignment: Alignment.center,
      children: [
        /// OUTER GLOW RING
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xffB6FF52).withOpacity(0.35),
              width: 6,
            ),
          ),

          /// INNER RING
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xffB6FF52).withOpacity(0.8),
                width: 6,
              ),
            ),
            /// AVATAR
            child: const CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
            ),
          ),
        ),
      ],
    );
  }


  Widget _guestGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: .8,
        ),
        itemBuilder: (_, index) {
          bool isOccupied = index < 2;
          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isOccupied) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        /// OUTER GLOW RING
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffB6FF52).withOpacity(0.35),
                              width: 6,
                            ),
                          ),

                          /// INNER RING
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xffB6FF52).withOpacity(0.8),
                                width: 6,
                              ),
                            ),

                            /// AVATAR
                            child: const CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                            ),
                          ),
                        ),

                        /// MIC ICON
                        const Positioned(
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black,
                            child: Icon(Icons.mic, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ] else ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                        color: Colors.black26,
                      ),
                      child: Center(child: Image.asset("assets/icons/seat-live.png",height: 22,)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isOccupied ? "Priya Devi" : "Empty",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget giftWidget(){
    final gift = [
      {
        "value": "10",
        "image": "assets/images/gift-1.png",
      },
      {
        "value": "20",
        "image": "assets/images/gift-2.png",
      },
      {
        "value": "30",
        "image": "assets/images/gift-3.png",
      },
      {
        "value": "40",
        "image": "assets/images/gift-4.png",
      },
      {
        "value": "50",
        "image": "assets/images/gift-5.png",
      },
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        separatorBuilder: (context,i)=>const SizedBox(width: 5,),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: gift.length,
        itemBuilder: (context, index) {
          final giftValue = gift[index];
          return Column(
              children: [
               Image.asset(giftValue["image"] as String,height: 40,),
            const SizedBox(height: 4),
                Row(
                  children: [
                    Text( giftValue["value"] as String,
                    style: const TextStyle(color: Colors.white,fontSize: 12,fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5,),
                    Image.asset(AssetRes.coinIcon,height: 16,),
                  ],
                )
              ]
          );
        },
      ),
    );
  }

  Widget chatSection() {
    final users = [
      {
        "name": "Moghit",
        "avatar": "https://i.pravatar.cc/150?img=1",
      },
      {
        "name": "Vanitha",
        "avatar": "https://i.pravatar.cc/150?img=2",
      },
      {
        "name": "Swaetha",
        "avatar": "https://i.pravatar.cc/150?img=3",
      },
      {
        "name": "Ram Kumar",
        "avatar": "https://i.pravatar.cc/150?img=4",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              /// Avatar
              CircleAvatar(
                radius: 23,
                backgroundImage: NetworkImage(user["avatar"] as String),
              ),

              const SizedBox(width: 10),

              /// Name + Message
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user["name"] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                              ),
                            ),
                        const SizedBox(height: 2),
                      ],
                    ),
                    const Text(
                      "has joined the chat",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
            ],
          ),
                ]
          )
        );
      },
    );
  }



  Widget _bottomBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6F88E8),
                  Color(0xFF273A57),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write here...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                GestureDetector(
                  onTap: () {

                  },
                  child: const Text(
                    "Send",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ),
        const SizedBox(width: 12),
        GestureDetector(
            onTap: (){
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const GiftBottomSheet(),
              );
            },
            child: Image.asset(AssetRes.effectGift,height: 35,width: 35)),
        const SizedBox(width: 12),
        Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20)),
      ],
    );
  }
}
