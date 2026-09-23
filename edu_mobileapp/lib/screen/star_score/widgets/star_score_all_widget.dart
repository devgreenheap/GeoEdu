import 'package:flutter/material.dart';
import 'package:geoedu/model/star_score/star_score_model.dart';
import 'package:geoedu/utilities/asset_res.dart';


class StarScoreAllWidget extends StatefulWidget {
  const StarScoreAllWidget({super.key});

  @override
  State<StarScoreAllWidget> createState() => _StarScoreAllWidgetState();
}

class _StarScoreAllWidgetState extends State<StarScoreAllWidget> {

  List<StarScoreModel> dummyActivities = [
    StarScoreModel(
      title: "Chat",
      time: "12:48 PM",
      date: "06/02/26",
      transactionId: "...41b91",
      points: 20,
      rewardIcon: "star",
    ),
    StarScoreModel(
      title: "Live Room Hosting",
      time: "10:15 AM",
      date: "05/02/26",
      transactionId: "...82a73",
      points: 50,
      rewardIcon: "star",
    ),
    StarScoreModel(
      title: "Chat",
      time: "09:00 AM",
      date: "05/02/26",
      transactionId: "...19c44",
      points: 10,
      rewardIcon: "star",
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return ListView.separated(itemBuilder: (context,index){
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [
            Color(0xFF5C24B7),
            Color(0xFF36404E),
          ])
        ),
        child: Column(
          spacing: 5,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dummyActivities[index].title,style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold),),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "+ ${dummyActivities[index].points} ",
                        style: const TextStyle(
                          color: Color(0xFFB6FF52),
                          fontSize: 14,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Image.asset(
                          AssetRes.starScoreStar,
                          height: 12,
                          width: 12,
                        ),
                      ),
                    ],
                  ),
                )

              ]
            ),
            Row(
              spacing: 5,
              children: [
                Text(dummyActivities[index].time,style: TextStyle(color: Colors.white,fontSize: 14),),
                Circle(),
                Text(dummyActivities[index].date,style: TextStyle(color: Colors.white,fontSize: 14),),
                Circle(),
                Text(dummyActivities[index].transactionId,style: TextStyle(color: Colors.white,fontSize: 14),),
              ],
            )
          ],
        ),
      );
    }, separatorBuilder: (context,index)=>const SizedBox(height: 10,), itemCount: dummyActivities.length);
  }
  Widget Circle()
  {
    return Container(
      height: 5,
      width: 5,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
