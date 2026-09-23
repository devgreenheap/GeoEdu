import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/diamond_purchase/diamond_wallet_model.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/what_are_diamonds.dart';

import '../../../model/star_store/diamond_pack_model.dart';
import '../../../utilities/color_res.dart';
import '../../star_score/widgets/diamond_purchase_bottom.dart';

class DiamondStore extends StatefulWidget {
  const DiamondStore({super.key});

  @override
  State<DiamondStore> createState() => _DiamondStoreState();
}

class _DiamondStoreState extends State<DiamondStore> {
  List<DiamondPackModel> diamondPacks = [];
  bool isLoading = true;
  int diamondBalance = 0;

  @override
  void initState() {
    super.initState();
    fetchDiamondPackages();
    fetchDiamondWallet();
  }

  Future<void> fetchDiamondPackages() async {
    try {
      final result = await GiftWalletService.instance.fetchDiamondPackages();
      setState(() {
        diamondPacks = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchDiamondWallet() async {
    try {
      final result = await GiftWalletService.instance.fetchMyDiamondWallet();
      Loggers.info('Diamond wallet response: status=${result.status}, data=${result.data}');
      if (result.data != null) {
        setState(() {
          diamondBalance = result.data!.diamondBalance ?? 0;
        });
      }
    } catch (e) {
      Loggers.error('fetchDiamondWallet error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorRes.gold, ColorRes.green],
            )
          ),
          child: Row(
            spacing: 15,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/images/gold_diamond.png",width: 60,height: 60),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$diamondBalance",style: const TextStyle(fontSize: 20,color: Colors.white),),
                  const Text("Your Balance",style: TextStyle(fontSize: 15,color: Colors.white),)
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 10,),
        InkWell(
          onTap: (){
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              barrierColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              builder: (context)=> const WhatAreDiamondBottom()
            );
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [ColorRes.gold, ColorRes.green],
              ),
            ),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorRes.cardBackground,
          ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("What are Diamonds ?",
                  style: TextStyle(fontSize: 16,color: Colors.white),
                ),Text(">",
                  style: TextStyle(fontSize: 16,color: Colors.white),
                ),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 15,),
        Row(
          children: [
            Image.asset('assets/icons/yellow-dimond.png',height: 16,),const SizedBox(width: 5,),
            const Text("Buy Diamond",style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w600),),
          ],
        ),
        const SizedBox(height: 10,),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: ColorRes.primaryColor),
            ),
          )
        else if (diamondPacks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No packages available", style: TextStyle(color: Colors.white70)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12),
            itemCount: diamondPacks.length,
            itemBuilder: (context, index) {
              final diamondPack = diamondPacks[index];
              final originalPrice = diamondPack.originalPrice ?? 0;
              final discountedPrice = diamondPack.discountedPrice ?? 0;
              final int percentOff = originalPrice > 0
                  ? (((originalPrice - discountedPrice) / originalPrice) * 100).round().clamp(0, 99)
                  : 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 22),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: (){
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          barrierColor: Colors.transparent,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DiamondPurchaseBottom(
                            diamonds: '${diamondPack.diamonds ?? 0}',
                            offerPrice: '${diamondPack.discountedPrice ?? 0}',
                            price: '${diamondPack.originalPrice ?? 0}',
                            diamondPackId: diamondPack.id,
                            onPurchaseSuccess: fetchDiamondWallet,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: ColorRes.cardBackground,
                          border: Border.all(
                            color: ColorRes.green1.withValues(alpha: .55),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                diamondPack.image != null && diamondPack.image!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: diamondPack.image!.addBaseURL(),
                                        width: 34,
                                        height: 34,
                                        fit: BoxFit.contain,
                                        placeholder: (_, __) => Image.asset("assets/images/gold_diamond.png", width: 34, height: 34),
                                        errorWidget: (_, __, ___) => Image.asset("assets/images/gold_diamond.png", width: 34, height: 34),
                                      )
                                    : Image.asset("assets/images/gold_diamond.png", width: 34, height: 34),
                                Text("${diamondPack.diamonds ?? 0}",
                                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [ColorRes.primaryColor, ColorRes.orangeDark],
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 6,
                                children: [
                                  const Text("Buy for",style: TextStyle(fontSize: 12,color: Colors.white70, fontWeight: FontWeight.w500),),
                                  if (percentOff > 0)
                                    Text("₹${originalPrice.toInt()}",style: const TextStyle(fontSize: 12,color: Colors.white54,decoration: TextDecoration.lineThrough,),),
                                  Text("₹${discountedPrice.toInt()}",style: const TextStyle(fontSize: 14,color: Colors.white, fontWeight: FontWeight.w700),),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    if (percentOff > 0)
                      Positioned(
                        top: -12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorRes.gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$percentOff% Off",
                            style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
          ),
        const Center(
          child: Text("Trusted by 10 Crore+ Indians 🇮🇳",style: TextStyle(fontSize: 14,color: Colors.white),),
        )
      ],
    );
  }
}
