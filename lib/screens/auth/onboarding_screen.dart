import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart' show onboardingCompleteProvider;
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';

/// Shown once per account, immediately after email verification passes
/// (or right after a first-time Google / GitHub sign-in).
///
/// Collects the five gym-specific fields that no OAuth provider supplies:
/// gender, date of birth, weight, height, and fitness goal.
///
/// On completion it writes a User profile document to Firestore, keyed by
/// UID. AuthGate's onboardingCompleteProvider checks whether that document
/// exists to decide whether to show this screen again - since it lives in
/// Firestore rather than on-device storage, it survives reinstalls, app
/// data clears, and signing in on a different device.

class OnboardingScreen extends ConsumerStatefulWidget {
  /// Firebase UID of the currently signed-in user. Doubles as the User
  /// profile document's ID in Firestore when the form is submitted.
  final String uid;

  const OnboardingScreen({super.key, required this.uid});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // ── 1. Gender ────────────────────────────────────────────────────────
  String? _gender; // 'Male' or 'Female'

  // ── 2. Date of birth ─────────────────────────────────────────────────
  DateTime? _dob;
  final _dobController = TextEditingController();

  // ── 3 & 4. Weight / Height ───────────────────────────────────────────
  final _weightController = TextEditingController(text: '60');
  final _heightController = TextEditingController(text: '175');

  // ── 5. Fitness goal ──────────────────────────────────────────────────
  String? _goal; // 'Hypertrophy', 'Strength', 'Endurance'

  bool _isSaving = false;

  @override
  void dispose() {
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Helpers

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // Default to a sensible starting year for a gym app
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1940),
      // Must be at least 13 years old
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        // Wrap in Theme to keep the date picker consistent with the dark UI
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')} / '
            '${picked.month.toString().padLeft(2, '0')} / '
            '${picked.year}';
      });
    }
  }

  bool get _isFormValid =>
      _gender != null &&
      _dob != null &&
      _weightController.text.trim().isNotEmpty &&
      _heightController.text.trim().isNotEmpty &&
      _goal != null;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _submit() async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields before continuing.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authUser = FirebaseAuth.instance.currentUser!;
      final profile = UserProfile(
        userId: widget.uid,
        displayName: authUser.displayName,
        dateOfBirth: _dob!,
        gender: _gender!,
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        goal: _goal!,
        accountCreated: DateTime.now(),
      );
      await UserProfileService().saveProfile(profile);

      // Tell Riverpod the cached "does this UID have a profile?" answer is
      // stale. onboardingCompleteProvider is a FutureProvider.family keyed
      // by UID - invalidating it forces a fresh Firestore read, which now
      // returns true → AuthGate rebuilds → RootScreen is shown.
      // No Navigator.push needed: AuthGate handles routing for us.
      ref.invalidate(onboardingCompleteProvider(widget.uid));
    } catch (_) {
      if (mounted) {
        _showError('Could not save your profile. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ────────────────────────────────────────────────
              Center(
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // ── 1. Gender ───────────────────────────────────────────
              _SectionLabel(number: 1, text: 'Gender'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      label: 'Male',
                      icon: Icons.male,
                      selected: _gender == 'Male',
                      onTap: () => setState(() => _gender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderCard(
                      label: 'Female',
                      icon: Icons.female,
                      selected: _gender == 'Female',
                      onTap: () => setState(() => _gender = 'Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 2. Date of birth ────────────────────────────────────
              _SectionLabel(number: 2, text: 'Date of Birth'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dobController.text.isEmpty
                            ? 'DD / MM / YYYY'
                            : _dobController.text,
                        style: TextStyle(
                          color: _dobController.text.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 3 & 4. Weight / Height (side by side) ───────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(number: 3, text: 'Weight'),
                        const SizedBox(height: 12),
                        _UnitField(controller: _weightController, unit: 'kg'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(number: 4, text: 'Height'),
                        const SizedBox(height: 12),
                        _UnitField(controller: _heightController, unit: 'cm'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 5. Fitness goal ─────────────────────────────────────
              _SectionLabel(number: 5, text: 'Fitness Goal'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _GoalChip(
                    label: 'Hypertrophy',
                    selected: _goal == 'Hypertrophy',
                    onTap: () => setState(() => _goal = 'Hypertrophy'),
                  ),
                  const SizedBox(width: 8),
                  _GoalChip(
                    label: 'Strength',
                    selected: _goal == 'Strength',
                    onTap: () => setState(() => _goal = 'Strength'),
                  ),
                  const SizedBox(width: 8),
                  _GoalChip(
                    label: 'Endurance',
                    selected: _goal == 'Endurance',
                    onTap: () => setState(() => _goal = 'Endurance'),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── CTA button ──────────────────────────────────────────
              PrimaryButton(
                label: _isSaving ? "Let's Go!" : "Let's Go!",
                onPressed: _isSaving ? null : _submit,
              ),
              const SizedBox(height: 16),

              // ── Privacy note ────────────────────────────────────────
              Center(
                child: Text(
                  'Your information is secure and will\nnever be shared.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered section header, e.g. "1. Gender"
class _SectionLabel extends StatelessWidget {
  final int number;
  final String text;
  const _SectionLabel({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$number. $text',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Tappable gender card (Male / Female) with icon + label.
/// Highlights with a primary-colour border when selected.
class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Number input with a fixed unit suffix (e.g. "60 kg").
class _UnitField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;

  const _UnitField({required this.controller, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped goal selection chip.
class _GoalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
