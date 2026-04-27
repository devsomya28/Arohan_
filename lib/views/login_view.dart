import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'guest_home_view.dart';
import 'staff_home_view.dart';
import 'analytics_view.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginUsernameCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _signupUsernameCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  String _selectedRole = 'staff';
  bool _isLoading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final token = await _api.getToken();
    final role = await _api.getRole();
    if (token != null && mounted) {
      _navigateByRole(role ?? 'guest');
    }
  }

  void _navigateByRole(String role) {
    Widget dest;
    switch (role) {
      case 'admin':
      case 'staff':
      case 'emergency':
        dest = StaffHomeView();
        break;
      default:
        dest = GuestHomeView();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }

  Future<void> _doLogin() async {
    if (_loginUsernameCtrl.text.trim().isEmpty || _loginPasswordCtrl.text.isEmpty) {
      _showError("Please enter username and password");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await _api.login(
        _loginUsernameCtrl.text.trim(),
        _loginPasswordCtrl.text,
      );
      _navigateByRole(data['role'] ?? 'staff');
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doSignup() async {
    if (_signupUsernameCtrl.text.trim().isEmpty || _signupPasswordCtrl.text.isEmpty) {
      _showError("Please enter username and password");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _api.signup(
        _signupUsernameCtrl.text.trim(),
        _signupPasswordCtrl.text,
        role: _selectedRole,
      );
      // Auto login right after signup
      final data = await _api.login(
        _signupUsernameCtrl.text.trim(),
        _signupPasswordCtrl.text,
      );
      _navigateByRole(data['role'] ?? _selectedRole);
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
    );
  }

  // Guest bypass — no auth needed
  void _continueAsGuest() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GuestHomeView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.diamond_outlined, size: 64, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 20),
              const Text("AAROHAN AI",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 8),
              const Text("AOCC ORCHESTRATION ENGINE",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              const Text("Authentication Portal",
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 40),

              // Form Container
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151A27),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1220),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          unselectedLabelColor: Colors.white54,
                          tabs: const [Tab(text: "Login"), Tab(text: "Sign Up")],
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildLoginForm(), _buildSignupForm()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _inputField("Email Address", _loginUsernameCtrl, false, Icons.lock_outline),
        const SizedBox(height: 20),
        _inputField("Password", _loginPasswordCtrl, true, Icons.lock_outline),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isLoading ? null : _doLogin,
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("SECURE PORTAL ACCESS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {},
          child: const Text("Forgot Password?", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        _inputField("Email Address", _signupUsernameCtrl, false, Icons.lock_outline),
        const SizedBox(height: 16),
        _inputField("Password", _signupPasswordCtrl, true, Icons.lock_outline),
        const SizedBox(height: 16),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF0B1220),
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
              items: const [
                DropdownMenuItem(value: 'guest', child: Text("Guest")),
                DropdownMenuItem(value: 'staff', child: Text("Staff")),
                DropdownMenuItem(value: 'emergency', child: Text("Emergency Dept.")),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isLoading ? null : _doSignup,
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, bool isPassword, IconData icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupUsernameCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }
}
