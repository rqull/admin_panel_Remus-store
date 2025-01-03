import 'package:app_web/views/side_bar_screens/buyers_screen.dart';
import 'package:app_web/views/side_bar_screens/category_screen.dart';
import 'package:app_web/views/side_bar_screens/dashboard_screen.dart';
import 'package:app_web/views/side_bar_screens/orders_screen.dart';
import 'package:app_web/views/side_bar_screens/product_screen.dart';
import 'package:app_web/views/side_bar_screens/upload_banner_screen.dart';
import 'package:app_web/views/side_bar_screens/vendors_screen.dart';
import 'package:app_web/views/side_bar_screens/withdrawal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Widget _selectedItem = DashboardScreen();

  screenSlector(item) {
    switch (item.route) {
      case DashboardScreen.id:
        setState(() {
          _selectedItem = DashboardScreen();
        });
        break;
      case VendorsScreen.id:
        setState(() {
          _selectedItem = VendorsScreen();
        });
        break;
      case BuyersScreen.id:
        setState(() {
          _selectedItem = BuyersScreen();
        });
        break;
      case OrdersScreen.id:
        setState(() {
          _selectedItem = OrdersScreen();
        });
        break;
      case CategoryScreen.id:
        setState(() {
          _selectedItem = CategoryScreen();
        });
        break;
      case ProductScreen.id:
        setState(() {
          _selectedItem = ProductScreen();
        });
        break;
      case UploadBannerScreen.id:
        setState(() {
          _selectedItem = UploadBannerScreen();
        });
        break;
      case WithdrawalScreen.id:
        setState(() {
          _selectedItem = WithdrawalScreen();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Management'),
      ),
      sideBar: SideBar(
        items: const [
          AdminMenuItem(
            title: 'Dashboard',
            route: DashboardScreen.id,
            icon: Icons.dashboard,
          ),
          AdminMenuItem(
            title: 'Vendors',
            route: VendorsScreen.id,
            icon: Icons.store,
          ),
          AdminMenuItem(
            title: 'Buyers',
            route: BuyersScreen.id,
            icon: Icons.person,
          ),
          AdminMenuItem(
            title: 'Orders',
            route: OrdersScreen.id,
            icon: Icons.shopping_cart,
          ),
          AdminMenuItem(
            title: 'Categories',
            route: CategoryScreen.id,
            icon: Icons.category,
          ),
          AdminMenuItem(
            title: 'Products',
            route: ProductScreen.id,
            icon: Icons.shop,
          ),
          AdminMenuItem(
            title: 'Upload Banners',
            route: UploadBannerScreen.id,
            icon: Icons.add_photo_alternate_outlined,
          ),
          AdminMenuItem(
            title: 'Withdrawal',
            route: WithdrawalScreen.id,
            icon: Icons.money,
          ),
        ],
        selectedRoute: DashboardScreen.id,
        onSelected: (item) {
          screenSlector(item);
        },
        header: Container(
          height: 50,
          width: double.infinity,
          color: const Color(0xff444444),
          child: const Center(
            child: Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
        footer: Container(
          height: 50,
          width: double.infinity,
          color: const Color(0xff444444),
          child: const Center(
            child: Text(
              'footer',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _selectedItem,
    );
  }
}
