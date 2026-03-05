import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotsPage extends StatefulWidget {
  final String vehicleType;
  const ParkingSlotsPage({super.key, required this.vehicleType});

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String? currentBooking;

  int get _pricePerMinute {
    switch (widget.vehicleType) {
      case 'Bike':
        return 20;
      case 'Car':
        return 100;
      case 'SUV':
        return 200;
      default:
        return 100;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentBooking();
  }

  Future<void> _checkCurrentBooking() async {
    final snapshot = await _firestore
        .collection('parking_slots')
        .where('userId', isEqualTo: user?.uid)
        .where('isActive', isEqualTo: true)
        .where('vehicleType', isEqualTo: widget.vehicleType)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        currentBooking = snapshot.docs.first.id;
      });
    }
  }

  Future<void> _bookSlot(String slotId) async {
    if (currentBooking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an active booking!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Slot'),
        content: Text('Do you want to book $slotId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Book'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final bookingTime = DateTime.now();

        // 1. Save to parking_slots table - mark slot as RESERVED
        await _firestore.collection('parking_slots').doc(slotId).set({
          'userId': user?.uid,
          'userEmail': user?.email,
          'userName': user?.displayName ?? 'User',
          'slotId': slotId,
          'bookingTime': bookingTime,
          'isReserved': true, // Mark slot as RESERVED
          'isActive': true,
          'vehicleType': widget.vehicleType,
          'pricePerMinute': _pricePerMinute,
        });

        // 2. Save to users/{userId}/booking_history subcollection
        await _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('booking_history')
            .add({
              'slotId': slotId,
              'bookingTime': bookingTime,
              'leaveTime': null,
              'isActive': true,
              'amount': 0, // Will be updated when leaving
              'paid': false, // Will be updated when payment is made
              'vehicleType': widget.vehicleType,
              'pricePerMinute': _pricePerMinute,
            });

        // 3. Save to global booking_history collection
        await _firestore.collection('booking_history').add({
          'userId': user?.uid,
          'userEmail': user?.email,
          'userName': user?.displayName ?? 'User',
          'slotId': slotId,
          'bookingTime': bookingTime,
          'leaveTime': null,
          'isActive': true,
          'amount': 0, // Will be updated when leaving
          'paid': false, // Will be updated when payment is made
          'vehicleType': widget.vehicleType,
          'pricePerMinute': _pricePerMinute,
        });

        setState(() {
          currentBooking = slotId;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$slotId booked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _leaveSlot(String slotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Slot'),
        content: Text('Do you want to leave $slotId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final leaveTime = DateTime.now();

        // Get booking time to calculate bill
        final slotData =
            (await _firestore.collection('parking_slots').doc(slotId).get())
                .data();

        final bookingTime = (slotData?['bookingTime'] as Timestamp).toDate();
        final duration = leaveTime.difference(bookingTime);
        final pricePerMin =
            slotData?['pricePerMinute'] as int? ?? _pricePerMinute;

        // Calculate bill based on vehicle type rate, free if less than 1 minute
        final minutes = duration.inMinutes;
        final amount = minutes < 1 ? 0 : minutes * pricePerMin;

        // 1. Delete from parking_slots - mark slot as FREE (not reserved)
        await _firestore.collection('parking_slots').doc(slotId).delete();

        // 2. Update user's booking history
        final userHistorySnapshot = await _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('booking_history')
            .where('slotId', isEqualTo: slotId)
            .where('isActive', isEqualTo: true)
            .get();

        for (var doc in userHistorySnapshot.docs) {
          await doc.reference.update({
            'leaveTime': leaveTime,
            'isActive': false,
            'amount': amount,
          });
        }

        // 3. Update global booking history
        final globalHistorySnapshot = await _firestore
            .collection('booking_history')
            .where('userId', isEqualTo: user?.uid)
            .where('slotId', isEqualTo: slotId)
            .where('isActive', isEqualTo: true)
            .get();

        for (var doc in globalHistorySnapshot.docs) {
          await doc.reference.update({
            'leaveTime': leaveTime,
            'isActive': false,
            'amount': amount,
          });
        }

        setState(() {
          currentBooking = null;
        });

        if (mounted) {
          // Show bill in dialog with animated Pay button
          bool isPaid = false;

          showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text(
                    'Parking Bill',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_parking, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Slot: $slotId',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Duration: ${minutes < 1 ? "${duration.inSeconds}s" : "${minutes}m"}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: amount == 0
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: amount == 0 ? Colors.green : Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              size: 28,
                              color: Colors.black87,
                            ),
                            Text(
                              '$amount',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: amount == 0
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (amount == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Center(
                            child: Text(
                              '🎉 Free Parking - Less than 1 minute',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (amount > 0 && !isPaid)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isPaid
                                  ? null
                                  : () async {
                                      try {
                                        // Update paid status in user's booking history
                                        final userHistorySnapshot =
                                            await _firestore
                                                .collection('users')
                                                .doc(user?.uid)
                                                .collection('booking_history')
                                                .where(
                                                  'slotId',
                                                  isEqualTo: slotId,
                                                )
                                                .where(
                                                  'isActive',
                                                  isEqualTo: false,
                                                )
                                                .get();

                                        for (var doc
                                            in userHistorySnapshot.docs) {
                                          await doc.reference.update({
                                            'paid': true,
                                          });
                                        }

                                        // Update paid status in global booking history
                                        final globalHistorySnapshot =
                                            await _firestore
                                                .collection('booking_history')
                                                .where(
                                                  'userId',
                                                  isEqualTo: user?.uid,
                                                )
                                                .where(
                                                  'slotId',
                                                  isEqualTo: slotId,
                                                )
                                                .where(
                                                  'isActive',
                                                  isEqualTo: false,
                                                )
                                                .get();

                                        for (var doc
                                            in globalHistorySnapshot.docs) {
                                          await doc.reference.update({
                                            'paid': true,
                                          });
                                        }

                                        // Show success message
                                        setDialogState(() {
                                          isPaid = true;
                                        });

                                        // Wait 2 seconds to show success message, then close dialog
                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );

                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Payment failed: ${e.toString()}',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 5,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.payment, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay ₹$amount',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (isPaid)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'PAYMENT SUCCESSFUL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleType} Parking'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee, size: 16),
                Text(
                  '$_pricePerMinute/min',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('parking_slots')
              .where('vehicleType', isEqualTo: widget.vehicleType)
              .snapshots(),
          builder: (context, snapshot) {
            // Create list of slots based on vehicle type
            final slots = [
              '${widget.vehicleType} A',
              '${widget.vehicleType} B',
              '${widget.vehicleType} C',
              '${widget.vehicleType} D',
            ];

            final bookedSlots = snapshot.hasData
                ? snapshot.data!.docs
                      .where((doc) => doc['vehicleType'] == widget.vehicleType)
                      .map((doc) => doc.id)
                      .toList()
                : <String>[];

            final freeSlots = slots
                .where((slot) => !bookedSlots.contains(slot))
                .length;

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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.local_parking,
                            size: 40,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$freeSlots Free',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.car_rental,
                            size: 40,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${bookedSlots.length} Booked',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slotId = slots[index];
                      final isBooked = bookedSlots.contains(slotId);
                      final isMyBooking = currentBooking == slotId;

                      return StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection('parking_slots')
                            .doc(slotId)
                            .snapshots(),
                        builder: (context, slotSnapshot) {
                          final data =
                              slotSnapshot.data?.data()
                                  as Map<String, dynamic>?;
                          final bookingTime =
                              data?['bookingTime'] as Timestamp?;

                          return GestureDetector(
                            onTap: () {
                              if (isMyBooking) {
                                _leaveSlot(slotId);
                              } else if (!isBooked) {
                                _bookSlot(slotId);
                              }
                            },
                            child: Card(
                              elevation: 8,
                              color: isMyBooking
                                  ? Colors.orange.shade100
                                  : isBooked
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_parking,
                                      size: 50,
                                      color: isMyBooking
                                          ? Colors.orange
                                          : isBooked
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      slotId,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMyBooking
                                          ? 'Your Slot'
                                          : isBooked
                                          ? 'Occupied'
                                          : 'Available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isMyBooking
                                            ? Colors.orange.shade700
                                            : isBooked
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (bookingTime != null && isMyBooking)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'Since: ${_formatTime(bookingTime.toDate())}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    if (isMyBooking)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Tap to Leave',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Parking Layout Diagram
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parking Layout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Bikes Section with ENTRANCE
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.vehicleType == 'Bike'
                                      ? Colors.blue.shade700
                                      : Colors.blue.shade300,
                                  width: widget.vehicleType == 'Bike' ? 3 : 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.two_wheeler,
                                    size: 40,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'BIKES',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 12,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ENTRANCE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Cars Section
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.vehicleType == 'Car'
                                      ? Colors.green.shade700
                                      : Colors.green.shade300,
                                  width: widget.vehicleType == 'Car' ? 3 : 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 40,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'CARS',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // SUVs Section with EXIT
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.vehicleType == 'SUV'
                                      ? Colors.orange.shade700
                                      : Colors.orange.shade300,
                                  width: widget.vehicleType == 'SUV' ? 3 : 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.airport_shuttle,
                                    size: 40,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'SUVs',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          size: 12,
                                          color: Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'EXIT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
