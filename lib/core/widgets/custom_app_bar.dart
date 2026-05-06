import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final bool showDrawer;
  final VoidCallback? onDrawerPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.showDrawer = false,
    this.onDrawerPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : showDrawer
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed:
                  onDrawerPressed ?? () => Scaffold.of(context).openDrawer(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
