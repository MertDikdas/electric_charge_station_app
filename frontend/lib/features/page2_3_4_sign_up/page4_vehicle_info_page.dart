import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_snackbar.dart';
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
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _connectorController = TextEditingController(text: 'Type 2');
  final _currentTypeController = TextEditingController(text: 'AC');
  final _maxPowerController = TextEditingController();
  final _batteryCapacityController = TextEditingController();
  final List<_VehicleInfo> _vehicles = [];
  final _authService = AuthService();
  final _vehicleService = VehicleService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _connectorController.dispose();
    _currentTypeController.dispose();
    _maxPowerController.dispose();
    _batteryCapacityController.dispose();
    super.dispose();
  }

  void _addVehicle() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _vehicles.add(
        _VehicleInfo(
          name: _nameController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim().toUpperCase(),
          connectorType: _connectorController.text.trim(),
          currentType: _currentTypeController.text.trim(),
          maxChargingPower: _maxPowerController.text.trim(),
          batteryCapacity: _batteryCapacityController.text.trim(),
        ),
      );
      _nameController.clear();
      _modelController.clear();
      _plateController.clear();
      _maxPowerController.clear();
      _batteryCapacityController.clear();
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
    return _nameController.text.trim().isNotEmpty ||
        _modelController.text.trim().isNotEmpty ||
        _plateController.text.trim().isNotEmpty ||
        _maxPowerController.text.trim().isNotEmpty ||
        _batteryCapacityController.text.trim().isNotEmpty;
  }

  void _completeSignup() {
    if (_hasVehicleDraft) {
      if (!_formKey.currentState!.validate()) return;

      _vehicles.add(
        _VehicleInfo(
          name: _nameController.text.trim(),
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim().toUpperCase(),
          connectorType: _connectorController.text.trim(),
          currentType: _currentTypeController.text.trim(),
          maxChargingPower: _maxPowerController.text.trim(),
          batteryCapacity: _batteryCapacityController.text.trim(),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      AppSnackBar.showWarning(context, 'Arac ekleyin veya Skip for Now ile devam edin');
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
              maxChargingPower: double.parse(vehicle.maxChargingPower),
              batteryCapacity: double.parse(vehicle.batteryCapacity),
              connectorType: _normalizeConnectorType(vehicle.connectorType),
              currentType: vehicle.currentType.trim().toUpperCase(),
            ),
          );
        }
      }

      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        skippedVehicleInfo
            ? 'Uyelik arac bilgisi olmadan tamamlandi'
            : 'Uyelik ve arac bilgileri kaydedildi',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.toString());
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Bu alan gerekli';
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) return 'Pozitif sayi girin';
    return null;
  }

  String _normalizeConnectorType(String value) {
    return value.trim().toUpperCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add Vehicle', style: textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Vehicle Name',
                    prefixIcon: const Icon(Icons.directions_car),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Vehicle Model',
                    prefixIcon: const Icon(Icons.ev_station_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Plate Number',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').length < 5) {
                      return 'Gecerli bir plaka girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _connectorController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Connector Type',
                    prefixIcon: const Icon(Icons.power),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentTypeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Current Type',
                    prefixIcon: const Icon(Icons.electrical_services_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxPowerController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    labelText: 'Max Charging Power (kW)',
                    prefixIcon: const Icon(Icons.bolt_outlined),
                  ),
                  validator: _positiveNumber,
                ),
                const SizedBox(height: 12),
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
                    labelText: 'Battery Capacity (kWh)',
                    prefixIcon: const Icon(
                      Icons.battery_charging_full_outlined,
                    ),
                  ),
                  validator: _positiveNumber,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _addVehicle,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('My Vehicles', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_vehicles.isEmpty)
                  const _MessageCard(
                    icon: Icons.directions_car_filled,
                    title: 'No vehicle added yet',
                    subtitle: 'Your vehicles will appear here.',
                  )
                else
                  ..._vehicles.indexed.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VehicleTile(
                        vehicle: entry.$2,
                        onRemove: () => _removeVehicle(entry.$1),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSubmitting ? null : _completeSignup,
                  child: Text(_isSubmitting ? 'Saving...' : 'Complete Signup'),
                ),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _finishSignup(
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
    required this.maxChargingPower,
    required this.batteryCapacity,
  });

  final String name;
  final String model;
  final String licensePlate;
  final String connectorType;
  final String currentType;
  final String maxChargingPower;
  final String batteryCapacity;
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.onRemove});

  final _VehicleInfo vehicle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car_filled),
        title: Text('${vehicle.name} ${vehicle.model}'.trim()),
        subtitle: Text(
          '${vehicle.licensePlate} - ${vehicle.connectorType} - ${vehicle.maxChargingPower} kW',
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String labelText,
  required Widget prefixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: colorScheme.surface,
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.error, width: 1.4),
    ),
  );
}
