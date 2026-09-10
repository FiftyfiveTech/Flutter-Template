import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/document_picker_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_badge.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_date_field.dart';
import '../../../../shared/widgets/ah_switch_tile.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../../domain/entities/host_document_selection.dart';
import '../../domain/entities/host_document_type.dart';
import '../../domain/entities/host_type.dart';
import '../controllers/host_documents_controller.dart'
    show
        DocumentUploadState,
        DocumentUploadStatus,
        hostDocumentsControllerProvider;
import '../controllers/host_type_controller.dart';
import '../widgets/step_progress_dots.dart';

const _documentFileExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

/// H-03 · Documents — collects payout details for every host, plus the
/// address proof / FSSAI / excise licence set that only applies to venues.
class HostDocumentsPage extends ConsumerStatefulWidget {
  const HostDocumentsPage({super.key});

  @override
  ConsumerState<HostDocumentsPage> createState() => _HostDocumentsPageState();
}

class _HostDocumentsPageState extends ConsumerState<HostDocumentsPage> {
  final _upiIdController = TextEditingController();

  @override
  void dispose() {
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(HostDocumentType type) async {
    try {
      final result = await ref
          .read(documentPickerProvider)
          .pickFile(allowedExtensions: _documentFileExtensions);
      if (result == null || !mounted) return;

      ref
          .read(hostDocumentsControllerProvider.notifier)
          .selectDocument(
            type,
            HostDocumentSelection(
              fileName: result.fileName,
              sizeBytes: result.sizeBytes,
            ),
            result.path,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the file picker")),
      );
    }
  }

  Future<void> _onSubmit(HostType hostType) async {
    final notifier = ref.read(hostDocumentsControllerProvider.notifier);
    final isValid = notifier.submit(hostType: hostType);
    if (!isValid) return;

    final submitted = await notifier.submitForReview(hostType: hostType);
    if (!submitted) {
      final submitError = ref.read(hostDocumentsControllerProvider).submitError;
      if (submitError != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(submitError)));
      }
      return;
    }
    if (!mounted) return;

