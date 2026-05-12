import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_snackbar.dart';
import '../../data/models/charging_session.dart';
import '../../data/services/charging_session_service.dart';

class ChargingVerificationScreen extends StatefulWidget {
  ChargingVerificationScreen({
    super.key,
    ChargingSessionService? chargingSessionService,
  }) : _chargingSessionService =
           chargingSessionService ?? ChargingSessionService();
  final ChargingSessionService _chargingSessionService;

  @override
  State<ChargingVerificationScreen> createState() =>
      _ChargingVerificationScreenState();
}

class _ChargingVerificationScreenState
    extends State<ChargingVerificationScreen> {
  static const int _pinLength = 6;
  static const Duration _transitionDuration = Duration(milliseconds: 260);

  final List<TextEditingController> _controllers = List.generate(
    _pinLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _pinLength,
    (_) => FocusNode(),
  );

  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _pinValue {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isComplete => _pinValue.length == _pinLength;

  Future<void> _submit() async {
    if (_isSubmitting || !_isComplete) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final session = ChargingSession(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        reservationId: 0,
        startTime: DateTime.now().toString(),
        endTime: '',
        consumedEnergy: 0,
        totalCost: 0,
        status: 'STARTED',
      );

      if (!mounted) return;

      Navigator.of(context).pop(session);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    AppSnackBar.showError(context, message);
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final trimmed = value.substring(value.length - 1);
      _controllers[index].text = trimmed;
      _controllers[index].selection = TextSelection.collapsed(
        offset: trimmed.length,
      );
    }

    if (value.isNotEmpty && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].selection = TextSelection.collapsed(
        offset: _controllers[index - 1].text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: AnimatedPadding(
            duration: _transitionDuration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/logo.png',
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  'ENTER CODE TO START',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please enter the 6-digit code found on the charger to begin the charging session.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _PinRow(
                  controllers: _controllers,
                  focusNodes: _focusNodes,
                  onChanged: _onChanged,
                  onKeyEvent: _onKeyEvent,
                ),
                const Spacer(),
                _ConfirmButton(
                  enabled: _isComplete && !_isSubmitting,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final void Function(int index, KeyEvent event) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        controllers.length,
        (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _PinBox(
              controller: controllers[index],
              focusNode: focusNodes[index],
              primaryColor: colorScheme.primary,
              onChanged: (value) => onChanged(index, value),
              onKeyEvent: (event) => onKeyEvent(index, event),
            ),
          );
        },
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.primaryColor,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color primaryColor;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  focusNode.hasFocus
                      ? primaryColor
                      : colorScheme.outlineVariant,
              width: focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Focus(
            onKeyEvent: (_, event) {
              onKeyEvent(event);
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF0B1F4D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('CONFIRM'),
      ),
    );
  }
}

class ChargingVerificationRoute extends PageRouteBuilder<ChargingSession> {
  ChargingVerificationRoute()
    : super(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChargingVerificationScreen();
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}
