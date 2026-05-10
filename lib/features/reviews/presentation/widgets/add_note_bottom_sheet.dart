import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/note.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../providers/review_provider.dart';

class AddNoteBottomSheet extends ConsumerStatefulWidget {
  final String bookId;

  const AddNoteBottomSheet({super.key, required this.bookId});

  @override
  ConsumerState<AddNoteBottomSheet> createState() => _AddNoteBottomSheetState();
}

class _AddNoteBottomSheetState extends ConsumerState<AddNoteBottomSheet> {
  final _contentCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  NoteType _type = NoteType.note;
  bool _isPublic = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter some text')));
      return;
    }

    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider)!;
    
    final note = Note(
      id: '', 
      userId: user.id,
      bookId: widget.bookId,
      content: _contentCtrl.text.trim(),
      pageNumber: int.tryParse(_pageCtrl.text),
      type: _type,
      isPublic: _isPublic,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(reviewRepositoryProvider).saveNote(note);
      
      ref.invalidate(bookNotesProvider(widget.bookId));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.elevated, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text('Add Entry', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
            
            Wrap(
              spacing: Spacing.sm,
              children: NoteType.values.map((t) {
                final isSelected = _type == t;
                return ChoiceChip(
                  label: Text(t.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.amber,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(color: isSelected ? AppColors.background : AppColors.amber),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: Spacing.md),

            AppTextField(
              label: 'Page number (optional)',
              controller: _pageCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Spacing.sm),
            
            AppTextField(
              label: 'Your text...',
              controller: _contentCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: Spacing.sm),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Make public', style: TextStyle(color: AppColors.textPrimary)),
              value: _isPublic,
              activeColor: AppColors.amber,
              onChanged: (val) => setState(() => _isPublic = val),
            ),
            
            const SizedBox(height: Spacing.md),
            AppButton(
              label: 'Save',
              isLoading: _isSaving,
              onPressed: _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}