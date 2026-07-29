import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../services/firestore_service.dart';
import '../services/preference_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _pairingCode;
  FamilyModel? _currentFamily;
  String? _error;

  bool get isLoading => _isLoading;
  String? get pairingCode => _pairingCode;
  FamilyModel? get currentFamily => _currentFamily;
  String? get error => _error;

  Future<String?> generateInviteCode(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pairingCode = await _firestoreService.generatePairingCode(parentId);
      _isLoading = false;
      notifyListeners();
      return _pairingCode;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> pairChildWithCode({
    required String code,
    required String childDeviceName,
    required String deviceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentFamily = await _firestoreService.pairChildWithCode(
        code: code,
        childDeviceName: childDeviceName,
        deviceId: deviceId,
      );

      _isLoading = false;
      if (_currentFamily != null) {
        // Persist child pairing session locally!
        await PreferenceService.saveSession(
          role: 'child',
          familyId: _currentFamily!.familyId,
          deviceId: deviceId,
          childName: childDeviceName,
        );

        notifyListeners();
        return true;
      } else {
        _error = 'Invalid or expired 6-digit code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Pairing error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
