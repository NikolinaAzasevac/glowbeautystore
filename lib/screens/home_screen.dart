import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/consts/app_constants.dart';
import 'package:glow_beauty_store/models/product_model.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/screens/search_screen.dart';
import 'package:glow_beauty_store/widgets/common/brand_mark.dart';
import 'package:glow_beauty_store/widgets/products/ctg_rounded_widget.dart';
import 'package:glow_beauty_store/widgets/products/latest_arrival.dart';
import 'package:glow_beauty_store/widgets/products/product_widget.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final productProvider = Provider.of<ProductsProvider>(context);
    final usedProductIds = <String>{};
    final featuredProducts = _pickDistinctSection(
      source: productProvider.featuredProducts,
      usedProductIds: usedProductIds,
      limit: 6,
    );
    final trendingProducts = _pickDistinctSection(
      source: productProvider.trendingProducts,
      usedProductIds: usedProductIds,
      limit: 6,
    );
    final topRatedProducts = _pickDistinctSection(
      source: productProvider.bestSellerProducts,
      usedProductIds: usedProductIds,
      limit: 4,
    );
    final recommendedProducts = _pickDistinctSection(
      source: productProvider.recommendedProducts,
      usedProductIds: usedProductIds,
      limit: 4,
    );
    final newArrivalProducts = _pickDistinctSection(
      source: productProvider.newArrivalProducts,
      usedProductIds: usedProductIds,
      limit: 6,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.all(14.0),
          child: BrandMark(size: 48),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TitelesTextWidget(
              label: "Glow Beauty Store",
              fontSize: 18,
            ),
            SubtitleTextWidget(
              label: "Curated beauty for every day",
              fontSize: 12,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, SearchScreen.routeName);
              },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
              ),
              icon: const Icon(Icons.search_rounded),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.darkPrimary,
        onRefresh: () => productProvider.fetchProducts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xffffeff6),
                      Color(0xfff6e6f7),
                      Color(0xfffef8fb),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 30,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubtitleTextWidget(
                      label: "THIS WEEK'S PICKS",
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPrimary,
                    ),
                    const SizedBox(height: 10),
                    const TitelesTextWidget(
                      label: "Beauty essentials for a polished daily routine.",
                      fontSize: 28,
                    ),
                    const SizedBox(height: 10),
                    const SubtitleTextWidget(
                      label:
                          "Discover trending skincare, makeup favorites and refined fragrance picks curated for your everyday glow.",
                      fontSize: 14,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                                context, SearchScreen.routeName);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          child: const Text("Shop now"),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SubtitleTextWidget(
                            label:
                                "${productProvider.getProducts.length}+ products",
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: size.height * 0.23,
                child: Swiper(
                  autoplay: true,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _BannerImage(
                              imagePath: AppConstants.bannersImages[index],
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.45),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 18,
                              right: 18,
                              bottom: 18,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TitelesTextWidget(
                                    label: "New beauty highlights",
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                  SizedBox(height: 6),
                                  SubtitleTextWidget(
                                    label:
                                        "Discover fresh launches, skincare rituals and signature scent moments.",
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: AppConstants.bannersImages.length,
                  pagination: const SwiperPagination(
                    builder: DotSwiperPaginationBuilder(
                      activeColor: AppColors.darkPrimary,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const _SectionHeader(
                title: "Categories",
                subtitle: "Shop by category",
                topPadding: 26,
              ),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 84,
                      child: CategoryRoundedWidget(
                        name: AppConstants.categoriesList[index].name,
                        categoryId: AppConstants.categoriesList[index].id,
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: AppConstants.categoriesList.length,
                ),
              ),
              _buildHorizontalSection(
                context: context,
                title: "Featured Products",
                subtitle: "Editor-approved favorites",
                products: featuredProducts,
              ),
              _buildHorizontalSection(
                context: context,
                title: "Trending Now",
                subtitle: "Selected products from the catalog",
                products: trendingProducts,
                compact: true,
              ),
              _buildGridSection(
                title: "Top Rated",
                subtitle: "Based on customer reviews",
                products: topRatedProducts,
              ),
              _buildGridSection(
                title: "Recommended For You",
                subtitle: "A balanced mix from each category",
                products: recommendedProducts,
              ),
              _buildHorizontalSection(
                context: context,
                title: "New Arrivals",
                subtitle: "Fresh launches worth exploring",
                products: newArrivalProducts,
                compact: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<ProductModel> products,
    bool compact = false,
  }) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        SizedBox(
          height: compact ? 204 : 286,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ChangeNotifierProvider.value(
                value: products[index],
                child: compact
                    ? const LatestArrivalProductsWidget()
                    : SizedBox(
                        width: MediaQuery.of(context).size.width * 0.56,
                        child:
                            ProductWidget(productId: products[index].productId),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<ProductModel> _pickDistinctSection({
    required List<ProductModel> source,
    required Set<String> usedProductIds,
    required int limit,
  }) {
    final picked = <ProductModel>[];
    for (final product in source) {
      if (usedProductIds.contains(product.productId)) {
        continue;
      }
      picked.add(product);
      usedProductIds.add(product.productId);
      if (picked.length == limit) {
        break;
      }
    }
    return picked;
  }

  Widget _buildGridSection({
    required String title,
    required String subtitle,
    required List<ProductModel> products,
  }) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: subtitle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length > 4 ? 4 : products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                return ProductWidget(productId: products[index].productId);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            color: const Color(0xffffeff6),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: AppColors.darkPrimary,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xffffeff6),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.darkPrimary,
          ),
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.topPadding = 20,
  });

  final String title;
  final String subtitle;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitelesTextWidget(
            label: title,
            fontSize: 22,
          ),
          const SizedBox(height: 4),
          SubtitleTextWidget(
            label: subtitle,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}
