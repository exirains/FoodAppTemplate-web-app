import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/sangak_text_field.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/widgets/sangak_dialogs.dart';
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
  final _scrollController = ScrollController();
  
  // Focus nodes for validation scrolling
  final _labelFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _districtFocus = FocusNode();
  final _streetFocus = FocusNode();
  final _buildingFocus = FocusNode();
  final _doorFocus = FocusNode();

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
  bool _showAutoFillPrompt = false;
  String _selectedLabelKey = 'home'; // 'home', 'work', 'school', 'other'
  String? _selectedAddressId; // Track the ID of an existing address
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _labelController.text = 'Home'; // Default visible label
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _labelFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _districtFocus.dispose();
    _streetFocus.dispose();
    _buildingFocus.dispose();
    _doorFocus.dispose();
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
    _selectedAddressId = null;
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
            _showAutoFillPrompt = true;
          });
          BabkaToast.show(context, l10n.locationCaptured);
          
          // Scroll to bottom after state update
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorKey = e.toString();
      
      if (errorKey.contains('locationServiceDisabled')) {
        SangakConfirmDialog.show(
          context,
          title: l10n.locationServiceOffTitle,
          message: l10n.locationServiceOffMessage,
          confirmLabel: l10n.turnOn,
          cancelLabel: l10n.nevermind,
          onConfirm: () => Geolocator.openLocationSettings(),
        );
      } else {
        String message = l10n.locationError;
        if (errorKey.contains('locationPermissionDenied')) {
          message = l10n.locationPermissionDenied;
        } else if (errorKey.contains('locationPermissionPermanentlyDenied')) {
          message = l10n.locationPermissionPermanentlyDenied;
        }
        BabkaToast.show(context, message);
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) {
      // Logic to scroll to the first error
      FocusNode? firstErrorFocus;
      if (_labelController.text.trim().isEmpty) {
        firstErrorFocus = _labelFocus;
      } else if (_addressController.text.isEmpty) {
        firstErrorFocus = _addressFocus;
      } else if (_cityController.text.isEmpty) {
        firstErrorFocus = _cityFocus;
      } else if (_districtController.text.isEmpty) {
        firstErrorFocus = _districtFocus;
      } else if (_streetController.text.isEmpty) {
        firstErrorFocus = _streetFocus;
      } else if (_buildingController.text.isEmpty) {
        firstErrorFocus = _buildingFocus;
      } else if (_doorController.text.isEmpty) {
        firstErrorFocus = _doorFocus;
      }

      if (firstErrorFocus != null) {
        firstErrorFocus.requestFocus();
        // Ensure the field is visible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (firstErrorFocus!.context != null) {
            Scrollable.ensureVisible(
              firstErrorFocus.context!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.5, // Center the field in the viewport
            );
          }
        });
      }
      return;
    }

    final address = Address(
      id: _selectedAddressId,
      userId: null, // Set by the provider
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
      BabkaToast.show(context, AppLocalizations.of(context).profileUpdated);
      context.pop();
    }
  }

  void _selectSavedAddress(Address address) {
    setState(() {
      _selectedAddressId = address.id;
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
    
    // Show success message
    final l10n = AppLocalizations.of(context);
    final localizedSelected = _selectedLabelKey == 'home' ? l10n.home :
                            _selectedLabelKey == 'work' ? l10n.work :
                            _selectedLabelKey == 'school' ? l10n.school : address.title;
                            
    BabkaToast.show(context, l10n.successfullySelected(localizedSelected));
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
      backgroundColor: BabkaColors.background,
      appBar: AppBar(
        title: Text(l10n.deliveryAddress),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(addressListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(addressListProvider),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(BabkaDimens.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (savedAddresses.isNotEmpty) ...[
                  Text(l10n.lastUsedAddresses, style: BabkaTypography.h3(context)),
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectSavedAddress(addr),
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BabkaColors.surface,
                              borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
                              border: Border.all(color: BabkaColors.border),
                              boxShadow: BabkaDimens.shadowLow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getIconForLabel(addr.title), size: 16, color: BabkaColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        addr.title,
                                        style: BabkaTypography.title(context).copyWith(fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  addr.fullAddress,
                                  style: BabkaTypography.bodySmall(context).copyWith(fontSize: 12, color: BabkaColors.inkLight),
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
                
                BabkaButton.outlined(
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
                      child: Text(l10n.addressName, style: BabkaTypography.h3(context)),
                    ),
                    TextButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l10n.clear, style: BabkaTypography.bodySmall(context).copyWith(color: BabkaColors.primary)),
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
                BabkaTextField(
                  label: l10n.customName,
                  hintText: l10n.customName,
                  controller: _labelController,
                  focusNode: _labelFocus,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                ),
                
                const SizedBox(height: 32),
                Text(l10n.address, style: BabkaTypography.h3(context)),
                const SizedBox(height: 16),
                BabkaTextField(
                  label: l10n.address,
                  hintText: l10n.address,
                  controller: _addressController,
                  focusNode: _addressFocus,
                  inputFormatters: [LengthLimitingTextInputFormatter(160)],
                  validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: BabkaTextField(
                        label: l10n.city,
                        controller: _cityController,
                        focusNode: _cityFocus,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZğüşöçıİĞÜŞÖÇ\s-]")),
                          LengthLimitingTextInputFormatter(40),
                        ],
                        validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BabkaTextField(
                        label: l10n.district,
                        controller: _districtController,
                        focusNode: _districtFocus,
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
                BabkaTextField(
                  label: l10n.street,
                  controller: _streetController,
                  focusNode: _streetFocus,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 16),
                if (_showAutoFillPrompt)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: BabkaColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pleaseFillFloorDoor,
                          style: BabkaTypography.title(context).copyWith(
                            fontSize: 12,
                            color: BabkaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: BabkaTextField(
                        label: l10n.building,
                        controller: _buildingController,
                        focusNode: _buildingFocus,
                        inputFormatters: [LengthLimitingTextInputFormatter(12)],
                        validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BabkaTextField(
                        label: l10n.floor,
                        controller: _floorController,
                        inputFormatters: [LengthLimitingTextInputFormatter(8)],
                        onChanged: (v) {
                          if (_showAutoFillPrompt) setState(() => _showAutoFillPrompt = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BabkaTextField(
                        label: l10n.door,
                        controller: _doorController,
                        focusNode: _doorFocus,
                        inputFormatters: [LengthLimitingTextInputFormatter(12)],
                        validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                        onChanged: (v) {
                          if (_showAutoFillPrompt) setState(() => _showAutoFillPrompt = false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BabkaTextField(
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
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        decoration: BoxDecoration(
          color: BabkaColors.surface,
          boxShadow: BabkaDimens.shadowHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(BabkaDimens.radiusXL)),
        ),
        child: BabkaButton.primary(
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BabkaColors.primary : BabkaColors.surface,
          borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
          border: Border.all(
            color: isSelected ? BabkaColors.primary : BabkaColors.border,
          ),
          boxShadow: isSelected ? BabkaDimens.shadowLow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : BabkaColors.inkLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: BabkaTypography.bodySmall(context).copyWith(
                color: isSelected ? Colors.white : BabkaColors.inkLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
