import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/banner_model.dart';

class BannerCarousel extends StatefulWidget {
  final String type;
  const BannerCarousel({super.key, this.type = 'homepage'});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int currentIndex = 0;
  List<BannerData> banners = [];
  final Set<String> _brokenImageUrls = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final result = await CommonService.instance.fetchBanners(type: widget.type);
      if (result.status == true && result.data != null) {
        setState(() {
          banners = result.data!;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
      );
    }

    // Some banner rows point at images that no longer exist on the server —
    // skip those entirely instead of reserving blank space for them.
    final visibleBanners =
        banners.where((b) => !_brokenImageUrls.contains(b.imageUrl ?? '')).toList();
    if (visibleBanners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: visibleBanners.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              final url = visibleBanners[index].imageUrl ?? '';
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                    onError: (_, __) {
                      if (!_brokenImageUrls.contains(url)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _brokenImageUrls.add(url));
                        });
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            visibleBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: currentIndex == index ? 18 : 6,
              decoration: BoxDecoration(
                color: currentIndex == index ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
