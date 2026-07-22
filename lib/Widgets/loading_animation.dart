import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Md3Colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Image(
                        image: AssetImage('Assets/mdIcon_V_with_effect.png'),
                        width: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'One moment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MovieDiary is finishing your request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Md3Colors.surfaceMuted,
                      color: Md3Colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
