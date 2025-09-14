// lib/data/data.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// ============================================================================
// API Response Models
// ============================================================================

sealed class ApiResponse<T> {}

class Loading<T> extends ApiResponse<T> {}

class Success<T> extends ApiResponse<T> {
  final T data;
  Success(this.data);
}

class Error<T> extends ApiResponse<T> {
  final String message;
  Error(this.message);
}

// ============================================================================
// Restaurant Models
// ============================================================================

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String pictureId;
  final String city;
  final double rating;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.pictureId,
    required this.city,
    required this.rating,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pictureId: json['pictureId'] ?? '',
      city: json['city'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pictureId': pictureId,
      'city': city,
      'rating': rating,
    };
  }
}

class RestaurantDetail {
  final String id;
  final String name;
  final String description;
  final String city;
  final String address;
  final String pictureId;
  final List<Category> categories;
  final Menus menus;
  final double rating;
  final List<CustomerReview> customerReviews;

  RestaurantDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.pictureId,
    required this.categories,
    required this.menus,
    required this.rating,
    required this.customerReviews,
  });

  factory RestaurantDetail.fromJson(Map<String, dynamic> json) {
    return RestaurantDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      pictureId: json['pictureId'] ?? '',
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => Category.fromJson(e))
          .toList(),
      menus: Menus.fromJson(json['menus'] ?? {}),
      rating: (json['rating'] ?? 0).toDouble(),
      customerReviews: (json['customerReviews'] as List<dynamic>? ?? [])
          .map((e) => CustomerReview.fromJson(e))
          .toList(),
    );
  }
}

class Category {
  final String name;

  Category({required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(name: json['name'] ?? '');
  }
}

class Menus {
  final List<MenuItem> foods;
  final List<MenuItem> drinks;

  Menus({required this.foods, required this.drinks});

  factory Menus.fromJson(Map<String, dynamic> json) {
    return Menus(
      foods: (json['foods'] as List<dynamic>? ?? [])
          .map((e) => MenuItem.fromJson(e))
          .toList(),
      drinks: (json['drinks'] as List<dynamic>? ?? [])
          .map((e) => MenuItem.fromJson(e))
          .toList(),
    );
  }
}

class MenuItem {
  final String name;

  MenuItem({required this.name});

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(name: json['name'] ?? '');
  }
}

class CustomerReview {
  final String name;
  final String review;
  final String date;

  CustomerReview({
    required this.name,
    required this.review,
    required this.date,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      name: json['name'] ?? '',
      review: json['review'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'review': review,
      'date': date,
    };
  }
}

// ============================================================================
// Enums
// ============================================================================

enum ImageSize { small, medium, large }

// ============================================================================
// API Service
// ============================================================================

class ApiService {
  static const String baseUrl = 'https://restaurant-api.dicoding.dev';
  static const String imageBaseUrl = '$baseUrl/images';

  // Get list of restaurants
  Future<List<Restaurant>> getRestaurantList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> restaurants = data['restaurants'];
        return restaurants.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load restaurants');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get restaurant detail
  Future<RestaurantDetail> getRestaurantDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/detail/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return RestaurantDetail.fromJson(data['restaurant']);
      } else {
        throw Exception('Failed to load restaurant detail');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Search restaurants
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> restaurants = data['restaurants'] ?? [];
        return restaurants.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search restaurants');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add review
  Future<List<CustomerReview>> addReview(
      String id,
      String name,
      String review,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': id,
          'name': name,
          'review': review,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> reviews = data['customerReviews'];
        return reviews.map((json) => CustomerReview.fromJson(json)).toList();
      } else {
        throw Exception('Failed to add review');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get image URL
  static String getImageUrl(String pictureId, {ImageSize size = ImageSize.medium}) {
    String sizeString;
    switch (size) {
      case ImageSize.small:
        sizeString = 'small';
        break;
      case ImageSize.medium:
        sizeString = 'medium';
        break;
      case ImageSize.large:
        sizeString = 'large';
        break;
    }
    return '$imageBaseUrl/$sizeString/$pictureId';
  }
}

// ============================================================================
// Database Helper
// ============================================================================

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal() {
    _instance = this;
  }

  factory DatabaseHelper() => _instance ?? DatabaseHelper._internal();

  static const String _tblFavorite = 'favorites';

  Future<Database> _initializeDb() async {
    var path = await getDatabasesPath();
    var db = openDatabase(
      join(path, 'restaurant_app.db'),
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE $_tblFavorite (
           id TEXT PRIMARY KEY,
           name TEXT,
           description TEXT,
           pictureId TEXT,
           city TEXT,
           rating REAL
         )''');
      },
      version: 1,
    );

    return db;
  }

  Future<Database?> get database async {
    _database ??= await _initializeDb();
    return _database;
  }

  Future<void> insertFavorite(Restaurant restaurant) async {
    final db = await database;
    await db!.insert(
      _tblFavorite,
      {
        'id': restaurant.id,
        'name': restaurant.name,
        'description': restaurant.description,
        'pictureId': restaurant.pictureId,
        'city': restaurant.city,
        'rating': restaurant.rating,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Restaurant>> getFavorites() async {
    final db = await database;
    List<Map<String, dynamic>> results = await db!.query(_tblFavorite);

    return results.map((res) => Restaurant.fromJson(res)).toList();
  }

  Future<Restaurant?> getFavoriteById(String id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db!.query(
      _tblFavorite,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return Restaurant.fromJson(results.first);
    } else {
      return null;
    }
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db!.delete(
      _tblFavorite,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isFavorite(String id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db!.query(
      _tblFavorite,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty;
  }

  Future<void> clearFavorites() async {
    final db = await database;
    await db!.delete(_tblFavorite);
  }
}

// ============================================================================
// Preferences Helper
// ============================================================================

class PreferencesHelper {
  final Future<SharedPreferences> sharedPreferences;

  PreferencesHelper({required this.sharedPreferences});

  static const String _isDarkTheme = 'isDarkTheme';
  static const String _isDailyReminderActive = 'isDailyReminderActive';

  // Theme preferences
  Future<bool> get isDarkTheme async {
    final prefs = await sharedPreferences;
    return prefs.getBool(_isDarkTheme) ?? false;
  }

  Future<bool> setDarkTheme(bool value) async {
    final prefs = await sharedPreferences;
    return prefs.setBool(_isDarkTheme, value);
  }

  // Daily reminder preferences
  Future<bool> get isDailyReminderActive async {
    final prefs = await sharedPreferences;
    return prefs.getBool(_isDailyReminderActive) ?? false;
  }

  Future<bool> setDailyReminder(bool value) async {
    final prefs = await sharedPreferences;
    return prefs.setBool(_isDailyReminderActive, value);
  }

  // Clear all preferences
  Future<bool> clearAllPreferences() async {
    final prefs = await sharedPreferences;
    return prefs.clear();
  }
}