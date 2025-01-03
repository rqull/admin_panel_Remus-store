import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  static const String id = 'orders_screen';
  const OrdersScreen({super.key});

  Widget _buildOrderStatus(bool processing, bool delivered, bool cancelled) {
    if (cancelled) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'Cancelled',
            style: TextStyle(color: Colors.red.shade900),
          ),
        ),
      );
    } else if (delivered) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'Delivered',
            style: TextStyle(color: Colors.green.shade900),
          ),
        ),
      );
    } else if (processing) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'Processing',
            style: TextStyle(color: Colors.orange.shade900),
          ),
        ),
      );
    }
    return const Text('Unknown');
  }

  DataRow _buildOrderRow(
      DocumentSnapshot document, Map<String, dynamic>? buyerData) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    return DataRow(cells: [
      DataCell(Text(data['orderId'] ?? '')),
      DataCell(Row(
        children: [
          Container(
            width: 50,
            height: 50,
            child: Image.network(
              data['productImage'] ?? '',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(data['productName'] ?? ''),
        ],
      )),
      DataCell(Text(data['productSize'] ?? '')),
      DataCell(Text(data['quantity'].toString())),
      DataCell(Text(
          '\$${(data['productPrice'] * data['quantity']).toStringAsFixed(2)}')),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(buyerData?['fullname'] ?? 'Loading...'),
          Text(
            buyerData?['email'] ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(buyerData?['city'] ?? 'Loading...'),
          Text(
            buyerData?['locality'] != null && buyerData?['state'] != null
                ? '${buyerData!['locality']}, ${buyerData['state']}'
                : '',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      )),
      DataCell(Text(
          DateFormat('dd/MM/yyyy HH:mm').format(data['orderDate'].toDate()))),
      DataCell(_buildOrderStatus(
        data['processing'] ?? false,
        data['delivered'] ?? false,
        data['cancelled'] ?? false,
      )),
      DataCell(Row(
        children: [
          IconButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(document.id)
                  .update({
                'delivered': true,
                'processing': false,
                'deliveredCount': (data['deliveredCount'] ?? 0) + 1,
              });
            },
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            tooltip: 'Mark as Delivered',
          ),
          IconButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(document.id)
                  .update({
                'cancelled': true,
                'processing': false,
              });
            },
            icon: const Icon(
              Icons.cancel,
              color: Colors.red,
            ),
            tooltip: 'Cancel Order',
          ),
        ],
      )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId',
            isEqualTo: '') // Only get orders where vendorId is empty
        .snapshots();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(10),
        child: StreamBuilder<QuerySnapshot>(
          stream: _ordersStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Container(
              width:
                  MediaQuery.of(context).size.width - 40, // Adjust for padding
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: StreamBuilder<Map<String, DocumentSnapshot>>(
                  stream:
                      Stream.fromFuture(_fetchBuyersData(snapshot.data!.docs)),
                  builder: (context, buyersSnapshot) {
                    if (buyersSnapshot.hasError) {
                      return const Text('Error fetching buyers data');
                    }

                    if (buyersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 60,
                      ),
                      child: DataTable(
                        columnSpacing: 20, // Add spacing between columns
                        horizontalMargin: 10, // Reduce horizontal margin
                        showBottomBorder: true,
                        dataRowHeight: 60,
                        headingRowColor:
                            MaterialStateProperty.all(Colors.grey[200]),
                        columns: const [
                          DataColumn(
                            label: Text('Order ID'),
                            tooltip: 'Order ID',
                          ),
                          DataColumn(
                            label: Text('Product'),
                            tooltip: 'Product details',
                          ),
                          DataColumn(
                            label: Text('Size'),
                            tooltip: 'Product size',
                          ),
                          DataColumn(
                            label: Text('Qty'), // Shortened label
                            tooltip: 'Quantity',
                          ),
                          DataColumn(
                            label: Text('Total'),
                            tooltip: 'Total price',
                          ),
                          DataColumn(
                            label: Text('Buyer'),
                            tooltip: 'Buyer details',
                          ),
                          DataColumn(
                            label: Text('Location'),
                            tooltip: 'Buyer location',
                          ),
                          DataColumn(
                            label: Text('Date'),
                            tooltip: 'Order date',
                          ),
                          DataColumn(
                            label: Text('Status'),
                            tooltip: 'Order status',
                          ),
                          DataColumn(
                            label: Text('Actions'),
                            tooltip: 'Available actions',
                          ),
                        ],
                        rows: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          String userId = (document.data()
                                  as Map<String, dynamic>)['userId'] ??
                              '';
                          Map<String, dynamic>? buyerData;
                          if (buyersSnapshot.hasData &&
                              buyersSnapshot.data!.containsKey(userId)) {
                            buyerData = buyersSnapshot.data![userId]?.data()
                                as Map<String, dynamic>?;
                          }
                          return _buildOrderRow(document, buyerData);
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, DocumentSnapshot>> _fetchBuyersData(
      List<DocumentSnapshot> orders) async {
    Map<String, DocumentSnapshot> buyersData = {};

    for (var order in orders) {
      String userId = (order.data() as Map<String, dynamic>)['userId'] ?? '';
      if (userId.isNotEmpty && !buyersData.containsKey(userId)) {
        try {
          DocumentSnapshot buyerDoc = await FirebaseFirestore.instance
              .collection('buyers')
              .doc(userId)
              .get();
          if (buyerDoc.exists) {
            buyersData[userId] = buyerDoc;
          }
        } catch (e) {
          print('Error fetching buyer data: $e');
        }
      }
    }

    return buyersData;
  }
}
