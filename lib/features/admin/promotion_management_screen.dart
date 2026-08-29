import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/widgets/role_guard.dart';
import '../../services/promotions_repository.dart';
import '../../models/promotion.dart';
import 'package:uuid/uuid.dart';

class PromotionManagementScreen extends ConsumerStatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  ConsumerState<PromotionManagementScreen> createState() => _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends ConsumerState<PromotionManagementScreen> {
  late Future<List<Promotion>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPromotions();
  }

  void _refreshPromotions() {
    setState(() {
      _promotionsFuture = ref.read(promotionsRepositoryProvider).getActivePromotions();
    });
  }

  void _showPromotionDialog([Promotion? promo]) {
    showDialog(
      context: context,
      builder: (context) => PromotionDialog(
        promotion: promo,
        onSave: () {
          _refreshPromotions();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: BabkaColors.background,
        appBar: AppBar(
          title: Text(l10n.promotionsBanners),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showPromotionDialog(),
            ),
          ],
        ),
        body: FutureBuilder<List<Promotion>>(
          future: _promotionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(l10n.errorOccurred));
            }
            final promos = snapshot.data ?? [];
            if (promos.isEmpty) {
              return Center(child: Text(l10n.noPromotions));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(BabkaDimens.spacing16),
              itemCount: promos.length,
              separatorBuilder: (_, _) => const SizedBox(height: BabkaDimens.spacing12),
              itemBuilder: (context, index) {
                final promo = promos[index];
                return Card(
                  child: ListTile(
                    title: Text(promo.title),
                    subtitle: Text(promo.description ?? l10n.noDescription),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: BabkaColors.primary),
                          onPressed: () => _showPromotionDialog(promo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: BabkaColors.error),
                          onPressed: () async {
                            await ref.read(promotionsRepositoryProvider).deletePromotion(promo.id);
                            _refreshPromotions();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PromotionDialog extends ConsumerStatefulWidget {
  final Promotion? promotion;
  final VoidCallback onSave;

  const PromotionDialog({super.key, this.promotion, required this.onSave});

  @override
  ConsumerState<PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends ConsumerState<PromotionDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _titleController.text = widget.promotion!.title;
      _descController.text = widget.promotion!.description ?? '';
      _imageController.text = widget.promotion!.imageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.promotion == null ? l10n.addPromotion : l10n.editPromotion),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BabkaTextField(
              label: l10n.title,
              controller: _titleController,
            ),
            const SizedBox(height: 16),
            BabkaTextField(
              label: l10n.description,
              controller: _descController,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            BabkaTextField(
              label: l10n.image,
              controller: _imageController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        BabkaButton.primary(
          label: l10n.save,
          isLoading: _isSaving,
          onPressed: () async {
            setState(() => _isSaving = true);
            try {
              final promo = Promotion(
                id: widget.promotion?.id ?? const Uuid().v4(),
                title: _titleController.text,
                description: _descController.text,
                imageUrl: _imageController.text.isNotEmpty ? _imageController.text : null,
                isActive: true,
              );
              if (widget.promotion == null) {
                await ref.read(promotionsRepositoryProvider).addPromotion(promo);
              } else {
                await ref.read(promotionsRepositoryProvider).updatePromotion(promo);
              }
              widget.onSave();
            } catch (e) {
              if (mounted && context.mounted) {
                BabkaToast.show(context, '${l10n.errorOccurred}: $e');
              }
            } finally {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            }
          },
        ),
      ],
    );
  }
}
