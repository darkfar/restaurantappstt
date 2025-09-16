// lib/providers/additional_providers.dart
// Add these to your existing providers.dart file

import 'package:flutter/material.dart';

// ============================================================================
// NAVIGATION PROVIDER - For managing bottom navigation state
// ============================================================================

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void resetToHome() {
    setSelectedIndex(0);
  }

  bool get isOnHomePage => _selectedIndex == 0;
  bool get isOnFavoritePage => _selectedIndex == 1;
  bool get isOnSettingsPage => _selectedIndex == 2;
}

// ============================================================================
// REVIEW FORM PROVIDER - For managing review form state
// ============================================================================

class ReviewFormProvider extends ChangeNotifier {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController get nameController => _nameController;
  TextEditingController get reviewController => _reviewController;
  GlobalKey<FormState> get formKey => _formKey;

  String _name = '';
  String _review = '';
  bool _isValid = false;

  String get name => _name;
  String get review => _review;
  bool get isValid => _isValid;

  ReviewFormProvider() {
    _nameController.addListener(_onNameChanged);
    _reviewController.addListener(_onReviewChanged);
  }

  void _onNameChanged() {
    _name = _nameController.text;
    _validateForm();
  }

  void _onReviewChanged() {
    _review = _reviewController.text;
    _validateForm();
  }

  void _validateForm() {
    bool wasValid = _isValid;
    _isValid = _name.trim().isNotEmpty &&
        _name.trim().length >= 2 &&
        _review.trim().isNotEmpty &&
        _review.trim().length >= 10;

    if (wasValid != _isValid) {
      notifyListeners();
    }
  }

  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  void clearForm() {
    _nameController.clear();
    _reviewController.clear();
    _name = '';
    _review = '';
    _isValid = false;
    notifyListeners();
  }

  void setInitialValues({String? name, String? review}) {
    if (name != null) {
      _nameController.text = name;
      _name = name;
    }
    if (review != null) {
      _reviewController.text = review;
      _review = review;
    }
    _validateForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }
}

// ============================================================================
// UI STATE PROVIDER - For managing UI-specific states
// ============================================================================

class UIStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      // Clear messages when loading state changes
      if (loading) {
        _errorMessage = null;
        _successMessage = null;
      }
      notifyListeners();
    }
  }

  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    _successMessage = null;
    notifyListeners();
  }

  void setSuccess(String? success) {
    _successMessage = success;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    if (_errorMessage != null || _successMessage != null) {
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearSuccess() {
    if (_successMessage != null) {
      _successMessage = null;
      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

// ============================================================================
// SEARCH STATE PROVIDER - For managing search-specific state
// ============================================================================

class SearchStateProvider extends ChangeNotifier {
  String _query = '';
  bool _hasSearched = false;
  List<String> _recentSearches = [];
  bool _isSearchActive = false;

  String get query => _query;
  bool get hasSearched => _hasSearched;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isSearchActive => _isSearchActive;

  void setQuery(String query) {
    if (_query != query) {
      _query = query;
      notifyListeners();
    }
  }

  void setHasSearched(bool hasSearched) {
    if (_hasSearched != hasSearched) {
      _hasSearched = hasSearched;
      notifyListeners();
    }
  }

  void setSearchActive(bool isActive) {
    if (_isSearchActive != isActive) {
      _isSearchActive = isActive;
      notifyListeners();
    }
  }

  void addToRecentSearches(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // Remove if already exists
    _recentSearches.remove(trimmedQuery);

    // Add to beginning
    _recentSearches.insert(0, trimmedQuery);

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }

    notifyListeners();
  }

  void removeFromRecentSearches(String query) {
    if (_recentSearches.remove(query)) {
      notifyListeners();
    }
  }

  void clearRecentSearches() {
    if (_recentSearches.isNotEmpty) {
      _recentSearches.clear();
      notifyListeners();
    }
  }

  void clearSearch() {
    _query = '';
    _hasSearched = false;
    _isSearchActive = false;
    notifyListeners();
  }

  void reset() {
    _query = '';
    _hasSearched = false;
    _isSearchActive = false;
    notifyListeners();
  }
}

// ============================================================================
// DIALOG STATE PROVIDER - For managing dialog states
// ============================================================================

class DialogStateProvider extends ChangeNotifier {
  bool _isDialogOpen = false;
  String? _dialogType;
  Map<String, dynamic>? _dialogData;

  bool get isDialogOpen => _isDialogOpen;
  String? get dialogType => _dialogType;
  Map<String, dynamic>? get dialogData => _dialogData;

  void openDialog(String type, {Map<String, dynamic>? data}) {
    _isDialogOpen = true;
    _dialogType = type;
    _dialogData = data;
    notifyListeners();
  }

  void closeDialog() {
    _isDialogOpen = false;
    _dialogType = null;
    _dialogData = null;
    notifyListeners();
  }

  bool isDialogOfType(String type) {
    return _isDialogOpen && _dialogType == type;
  }

  T? getDialogData<T>(String key) {
    return _dialogData?[key] as T?;
  }
}