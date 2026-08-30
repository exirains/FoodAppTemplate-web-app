import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/babka_number_formatter.dart';
import '../../shared/utils/babka_toast.dart';
import '../../shared/widgets/babka_button.dart';
import '../../shared/widgets/babka_text_field.dart';
import '../../shared/widgets/babka_dialogs.dart';
import '../../shared/widgets/product_tag.dart';
import '../../models/bread.dart';
import '../home/home_provider.dart';
import '../../shared/widgets/role_guard.dart';
import '../../main.dart';

class ProductManagementScreen extends ConsumerWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breadsAsync = ref.watch(breadsProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: BabkaColors.background,
        appBar: AppBar(
          title: Text(l10n.productManagement),
          actions: [
            IconButton(
              onPressed: () => _showEditProductDialog(context, ref, null),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: breadsAsync.when(
          data: (breads) => breads.isEmpty 
            ? Center(child: Text(l10n.noProductsFound))
            : ListView.separated(
                padding: const EdgeInsets.all(BabkaDimens.spacing24),
                itemCount: breads.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final bread = breads[index];
                  return _ProductCard(bread: bread, lang: lang, l10n: l10n);
                },
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorOccurred)),
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Bread? bread) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditProductDialog(bread: bread),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Bread bread;
  final String lang;
  final AppLocalizations l10n;

  const _ProductCard({required this.bread, required this.lang, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
        boxShadow: BabkaDimens.shadowMedium,
        border: Border.all(color: BabkaColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: bread.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: BabkaColors.background,
                child: const Icon(Icons.image_not_supported_outlined, color: BabkaColors.border),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bread.localizedName(lang),
                      style: BabkaTypography.h3(context).copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bread.tag != null) ...[
                    const SizedBox(width: 8),
                    ProductTag.fromText(bread.tag!, context: context),
                  ],
                ],
              ),
                const SizedBox(height: 4),
                Text(
                  BabkaNumberFormatter.formatCurrency(bread.price, lang),
                  style: BabkaTypography.price(context),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      try {
                        await ref.read(breadRepositoryProvider).updateAvailability(bread.id, !bread.available);
                        await ref.read(cacheServiceProvider).clear();
                        ref.invalidate(breadsProvider);
                        if (context.mounted) BabkaToast.show(context, l10n.productStatusUpdated);
                      } catch (e) {
                        if (context.mounted) BabkaToast.show(context, l10n.errorOccurred);
                      }
                    },
                    borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
                    child: _StatusChip(isActive: bread.available, l10n: l10n),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => _showEditProductDialog(context, ref, bread),
                  icon: const Icon(Icons.edit_outlined, color: BabkaColors.primary, size: 20),
                  padding: EdgeInsets.zero,
                  splashRadius: 22,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => _confirmDelete(context, ref, bread),
                  icon: const Icon(Icons.delete_outline_rounded, color: BabkaColors.error, size: 20),
                  padding: EdgeInsets.zero,
                  splashRadius: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Bread? bread) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditProductDialog(bread: bread),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Bread bread) {
    BabkaConfirmDialog.show(
      context,
      title: l10n.deleteProduct,
      message: l10n.confirmDeleteProduct,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      onConfirm: () async {
        try {
          await ref.read(breadRepositoryProvider).deleteProduct(bread.id);
          await ref.read(cacheServiceProvider).clear();
          ref.invalidate(breadsProvider);
          if (context.mounted) BabkaToast.show(context, 'Product deleted');
        } catch (e) {
          if (context.mounted) BabkaToast.show(context, 'Error: $e');
        }
      },
      isDestructive: true,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  final AppLocalizations l10n;
  const _StatusChip({required this.isActive, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? BabkaColors.success : BabkaColors.error;
    return Ink(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isActive ? l10n.available.toUpperCase() : 'DEACTIVATED',
        style: TextStyle(
          color: color, 
          fontSize: 10, 
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EditProductDialog extends ConsumerStatefulWidget {
  final Bread? bread;
  const _EditProductDialog({this.bread});

  @override
  ConsumerState<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameEnController;
  late TextEditingController _descEnController;
  late TextEditingController _nameTrController;
  late TextEditingController _descTrController;
  late TextEditingController _nameFaController;
  late TextEditingController _descFaController;
  late TextEditingController _priceController;
  late TextEditingController _prepTimeController;
  late TextEditingController _caloriesController;
  
  String? _imageUrl;
  String? _selectedCategoryId;
  String? _selectedTag;
  bool _available = true;
  bool _isOrganic = false;
  bool _isSaving = false;
  
  Uint8List? _previewBytes;
  String? _imageExt;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.bread != null;
    final b = widget.bread;
    
    _nameEnController = TextEditingController(text: isEditing ? (b!.translations?['en']?['name'] ?? b.name) : '');
    _descEnController = TextEditingController(text: isEditing ? (b!.translations?['en']?['description'] ?? b.description) : '');
    _nameTrController = TextEditingController(text: isEditing ? b!.translations?['tr']?['name'] ?? '' : '');
    _descTrController = TextEditingController(text: isEditing ? b!.translations?['tr']?['description'] ?? '' : '');
    _nameFaController = TextEditingController(text: isEditing ? b!.translations?['fa']?['name'] ?? '' : '');
    _descFaController = TextEditingController(text: isEditing ? b!.translations?['fa']?['description'] ?? '' : '');
    _priceController = TextEditingController(text: isEditing ? b!.price.toString() : '');
    _prepTimeController = TextEditingController(text: isEditing ? b!.prepTime.toString() : '20');
    _caloriesController = TextEditingController(text: isEditing ? b!.calories.toString() : '250');
    
    _imageUrl = isEditing ? b!.imageUrl : null;
    _selectedCategoryId = isEditing ? b!.categoryId : null;
    _selectedTag = isEditing ? b!.tag : null;
    _available = isEditing ? b!.available : true;
    _isOrganic = isEditing ? b!.isOrganic : false;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _descEnController.dispose();
    _nameTrController.dispose();
    _descTrController.dispose();
    _nameFaController.dispose();
    _descFaController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _imageExt = image.path.split('.').last;
      });
    }
  }

  void _onCancel() {
    final l10n = AppLocalizations.of(context);
    BabkaConfirmDialog.show(
      context,
      title: l10n.cancel,
      message: l10n.discardChanges,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.cancel,
      onConfirm: () => Navigator.pop(context),
      isDestructive: true,
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final l10n = AppLocalizations.of(context);
    BabkaConfirmDialog.show(
      context,
      title: widget.bread != null ? l10n.saveChanges : l10n.addProduct,
      message: l10n.confirmSaveProduct,
      confirmLabel: widget.bread != null ? l10n.save : l10n.add, 
      cancelLabel: l10n.cancel,
      onConfirm: () => _executeSave(),
    );
  }

  Future<void> _executeSave() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(breadRepositoryProvider);
    
    setState(() => _isSaving = true);
    
    try {
      String finalImageUrl = _imageUrl ?? '';

      if (_previewBytes != null && _imageExt != null) {
        final storageId = widget.bread?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
        finalImageUrl = await repo.uploadImage(storageId, _previewBytes!, _imageExt!);
      }

      final price = double.tryParse(_priceController.text) ?? 0.0;
      final prepTime = int.tryParse(_prepTimeController.text) ?? 20;
      final calories = int.tryParse(_caloriesController.text) ?? 250;
      
      final productData = {
        'name': _nameEnController.text.trim(),
        'description': _descEnController.text.trim(),
        'price': price,
        'image_url': finalImageUrl,
        'category_id': _selectedCategoryId ?? '8906660b-8d18-4720-bc2d-520e50e1ef00',
        'available': _available,
        'is_organic': _isOrganic,
        'tag': (_selectedTag == 'none' || _selectedTag == null) ? null : _selectedTag,
        'prep_time': prepTime,
        'calories': calories,
      };

      String productId;
      if (widget.bread != null) {
        productId = widget.bread!.id;
        await repo.updateProduct(productId, productData);
      } else {
        final newProduct = await repo.addProduct(productData);
        productId = newProduct['id'];
      }

      await repo.updateTranslations(productId, {
        'en': {'name': _nameEnController.text.trim(), 'description': _descEnController.text.trim()},
        'tr': {'name': _nameTrController.text.trim(), 'description': _descTrController.text.trim()},
        'fa': {'name': _nameFaController.text.trim(), 'description': _descFaController.text.trim()},
      });

      await ref.read(cacheServiceProvider).clear();
      ref.invalidate(breadsProvider);
      ref.invalidate(popularBreadsProvider);
      
      if (mounted) {
        BabkaToast.show(context, l10n.productSavedSuccess);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) BabkaToast.show(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    final tags = [
      {'value': 'none', 'label': l10n.productTagNone},
      {'value': 'Popular', 'label': l10n.productTagPopular},
      {'value': 'Bestseller', 'label': l10n.productTagBestseller},
      {'value': 'New', 'label': l10n.productTagNew},
      {'value': 'Traditional', 'label': l10n.productTagTraditional},
      {'value': 'Recommended', 'label': l10n.productTagRecommended},
      {'value': 'Seasonal', 'label': l10n.productTagSeasonal},
      {'value': 'Special', 'label': l10n.productTagSpecial},
      {'value': 'Limited', 'label': l10n.productTagLimited},
    ];

    final currentTagValue = _selectedTag ?? 'none';
    if (!tags.any((t) => t['value'] == currentTagValue)) {
      tags.add({'value': currentTagValue, 'label': currentTagValue});
    }

    return AlertDialog(
      title: Text(widget.bread != null ? l10n.editProduct : l10n.addProduct),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickImage,
                child: Ink(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: BabkaColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BabkaColors.border),
                  ),
                  child: _previewBytes != null
                     ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                     : _imageUrl != null 
                        ? CachedNetworkImage(imageUrl: _imageUrl!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, size: 40, color: BabkaColors.primary),
                              const SizedBox(height: 8),
                              Text(l10n.imageUrl),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (categoriesAsync.hasValue)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId ?? (categoriesAsync.value!.isNotEmpty ? categoriesAsync.value!.first.id : null),
                  decoration: InputDecoration(labelText: l10n.category),
                  items: categoriesAsync.value!.map<DropdownMenuItem<String>>((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                )
              else if (categoriesAsync.isLoading)
                const LinearProgressIndicator()
              else
                Text(l10n.errorLoadingCategories),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(l10n.available),
                  const Spacer(),
                  Switch(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    activeThumbColor: BabkaColors.primary,
                  ),
                ],
              ),

              const Divider(height: 32),
            Row(
              children: [
                Text(l10n.organic),
                const Spacer(),
                Switch(
                  value: _isOrganic,
                  onChanged: (v) => setState(() => _isOrganic = v),
                  activeThumbColor: BabkaColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: currentTagValue,
              decoration: const InputDecoration(labelText: 'Tag'),
              items: tags.map((t) => DropdownMenuItem(
                value: t['value'],
                child: Text(t['label']!),
              )).toList(),
              onChanged: (v) => setState(() => _selectedTag = v),
            ),
            const SizedBox(height: 12),
            BabkaTextField(
              label: l10n.price, 
              controller: _priceController, 
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BabkaTextField(
                    label: l10n.prepTimeLabel, 
                    controller: _prepTimeController, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BabkaTextField(
                    label: l10n.caloriesLabel, 
                    controller: _caloriesController, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                  ),
                ),
              ],
            ),
              
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.originalName),
              BabkaTextField(
                label: 'Name (EN)', 
                controller: _nameEnController,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              BabkaTextField(
                label: 'Description (EN)', 
                controller: _descEnController, 
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(l10n.turkishTranslations),
              BabkaTextField(
                label: 'Name (TR)', 
                controller: _nameTrController,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              BabkaTextField(
                label: 'Description (TR)', 
                controller: _descTrController, 
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(l10n.persianTranslations),
              BabkaTextField(
                label: 'Name (FA)', 
                controller: _nameFaController,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              BabkaTextField(
                label: 'Description (FA)', 
                controller: _descFaController, 
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _onCancel, child: Text(l10n.cancel)),
        BabkaButton.primary(
          label: widget.bread != null ? l10n.save : l10n.add, 
          width: 140, // Increased width to prevent Turkish Kaydet cut-off
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _onSave,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title.toUpperCase(), 
          style: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

