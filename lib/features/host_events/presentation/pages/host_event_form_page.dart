import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/document_picker_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_badge.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_date_time_field.dart';
import '../../../../shared/widgets/ah_dropdown_field.dart';
import '../../../../shared/widgets/ah_photo_slots.dart';
import '../../../../shared/widgets/ah_ratio_meter.dart';
import '../../../../shared/widgets/ah_slider.dart';
import '../../../../shared/widgets/ah_stepper_input.dart';
import '../../../../shared/widgets/ah_switch_tile.dart';
import '../../../../shared/widgets/ah_text_area.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../../../../shared/utils/scroll_to_first_error.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../domain/entities/host_event.dart'
    show HostEventLifecycleStatus, kRatioBandMaxPoints, kRatioBandMinPoints;
import '../../domain/usecases/cancel_host_event.dart'
    show kMaxCancelReasonLength;
import '../controllers/host_event_form_controller.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';

const _imagePickerExtensions = ['jpg', 'jpeg', 'png'];

/// H-08 · New event — also backs H-E1 "edit event" when [eventId] is
/// non-null. Wired from the H-05 Home "+" add-event button (create) and
/// from tapping an existing event card (edit).
class HostEventFormPage extends ConsumerStatefulWidget {
  const HostEventFormPage({super.key, this.eventId});

  final String? eventId;

  @override
  ConsumerState<HostEventFormPage> createState() => _HostEventFormPageState();
}

class _HostEventFormPageState extends ConsumerState<HostEventFormPage> {
  late final _titleController = TextEditingController();
  late final _descriptionController = TextEditingController();
  late final _ticketPriceController = TextEditingController();
  late final _cancellationTermsController = TextEditingController();

  late final _provider = hostEventFormControllerProvider(widget.eventId);

