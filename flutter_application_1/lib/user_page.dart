import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_type_selection_page.dart';
import 'booking_history_page.dart';
import 'location_permission_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String _currentCity = 'Detecting...';
  String _currentDistrict = '';
  String _currentArea = '';
  bool _isLoadingLocation = true;
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];

  // Popular Indian cities
  final List<Map<String, dynamic>> _popularCities = [
    {'name': 'Delhi NCR', 'icon': Icons.location_city},
    {'name': 'Mumbai', 'icon': Icons.location_city},
    {'name': 'Kolkata', 'icon': Icons.location_city},
    {'name': 'Bengaluru', 'icon': Icons.location_city},
    {'name': 'Hyderabad', 'icon': Icons.location_city},
    {'name': 'Chandigarh', 'icon': Icons.location_city},
  ];

  // All cities list
  final List<String> _allCities = [
    'Nellore',
    'Kavali',
    'Gudur',
    'Venkatagiri',
    'Abohar',
    'Abu Dhabi',
    'Abu Road',
    'Achampet',
    'Acharapakkam',
    'Addanki',
    'Adilabad',
    'Adipur',
    'Agra',
    'Ahmedabad',
    'Ahmednagar',
    'Aizawl',
    'Ajmer',
    'Akola',
    'Alappuzha',
    'Aligarh',
    'Allahabad',
    'Alwar',
    'Ambala',
    'Amravati',
    'Amritsar',
    'Anand',
    'Anantapur',
    'Anantnag',
    'Arrah',
    'Asansol',
    'Aurangabad',
    'Azamgarh',
    'Bagalkot',
    'Bangalore',
    'Bareilly',
    'Bathinda',
    'Belgaum',
    'Bellary',
    'Bhadrak',
    'Bharatpur',
    'Bhatpara',
    'Bhavnagar',
    'Bhilai',
    'Bhilwara',
    'Bhiwandi',
    'Bhopal',
    'Bhubaneswar',
    'Bidar',
    'Bijapur',
    'Bilaspur',
    'Bokaro',
    'Burdwan',
    'Chandigarh',
    'Chennai',
    'Chittoor',
    'Coimbatore',
    'Cuttack',
    'Darbhanga',
    'Davangere',
    'Dehradun',
    'Delhi',
    'Dhanbad',
    'Dharwad',
    'Dibrugarh',
    'Dindigul',
    'Durg',
    'Durgapur',
    'Erode',
    'Faridabad',
    'Firozabad',
    'Gandhinagar',
    'Gaya',
    'Ghaziabad',
    'Gorakhpur',
    'Gulbarga',
    'Guntur',
    'Gurgaon',
    'Guwahati',
    'Gwalior',
    'Hapur',
    'Hubli',
    'Hyderabad',
    'Imphal',
    'Indore',
    'Jabalpur',
    'Jaipur',
    'Jalandhar',
    'Jalgaon',
    'Jammu',
    'Jamnagar',
    'Jamshedpur',
    'Jhansi',
    'Jodhpur',
    'Kakinada',
    'Kalyan',
    'Kanpur',
    'Karimnagar',
    'Karnal',
    'Kochi',
    'Kolhapur',
    'Kolkata',
    'Kollam',
    'Kota',
    'Kottayam',
    'Kozhikode',
    'Lucknow',
    'Ludhiana',
    'Madurai',
    'Mangalore',
    'Mathura',
    'Meerut',
    'Moradabad',
    'Mumbai',
    'Muzaffarnagar',
    'Muzaffarpur',
    'Mysore',
    'Nadiad',
    'Nagpur',
    'Nanded',
    'Nashik',
    'Nellore',
    'Noida',
    'Panipat',
    'Patiala',
    'Patna',
    'Pune',
    'Raipur',
    'Rajahmundry',
    'Rajkot',
    'Ranchi',
    'Rourkela',
    'Salem',
    'Sangli',
    'Shimla',
    'Siliguri',
    'Solapur',
    'Srinagar',
    'Surat',
    'Thane',
    'Thiruvananthapuram',
    'Thrissur',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tirupati',
    'Tiruppur',
    'Udaipur',
    'Ujjain',
    'Vadodara',
    'Varanasi',
    'Vellore',
    'Vijayawada',
    'Visakhapatnam',
    'Warangal',
    'Yamuna Nagar',
  ];

  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = _allCities;
    // Don't auto-open location page on init
    setState(() {
      _currentCity = 'Select City';
      _isLoadingLocation = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _allCities;
      } else {
        _filteredCities = _allCities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectCity(String city) {
    setState(() {
      _currentCity = city;
      if (!_recentSearches.contains(city)) {
        _recentSearches.insert(0, city);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.sublist(0, 5);
        }
      }
    });
    Navigator.pop(context);
  }

  Future<void> _requestLocationPermission() async {
    // Open location permission page
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPermissionPage()),
    );

    if (result != null && result['success'] == true) {
      setState(() {
        _currentCity = result['city'] ?? 'Unknown City';
        _currentArea = result['area'] ?? '';
        _currentDistrict = result['district'] ?? '';
        _isLoadingLocation = false;
      });
    } else {
      setState(() {
        _currentCity = 'Select City';
        _isLoadingLocation = false;
      });
    }
  }

  void _showCitySelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: _filterCities,
                      decoration: InputDecoration(
                        hintText: 'Search city, area or locality',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Use Current Location
                    if (_searchController.text.isEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              _isLoadingLocation
                                  ? Icons.location_searching
                                  : Icons.my_location,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: const Text(
                            'Use current location',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _isLoadingLocation
                                ? 'Detecting location...'
                                : _currentArea.isNotEmpty
                                ? '$_currentCity, $_currentArea, $_currentDistrict'
                                : '$_currentCity, $_currentDistrict',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await _requestLocationPermission();
                          },
                        ),
                      ),

                      // Recent Searches
                      if (_recentSearches.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Recent searches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentSearches
                              .map(
                                (city) => ActionChip(
                                  label: Text(city),
                                  onPressed: () => _selectCity(city),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Popular Cities
                      const Text(
                        'Popular cities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemCount: _popularCities.length,
                        itemBuilder: (context, index) {
                          final city = _popularCities[index];
                          return InkWell(
                            onTap: () => _selectCity(city['name']),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.deepPurple.shade200,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    city['icon'],
                                    size: 32,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    city['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // All Cities Header
                      const Text(
                        'All cities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // City List
                    ..._filteredCities.map(
                      (city) => ListTile(
                        title: Text(city),
                        onTap: () => _selectCity(city),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Location Display in Top Right
          GestureDetector(
            onTap: _showCitySelectionSheet,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLoadingLocation
                        ? Icons.location_searching
                        : Icons.location_on,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentCity.length > 10
                        ? '${_currentCity.substring(0, 10)}...'
                        : _currentCity,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingHistoryPage(),
                ),
              );
            },
          ),
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
          image: const DecorationImage(
            image: AssetImage('assets/images/smart_park_logo.png'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade100.withOpacity(0.9),
              Colors.deepPurple.shade50.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Header (like reference image)
                GestureDetector(
                  onTap: _showCitySelectionSheet,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.deepPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _currentCity,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.black54,
                                    size: 24,
                                  ),
                                ],
                              ),
                              if (_currentArea.isNotEmpty ||
                                  _currentDistrict.isNotEmpty)
                                Text(
                                  _currentArea.isNotEmpty
                                      ? '$_currentArea, $_currentDistrict'
                                      : _currentDistrict,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ??
                            user?.email?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
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
                            'Hello, ${user?.displayName ?? 'User'}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const Text(
                            'SMART PARK',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Parking Statistics - Real-time Updates
                const Text(
                  'Parking Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parking_slots')
                      .snapshots(),
                  builder: (context, snapshot) {
                    const totalSlots = 4; // Total parking slots (A, B, C, D)
                    final bookedCount = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    final availableCount = totalSlots - bookedCount;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Total Slots
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.grid_view,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '4',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Total Slots',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              // Booked Slots
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.cancel,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$bookedCount',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Booked',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              // Available Slots
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$availableCount',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.update,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Live Updates - ${availableCount > 0 ? "$availableCount slot${availableCount != 1 ? 's' : ''} free" : "All slots full"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Booking History Section (at the top)
                const Text(
                  'Booking History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('booking_history')
                      .orderBy('bookingTime', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'No booking history yet',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final slotId = data['slotId'] ?? 'Unknown';
                          final bookingTime = (data['bookingTime'] as Timestamp)
                              .toDate();
                          final leaveTime = data['leaveTime'] != null
                              ? (data['leaveTime'] as Timestamp).toDate()
                              : null;
                          final isActive = data['isActive'] ?? false;
                          final amount = data['amount'] ?? 0;
                          final paid = data['paid'] ?? false;

                          final duration = leaveTime != null
                              ? leaveTime.difference(bookingTime)
                              : DateTime.now().difference(bookingTime);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? Colors.green.shade300
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.local_parking,
                                    color: isActive
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            slotId,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green
                                                  : Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Completed',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Booked: ${_formatDateTime(bookingTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (leaveTime != null)
                                        Text(
                                          'Left: ${_formatDateTime(leaveTime)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      Text(
                                        'Duration: ${_formatDuration(duration)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (!isActive)
                                        Text(
                                          'Amount: ₹$amount',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: amount == 0
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (!isActive && amount > 0)
                                        Row(
                                          children: [
                                            Icon(
                                              paid
                                                  ? Icons.check_circle
                                                  : Icons.warning,
                                              size: 14,
                                              color: paid
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              paid ? 'Paid' : 'Unpaid',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: paid
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BookingHistoryPage(),
                              ),
                            );
                          },
                          child: const Text('View All History'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Current Booking Status Card
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parking_slots')
                      .where('userId', isEqualTo: user?.uid)
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final booking =
                          snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                      final slotId = booking['slotId'];
                      final bookingTime = (booking['bookingTime'] as Timestamp)
                          .toDate();
                      final duration = DateTime.now().difference(bookingTime);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_parking,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Booking',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    slotId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Duration: ${_formatDuration(duration)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Main Parking Slot Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleTypeSelectionPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_parking,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parking Slots',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Find and book your slot',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Stats
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parking_slots')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final slots = ['Slot A', 'Slot B', 'Slot C', 'Slot D'];
                    final bookedSlots = snapshot.hasData
                        ? snapshot.data!.docs.map((doc) => doc.id).toList()
                        : <String>[];
                    final freeSlots = slots
                        .where((slot) => !bookedSlots.contains(slot))
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$freeSlots Free',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const Text(
                                  'Available Slots',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red.shade600,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${bookedSlots.length} Booked',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const Text(
                                  'Occupied Slots',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
