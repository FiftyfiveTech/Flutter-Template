import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/features/host_events/domain/entities/host_event.dart';
import 'package:host_mobile_app/features/host_events/presentation/controllers/host_event_form_controller.dart';

void main() {
  final published = HostEvent.empty.copyWith(
    status: HostEventLifecycleStatus.published,
  );

  test('a published event that has not ended can be cancelled', () {
    final state = HostEventFormState(draft: published, isEdit: true);
    expect(state.canCancel, isTrue);
  });

  test('an ended event offers no actions', () {
    final state = HostEventFormState(
      draft: published,
      isEdit: true,
      hasEnded: true,
    );
    expect(state.canCancel, isFalse);
    expect(state.isEditable, isFalse);
  });
}
