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
import 'address_provider.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  final bool fromCheckout;
  const AddressSelectionScreen({super.key, this.fromCheckout = true});

  @override
  ConsumerState<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends ConsumerState<AddressSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _doorController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoadingLocation = false;
  String _selectedLabelKey = 'home'; // 'home', 'work', 'school', 'other'
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _labelController.text = 'Home'; // Default visible label
  }

  @override
  void dispose() {
    _labelController.dispose();
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
    _labelController.text = 'Home';
    _selectedLabelKey = 'home';
    _addressController.clear();
    _cityController.clear();
    _districtController.clear();
    _streetController.clear();
    _buildingController.clear();
    _floorController.clear();
    _doorController.clear();
    _noteController.clear();
    _latitude = null;
    _longitude = null;
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
            _latitude = position.latitude;
            _longitude = position.longitude;
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

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      title: _labelController.text.trim(),
      fullAddress: _addressController.text,
      city: _cityController.text,
      district: _districtController.text,
      street: _streetController.text,
      building: _buildingController.text,
      floor: _floorController.text,
      door: _doorController.text,
      latitude: _latitude,
      longitude: _longitude,
      deliveryNote: '', 
    );

    // 1. Save to Local Cache (Fast access/History)
    final storage = ref.read(storageServiceProvider);
    final saved = storage.addresses;
    final List<Map<String, dynamic>> addresses = saved == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(saved) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    
    // Move to top/Update
    addresses.removeWhere((a) => a['address'] == address.fullAddress && a['label'] == address.title);
    addresses.add(address.toJson());
    
    if (addresses.length > 10) addresses.removeAt(0);
    storage.saveAddresses(jsonEncode(addresses));

    // 2. Save to Supabase (Cloud Sync)
    // We await this to ensure we have the ID for the next screen if needed
    // and to catch errors early.
    await ref.read(addressListProvider.notifier).saveAddress(address);

    if (!mounted) return;

    if (widget.fromCheckout) {
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
      _labelController.text = address.title;
      _addressController.text = address.fullAddress;
      _cityController.text = address.city;
      _districtController.text = address.district;
      _streetController.text = address.street;
      _buildingController.text = address.building ?? '';
      _floorController.text = address.floor ?? '';
      _doorController.text = address.door ?? '';
      _noteController.clear();
      
      _latitude = address.latitude;
      _longitude = address.longitude;
      
      // Attempt to map back to a label key for UI selection
      final titleLower = address.title.toLowerCase();
      if (titleLower.contains('home') || titleLower.contains('ev')) {
        _selectedLabelKey = 'home';
      } else if (titleLower.contains('work') || titleLower.contains('iş')) {
        _selectedLabelKey = 'work';
      } else if (titleLower.contains('school') || titleLower.contains('okul')) {
        _selectedLabelKey = 'school';
      } else {
        _selectedLabelKey = 'other';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    
    // 1. Get Local Addresses (History)
    final savedJson = storage.addresses;
    final List<Address> localAddresses = savedJson == null
        ? []
        : (jsonDecode(savedJson) as List)
            .map((e) => Address.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    // 2. Get Cloud Addresses (Synced)
    final cloudAddresses = ref.watch(addressListProvider).value ?? [];
    
    // 3. Merge: Prioritize Cloud, fill with Local History
    // We deduplicate by fullAddress to keep the list clean
    final Map<String, Address> mergedMap = {};
    for (final addr in localAddresses) {
      mergedMap[addr.fullAddress] = addr;
    }
    for (final addr in cloudAddresses) {
      mergedMap[addr.fullAddress] = addr;
    }

    final savedAddresses = mergedMap.values.toList().reversed.toList();

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
                  height: 110,
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SangakColors.surface,
                            borderRadius: BorderRadius.circular(SangakDimens.radiusL),
                            border: Border.all(color: SangakColors.border),
                            boxShadow: SangakDimens.shadowLow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(_getIconForLabel(addr.title), size: 16, color: SangakColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      addr.title,
                                      style: SangakTypography.title(context).copyWith(fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                addr.fullAddress,
                                style: SangakTypography.bodySmall(context).copyWith(fontSize: 12, color: SangakColors.inkLight),
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
              const SizedBox(height: 40),
              
              // Label selection title
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.addressName, style: SangakTypography.h3(context)),
                  ),
                  TextButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.clear, style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Label selection chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _LabelChip(
                    icon: Icons.home_outlined,
                    label: l10n.home,
                    isSelected: _selectedLabelKey == 'home',
                    onTap: () => setState(() {
                      _selectedLabelKey = 'home';
                      _labelController.text = l10n.home;
                    }),
                  ),
                  _LabelChip(
                    icon: Icons.work_outline,
                    label: l10n.work,
                    isSelected: _selectedLabelKey == 'work',
                    onTap: () => setState(() {
                      _selectedLabelKey = 'work';
                      _labelController.text = l10n.work;
                    }),
                  ),
                  _LabelChip(
                    icon: Icons.school_outlined,
                    label: l10n.school,
                    isSelected: _selectedLabelKey == 'school',
                    onTap: () => setState(() {
                      _selectedLabelKey = 'school';
                      _labelController.text = l10n.school;
                    }),
                  ),
                  _LabelChip(
                    icon: Icons.location_on_outlined,
                    label: l10n.other,
                    isSelected: _selectedLabelKey == 'other',
                    onTap: () => setState(() {
                      _selectedLabelKey = 'other';
                      if (_labelController.text == l10n.home || 
                          _labelController.text == l10n.work || 
                          _labelController.text == l10n.school) {
                        _labelController.clear();
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SangakTextField(
                label: l10n.customName,
                hintText: l10n.customName,
                controller: _labelController,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              ),
              
              const SizedBox(height: 32),
              Text(l10n.address, style: SangakTypography.h3(context)),
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

  IconData _getIconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('home') || l.contains('ev')) return Icons.home_rounded;
    if (l.contains('work') || l.contains('iş')) return Icons.work_rounded;
    if (l.contains('school') || l.contains('okul')) return Icons.school_rounded;
    return Icons.location_on_rounded;
  }
}

class _LabelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LabelChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SangakColors.primary : SangakColors.surface,
          borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
          border: Border.all(
            color: isSelected ? SangakColors.primary : SangakColors.border,
          ),
          boxShadow: isSelected ? SangakDimens.shadowLow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : SangakColors.inkLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: SangakTypography.bodySmall(context).copyWith(
                color: isSelected ? Colors.white : SangakColors.inkLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
