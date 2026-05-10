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