import 'package:flutter/material.dart';
import 'package:video_tape_store/Pages/Utils/Constants.dart';
import 'package:video_tape_store/Models/VideoTape.dart';

class CartItem {
  final VideoTape tape;
  int quantity;

  CartItem({
    required this.tape,
    this.quantity = 1,
  });
}

class CartPage extends StatefulWidget {
  final List<CartItem>? cartItems;

  const CartPage({
    super.key,
    this.cartItems,
  });

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  bool isLoading = false;
  late List<CartItem> shoppingCartItems;

  double get totalPrice => shoppingCartItems.fold(
        0,
        (sum, item) => sum + (item.tape.price * item.quantity),
      );

  @override
  void initState() {
    super.initState();
    shoppingCartItems = widget.cartItems ?? [];
  }

  void updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        shoppingCartItems[index].quantity = newQuantity;
      } else {
        shoppingCartItems.removeAt(index);
      }
    });
  }

  Future<void> processCheckout() async {
    if (shoppingCartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: AppColors.successColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your purchase was successful',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      setState(() {
        shoppingCartItems.clear();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process purchase. Please try again.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Shopping Cart',
          style: AppTextStyles.headingMedium,
        ),
      ),
      body: shoppingCartItems.isEmpty ? buildEmptyCart() : buildCartContent(),
      bottomNavigationBar:
          shoppingCartItems.isEmpty ? null : buildCheckoutBar(),
    );
  }

  Widget buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: AppDimensions.iconSizeLarge * 2,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          const Text(
            'Your cart is empty',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          const Text(
            'Add some video tapes to get started!',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
            ),
            child: const Text(
              'Browse Video Tapes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCartContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: shoppingCartItems.length,
      itemBuilder: (context, index) {
        final item = shoppingCartItems[index];
        return buildCartItem(item, index);
      },
    );
  }

  Widget buildCartItem(CartItem item, int index) {
    return Dismissible(
      key: Key(item.tape.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.paddingMedium),
        color: AppColors.errorColor,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        setState(() => shoppingCartItems.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.tape.title} removed from cart'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() => shoppingCartItems.insert(index, item));
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
                child: Image.network(
                  item.tape.imageUrls.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppDimensions.marginMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tape.title,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.marginSmall),
                    Text(
                      '\$${item.tape.price.toStringAsFixed(2)}',
                      style: AppTextStyles.priceText,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => updateQuantity(index, item.quantity + 1),
                  ),
                  Text(
                    '${item.quantity}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => updateQuantity(index, item.quantity - 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusMedium),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total:',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: AppTextStyles.headingMedium,
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.marginMedium),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
