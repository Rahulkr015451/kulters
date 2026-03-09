import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KultersApp());
}

class KultersApp extends StatelessWidget {
  const KultersApp({super.key});

  static const Color _primaryDeepYellow = Color(0xFFFFB300);
  static const Color _secondaryCharcoal = Color(0xFF212121);

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryDeepYellow,
        primary: _primaryDeepYellow,
        brightness: Brightness.light,
      ).copyWith(
        secondary: _secondaryCharcoal,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryDeepYellow,
        primary: _primaryDeepYellow,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: _secondaryCharcoal,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kulters',
      themeMode: ThemeMode.system,
      theme: lightTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(lightTheme.textTheme),
        appBarTheme: lightTheme.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: _secondaryCharcoal,
        ),
        bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
          selectedItemColor: _primaryDeepYellow,
          unselectedItemColor: _secondaryCharcoal.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        chipTheme: lightTheme.chipTheme.copyWith(
          selectedColor: _primaryDeepYellow,
          backgroundColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: lightTheme.cardTheme.copyWith(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(darkTheme.textTheme),
        appBarTheme: darkTheme.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: darkTheme.bottomNavigationBarTheme.copyWith(
          selectedItemColor: _primaryDeepYellow,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        chipTheme: darkTheme.chipTheme.copyWith(
          selectedColor: _primaryDeepYellow,
          backgroundColor: const Color(0xFF1F1F1F),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: darkTheme.cardTheme.copyWith(
          color: const Color(0xFF1F1F1F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Determines the correct screen based on auth state and Firestore profile.
Future<Widget> getNextScreen() async {
  final user = AuthService.instance.currentUser;
  if (user == null) return const LoginSignUpPage();

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists ||
      doc.data()?['name'] == null ||
      (doc.data()?['name'] as String).trim().isEmpty) {
    return const ProfileSetupPage();
  }

  // Get role or default to 'renter'
  String roleStr = doc.data()?['role'] as String? ?? 'renter';
  
  // If role doesn't exist, set it to 'renter' by default
  if (doc.data()?['role'] == null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'role': 'renter'});
  }

  final role = roleStr == 'owner' ? UserRole.owner : UserRole.renter;
  return KultersRoot(role: role);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final screen = await getNextScreen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    const charcoal = Color(0xFF212121);

    return Scaffold(
      backgroundColor: charcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryYellow.withOpacity(0.4), width: 2),
                color: charcoal,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction,
                size: 40,
                color: primaryYellow,
              ),
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/logo.png',
              height: 80,
              color: Colors.black,
              colorBlendMode: BlendMode.dstIn,
            ),
            const SizedBox(height: 8),
            Text(
              'Heavy Machinery. Light Work.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginSignUpPage extends StatefulWidget {
  const LoginSignUpPage({super.key});

  @override
  State<LoginSignUpPage> createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        await AuthService.instance.signUpWithEmail(
          email: email,
          password: password,
        );
      }
      if (!mounted) return;
      final screen = await getNextScreen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    const primaryYellow = Color(0xFFFFB300);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your email address and we\'ll send you a link to reset your password.'),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              foregroundColor: const Color(0xFF212121),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Check your email to reset your password.'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    const charcoal = Color(0xFF212121);

    return Scaffold(
      backgroundColor: charcoal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade300,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                  color: Colors.black,
                  colorBlendMode: BlendMode.dstIn,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLogin = true;
                                _error = null;
                              });
                            },
                            child: Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _isLogin
                                    ? primaryYellow
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLogin = false;
                                _error = null;
                              });
                            },
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: !_isLogin
                                    ? primaryYellow
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _AuthField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        obscureText: false,
                      ),
                      const SizedBox(height: 16),
                      _AuthField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _showForgotPasswordDialog(),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: primaryYellow,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryYellow,
                            foregroundColor: charcoal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(charcoal),
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Login' : 'Create account',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.obscureText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(
              icon,
              color: primaryYellow,
            ),
            filled: true,
            fillColor: const Color(0xFF111111),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryYellow,
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryYellow,
                width: 1.8,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

