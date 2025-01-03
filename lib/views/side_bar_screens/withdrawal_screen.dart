import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WithdrawalScreen extends StatelessWidget {
  static const String id = 'withdrawal-screen';
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _withdrawalStream =
        FirebaseFirestore.instance.collection('withdrawal').snapshots();

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
                'Withdrawal Requests',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _withdrawalStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return Card(
                  child: DataTable(
                    columnSpacing: 20,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Vendor',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Amount',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Bank Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Account Number',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Request Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;
                      return DataRow(
                        cells: [
                          DataCell(Text(data['vendorName'] ?? '')),
                          DataCell(Text(
                            NumberFormat.currency(
                              locale: 'en_US',
                              symbol: '\$',
                              decimalDigits: 2,
                            ).format(data['amount'] ?? 0),
                          )),
                          DataCell(Text(data['bankName'] ?? '')),
                          DataCell(Text(data['accountNumber'] ?? '')),
                          DataCell(Text(
                            data['requestDate'] != null
                                ? DateFormat('MMM d, y').format(
                                    (data['requestDate'] as Timestamp).toDate(),
                                  )
                                : '',
                          )),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: data['status'] == 'approved'
                                    ? Colors.green.shade100
                                    : data['status'] == 'rejected'
                                        ? Colors.red.shade100
                                        : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data['status'] ?? 'pending',
                                style: TextStyle(
                                  color: data['status'] == 'approved'
                                      ? Colors.green
                                      : data['status'] == 'rejected'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                if (data['status'] == 'pending') ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('withdrawal')
                                          .doc(document.id)
                                          .update({
                                        'status': 'approved',
                                      });
                                    },
                                    tooltip: 'Approve Withdrawal',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('withdrawal')
                                          .doc(document.id)
                                          .update({
                                        'status': 'rejected',
                                      });
                                    },
                                    tooltip: 'Reject Withdrawal',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
