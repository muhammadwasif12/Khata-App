import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../stock/domain/entities/product_entity.dart';

class StockSelectionScreen extends StatefulWidget {
  final List<ProductEntity> products;

  const StockSelectionScreen({super.key, required this.products});

  @override
  State<StockSelectionScreen> createState() => _StockSelectionScreenState();
}

class _StockSelectionScreenState extends State<StockSelectionScreen> {
  final List<ProductEntity> _selectedProducts = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'اسٹاک سے منتخب کریں',
          style: TextStyle(
            fontFamily: AppTextStyles.urduFont,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'پروڈکٹ تلاش کریں...',
                hintStyle: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'کوئی پروڈکٹ نہیں ملی',
                      style: TextStyle(
                        fontFamily: AppTextStyles.urduFont,
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isSelected = _selectedProducts.contains(product);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedProducts.remove(product);
                              } else {
                                _selectedProducts.add(product);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedProducts.add(product);
                                      } else {
                                        _selectedProducts.remove(product);
                                      }
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.urduFont,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'قیمت: ${CurrencyFormatter.formatAmount(product.salePrice)} | موجود: ${product.currentStock} ${product.unit}',
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.urduFont,
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedProducts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, _selectedProducts);
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                '${_selectedProducts.length} منتخب کریں',
                style: const TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
