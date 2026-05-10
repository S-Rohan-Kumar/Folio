import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/community_providers.dart';
import '../../domain/entities/club.dart';
import '../../../../shared/providers/supabase_provider.dart';

class DiscoverClubsTab extends ConsumerStatefulWidget {
  const DiscoverClubsTab({super.key});

  @override
  ConsumerState<DiscoverClubsTab> createState() => _DiscoverClubsTabState();
}

class _DiscoverClubsTabState extends ConsumerState<DiscoverClubsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showJoinPrivateClubDialog() {
    final codeCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceVariant,
          title: Text("Join Private Club", style: AppTextStyles.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter the 8-character invite code:", style: AppTextStyles.bodyMedium),
              const SizedBox(height: Spacing.md),
              AppTextField(
                label: "Invite Code",
                controller: codeCtrl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
            ),
            AppButton(
              label: "Join",
              compact: true,
              isLoading: isLoading,
              onPressed: () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;

                setState(() => isLoading = true);
                try {
                  // Wait, to join by code we need the clubId. 
                  // In this spec, the prompt says JoinClubUseCase takes code. But we don't know the ID!
                  // Let's modify join logic to look up by code if no ID is passed.
                  // For now, let's use supabase direct to find club ID by code
                  final client = ref.read(supabaseClientProvider);
                  final data = await client.from('clubs').select('id, name').eq('invite_code', code).eq('is_public', false).maybeSingle();
                  
                  if (data == null) {
                    throw Exception("Invalid invite code. Check with the club owner.");
                  }
                  
                  await ref.read(joinClubUseCaseProvider)(data['id'], inviteCode: code);
                  ref.invalidate(myClubsProvider);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined ${data['name']}! 🎉"), backgroundColor: AppColors.success));
                    context.push('/club/${data['id']}');
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(discoverClubsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: "Search clubs",
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _query = val.toLowerCase()),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              OutlinedAppButton(
                label: "Code",
                compact: true,
                onPressed: _showJoinPrivateClubDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: clubsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (clubs) {
              final filtered = clubs.where((c) => c.name.toLowerCase().contains(_query)).toList();
              
              if (filtered.isEmpty) {
                return const Center(child: Text("No public clubs found."));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final club = filtered[index];
                  return _DiscoverClubCard(club: club);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiscoverClubCard extends ConsumerStatefulWidget {
  final Club club;
  const _DiscoverClubCard({required this.club});

  @override
  ConsumerState<_DiscoverClubCard> createState() => _DiscoverClubCardState();
}

class _DiscoverClubCardState extends ConsumerState<_DiscoverClubCard> {
  bool _isJoining = false;
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: RadiusSize.lg),
      child: ListTile(
        contentPadding: const EdgeInsets.all(Spacing.sm),
        leading: ClipRRect(
          borderRadius: RadiusSize.sm,
          child: CachedNetworkImage(
            imageUrl: widget.club.coverUrl ?? '',
            width: 48, height: 48, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: AppColors.amberMuted, width: 48, height: 48, child: const Icon(Icons.groups, color: AppColors.amber)),
          ),
        ),
        title: Text(widget.club.name, style: AppTextStyles.titleLarge),
        subtitle: Text("${widget.club.memberCount} members", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        trailing: _joined
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : OutlinedAppButton(
                label: "Join",
                compact: true,
                onPressed: _isJoining ? null : () async {
                  setState(() => _isJoining = true);
                  try {
                    await ref.read(joinClubUseCaseProvider)(widget.club.id);
                    ref.invalidate(myClubsProvider);
                    ref.invalidate(discoverClubsProvider);
                    
                    if (mounted) {
                      setState(() { _isJoining = false; _joined = true; });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined ${widget.club.name}! 🎉"), backgroundColor: AppColors.success));
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isJoining = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
                    }
                  }
                },
              ),
        onTap: () => context.push('/club/${widget.club.id}', extra: widget.club),
      ),
    );
  }
}