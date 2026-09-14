import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/document_picker_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_chip_select.dart';
import '../../../../shared/widgets/ah_dropdown_field.dart';
import '../../../../shared/widgets/ah_photo_slots.dart';
import '../../../../shared/widgets/ah_stepper_input.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../../domain/entities/host_venue.dart';
import '../controllers/host_venue_form_controller.dart';

/// Event types offered when creating a venue. No product doc pins this list
/// down yet; matches the placeholder set the design spec suggested.
const kVenueEventTypeOptions = [
  'House party',
  'Rooftop',
  'Bar takeover',
  'Warehouse',
  'Private residence',
];

/// Bangalore-only pilot, same scoping as `host_documents_page.dart` and
/// `host_signup_page.dart`'s city field.
const kVenueCityOptions = ['Bangalore'];

const _photoSlotCount = 3;
const _imagePickerExtensions = ['jpg', 'jpeg', 'png'];

/// H-07 · Venue details — also backs H-E0 "add a venue" when [venue] is
/// null. Editing an existing venue updates every upcoming event held there.
class HostVenueDetailsPage extends ConsumerStatefulWidget {
  const HostVenueDetailsPage({super.key, this.venue});

  final HostVenue? venue;

  @override
  ConsumerState<HostVenueDetailsPage> createState() =>
      _HostVenueDetailsPageState();
}

class _HostVenueDetailsPageState extends ConsumerState<HostVenueDetailsPage> {
  late final _nameController = TextEditingController(text: widget.venue?.name);
  late final _addressLine1Controller = TextEditingController(
    text: widget.venue?.addressLine1,
  );
  late final _addressLine2Controller = TextEditingController(
    text: widget.venue?.addressLine2,
  );
  late final _pincodeController = TextEditingController(
    text: widget.venue?.pincode,
  );
  bool _confirmDelete = false;

  late final _provider = hostVenueFormControllerProvider(widget.venue);

  @override
  void dispose() {
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    try {
      final result = await ref
          .read(documentPickerProvider)
          .pickFile(allowedExtensions: _imagePickerExtensions);
      if (result == null || !mounted) return;
      ref.read(_provider.notifier).setPhotoAt(index, result.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the photo picker")),
      );
    }
  }

