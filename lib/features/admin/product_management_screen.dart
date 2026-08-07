import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/sangak_dialogs.dart';
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
        backgroundColor: SangakColors.background,
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
                padding: const EdgeInsets.all(SangakDimens.spacing24),
                itemCount: breads.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final bread = breads[index];
                  return _ProductCard(bread: bread, lang: lang, l10n: l10n);
                },
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, dynamic bread) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force use of cancel/save
      builder: (context) => _EditProductDialog(bread: bread),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final dynamic bread;
  final String lang;
  final AppLocalizations l10n;

  const _ProductCard({required this.bread, required this.lang, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
        border: Border.all(color: SangakColors.border),
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
                color: SangakColors.background,
                child: const Icon(Icons.image_not_supported_outlined, color: SangakColors.border),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bread.localizedName(lang),
                  style: SangakTypography.h3(context).copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  SangakNumberFormatter.formatCurrency(bread.price, lang),
                  style: SangakTypography.price(context),
                ),
                const SizedBox(height: 8),
                _StatusChip(isActive: bread.available, l10n: l10n),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEditProductDialog(context, ref, bread),
                icon: const Icon(Icons.edit_outlined, color: SangakColors.primary),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, ref, bread),
                icon: const Icon(Icons.delete_outline_rounded, color: SangakColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, dynamic bread) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditProductDialog(bread: bread),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic bread) {
    SangakConfirmDialog.show(
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
          if (context.mounted) SangakToast.show(context, 'Product deleted');
        } catch (e) {
          if (context.mounted) SangakToast.show(context, 'Error: $e');
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
    final color = isActive ? SangakColors.success : SangakColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isActive ? l10n.available.toUpperCase() : 'DEACTIVATED',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EditProductDialog extends ConsumerStatefulWidget {
  final dynamic bread;
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
  
  String? _imageUrl;
  String? _selectedCategoryId;
  bool _available = true;
  bool _isSaving = false;
  
  Uint8List? _previewBytes;
  String? _imageExt;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.bread != null;
    final b = widget.bread;
    
    _nameEnController = TextEditingController(text: isEditing ? b.name : '');
    _descEnController = TextEditingController(text: isEditing ? b.description : '');
    _nameTrController = TextEditingController(text: isEditing ? b.translations?['tr']?['name'] ?? '' : '');
    _descTrController = TextEditingController(text: isEditing ? b.translations?['tr']?['description'] ?? '' : '');
    _nameFaController = TextEditingController(text: isEditing ? b.translations?['fa']?['name'] ?? '' : '');
    _descFaController = TextEditingController(text: isEditing ? b.translations?['fa']?['description'] ?? '' : '');
    _priceController = TextEditingController(text: isEditing ? b.price.toString() : '');
    
    _imageUrl = isEditing ? b.imageUrl : null;
    _selectedCategoryId = isEditing ? b.categoryId : null;
    _available = isEditing ? b.available : true;
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
    SangakConfirmDialog.show(
      context,
      title: l10n.cancel,
      message: 'Discard all unsaved changes?',
      confirmLabel: 'Discard',
      cancelLabel: l10n.cancel,
      onConfirm: () => Navigator.pop(context),
      isDestructive: true,
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final l10n = AppLocalizations.of(context);
    SangakConfirmDialog.show(
      context,
      title: l10n.saveChanges,
      message: 'Are you sure you want to save this product?',
      confirmLabel: 'Save',
      cancelLabel: l10n.cancel,
      onConfirm: () => _executeSave(),
    );
  }

  Future<void> _executeSave() async {
    final repo = ref.read(breadRepositoryProvider);
    
    setState(() => _isSaving = true);
    
    try {
      final id = widget.bread?.id ?? 'PRD_${DateTime.now().millisecondsSinceEpoch}';
      String finalImageUrl = _imageUrl ?? '';

      if (_previewBytes != null && _imageExt != null) {
        finalImageUrl = await repo.uploadImage(id, _previewBytes!, _imageExt!);
      }

      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      final productData = {
        'id': id,
        'name': _nameEnController.text.trim(),
        'description': _descEnController.text.trim(),
        'price': price,
        'image_url': finalImageUrl,
        'category_id': _selectedCategoryId ?? '8906660b-8d18-4720-bc2d-520e50e1ef00',
        'available': _available,
      };

      if (widget.bread != null) {
        await repo.updateProduct(id, productData);
      } else {
        await repo.addProduct(productData);
      }

      // Update Translations
      await repo.updateTranslations(id, {
        'en': {'name': _nameEnController.text.trim(), 'description': _descEnController.text.trim()},
        'tr': {'name': _nameTrController.text.trim(), 'description': _descTrController.text.trim()},
        'fa': {'name': _nameFaController.text.trim(), 'description': _descFaController.text.trim()},
      });

      await ref.read(cacheServiceProvider).clear();
      ref.invalidate(breadsProvider);
      
      if (mounted) {
        SangakToast.show(context, 'Product saved successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) SangakToast.show(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(widget.bread != null ? l10n.editProduct : l10n.addProduct),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: SangakColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SangakColors.border),
                  ),
                  child: _previewBytes != null
                     ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                     : _imageUrl != null 
                        ? CachedNetworkImage(imageUrl: _imageUrl!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: SangakColors.primary),
                              SizedBox(height: 8),
                              Text('Tap to select image'),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 16),
              
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId ?? categories.firstOrNull?.id,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => const Text('Error loading categories'),
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Available for Sale'),
                  const Spacer(),
                  Switch(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                    activeThumbColor: SangakColors.primary,
                  ),
                ],
              ),

              const Divider(height: 32),
              SangakTextField(
                label: l10n.newPrice, 
                controller: _priceController, 
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.originalName),
              SangakTextField(
                label: 'Name (EN)', 
                controller: _nameEnController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SangakTextField(
                label: 'Description (EN)', 
                controller: _descEnController, 
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(l10n.turkishTranslations),
              SangakTextField(
                label: 'Name (TR)', 
                controller: _nameTrController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SangakTextField(
                label: 'Description (TR)', 
                controller: _descTrController, 
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(l10n.persianTranslations),
              SangakTextField(
                label: 'Name (FA)', 
                controller: _nameFaController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              SangakTextField(
                label: 'Description (FA)', 
                controller: _descFaController, 
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _onCancel, child: Text(l10n.cancel)),
        SangakButton.primary(
          label: 'Save', // Shorter label to avoid truncation
          width: 100,
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
          style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
