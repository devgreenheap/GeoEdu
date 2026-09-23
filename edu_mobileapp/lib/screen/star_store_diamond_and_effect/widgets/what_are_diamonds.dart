import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/star_store/diamond_info_model.dart';
import 'package:geoedu/utilities/asset_res.dart';

class WhatAreDiamondBottom extends StatefulWidget {
  const WhatAreDiamondBottom({
    super.key,
  });

  @override
  State<WhatAreDiamondBottom> createState() => _WhatAreDiamondBottomState();
}

class _WhatAreDiamondBottomState extends State<WhatAreDiamondBottom> {
  List<DiamondInfoModel> infoList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    try {
      final data =
          await GiftWalletService.instance.fetchDiamondBuyingInformation();
      if (mounted) {
        setState(() {
          infoList = data;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Column(
                spacing: 5,
                children: [
                  Image.asset(
                    AssetRes.starstoreDiamond,
                    height: 45,
                    width: 45,
                  ),
                  const Text("What are Diamonds ?",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: Color(0xFFffc420),
                ),
              )
            else if (infoList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No information available',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: infoList.length,
                  itemBuilder: (context, index) {
                    final info = infoList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: mainSection(
                        color: Colors.yellow,
                        icon: Icons.diamond,
                        definition: info.information ?? '',
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            buyBtn(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buyBtn() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFffc420),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "Got it",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget mainSection({
    required IconData icon,
    required String definition,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2b2c2b),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Row(
          spacing: 10,
          children: [
            Icon(icon, color: color, size: 25),
            Expanded(
              child: Text(
                definition,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
