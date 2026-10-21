import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/document_picker_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_avatar.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../controllers/host_edit_profile_controller.dart';

/// Edit profile — photo, first/last name and business name, saved via
/// `PATCH /api/v1/host/profile`. Opened from the profile card on H-12.
class HostEditProfilePage extends ConsumerStatefulWidget {
  const HostEditProfilePage({super.key});

  @override
  ConsumerState<HostEditProfilePage> createState() =>
      _HostEditProfilePageState();
}

class _HostEditProfilePageState extends ConsumerState<HostEditProfilePage> {
  static const _photoExtensions = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
  static const _avatarRadius = 40.0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _businessNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ref
        .read(documentPickerProvider)
        .pickFile(allowedExtensions: _photoExtensions);
    if (picked == null) return;
    ref.read(hostEditProfileControllerProvider.notifier).pickPhoto(picked.path);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(hostEditProfileControllerProvider.notifier)
        .save(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          businessName: _businessNameController.text,
        );
    if (!mounted) return;
    if (saved) {
      context.pop();
      return;
    }
    final submitError = ref.read(hostEditProfileControllerProvider).submitError;
    if (submitError != null) {
      showAhMessageSheet(
        context,
        message: submitError,
        tone: AhMessageTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostEditProfileControllerProvider);

    // Prefill once the cached profile has loaded.
    ref.listen(hostEditProfileControllerProvider.select((s) => s.isLoading), (
      wasLoading,
      isLoading,
    ) {
      if (wasLoading != true || isLoading) return;
      final loaded = ref.read(hostEditProfileControllerProvider);
      _firstNameController.text = loaded.firstName;
      _lastNameController.text = loaded.lastName;
      _businessNameController.text = loaded.businessName;
    });

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Edit profile', style: typography.h3),
      ),
      body: SafeArea(
        child: state.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: context.colors.actionPrimary,
                ),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Semantics(
                              button: true,
                              label: 'Change profile photo',
                              child: GestureDetector(
                                onTap: state.isSaving ? null : _pickPhoto,
                                child: AhAvatar(
                                  name: state.businessName,
                                  photoPath:
                                      state.pickedPhotoPath ?? state.photoPath,
                                  radius: _avatarRadius,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: AhButton(
                              label: 'Change photo',
                              variant: AhButtonVariant.tertiary,
                              onPressed: state.isSaving ? null : _pickPhoto,
                            ),
                          ),
                          AppSpacing.spacerMd,
                          AhTextField(
                            label: 'First name',
                            placeholder: 'e.g. Aarav',
                            controller: _firstNameController,
                            onChanged: (_) {},
                            errorText: state.fieldErrors['firstName'],
                          ),
                          AppSpacing.spacerMd,
                          AhTextField(
                            label: 'Last name',
                            placeholder: 'e.g. Shetty',
                            controller: _lastNameController,
                            onChanged: (_) {},
                            errorText: state.fieldErrors['lastName'],
                          ),
                          AppSpacing.spacerMd,
                          AhTextField(
                            label: 'Business or organiser name',
                            placeholder: 'e.g. Cellar Door Collective',
                            controller: _businessNameController,
                            onChanged: (_) {},
                            errorText: state.fieldErrors['businessName'],
                          ),
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
                        label: 'Save',
                        fullWidth: true,
                        isLoading: state.isSaving,
                        onPressed: _save,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
