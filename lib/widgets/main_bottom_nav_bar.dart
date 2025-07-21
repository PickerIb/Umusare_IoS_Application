import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_service.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const MainBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/products');
                break;
              case 2:
                context.go('/messenger');
                break;
              case 3:
                context.go('/cart');
                break;
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_rounded),
              label: 'Products',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded),
              label: 'Messenger',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
} 