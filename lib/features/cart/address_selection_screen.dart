import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../models/address.dart';
import 'checkout_provider.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends ConsumerState<AddressSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _doorController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _doorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final l10n = AppLocalizations.of(context);

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      if (position != null) {
        final placemark = await locationService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );

        if (placemark != null) {
          setState(() {
            _cityController.text = placemark.administrativeArea ?? '';
            _districtController.text = placemark.subAdministrativeArea ?? '';
            _streetController.text = placemark.street ?? '';
            _addressController.text = '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}';
          });
          SangakToast.show(context, 'Location captured successfully');
        }
      }
    } catch (e) {
      SangakToast.show(context, 'Could not get location. Please enter manually.');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      title: 'Delivery Address',
      fullAddress: _addressController.text,
      city: _cityController.text,
      district: _districtController.text,
      street: _streetController.text,
      building: _buildingController.text,
      floor: _floorController.text,
      door: _doorController.text,
      deliveryNote: _noteController.text,
    );

    ref.read(checkoutProvider.notifier).selectAddress(address);
    context.push('/payment-selection');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.deliveryAddress),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SangakButton.outlined(
                label: l10n.useCurrentLocation,
                width: double.infinity,
                icon: Icons.my_location_rounded,
                isLoading: _isLoadingLocation,
                onPressed: _getCurrentLocation,
              ),
              const SizedBox(height: 32),
              Text(l10n.address, style: SangakTypography.h3(context)),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.address,
                hintText: 'Full address description',
                controller: _addressController,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SangakTextField(
                      label: l10n.city,
                      controller: _cityController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SangakTextField(
                      label: l10n.district,
                      controller: _districtController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.street,
                controller: _streetController,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SangakTextField(
                      label: l10n.building,
                      controller: _buildingController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SangakTextField(
                      label: l10n.floor,
                      controller: _floorController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SangakTextField(
                      label: l10n.door,
                      controller: _doorController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.addDeliveryNote,
                hintText: 'e.g. Leave at the door',
                controller: _noteController,
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        decoration: BoxDecoration(
          color: SangakColors.surface,
          boxShadow: SangakDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
        ),
        child: SangakButton.primary(
          label: l10n.continueButton,
          width: double.infinity,
          onPressed: _onSave,
        ),
      ),
    );
  }
}
