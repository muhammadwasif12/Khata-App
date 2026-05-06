import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/business_provider.dart';

class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(businessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myBusinesses),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: businessesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.noBusiness,
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.noBusinessDesc,
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              final isActive =
                  ref.watch(activeBusinessIdProvider) == business.id;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      business.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'NotoNastaliqUrdu',
                      ),
                    ),
                  ),
                  title: Text(
                    business.name,
                    style: const TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    business.type,
                    style: const TextStyle(fontFamily: 'NotoNastaliqUrdu'),
                  ),
                  trailing: isActive
                      ? const Chip(
                          label: Text(
                            'فعال',
                            style: TextStyle(
                              fontFamily: 'NotoNastaliqUrdu',
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: AppColors.primarySurface,
                        )
                      : null,
                  onTap: () async {
                    await ref
                        .read(businessesProvider.notifier)
                        .setActiveBusinessId(business.id);
                    ref.read(activeBusinessIdProvider.notifier).state =
                        business.id;
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/businesses/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
