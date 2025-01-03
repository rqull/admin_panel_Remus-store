import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BuyersScreen extends StatelessWidget {
  static const String id = 'buyers-screen';
  const BuyersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _buyersStream =
        FirebaseFirestore.instance.collection('buyers').snapshots();

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
                'Buyers',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _buyersStream,
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
                          'Profile',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Full Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'City',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Balance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Join Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 40,
                              height: 40,
                              child: data['profilImage'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        data['profilImage'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                            ),
                          ),
                          DataCell(Text(data['fullname'] ?? '')),
                          DataCell(Text(data['email'] ?? '')),
                          DataCell(Text(data['city'] ?? '')),
                          DataCell(Text(
                            NumberFormat.currency(
                              locale: 'en_US',
                              symbol: '\$',
                              decimalDigits: 2,
                            ).format(data['balance'] ?? 0),
                          )),
                          DataCell(Text(
                            data['joinDate'] != null
                                ? DateFormat('MMM d, y').format(
                                    (data['joinDate'] as Timestamp).toDate(),
                                  )
                                : '',
                          )),
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
