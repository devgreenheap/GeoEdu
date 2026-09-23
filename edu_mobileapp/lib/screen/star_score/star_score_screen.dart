import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/screen/star_score/widgets/star_transaction_list.dart';
import 'package:geoedu/screen/star_score/widgets/stars_score_tabs.dart';


class StarScoreScreen extends StatefulWidget {
  const StarScoreScreen({super.key});

  @override
  State<StarScoreScreen> createState() => _StarScoreScreenState();
}

class _StarScoreScreenState extends State<StarScoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: kSecondaryHeaderGradient)),
          ),
          Column(
            children: [
              CustomAppBar(title: "Star Score", iconColor: Colors.white),
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      const StarScoreTabs(),
                      const Expanded(
                        child: TabBarView(children: [
                          StarTransactionList(type: 'all'),
                          StarTransactionList(type: 'video'),
                          StarTransactionList(type: 'audio'),
                          StarTransactionList(type: 'chat'),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
