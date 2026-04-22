import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../auth_provider.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? initialUser;

  const EditProfileScreen({super.key, this.initialUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getInitial() {
    final n = _nameController.text.trim().isEmpty
        ? widget.initialUser?.name
        : _nameController.text.trim();
    if (n == null || n.isEmpty) return '?';
    return n.substring(0, 1).toUpperCase();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: PremiumAppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to update profile',
            style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final user = widget.initialUser;

    return Scaffold(
      backgroundColor: PremiumAppTheme.background,
      appBar: const PremiumAppBar(title: 'Edit Profile'),
      body: user == null
          ? Center(
              child: Text(
                'No user data',
                style: PremiumAppTheme.bodyLarge.copyWith(
                  color: PremiumAppTheme.textSecondary,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PremiumWidgets.premiumCard(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: PremiumAppTheme.primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              _getInitial(),
                              style: PremiumAppTheme.headlineMedium.copyWith(
                                color: PremiumAppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone (Optional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                              hintText: 'e.g. +977-9841000000',
                            ),
                            keyboardType: TextInputType.phone,
                            autocorrect: false,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: user.email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            enabled: false,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email cannot be changed for security reasons.',
                            style: PremiumAppTheme.bodySmall.copyWith(
                              color: PremiumAppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return PremiumWidgets.premiumButton(
                          text: 'Save Changes',
                          onPressed: _handleSave,
                          isLoading: authProvider.isLoading,
                          icon: Icons.save,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

