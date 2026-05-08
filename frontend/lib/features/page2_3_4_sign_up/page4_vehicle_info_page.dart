import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/main_navigation_shell.dart';
import '../../data/models/vehicle.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/vehicle_service.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String phoneNumber;
  final String fullName;
  final String email;
  final String password;

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _chargingPowerController = TextEditingController();
  final _batteryCapacityController = TextEditingController();
  final List<_VehicleInfo> _vehicles = [];
  final _authService = AuthService();
  final _vehicleService = VehicleService();

  String _connectorType = 'Type 2';
  String _currentType = 'AC';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _chargingPowerController.dispose();
    _batteryCapacityController.dispose();
    super.dispose();
  }

  void _addVehicle() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _vehicles.add(
        _VehicleInfo(
          name: _vehicleNameController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim().toUpperCase(),
          connectorType: _connectorType,
          currentType: _currentType,
          chargingPower: _chargingPowerController.text.trim(),
          batteryCapacity: _batteryCapacityController.text.trim(),
        ),
      );
      _vehicleNameController.clear();
      _modelController.clear();
      _plateController.clear();
      _chargingPowerController.clear();
      _batteryCapacityController.clear();
      _connectorType = 'Type 2';
      _currentType = 'AC';
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
    return _vehicleNameController.text.trim().isNotEmpty ||
        _modelController.text.trim().isNotEmpty ||
        _plateController.text.trim().isNotEmpty ||
        _chargingPowerController.text.trim().isNotEmpty ||
        _batteryCapacityController.text.trim().isNotEmpty;
  }

  void _completeSignup() {
    if (_hasVehicleDraft) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      _vehicles.add(
        _VehicleInfo(
          name: _vehicleNameController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim().toUpperCase(),
          connectorType: _connectorType,
          currentType: _currentType,
          chargingPower: _chargingPowerController.text.trim(),
          batteryCapacity: _batteryCapacityController.text.trim(),
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

  Future<void> _finishSignup({required bool skippedVehicleInfo}) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await _authService.register(
        fullName: widget.fullName,
        mail: widget.email,
        password: widget.password,
      );

      if (!skippedVehicleInfo) {
        for (final vehicle in _vehicles) {
          await _vehicleService.createVehicle(
            VehicleInput(
              userId: user.id,
              model: '${vehicle.name} ${vehicle.model}'.trim(),
              plate: vehicle.licensePlate,
              maxChargingPower: double.parse(vehicle.chargingPower),
              batteryCapacity: double.parse(vehicle.batteryCapacity),
              connectorType: vehicle.connectorType,
              currentType: vehicle.currentType,
            ),
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skippedVehicleInfo
                ? 'Uyelik arac bilgisi olmadan tamamlandi'
                : 'Uyelik ve arac bilgileri kaydedildi',
          ),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                      controller: _vehicleNameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Vehicle Name',
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
                        hintText: 'Vehicle Model',
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
                        hintText: 'Plate Number',
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
                    DropdownButtonFormField<String>(
                      initialValue: _connectorType,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Connector Type',
                        prefixIcon: const Icon(Icons.power),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Type 2',
                          child: Text('Type 2'),
                        ),
                        DropdownMenuItem(value: 'CCS', child: Text('CCS')),
                        DropdownMenuItem(
                          value: 'CHAdeMO',
                          child: Text('CHAdeMO'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _connectorType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _currentType,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Current Type',
                        prefixIcon: const Icon(
                          Icons.electrical_services_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'AC', child: Text('AC')),
                        DropdownMenuItem(value: 'DC', child: Text('DC')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _currentType = value;
                        });
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
                        hintText: 'Max Charging Power (kW)',
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _batteryCapacityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Battery Capacity (kWh)',
                        prefixIcon: const Icon(
                          Icons.battery_charging_full_outlined,
                        ),
                      ),
                      validator: (value) {
                        final capacity = double.tryParse(value?.trim() ?? '');
                        if (capacity == null || capacity <= 0) {
                          return 'Gecerli bir kWh degeri girin';
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
                      onPressed: _isSubmitting ? null : _completeSignup,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          _finishSignup(skippedVehicleInfo: _vehicles.isEmpty),
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
    required this.name,
    required this.model,
    required this.licensePlate,
    required this.connectorType,
    required this.currentType,
    required this.chargingPower,
    required this.batteryCapacity,
  });

  final String name;
  final String model;
  final String licensePlate;
  final String connectorType;
  final String currentType;
  final String chargingPower;
  final String batteryCapacity;
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
          '${vehicle.name} ${vehicle.model}',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${vehicle.licensePlate} - ${vehicle.connectorType} - ${vehicle.currentType} - ${vehicle.chargingPower} kW',
        ),
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
    labelText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.78),
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.55),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF25B7D3), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
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
  final VoidCallback? onPressed;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
