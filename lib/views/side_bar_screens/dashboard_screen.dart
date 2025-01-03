import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  static const String id = 'dashboard-screen';
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(10),
              child: Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, ordersSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, productsSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('buyers').snapshots(),
                      builder: (context, buyersSnapshot) {
                        if (ordersSnapshot.connectionState == ConnectionState.waiting ||
                            productsSnapshot.connectionState == ConnectionState.waiting ||
                            buyersSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        // Calculate total revenue from orders
                        double totalRevenue = 0;
                        int totalOrders = 0;
                        if (ordersSnapshot.hasData) {
                          for (var doc in ordersSnapshot.data!.docs) {
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            totalRevenue += (data['productPrice'] ?? 0) * (data['quantity'] ?? 1);
                            totalOrders++;
                          }
                        }

                        // Count admin products (where vendorId is empty)
                        int adminProducts = 0;
                        if (productsSnapshot.hasData) {
                          adminProducts = productsSnapshot.data!.docs
                              .where((doc) => (doc.data() as Map<String, dynamic>)['vendorId'] == '')
                              .length;
                        }

                        // Count total buyers
                        int totalBuyers = buyersSnapshot.hasData ? buyersSnapshot.data!.docs.length : 0;

                        return GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          children: [
                            _buildDashboardCard(
                              title: 'Total Orders',
                              value: totalOrders.toString(),
                              icon: Icons.shopping_cart,
                              color: Colors.blue,
                            ),
                            _buildDashboardCard(
                              title: 'Admin Products',
                              value: adminProducts.toString(),
                              icon: Icons.shop,
                              color: Colors.green,
                            ),
                            _buildDashboardCard(
                              title: 'Total Buyers',
                              value: totalBuyers.toString(),
                              icon: Icons.people,
                              color: Colors.orange,
                            ),
                            _buildDashboardCard(
                              title: 'Total Revenue',
                              value: NumberFormat.currency(
                                locale: 'en_US',
                                symbol: '\$',
                                decimalDigits: 2,
                              ).format(totalRevenue),
                              icon: Icons.attach_money,
                              color: Colors.red,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
