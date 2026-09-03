import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ocr_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInAnonymously();

  runApp(const SmartCareApp());
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
  
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCare',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6FAF8),
      ),
      home: const MainScreen(),
    );
  }
}

// ================= MAIN SCREEN =================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    MedicinesPage(),
    HealthPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDF5EB),
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ================= HOME =================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning 👋',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF71807A),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Sparsha',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B35),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB8E8D4),
                    Color(0xFFDDF5EB),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 45,
                    color: Color(0xFF4D9B82),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Your care summary',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF49665D),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'You are doing great!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF193B35),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Keep following your medication schedule.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF49665D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Today's care",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B35),
              ),
            ),
            const SizedBox(height: 12),
            _homeCard(
              context,
              Icons.medication_rounded,
              'Medicines',
              'Stay on track with your medication',
            ),
            const SizedBox(height: 12),
            _homeCard(
              context,
              Icons.person_rounded,
              'Caregiver',
              'Your caregiver is connected',
            ),
            const SizedBox(height: 12),
            _homeCard(
              context,
              Icons.emergency_rounded,
              'SOS Emergency',
              'Get emergency assistance',
            ),
            const SizedBox(height: 12),
            _homeCard(
  context,
  Icons.document_scanner_rounded,
  'Prescription Scanner',
  'Upload prescription and extract medicines',
),
          ],
        ),
      ),
    );
  }

static Widget _homeCard(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
) {
return GestureDetector(
onTap: () async {
  if (title == "Prescription Scanner") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OCRScreen(),
      ),
    );
    return;
  }

  if (title == "SOS Emergency") {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection("sos")
          .add({
        "userId": user.uid,
        "name": data["name"] ?? "Unknown",
        "residentId": data["residentId"] ?? "",
        "phone": data["phone"] ?? "",
        "emergencyContact": data["emergencyContact"] ?? "",
        "status": "active",
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency alert sent"),
          ),
        );
      }
    }

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$title selected")),
  );
},
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F1),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4D9B82),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF193B35),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF71807A),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
  }
}

// ================= MEDICINE MODEL =================

class Medicine {
  String name;
  String dosage;
  String time;
  bool isTaken;

  Medicine({
    required this.name,
    required this.dosage,
    required this.time,
    this.isTaken = false,
  });
}

// ================= MEDICINES PAGE =================

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
final CollectionReference medicinesRef =
    FirebaseFirestore.instance.collection("medications");

  void addMedicine() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Medicine',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine name',
                    prefixIcon: Icon(Icons.medication_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'Example: 500 mg / 1 tablet',
                    prefixIcon: Icon(Icons.local_pharmacy_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // TIME PICKER
                TextField(
                  controller: timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Medicine time',
                    hintText: 'Select time',
                    prefixIcon: Icon(Icons.access_time_rounded),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final TimeOfDay? pickedTime =
                        await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      timeController.text =
                          pickedTime.format(dialogContext);
                    }
                  },
                ),
              ],
            ),
          ),

          // DIALOG ACTIONS
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
onPressed: () async {
  if (nameController.text.trim().isEmpty ||
      dosageController.text.trim().isEmpty ||
      timeController.text.trim().isEmpty) {
    return;
  }

  // Save to Firestore
  await FirebaseFirestore.instance.collection("medications").add({
    "name": nameController.text.trim(),
    "dosage": dosageController.text.trim(),
    "time": timeController.text.trim(),
    "status": "pending",
    "createdAt": FieldValue.serverTimestamp(),
  });

  Navigator.pop(dialogContext);
},
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

Future<void> deleteMedicine(String docId) async {
  await FirebaseFirestore.instance
      .collection("medications")
      .doc(docId)
      .delete();
};
  }

