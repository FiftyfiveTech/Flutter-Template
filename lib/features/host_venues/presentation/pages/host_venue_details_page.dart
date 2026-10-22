import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/document_picker_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_async_search_field.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_confirm_dialog.dart';
import '../../../../shared/widgets/ah_chip_select.dart';
import '../../../../shared/widgets/ah_photo_slots.dart';
import '../../../../shared/widgets/ah_stepper_input.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../../../../shared/utils/scroll_to_first_error.dart';
import '../../../host_onboarding/domain/entities/city.dart';
import '../../../host_onboarding/presentation/controllers/city_search_providers.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';
import '../controllers/host_venue_form_controller.dart'
    show
        HostVenueFormState,
        hostVenueFormControllerProvider,
        kMaxVenuePhotos,
        kMinVenuePhotos;

const _imagePickerExtensions = ['jpg', 'jpeg', 'png'];

/// H-07 · Venue details — also backs H-E0 "add a venue" when [venueId] is
/// null. Editing an existing venue updates every upcoming event held there.
/// The full venue (with its short-lived photo urls) is fetched fresh from
/// the backend rather than passed in via navigation, since the H-06 list
/// response never includes photos.
class HostVenueDetailsPage extends ConsumerStatefulWidget {
  const HostVenueDetailsPage({super.key, this.venueId});

  final String? venueId;

  @override
  ConsumerState<HostVenueDetailsPage> createState() =>
      _HostVenueDetailsPageState();
}

class _HostVenueDetailsPageState extends ConsumerState<HostVenueDetailsPage> {
  late final _nameController = TextEditingController();
  late final _addLine1Controller = TextEditingController();
  late final _addLine2Controller = TextEditingController();
  late final _localityController = TextEditingController();
  late final _pincodeController = TextEditingController();
  bool _controllersSeeded = false;

  late final _provider = hostVenueFormControllerProvider(widget.venueId);

