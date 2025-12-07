import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/shipping_settings.dart';

class ShippingService extends ChangeNotifier {
  static final ShippingService _instance = ShippingService._internal();
  factory ShippingService() => _instance;
  ShippingService._internal() {
    _loadSettings();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'shipping_settings';
  static const String _documentId = 'config';

  ShippingSettings _settings = ShippingSettings.defaultSettings();

  ShippingSettings get settings => _settings;
  ValueListenable<ShippingSettings> get settingsListenable =>
      _SettingsNotifier(this);

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        _settings = ShippingSettings.fromJson(doc.data()!);
      } else {
        // Initialize with default settings if document doesn't exist
        await _saveSettings(_settings);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading shipping settings: $e');
      // Use default settings on error
      _settings = ShippingSettings.defaultSettings();
      notifyListeners();
    }
  }

  Future<void> updateSettings(ShippingSettings newSettings) async {
    try {
      await _saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw 'Permission denied. Please update Firestore security rules to allow shipping configuration. See Firebase Console → Firestore Database → Rules';
      }
      throw 'Failed to update shipping settings: ${e.message}';
    }
  }

  Future<void> _saveSettings(ShippingSettings settings) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(settings.toJson());
    } on FirebaseException catch (e) {
      debugPrint('Error saving shipping settings: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error saving shipping settings: $e');
      rethrow;
    }
  }

  double getShippingCost() {
    return _settings.effectiveCost;
  }
}

class _SettingsNotifier extends ValueNotifier<ShippingSettings> {
  _SettingsNotifier(ShippingService service) : super(service.settings) {
    service.addListener(_update);
    _service = service;
  }

  late final ShippingService _service;

  void _update() {
    value = _service.settings;
  }

  @override
  void dispose() {
    _service.removeListener(_update);
    super.dispose();
  }
}
