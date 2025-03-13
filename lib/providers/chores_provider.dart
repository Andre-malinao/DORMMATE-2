import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'roommate_provider.dart';

class ChoresProvider with ChangeNotifier {
  final RoommateProvider roommateProvider;
  Box? _choresBox;

  ChoresProvider(this.roommateProvider);

  Future<void> _ensureBoxesInitialized() async {
    _choresBox ??= await Hive.openBox('chores');
  }

  Future<void> deleteChoresForUser(String userId) async {
    await _ensureBoxesInitialized();
    final choresList = _choresBox!.values.toList();

    for (int i = choresList.length - 1; i >= 0; i--) {
      if (choresList[i]['userId'] == userId) {
        await _choresBox!.deleteAt(i);
      }
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getRoommates() {
    return roommateProvider.roommates;
  }
}
