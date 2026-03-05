import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('booking_history')
              .orderBy('bookingTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 100, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No booking history yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final bookings = snapshot.data!.docs;
            final totalBookings = bookings.length;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history,
                        size: 30,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total Bookings: $totalBookings',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking =
                          bookings[index].data() as Map<String, dynamic>;
                      final slotId = booking['slotId'] ?? 'Unknown';
                      final vehicleType = booking['vehicleType'] ?? 'Car';
                      final pricePerMinute = booking['pricePerMinute'] ?? 100;
                      final bookingTime = (booking['bookingTime'] as Timestamp?)
                          ?.toDate();
                      final leaveTime = (booking['leaveTime'] as Timestamp?)
                          ?.toDate();
                      final isActive = booking['isActive'] ?? false;
                      final amount = booking['amount'] ?? 0;
                      final paid = booking['paid'] ?? false;

                      final duration = leaveTime != null && bookingTime != null
                          ? leaveTime.difference(bookingTime)
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Colors.green
                                : Colors.grey,
                            child: Icon(
                              isActive
                                  ? Icons.local_parking
                                  : Icons.check_circle,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            slotId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    vehicleType == 'Bike'
                                        ? Icons.two_wheeler
                                        : vehicleType == 'SUV'
                                        ? Icons.airport_shuttle
                                        : Icons.directions_car,
                                    size: 14,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$vehicleType (₹$pricePerMinute/min)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Booked: ${_formatDateTime(bookingTime)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              if (leaveTime != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.exit_to_app,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Left: ${_formatDateTime(leaveTime)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              if (duration != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Duration: ${_formatDuration(duration)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              if (!isActive)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.currency_rupee,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Amount: ₹$amount',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: amount == 0
                                            ? Colors.green
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                    if (amount == 0)
                                      const Text(
                                        ' (Free)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                        ),
                                      ),
                                  ],
                                ),
                              if (!isActive && amount > 0)
                                Row(
                                  children: [
                                    Icon(
                                      paid ? Icons.check_circle : Icons.warning,
                                      size: 14,
                                      color: paid ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      paid ? 'Paid' : 'Unpaid',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: paid
                                            ? Colors.green
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              isActive ? 'Active' : 'Completed',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: isActive
                                ? Colors.green
                                : Colors.grey,
                          ),
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

  String _formatDateTime(DateTime? time) {
    if (time == null) return 'N/A';
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
