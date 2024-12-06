import 'package:flutter/material.dart';
import 'package:video_tape_store/Models/VideoTape.dart';
import 'package:video_tape_store/Pages/Product/VideoTapeDetail.dart';
import 'package:video_tape_store/Pages/Utils/Constants.dart';
import 'package:video_tape_store/Pages/Cart/CartPage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _carouselIndex = 0;
  final _searchController = TextEditingController();
  bool _isLoading = true;
  final List<CartItem> cartItems = [];
  List<VideoTape> _videoTapes = [];

  // final List<VideoTape> _featuredTapes = [
  // VideoTape(
  //   id: '1',
  //   title: 'Jurassic Park',
  //   price: 100.00,
  //   description:
  //       'Experience the thrill of dinosaurs in this classic masterpiece.',
  //   genreId: '1',
  //   genreName: 'Sci-Fi',
  //   level: 1,
  //   imageUrls: [
  //     'https://picsum.photos/400/300?random=1',
  //     'https://picsum.photos/400/300?random=2',
  //     'https://picsum.photos/400/300?random=3',
  //   ],
  //   releasedDate: DateTime(1993),
  //   stockQuantity: 5,
  //   rating: 4.8,
  //   totalReviews: 2453,
  // ),
  // ];

  List<VideoTape> get _filteredTapes {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _videoTapes;

    return _videoTapes.where((tape) {
      return tape.title.toLowerCase().contains(query) ||
          tape.description.toLowerCase().contains(query) ||
          tape.genreName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("http://localhost:3000/api/videotapes");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _videoTapes = data.map((video) => VideoTape.fromJson(video)).toList();
        });
      } else {
        throw Exception("Failed to load video tapes");
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  _buildSearchBar(),
                  SliverToBoxAdapter(
                    child: _buildFeaturedCarousel(),
                  ),
                  _buildSectionHeader('Tapes Catalog'),
                  _buildVideoTapeGrid(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        AppStrings.appName,
        style: AppTextStyles.headingMedium,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartPage(cartItems: cartItems),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      sliver: SliverToBoxAdapter(
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search video tapes...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surfaceColor,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    if (_videoTapes.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        child: const Center(
          child: Text('No videos available'),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.8,
            enlargeCenterPage: true,
            autoPlay: _videoTapes.length > 1,
            onPageChanged: (index, reason) {
              setState(() => _carouselIndex = index);
            },
          ),
          items: _videoTapes.map((tape) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusMedium),
                    image: DecorationImage(
                      image: Image.network(
                        tape.imageUrls.first,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surfaceColor,
                            child: const Icon(Icons.error),
                          );
                        },
                      ).image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tape.title,
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: AppDimensions.marginSmall),
                        Row(
                          children: [
                            Text(
                              '\$${tape.price.toStringAsFixed(2)}',
                              style: AppTextStyles.priceText,
                            ),
                            const Spacer(),
                            if (tape.rating > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tape.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        if (_videoTapes.length > 1)
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.marginSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _videoTapes.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _carouselIndex == entry.key
                        ? AppColors.primaryColor
                        : AppColors.surfaceColor,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.headingSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTapeGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.5,
          crossAxisSpacing: AppDimensions.marginMedium,
          mainAxisSpacing: AppDimensions.marginMedium,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tape = _filteredTapes[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: InkWell(
                      onTap: () => _navigateToDetail(tape),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top:
                              Radius.circular(AppDimensions.borderRadiusMedium),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              tape.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tape.genreName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tape.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${tape.price.toStringAsFixed(2)}',
                                style: AppTextStyles.priceText,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    tape.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _addToCart(tape),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successColor,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _filteredTapes.length,
        ),
      ),
    );
  }

  void _addToCart(VideoTape tape) {
    setState(() {
      cartItems.add(CartItem(tape: tape));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tape.title} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(cartItems: cartItems),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetail(VideoTape tape) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoTapeDetailPage(
          tape: tape,
          cartItems: cartItems,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
