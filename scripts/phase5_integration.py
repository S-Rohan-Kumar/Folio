import os

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ==========================================
# 1. BOOK COMMUNITY TAB
# ==========================================

w('lib/features/community/presentation/widgets/book_community_tab.dart', r"""
import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import 'threads_list.dart';
import 'create_thread_sheet.dart';

class BookCommunityTab extends StatelessWidget {
  final String bookId;

  const BookCommunityTab({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Text("Discussions", style: AppTextStyles.headlineMedium),
                const Spacer(),
                OutlinedAppButton(
                  label: "New",
                  compact: true,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CreateThreadSheet(bookId: bookId),
                    );
                  },
                ),
              ],
            ),
          ),
          ThreadsList(bookId: bookId),
          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }
}
""".strip())

print("Phase 5 integration scripts generated")
