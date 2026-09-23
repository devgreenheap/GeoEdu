import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:geoedu/model/liveaudio/live_audio_techers_model.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/theme_res.dart';

import '../edit_profile_screen/edit_profile_screen.dart';
import '../select_language_screen/select_language_screen.dart';
import 'audio_live_screen.dart';

class AudioLiveListScreen extends StatefulWidget {
  const AudioLiveListScreen({super.key});

  @override
  State<AudioLiveListScreen> createState() => _AudioLiveListScreenState();
}

class _AudioLiveListScreenState extends State<AudioLiveListScreen> {

  List<LiveAudioTeacherModel> dummyLiveTeachers = [
    LiveAudioTeacherModel(
      id: "1",
      name: "Ravi Gopal Sir",
      description:
      "Skilled in guiding students with clear concepts and strong academic fundamentals.",
      imageUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      rating: 4.53,
      totalSeats: 5,
      isLive: true,
      buttonText: "Join Audio",
    ),
    LiveAudioTeacherModel(
      id: "2",
      name: "Anita Sharma Ma'am",
      description:
      "Expert in Mathematics and logical reasoning with 10+ years experience.",
      imageUrl: "https://randomuser.me/api/portraits/women/2.jpg",
      rating: 4.78,
      totalSeats: 8,
      isLive: true,
      buttonText: "Join Audio",
    ),
    LiveAudioTeacherModel(
      id: "3",
      name: "Rahul Verma Sir",
      description:
      "Physics specialist helping students master problem solving techniques.",
      imageUrl: "https://randomuser.me/api/portraits/men/3.jpg",
      rating: 4.21,
      totalSeats: 3,
      isLive: false,
      buttonText: "Join Audio",
    ),
    LiveAudioTeacherModel(
      id: "1",
      name: "Ravi Gopal Sir",
      description:
      "Skilled in guiding students with clear concepts and strong academic fundamentals.",
      imageUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      rating: 4.53,
      totalSeats: 5,
      isLive: true,
      buttonText: "Join Audio",
    ),
    LiveAudioTeacherModel(
      id: "2",
      name: "Anita Sharma Ma'am",
      description:
      "Expert in Mathematics and logical reasoning with 10+ years experience.",
      imageUrl: "https://randomuser.me/api/portraits/women/2.jpg",
      rating: 4.78,
      totalSeats: 8,
      isLive: true,
      buttonText: "Join Audio",
    ),
    LiveAudioTeacherModel(
      id: "3",
      name: "Rahul Verma Sir",
      description:
      "Physics specialist helping students master problem solving techniques.",
      imageUrl: "https://randomuser.me/api/portraits/men/3.jpg",
      rating: 4.21,
      totalSeats: 3,
      isLive: false,
      buttonText: "Join Audio",
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021636),
      appBar: AppBar(
        title: const Text("Audio Live",style: TextStyle(color: ColorRes.whitePure),),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,

        bottom: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF477d8d),
                      Color(0xFF214f86),
                      Color(0xFF214f86),
                    ],
                    begin: AlignmentGeometry.bottomRight,
                    end: AlignmentGeometry.topLeft,
                    stops: [0.0, 0.5, 1.0],
                  )
              ),
            ),
            Positioned(
              left: 150,
              right: 20,
              top: 8,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: 200,
              top: 20,
              right: 15,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20),
        separatorBuilder: (context,index)=>const SizedBox(height: 10,),
        itemCount: dummyLiveTeachers.length,
        itemBuilder: (context, index) {
          final liveTeacher = dummyLiveTeachers[index];
          return GestureDetector(
            onTap: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AudioLiveScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF0C203C),
                  Color(0xFFCEFF3B),
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    children : [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child : Image.network(
                              liveTeacher.imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover)
                      ),
                      Positioned(
                        top: 0,
                        left: 2,
                        child: Image.asset(AssetRes.livestream,width: 20,height: 20,),
                      ),
                    ]
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveTeacher.name,
                          style: const TextStyle(
                            color: ColorRes.whitePure,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          liveTeacher.description,
                          style: const TextStyle(
                            color: ColorRes.whitePure,
                            fontSize: 8,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 5,
                              children: [
                                SvgPicture.asset("assets/svg_icons/audiopage/Voicecirclre.svg"),
                                Text(
                                  liveTeacher.rating.toString(),
                                  style: const TextStyle(
                                    color: ColorRes.whitePure,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 2,),
                                Container(
                                  width: 2,
                                  height: 15,
                                  decoration: BoxDecoration(
                                      color: whitePure(context),
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                ),
                                const SizedBox(width: 2,),

                                SvgPicture.asset("assets/svg_icons/audiopage/Voicecirclre.svg"),
                                Text(
                                  liveTeacher.rating.toString(),
                                  style: const TextStyle(
                                    color: ColorRes.whitePure,
                                    fontSize: 12,
                                  ),
                                ),
                              ]
                            ),

                            InkWell(
                              onTap: (){},
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                                decoration: BoxDecoration(
                                  color: blackPure(context),
                                  borderRadius: BorderRadius.circular(25)
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset("assets/svg_icons/audiopage/join.svg",height: 10,),
                                    const SizedBox(width: 5,),
                                    const Text("Join audio",style: TextStyle(color: ColorRes.whitePure,fontSize: 10),)
                                  ]
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
            ),
            ),
          );

        }
      ),
    );
  }
}