Future<void> toggleTaken(String docId, bool currentStatus) async {
  await FirebaseFirestore.instance
      .collection("medications")
      .doc(docId)
      .update({
    "status": currentStatus ? "pending" : "taken",
  });
}

  @override
  Widget build(BuildContext context) {
    final takenCount =
    docs.where((doc) => doc["status"] == "taken").length;

final totalCount = docs.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Medicines',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF193B35),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Stay on track with your medication',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF71807A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF5EB),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Color(0xFF4D9B82),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // PROGRESS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB8E8D4),
                    Color(0xFFDDF5EB),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: Color(0xFF4D9B82),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Progress",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF193B35),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$takenCount of $totalCount medicines taken',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF49665D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SCHEDULE HEADER
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF193B35),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: addMedicine,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 19,
                  ),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF4D9B82),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // MEDICINE LIST
            if (medicines.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 55,
                      color: Color(0xFF9AB8AC),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No medicines added yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF193B35),
                      ),
                    ),
                  ],
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
  stream: medicinesRef.orderBy("createdAt").snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    return Column(
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return medicineCard(
  medicine: Medicine(
    name: data["name"] ?? "",
    dosage: data["dosage"] ?? "",
    time: data["time"] ?? "",
    isTaken: data["status"] == "taken",
  ),
  docId: doc.id,
);
      }).toList(),
    );
  },
),

            const SizedBox(height: 15),

            // REMINDER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE3ECE8),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF4D9B82),
                    size: 28,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medicine reminders are ON',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF193B35),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You will receive notifications for upcoming medicines.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF71807A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MEDICINE CARD

Widget medicineCard({
  required Medicine medicine,
  required String docId,
}) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Color(0xFF4D9B82),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF193B35),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${medicine.dosage} • ${medicine.time}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71807A),
                  ),
                ),
                const SizedBox(height: 9),
                GestureDetector(
                  onTap: () => toggleTaken(docId, medicine.isTaken),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: medicine.isTaken
                          ? const Color(0xFFDDF5EB)
                          : const Color(0xFFFFF1D9),
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                    child: Text(
                      medicine.isTaken
                          ? '✓ Taken'
                          : 'Mark as Taken',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: medicine.isTaken
                            ? const Color(0xFF4D9B82)
                            : const Color(0xFFE09A55),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
onPressed: () => deleteMedicine(docId),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD95353),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= HEALTH =================
// ================= HEALTH RECORD MODEL =================

class HealthRecord {
  final String type;
  final String value;
  final String unit;
  final String status;
  final DateTime time;

  HealthRecord({
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.time,
  });
}


// ================= HEALTH =================

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}


class _HealthPageState extends State<HealthPage> {

  // CURRENT VALUES
  String heartRate = '78';
  String bloodPressure = '120/80';
  String temperature = '36.7';
  String oxygen = '98';

  // CURRENT STATUS
  String heartStatus = 'Normal';
  String bpStatus = 'Normal';
  String temperatureStatus = 'Normal';
  String oxygenStatus = 'Normal';

  // ================= HISTORY =================

  final List<HealthRecord> history = [];


  // ================= HEART RATE STATUS =================

  String getHeartStatus(String value) {

    final bpm = double.tryParse(value);

    if (bpm == null) {
      return 'Invalid';
    }

    if (bpm < 60) {
      return 'Low';
    }

    if (bpm > 100) {
      return 'High';
    }

    return 'Normal';
  }


  // ================= BLOOD PRESSURE STATUS =================

  String getBPStatus(String value) {

    final parts = value.split('/');

    if (parts.length != 2) {
      return 'Invalid';
    }

    final systolic = double.tryParse(parts[0].trim());
    final diastolic = double.tryParse(parts[1].trim());

    if (systolic == null || diastolic == null) {
      return 'Invalid';
    }

    if (systolic < 90 || diastolic < 60) {
      return 'Low';
    }

    if (systolic >= 140 || diastolic >= 90) {
      return 'High';
    }

    return 'Normal';
  }


  // ================= TEMPERATURE STATUS =================

  String getTemperatureStatus(String value) {

    final temp = double.tryParse(value);

    if (temp == null) {
      return 'Invalid';
    }

    if (temp < 36.0) {
      return 'Low';
    }

    if (temp >= 38.0) {
      return 'High';
    }

    return 'Normal';
  }


  // ================= SPO2 STATUS =================

  String getOxygenStatus(String value) {

    final oxygenValue = double.tryParse(value);

    if (oxygenValue == null) {
      return 'Invalid';
    }

    if (oxygenValue < 95) {
      return 'Low';
    }

    return 'Normal';
  }


  // ================= STATUS COLOR =================

  Color getStatusColor(String status) {

    if (status == 'High') {
      return const Color(0xFFD95353);
    }

    if (status == 'Low') {
      return const Color(0xFFE09A55);
    }

    if (status == 'Invalid') {
      return const Color(0xFFD95353);
    }

    return const Color(0xFF4D9B82);
  }


