import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/main_navigation_shell.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.email,
  });

  final String phoneNumber;
  final String fullName;
  final String email;

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _chargingPowerController = TextEditingController();
  final List<_VehicleInfo> _vehicles = [];

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _chargingPowerController.dispose();
    super.dispose();
  }

  void _addVehicle() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _vehicles.add(
        _VehicleInfo(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim().toUpperCase(),
          chargingPower: _chargingPowerController.text.trim(),
        ),
      );
      _brandController.clear();
      _modelController.clear();
      _plateController.clear();
      _chargingPowerController.clear();
      _formKey.currentState!.reset();
    });

    FocusScope.of(context).unfocus();
  }

  void _removeVehicle(int index) {
    setState(() {
      _vehicles.removeAt(index);
    });
  }

  bool get _hasVehicleDraft {
    return _brandController.text.trim().isNotEmpty ||
        _modelController.text.trim().isNotEmpty ||
        _plateController.text.trim().isNotEmpty ||
        _chargingPowerController.text.trim().isNotEmpty;
  }

  void _completeSignup() {
    if (_hasVehicleDraft) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      _vehicles.add(
        _VehicleInfo(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim().toUpperCase(),
          chargingPower: _chargingPowerController.text.trim(),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Araç ekleyin veya Skip for Now ile devam edin'),
        ),
      );
      return;
    }

    _finishSignup(skippedVehicleInfo: false);
  }

  void _finishSignup({required bool skippedVehicleInfo}) {
    debugPrint('Signup completed');
    debugPrint('Phone: ${widget.phoneNumber}');
    debugPrint('Full name: ${widget.fullName}');
    debugPrint('Email: ${widget.email}');
    debugPrint('Vehicle info skipped: $skippedVehicleInfo');
    debugPrint('Vehicle count: ${_vehicles.length}');

    for (final (index, vehicle) in _vehicles.indexed) {
      debugPrint(
        'Vehicle ${index + 1}: ${vehicle.brand} ${vehicle.model}, '
        '${vehicle.licensePlate}, ${vehicle.chargingPower} kW',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skippedVehicleInfo
              ? 'Signup completed without vehicle info'
              : 'Signup completed',
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FFFB), Color(0xFFEFF8F8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    48,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SignupLogo(size: 116),
                    const SizedBox(height: 22),
                    Text(
                      'Vehicle Info',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İsterseniz birden fazla araç ekleyin veya bu adımı atlayın.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_vehicles.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      ..._vehicles.indexed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VehicleTile(
                            vehicle: entry.$2,
                            onRemove: () => _removeVehicle(entry.$1),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _brandController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Car Brand',
                        prefixIcon: const Icon(Icons.directions_car_outlined),
                      ),
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return 'Araç markası gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _modelController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Car Model',
                        prefixIcon: const Icon(Icons.ev_station_outlined),
                      ),
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return 'Araç modeli gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'License Plate',
                        prefixIcon: const Icon(Icons.pin_outlined),
                      ),
                      validator: (value) {
                        if ((value?.trim() ?? '').length < 5) {
                          return 'Geçerli bir plaka girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _chargingPowerController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Charging Power (kW)',
                        prefixIcon: const Icon(Icons.bolt_outlined),
                      ),
                      validator: (value) {
                        final power = double.tryParse(value?.trim() ?? '');
                        if (power == null || power <= 0) {
                          return 'Geçerli bir kW değeri girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _addVehicle,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: const Color(0xFF18305F),
                        side: const BorderSide(color: Color(0xFF25B7D3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GradientButton(
                      label: 'Complete Signup',
                      onPressed: _completeSignup,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _finishSignup(
                        skippedVehicleInfo: _vehicles.isEmpty,
                      ),
                      child: Text(
                        _vehicles.isEmpty
                            ? 'Skip for Now'
                            : 'Continue with ${_vehicles.length} Vehicle${_vehicles.length == 1 ? '' : 's'}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleInfo {
  const _VehicleInfo({
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.chargingPower,
  });

  final String brand;
  final String model;
  final String licensePlate;
  final String chargingPower;
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.onRemove});

  final _VehicleInfo vehicle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF39C1D6).withValues(alpha: 0.16),
          foregroundColor: const Color(0xFF18305F),
          child: const Icon(Icons.directions_car_outlined),
        ),
        title: Text(
          '${vehicle.brand} ${vehicle.model}',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${vehicle.licensePlate} · ${vehicle.chargingPower} kW'),
        trailing: IconButton(
          tooltip: 'Remove vehicle',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? prefixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.78),
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.55)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF25B7D3), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
  );
}

class _SignupLogo extends StatelessWidget {
  const _SignupLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF39C1D6), Color(0xFF1E9FBC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E9FBC).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF18305F),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
