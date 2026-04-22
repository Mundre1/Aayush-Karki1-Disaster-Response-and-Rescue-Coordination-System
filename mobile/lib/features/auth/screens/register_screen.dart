import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRoleName; // 'citizen', 'volunteer', 'responder'
  String _organizationChoice = 'existing';
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _organizationContactController =
      TextEditingController();
  final TextEditingController _organizationSpecializationController =
      TextEditingController();
  List<Map<String, dynamic>> _availableOrganizations = [];
  int? _selectedOrganizationId;
  bool _isLoadingOrganizations = false;

  Future<void> _loadOrganizations() async {
    setState(() => _isLoadingOrganizations = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final organizations = await authProvider.getAvailableOrganizations();
    if (!mounted) return;
    setState(() {
      _availableOrganizations = organizations;
      _isLoadingOrganizations = false;
      if (_availableOrganizations.isNotEmpty && _selectedOrganizationId == null) {
        _selectedOrganizationId =
            _availableOrganizations.first['organizationId'] as int?;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _organizationNameController.dispose();
    _organizationContactController.dispose();
    _organizationSpecializationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrganizations());
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // Unfocus all text fields
      _nameFocusNode.unfocus();
      _emailFocusNode.unfocus();
      _passwordFocusNode.unfocus();
      _confirmPasswordFocusNode.unfocus();
      _phoneFocusNode.unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        roleName: _selectedRoleName!,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        organizationChoice: _selectedRoleName == 'responder'
            ? _organizationChoice
            : null,
        organizationId: _selectedRoleName == 'responder' &&
                _organizationChoice == 'existing'
            ? _selectedOrganizationId
            : null,
        organizationName: _selectedRoleName == 'responder' &&
                _organizationChoice == 'new'
            ? _organizationNameController.text.trim()
            : null,
        organizationContact: _selectedRoleName == 'responder' &&
                _organizationChoice == 'new'
            ? _organizationContactController.text.trim()
            : null,
        organizationSpecialization: _selectedRoleName == 'responder' &&
                _organizationChoice == 'new'
            ? _organizationSpecializationController.text.trim()
            : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedRoleName == 'responder'
                        ? 'Request submitted. Wait for admin approval before login.'
                        : 'Registration successful! Please login.',
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: PremiumAppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ?? 'Registration failed',
                    style: PremiumAppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: PremiumAppTheme.emergency,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return true; // Optional field
    return RegExp(
      r'^[+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$',
    ).hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: PremiumAppTheme.textPrimary,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Create Account',
                      style: PremiumAppTheme.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: PremiumAppTheme.bodyLarge.copyWith(
                        color: PremiumAppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!_isValidEmail(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // User Type Selection Dropdown (roleName ensures correct role regardless of DB roleId)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRoleName,
                      decoration: const InputDecoration(
                        labelText: 'User Type *',
                        hintText: 'Select your user type',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'citizen',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.indigo,
                              ),
                              SizedBox(width: 12),
                              Text('Citizen'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'volunteer',
                          child: Row(
                            children: [
                              Icon(
                                Icons.handshake,
                                size: 20,
                                color: Colors.green,
                              ),
                              SizedBox(width: 12),
                              Text('Volunteer'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'responder',
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 12),
                              Text('Responder'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRoleName = value;
                          if (value != 'responder') {
                            _organizationChoice = 'existing';
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a user type';
                        }
                        return null;
                      },
                    ),
                    if (_selectedRoleName == 'responder') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'existing',
                              groupValue: _organizationChoice,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Join existing'),
                              onChanged: (value) => setState(
                                () => _organizationChoice = value!,
                              ),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'new',
                              groupValue: _organizationChoice,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Create new'),
                              onChanged: (value) => setState(
                                () => _organizationChoice = value!,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_organizationChoice == 'existing') ...[
                        if (_isLoadingOrganizations)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          ),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedOrganizationId,
                          decoration: const InputDecoration(
                            labelText: 'Available Organization',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                          items: _availableOrganizations
                              .map(
                                (org) => DropdownMenuItem<int>(
                                  value: org['organizationId'] as int?,
                                  child: Text(
                                    org['organizationName']?.toString() ??
                                        'Organization',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedOrganizationId = value),
                          validator: (value) {
                            if (_selectedRoleName == 'responder' &&
                                _organizationChoice == 'existing' &&
                                value == null) {
                              return 'Please select organization';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _organizationNameController,
                          decoration: const InputDecoration(
                            labelText: 'New Organization Name',
                            prefixIcon: Icon(Icons.domain_add_rounded),
                          ),
                          validator: (value) {
                            if (_selectedRoleName == 'responder' &&
                                _organizationChoice == 'new' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Organization name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _organizationContactController,
                          decoration: const InputDecoration(
                            labelText: 'Organization Contact (optional)',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _organizationSpecializationController,
                          decoration: const InputDecoration(
                            labelText: 'Specialization (optional)',
                            prefixIcon: Icon(Icons.groups_2_rounded),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(
                          context,
                        ).requestFocus(_confirmPasswordFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_phoneFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Phone Field (Optional)
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!_isValidPhone(value.trim())) {
                            return 'Please enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Register Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumAppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: PremiumAppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: PremiumAppTheme.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: PremiumAppTheme.bodySmall.copyWith(
                              color: PremiumAppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: PremiumAppTheme.border)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: PremiumAppTheme.bodyMedium.copyWith(
                            color: PremiumAppTheme.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Sign In',
                            style: PremiumAppTheme.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: PremiumAppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