  Color getStatusBackground(String status) {

    if (status == 'High') {
      return const Color(0xFFFFE5E5);
    }

    if (status == 'Low') {
      return const Color(0xFFFFF1D9);
    }

    if (status == 'Invalid') {
      return const Color(0xFFFFE5E5);
    }

    return const Color(0xFFDDF5EB);
  }


  // ================= EDIT HEALTH VALUE =================

  void editHealthValue({
    required String title,
    required String currentValue,
    required String unit,
    required String Function(String) getStatus,
    required Function(String, String) onSave,
  }) {

    final controller =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          title: Text(
            'Update $title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF193B35),
            ),
          ),

          content: TextField(

            controller: controller,

            keyboardType: TextInputType.text,

            decoration: InputDecoration(
              labelText: title,
              hintText: unit == 'mmHg'
                  ? 'Example: 120/80'
                  : 'Enter value',
              suffixText: unit,
              border: const OutlineInputBorder(),
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton.icon(

              onPressed: () {

                final value =
                    controller.text.trim();

                if (value.isEmpty) {

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please enter a value.'),
                    ),
                  );

                  return;
                }

                final status =
                    getStatus(value);

                if (status == 'Invalid') {

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid $title value.',
                      ),
                    ),
                  );

                  return;
                }

                setState(() {

                  onSave(value, status);

                  history.insert(
                    0,
                    HealthRecord(
                      type: title,
                      value: value,
                      unit: unit,
                      status: status,
                      time: DateTime.now(),
                    ),
                  );
                  final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  await FirebaseFirestore.instance
      .collection("health_records")
      .add({
    "userId": user.uid,
    "type": title,
    "value": value,
    "unit": unit,
    "status": status,
    "time": FieldValue.serverTimestamp(),
  });
}

Navigator.pop(dialogContext);

                final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  await FirebaseFirestore.instance
      .collection("health_records")
      .add({
    "userId": user.uid,
    "type": title,
    "value": value,
    "unit": unit,
    "status": status,
    "time": FieldValue.serverTimestamp(),
  });
}

                Navigator.pop(dialogContext);
              },

              icon:
                  const Icon(Icons.save_rounded),

              label:
                  const Text('Save'),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF4D9B82),
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }


  // ================= TIME FORMAT =================

  String formatTime(DateTime time) {

    int hour = time.hour;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }


  // ================= RECORD ICON =================

  IconData recordIcon(String type) {

    switch (type) {

      case 'Heart Rate':
        return Icons.favorite_rounded;

      case 'Blood Pressure':
        return Icons.monitor_heart_rounded;

      case 'Temperature':
        return Icons.thermostat_rounded;

      case 'SpO₂':
        return Icons.air_rounded;

      default:
        return Icons.health_and_safety_rounded;
    }
  }


  @override
  Widget build(BuildContext context) {

    return SafeArea(

      child: SingleChildScrollView(

        padding:
            const EdgeInsets.fromLTRB(
          20,
          25,
          20,
          30,
        ),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ================= HEADER =================

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                const Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      'My Health',

                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF193B35),
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Keep track of your health',

                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF71807A),
                      ),
                    ),
                  ],
                ),

                Container(

                  padding:
                      const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFDDF5EB),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),

                  child: const Icon(
                    Icons.favorite_rounded,
                    color:
                        Color(0xFF4D9B82),
                    size: 25,
                  ),
                ),
              ],
            ),


            const SizedBox(height: 25),


            // ================= OVERALL HEALTH =================

            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.all(22),

              decoration: BoxDecoration(

                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFFB8E8D4),
                    Color(0xFFDDF5EB),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(25),
              ),

              child: Row(

                children: [

                  Container(

                    width: 65,
                    height: 65,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white
                              .withValues(alpha: 0.75),
                      shape:
                          BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 34,
                      color:
                          Color(0xFF4D9B82),
                    ),
                  ),

                  const SizedBox(width: 17),

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Overall Health',

                          style: TextStyle(
                            fontSize: 15,
                            color:
                                Color(0xFF49665D),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          (heartStatus == 'Normal' &&
                                  bpStatus == 'Normal' &&
                                  temperatureStatus ==
                                      'Normal' &&
                                  oxygenStatus ==
                                      'Normal')
                              ? 'Looking Good!'
                              : 'Needs Attention',

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF193B35),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          (heartStatus == 'Normal' &&
                                  bpStatus == 'Normal' &&
                                  temperatureStatus ==
                                      'Normal' &&
                                  oxygenStatus ==
                                      'Normal')
                              ? 'Your health indicators are normal.'
                              : 'One or more readings need attention.',

                          style: const TextStyle(
                            fontSize: 12,
                            color:
                                Color(0xFF49665D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 28),


            // ================= VITAL SIGNS =================

            const Text(
              'Vital Signs',

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF193B35),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tap a reading to update it',

              style: TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF71807A),
              ),
            ),

            const SizedBox(height: 14),


            // ================= HEART + BP =================

            Row(

              children: [

                Expanded(

                  child: healthCard(
                    icon:
                        Icons.favorite_rounded,
                    title:
                        'Heart Rate',
                    value:
                        heartRate,
                    unit:
                        'BPM',
                    status:
                        heartStatus,

                    onTap: () {

                      editHealthValue(

                        title:
                            'Heart Rate',

                        currentValue:
                            heartRate,

                        unit:
                            'BPM',

                        getStatus:
                            getHeartStatus,

                        onSave:
                            (value, status) {

                          heartRate =
                              value;

                          heartStatus =
                              status;
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child: healthCard(

                    icon:
                        Icons.monitor_heart_rounded,

                    title:
                        'Blood Pressure',

                    value:
                        bloodPressure,

                    unit:
                        'mmHg',

                    status:
                        bpStatus,

                    onTap: () {

                      editHealthValue(

                        title:
                            'Blood Pressure',

                        currentValue:
                            bloodPressure,

                        unit:
                            'mmHg',

                        getStatus:
                            getBPStatus,

                        onSave:
                            (value, status) {

                          bloodPressure =
                              value;

                          bpStatus =
                              status;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),


            const SizedBox(height: 12),


            // ================= TEMP + SPO2 =================

            Row(

              children: [

                Expanded(

                  child: healthCard(

                    icon:
                        Icons.thermostat_rounded,

                    title:
                        'Temperature',

                    value:
                        temperature,

                    unit:
                        '°C',

                    status:
                        temperatureStatus,

                    onTap: () {

                      editHealthValue(

                        title:
                            'Temperature',

                        currentValue:
                            temperature,

                        unit:
                            '°C',

                        getStatus:
                            getTemperatureStatus,

                        onSave:
                            (value, status) {

                          temperature =
                              value;

                          temperatureStatus =
                              status;
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(

                  child: healthCard(

                    icon:
                        Icons.air_rounded,

                    title:
                        'SpO₂',

                    value:
                        oxygen,

                    unit:
                        '%',

                    status:
                        oxygenStatus,

                    onTap: () {

                      editHealthValue(

                        title:
                            'SpO₂',

                        currentValue:
                            oxygen,

                        unit:
                            '%',

                        getStatus:
                            getOxygenStatus,

                        onSave:
                            (value, status) {

                          oxygen =
                              value;

                          oxygenStatus =
                              status;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),


            const SizedBox(height: 30),


            // ================= HISTORY =================

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                const Text(
                  'Health History',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF193B35),
                  ),
                ),

                Text(
                  '${history.length} records',

                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF71807A),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 14),


            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(22),

                border: Border.all(
                  color:
                      const Color(0xFFE3ECE8),
                ),
              ),

              child: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("health_records")
      .where(
        "userId",
        isEqualTo: FirebaseAuth.instance.currentUser?.uid,
      )
      .orderBy("time", descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            "No health records yet.\nUpdate a vital reading to create history.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final docs = snapshot.data!.docs;

    return Column(
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  recordIcon(data["type"] ?? ""),
                  color: const Color(0xFF4D9B82),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["type"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF193B35),
                      ),
                    ),
                    Text(
                      data["status"] ?? "",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF71807A),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${data["value"]} ${data["unit"]}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  },
),
            ),


            const SizedBox(height: 20),


            // ================= HEALTH TIP =================

            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                    const Color(0xFFFFF7E8),
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: const Row(

                children: [

                  Icon(
                    Icons.lightbulb_rounded,
                    color:
                        Color(0xFFE09A55),
                    size: 27,
                  ),

                  SizedBox(width: 13),

                  Expanded(

                    child: Text(
                      'Health readings are for monitoring purposes and should not replace professional medical advice.',

                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color:
                            Color(0xFF765B38),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ================= HEALTH CARD =================

  Widget healthCard({

    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String status,
    required VoidCallback onTap,

  }) {

    final statusColor =
        getStatusColor(status);

    final statusBackground =
        getStatusBackground(status);

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(21),

          boxShadow: [

            BoxShadow(
              color:
                  Colors.black
                      .withValues(alpha: 0.04),

              blurRadius:
                  10,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [

                Container(

                  width: 43,
                  height: 43,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFEAF7F1),

                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: Icon(
                    icon,

                    color:
                        const Color(0xFF4D9B82),

                    size: 22,
                  ),
                ),

                const Icon(
                  Icons.edit_rounded,

                  size: 16,

                  color:
                      Color(0xFF9AB8AC),
                ),
              ],
            ),


            const SizedBox(height: 12),


            Text(
              title,

              style: const TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF71807A),
              ),
            ),


            const SizedBox(height: 4),


            Row(

              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [

                Flexible(

                  child: Text(
                    value,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF193B35),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                Padding(

                  padding:
                      const EdgeInsets.only(
                    bottom: 2,
                  ),

                  child: Text(
                    unit,

                    style: const TextStyle(
                      fontSize: 10,
                      color:
                          Color(0xFF71807A),
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 7),


            Container(

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),

              decoration:
                  BoxDecoration(

                color:
                    statusBackground,

                borderRadius:
                    BorderRadius.circular(8),
              ),

              child: Text(

                '● $status',

                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ================= HISTORY CARD =================

  Widget historyCard(
    HealthRecord record,
  ) {

    final statusColor =
        getStatusColor(record.status);

    final statusBackground =
        getStatusBackground(record.status);

    return Row(

      children: [

        Container(

          width: 45,
          height: 45,

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFEAF7F1),

            borderRadius:
                BorderRadius.circular(14),
          ),

          child: Icon(
            recordIcon(record.type),

            color:
                const Color(0xFF4D9B82),

            size: 22,
          ),
        ),


        const SizedBox(width: 13),


        Expanded(

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                record.type,

                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 14,
                  color:
                      Color(0xFF193B35),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                formatTime(record.time),

                style: const TextStyle(
                  fontSize: 11,
                  color:
                      Color(0xFF71807A),
                ),
              ),
            ],
          ),
        ),


        Column(

          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [

            Text(
              '${record.value} ${record.unit}',

              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF193B35),
              ),
            ),

            const SizedBox(height: 4),

            Container(

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),

              decoration:
                  BoxDecoration(

                color:
                    statusBackground,

                borderRadius:
                    BorderRadius.circular(7),
              ),

              child: Text(

                record.status,

                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ================= PROFILE =================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Sparsha";
  String age = "20";
  String phone = "";
  String emergencyContact = "";
  String language = "English";

  bool notificationsEnabled = true;

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =========================
  // LOAD SAVED PROFILE
  // =========================
Future<void> _loadProfile() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .get();

  if (!doc.exists) return;

  final data = doc.data()!;

  setState(() {
    name = data["name"] ?? "Sparsha";
    age = data["age"] ?? "20";
    phone = data["phone"] ?? "";
    emergencyContact = data["emergencyContact"] ?? "";
    language = data["language"] ?? "English";
    notificationsEnabled = data["notificationsEnabled"] ?? true;
  });
}
  // =========================
  // SAVE PROFILE
  // =========================
Future<void> _saveProfile() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .set({
    "name": nameController.text.trim(),
    "age": ageController.text.trim(),
    "phone": phoneController.text.trim(),
    "emergencyContact": emergencyContact,
    "language": language,
    "notificationsEnabled": notificationsEnabled,
  }, SetOptions(merge: true));

  setState(() {
    name = nameController.text.trim();
    age = ageController.text.trim();
    phone = phoneController.text.trim();
  });
}

  // =========================
  // EDIT PROFILE
  // =========================
  void _editProfile() {
    nameController.text = name;
    ageController.text = age;
    phoneController.text = phone;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF193B35),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    prefixIcon:
                        const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Age",
                    prefixIcon:
                        const Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon:
                        const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D9B82),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter your name"),
                    ),
                  );
                  return;
                }

                await _saveProfile();

                if (mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("Profile updated successfully 💚"),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // EMERGENCY CONTACT
  // =========================
  void _editEmergencyContact() {
    emergencyController.text = emergencyContact;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Emergency Contact",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF193B35),
            ),
          ),

          content: TextField(
            controller: emergencyController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Emergency phone number",
              prefixIcon:
                  const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D9B82),
                foregroundColor: Colors.white,
              ),
onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .set({
    "emergencyContact": emergencyController.text.trim(),
  }, SetOptions(merge: true));

  setState(() {
    emergencyContact = emergencyController.text.trim();
  });

  if (mounted) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency contact saved"),
      ),
    );
  }
},
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // LANGUAGE
  // =========================
  void _selectLanguage() {
    final languages = [
      "English",
      "Kannada",
      "Hindi",
      "Tamil",
      "Telugu",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Select Language",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              return ListTile(
                leading: const Icon(
                  Icons.language,
                  color: Color(0xFF4D9B82),
                ),

                title: Text(lang),

                trailing: language == lang
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4D9B82),
                      )
                    : null,

                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .set({
    "language": lang,
  }, SetOptions(merge: true));
}

                  setState(() {
                    language = lang;
                  });

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // =========================
  // PROFILE TILE
  // =========================
  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),

        leading: Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            color: const Color(0xFFDDF5EB),
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(
            icon,
            color: const Color(0xFF4D9B82),
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF193B35),
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF71807A),
            ),
          ),
        ),

        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF71807A),
            ),

        onTap: onTap,
      ),
    );
  }

  // =========================
  // LOGOUT
  // =========================
  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Are you sure you want to logout?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Logout functionality will be connected to authentication later.",
                    ),
                  ),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF8),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                "My Profile",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193B35),
                ),
              ),

              const SizedBox(height: 22),

              // PROFILE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDDF5EB),
                      Color(0xFFB8E8D4),
                    ],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius:
                      BorderRadius.circular(24),
                ),

                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.08),
                            blurRadius: 12,
                          ),
                        ],
                      ),

                      child: const Icon(
                        Icons.person,
                        size: 52,
                        color: Color(0xFF4D9B82),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      name.isEmpty ? "User" : name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF193B35),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Age $age • SmartCare User",
                      style: const TextStyle(
                        color: Color(0xFF71807A),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed: _editProfile,

                        icon: const Icon(
                          Icons.edit_outlined,
                        ),

                        label:
                            const Text("Edit Profile"),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF4D9B82),

                          foregroundColor:
                              Colors.white,

                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 13,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193B35),
                ),
              ),

              const SizedBox(height: 12),

              _profileTile(
                icon: Icons.phone_outlined,
                title: "Phone Number",
                subtitle: phone.isEmpty
                    ? "Not added"
                    : phone,
              ),

              _profileTile(
                icon:
                    Icons.contact_emergency_outlined,
                title: "Emergency Contact",
                subtitle: emergencyContact.isEmpty
                    ? "Not added"
                    : emergencyContact,
                onTap: _editEmergencyContact,
              ),

              _profileTile(
                icon: Icons.language_outlined,
                title: "Language",
                subtitle: language,
                onTap: _selectLanguage,
              ),

              const SizedBox(height: 16),

              const Text(
                "App Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193B35),
                ),
              ),

              const SizedBox(height: 12),

              _profileTile(
                icon:
                    Icons.notifications_outlined,
                title: "Medicine Notifications",
                subtitle: notificationsEnabled
                    ? "Notifications are enabled"
                    : "Notifications are disabled",

                trailing: Switch(
                  value: notificationsEnabled,

                  activeColor:
                      const Color(0xFF4D9B82),

                  onChanged: (value) async {
                    final prefs =
                        await SharedPreferences
                            .getInstance();

                    await prefs.setBool(
                      "notifications_enabled",
                      value,
                    );

                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
              ),

              _profileTile(
                icon: Icons.people_outline,
                title: "Caregiver",
                subtitle:
                    "Manage caregiver connection",
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Caregiver connection will be added next 👨‍⚕️",
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // LOGOUT
              Container(
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 5,
                  ),

                  leading: Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5E5),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                    ),
                  ),

                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),

                  subtitle: const Text(
                    "Sign out of SmartCare",
                    style: TextStyle(
                      color: Color(0xFF71807A),
                    ),
                  ),

                  onTap: _logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    emergencyController.dispose();
    super.dispose();
  }
}