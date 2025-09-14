// lib/providers/providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../data/data.dart'; // Import semua dari file data.dart yang sudah berisi DatabaseHelper, ApiResponse, Restaurant, dll.
import '../utils/utils.dart'; // Import utils yang berisi NotificationHelper

// Theme Provider
class ThemeProvider extends ChangeNotifier {
  final PreferencesHelper preferencesHelper;

  ThemeProvider({required this.preferencesHelper}) {
    _loadThemePreference();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isDarkMode = await preferencesHelper.isDarkTheme;
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      _isDarkMode = false; // Default to light theme on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle theme and save to preferences
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      await preferencesHelper.setDarkTheme(_isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
      // Revert if save failed
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  // Set specific theme and save to preferences
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;

    try {
      _isDarkMode = isDark;
      await preferencesHelper.setDarkTheme(_isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
      // Revert if save failed
      _isDarkMode = !isDark;
      notifyListeners();
    }
  }

  // Get current theme mode
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Get theme name for display
  String get themeName => _isDarkMode ? 'Dark Theme' : 'Light Theme';

  // Refresh theme preference
  Future<void> refreshTheme() async {
    await _loadThemePreference();
  }
}

// Settings Provider
class SettingsProvider extends ChangeNotifier {
  final PreferencesHelper preferencesHelper;
  late final NotificationHelper notificationHelper;

  SettingsProvider({
    required this.preferencesHelper,
    NotificationHelper? notificationHelper,
  }) {
    // Use provided instance or get singleton
    this.notificationHelper = notificationHelper ?? NotificationHelper.instance;
    _loadSettings();
  }

  bool _isDailyReminderActive = false;
  bool get isDailyReminderActive => _isDailyReminderActive;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Load settings from preferences
  Future<void> _loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isDailyReminderActive = await preferencesHelper.isDailyReminderActive;
    } catch (e) {
      _errorMessage = 'Failed to load settings: $e';
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle daily reminder
  Future<void> toggleDailyReminder(bool value) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (value) {
        // Schedule daily notification
        await notificationHelper.scheduleDailyReminder();
      } else {
        // Cancel daily notification
        await notificationHelper.cancelDailyReminder();
      }

      // Save preference
      await preferencesHelper.setDailyReminder(value);
      _isDailyReminderActive = value;
    } catch (e) {
      _errorMessage = 'Failed to update daily reminder: $e';
      debugPrint('Error updating daily reminder: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh settings
  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset all settings
  Future<void> resetSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await preferencesHelper.clearAllPreferences();
      try {
        await notificationHelper.cancelDailyReminder();
      } catch (e) {
        debugPrint('Error cancelling notifications during reset: $e');
        // Don't let notification errors prevent settings reset
      }

      _isDailyReminderActive = false;
    } catch (e) {
      _errorMessage = 'Failed to reset settings: $e';
      debugPrint('Error resetting settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Restaurant Provider
// lib/providers/restaurant_provider.dart
// Update your existing RestaurantProvider in providers.dart with this version:

class RestaurantProvider extends ChangeNotifier {
  ApiService? _apiService;

  // Getter that returns the injected service or creates a default one
  ApiService get apiService => _apiService ?? ApiService();

  ApiResponse<List<Restaurant>> _restaurantListState = Loading<List<Restaurant>>();
  ApiResponse<List<Restaurant>> get restaurantListState => _restaurantListState;

  ApiResponse<RestaurantDetail> _restaurantDetailState = Loading<RestaurantDetail>();
  ApiResponse<RestaurantDetail> get restaurantDetailState => _restaurantDetailState;

  ApiResponse<List<Restaurant>> _searchState = Success<List<Restaurant>>([]);
  ApiResponse<List<Restaurant>> get searchState => _searchState;

  bool _isAddingReview = false;
  bool get isAddingReview => _isAddingReview;

  String _lastSearchQuery = '';
  String get lastSearchQuery => _lastSearchQuery;

  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  // Constructor that accepts optional ApiService for testing
  RestaurantProvider({ApiService? apiService}) : _apiService = apiService;

  // Get restaurant list
  Future<void> fetchRestaurantList() async {
    _restaurantListState = Loading<List<Restaurant>>();
    notifyListeners();

    try {
      final restaurants = await apiService.getRestaurantList();
      _restaurantListState = Success<List<Restaurant>>(restaurants);
    } catch (e) {
      _restaurantListState = Error<List<Restaurant>>(_getErrorMessage(e));
    }
    notifyListeners();
  }

  // Get restaurant detail
  Future<void> fetchRestaurantDetail(String id) async {
    _restaurantDetailState = Loading<RestaurantDetail>();
    notifyListeners();

    try {
      final restaurant = await apiService.getRestaurantDetail(id);
      _restaurantDetailState = Success<RestaurantDetail>(restaurant);
    } catch (e) {
      _restaurantDetailState = Error<RestaurantDetail>(_getErrorMessage(e));
    }
    notifyListeners();
  }

  // Search restaurants
  Future<void> searchRestaurants(String query) async {
    _lastSearchQuery = query;
    _hasSearched = true;

    if (query.isEmpty) {
      _searchState = Success<List<Restaurant>>([]);
      _hasSearched = false;
      notifyListeners();
      return;
    }

    _searchState = Loading<List<Restaurant>>();
    notifyListeners();

    try {
      final restaurants = await apiService.searchRestaurants(query);
      _searchState = Success<List<Restaurant>>(restaurants);
    } catch (e) {
      _searchState = Error<List<Restaurant>>(_getErrorMessage(e));
    }
    notifyListeners();
  }

  // Add review
  Future<bool> addReview(String restaurantId, String name, String review) async {
    _isAddingReview = true;
    notifyListeners();

    try {
      final updatedReviews = await apiService.addReview(restaurantId, name, review);

      // Update the current restaurant detail if it's loaded and matches the ID
      if (_restaurantDetailState is Success<RestaurantDetail>) {
        final currentDetail = (_restaurantDetailState as Success<RestaurantDetail>).data;
        if (currentDetail.id == restaurantId) {
          // Create updated detail with new reviews
          final updatedDetail = RestaurantDetail(
            id: currentDetail.id,
            name: currentDetail.name,
            description: currentDetail.description,
            city: currentDetail.city,
            address: currentDetail.address,
            pictureId: currentDetail.pictureId,
            categories: currentDetail.categories,
            menus: currentDetail.menus,
            rating: currentDetail.rating,
            customerReviews: updatedReviews,
          );
          _restaurantDetailState = Success<RestaurantDetail>(updatedDetail);
        }
      }

      _isAddingReview = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAddingReview = false;
      notifyListeners();
      return false;
    }
  }

  // Reset search
  void clearSearch() {
    _searchState = Success<List<Restaurant>>([]);
    _lastSearchQuery = '';
    _hasSearched = false;
    notifyListeners();
  }

  // Helper method untuk error message yang user-friendly
  String _getErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (errorString.contains('timeout')) {
      return 'Koneksi timeout. Silakan coba lagi.';
    } else if (errorString.contains('404')) {
      return 'Data tidak ditemukan.';
    } else if (errorString.contains('500')) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    } else if (errorString.contains('failed to load')) {
      return 'Gagal memuat data. Silakan coba lagi.';
    } else {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}

// Favorite Provider
class FavoriteProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Restaurant> _favorites = [];
  List<Restaurant> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, bool> _favoriteStatus = {};

  // Constructor
  FavoriteProvider() {
    _loadFavorites();
  }

  // Load favorites from database
  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _databaseHelper.getFavorites();
      _updateFavoriteStatus();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update favorite status map for quick lookup
  void _updateFavoriteStatus() {
    _favoriteStatus.clear();
    for (final restaurant in _favorites) {
      _favoriteStatus[restaurant.id] = true;
    }
  }

  // Check if restaurant is favorite
  bool isFavorite(String id) {
    return _favoriteStatus[id] ?? false;
  }

  // Add restaurant to favorites
  Future<void> addToFavorite(Restaurant restaurant) async {
    try {
      await _databaseHelper.insertFavorite(restaurant);
      _favorites.add(restaurant);
      _favoriteStatus[restaurant.id] = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove restaurant from favorites
  Future<void> removeFromFavorite(String id) async {
    try {
      await _databaseHelper.removeFavorite(id);
      _favorites.removeWhere((restaurant) => restaurant.id == id);
      _favoriteStatus.remove(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Restaurant restaurant) async {
    if (isFavorite(restaurant.id)) {
      await removeFromFavorite(restaurant.id);
    } else {
      await addToFavorite(restaurant);
    }
  }

  // Refresh favorites list
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      await _databaseHelper.clearFavorites();
      _favorites.clear();
      _favoriteStatus.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all favorites: $e');
      rethrow;
    }
  }

  // Get favorite count
  int get favoriteCount => _favorites.length;

  // Check if favorites list is empty
  bool get isEmpty => _favorites.isEmpty;
  bool get isNotEmpty => _favorites.isNotEmpty;
}