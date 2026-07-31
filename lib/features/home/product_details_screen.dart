import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/bread.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/freshness_badge.dart';
import '../../shared/utils/auth_gate.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final Bread bread;

  const ProductDetailsScreen({
    super.key,
    required this.bread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: SangakColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Image Area
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: SangakColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SangakColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      bread.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: bread.isFavorite ? SangakColors.error : SangakColors.ink,
                    ),
                    onPressed: () {
                      AuthGate.run(
                        context,
                        ref,
                        action: () {
                          // TODO: Implement favorite toggle
                        },
                        title: 'Save your favorites',
                        message: 'Create an account to save your favorite artisan breads.',
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'bread_${bread.id}',
                child: Image.network(
                  bread.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bread.freshness != null) ...[
                    FreshnessBadge(token: bread.freshness!),
                    const SizedBox(height: SangakDimens.spacing12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(bread.title, style: SangakTypography.h1),
                      ),
                      Text('₺${bread.price.toStringAsFixed(0)}', style: SangakTypography.h1.copyWith(color: SangakColors.primary)),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
                      const SizedBox(width: 4),
                      Text(bread.rating.toString(), style: SangakTypography.title.copyWith(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text('(${bread.reviews} reviews)', style: SangakTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: SangakDimens.spacing24),
                  Text('Description', style: SangakTypography.title),
                  const SizedBox(height: SangakDimens.spacing8),
                  Text(
                    bread.description,
                    style: SangakTypography.bodyLarge.copyWith(color: SangakColors.inkLight),
                  ),
                  const SizedBox(height: SangakDimens.spacing32),
                  
                  // Nutrition / Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(Icons.timer_outlined, '20 min'),
                      _buildInfoItem(Icons.local_fire_department_outlined, '250 kcal'),
                      _buildInfoItem(Icons.eco_outlined, 'Organic'),
                    ],
                  ),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        decoration: BoxDecoration(
          color: SangakColors.surface,
          boxShadow: SangakDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: SangakColors.background,
                borderRadius: BorderRadius.circular(SangakDimens.radiusM),
              ),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.remove)),
                  Text('1', style: SangakTypography.title),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                ],
              ),
            ),
            const SizedBox(width: SangakDimens.spacing16),
            Expanded(
              child: SangakButton.primary(
                label: 'Add to Cart',
                onPressed: () {
                  AuthGate.run(
                    context,
                    ref,
                    action: () {
                      // TODO: Implement cart logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${bread.title} added to basket!')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SangakColors.primary),
          const SizedBox(width: 8),
          Text(label, style: SangakTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
