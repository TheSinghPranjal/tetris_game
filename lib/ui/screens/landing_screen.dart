import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_provider.dart';
import '../theme/neon.dart';
import '../widgets/control_legend.dart';
import '../widgets/neon_backdrop.dart';
import 'game_screen.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = ref.watch(gameProvider.select((state) => state.highScore));
    return Scaffold(
      body: NeonBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: <Widget>[
                        const Spacer(),
                        Text(
                          'ARCADE',
                          style: rajdhani(
                            14,
                            color: Neon.cyan,
                            letterSpacing: 6,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 10),
                        FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'TETRIS',
                                textAlign: TextAlign.center,
                                style: orbitron(
                                  56,
                                  weight: FontWeight.w900,
                                  letterSpacing: 6,
                                  shadows: titleGlow(),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.18, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          'NEON STACK',
                          style: rajdhani(
                            18,
                            color: Neon.muted,
                            letterSpacing: 4,
                          ),
                        ).animate(delay: 80.ms).fadeIn(duration: 450.ms),
                        const SizedBox(height: 28),
                        _BestScore(score: best)
                            .animate(delay: 140.ms)
                            .fadeIn(duration: 450.ms)
                            .slideY(begin: 0.12, end: 0),
                        const SizedBox(height: 28),
                        _PlayButton(
                              onPressed: () {
                                ref.read(gameProvider.notifier).openGame();
                                Navigator.of(context).push(
                                  PageRouteBuilder<void>(
                                    transitionDuration: const Duration(
                                      milliseconds: 420,
                                    ),
                                    reverseTransitionDuration: const Duration(
                                      milliseconds: 280,
                                    ),
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) {
                                          return const GameScreen();
                                        },
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                            )
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.96, 0.96),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutCubic,
                            ),
                        const Spacer(),
                        const ControlLegend(),
                        const SizedBox(height: 8),
                        Text(
                          'Tap a zone on the well',
                          style: rajdhani(
                            13,
                            color: Neon.muted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BestScore extends StatelessWidget {
  const _BestScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xCC1A0B2E), Color(0xCC0C1C33)],
          ),
          border: Border.all(color: Neon.violet.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            children: <Widget>[
              Text(
                'BEST',
                style: rajdhani(13, color: Neon.cyan, letterSpacing: 3),
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: orbitron(32, color: Neon.amber, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.35 + (_pulse.value * 0.4);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Neon.magenta.withValues(alpha: glow),
                blurRadius: 22 + (_pulse.value * 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('play-button'),
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFFFF2BD6),
                  Color(0xFF7A4DFF),
                  Color(0xFF3DFFF3),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
              child: Text(
                'PLAY',
                style: orbitron(
                  20,
                  color: const Color(0xFF140818),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
