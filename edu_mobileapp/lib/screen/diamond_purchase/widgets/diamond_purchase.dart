import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/utilities/theme_res.dart';

import '../../../model/diamond_purchase/diamond_purchase_model.dart';
import '../../../utilities/asset_res.dart';

class DiamondPurchase extends StatefulWidget {
  const DiamondPurchase({super.key});

  @override
  State<DiamondPurchase> createState() => _DiamondPurchaseState();
}

class _DiamondPurchaseState extends State<DiamondPurchase> {
  List<DiamondTransactionModel> diamondTransactions = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int? lastItemId;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _fetchTransactions(loadMore: true);
    }
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        diamondTransactions.clear();
        lastItemId = null;
        hasMore = true;
      });
    }

    try {
      final results = await GiftWalletService.instance
          .fetchDiamondTransactions(lastItemId: lastItemId);
      setState(() {
        diamondTransactions.addAll(results);
        if (results.isNotEmpty) {
          lastItemId = results.last.id;
        }
        if (results.isEmpty) {
          hasMore = false;
        }
      });
    } catch (_) {}

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (diamondTransactions.isEmpty) {
      return const Center(
          child: Text('No purchase history',
              style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: diamondTransactions.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == diamondTransactions.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          final purchase = diamondTransactions[index];
          return Container(
            padding: const EdgeInsets.all(4),
            color: Colors.transparent,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff5C24B7), Color(0xff36404E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${purchase.title}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          Row(
                            children: [
                              Text("+ ${purchase.diamonds}",
                                  style: const TextStyle(
                                      color: Color(0xFFB6FF52))),
                              Image.asset(AssetRes.coinIcon,
                                  width: 20, height: 20)
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        spacing: 10,
                        children: [
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.date,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: whitePure(context))),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  width: 3,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: whitePure(context),
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ]),
                          ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.time,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: whitePure(context))),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  width: 3,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: whitePure(context),
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ]),
                          ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.transactionId,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: whitePure(context))),
                            ]),
                          ),
                          const SizedBox(width: 15),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: purchase.currency ?? '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10)),
                              const WidgetSpan(child: SizedBox(width: 5)),
                              TextSpan(
                                  text: '${purchase.amount ?? 0}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10)),
                            ]),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0xff260063),
                      Color(0xff38547D),
                    ]),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionItem(icon: AssetRes.help, title: "Get Help"),
                      _actionItem(icon: AssetRes.download, title: "Download"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }
}

Widget _actionItem({required String icon, required String title}) {
  return Row(
    children: [
      Image.asset(icon, height: 20, width: 20),
      const SizedBox(width: 6),
      Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}