  /// Keys the field widgets below so a failed save can scroll the first
  /// erroring one into view, in the same top-to-bottom order they appear
  /// on screen.
  final _fieldKeys = {
    for (final field in const [
      'photos',
      'venueTypes',
      'name',
      'addLine1',
      'addLine2',
      'locality',
      'city',
      'pincode',
      'maxCapacity',
    ])
      field: GlobalKey(),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _addLine1Controller.dispose();
    _addLine2Controller.dispose();
    _localityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  /// Text controllers can only be seeded once the fetched venue lands (for
  /// edit mode) — done here rather than in `initState` since the draft
  /// isn't available until the async load completes.
  void _seedControllersIfNeeded(HostVenueFormState state) {
    if (_controllersSeeded) return;
    if (widget.venueId != null && state.isLoadingVenue) return;
    _controllersSeeded = true;
    _nameController.text = state.draft.name;
    _addLine1Controller.text = state.draft.addLine1;
    _addLine2Controller.text = state.draft.addLine2;
    _localityController.text = state.draft.locality;
    _pincodeController.text = state.draft.pincode;
  }

  /// Always shows one empty "add" slot past the photos already picked so
  /// far — down to [kMinVenuePhotos] shown at minimum — up to the
  /// backend's [kMaxVenuePhotos] cap, past which no empty slot is offered.
  int _visiblePhotoSlotCount(HostVenueFormState state) {
    return (state.photoSlots.length + 1).clamp(
      kMinVenuePhotos,
      kMaxVenuePhotos,
    );
  }

  Future<void> _pickPhoto(int index) async {
    try {
      final result = await ref
          .read(documentPickerProvider)
          .pickFile(allowedExtensions: _imagePickerExtensions);
      if (result == null || !mounted) return;
      ref
          .read(_provider.notifier)
          .pickPhotoAt(index, result.path, result.fileName);
    } catch (_) {
      if (!mounted) return;
      showAhMessageSheet(
        context,
        message: "Couldn't open the photo picker",
        tone: AhMessageTone.error,
      );
    }
  }

  Future<void> _onSave() async {
    final wasEdit = ref.read(_provider).isEdit;
    final saved = await ref.read(_provider.notifier).save();
    if (!mounted) return;
    if (saved) {
      // Show on the navigator's context after popping, so the pop
      // closes this page rather than the sheet.
      final navigatorContext = Navigator.of(context).context;
      context.pop();
      if (!navigatorContext.mounted) return;
      showAhMessageSheet(
        navigatorContext,
        message: wasEdit
            ? 'Venue updated successfully'
            : 'Venue created successfully',
        tone: AhMessageTone.success,
      );
      return;
    }

    final state = ref.read(_provider);
    final error = state.errorMessage;
    if (error != null) {
      showAhMessageSheet(context, message: error, tone: AhMessageTone.error);
    }
    _scrollToFirstError(state.fieldErrors);
  }

  void _scrollToFirstError(Map<String, String> fieldErrors) {
    scrollToFirstError(_fieldKeys, fieldErrors);
  }

  /// Warns first; only a confirmed delete calls `DELETE /api/v1/venues/{id}`.
  Future<void> _onDelete() async {
    final name = ref.read(_provider).draft.name.trim();
    final confirmed = await showAhConfirmDialog(
      context,
      title: name.isEmpty ? 'Delete this venue?' : 'Delete $name?',
      message: "It'll be removed from your saved venues. This can't be undone.",
      confirmLabel: 'Delete venue',
      cancelLabel: 'Keep venue',
    );
    if (!confirmed || !mounted) return;
    final deleted = await ref.read(_provider.notifier).delete();
    if (!mounted) return;
    if (deleted) {
      final navigatorContext = Navigator.of(context).context;
      context.pop();
      if (!navigatorContext.mounted) return;
      showAhMessageSheet(
        navigatorContext,
        message: 'Venue deleted.',
        tone: AhMessageTone.success,
      );
      return;
    }
    final error = ref.read(_provider).errorMessage;
    if (error != null) {
      showAhMessageSheet(context, message: error, tone: AhMessageTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final draft = state.draft;
    final fieldErrors = state.fieldErrors;
    _seedControllersIfNeeded(state);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          state.isEdit ? draft.name : 'Add a venue',
          style: typography.h3,
        ),
      ),
      body: SafeArea(
        child: state.isLoadingVenue
            ? Center(
                child: CircularProgressIndicator(
                  color: context.colors.actionPrimary,
                ),
              )
            : state.loadError != null
            ? _LoadErrorView(
                message: state.loadError!,
                onRetry: notifier.retryLoad,
              )
            : Column(
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
                            'Venue photos',
                            style: typography.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.spacerSm,
                          KeyedSubtree(
                            key: _fieldKeys['photos'],
                            child: AhPhotoSlots(
                              count: _visiblePhotoSlotCount(state),
                              slots: state.photoSlots,
                              onTapSlot: _pickPhoto,
                              onRemoveSlot: ref
                                  .read(_provider.notifier)
                                  .removePhotoAt,
                            ),
                          ),
                          AppSpacing.spacerXs,
                          Text(
                            fieldErrors['photos'] ??
                                'Minimum $kMinVenuePhotos, up to '
                                    '$kMaxVenuePhotos.',
                            style: typography.caption.copyWith(
                              color: fieldErrors['photos'] != null
                                  ? context.colors.statusError
                                  : context.colors.textTertiary,
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['venueTypes'],
                            child: AhAsyncSearchField<String>(
                              label: 'Venue type',
                              value: '',
                              placeholder: 'Search venue types',
                              search: (query) async =>
                                  notifier.searchVenueTypes(query),
                              displayStringForOption: (type) => type,
                              onSelected: notifier.addVenueType,
                              debounce: Duration.zero,
                              searchOnEmptyQuery: true,
                              clearOnSelect: true,
                            ),
                          ),
                          if (draft.allowedVenueTypes.isNotEmpty) ...[
                            AppSpacing.spacerSm,
                            AhChipSelect(
                              options: draft.allowedVenueTypes,
                              selected: draft.allowedVenueTypes,
                              onToggle: notifier.toggleVenueType,
                              showRemoveIcon: true,
                            ),
                          ],
                          AppSpacing.spacerXs,
                          Text(
                            fieldErrors['venueTypes'] ??
                                'Pick every type that describes this '
                                    'venue.',
                            style: typography.caption.copyWith(
                              color: fieldErrors['venueTypes'] != null
                                  ? context.colors.statusError
                                  : context.colors.textTertiary,
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['name'],
                            child: AhTextField(
                              label: 'Venue name',
                              placeholder: 'e.g. Toit, Indiranagar',
                              controller: _nameController,
                              onChanged: notifier.updateName,
                              errorText: fieldErrors['name'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['addLine1'],
                            child: AhTextField(
                              label: 'Address line 1',
                              placeholder: 'e.g. 12, 100 Feet Road',
                              controller: _addLine1Controller,
                              onChanged: notifier.updateAddLine1,
                              errorText: fieldErrors['addLine1'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['addLine2'],
                            child: AhTextField(
                              label: 'Address line 2',
                              placeholder: '(optional)',
                              controller: _addLine2Controller,
                              onChanged: notifier.updateAddLine2,
                              errorText: fieldErrors['addLine2'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['locality'],
                            child: AhTextField(
                              label: 'Locality',
                              placeholder: 'e.g. Indiranagar',
                              controller: _localityController,
                              onChanged: notifier.updateLocality,
                              errorText: fieldErrors['locality'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['city'],
                            child: AhAsyncSearchField<City>(
                              label: 'City',
                              value: draft.cityName,
                              placeholder: 'Search for a city',
                              search: (query) => ref.read(
                                citySearchResultsProvider(query).future,
                              ),
                              displayStringForOption: (city) => city.name,
                              onSelected: notifier.updateCity,
                              errorText: fieldErrors['city'],
                              searchOnEmptyQuery: true,
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['pincode'],
                            child: AhTextField(
                              label: 'Pincode',
                              placeholder: 'e.g. 560038',
                              controller: _pincodeController,
                              onChanged: notifier.updatePincode,
                              keyboardType: TextInputType.number,
                              errorText: fieldErrors['pincode'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          KeyedSubtree(
                            key: _fieldKeys['maxCapacity'],
                            child: AhStepperInput(
                              label: 'Max capacity at this venue',
                              value: draft.maxCapacity,
                              min: 1,
                              max: 300,
                              step: 1,
                              suffix: 'seats',
                              onChanged: notifier.updateMaxCapacity,
                              errorText: fieldErrors['maxCapacity'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          // AhAlertBanner(
                          //   message:
                          //       'The exact address is only released to a '
                          //       "member after they book — this stays "
                          //       'true for every event at this venue.',
                          // ),
                          if (state.isEdit) ...[
                            AppSpacing.spacerLg,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: context.colors.borderDefault,
                                  ),
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
                                        : _onDelete,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: context.colors.statusError,
                                    ),
                                    label: Text(
                                      state.isDeleting
                                          ? 'Deleting…'
                                          : 'Delete this venue',
                                      style: typography.bodySm.copyWith(
                                        color: context.colors.statusError,
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
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.colors.borderDefault),
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
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load this venue",
              style: typography.h3,
              textAlign: TextAlign.center,
            ),
            AppSpacing.spacerSm,
            Text(
              message,
              style: typography.bodySm.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.spacerMd,
            AhButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
