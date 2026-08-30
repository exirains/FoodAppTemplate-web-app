import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../core/design_system/babka_tokens.dart';
import '../../shared/widgets/babka_button.dart';
import '../../shared/widgets/babka_text_field.dart';
import '../../shared/widgets/freshness_badge.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/hero_banner.dart';
import '../../shared/widgets/category_chip.dart';

class DesignSystemGalleryScreen extends StatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  State<DesignSystemGalleryScreen> createState() => _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState extends State<DesignSystemGalleryScreen> {
  int _productQuantity = 0;
  bool _isFavorite = false;
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Babka Design System v1.0.0'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        children: [
          _buildSection('Typography', [
            Text('Display Heading', style: BabkaTypography.display(context)),
            const SizedBox(height: 8),
            Text('Headline 1', style: BabkaTypography.h1(context)),
            const SizedBox(height: 8),
            Text('Headline 2', style: BabkaTypography.h2(context)),
            const SizedBox(height: 8),
            Text('Headline 3', style: BabkaTypography.h3(context)),
            const SizedBox(height: 16),
            Text('Body Large - Jakarta Sans', style: BabkaTypography.bodyLarge(context)),
            Text('Body Medium - Regular reading text', style: BabkaTypography.bodyMedium(context)),
            Text('Price Label: ₺80', style: BabkaTypography.price(context)),
          ], context),
          
          _buildSection('Colors', [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildColorCircle(BabkaColors.primary, 'Primary', context),
                _buildColorCircle(BabkaColors.secondary, 'Secondary', context),
                _buildColorCircle(BabkaColors.background, 'BG', context),
                _buildColorCircle(BabkaColors.accent, 'Accent', context),
                _buildColorCircle(BabkaColors.error, 'Error', context),
              ],
            ),
          ], context),

          _buildSection('Buttons', [
            BabkaButton.primary(
              label: 'Primary Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            BabkaButton.outlined(
              label: 'Outlined Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            BabkaButton.primary(
              label: 'Loading State',
              isLoading: true,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            const BabkaButton.primary(
              label: 'Disabled Button',
              onPressed: null,
            ),
          ], context),

          _buildSection('Inputs', [
            const BabkaTextField(
              label: 'Email Address',
              hintText: 'Enter your email',
              leadingIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            const BabkaTextField(
              label: 'Password',
              hintText: 'Enter your password',
              isPassword: true,
              errorText: 'Password is too short',
            ),
          ], context),

          _buildSection('Badges', [
            Wrap(
              spacing: 8,
              children: [
                FreshnessBadge.freshToday(),
                FreshnessBadge.outOfOven(),
                FreshnessBadge.limited(),
              ],
            ),
          ], context),

          _buildSection('Chips', [
            Wrap(
              spacing: 8,
              children: List.generate(3, (index) => CategoryChip(
                label: ['Traditional', 'Whole Wheat', 'Pastries'][index],
                isSelected: _selectedCategory == index,
                onTap: () => setState(() => _selectedCategory = index),
              )),
            ),
          ], context),

          _buildSection('Signature Components', [
            const HeroBanner(
              title: 'Artisan Babka',
              subtitle: 'Traditional stone-baked perfection',
              imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=600',
            ),
            const SizedBox(height: 24),
            Center(
              child: ProductCard(
                name: 'Traditional Babka',
                description: 'Stone-baked whole wheat flatbread, perfect for breakfast.',
                price: 80,
                imageUrl: 'https://images.unsplash.com/photo-1598373182133-52452f7691ef?q=80&w=400',
                freshness: BabkaTokens.outOfOven,
                isFavorite: _isFavorite,
                width: 220,
                onFavoriteToggle: () => setState(() => _isFavorite = !_isFavorite),
                onAddToBasket: () => setState(() => _productQuantity++),
              ),
            ),
          ], context),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BabkaTypography.h2(context)),
              const Divider(),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildColorCircle(Color color, String label, BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: BabkaColors.border),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: BabkaTypography.caption(context)),
      ],
    );
  }
}

