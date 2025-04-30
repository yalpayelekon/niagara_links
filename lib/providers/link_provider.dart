import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/link.dart';

final linkListProvider = StateNotifierProvider<LinkListNotifier, List<Link>>(
  (ref) => LinkListNotifier(),
);

class LinkListNotifier extends StateNotifier<List<Link>> {
  LinkListNotifier() : super([]);

  void addLink(Link link) {
    state = [...state, link];
  }

  void removeLink(String id) {
    state = state.where((l) => l.id != id).toList();
  }
}