  /// Keys the field widgets below so a failed submit can scroll the first
  /// erroring one into view, in the same top-to-bottom order they appear
  /// on screen.
  final _fieldKeys = {
    for (final field in const [
      'photos',
      'title',
      'description',
      'format',
      'startAt',
      'endAt',
      'doorsOpenAt',
      'venue',
      'capacity',
      'ticketPrice',
      'cancellationTerms',
      'refundCutoffHoursBeforeStart',
    ])
      field: GlobalKey(),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ticketPriceController.dispose();
    _cancellationTermsController.dispose();
    super.dispose();
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

  int _visiblePhotoSlotCount(int slotCount) {
    return (slotCount + 1).clamp(kMinEventPhotos, kMaxEventPhotos);
  }

  void _onPreview() {
    showAhMessageSheet(
      context,
      message: 'Preview — coming soon',
      tone: AhMessageTone.info,
    );
  }

  /// Pops this page, then shows [message] on the navigator's context so
  /// the pop closes this page rather than the sheet.
  void _popWithMessage(String message, AhMessageTone tone) {
    final navigatorContext = Navigator.of(context).context;
    context.pop();
    if (!navigatorContext.mounted) return;
    showAhMessageSheet(navigatorContext, message: message, tone: tone);
  }

  void _showFailure() {
    final state = ref.read(_provider);
    final error = state.errorMessage;
    if (error != null) {
      showAhMessageSheet(context, message: error, tone: AhMessageTone.error);
    }
    _scrollToFirstError(state.fieldErrors);
  }

  Future<void> _onSaveDraft() async {
    final saved = await ref.read(_provider.notifier).save();
    if (!mounted) return;
    if (saved) {
      _popWithMessage('Draft saved', AhMessageTone.success);
      return;
    }
    _showFailure();
  }

  Future<void> _onSubmitForReview() async {
    final outcome = await ref.read(_provider.notifier).saveAndSubmit();
    if (!mounted) return;
    switch (outcome) {
      case HostEventSubmitOutcome.submitted:
        _popWithMessage(
          "Event submitted for review. It goes live once it's approved.",
          AhMessageTone.success,
        );
      case HostEventSubmitOutcome.savedAsDraftOnly:
        _popWithMessage(
          ref.read(_provider).errorMessage ?? 'Saved as a draft',
          AhMessageTone.error,
        );
      case HostEventSubmitOutcome.failed:
        _showFailure();
    }
  }

  Future<void> _onCancelEvent() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (_) => const _CancelEventSheet(),
    );
    if (reason == null || !mounted) return;
    final cancelled = await ref.read(_provider.notifier).cancelEvent(reason);
    if (!mounted) return;
    if (cancelled) {
      _popWithMessage(
        'Event cancelled. Attendee refunds have been initiated.',
        AhMessageTone.success,
      );
      return;
    }
    _showFailure();
  }

  void _scrollToFirstError(Map<String, String> fieldErrors) {
    scrollToFirstError(_fieldKeys, fieldErrors);
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final draft = state.draft;
    final fieldErrors = state.fieldErrors;
    final selectedVenue = state.selectedVenue;

    if (_titleController.text != draft.title) {
      _titleController.text = draft.title;
    }
    if (_descriptionController.text != draft.description) {
      _descriptionController.text = draft.description;
    }
    if (_ticketPriceController.text !=
        (draft.ticketPriceRupees == 0 ? '' : '${draft.ticketPriceRupees}')) {
      _ticketPriceController.text = draft.ticketPriceRupees == 0
          ? ''
          : '${draft.ticketPriceRupees}';
    }
    if (_cancellationTermsController.text != draft.cancellationTerms) {
      _cancellationTermsController.text = draft.cancellationTerms;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          state.isEdit
              ? (draft.title.isEmpty ? 'Edit event' : draft.title)
              : 'New event',
          style: typography.h3,
        ),
        actions: [
          if (!state.isLoadingEvent && state.loadError == null)
            TextButton(
              onPressed: state.isBusy ? null : _onPreview,
              child: Text(
                'Preview',
                style: typography.bodySm.copyWith(
                  color: AppColors.actionPrimary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: state.isLoadingEvent
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.actionPrimary,
                ),
              )
            : state.loadError != null
            ? _LoadErrorView(
                message: state.loadError!,
                onRetry: notifier.retryLoadEvent,
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
                      // Only drafts can be edited (`PATCH` is draft-only).
                      child: IgnorePointer(
                        ignoring: !state.isEditable,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!state.isEditable) ...[
                              AhAlertBanner(
                                message: _statusMessage(draft.status),
                                tone:
                                    draft.status ==
                                        HostEventLifecycleStatus.cancelled
                                    ? AhBannerTone.warning
                                    : AhBannerTone.info,
                              ),
                              AppSpacing.spacerMd,
                            ],
                            KeyedSubtree(
                              key: _fieldKeys['photos'],
                              child: AhPhotoSlots(
                                count: _visiblePhotoSlotCount(
                                  state.photoSlots.length,
                                ),
                                slots: state.photoSlots,
                                onTapSlot: _pickPhoto,
                              ),
                            ),
                            AppSpacing.spacerXs,
                            Text(
                              fieldErrors['photos'] ??
                                  'Minimum $kMinEventPhotos photos.',
                              style: typography.caption.copyWith(
                                color: fieldErrors['photos'] != null
                                    ? AppColors.statusError
                                    : AppColors.textTertiary,
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['title'],
                              child: AhTextField(
                                label: 'Title',
                                placeholder: 'e.g. Blind Wine & Bad Takes',
                                controller: _titleController,
                                onChanged: notifier.updateTitle,
                                errorText: fieldErrors['title'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['description'],
                              child: AhTextArea(
                                label: 'Description',
                                placeholder: 'What should guests expect?',
                                controller: _descriptionController,
                                onChanged: notifier.updateDescription,
                                errorText: fieldErrors['description'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['format'],
                              child: AhDropdownField(
                                label: 'Format',
                                value: draft.format,
                                options: state.formatOptions,
                                onChanged: notifier.updateFormat,
                                hint: 'Select a format',
                                errorText: fieldErrors['format'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['startAt'],
                              child: AhDateTimeField(
                                label: 'Start date & time',
                                value: draft.startAt,
                                onChanged: notifier.updateStartAt,
                                errorText: fieldErrors['startAt'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['endAt'],
                              child: AhDateTimeField(
                                label: 'End date & time',
                                value: draft.endAt,
                                onChanged: notifier.updateEndAt,
                                errorText: fieldErrors['endAt'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['doorsOpenAt'],
                              child: AhDateTimeField(
                                label: 'Doors open time',
                                value: draft.doorsOpenAt,
                                onChanged: notifier.updateDoorsOpenAt,
                                errorText: fieldErrors['doorsOpenAt'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['venue'],
                              child: AhDropdownField(
                                label: 'Venue',
                                value: selectedVenue?.name ?? '',
                                options: [for (final v in state.venues) v.name],
                                onChanged: (name) {
                                  final venue = state.venues.firstWhere(
                                    (v) => v.name == name,
                                  );
                                  notifier.updateVenue(venue);
                                },
                                hint: state.venues.isEmpty
                                    ? (state.isLoadingVenues
                                          ? 'Loading your venues…'
                                          : 'No saved venues yet — add one '
                                                'first')
                                    : 'Pick a saved venue, or add a new one.',
                                errorText: fieldErrors['venue'],
                              ),
                            ),
                            if (selectedVenue != null) ...[
                              AppSpacing.spacerMd,
                              _LockedAddressCard(
                                address: selectedVenue.address,
                              ),
                            ],
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['capacity'],
                              child: AhStepperInput(
                                label: 'Capacity',
                                value: draft.capacity,
                                min: kEventCapacityMin,
                                max: selectedVenue == null
                                    ? kEventCapacityMax
                                    : selectedVenue.maxCapacity
                                          .clamp(
                                            kEventCapacityMin,
                                            kEventCapacityMax,
                                          )
                                          .toInt(),
                                step: kEventCapacityStep,
                                suffix: 'seats',
                                onChanged: notifier.updateCapacity,
                                errorText: fieldErrors['capacity'],
                              ),
                            ),
                            AppSpacing.spacerXs,
                            Text(
                              'Can be raised later.',
                              style: typography.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['ticketPrice'],
                              child: AhTextField(
                                label: 'Ticket price',
                                placeholder: 'e.g. 1,299',
                                icon: Icons.currency_rupee,
                                controller: _ticketPriceController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final digits = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );
                                  notifier.updateTicketPrice(
                                    int.tryParse(digits) ?? 0,
                                  );
                                },
                                errorText: fieldErrors['ticketPrice'],
                                helperText:
                                    'Locked once the first ticket sells.',
                              ),
                            ),
                            AppSpacing.spacerMd,
                            _RatioBandCard(
                              toleranceBandPoints: draft.toleranceBandPoints,
                              bandLabel: draft.ratioBandLabel,
                              onChanged: notifier.updateToleranceBandPoints,
                            ),
                            AppSpacing.spacerMd,
                            AhCard(
                              child: AhSwitchTile(
                                label:
                                    'Hold back male seats until 8 women have '
                                    'booked',
                                description:
                                    'Held seats release automatically, and the '
                                    'waitlist is notified.',
                                value: draft.holdbackEnabled,
                                onChanged: notifier.toggleHoldback,
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['cancellationTerms'],
                              child: AhTextArea(
                                label: 'Cancellation terms',
                                placeholder:
                                    'e.g. No refunds within 24h of doors.',
                                controller: _cancellationTermsController,
                                onChanged: notifier.updateCancellationTerms,
                                errorText: fieldErrors['cancellationTerms'],
                              ),
                            ),
                            AppSpacing.spacerMd,
                            KeyedSubtree(
                              key: _fieldKeys['refundCutoffHoursBeforeStart'],
                              child: AhStepperInput(
                                label: 'Refund cutoff',
                                value: draft.refundCutoffHoursBeforeStart,
                                min: 0,
                                max: 168,
                                step: 1,
                                suffix: 'hours before start',
                                onChanged: notifier.updateRefundCutoffHours,
                                errorText:
                                    fieldErrors['refundCutoffHoursBeforeStart'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.isEditable || state.canCancel)
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
                        child: state.isEditable
                            ? Row(
                                children: [
                                  Expanded(
                                    child: AhButton(
                                      label: 'Save draft',
                                      variant: AhButtonVariant.secondary,
                                      onPressed: state.isBusy
                                          ? null
                                          : _onSaveDraft,
                                    ),
                                  ),
                                  AppSpacing.spacerSm,
                                  Expanded(
                                    flex: 2,
                                    child: AhButton(
                                      label: state.isSaving
                                          ? 'Submitting…'
                                          : 'Submit for review',
                                      onPressed: state.isBusy
                                          ? null
                                          : _onSubmitForReview,
                                    ),
                                  ),
                                ],
                              )
                            : AhButton(
                                label: state.isCancelling
                                    ? 'Cancelling…'
                                    : 'Cancel event',
                                variant: AhButtonVariant.destructive,
                                fullWidth: true,
                                onPressed: state.isBusy ? null : _onCancelEvent,
                              ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

String _statusMessage(HostEventLifecycleStatus status) {
  return switch (status) {
    HostEventLifecycleStatus.submitted =>
      "Submitted for review. It goes live once it's approved, and can't be "
          'edited in the meantime.',
    HostEventLifecycleStatus.published =>
      "This event is live. Published events can't be edited.",
    HostEventLifecycleStatus.cancelled =>
      'This event was cancelled and attendee refunds were initiated.',
    HostEventLifecycleStatus.completed => 'This event has ended.',
    HostEventLifecycleStatus.draft ||
    HostEventLifecycleStatus.unknown => "This event can't be edited.",
  };
}

/// Asks for the required cancellation reason (`CancelEventDto.reason`,
/// max [kMaxCancelReasonLength]) and pops it, or null if the host backs out.
class _CancelEventSheet extends StatefulWidget {
  const _CancelEventSheet();

  @override
  State<_CancelEventSheet> createState() => _CancelEventSheetState();
}

class _CancelEventSheetState extends State<_CancelEventSheet> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Add a reason for cancelling.');
      return;
    }
    if (reason.length > kMaxCancelReasonLength) {
      setState(() => _error = 'Max $kMaxCancelReasonLength characters.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel this event?', style: typography.h2),
            AppSpacing.spacerSm,
            Text(
              "Every attendee will be refunded. This can't be undone.",
              style: typography.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.spacerMd,
            AhTextArea(
              label: 'Reason',
              placeholder: 'e.g. Venue maintenance emergency',
              controller: _reasonController,
              onChanged: (_) => setState(() => _error = null),
              errorText: _error,
              helperText:
                  '${_reasonController.text.trim().length}/'
                  '$kMaxCancelReasonLength',
            ),
            AppSpacing.spacerLg,
            AhButton(
              label: 'Cancel event',
              variant: AhButtonVariant.destructive,
              fullWidth: true,
              onPressed: _confirm,
            ),
            AppSpacing.spacerSm,
            AhButton(
              label: 'Keep event',
              variant: AhButtonVariant.tertiary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
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
              "Couldn't load this event",
              style: typography.h3,
              textAlign: TextAlign.center,
            ),
            AppSpacing.spacerSm,
            Text(
              message,
              style: typography.bodySm.copyWith(color: AppColors.textSecondary),
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

class _LockedAddressCard extends StatelessWidget {
  const _LockedAddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 18,
            color: AppColors.textTertiary,
          ),
          AppSpacing.spacerSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: typography.bodySm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppSpacing.spacerXs,
                Text(
                  'From the venue record. Edit it under Venues.',
                  style: typography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatioBandCard extends StatelessWidget {
  const _RatioBandCard({
    required this.toleranceBandPoints,
    required this.bandLabel,
    required this.onChanged,
  });

  final int toleranceBandPoints;
  final String bandLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return AhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.balance,
                size: 18,
                color: AppColors.trustVerified,
              ),
              AppSpacing.spacerSm,
              Text(
                'Ratio band',
                style: typography.bodySm.copyWith(fontWeight: FontWeight.w600),
              ),
              AppSpacing.spacerSm,
              AhBadge(label: bandLabel, tone: AhTone.trust),
            ],
          ),
          AppSpacing.spacerMd,
          // Brand-new event, zero sales yet — a static, neutral 50:50
          // preview bar. Real sold/male-pct data only exists on the live
          // event dashboard (out of scope here).
          const AhRatioMeter(),
          AppSpacing.spacerMd,
          Text(
            'No gender may exceed 60% of seats sold.',
            style: typography.caption.copyWith(color: AppColors.textTertiary),
          ),
          AppSpacing.spacerMd,
          AhSlider(
            label: 'Tolerance',
            value: toleranceBandPoints,
            min: kRatioBandMinPoints,
            max: kRatioBandMaxPoints,
            valueLabel: bandLabel,
            helperText: 'Drag left to tighten the band.',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