    // pushReplacement, not push: the wizard is done once submitted — back
    // shouldn't return to the documents form.
    context.pushReplacement('/host/signup/host-type/documents/verification');
  }

  Widget _documentRow(
    HostDocumentType type,
    HostDocumentSelection? selection,
    String? errorText,
    DocumentUploadState? uploadState,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final isSelected = selection != null;
    final hasError = errorText != null && errorText.isNotEmpty;
    final isUploading = uploadState?.status == DocumentUploadStatus.uploading;
    final uploadFailed = uploadState?.status == DocumentUploadStatus.error;
    final uploaded = uploadState?.status == DocumentUploadStatus.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AhCard(
          onTap: () => _pickDocument(type),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  uploaded
                      ? Icons.check_circle
                      : isSelected
                      ? (uploadFailed
                            ? Icons.error_outline
                            : Icons.insert_drive_file)
                      : Icons.upload_file,
                  size: 20,
                  color: uploaded
                      ? AppColors.statusSuccess
                      : uploadFailed
                      ? AppColors.statusError
                      : isSelected
                      ? AppColors.actionPrimary
                      : AppColors.textTertiary,
                ),
              AppSpacing.spacerMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.label, style: typography.body),
                    if (isSelected) ...[
                      AppSpacing.spacerXs,
                      Text(
                        selection.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AhBadge(
                label: isUploading
                    ? 'Uploading…'
                    : uploadFailed
                    ? 'Retry'
                    : uploaded
                    ? 'Uploaded'
                    : isSelected
                    ? 'Selected'
                    : 'Add file',
                tone: uploadFailed
                    ? AhTone.error
                    : uploaded
                    ? AhTone.success
                    : AhTone.accent,
              ),
            ],
          ),
        ),
        if (hasError) ...[
          AppSpacing.spacerXs,
          Text(
            errorText,
            style: typography.caption.copyWith(color: AppColors.statusError),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final hostType =
        ref.watch(hostTypeControllerProvider) ?? HostType.individualOperator;
    final formState = ref.watch(hostDocumentsControllerProvider);
    final notifier = ref.read(hostDocumentsControllerProvider.notifier);
    final isVenue = hostType == HostType.venue;
    final documents = formState.draft.documents;
    final fieldErrors = formState.fieldErrors;
    final uploadStates = formState.uploadStates;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Verification documents', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
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
                    const StepProgressDots(currentStep: 3, totalSteps: 4),
                    AppSpacing.spacerMd,
                    // TODO(host-onboarding): same Bangalore-only pilot scoping
                    // as host_signup_page.dart's city field — source from
                    // Platform Foundation config once a second city launches.
                    AhBadge(
                      label: '${hostType.label} · Bangalore',
                      tone: AhTone.trust,
                    ),
                    AppSpacing.spacerMd,
                    Text(
                      'REQUIRED FOR EVERY HOST',
                      style: typography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    AppSpacing.spacerSm,
                    _documentRow(
                      HostDocumentType.businessRegistration,
                      documents[HostDocumentType.businessRegistration],
                      fieldErrors[HostDocumentType.businessRegistration.name],
                      uploadStates[HostDocumentType.businessRegistration],
                    ),
                    AppSpacing.spacerSm,
                    _documentRow(
                      HostDocumentType.panCard,
                      documents[HostDocumentType.panCard],
                      fieldErrors[HostDocumentType.panCard.name],
                      uploadStates[HostDocumentType.panCard],
                    ),
                    AppSpacing.spacerMd,
                    AhTextField(
                      label: 'UPI ID for payouts',
                      placeholder: 'business@upi',
                      helperText:
                          'Verified with a penny-drop before your first payout.',
                      controller: _upiIdController,
                      onChanged: notifier.updateUpiId,
                      errorText: fieldErrors['upiId'],
                    ),
                    if (isVenue) ...[
                      AppSpacing.spacerLg,
                      Text(
                        'ADDITIONAL · VENUE',
                        style: typography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      AppSpacing.spacerSm,
                      _documentRow(
                        HostDocumentType.addressProof,
                        documents[HostDocumentType.addressProof],
                        fieldErrors[HostDocumentType.addressProof.name],
                        uploadStates[HostDocumentType.addressProof],
                      ),
                      AppSpacing.spacerMd,
                      AhSwitchTile(
                        label: 'We serve food',
                        description: 'Requires an FSSAI registration.',
                        value: formState.draft.servesFood,
                        onChanged: notifier.setServesFood,
                      ),
                      AppSpacing.spacerSm,
                      _documentRow(
                        HostDocumentType.fssaiRegistration,
                        documents[HostDocumentType.fssaiRegistration],
                        fieldErrors[HostDocumentType.fssaiRegistration.name],
                        uploadStates[HostDocumentType.fssaiRegistration],
                      ),
                      AppSpacing.spacerMd,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AhDateField(
                              label: 'FSSAI valid from',
                              value: formState.draft.fssaiLicenceValidFrom,
                              onChanged: notifier.updateFssaiLicenceValidFrom,
                              errorText: fieldErrors['fssaiLicenceValidFrom'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          Expanded(
                            child: AhDateField(
                              label: 'FSSAI valid to',
                              value: formState.draft.fssaiLicenceValidTo,
                              onChanged: notifier.updateFssaiLicenceValidTo,
                              errorText: fieldErrors['fssaiLicenceValidTo'],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.spacerMd,
                      AhSwitchTile(
                        label: 'We serve alcohol',
                        description: 'Requires the state excise licence.',
                        value: formState.draft.servesAlcohol,
                        onChanged: notifier.setServesAlcohol,
                      ),
                      AppSpacing.spacerSm,
                      _documentRow(
                        HostDocumentType.exciseLicence,
                        documents[HostDocumentType.exciseLicence],
                        fieldErrors[HostDocumentType.exciseLicence.name],
                        uploadStates[HostDocumentType.exciseLicence],
                      ),
                      AppSpacing.spacerMd,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AhDateField(
                              label: 'Excise valid from',
                              value: formState.draft.exciseLicenceValidFrom,
                              onChanged: notifier.updateExciseLicenceValidFrom,
                              errorText: fieldErrors['exciseLicenceValidFrom'],
                            ),
                          ),
                          AppSpacing.spacerMd,
                          Expanded(
                            child: AhDateField(
                              label: 'Excise valid to',
                              value: formState.draft.exciseLicenceValidTo,
                              onChanged: notifier.updateExciseLicenceValidTo,
                              errorText: fieldErrors['exciseLicenceValidTo'],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      AppSpacing.spacerLg,
                      const AhAlertBanner(
                        message:
                            'Clubs, communities and individual operators '
                            'skip the address proof, FSSAI and excise '
                            'steps.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: AhButton(
                  label: formState.isSubmitting
                      ? 'Please wait…'
                      : 'Submit for review',
                  fullWidth: true,
                  onPressed: formState.isSubmitting
                      ? null
                      : () => _onSubmit(hostType),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
