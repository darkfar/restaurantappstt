// lib/ui/pages/pages.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/widgets.dart';
import '../../data/data.dart';
import '../../providers/providers.dart';

// =============================================================================
// MAIN NAVIGATION - Now using Provider for state management
// =============================================================================

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: const _MainNavigationView(),
    );
  }
}

class _MainNavigationView extends StatelessWidget {
  const _MainNavigationView();

  final List<Widget> _pages = const [
    HomePage(),
    FavoritePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: Consumer<FavoriteProvider>(
            builder: (context, favoriteProvider, child) {
              return BottomNavigationBar(
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    activeIcon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        const Icon(Icons.favorite_border),
                        if (favoriteProvider.favoriteCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                favoriteProvider.favoriteCount > 99
                                    ? '99+'
                                    : '${favoriteProvider.favoriteCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    activeIcon: Stack(
                      children: [
                        const Icon(Icons.favorite),
                        if (favoriteProvider.favoriteCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                favoriteProvider.favoriteCount > 99
                                    ? '99+'
                                    : '${favoriteProvider.favoriteCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Favorit',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    activeIcon: Icon(Icons.settings),
                    label: 'Pengaturan',
                  ),
                ],
                currentIndex: navigationProvider.selectedIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                onTap: navigationProvider.setSelectedIndex,
                type: BottomNavigationBarType.fixed,
                elevation: 8,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// HOME PAGE - Using Provider state management
// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurantList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant App'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            icon: const Icon(Icons.search),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurantList();
        },
        child: Consumer<RestaurantProvider>(
          builder: (context, provider, child) {
            switch (provider.restaurantListState) {
              case Loading():
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat daftar restoran...'),
                    ],
                  ),
                );

              case Success(data: final restaurants):
                if (restaurants.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    return RestaurantCard(restaurant: restaurants[index]);
                  },
                );

              case Error(message: final message):
                return CustomErrorWidget(
                  error: message,
                  title: 'Gagal Memuat Restoran',
                  onRetry: () => Provider.of<RestaurantProvider>(context, listen: false)
                      .fetchRestaurantList(),
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Restoran',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada data restoran yang tersedia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Provider.of<RestaurantProvider>(context, listen: false)
                .fetchRestaurantList(),
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SEARCH PAGE - Already using Provider correctly
// =============================================================================

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Restoran'),
      ),
      body: Column(
        children: [
          // Search Bar
          Consumer<RestaurantProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari restoran favorit Anda...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.lastSearchQuery.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        provider.clearSearch();
                      },
                      icon: const Icon(Icons.clear),
                    )
                        : null,
                  ),
                  onChanged: provider.searchRestaurants,
                  onSubmitted: provider.searchRestaurants,
                ),
              );
            },
          ),
          // Search Results
          Expanded(
            child: Consumer<RestaurantProvider>(
              builder: (context, provider, child) {
                // Show initial search prompt
                if (!provider.hasSearched) {
                  return _buildSearchPrompt(context, provider);
                }

                // Show search results
                return _buildSearchResults(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt(BuildContext context, RestaurantProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Cari Restoran',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Masukkan nama restoran yang ingin Anda cari',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Focus will be handled automatically when user taps the search field
            },
            icon: const Icon(Icons.search),
            label: const Text('Mulai Pencarian'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(RestaurantProvider provider) {
    switch (provider.searchState) {
      case Loading<List<Restaurant>>():
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Mencari restoran...'),
            ],
          ),
        );

      case Success<List<Restaurant>>(data: final restaurants):
        if (restaurants.isEmpty && provider.lastSearchQuery.isNotEmpty) {
          return _buildNoResults(provider);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            return RestaurantCard(restaurant: restaurants[index]);
          },
        );

      case Error<List<Restaurant>>(message: final message):
        return CustomErrorWidget(
          error: message,
          title: 'Pencarian Gagal',
          onRetry: () => provider.searchRestaurants(provider.lastSearchQuery),
        );
    }
  }

  Widget _buildNoResults(RestaurantProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ditemukan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada restoran yang cocok dengan pencarian "${provider.lastSearchQuery}"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              provider.clearSearch();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Cari Lagi'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FAVORITE PAGE - Already using Provider correctly
// =============================================================================

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Restoran'),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, favoriteProvider, child) {
              if (favoriteProvider.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearAllDialog(context, favoriteProvider),
                  tooltip: 'Hapus Semua Favorit',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<FavoriteProvider>(context, listen: false)
              .refreshFavorites();
        },
        child: Consumer<FavoriteProvider>(
          builder: (context, favoriteProvider, child) {
            if (favoriteProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat favorit...'),
                  ],
                ),
              );
            }

            if (favoriteProvider.isEmpty) {
              return _buildEmptyFavorites(context);
            }

            return Column(
              children: [
                // Favorite count header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    '${favoriteProvider.favoriteCount} restoran favorit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                // Favorites list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favoriteProvider.favorites.length,
                    itemBuilder: (context, index) {
                      final restaurant = favoriteProvider.favorites[index];
                      return FavoriteRestaurantCard(
                        restaurant: restaurant,
                        onRemoved: () => _showRemoveDialog(
                          context,
                          favoriteProvider,
                          restaurant.id,
                          restaurant.name,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Favorit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Restoran yang Anda tandai sebagai favorit akan muncul di sini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to home page or show restaurants
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.explore),
              label: const Text('Jelajahi Restoran'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(
      BuildContext context,
      FavoriteProvider favoriteProvider,
      String restaurantId,
      String restaurantName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus dari Favorit'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$restaurantName" dari daftar favorit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await favoriteProvider.removeFromFavorite(restaurantId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$restaurantName dihapus dari favorit'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Batal',
                          textColor: Colors.white,
                          onPressed: () {
                            // Note: This would require storing the restaurant data
                            // to be able to re-add it. For simplicity, we'll skip this.
                          },
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menghapus dari favorit'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog(
      BuildContext context,
      FavoriteProvider favoriteProvider,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Semua Favorit'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua restoran dari daftar favorit? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await favoriteProvider.clearAllFavorites();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Semua favorit berhasil dihapus'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menghapus semua favorit'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// RESTAURANT DETAIL PAGE - Using Provider state management
// =============================================================================

// Updated RestaurantDetailPage in pages.dart
class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false)
          .fetchRestaurantDetail(widget.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          switch (provider.restaurantDetailState) {
            case Loading():
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );

            case Success(data: final restaurant):
              return CustomScrollView(
                slivers: [
                  // App Bar with Image and Favorite Button
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    actions: [
                      // Favorite Button in AppBar
                      Consumer<FavoriteProvider>(
                        builder: (context, favoriteProvider, child) {
                          final isFavorite = favoriteProvider.isFavorite(restaurant.id);

                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () async {
                                try {
                                  // Create Restaurant object from RestaurantDetail
                                  final restaurantObj = Restaurant(
                                    id: restaurant.id,
                                    name: restaurant.name,
                                    description: restaurant.description,
                                    pictureId: restaurant.pictureId,
                                    city: restaurant.city,
                                    rating: restaurant.rating,
                                  );

                                  await favoriteProvider.toggleFavorite(restaurantObj);

                                  if (context.mounted) {
                                    final message = isFavorite
                                        ? '${restaurant.name} dihapus dari favorit'
                                        : '${restaurant.name} ditambahkan ke favorit';

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor: isFavorite ? Colors.orange : Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Gagal mengubah status favorit'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: CachedNetworkImage(
                        imageUrl: ApiService.getImageUrl(
                          restaurant.pictureId,
                          size: ImageSize.large,
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Restaurant Info with Favorite Button
                          _buildRestaurantInfoWithFavorite(restaurant),
                          const SizedBox(height: 24),

                          // Categories
                          _buildCategories(restaurant),
                          const SizedBox(height: 24),

                          // Description
                          _buildDescription(restaurant),
                          const SizedBox(height: 24),

                          // Menu
                          _buildMenu(restaurant),
                          const SizedBox(height: 24),

                          // Reviews
                          _buildReviewsSection(restaurant),
                        ],
                      ),
                    ),
                  ),
                ],
              );

            case Error(message: final message):
              return Scaffold(
                appBar: AppBar(title: const Text('Detail Restoran')),
                body: CustomErrorWidget(
                  error: message,
                  onRetry: () => Provider.of<RestaurantProvider>(context, listen: false)
                      .fetchRestaurantDetail(widget.restaurantId),
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildRestaurantInfoWithFavorite(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Rating
        Row(
          children: [
            Expanded(
              child: Text(
                restaurant.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    restaurant.rating.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Location
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${restaurant.address}, ${restaurant.city}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Favorite Action Button
        Consumer<FavoriteProvider>(
          builder: (context, favoriteProvider, child) {
            final isFavorite = favoriteProvider.isFavorite(restaurant.id);

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Create Restaurant object from RestaurantDetail
                    final restaurantObj = Restaurant(
                      id: restaurant.id,
                      name: restaurant.name,
                      description: restaurant.description,
                      pictureId: restaurant.pictureId,
                      city: restaurant.city,
                      rating: restaurant.rating,
                    );

                    await favoriteProvider.toggleFavorite(restaurantObj);

                    if (context.mounted) {
                      final message = isFavorite
                          ? '${restaurant.name} dihapus dari favorit'
                          : '${restaurant.name} ditambahkan ke favorit';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: isFavorite ? Colors.orange : Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal mengubah status favorit'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(
                  isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFavorite ? Colors.orange : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategories(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: restaurant.categories.map<Widget>((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DescriptionWidget(
          description: restaurant.description,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Foods
        _buildMenuSection('Makanan', restaurant.menus.foods, Icons.restaurant),
        const SizedBox(height: 16),

        // Drinks
        _buildMenuSection('Minuman', restaurant.menus.drinks, Icons.local_drink),
      ],
    );
  }

  Widget _buildMenuSection(String title, List items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map<Widget>((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewPage(restaurant: restaurant),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Show latest 2 reviews
        if (restaurant.customerReviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Belum ada review.\nJadilah yang pertama memberikan review!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...restaurant.customerReviews.take(2).map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          review.name.isNotEmpty ? review.name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              review.date,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.review),
                ],
              ),
            );
          }).toList(),

        const SizedBox(height: 16),

        // Add Review Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewPage(restaurant: restaurant),
                ),
              );
            },
            icon: const Icon(Icons.add_comment),
            label: const Text('Tambah Review'),
          ),
        ),
      ],
    );
  }
}
// =============================================================================
// REVIEW PAGE - Using Provider state management
// =============================================================================

class ReviewPage extends StatelessWidget {
  final RestaurantDetail restaurant;

  const ReviewPage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews - ${restaurant.name}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Review List
          Expanded(
            child: restaurant.customerReviews.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada review',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: restaurant.customerReviews.length,
              itemBuilder: (context, index) {
                final review = restaurant.customerReviews[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                review.name.isNotEmpty ? review.name[0].toUpperCase() : 'A',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    review.date,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          review.review,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Add Review Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddReviewBottomSheet(context),
              icon: const Icon(Icons.add_comment),
              label: const Text('Tambah Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReviewBottomSheet(restaurantId: restaurant.id),
    );
  }
}

// =============================================================================
// ADD REVIEW BOTTOM SHEET - Using Provider state management
// =============================================================================

class AddReviewBottomSheet extends StatelessWidget {
  final String restaurantId;

  const AddReviewBottomSheet({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewFormProvider(),
      child: _AddReviewForm(restaurantId: restaurantId),
    );
  }
}

class _AddReviewForm extends StatelessWidget {
  final String restaurantId;

  const _AddReviewForm({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Consumer<ReviewFormProvider>(
        builder: (context, formProvider, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formProvider.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tambah Review',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: formProvider.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Anda',
                      hintText: 'Masukkan nama Anda',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      if (value.trim().length < 2) {
                        return 'Nama minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: formProvider.reviewController,
                    decoration: const InputDecoration(
                      labelText: 'Review Anda',
                      hintText: 'Bagikan pengalaman Anda di restoran ini...',
                      prefixIcon: Icon(Icons.rate_review),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Review tidak boleh kosong';
                      }
                      if (value.trim().length < 10) {
                        return 'Review minimal 10 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<RestaurantProvider>(
                    builder: (context, restaurantProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: restaurantProvider.isAddingReview
                              ? null
                              : () => _submitReview(
                              context, formProvider, restaurantProvider),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: restaurantProvider.isAddingReview
                              ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Mengirim Review...'),
                            ],
                          )
                              : const Text('Kirim Review'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReview(
      BuildContext context,
      ReviewFormProvider formProvider,
      RestaurantProvider restaurantProvider,
      ) async {
    if (!formProvider.validateForm()) return;

    final success = await restaurantProvider.addReview(
      restaurantId,
      formProvider.nameController.text.trim(),
      formProvider.reviewController.text.trim(),
    );

    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan review. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// =============================================================================
// SETTINGS PAGE - Already using Provider correctly
// =============================================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
      ),
      body: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          return ListView(
            children: [
              // Theme Settings Section
              _buildSectionHeader(context, 'Tampilan'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Tema Gelap'),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? 'Mode gelap aktif'
                            : 'Mode terang aktif',
                      ),
                      trailing: Switch.adaptive(
                        value: themeProvider.isDarkMode,
                        onChanged: themeProvider.isLoading
                            ? null
                            : (value) => themeProvider.toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notification Settings Section
              _buildSectionHeader(context, 'Notifikasi'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        settingsProvider.isDailyReminderActive
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text('Pengingat Harian'),
                      subtitle: Text(
                        settingsProvider.isDailyReminderActive
                            ? 'Aktif - Notifikasi pada 11:00 AM'
                            : 'Nonaktif - Tidak ada pengingat',
                      ),
                      trailing: Switch.adaptive(
                        value: settingsProvider.isDailyReminderActive,
                        onChanged: settingsProvider.isLoading
                            ? null
                            : (value) => _handleDailyReminderToggle(
                            context, settingsProvider, value),
                      ),
                    ),
                    if (settingsProvider.isDailyReminderActive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Pengingat akan muncul setiap hari pada pukul 11:00 AM untuk mengingatkan Anda makan siang.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App Info Section
              _buildSectionHeader(context, 'Tentang Aplikasi'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Versi Aplikasi'),
                      subtitle: Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.developer_mode),
                      title: const Text('Dikembangkan oleh'),
                      subtitle: const Text('Flutter Developer'),
                      onTap: () => _showDeveloperInfo(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Data API'),
                      subtitle: const Text('Dicoding Restaurant API'),
                      onTap: () => _showApiInfo(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reset Settings Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.restore,
                    color: Colors.orange,
                  ),
                  title: const Text('Reset Pengaturan'),
                  subtitle: const Text('Kembalikan pengaturan ke default'),
                  onTap: () => _showResetDialog(context, settingsProvider),
                ),
              ),

              const SizedBox(height: 32),

              // Loading indicator
              if (settingsProvider.isLoading || themeProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Error message
              if (settingsProvider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          settingsProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        onPressed: settingsProvider.clearError,
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future<void> _handleDailyReminderToggle(
      BuildContext context,
      SettingsProvider settingsProvider,
      bool value,
      ) async {
    if (value) {
      // Show permission dialog first
      final bool shouldEnable = await _showPermissionDialog(context);
      if (shouldEnable) {
        await settingsProvider.toggleDailyReminder(value);
      }
    } else {
      await settingsProvider.toggleDailyReminder(value);
    }
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Notifikasi'),
          content: const Text(
            'Aplikasi memerlukan izin untuk menampilkan notifikasi pengingat harian. '
                'Pastikan Anda mengizinkan notifikasi dari aplikasi ini di pengaturan perangkat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  void _showResetDialog(
      BuildContext context,
      SettingsProvider settingsProvider,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Pengaturan'),
          content: const Text(
            'Apakah Anda yakin ingin mereset semua pengaturan ke default? '
                'Tindakan ini akan menghapus semua preferensi yang telah Anda simpan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await settingsProvider.resetSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan berhasil direset'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informasi Developer'),
          content: const Text(
            'Aplikasi Restaurant App ini dikembangkan sebagai bagian dari submission '
                'kelas Flutter Fundamental di Dicoding Academy.\n\n'
                'Dibuat dengan Flutter dan menggunakan Dicoding Restaurant API.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showApiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informasi API'),
          content: const Text(
            'Data restoran disediakan oleh Dicoding Restaurant API.\n\n'
                'Base URL: https://restaurant-api.dicoding.dev\n\n'
                'API ini menyediakan data daftar restoran, detail restoran, '
                'pencarian, dan fitur review.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}