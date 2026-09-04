import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ocr_screen.dart';


// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartCareApp());
}


// ============================================================
// SMARTCARE APP
// ============================================================

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SmartCare",

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4FBF9),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF78B9A7),
          brightness: Brightness.light,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD5E9E2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFD5E9E2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF78B9A7),
              width: 2,
            ),
          ),
        ),
      ),

      // IMPORTANT:
      // App now starts with authentication checking.
      home: const AuthGate(),
    );
  }
}


// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginPage();
      },
    );
  }
}


// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please enter email and password");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      if (e.code == "user-not-found") {
        message = "No account found with this email";
      } else if (e.code == "wrong-password") {
        message = "Incorrect password";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address";
      } else if (e.code == "invalid-credential") {
        message = "Invalid email or password";
      }

      showMessage(message);
    } catch (e) {
      showMessage("Something went wrong");
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> createAccount() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Enter email and password first");
      return;
    }

    if (password.length < 6) {
      showMessage("Password must contain at least 6 characters");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "name": "Sparsha",
          "age": "20",
          "phone": "",
          "emergencyContact": "",
          "language": "English",
          "notificationsEnabled": true,
          "email": email,
        });
      }

      showMessage("Account created successfully!");
    } on FirebaseAuthException catch (e) {
      String message = "Account creation failed";

      if (e.code == "email-already-in-use") {
        message = "An account already exists with this email";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address";
      } else if (e.code == "weak-password") {
        message = "Password is too weak";
      }

      showMessage(message);
    } catch (e) {
      showMessage("Something went wrong");
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF9),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [

                // LOGO
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF5EB),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 48,
                    color: Color(0xFF78B9A7),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "SmartCare",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF193B35),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Smart medication & care monitoring",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF648079),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed: loading ? null : login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF78B9A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: OutlinedButton(
                    onPressed: loading ? null : createAccount,

                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F8E7D),
                      side: const BorderSide(
                        color: Color(0xFF78B9A7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Your care. Your health. Your peace of mind.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF78928B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  String profileName = "Sparsha";

  @override
  void initState() {
    super.initState();
    loadProfileName();
  }

  Future<void> loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString("profile_name");

    if (savedName != null && savedName.isNotEmpty && mounted) {
      setState(() {
        profileName = savedName;
      });
    }
  }

  void updateProfileName(String name) {
    if (!mounted) return;

    setState(() {
      profileName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(name: profileName),

      const MedicinesPage(),

      const HealthPage(),

      ProfilePage(
        onNameChanged: updateProfileName,
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        backgroundColor: Colors.white,

        indicatorColor: const Color(0xFFDDF5EB),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: "Medicines",
          ),

          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: "Health",
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}


// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  final String name;

  const HomePage({
    super.key,
    required this.name,
  });

  Future<void> sendSOS(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please login first"),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection("sos").add({
        "userId": user.uid,
        "name": name,
        "time": FieldValue.serverTimestamp(),
        "status": "Emergency",
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("SOS Sent"),
            content: const Text(
              "Emergency alert has been sent successfully.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to send SOS"),
        ),
      );
    }
  }

  void handleFeature(
    BuildContext context,
    String title,
  ) {
    // FIXED MEDICINES NAVIGATION
    if (title == "Medicines") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MedicinesPage(),
        ),
      );
      return;
    }

    if (title == "Caregiver") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CaregiverPage(),
        ),
      );
      return;
    }

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
      sendSOS(context);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 10),

            Text(
              "Hello, $name 👋",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B35),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Take care of your health today.",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF648079),
              ),
            ),

            const SizedBox(height: 22),

            // WELCOME CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: const Color(0xFFDDF5EB),
                borderRadius: BorderRadius.circular(24),
              ),

              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: const [
                        Text(
                          "Stay healthy 💚",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF193B35),
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "SmartCare helps you manage medicines, health records and caregiver support.",
                          style: TextStyle(
                            color: Color(0xFF55766D),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.health_and_safety_rounded,
                    size: 65,
                    color: Color(0xFF78B9A7),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Quick Access",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B35),
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              crossAxisCount: 2,

              crossAxisSpacing: 14,
              mainAxisSpacing: 14,

              childAspectRatio: 1.15,

              children: [

                featureCard(
                  context,
                  Icons.medication_rounded,
                  "Medicines",
                ),

                featureCard(
                  context,
                  Icons.people_alt_rounded,
                  "Caregiver",
                ),

                featureCard(
                  context,
                  Icons.document_scanner_rounded,
                  "Prescription Scanner",
                ),

                featureCard(
                  context,
                  Icons.emergency_rounded,
                  "SOS Emergency",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget featureCard(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () {
        handleFeature(context, title);
      },

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: const Color(0xFFD8EAE4),
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 38,
              color: const Color(0xFF78B9A7),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF193B35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// MEDICINE MODEL
// ============================================================

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


// ============================================================
// MEDICINES PAGE
// ============================================================

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  final CollectionReference medicinesRef =
      FirebaseFirestore.instance.collection("medications");

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final timeController = TextEditingController();

  Future<void> addMedicine() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage("Please login first");
      return;
    }

    final name = nameController.text.trim();
    final dosage = dosageController.text.trim();
    final time = timeController.text.trim();

    if (name.isEmpty) {
      showMessage("Enter medicine name");
      return;
    }

    try {
      await medicinesRef.add({
        "userId": user.uid,
        "name": name,
        "dosage": dosage,
        "time": time,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      nameController.clear();
      dosageController.clear();
      timeController.clear();

      if (mounted) {
        Navigator.pop(context);
      }

      showMessage("Medicine saved successfully");
    } catch (e) {
      showMessage("Could not save medicine");
    }
  }

  Future<void> deleteMedicine(String docId) async {
    try {
      await medicinesRef.doc(docId).delete();

      showMessage("Medicine deleted");
    } catch (e) {
      showMessage("Could not delete medicine");
    }
  }

  Future<void> toggleMedicine(
    String docId,
    bool currentStatus,
  ) async {
    try {
      await medicinesRef.doc(docId).update({
        "status": currentStatus ? "pending" : "taken",
      });
    } catch (e) {
      showMessage("Could not update medicine");
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openAddMedicine() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4FBF9),

      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                "Add Medicine",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193B35),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Medicine Name",
                  prefixIcon: Icon(Icons.medication),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: "Dosage",
                  hintText: "e.g. 500 mg",
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: "Time",
                  hintText: "e.g. 8:00 AM",
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: addMedicine,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF78B9A7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    "Save Medicine",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please login"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Medicines",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF4FBF9),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddMedicine,

        backgroundColor:
            const Color(0xFF78B9A7),

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: medicinesRef
            .where(
              "userId",
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading medicines:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.medication_outlined,
                    size: 70,
                    color: Color(0xFF9BC9BB),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "No medicines added yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF193B35),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Tap + to add your medicine",
                    style: TextStyle(
                      color: Color(0xFF648079),
                    ),
                  ),
                ],
              ),
            );
          }

          final sortedDocs = [...docs];

          sortedDocs.sort((a, b) {
            final aData =
                a.data() as Map<String, dynamic>;

            final bData =
                b.data() as Map<String, dynamic>;

            final aTime =
                aData["createdAt"] as Timestamp?;

            final bTime =
                bData["createdAt"] as Timestamp?;

            if (aTime == null && bTime == null) {
              return 0;
            }

            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime);
          });

          int takenCount = 0;

          for (final doc in sortedDocs) {
            final data =
                doc.data() as Map<String, dynamic>;

            if (data["status"] == "taken") {
              takenCount++;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),

            children: [

              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5EB),
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Row(
                  children: [

                    const Icon(
                      Icons.medication_rounded,
                      size: 40,
                      color: Color(0xFF78B9A7),
                    ),

                    const SizedBox(width: 15),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Today's Medicines",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF193B35),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "$takenCount of ${sortedDocs.length} taken",
                          style: const TextStyle(
                            color: Color(0xFF648079),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ...sortedDocs.map((doc) {
                final data =
                    doc.data() as Map<String, dynamic>;

                final medicineName =
                    data["name"] ?? "";

                final dosage =
                    data["dosage"] ?? "";

                final time =
                    data["time"] ?? "";

                final isTaken =
                    data["status"] == "taken";

                return Container(
                  margin:
                      const EdgeInsets.only(bottom: 14),

                  padding: const EdgeInsets.all(17),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),

                    border: Border.all(
                      color:
                          const Color(0xFFD8EAE4),
                    ),
                  ),

                  child: Row(
                    children: [

                      Container(
                        padding:
                            const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFDDF5EB),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.medication,
                          color:
                              Color(0xFF78B9A7),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              medicineName,
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Color(0xFF193B35),
                              ),
                            ),

                            if (dosage
                                .toString()
                                .isNotEmpty)
                              Text(
                                dosage.toString(),
                                style:
                                    const TextStyle(
                                  color:
                                      Color(0xFF648079),
                                ),
                              ),

                            if (time
                                .toString()
                                .isNotEmpty)
                              Text(
                                time.toString(),
                                style:
                                    const TextStyle(
                                  color:
                                      Color(0xFF648079),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Checkbox(
                        value: isTaken,

                        activeColor:
                            const Color(0xFF78B9A7),

                        onChanged: (_) {
                          toggleMedicine(
                            doc.id,
                            isTaken,
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),

                        onPressed: () {
                          deleteMedicine(doc.id);
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}


// ============================================================
// HEALTH PAGE
// ============================================================

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final bpController = TextEditingController();
  final sugarController = TextEditingController();
  final heartRateController = TextEditingController();
  final temperatureController = TextEditingController();

  Future<void> saveHealthRecord(
    String type,
    String value,
    String unit,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage("Please login first");
      return;
    }

    if (value.trim().isEmpty) {
      showMessage("Enter a value");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("health_records")
          .add({
        "userId": user.uid,
        "type": type,
        "value": value.trim(),
        "unit": unit,
        "status": "Recorded",
        "time": FieldValue.serverTimestamp(),
      });

      showMessage("$type saved successfully");
    } catch (e) {
      showMessage("Could not save health record");
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    bpController.dispose();
    sugarController.dispose();
    heartRateController.dispose();
    temperatureController.dispose();
    super.dispose();
  }

  Widget healthInput(
    String title,
    String unit,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFD8EAE4),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Icon(
                icon,
                color: const Color(0xFF78B9A7),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193B35),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      TextInputType.text,

                  decoration:
                      InputDecoration(
                    hintText: "Enter value",
                    suffixText: unit,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              IconButton(
                onPressed: () {
                  saveHealthRecord(
                    title,
                    controller.text,
                    unit,
                  );
                },

                icon: const Icon(
                  Icons.save_outlined,
                ),

                color:
                    const Color(0xFF78B9A7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Health",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor:
            const Color(0xFFF4FBF9),
      ),

      body: user == null
          ? const Center(
              child: Text("Please login"),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Health Records",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF193B35),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Keep track of your important health readings.",
                    style: TextStyle(
                      color: Color(0xFF648079),
                    ),
                  ),

                  const SizedBox(height: 22),

                  healthInput(
                    "Blood Pressure",
                    "mmHg",
                    Icons.favorite_outline,
                    bpController,
                  ),

                  healthInput(
                    "Blood Sugar",
                    "mg/dL",
                    Icons.water_drop_outlined,
                    sugarController,
                  ),

                  healthInput(
                    "Heart Rate",
                    "bpm",
                    Icons.monitor_heart_outlined,
                    heartRateController,
                  ),

                  healthInput(
                    "Temperature",
                    "°C",
                    Icons.thermostat_outlined,
                    temperatureController,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Recent Records",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF193B35),
                    ),
                  ),

                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("health_records")
                        .where(
                          "userId",
                          isEqualTo: user.uid,
                        )
                        .snapshots(),

                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          "Unable to load records",
                          style: TextStyle(
                            color: Colors.red.shade400,
                          ),
                        );
                      }

                      final docs =
                          snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Text(
                          "No health records yet.",
                          style: TextStyle(
                            color: Color(0xFF648079),
                          ),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;

                          return Container(
                            width: double.infinity,
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),

                            padding:
                                const EdgeInsets.all(15),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),

                            child: Row(
                              children: [

                                const Icon(
                                  Icons
                                      .health_and_safety_outlined,
                                  color:
                                      Color(0xFF78B9A7),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    "${data["type"]}: ${data["value"]} ${data["unit"]}",
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      color:
                                          Color(0xFF193B35),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}


// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatefulWidget {
  final Function(String) onNameChanged;

  const ProfilePage({
    super.key,
    required this.onNameChanged,
  });

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      String loadedName =
          prefs.getString("profile_name") ??
              "Sparsha";

      String loadedAge =
          prefs.getString("profile_age") ?? "20";

      String loadedPhone =
          prefs.getString("profile_phone") ?? "";

      final user =
          FirebaseAuth.instance.currentUser;

      String loadedEmergency = "";
      String loadedLanguage = "English";
      bool loadedNotifications = true;

      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (doc.exists) {
          final data = doc.data() ?? {};

          loadedName =
              data["name"]?.toString() ??
                  loadedName;

          loadedAge =
              data["age"]?.toString() ??
                  loadedAge;

          loadedPhone =
              data["phone"]?.toString() ??
                  loadedPhone;

          loadedEmergency =
              data["emergencyContact"]
                      ?.toString() ??
                  "";

          loadedLanguage =
              data["language"]?.toString() ??
                  "English";

          loadedNotifications =
              data["notificationsEnabled"] ??
                  true;
        }
      }

      if (!mounted) return;

      setState(() {
        name = loadedName;
        age = loadedAge;
        phone = loadedPhone;
        emergencyContact = loadedEmergency;
        language = loadedLanguage;
        notificationsEnabled =
            loadedNotifications;
      });

      nameController.text = name;
      ageController.text = age;
      phoneController.text = phone;
    } catch (e) {
      debugPrint(
        "Profile load error: $e",
      );
    }
  }

  Future<bool> _saveProfile() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        "Please login before updating profile",
      );
      return false;
    }

    final newName =
        nameController.text.trim();

    final newAge =
        ageController.text.trim();

    final newPhone =
        phoneController.text.trim();

    if (newName.isEmpty) {
      showMessage("Name cannot be empty");
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "name": newName,
        "age": newAge,
        "phone": newPhone,
        "emergencyContact":
            emergencyContact,
        "language": language,
        "notificationsEnabled":
            notificationsEnabled,
        "email": user.email ?? "",
      }, SetOptions(merge: true));

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        "profile_name",
        newName,
      );

      await prefs.setString(
        "profile_age",
        newAge,
      );

      await prefs.setString(
        "profile_phone",
        newPhone,
      );

      if (!mounted) return false;

      setState(() {
        name = newName;
        age = newAge;
        phone = newPhone;
      });

      widget.onNameChanged(newName);

      showMessage(
        "Profile updated successfully 💚",
      );

      return true;
    } catch (e) {
      debugPrint(
        "Profile save error: $e",
      );

      showMessage(
        "Profile update failed. Check Firebase connection.",
      );

      return false;
    }
  }

  void _editProfile() {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Edit Profile",
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                TextField(
                  controller:
                      nameController,
                  decoration:
                      const InputDecoration(
                    labelText: "Name",
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      ageController,
                  keyboardType:
                      TextInputType.number,

                  decoration:
                      const InputDecoration(
                    labelText: "Age",
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      phoneController,
                  keyboardType:
                      TextInputType.phone,

                  decoration:
                      const InputDecoration(
                    labelText: "Phone",
                  ),
                ),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final success =
                    await _saveProfile();

                if (success &&
                    dialogContext.mounted) {
                  Navigator.pop(
                    dialogContext,
                  );
                }
              },

              child:
                  const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveEmergencyContact(
    String value,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "emergencyContact": value,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          emergencyContact = value;
        });
      }

      showMessage(
        "Emergency contact saved",
      );
    } catch (e) {
      showMessage(
        "Could not save emergency contact",
      );
    }
  }

  Future<void> saveLanguage(
    String value,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "language": value,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          language = value;
        });
      }

      showMessage(
        "Language updated",
      );
    } catch (e) {
      showMessage(
        "Could not update language",
      );
    }
  }

  Future<void> saveNotifications(
    bool value,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        "notifications_enabled",
        value,
      );

      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "notificationsEnabled": value,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          notificationsEnabled = value;
        });
      }
    } catch (e) {
      showMessage(
        "Could not update notification setting",
      );
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // IMPORTANT:
      // DO NOT sign in anonymously again.
      // AuthGate will automatically show LoginPage.
    } catch (e) {
      showMessage("Logout failed");
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor:
            const Color(0xFFF4FBF9),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // PROFILE ICON
            Container(
              width: 100,
              height: 100,

              decoration: BoxDecoration(
                color: const Color(0xFFDDF5EB),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person,
                size: 55,
                color: Color(0xFF78B9A7),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF193B35),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              user?.email ?? "",
              style: const TextStyle(
                color: Color(0xFF648079),
              ),
            ),

            const SizedBox(height: 25),

            profileTile(
              Icons.person_outline,
              "Name",
              name,
            ),

            profileTile(
              Icons.cake_outlined,
              "Age",
              age,
            ),

            profileTile(
              Icons.phone_outlined,
              "Phone",
              phone.isEmpty
                  ? "Not added"
                  : phone,
            ),

            profileTile(
              Icons.contact_phone_outlined,
              "Emergency Contact",
              emergencyContact.isEmpty
                  ? "Not added"
                  : emergencyContact,
            ),

            profileTile(
              Icons.language_outlined,
              "Language",
              language,
            ),

            const SizedBox(height: 10),

            // EDIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: _editProfile,

                icon: const Icon(
                  Icons.edit,
                ),

                label: const Text(
                  "Edit Profile",
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF78B9A7),
                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // EMERGENCY CONTACT
            Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.emergency_outlined,
                  color: Colors.redAccent,
                ),

                title: const Text(
                  "Emergency Contact",
                ),

                subtitle: Text(
                  emergencyContact.isEmpty
                      ? "Add emergency contact"
                      : emergencyContact,
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: () {
                  final controller =
                      TextEditingController(
                    text:
                        emergencyContact,
                  );

                  showDialog(
                    context: context,

                    builder: (_) =>
                        AlertDialog(
                      title: const Text(
                        "Emergency Contact",
                      ),

                      content: TextField(
                        controller:
                            controller,

                        keyboardType:
                            TextInputType.phone,

                        decoration:
                            const InputDecoration(
                          hintText:
                              "Phone number",
                        ),
                      ),

                      actions: [

                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            );
                          },

                          child:
                              const Text(
                            "Cancel",
                          ),
                        ),

                        ElevatedButton(
                          onPressed: () async {
                            await saveEmergencyContact(
                              controller.text
                                  .trim(),
                            );

                            if (context
                                .mounted) {
                              Navigator.pop(
                                context,
                              );
                            }
                          },

                          child:
                              const Text(
                            "Save",
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // LANGUAGE
            Card(
              color: Colors.white,

              child: ListTile(
                leading: const Icon(
                  Icons.language,
                  color:
                      Color(0xFF78B9A7),
                ),

                title: const Text(
                  "Language",
                ),

                subtitle: Text(language),

                trailing: DropdownButton<String>(
                  value: language,

                  underline:
                      const SizedBox(),

                  items: const [
                    DropdownMenuItem(
                      value: "English",
                      child: Text("English"),
                    ),

                    DropdownMenuItem(
                      value: "Kannada",
                      child: Text("Kannada"),
                    ),

                    DropdownMenuItem(
                      value: "Hindi",
                      child: Text("Hindi"),
                    ),
                  ],

                  onChanged: (value) {
                    if (value != null) {
                      saveLanguage(value);
                    }
                  },
                ),
              ),
            ),

            // NOTIFICATIONS
            Card(
              color: Colors.white,

              child: SwitchListTile(
                title: const Text(
                  "Notifications",
                ),

                subtitle: const Text(
                  "Medicine reminder notifications",
                ),

                value:
                    notificationsEnabled,

                activeColor:
                    const Color(0xFF78B9A7),

                onChanged:
                    saveNotifications,
              ),
            ),

            const SizedBox(height: 18),

            // LOGOUT
            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton.icon(
                onPressed: logout,

                icon: const Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),

                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),

                style:
                    OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.redAccent,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget profileTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFD8EAE4),
        ),
      ),

      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF78B9A7),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF193B35),
          ),
        ),

        subtitle: Text(
          value.isEmpty
              ? "Not added"
              : value,
        ),
      ),
    );
  }
}


