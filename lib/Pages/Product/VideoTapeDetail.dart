import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_tape_store/Models/VideoTape.dart';
import 'package:video_tape_store/Pages/Cart/CartPage.dart';
import 'package:video_tape_store/Pages/Utils/Constants.dart';

class VideoTapeDetailPage extends StatefulWidget {
  final VideoTape tape;
  final List<CartItem> cartItems;

  const VideoTapeDetailPage({
    super.key,
    required this.tape,
    required this.cartItems,
  });

  @override
  State<VideoTapeDetailPage> createState() => VideoTapeDetailPageState();
}

class VideoTapeDetailPageState extends State<VideoTapeDetailPage> {
  int selectedImageIndex = 0;
  bool isAddingToCart = false;
  final CarouselSliderController carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          buildImageCarousel(),
          buildProductDetails(),
        ],
      ),
      bottomNavigationBar: buildAddToCartButton(),
    );
  }

  Widget buildImageCarousel() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            buildCarouselSlider(),
            buildCarouselIndicators(),
          ],
        ),
      ),
    );
  }

  Widget buildCarouselSlider() {
    return CarouselSlider(
      carouselController: carouselController,
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        onPageChanged: (index, reason) {
          setState(() {
            selectedImageIndex = index;
          });
        },
      ),
      items: widget.tape.imageUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Image.network(url, fit: BoxFit.cover);
          },
        );
      }).toList(),
    );
  }

  Widget buildCarouselIndicators() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.tape.imageUrls.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () => carouselController.animateToPage(entry.key),
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectedImageIndex == entry.key
                    ? AppColors.primaryColor
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildProductDetails() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(widget.tape.title, style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.marginMedium),
          Text('\$${widget.tape.price.toStringAsFixed(2)}',
              style: AppTextStyles.priceText),
          const SizedBox(height: AppDimensions.marginMedium),
          buildProductMetadata(),
          const SizedBox(height: AppDimensions.marginLarge),
          buildDescriptionSection(),
        ]),
      ),
    );
  }

  // Update buildProductMetadata to include level
  Widget buildProductMetadata() {
    return Row(
      children: [
        buildGenreTag(),
        const SizedBox(width: AppDimensions.marginMedium),
        buildLevelTag(), // Add level tag
        const SizedBox(width: AppDimensions.marginMedium),
        buildRatingInfo(),
      ],
    );
  }

  Widget buildGenreTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        widget.tape.genreName,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryColor),
      ),
    );
  }

  // Add new method for level tag
  Widget buildLevelTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Text(
        VideoLevel.values[widget.tape.level].displayName,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
      ),
    );
  }

  // Update buildRatingInfo to only show rating
  Widget buildRatingInfo() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(widget.tape.rating.toStringAsFixed(1),
            style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppDimensions.marginSmall),
        Text(widget.tape.description, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppDimensions.marginLarge),
      ],
    );
  }

  Widget buildAddToCartButton() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isAddingToCart ? null : handleAddToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMedium,
            ),
            minimumSize: const Size.fromHeight(48),
          ),
          child: isAddingToCart
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  void handleAddToCart() {
    setState(() => isAddingToCart = true);
    widget.cartItems.add(CartItem(tape: widget.tape));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => isAddingToCart = false);
        showAddToCartSnackBar();
      }
    });
  }

  void showAddToCartSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.tape.title} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(cartItems: widget.cartItems),
              ),
            );
          },
        ),
      ),
    );
  }
}