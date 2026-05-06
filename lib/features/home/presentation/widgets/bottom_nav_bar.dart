import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String businessId;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'NotoNastaliqUrdu',
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'NotoNastaliqUrdu',
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: AppStrings.navHome,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: AppStrings.navCustomers,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: AppStrings.navSuppliers,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: AppStrings.navCashbook,
        ),
      ],
    );
  }
}
