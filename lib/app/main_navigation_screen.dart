// Hosts the authenticated tabs and owns the active address and basket state.
import 'package:flutter/material.dart';
import 'package:grabber_app/app/app_session.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/basket/domain/entities/basket_item.dart';
import 'package:grabber_app/features/basket/presentation/screens/basket_screen.dart';
import 'package:grabber_app/features/basket/presentation/widgets/basket_summary.dart';
import 'package:grabber_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:grabber_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:grabber_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:grabber_app/features/favorites/domain/errors/favorites_failure.dart';
import 'package:grabber_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:grabber_app/features/favorites/presentation/favorites_controller.dart';
import 'package:grabber_app/features/home/data/models/catalog_models.dart';
import 'package:grabber_app/features/home/presentation/delivery_address_formatter.dart';
import 'package:grabber_app/features/home/presentation/screens/home.dart';
import 'package:grabber_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/presentation/screens/delivery_address_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  /// Receives the authenticated UID, required address, and shared repositories.
  const MainNavigationScreen({
    super.key,
    required this.uid,
    required this.initialAddress,
    required this.deliveryAddressRepository,
    this.authRepository,
    this.favoritesRepository,
    this.session,
  });

  final String uid;
  final DeliveryAddress initialAddress;
  final AuthRepository? authRepository;
  final FavoritesRepository? favoritesRepository;
  final DeliveryAddressRepository deliveryAddressRepository;
  final AppSession? session;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late DeliveryAddress _deliveryAddress;
  late FavoritesController _favoritesController;
  // This navigation shell is the sole in-memory owner of basket line items.
  final List<BasketItem> _basketItems = [];

  @override
  void initState() {
    super.initState();
    _deliveryAddress = widget.initialAddress;
    _createFavoritesController();
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid ||
        oldWidget.authRepository != widget.authRepository ||
        oldWidget.favoritesRepository != widget.favoritesRepository) {
      _disposeFavoritesController();
      _createFavoritesController();
    }
  }

  void _createFavoritesController() {
    _favoritesController = FavoritesController(
      repository: widget.favoritesRepository ?? FavoritesRepositoryImpl(),
      authRepository: widget.authRepository,
      initialUid: widget.uid,
    )..addListener(_onFavoritesChanged);
  }

  void _disposeFavoritesController() {
    _favoritesController
      ..removeListener(_onFavoritesChanged)
      ..dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite(ProductModel product) async {
    final controller = _favoritesController;
    try {
      await controller.toggleFavorite(product.id);
    } on FavoritesFailure catch (failure) {
      if (!mounted || !identical(controller, _favoritesController)) return;
      final message = switch (failure.code) {
        'permission-denied' =>
          'You do not have permission to change this favorite.',
        'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
          'Favorites need an internet connection. Please try again.',
        _ => 'Unable to update your favorites. Please try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _disposeFavoritesController();
    super.dispose();
  }

  /// Counts all product units currently held in the in-memory basket.
  int get totalItemQuantity =>
      _basketItems.fold(0, (total, item) => total + item.quantity);

  /// Returns the subtotal in cents, or `null` if any product price is invalid.
  int? get subtotalCents {
    var total = 0;
    for (final item in _basketItems) {
      final lineSubtotal = item.lineSubtotalCents;
      if (lineSubtotal == null) return null;
      total += lineSubtotal;
    }
    return total;
  }

  /// Looks up a product's current quantity for catalog cards.
  int getQuantity(String productId) {
    for (final item in _basketItems) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  /// Adds a product or increments its existing basket line.
  void addProduct(ProductModel product) {
    setState(() {
      final index = _basketItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (index == -1) {
        _basketItems.add(BasketItem(product: product, quantity: 1));
      } else {
        final item = _basketItems[index];
        _basketItems[index] = item.withQuantity(item.quantity + 1);
      }
    });
  }

  /// Decrements a product line and removes it when its quantity reaches zero.
  void decreaseQuantity(String productId) {
    final index = _basketItems.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index == -1) return;

    setState(() {
      final item = _basketItems[index];
      if (item.quantity == 1) {
        _basketItems.removeAt(index);
      } else {
        _basketItems[index] = item.withQuantity(item.quantity - 1);
      }
    });
  }

  /// Removes the product line from the shared in-memory basket.
  void removeProduct(String productId) {
    if (getQuantity(productId) == 0) return;
    setState(() {
      _basketItems.removeWhere((item) => item.product.id == productId);
    });
  }

  /// Opens the basket screen with this navigation shell's live basket state.
  void openBasket() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BasketScreen(
          basketItems: _basketItems,
          totalItemQuantity: () => totalItemQuantity,
          subtotalCents: () => subtotalCents,
          onAddProduct: addProduct,
          onDecreaseQuantity: decreaseQuantity,
          onRemoveProduct: removeProduct,
        ),
      ),
    );
  }

  /// Opens the saved-address form and refreshes Home after a successful update.
  Future<void> _editDeliveryAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliveryAddressScreen(
          uid: widget.uid,
          deliveryAddressRepository: widget.deliveryAddressRepository,
          initialAddress: _deliveryAddress,
          onAddressSaved: (address) {
            if (!mounted) return;
            setState(() => _deliveryAddress = address);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      Home(
        onOpenBasket: openBasket,
        deliveryAddressLabel: DeliveryAddressFormatter.format(_deliveryAddress),
        onEditAddress: _editDeliveryAddress,
      ),
      CategoriesScreen(
        onAddProduct: addProduct,
        onDecreaseQuantity: decreaseQuantity,
        getQuantity: getQuantity,
        favoritesController: _favoritesController,
        onToggleFavorite: _toggleFavorite,
      ),
      FavoritesScreen(
        favoritesController: _favoritesController,
        onToggleFavorite: _toggleFavorite,
        onAddProduct: addProduct,
        onDecreaseQuantity: decreaseQuantity,
        getQuantity: getQuantity,
      ),
      ProfileScreen(
        authRepository: widget.authRepository,
        deliveryAddressRepository: widget.deliveryAddressRepository,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedIndex == 0 && totalItemQuantity > 0)
            BasketSummary(
              totalItemQuantity: totalItemQuantity,
              subtotalCents: subtotalCents,
              onOpenBasket: openBasket,
            ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColor.primary,
            unselectedItemColor: Colors.grey.shade600,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: 'Categories',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
