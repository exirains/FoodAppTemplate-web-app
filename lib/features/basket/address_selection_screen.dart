import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/location/geoapify_service.dart';
import '../../main.dart';
import 'checkout_provider.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  final bool fromCheckout;
  const AddressSelectionScreen({super.key, this.fromCheckout = true});

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

  void _clearForm() {
    _addressController.clear();
    _cityController.clear();
    _districtController.clear();
    _streetController.clear();
    _buildingController.clear();
    _floorController.clear();
    _doorController.clear();
    _noteController.clear();
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoadingLocation = true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      if (position != null) {
        final AddressLocation? locationData = await locationService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );

        if (locationData != null) {
          if (!mounted) return;
          setState(() {
            _cityController.text = locationData.city ?? '';
            _districtController.text = locationData.district ?? '';
            _streetController.text = locationData.street ?? '';
            _buildingController.text = locationData.buildingNumber ?? '';
            _addressController.text = locationData.formattedAddress ?? '';
          });
          SangakToast.show(context, l10n.locationCaptured);
        }
      }
    } catch (e) {
      if (!mounted) return;
      SangakToast.show(context, l10n.locationError);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      title: AppLocalizations.of(context).deliveryAddress,
      fullAddress: _addressController.text,
      city: _cityController.text,
      district: _districtController.text,
      street: _streetController.text,
      building: _buildingController.text,
      floor: _floorController.text,
      door: _doorController.text,
      deliveryNote: '', // Do not save delivery note in the address object itself for history
    );

    final storage = ref.read(storageServiceProvider);
    final saved = storage.addresses;
    final addresses = saved == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(saved) as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    
    // Remove if exists to move to top
    addresses.removeWhere((a) => a['full_address'] == address.fullAddress);
    addresses.add(address.toJson());
    
    // Keep only last 5 addresses
    if (addresses.length > 5) addresses.removeAt(0);
    storage.saveAddresses(jsonEncode(addresses));

    if (widget.fromCheckout) {
      // If in checkout flow, we also care about the note for the current order
      final currentAddressWithNote = address.copyWith(deliveryNote: _noteController.text);
      ref.read(checkoutProvider.notifier).selectAddress(currentAddressWithNote);
      context.push('/payment-selection?from=checkout');
    } else {
      SangakToast.show(context, AppLocalizations.of(context).profileUpdated);
      context.pop();
    }
  }

  void _selectSavedAddress(Address address) {
    setState(() {
      _addressController.text = address.fullAddress;
      _cityController.text = address.city;
      _districtController.text = address.district;
      _streetController.text = address.street;
      _buildingController.text = address.building ?? '';
      _floorController.text = address.floor ?? '';
      _doorController.text = address.door ?? '';
      // We don't fill note from history as per user request to not save it
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final savedJson = storage.addresses;
    final List<Address> savedAddresses = savedJson == null
        ? []
        : (jsonDecode(savedJson) as List)
            .map((e) => Address.fromJson(Map<String, dynamic>.from(e)))
            .toList()
            .reversed
            .toList();

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
              if (savedAddresses.isNotEmpty) ...[
                Text(l10n.lastUsedAddresses, style: SangakTypography.h3(context)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: savedAddresses.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final addr = savedAddresses[index];
                      return GestureDetector(
                        onTap: () => _selectSavedAddress(addr),
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SangakColors.surface,
                            borderRadius: BorderRadius.circular(SangakDimens.radiusM),
                            border: Border.all(color: SangakColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                addr.street.isNotEmpty ? addr.street : addr.city,
                                style: SangakTypography.title(context).copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                addr.fullAddress,
                                style: SangakTypography.bodySmall(context).copyWith(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
              SangakButton.outlined(
                label: l10n.useCurrentLocation,
                width: double.infinity,
                icon: Icons.my_location_rounded,
                isLoading: _isLoadingLocation,
                onPressed: _getCurrentLocation,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.address, style: SangakTypography.h3(context)),
                  TextButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.clear, style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.address,
                hintText: l10n.address,
                controller: _addressController,
                inputFormatters: [LengthLimitingTextInputFormatter(160)],
                validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SangakTextField(
                      label: l10n.city,
                      controller: _cityController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZğüşöçıİĞÜŞÖÇ\s-]")),
                        LengthLimitingTextInputFormatter(40),
                      ],
                      validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SangakTextField(
                      label: l10n.district,
                      controller: _districtController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZğüşöçıİĞÜŞÖÇ\s-]")),
                        LengthLimitingTextInputFormatter(40),
                      ],
                      validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.street,
                controller: _streetController,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SangakTextField(
                      label: l10n.building,
                      controller: _buildingController,
                      inputFormatters: [LengthLimitingTextInputFormatter(12)],
                      validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SangakTextField(
                      label: l10n.floor,
                      controller: _floorController,
                      inputFormatters: [LengthLimitingTextInputFormatter(8)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SangakTextField(
                      label: l10n.door,
                      controller: _doorController,
                      inputFormatters: [LengthLimitingTextInputFormatter(12)],
                      validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.addDeliveryNote,
                hintText: l10n.addDeliveryNote,
                controller: _noteController,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
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
