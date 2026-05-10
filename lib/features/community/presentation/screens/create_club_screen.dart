import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../book_search/domain/entities/book.dart';
import '../providers/community_providers.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublic = true;
  Book? _currentBook; // We would use a BookPicker here in a full implementation
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    return List.generate(8, (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[Random().nextInt(36)]).join();
  }

  void _showInviteCodeDialog(String inviteCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text("Your Invite Code", style: AppTextStyles.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share this code with people you want to invite:", style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber),
              ),
              child: Text(
                inviteCode,
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.amber,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton.icon(
              icon: const Icon(Icons.copy, color: AppColors.amber),
              label: const Text("Copy code", style: TextStyle(color: AppColors.amber)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
              },
            ),
          ],
        ),
        actions: [
          AppButton(label: "Done", onPressed: () {
            Navigator.pop(context); // close dialog
            context.pop(); // return to community
          })
        ],
      ),
    );
  }

  Future<void> _createClub() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Club name is required"), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isCreating = true);
    final inviteCode = _isPublic ? null : _generateInviteCode();

    try {
      await ref.read(createClubUseCaseProvider)(CreateClubParams(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        isPublic: _isPublic,
        inviteCode: inviteCode,
        currentBookId: _currentBook?.id,
      ));

      await ref.read(logXpUseCaseProvider)('club_created', 25);
      
      ref.invalidate(myClubsProvider);
      ref.invalidate(discoverClubsProvider);

      if (mounted) {
        if (!_isPublic) {
          _showInviteCodeDialog(inviteCode!);
        } else {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Club created! 🎉"), backgroundColor: AppColors.success));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Create Club"),
        actions: [
          _isCreating 
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.amber)))
            : TextButton(onPressed: _createClub, child: const Text("Create", style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Image picker not fully implemented to keep spec tight, just visual
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cover picker coming soon")));
                  },
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.textHint, size: 32),
                        SizedBox(height: 4),
                        Text("Add cover", style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              
              AppTextField(label: "Club Name *", controller: _nameController, maxLength: 50),
              const SizedBox(height: Spacing.md),
              AppTextField(label: "Description", controller: _descController, maxLines: 3, maxLength: 500, hint: "What's this club about?"),
              const SizedBox(height: Spacing.lg),
              
              Text("Visibility", style: AppTextStyles.titleLarge),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _VisibilityCard(
                      title: "Public", icon: Icons.public, desc: "Anyone can find and join",
                      isSelected: _isPublic,
                      onTap: () => setState(() => _isPublic = true),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _VisibilityCard(
                      title: "Private", icon: Icons.lock, desc: "Join with invite code only",
                      isSelected: !_isPublic,
                      onTap: () => setState(() => _isPublic = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              
              Text("Current Book (optional)", style: AppTextStyles.titleLarge),
              const SizedBox(height: Spacing.sm),
              OutlinedAppButton(
                label: "+ Select a book",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Book picker implementation pending")));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityCard({required this.title, required this.icon, required this.desc, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purpleMuted.withOpacity(0.2) : AppColors.surface,
          borderRadius: RadiusSize.md,
          border: Border.all(color: isSelected ? AppColors.amber : AppColors.elevated),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.amber : AppColors.textHint),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text(desc, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}