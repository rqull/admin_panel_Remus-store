import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderListWidget extends StatelessWidget {
  const OrderListWidget({super.key});

  Widget orderDisplayData(Widget widget, int? flex) {
    return Expanded(
      flex: flex!,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: widget,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _ordersStream =
        FirebaseFirestore.instance.collection('orders').snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return LinearProgressIndicator();
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final orderData = snapshot.data!.docs[index];
            return Row(
              children: [
                orderDisplayData(
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.network(
                      orderData['productImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  1,
                ),
                orderDisplayData(
                  Text(
                    orderData['productName'],
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  1,
                ),
                orderDisplayData(
                  Text(
                    '${orderData['state']},${orderData['city']}',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  2,
                ),
                orderDisplayData(
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                        Color(0xFF3C55EF),
                      )),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderData['orderId'])
                            .update({
                          'delivered': true,
                          'processing': false,
                          'deliveredCount': FieldValue.increment(1),
                        });
                      },
                      child: orderData['delivered'] == true
                          ? Text(
                              'Delivered',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Mark Delivered',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                    ),
                    1),
                orderDisplayData(
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                        Colors.red,
                      )),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderData['orderId'])
                            .update({
                          'delivered': false,
                          'processing': false,
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    1),
              ],
            );
          },
        );
      },
    );
  }
}
