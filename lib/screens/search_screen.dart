import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/product_model.dart';
import 'package:glow_beauty_store/providers/products_provider.dart';
import 'package:glow_beauty_store/widgets/common/brand_mark.dart';
import 'package:glow_beauty_store/widgets/products/product_widget.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class SearchScreen extends StatefulWidget {
  static const routeName = "/SearchScreen";
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController searchTextController;
  List<ProductModel> productListSearch = [];
  bool _isFetchingProducts = false;
  String _selectedCategory = 'all';
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    searchTextController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProductsLoaded();
    });
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  Future<void> _ensureProductsLoaded({bool forceRefresh = false}) async {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    if (!forceRefresh &&
        (productsProvider.products.isNotEmpty || productsProvider.isLoading)) {
      return;
    }
    if (mounted) {
      setState(() {
        _isFetchingProducts = true;
      });
    }
    try {
      await productsProvider.fetchProducts(forceRefresh: forceRefresh);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingProducts = false;
        });
      }
    }
  }

  void _applySearch(
    ProductsProvider productsProvider,
    List<ProductModel> productList,
    String value,
  ) {
    setState(() {
      productListSearch = productsProvider.searchQuery(
        searchText: value,
        passedList: productList,
      );
    });
  }

  List<ProductModel> _visibleProducts(List<ProductModel> source) {
    final filtered = source.where((product) {
      if (_selectedCategory == 'all') {
        return true;
      }
      return product.productCategory.toLowerCase() ==
          _selectedCategory.toLowerCase();
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'priceLow':
          return a.priceValue.compareTo(b.priceValue);
        case 'priceHigh':
          return b.priceValue.compareTo(a.priceValue);
        case 'nameAz':
          return a.productTitle
              .toLowerCase()
              .compareTo(b.productTitle.toLowerCase());
        case 'stock':
          return b.quantityValue.compareTo(a.quantityValue);
        case 'newest':
        default:
          final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return bMillis.compareTo(aMillis);
      }
    });

    return filtered;
  }

  List<String> _availableCategories(List<ProductModel> products) {
    final categories = products
        .map((product) => product.productCategory.trim().toLowerCase())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort(
          (a, b) => _formatCategoryLabel(a).compareTo(_formatCategoryLabel(b)));
    return ['all', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    final passedCategory =
        routeArgument is String && routeArgument.trim().isNotEmpty
            ? routeArgument
            : null;
    final categoryLabel =
        passedCategory == null ? null : _formatCategoryLabel(passedCategory);
    final productList = passedCategory == null
        ? productsProvider.products
        : productsProvider.findByCategory(categoryName: passedCategory);
    final isSearching = searchTextController.text.trim().isNotEmpty;
    final activeList =
        _visibleProducts(isSearching ? productListSearch : productList);
    final availableCategories = _availableCategories(productList);
    final isCatalogLoading = productList.isEmpty &&
        (productsProvider.isLoading || _isFetchingProducts);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          leadingWidth: 72,
          leading: const Padding(
            padding: EdgeInsets.all(10),
            child: BrandMark(size: 52),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TitelesTextWidget(
                label: passedCategory ?? "Search Products",
                fontSize: 18,
              ),
              SubtitleTextWidget(
                label: passedCategory == null
                    ? "Find skincare, fragrance and makeup favorites"
                    : "Browsing category: $categoryLabel",
                fontSize: 12,
              ),
            ],
          ),
        ),
        body: isCatalogLoading
            ? const _SearchLoadingCatalog()
            : productList.isEmpty
                ? RefreshIndicator(
                    color: AppColors.darkPrimary,
                    onRefresh: () => _ensureProductsLoaded(forceRefresh: true),
                    child: _SearchEmptyCatalog(
                      message: productsProvider.errorMessage,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.darkPrimary,
                    onRefresh: () => _ensureProductsLoaded(forceRefresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xffffeff6),
                                Color(0xfff6e7f7),
                                Color(0xfffffbfd),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SubtitleTextWidget(
                                label: passedCategory == null
                                    ? "DISCOVER"
                                    : "CATEGORY",
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkPrimary,
                              ),
                              const SizedBox(height: 10),
                              TitelesTextWidget(
                                label: passedCategory == null
                                    ? "Search by product, brand or category."
                                    : "Explore everything under $categoryLabel.",
                                fontSize: 26,
                              ),
                              const SizedBox(height: 10),
                              const SubtitleTextWidget(
                                label:
                                    "Search the catalog, filter categories and sort products by the details that matter.",
                                fontSize: 14,
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: searchTextController,
                                decoration: InputDecoration(
                                  hintText: "Search beauty, brand or category",
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      FocusScope.of(context).unfocus();
                                      searchTextController.clear();
                                      _applySearch(
                                          productsProvider, productList, '');
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.darkPrimary,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  _applySearch(
                                      productsProvider, productList, value);
                                },
                                onSubmitted: (value) async {
                                  _applySearch(
                                      productsProvider, productList, value);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SearchControlsBlock(
                          categories: availableCategories,
                          selectedCategory: _selectedCategory,
                          selectedSort: _selectedSort,
                          onCategoryChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          onSortChanged: (value) {
                            setState(() {
                              _selectedSort = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _SearchResultHeader(
                          title: isSearching
                              ? '"${searchTextController.text.trim()}"'
                              : 'Catalog results',
                          subtitle:
                              '${activeList.length} products after filters',
                        ),
                        const SizedBox(height: 12),
                        if (activeList.isEmpty)
                          const _SearchNoResultsState()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeList.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.58,
                            ),
                            itemBuilder: (context, index) {
                              return ProductWidget(
                                productId: activeList[index].productId,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

String _formatCategoryLabel(String value) {
  const labels = {
    'beauty': 'Makeup',
    'makeup': 'Makeup',
    'face-care': 'Care',
    'care': 'Care',
    'skincare': 'Care',
    'skin-care': 'Care',
    'body-care': 'Body Care',
    'hair-care': 'Hair Care',
    'nails': 'Nails',
    'fragrance': 'Fragrance',
    'fragrances': 'Fragrance',
    'perfume': 'Perfume',
    'accessories': 'Accessories',
    'sun-care': 'Sun Care',
    'dermocosmetics': 'Dermocosmetics',
    'natural': 'Natural',
    'wellness': 'Wellness',
    'devices': 'Devices',
    'oral-care': 'Oral Care',
    'shaving': 'Shaving',
    'gifts': 'Gifts',
    'luxury': 'Luxury',
    'womens-jewellery': 'Jewelry',
    'sunglasses': 'Sunglasses',
    'womens-bags': 'Bags',
    'newarrivals': 'New Arrivals',
    'bestsellers': 'Best Sellers',
  };
  return labels[value.toLowerCase()] ?? value;
}

class _SearchControlsBlock extends StatelessWidget {
  const _SearchControlsBlock({
    required this.categories,
    required this.selectedCategory,
    required this.selectedSort,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final String selectedSort;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSortChanged;

  static const _sortLabels = <String, String>{
    'newest': 'Newest',
    'priceLow': 'Price: low to high',
    'priceHigh': 'Price: high to low',
    'nameAz': 'Name A-Z',
    'stock': 'Stock',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitelesTextWidget(label: "Filter and sort", fontSize: 18),
                    SizedBox(height: 4),
                    SubtitleTextWidget(
                      label: "Narrow products by category and order",
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: selectedSort,
                underline: const SizedBox.shrink(),
                items: _sortLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onSortChanged(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map(
                  (category) => ChoiceChip(
                    selected: category == selectedCategory,
                    selectedColor: AppColors.lightPrimary,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    side: BorderSide.none,
                    label: SubtitleTextWidget(
                      label: category == 'all'
                          ? 'All'
                          : _formatCategoryLabel(category),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: category == selectedCategory
                          ? AppColors.darkPrimary
                          : null,
                    ),
                    onSelected: (_) => onCategoryChanged(category),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResultHeader extends StatelessWidget {
  const _SearchResultHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.darkPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitelesTextWidget(
                  label: title,
                  fontSize: 17,
                ),
                const SizedBox(height: 3),
                SubtitleTextWidget(
                  label: subtitle,
                  fontSize: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchNoResultsState extends StatelessWidget {
  const _SearchNoResultsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.darkPrimary,
          ),
          SizedBox(height: 14),
          TitelesTextWidget(
            label: "No products found",
            fontSize: 22,
          ),
          SizedBox(height: 8),
          SubtitleTextWidget(
            label:
                "Try a broader keyword, another brand name or switch to a different category.",
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}

class _SearchLoadingCatalog extends StatelessWidget {
  const _SearchLoadingCatalog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.darkPrimary,
      ),
    );
  }
}

class _SearchEmptyCatalog extends StatelessWidget {
  const _SearchEmptyCatalog({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.darkPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  size: 50,
                  color: AppColors.darkPrimary,
                ),
              ),
              const SizedBox(height: 18),
              const TitelesTextWidget(
                label: "Catalog unavailable",
                fontSize: 24,
              ),
              const SizedBox(height: 8),
              SubtitleTextWidget(
                label: message == null || message!.trim().isEmpty
                    ? "Products are not available right now. Pull down to refresh after the catalog loads."
                    : message!,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