enum UserRole { renter, owner }

class KultersRoot extends StatefulWidget {
  const KultersRoot({super.key, required this.role});

  final UserRole role;

  @override
  State<KultersRoot> createState() => _KultersRootState();
}

class _KultersRootState extends State<KultersRoot> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role == UserRole.owner;

    final pages = isOwner
        ? const <Widget>[
            OwnerHomeScreen(),
            OwnerBookingsScreen(),
            ProfileScreen(),
          ]
        : const <Widget>[
            KultersHomeScreen(),
            RenterBookingsScreen(),
            ProfileScreen(),
          ];

    // Reset index if out of bounds (e.g. switching role)
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    final navItems = isOwner
        ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse_outlined),
              activeIcon: Icon(Icons.warehouse),
              label: 'My Fleet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ]
        : const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'My Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
      ),
    );
  }
}

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    final uid = AuthService.instance.currentUser?.uid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Fleet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your tractors, JCBs, cranes and manage all listings in one place.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  foregroundColor: const Color(0xFF212121),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OwnerListingFormScreen(),
                    ),
                  );
                  // Refresh the list after returning from the form
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Add Vehicle Listing',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: uid == null
                  ? const Center(child: Text('Not signed in.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vehicles')
                          .where('ownerId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading listings:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.red[400]),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No listings yet.\nTap "Add Vehicle Listing" to get started.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data()! as Map<String, dynamic>;
                            final docId = docs[index].id;
                            final model =
                                data['modelName'] as String? ?? 'Unnamed';
                            final type =
                                data['type'] as String? ?? '';
                            final price =
                                data['pricePerHour']?.toString() ?? '0';
                            final year =
                                data['year']?.toString() ?? '-';

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      primaryYellow.withValues(alpha: 0.15),
                                  child: const Icon(Icons.agriculture,
                                      color: primaryYellow),
                                ),
                                title: Text(
                                  model,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('$type • $year • ₹$price/hr'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red[400]),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Listing'),
                                        content: Text(
                                            'Remove "$model" from your fleet?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red[400])),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('vehicles')
                                          .doc(docId)
                                          .delete();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class KultersHomeScreen extends StatefulWidget {
  const KultersHomeScreen({super.key});

  @override
  State<KultersHomeScreen> createState() => _KultersHomeScreenState();
}

class _KultersHomeScreenState extends State<KultersHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.agriculture, 'label': 'All', 'type': 'All'},
    {'icon': Icons.agriculture, 'label': 'Tractor', 'type': 'Tractor'},
    {'icon': Icons.construction, 'label': 'JCB', 'type': 'JCB'},
    {'icon': Icons.precision_manufacturing, 'label': 'Crane', 'type': 'Crane'},
    {'icon': Icons.travel_explore, 'label': 'Excavator', 'type': 'Excavator'},
    {'icon': Icons.local_shipping, 'label': 'Loader', 'type': 'Loader'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'tractor':
        return Icons.agriculture;
      case 'jcb':
        return Icons.construction;
      case 'crane':
        return Icons.precision_manufacturing;
      case 'excavator':
        return Icons.travel_explore;
      case 'loader':
        return Icons.local_shipping;
      default:
        return Icons.agriculture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for JCB, Tractor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category list
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['type'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['type'] as String;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFFFFB300).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: isSelected 
                                  ? Colors.black
                                  : const Color(0xFFFFB300),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category['label'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected 
                                  ? const Color(0xFFFFB300)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Section header with View All button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vehicle Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AllVehiclesPage(),
                      ),
                    );
                  },
                  child: Text(
                    'View all',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFFB300),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle type sections
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehicles')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading vehicles.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Group vehicles by type
                  final Map<String, List<Map<String, dynamic>>> vehiclesByType = {};
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] as String? ?? 'Other';
                    
                    // Apply search filter
                    final modelName = data['modelName'] as String? ?? '';
                    final searchMatch = _searchQuery.isEmpty || 
                        modelName.toLowerCase().contains(_searchQuery) ||
                        type.toLowerCase().contains(_searchQuery);
                    
                    if (searchMatch) {
                      vehiclesByType.putIfAbsent(type, () => []);
                      vehiclesByType[type]!.add({
                        'doc': doc,
                        'data': data,
                      });
                    }
                  }

                  // Show only selected category or all if "All" is selected
                  final Map<String, List<Map<String, dynamic>>> filteredTypes = <String, List<Map<String, dynamic>>>{};
                  if (_selectedCategory == 'All') {
                    filteredTypes.addAll(vehiclesByType);
                  } else if (vehiclesByType.containsKey(_selectedCategory)) {
                    filteredTypes[_selectedCategory] = vehiclesByType[_selectedCategory]!;
                  }

                  if (filteredTypes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No vehicles found',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTypes.length,
                    itemBuilder: (context, index) {
                      final type = filteredTypes.keys.elementAt(index);
                      final vehicles = filteredTypes[type]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  _getVehicleIcon(type),
                                  color: const Color(0xFFFFB300),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ' (${vehicles.length})',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Vehicles in this section
                          ...vehicles.map((vehicle) {
                            final doc = vehicle['doc'];
                            final data = vehicle['data'] as Map<String, dynamic>;
                            final modelName = data['modelName'] as String? ?? 'Unnamed';
                            final price = data['pricePerHour'];
                            final year = data['year'] as int? ?? 0;
                            final hp = data['horsepower'] as int? ?? 0;
                            final ownerId = data['ownerId'] as String? ?? '';
                            final actualLocation = data['location'] as String? ?? 'Location not specified';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _VehicleCard(
                                vehicleId: doc.id,
                                ownerId: ownerId,
                                name: modelName,
                                pricePerHour: '₹${price ?? 0}/hr',
                                location: actualLocation,
                                brand: type,
                                year: year,
                                horsepower: hp,
                                ownerRating: 0,
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllVehiclesPage extends StatefulWidget {
  const AllVehiclesPage({super.key});

  @override
  State<AllVehiclesPage> createState() => _AllVehiclesPageState();
}

class _AllVehiclesPageState extends State<AllVehiclesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.agriculture, 'label': 'All', 'type': 'All'},
    {'icon': Icons.agriculture, 'label': 'Tractor', 'type': 'Tractor'},
    {'icon': Icons.construction, 'label': 'JCB', 'type': 'JCB'},
    {'icon': Icons.precision_manufacturing, 'label': 'Crane', 'type': 'Crane'},
    {'icon': Icons.travel_explore, 'label': 'Excavator', 'type': 'Excavator'},
    {'icon': Icons.local_shipping, 'label': 'Loader', 'type': 'Loader'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          color: Colors.black,
          colorBlendMode: BlendMode.dstIn,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for JCB, Tractor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1F1F1F) 
                    : Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category list
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['type'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['type'] as String;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFFFFB300).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              category['icon'] as IconData,
                              color: isSelected 
                                  ? Colors.black
                                  : const Color(0xFFFFB300),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category['label'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected 
                                  ? const Color(0xFFFFB300)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Vehicles list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading vehicles.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Apply filters
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            final modelName = data['modelName'] as String? ?? '';

            // Category filter
            final categoryMatch = _selectedCategory == 'All' || type == _selectedCategory;

            // Search filter
            final searchMatch = _searchQuery.isEmpty || 
                modelName.toLowerCase().contains(_searchQuery) ||
                type.toLowerCase().contains(_searchQuery);

            return categoryMatch && searchMatch;
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No vehicles found',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data()! as Map<String, dynamic>;
              final modelName = data['modelName'] as String? ?? 'Unnamed';
              final type = data['type'] as String? ?? '';
              final price = data['pricePerHour'];
              final year = data['year'] as int? ?? 0;
              final hp = data['horsepower'] as int? ?? 0;
              final ownerId = data['ownerId'] as String? ?? '';
              final actualLocation = data['location'] as String? ?? 'Location not specified';

              return _VehicleCard(
                vehicleId: doc.id,
                ownerId: ownerId,
                name: modelName,
                pricePerHour: '₹${price ?? 0}/hr',
                location: actualLocation,
                brand: type,
                year: year,
                horsepower: hp,
                ownerRating: 0,
              );
            },
          );
        },
      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicleId,
    required this.ownerId,
    required this.name,
    required this.pricePerHour,
    required this.location,
    required this.brand,
    required this.year,
    required this.horsepower,
    required this.ownerRating,
  });

  final String vehicleId;
  final String ownerId;
  final String name;
  final String pricePerHour;
  final String location;
  final String brand;
  final int year;
  final int horsepower;
  final double ownerRating;

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'tractor':
        return Icons.agriculture;
      case 'jcb':
        return Icons.construction;
      case 'crane':
        return Icons.precision_manufacturing;
      case 'excavator':
        return Icons.travel_explore;
      case 'loader':
        return Icons.local_shipping;
      default:
        return Icons.agriculture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFFFFB300);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VehicleDetailsPage(
                vehicleId: vehicleId,
                ownerId: ownerId,
                name: name,
                pricePerHour: pricePerHour,
                location: location,
                brand: brand,
                year: year,
                horsepower: horsepower,
                ownerRating: ownerRating,
              ),
            ),
          );
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Vehicle icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: Icon(
                      _getVehicleIcon(brand),
                      size: 40,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pricePerHour,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class VehicleDetailsPage extends StatefulWidget {
  const VehicleDetailsPage({
    super.key,
    required this.vehicleId,
    required this.ownerId,
    required this.name,
    required this.pricePerHour,
    required this.location,
    required this.brand,
    required this.year,
    required this.horsepower,
    required this.ownerRating,
  });

  final String vehicleId;
  final String ownerId;
  final String name;
  final String pricePerHour;
  final String location;
  final String brand;
  final int year;
  final int horsepower;
  final double ownerRating;

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  DateTimeRange? _selectedRange;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFFFB300),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  double _calculateTotalPrice() {
    if (_selectedRange == null) return 0.0;
    final days = _selectedRange!.end.difference(_selectedRange!.start).inDays + 1;
    final pricePerHour = double.tryParse(widget.pricePerHour.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    return days * pricePerHour * 8; // Assuming 8 hours per day
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF212121);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Image header with back button
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  child: Icon(
                    Icons.agriculture,
                    size: 96,
                    color: Colors.grey.shade600,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.4),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.location,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.ownerRating.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.pricePerHour,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primaryYellow,
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Specifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _SpecRow(label: 'Brand', value: widget.brand),
                    _SpecRow(label: 'Year', value: widget.year.toString()),
                    _SpecRow(label: 'Horsepower', value: '${widget.horsepower} HP'),
                    _SpecRow(
                      label: 'Owner Rating',
                      value: '${widget.ownerRating.toStringAsFixed(1)} / 5.0',
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Select rental dates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDates,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedRange == null
                                      ? 'Choose start and end dates'
                                      : '${_selectedRange!.start.toString().split(' ').first} → ${_selectedRange!.end.toString().split(' ').first}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: _selectedRange == null
                                            ? Colors.grey.shade600
                                            : textColor,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to open calendar',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today_outlined),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.call),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: textColor),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                // Get owner's phone number from Firestore
                                final ownerDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.ownerId)
                                    .get();
                                
                                final ownerPhone = ownerDoc.data()?['phone'] as String?;
                                
                                if (ownerPhone != null && ownerPhone.isNotEmpty) {
                                  final Uri phoneUri = Uri(scheme: 'tel', path: ownerPhone);
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri);
                                  } else {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not launch phone app')),
                                    );
                                  }
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Owner phone number not available')),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            },
                            label: const Text('Call Owner'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryYellow,
                              foregroundColor: const Color(0xFF212121),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              if (_selectedRange == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select rental dates before booking.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              
                              // Create actual booking in Firestore
                              try {
                                final user = AuthService.instance.currentUser;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please login to book')),
                                  );
                                  return;
                                }

                                await FirebaseFirestore.instance.collection('bookings').add({
                                  'vehicleId': widget.vehicleId,
                                  'vehicleName': widget.name,
                                  'ownerId': widget.ownerId,
                                  'renterId': user.uid,
                                  'startDate': _selectedRange!.start,
                                  'endDate': _selectedRange!.end,
                                  'status': 'pending',
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'totalPrice': _calculateTotalPrice(),
                                });

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking request sent! Owner will contact you soon.'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            },
                            child: const Text(
                              'Book Now',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final uid = AuthService.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'email': AuthService.instance.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'renter', // Set default role
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KultersRoot(role: UserRole.renter)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    const charcoal = Color(0xFF212121);

    return Scaffold(
      backgroundColor: charcoal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete your profile',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: primaryYellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us a bit about yourself to get started.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ProfileSetupField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Rahul Sharma',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _ProfileSetupField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+91 98765 43210',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _ProfileSetupField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Bengaluru',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        foregroundColor: charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(charcoal),
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSetupField extends StatelessWidget {
  const _ProfileSetupField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(icon, color: primaryYellow),
            filled: true,
            fillColor: const Color(0xFF111111),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryYellow, width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryYellow, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    setState(() {
      _profile = doc.data();
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginSignUpPage()),
      (route) => false,
    );
  }

  void _showRoleSwitcher() {
    final currentRole = _profile?['role'] as String? ?? 'renter';
    final newRole = currentRole == 'owner' ? 'renter' : 'owner';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Switch to $newRole'),
        content: Text('Are you sure you want to switch to $newRole mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF212121),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = AuthService.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'role': newRole});
                _loadProfile();
                
                // Notify KultersRoot to rebuild with new role
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => KultersRoot(role: newRole == 'owner' ? UserRole.owner : UserRole.renter)),
                  (route) => false,
                );
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = _profile?['name'] as String? ?? 'User';
    final email = AuthService.instance.currentUser?.email ?? '';
    final phone = _profile?['phone'] as String? ?? '';
    final city = _profile?['city'] as String? ?? '';
    final role = _profile?['role'] as String? ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryYellow.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: primaryYellow,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (role.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showRoleSwitcher,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryYellow.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 20,
                        color: primaryYellow,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Switch to ${role == 'owner' ? 'Renter' : 'Owner'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: primaryYellow,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            _ProfileInfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phone.isNotEmpty ? phone : 'Not set',
              isDark: isDark,
            ),
            _ProfileInfoTile(
              icon: Icons.location_city_outlined,
              label: 'City',
              value: city.isNotEmpty ? city : 'Not set',
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _logout,
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB300), size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RenterBookingsScreen extends StatelessWidget {
  const RenterBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    final uid = AuthService.instance.currentUser?.uid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track all your rental bookings in one place.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: uid == null
                  ? const Center(child: Text('Not signed in.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('renterId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading bookings.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note_outlined,
                                    size: 56, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No bookings yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Explore machinery and make your\nfirst booking!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data()! as Map<String, dynamic>;
                            final vehicleName =
                                data['vehicleName'] as String? ?? 'Vehicle';
                            final status =
                                data['status'] as String? ?? 'pending';
                            final startDate = data['startDate'];
                            final endDate = data['endDate'];

                            Color statusColor;
                            switch (status) {
                              case 'confirmed':
                                statusColor = Colors.green;
                                break;
                              case 'cancelled':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.orange;
                            }

                            // Handle date display
                            String startDateStr = '';
                            String endDateStr = '';
                            
                            if (startDate is Timestamp) {
                              startDateStr = startDate.toDate().toString().split(' ').first;
                            } else if (startDate is DateTime) {
                              startDateStr = startDate.toString().split(' ').first;
                            }
                            
                            if (endDate is Timestamp) {
                              endDateStr = endDate.toDate().toString().split(' ').first;
                            } else if (endDate is DateTime) {
                              endDateStr = endDate.toString().split(' ').first;
                            }

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      primaryYellow.withValues(alpha: 0.15),
                                  child: const Icon(Icons.agriculture,
                                      color: primaryYellow),
                                ),
                                title: Text(
                                  vehicleName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: startDateStr.isNotEmpty && endDateStr.isNotEmpty
                                    ? Text('$startDateStr → $endDateStr')
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status[0].toUpperCase() +
                                            status.substring(1),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.call, size: 20),
                                      onPressed: () async {
                                        try {
                                          final ownerId = data['ownerId'] as String?;
                                          if (ownerId != null) {
                                            final ownerDoc = await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(ownerId)
                                                .get();
                                            final ownerPhone = ownerDoc.data()?['phone'] as String?;
                                            
                                            if (ownerPhone != null && ownerPhone.isNotEmpty) {
                                              final Uri phoneUri = Uri(scheme: 'tel', path: ownerPhone);
                                              if (await canLaunchUrl(phoneUri)) {
                                                await launchUrl(
                                                  phoneUri,
                                                  mode: LaunchMode.externalApplication,
                                                );
                                              } else {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Could not launch phone app')),
                                                );
                                              }
                                            } else {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Owner phone number not available')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: ${e.toString()}')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    final uid = AuthService.instance.currentUser?.uid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage rental requests for your vehicles.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: uid == null
                  ? const Center(child: Text('Not signed in.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('ownerId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading bookings.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note_outlined,
                                    size: 56, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No booking requests yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'When renters book your vehicles,\nyou\'ll see them here!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data()! as Map<String, dynamic>;
                            final vehicleName =
                                data['vehicleName'] as String? ?? 'Vehicle';
                            final status =
                                data['status'] as String? ?? 'pending';
                            final startDate = data['startDate'];
                            final endDate = data['endDate'];
                            final renterId = data['renterId'] as String?;
                            final totalPrice = data['totalPrice'] as double? ?? 0.0;

                            Color statusColor;
                            switch (status) {
                              case 'confirmed':
                                statusColor = Colors.green;
                                break;
                              case 'cancelled':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.orange;
                            }

                            // Handle date display
                            String startDateStr = '';
                            String endDateStr = '';
                            
                            if (startDate is Timestamp) {
                              startDateStr = startDate.toDate().toString().split(' ').first;
                            } else if (startDate is DateTime) {
                              startDateStr = startDate.toString().split(' ').first;
                            }
                            
                            if (endDate is Timestamp) {
                              endDateStr = endDate.toDate().toString().split(' ').first;
                            } else if (endDate is DateTime) {
                              endDateStr = endDate.toString().split(' ').first;
                            }

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              primaryYellow.withValues(alpha: 0.15),
                                          child: const Icon(Icons.agriculture,
                                              color: primaryYellow),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                vehicleName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              if (startDateStr.isNotEmpty && endDateStr.isNotEmpty)
                                                Text(
                                                  '$startDateStr → $endDateStr',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(color: Colors.grey[600]),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status[0].toUpperCase() +
                                                status.substring(1),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total: ₹${totalPrice.toStringAsFixed(0)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Row(
                                          children: [
                                            if (status == 'pending') ...[
                                              TextButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore.instance
                                                      .collection('bookings')
                                                      .doc(docs[index].id)
                                                      .update({'status': 'confirmed'});
                                                },
                                                child: const Text('Accept'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore.instance
                                                      .collection('bookings')
                                                      .doc(docs[index].id)
                                                      .update({'status': 'cancelled'});
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Decline'),
                                              ),
                                            ],
                                            IconButton(
                                              icon: const Icon(Icons.call, size: 20),
                                              onPressed: () async {
                                                if (renterId != null) {
                                                  try {
                                                    final renterDoc = await FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(renterId)
                                                        .get();
                                                    final renterPhone = renterDoc.data()?['phone'] as String?;
                                                    
                                                    if (renterPhone != null && renterPhone.isNotEmpty) {
                                                      final Uri phoneUri = Uri(scheme: 'tel', path: renterPhone);
                                                      if (await canLaunchUrl(phoneUri)) {
                                                        await launchUrl(
                                                          phoneUri,
                                                          mode: LaunchMode.externalApplication,
                                                        );
                                                      } else {
                                                        if (!context.mounted) return;
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Could not launch phone app')),
                                                        );
                                                      }
                                                    } else {
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Renter phone number not available')),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (!context.mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error: ${e.toString()}')),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerListingFormScreen extends StatefulWidget {
  const OwnerListingFormScreen({super.key});

  @override
  State<OwnerListingFormScreen> createState() => _OwnerListingFormScreenState();
}

class _OwnerListingFormScreenState extends State<OwnerListingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<String> _vehicleTypes = [
    'Tractor',
    'JCB',
    'Crane',
    'Excavator',
    'Loader',
  ];

  String? _selectedVehicleType;
  bool _isPosting = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _hpController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 600,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];
    
    for (final XFile image in _selectedImages) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
        
        final uploadTask = await ref.putFile(File(image.path));
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    
    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFB300);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          color: Colors.black,
          colorBlendMode: BlendMode.dstIn,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner Listing Form',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),

                // Photo upload section
                Text(
                  'Vehicle Photos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                ),
                const SizedBox(height: 8),
                
                // Selected images preview
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Add photos button
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF1F1F1F) : Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Vehicle Photos',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Tap to select multiple images',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Vehicle type dropdown
                Text(
                  'Vehicle Type',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _vehicleTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a vehicle type' : null,
                ),
                const SizedBox(height: 16),

                // Model name
                _buildTextField(
                  label: 'Model Name',
                  controller: _modelController,
                  hint: 'e.g. JCB 3DX, Mahindra 575 DI',
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Year',
                        controller: _yearController,
                        hint: '2024',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Horsepower (HP)',
                        controller: _hpController,
                        hint: '50',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rental price per hour
                Text(
                  'Rental Price per Hour',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    hintText: '1500 / hr',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Location text input
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    hintText: 'Enter city or area',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Upload photos button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_rounded),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryYellow,
                      side: const BorderSide(color: primaryYellow),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo upload coming soon.'),
                        ),
                      );
                    },
                    label: const Text('Upload Photos'),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: const Color(0xFF212121),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isPosting
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      setState(() => _isPosting = true);

                      try {
                        // Upload images first
                        final photoUrls = await _uploadImages();
                        
                        final user = AuthService.instance.currentUser;
                        final doc = <String, dynamic>{
                          'ownerId': user?.uid,
                          'type': _selectedVehicleType,
                          'modelName': _modelController.text.trim(),
                          'year':
                              int.tryParse(_yearController.text.trim()) ?? 0,
                          'horsepower':
                              int.tryParse(_hpController.text.trim()) ?? 0,
                          'pricePerHour':
                              double.tryParse(_priceController.text.trim()) ??
                                  0,
                          'createdAt': FieldValue.serverTimestamp(),
                          'location': _locationController.text.trim(),
                          'photos': photoUrls,
                        };
                        await FirebaseFirestore.instance
                            .collection('vehicles')
                            .add(doc);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Vehicle listing saved to Firestore.'),
                          ),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving listing: $e'),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isPosting = false);
                        }
                      }
                    },
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF212121),
                        ),
                      ),
                    )
                  : const Text(
                      'Post Listing',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}

