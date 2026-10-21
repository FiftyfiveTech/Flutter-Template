import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_alert_banner.dart';
import '../../../../shared/widgets/ah_avatar.dart';
import '../../../../shared/widgets/ah_badge.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../../../shared/widgets/ah_segmented_control.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../../domain/entities/check_in_attendee.dart';
import '../../domain/entities/check_in_result.dart';
import '../controllers/check_in_controller.dart';
import '../widgets/check_in_connection_pill.dart';
import '../widgets/check_in_copy.dart';
import '../widgets/check_in_result_card.dart';

enum GuestFilter { all, checkedIn, notYet, noShow }

/// Search + filter over the guest list, A–Z.
@visibleForTesting
List<CheckInAttendee> filterGuests(
  List<CheckInAttendee> attendees, {
  required String query,
  required GuestFilter filter,
}) {
  final q = query.trim().toLowerCase();
  final matches = attendees.where((a) {
    if (q.isNotEmpty && !a.firstName.toLowerCase().contains(q)) return false;
    return switch (filter) {
      GuestFilter.all => true,
      GuestFilter.checkedIn => a.checkedIn,
      GuestFilter.notYet => !a.checkedIn && !a.noShow,
      GuestFilter.noShow => a.noShow,
    };
  }).toList();
  matches.sort(
    (a, b) => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
  );
  return matches;
}

/// HOST-OPS-03 · Guest list with check-in status and no-shows; tapping a
/// guest who isn't in yet opens the manual check-in fallback.
class CheckInGuestListPage extends ConsumerStatefulWidget {
  const CheckInGuestListPage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<CheckInGuestListPage> createState() =>
      _CheckInGuestListPageState();
}

class _CheckInGuestListPageState extends ConsumerState<CheckInGuestListPage> {
  final _search = TextEditingController();
  var _query = '';
  var _filter = GuestFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final provider = checkInControllerProvider(widget.eventId);
    final state = ref.watch(provider);
    final hasNoShows = state.attendees.any((a) => a.noShow);
    final filters = [
      GuestFilter.all,
      GuestFilter.checkedIn,
      GuestFilter.notYet,
      if (hasNoShows) GuestFilter.noShow,
    ];
    // The No-show tab disappears if the list reloads without any.
    final filter = filters.contains(_filter) ? _filter : GuestFilter.all;
    final guests = filterGuests(state.attendees, query: _query, filter: filter);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Guest list', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: CheckInConnectionPill(state: state)),
                      AppSpacing.spacerSm,
                      Text(
                        '${state.checkedInCount} / ${state.totalCount} in',
                        style: typography.bodySm.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.spacerSm,
                  AhTextField(
                    label: 'Search guests',
                    placeholder: 'First name',
                    icon: Icons.search,
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  AppSpacing.spacerSm,
                  AhSegmentedControl(
                    labels: [for (final f in filters) _filterLabel(f)],
                    selectedIndex: filters.indexOf(filter),
                    onChanged: (i) => setState(() => _filter = filters[i]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: context.colors.actionPrimary,
                onRefresh: ref.read(provider.notifier).refresh,
                child: _buildList(context, state, guests),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    CheckInState state,
    List<CheckInAttendee> guests,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    const padding = EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      AppSpacing.sm,
      AppSpacing.gutter,
      AppSpacing.lg,
    );

    if (state.isLoading && state.attendees.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.actionPrimary),
      );
    }
    if (state.attendees.isEmpty) {
      // Scrollable so pull-to-refresh still works on an empty list.
      return ListView(
        padding: padding,
        children: [
          if (state.loadErrorMessage != null)
            AhAlertBanner(
              message:
                  "Couldn't load the guest list: ${state.loadErrorMessage}",
              tone: AhBannerTone.error,
            )
          else
            Text(
              'No guests have booked yet.',
              style: typography.body.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      );
    }
    if (guests.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          Text(
            'No guests match.',
            style: typography.body.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: padding,
      itemCount: guests.length,
      separatorBuilder: (_, _) => AppSpacing.spacerSm,
      itemBuilder: (context, i) {
        final guest = guests[i];
        return _GuestRow(
          guest: guest,
          onTap: guest.checkedIn || guest.noShow
              ? null
              : () => _confirmManualCheckIn(guest),
        );
      },
    );
  }

  Future<void> _confirmManualCheckIn(CheckInAttendee guest) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surfaceCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (_) =>
          _ManualCheckInSheet(eventId: widget.eventId, guest: guest),
    );
  }

  String _filterLabel(GuestFilter filter) => switch (filter) {
    GuestFilter.all => 'All',
    GuestFilter.checkedIn => 'In',
    GuestFilter.notYet => 'Not yet',
    GuestFilter.noShow => 'No-show',
  };
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({required this.guest, this.onTap});

  final CheckInAttendee guest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final scannedAt = guest.scannedAt;
    final subtitle = [
      if (guest.ticketTypeName != null && guest.ticketTypeName!.isNotEmpty)
        guest.ticketTypeName!,
      if (guest.checkedIn && scannedAt != null)
        'In at ${formatCheckInTime(scannedAt)}',
    ].join(' · ');

    final (label, tone) = guest.isPendingSync
        ? ('Waiting to sync', AhTone.warning)
        : guest.checkedIn
        ? ('Checked in', AhTone.success)
        : guest.noShow
        ? ('No-show', AhTone.error)
        : ('Not yet', AhTone.info);

    return AhCard(
      onTap: onTap,
      child: Row(
        children: [
          AhAvatar(name: guest.firstName, photoUrl: guest.photoUrl),
          AppSpacing.spacerMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.firstName,
                  style: typography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: typography.caption.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.spacerSm,
          AhBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}

/// Two-step manual check-in: the host compares the guest's face with the
/// photo before confirming, since this skips the QR's signature check.
class _ManualCheckInSheet extends ConsumerStatefulWidget {
  const _ManualCheckInSheet({required this.eventId, required this.guest});

  final String eventId;
  final CheckInAttendee guest;

  @override
  ConsumerState<_ManualCheckInSheet> createState() =>
      _ManualCheckInSheetState();
}

class _ManualCheckInSheetState extends ConsumerState<_ManualCheckInSheet> {
  var _busy = false;
  CheckInResult? _result;

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    final result = await ref
        .read(checkInControllerProvider(widget.eventId).notifier)
        .manualCheckIn(widget.guest);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final guest = widget.guest;
    final result = _result;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: result != null
            ? CheckInResultCard(
                result: result,
                onDismiss: () => Navigator.of(context).pop(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AhAvatar(
                    name: guest.firstName,
                    photoUrl: guest.photoUrl,
                    radius: AppSpacing.xxl,
                  ),
                  AppSpacing.spacerMd,
                  Text(guest.firstName, style: typography.h2),
                  if (guest.ticketTypeName != null) ...[
                    AppSpacing.spacerXs,
                    Text(
                      guest.ticketTypeName!,
                      style: typography.bodySm.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                  AppSpacing.spacerMd,
                  Text(
                    'Check that this is the person in front of you before '
                    'checking them in by name.',
                    textAlign: TextAlign.center,
                    style: typography.body.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  AppSpacing.spacerLg,
                  AhButton(
                    label: _busy ? 'Checking in…' : 'Check in',
                    fullWidth: true,
                    onPressed: _busy ? null : _checkIn,
                  ),
                  AppSpacing.spacerSm,
                  AhButton(
                    label: 'Cancel',
                    variant: AhButtonVariant.tertiary,
                    fullWidth: true,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
      ),
    );
  }
}
