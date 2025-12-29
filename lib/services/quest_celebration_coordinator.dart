import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For UserProvider access
import '../models/quest.dart';
import 'quest_service.dart';
import 'user_provider.dart'; // For reloading balance

typedef OpenQuestWindow = void Function();
typedef AnimateCurrency = void Function(int delta);

class QuestCelebrationCoordinator {
  static final QuestCelebrationCoordinator instance = QuestCelebrationCoordinator._internal();
  QuestCelebrationCoordinator._internal() {
    QuestService.instance.completions.listen(_onQuestCompleted);
  }

  bool _homeActive = false;
  BuildContext? _homeContext;
  GlobalKey? _rocketIconKey;
  OpenQuestWindow? _openQuestWindow;
  AnimateCurrency? _animateCurrency;
  VoidCallback? _bounceTargetIcon;
  final Queue<Quest> _queue = Queue<Quest>();
  final Map<String, GlobalKey> _questRocketKeys = {};

  void registerHome(BuildContext context, GlobalKey rocketIconKey, OpenQuestWindow openQuestWindow, AnimateCurrency animateCurrency, VoidCallback bounceTargetIcon) {
    _homeActive = true;
    _homeContext = context;
    _rocketIconKey = rocketIconKey;
    _openQuestWindow = openQuestWindow;
    _animateCurrency = animateCurrency;
    _bounceTargetIcon = bounceTargetIcon;
    _drainQueue();
  }

  void unregisterHome() {
    _homeActive = false;
    _homeContext = null;
    _rocketIconKey = null;
    _openQuestWindow = null;
    _animateCurrency = null;
    _bounceTargetIcon = null;
  }

  void registerQuestRocketKey(String questId, GlobalKey key) {
    _questRocketKeys[questId] = key;
  }

  void _onQuestCompleted(Quest quest) {
    if (_homeActive) {
      // Only open quest window to prompt manual claim
      if (_openQuestWindow != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openQuestWindow?.call();
        });
      }
    } else {
      _queue.add(quest);
    }
  }

  void _drainQueue() {
    while (_queue.isNotEmpty) {
      final q = _queue.removeFirst();
      _triggerFlow(q);
    }
  }

  void _triggerFlow(Quest quest) {
    if (_openQuestWindow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openQuestWindow?.call();
      });
    }
  }

  void _spawnParticles(Quest quest, GlobalKey startKey, {VoidCallback? onArriveAll}) {
    if (_homeContext == null || _rocketIconKey == null) return;
    final overlay = Overlay.of(_homeContext!);
    if (!overlay.mounted) return;

    final startBox = startKey.currentContext?.findRenderObject() as RenderBox?;
    final endBox = _rocketIconKey!.currentContext?.findRenderObject() as RenderBox?;
    if (startBox == null || endBox == null) return;

    final start = startBox.localToGlobal(Offset(startBox.size.width / 2, startBox.size.height / 2));
    final end = endBox.localToGlobal(Offset(endBox.size.width / 2, endBox.size.height / 2));

    const int maxParticles = 20;
    final count = min(20, maxParticles);
    bool finalHandled = false;
    for (int i = 0; i < count; i++) {
      final delayMs = 40 * i;
      late OverlayEntry entry;
      bool removed = false;
      entry = OverlayEntry(
        builder: (context) {
          return _ParticleFlight(
            start: start,
            end: end,
            delay: Duration(milliseconds: delayMs),
            onArrive: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _bounceTargetIcon?.call();
                if (i == count - 1 && !finalHandled) {
                  finalHandled = true;
                  _animateCurrency?.call(quest.reward);
                  onArriveAll?.call();
                }
              });
            },
            onRemove: () {
              if (!removed) {
                removed = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  entry.remove();
                });
              }
            },
          );
        },
      );
      overlay.insert(entry);
    }
  }

  /// Public API: trigger claim animation and finalize quest
  /// Requires the specific GlobalKey of the claim button/icon clicked
  void claimQuest(Quest quest, GlobalKey buttonKey) {
    _spawnParticles(quest, buttonKey, onArriveAll: () {
      QuestService.instance.claimById(quest.id);
      
      // 🔄 CRITICAL FIX: Reload balance from CurrencyService to update UI
      // This fixes the bug where rewards don't appear in the UI immediately
      // The delay ensures CurrencyService has finished updating
      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          // Get UserProvider from context (if available)
          if (_homeContext != null && _homeContext!.mounted) {
            final userProvider = Provider.of<UserProvider>(_homeContext!, listen: false);
            await userProvider.reloadBalance();
            debugPrint('✅ Balance reloaded in UI after quest claim');
          }
        } catch (e) {
          debugPrint('⚠️ Could not reload balance: $e');
        }
      });
    });
  }
}

class _ParticleFlight extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Duration delay;
  final VoidCallback? onArrive;
  final VoidCallback? onRemove;
  const _ParticleFlight({required this.start, required this.end, required this.delay, this.onArrive, this.onRemove});
  @override
  State<_ParticleFlight> createState() => _ParticleFlightState();
}

class _ParticleFlightState extends State<_ParticleFlight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  late final Offset _controlPoint;
  late final double _rotSpeed;
  late final double _baseRot;
  final Random _rng = Random();
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    // Quadratic bezier control point with jitter and upward arc
    final midX = (widget.start.dx + widget.end.dx) / 2;
    final midY = (widget.start.dy + widget.end.dy) / 2;
    final jitterX = (_rng.nextDouble() - 0.5) * 80.0;
    final arcY = -120.0 + (_rng.nextDouble() - 0.5) * 60.0;
    _controlPoint = Offset(midX + jitterX, midY + arcY);
    // Rotation parameters for confetti-like tumble
    _rotSpeed = (_rng.nextDouble() * 2 - 1) * 3.0; // radians per progress unit
    _baseRot = (_rng.nextDouble() * (pi / 2));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onArrive != null) {
        widget.onArrive!();
        // Stability-first: remove immediately after arrival to avoid lifecycle races
        widget.onRemove?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final p = _t.value;
        final q = 1 - p;
        // Quadratic Bezier: B(t) = (1-t)^2*P0 + 2(1-t)t*C + t^2*P1
        final bx = (q * q * widget.start.dx) + (2 * q * p * _controlPoint.dx) + (p * p * widget.end.dx);
        final by = (q * q * widget.start.dy) + (2 * q * p * _controlPoint.dy) + (p * p * widget.end.dy);
        final s = 1.0 - (0.5 * p); // Scale down slightly as it flies
        final a = 1.0;
        final rot = _baseRot + _rotSpeed * p * 2 * pi;
        return Positioned(
          left: bx,
          top: by,
          child: IgnorePointer(
            child: Opacity(
              opacity: a,
              child: Transform.rotate(
                angle: rot,
                child: Transform.scale(
                  scale: s,
                  child: Image.asset(
                    'assets/images/currency_rocket1.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
