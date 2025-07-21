import 'package:flutter/material.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import '../../widgets/cart_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Your Cart',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review your selected items and proceed to checkout.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: CartWidget(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 3),
    );
  }
} 