import 'package:flutter/material.dart';

import 'Shared/md3_ui.dart';

class EmptyMoviesCard extends StatelessWidget {
  final String title;
  final String body;
  final String actionText;
  final IconData icon;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const EmptyMoviesCard({
    super.key,
    required this.title,
    required this.body,
    required this.actionText,
    required this.icon,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Md3Card(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Md3Colors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Md3Colors.primary, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 22,
                  height: 1.23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 1.44,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Md3PrimaryButton(
                text: actionText,
                icon: actionIcon,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