  Future<void> _onSave() async {
    final saved = await ref.read(_provider.notifier).save();
    if (!mounted) return;
    if (saved) {
      context.pop();
    } else {
      final error = ref.read(_provider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _onConfirmDelete() async {
    final deleted = await ref.read(_provider.notifier).delete();
    if (!mounted) return;
    if (deleted) {
      context.pop();
    } else {
      setState(() => _confirmDelete = false);
      final error = ref.read(_provider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final draft = state.draft;
    final fieldErrors = state.fieldErrors;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          state.isEdit ? draft.name : 'Add a venue',
          style: typography.h3,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved once, reused across every event you create '
                          'there. Editing it later updates all of your '
                          'upcoming events at that venue.',
                          style: typography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.spacerMd,
                        Text(
                          'Venue photos',
                          style: typography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.spacerSm,
                        AhPhotoSlots(
                          count: _photoSlotCount,
                          photoPaths: draft.photoPaths,
                          onTapSlot: _pickPhoto,
                        ),
                        AppSpacing.spacerXs,
                        Text(
                          fieldErrors['photos'] ??
                              'Minimum 3. Used as fallback artwork on events '
                                  'at this venue.',
                          style: typography.caption.copyWith(
                            color: fieldErrors['photos'] != null
                                ? AppColors.statusError
                                : AppColors.textTertiary,
                          ),
                        ),
                        AppSpacing.spacerMd,
                        Text(
                          'Event types this venue can host',
                          style: typography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.spacerSm,
                        AhChipSelect(
                          options: kVenueEventTypeOptions,
                          selected: draft.eventTypes,
                          onToggle: notifier.toggleEventType,
                        ),
                        AppSpacing.spacerXs,
                        Text(
                          fieldErrors['eventTypes'] ??
                              'Only these formats are offered when you '
                                  'create an event here.',
                          style: typography.caption.copyWith(
                            color: fieldErrors['eventTypes'] != null
                                ? AppColors.statusError
                                : AppColors.textTertiary,
                          ),
                        ),
                        AppSpacing.spacerMd,
                        AhTextField(
                          label: 'Venue name',
                          controller: _nameController,
                          onChanged: notifier.updateName,
                          errorText: fieldErrors['name'],
                        ),
                        AppSpacing.spacerMd,
                        AhTextField(
                          label: 'Address line 1',
                          controller: _addressLine1Controller,
                          onChanged: notifier.updateAddressLine1,
                          errorText: fieldErrors['addressLine1'],
                        ),
                        AppSpacing.spacerMd,
                        AhTextField(
                          label: 'Address line 2',
                          controller: _addressLine2Controller,
                          onChanged: notifier.updateAddressLine2,
                        ),
                        AppSpacing.spacerMd,
                        AhDropdownField(
                          label: 'City',
                          value: draft.city.isEmpty
                              ? kVenueCityOptions.first
                              : draft.city,
                          options: kVenueCityOptions,
                          onChanged: notifier.updateCity,
                          errorText: fieldErrors['city'],
                        ),
                        AppSpacing.spacerMd,
                        AhTextField(
                          label: 'Pincode',
                          controller: _pincodeController,
                          onChanged: notifier.updatePincode,
                          keyboardType: TextInputType.number,
                          errorText: fieldErrors['pincode'],
                        ),
                        AppSpacing.spacerMd,
                        AhStepperInput(
                          label: 'Max capacity at this venue',
                          value: draft.maxCapacity,
                          min: 8,
                          max: 300,
                          step: 2,
                          suffix: 'seats',
                          onChanged: notifier.updateMaxCapacity,
                        ),
                        AppSpacing.spacerMd,
                        const AhAlertBanner(
                          message:
                              'The exact address is only released to a '
                              "member after they book — this stays true for "
                              'every event at this venue.',
                        ),
                        if (state.isEdit) ...[
                          AppSpacing.spacerLg,
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.borderDefault),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                              ),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: state.isDeleting
                                      ? null
                                      : () => setState(
                                          () => _confirmDelete = true,
                                        ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.statusError,
                                  ),
                                  label: Text(
                                    'Delete this venue',
                                    style: typography.bodySm.copyWith(
                                      color: AppColors.statusError,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderDefault),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.sm + AppSpacing.xs,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    child: AhButton(
                      label: state.isSaving ? 'Saving…' : state.saveLabel,
                      fullWidth: true,
                      onPressed: state.isSaving ? null : _onSave,
                    ),
                  ),
                ),
              ],
            ),
            if (_confirmDelete)
              _DeleteVenueSheet(
                venueName: draft.name,
                isDeleting: state.isDeleting,
                onDelete: _onConfirmDelete,
                onCancel: () => setState(() => _confirmDelete = false),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeleteVenueSheet extends StatelessWidget {
  const _DeleteVenueSheet({
    required this.venueName,
    required this.isDeleting,
    required this.onDelete,
    required this.onCancel,
  });

  final String venueName;
  final bool isDeleting;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x8C000000),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSheet),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete $venueName?', style: typography.h3),
                  AppSpacing.spacerSm,
                  Text(
                    "Two upcoming events use this venue. They'll need a new "
                    "venue before they can stay published.",
                    style: typography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.spacerLg,
                  AhButton(
                    label: isDeleting ? 'Deleting…' : 'Delete venue',
                    fullWidth: true,
                    variant: AhButtonVariant.primary,
                    onPressed: isDeleting ? null : onDelete,
                  ),
                  AppSpacing.spacerSm,
                  AhButton(
                    label: 'Keep it',
                    fullWidth: true,
                    variant: AhButtonVariant.tertiary,
                    onPressed: isDeleting ? null : onCancel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