// ============================================================
// CAREGIVER PAGE
// ============================================================

class CaregiverPage extends StatefulWidget {
  const CaregiverPage({super.key});

  @override
  State<CaregiverPage> createState() =>
      _CaregiverPageState();
}

class _CaregiverPageState
    extends State<CaregiverPage> {
  String caregiverName = "";
  String caregiverPhone = "";
  String caregiverId = "";
  bool connected = false;

  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final idController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCaregiver();
  }

  Future<void> loadCaregiver() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      caregiverName =
          prefs.getString(
                "caregiver_name",
              ) ??
              "";

      caregiverPhone =
          prefs.getString(
                "caregiver_phone",
              ) ??
              "";

      caregiverId =
          prefs.getString(
                "caregiver_id",
              ) ??
              "";

      connected =
          prefs.getBool(
                "caregiver_connected",
              ) ??
              false;
    });
  }

  Future<void> connectCaregiver() async {
    final name =
        nameController.text.trim();

    final phone =
        phoneController.text.trim();

    final id =
        idController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        id.isEmpty) {
      showMessage(
        "Please fill all fields",
      );
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      "caregiver_name",
      name,
    );

    await prefs.setString(
      "caregiver_phone",
      phone,
    );

    await prefs.setString(
      "caregiver_id",
      id,
    );

    await prefs.setBool(
      "caregiver_connected",
      true,
    );

    if (!mounted) return;

    setState(() {
      caregiverName = name;
      caregiverPhone = phone;
      caregiverId = id;
      connected = true;
    });

    showMessage(
      "Caregiver connected",
    );
  }

  Future<void> disconnectCaregiver() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      "caregiver_connected",
      false,
    );

    if (!mounted) return;

    setState(() {
      connected = false;
    });

    showMessage(
      "Caregiver disconnected",
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Caregiver",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor:
            const Color(0xFFF4FBF9),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xFFDDF5EB),
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.people_alt_rounded,
                    size: 45,
                    color: Color(0xFF78B9A7),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Caregiver Support",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF193B35),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          connected
                              ? "Connected"
                              : "No caregiver connected",
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF648079),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            if (connected) ...[

              caregiverInfo(
                "Name",
                caregiverName,
                Icons.person_outline,
              ),

              caregiverInfo(
                "Phone",
                caregiverPhone,
                Icons.phone_outlined,
              ),

              caregiverInfo(
                "Caregiver ID",
                caregiverId,
                Icons.badge_outlined,
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: OutlinedButton(
                  onPressed:
                      disconnectCaregiver,

                  child: const Text(
                    "Disconnect Caregiver",
                  ),
                ),
              ),
            ] else ...[

              const Text(
                "Connect Caregiver",
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193B35),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    nameController,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Caregiver Name",
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    phoneController,

                keyboardType:
                    TextInputType.phone,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Caregiver Phone",
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    idController,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Caregiver ID",
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed:
                      connectCaregiver,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF78B9A7,
                    ),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child: const Text(
                    "Connect Caregiver",
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget caregiverInfo(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(0xFFD8EAE4),
        ),
      ),

      child: ListTile(
        leading: Icon(
          icon,
          color:
              const Color(0xFF78B9A7),
        ),

        title: Text(title),

        subtitle: Text(value),
      ),
    );
  }
}