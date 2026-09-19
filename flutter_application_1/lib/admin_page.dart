import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
          ),
        ),
        child: Column(
          children: [
            // Admin Header
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade600,
                    Colors.deepPurple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user?.email ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Statistics Cards
            const _StatisticsCardsWidget(),

            const SizedBox(height: 16),

            // All Bookings List
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    'All Users Booking History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const Expanded(child: _AllBookingsListWidget()),
          ],
        ),
      ),
    );
  }
}

// Statistics Cards Widget
class _StatisticsCardsWidget extends StatelessWidget {
  const _StatisticsCardsWidget();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_history')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final bookings = snapshot.data!.docs;
        int total = bookings.length;
        int active = 0;

        for (var booking in bookings) {
          final data = booking.data() as Map<String, dynamic>;
          if (data['isActive'] == true) {
            active++;
          }
        }

        return _buildCards({
          'total': total,
          'active': active,
          'completed': total - active,
        });
      },
    );
  }

  Future<Map<String, int>> _countBookings(
    List<QueryDocumentSnapshot> users,
  ) async {
    int total = 0;
    int active = 0;

    for (var userDoc in users) {
      final bookings = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('booking_history')
          .get();

      total += bookings.docs.length;
      for (var booking in bookings.docs) {
        final data = booking.data();
        if (data['isActive'] == true) {
          active++;
        }
      }
    }

    return {'total': total, 'active': active, 'completed': total - active};
  }

  Widget _buildCards(Map<String, int> counts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.history, color: Colors.blue.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '${counts['total']}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${counts['completed']}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Text(
                      'Completed',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.pending,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${counts['active']}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const Text(
                      'Active',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Separate widget to handle all bookings list with proper streaming
class _AllBookingsListWidget extends StatefulWidget {
  const _AllBookingsListWidget();

  @override
  State<_AllBookingsListWidget> createState() => _AllBookingsListWidgetState();
}

class _AllBookingsListWidgetState extends State<_AllBookingsListWidget> {
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() async {
    print('=== ADMIN PAGE: Loading bookings ===');

    // Check global collection
    final globalSnapshot = await FirebaseFirestore.instance
        .collection('booking_history')
        .get();
    print('Global booking_history count: ${globalSnapshot.docs.length}');

    // Check users collection
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();
    print('Users count: ${usersSnapshot.docs.length}');

    // Check each user's bookings
    for (var userDoc in usersSnapshot.docs) {
      final bookings = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('booking_history')
          .get();
      print('User ${userDoc.id} has ${bookings.docs.length} bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_history')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading bookings...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 80, color: Colors.red),
                SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No booking history yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                SizedBox(height: 8),
                Text(
                  'Bookings will appear here once users make reservations',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs;
        print('Total bookings found in global collection: ${bookings.length}');

        // Sort bookings by time (newest first)
        final sortedBookings = bookings.toList();
        sortedBookings.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime =
              (aData['bookingTime'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime =
              (bData['bookingTime'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.deepPurple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Total Bookings: ${sortedBookings.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedBookings.length,
                itemBuilder: (context, index) {
                  final bookingData =
                      sortedBookings[index].data() as Map<String, dynamic>;
                  return _buildBookingCard(bookingData);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    final userEmail = (data['userEmail'] ?? 'Unknown').toString();
    final rawUserName = data['userName'];
    final userName = (rawUserName != null && rawUserName.toString().isNotEmpty)
        ? rawUserName.toString()
        : userEmail.contains('@')
        ? userEmail.split('@')[0]
        : 'User';
    final slotId = (data['slotId'] ?? 'Unknown').toString();
    final vehicleType = (data['vehicleType'] ?? 'Car').toString();
    final pricePerMinute = (data['pricePerMinute'] is num)
        ? (data['pricePerMinute'] as num).toDouble()
        : 100.0;
    final bookingTimestamp = data['bookingTime'];
    final bookingTime = bookingTimestamp is Timestamp
        ? bookingTimestamp.toDate()
        : DateTime.now();
    final leaveTimestamp = data['leaveTime'];
    final leaveTime = leaveTimestamp is Timestamp
        ? leaveTimestamp.toDate()
        : null;
    final isActive = data['isActive'] == true;
    final amount = (data['amount'] is num)
        ? (data['amount'] as num).toInt()
        : 0;
    final paid = data['paid'] == true;

    final duration = leaveTime != null
        ? leaveTime.difference(bookingTime)
        : DateTime.now().difference(bookingTime);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.orange.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    userName.isNotEmpty
                        ? userName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.orange.shade400
                          : Colors.green.shade400,
                    ),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'COMPLETED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Booking Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_parking,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            slotId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            vehicleType == 'Bike'
                                ? Icons.two_wheeler
                                : vehicleType == 'SUV'
                                ? Icons.airport_shuttle
                                : Icons.directions_car,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vehicleType,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(₹$pricePerMinute/min)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount & Payment Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          size: 20,
                          color: Colors.black87,
                        ),
                        Text(
                          '$amount',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: amount == 0
                                ? Colors.green.shade700
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (!isActive && amount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paid
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: paid ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              paid ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: paid
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              paid ? 'Paid' : 'Unpaid',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: paid
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (amount == 0 && !isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🎉 Free',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Timestamps
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.login, size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      const Text(
                        'In: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        _formatDateTime(bookingTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (leaveTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Out: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          _formatDateTime(leaveTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
