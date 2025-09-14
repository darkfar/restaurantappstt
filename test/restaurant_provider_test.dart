// test/restaurant_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/providers/providers.dart';
import 'package:restaurant_app/data/data.dart';

// Fake ApiService untuk testing tanpa mockito
class FakeApiService extends ApiService {
  bool shouldReturnError = false;
  bool shouldReturnEmpty = false;
  Exception? customException;

  @override
  Future<List<Restaurant>> getRestaurantList() async {
    // Simulasi delay network
    await Future.delayed(const Duration(milliseconds: 50));

    if (shouldReturnError) {
      throw customException ?? Exception('Network error occurred');
    }

    if (shouldReturnEmpty) {
      return [];
    }

    // Return data dummy untuk testing
    return [
      Restaurant(
        id: '1',
        name: 'Test Restaurant 1',
        description: 'Test description for restaurant 1',
        pictureId: 'test_pic_1',
        city: 'Jakarta',
        rating: 4.5,
      ),
      Restaurant(
        id: '2',
        name: 'Test Restaurant 2',
        description: 'Test description for restaurant 2',
        pictureId: 'test_pic_2',
        city: 'Bandung',
        rating: 4.2,
      ),
    ];
  }
}

// Custom RestaurantProvider untuk testing
class TestableRestaurantProvider extends RestaurantProvider {
  FakeApiService? _fakeApiService;

  TestableRestaurantProvider({FakeApiService? fakeApiService}) {
    _fakeApiService = fakeApiService;
  }

  @override
  ApiService get apiService => _fakeApiService ?? super.apiService;
}

void main() {
  group('RestaurantProvider Tests - 3 Skenario Utama', () {
    late TestableRestaurantProvider restaurantProvider;
    late FakeApiService fakeApiService;

    setUp(() {
      fakeApiService = FakeApiService();
      restaurantProvider = TestableRestaurantProvider(
        fakeApiService: fakeApiService,
      );
    });

    group('fetchRestaurantList - Skenario Pengujian Utama', () {
      test('Skenario 1: Memastikan state awal provider harus didefinisikan', () {

        expect(
          restaurantProvider.restaurantListState,
          isA<Loading<List<Restaurant>>>(),
          reason: 'State awal provider harus Loading saat pertama kali dibuat',
        );

        print('✓ Skenario 1 PASSED: State awal provider adalah Loading');
      });

      test('Skenario 2: Memastikan harus mengembalikan daftar restoran ketika pengambilan data API berhasil', () async {
        // Arrange - Setup fake service untuk return data berhasil
        fakeApiService.shouldReturnError = false;
        fakeApiService.shouldReturnEmpty = false;

        // Act - Panggil method fetchRestaurantList
        await restaurantProvider.fetchRestaurantList();

        // Assert - Harus menghasilkan Success state dengan data
        expect(
          restaurantProvider.restaurantListState,
          isA<Success<List<Restaurant>>>(),
          reason: 'State harus Success ketika API berhasil',
        );

        final successState = restaurantProvider.restaurantListState as Success<List<Restaurant>>;

        expect(
          successState.data,
          isNotEmpty,
          reason: 'Data restoran tidak boleh kosong saat API berhasil',
        );

        expect(
          successState.data.length,
          equals(2),
          reason: 'Harus mengembalikan 2 restoran sesuai fake data',
        );

        expect(
          successState.data.first.name,
          equals('Test Restaurant 1'),
          reason: 'Data restoran harus sesuai dengan yang dikembalikan fake service',
        );

        print('✓ Skenario 2 PASSED: API berhasil mengembalikan daftar restoran');
      });

      test('Skenario 3: Memastikan harus mengembalikan kesalahan ketika pengambilan data API gagal', () async {
        // Arrange - Setup fake service untuk return error
        fakeApiService.shouldReturnError = true;
        fakeApiService.customException = Exception('Network connection failed');

        // Act - Panggil method fetchRestaurantList
        await restaurantProvider.fetchRestaurantList();

        // Assert - Harus menghasilkan Error state
        expect(
          restaurantProvider.restaurantListState,
          isA<Error<List<Restaurant>>>(),
          reason: 'State harus Error ketika API gagal',
        );

        final errorState = restaurantProvider.restaurantListState as Error<List<Restaurant>>;

        expect(
          errorState.message,
          isNotEmpty,
          reason: 'Error message tidak boleh kosong',
        );

        expect(
          errorState.message,
          isA<String>(),
          reason: 'Error message harus berupa String',
        );

        print('✓ Skenario 3 PASSED: API gagal mengembalikan error state');
      });
    });

    group('Pengujian Tambahan untuk Coverage', () {
      test('State transition dari Loading ke Success', () async {
        // Arrange
        fakeApiService.shouldReturnError = false;

        // Assert initial state
        expect(restaurantProvider.restaurantListState, isA<Loading<List<Restaurant>>>());

        // Act
        await restaurantProvider.fetchRestaurantList();

        // Assert final state
        expect(restaurantProvider.restaurantListState, isA<Success<List<Restaurant>>>());

        print('✓ State transition test PASSED');
      });

      test('State transition dari Loading ke Error', () async {
        // Arrange
        fakeApiService.shouldReturnError = true;
        fakeApiService.customException = Exception('Test error');

        // Assert initial state
        expect(restaurantProvider.restaurantListState, isA<Loading<List<Restaurant>>>());

        // Act
        await restaurantProvider.fetchRestaurantList();

        // Assert final state
        expect(restaurantProvider.restaurantListState, isA<Error<List<Restaurant>>>());

        print('✓ Error state transition test PASSED');
      });

      test('Handling empty data from API', () async {
        // Arrange
        fakeApiService.shouldReturnEmpty = true;
        fakeApiService.shouldReturnError = false;

        // Act
        await restaurantProvider.fetchRestaurantList();

        // Assert
        expect(restaurantProvider.restaurantListState, isA<Success<List<Restaurant>>>());

        final successState = restaurantProvider.restaurantListState as Success<List<Restaurant>>;
        expect(successState.data, isEmpty);

        print('✓ Empty data handling test PASSED');
      });

      test('Multiple consecutive API calls', () async {
        // Arrange
        fakeApiService.shouldReturnError = false;

        // Act - Panggil beberapa kali
        await restaurantProvider.fetchRestaurantList();
        final firstCallResult = restaurantProvider.restaurantListState;

        await restaurantProvider.fetchRestaurantList();
        final secondCallResult = restaurantProvider.restaurantListState;

        // Assert
        expect(firstCallResult, isA<Success<List<Restaurant>>>());
        expect(secondCallResult, isA<Success<List<Restaurant>>>());

        print('✓ Multiple API calls test PASSED');
      });

      test('Error message is not null or empty', () async {
        // Test berbagai jenis error untuk memastikan selalu ada message
        final errorTypes = [
          Exception('Network error'),
          Exception('Connection failed'),
          Exception('Server error'),
          Exception('Unknown error'),
        ];

        for (final error in errorTypes) {
          fakeApiService.shouldReturnError = true;
          fakeApiService.customException = error;

          await restaurantProvider.fetchRestaurantList();

          final errorState = restaurantProvider.restaurantListState as Error<List<Restaurant>>;
          expect(errorState.message, isNotEmpty);
          expect(errorState.message, isA<String>());
        }

        print('✓ Error message validation test PASSED');
      });
    });
  });
}