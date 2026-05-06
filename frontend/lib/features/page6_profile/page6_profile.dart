import 'package:flutter/material.dart';

import '../../data/api/token_storage.dart';
import '../../data/models/user.dart';
import '../../data/models/vehicle.dart';
import '../../data/services/user_service.dart';
import '../../data/services/vehicle_service.dart';
import '../../widgets/app_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStorage = TokenStorage();
  final _userService = UserService();

  late final Future<AppUser?> _userFuture = _loadUser();

  Future<AppUser?> _loadUser() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) return null;
    return _userService.getUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Profil'),
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Profil Bilgileri', style: textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  _MessageCard(
                    icon: Icons.error_outline,
                    title: 'Profil yuklenemedi',
                    subtitle: snapshot.error.toString(),
                  )
                else if (user == null)
                  const _MessageCard(
                    icon: Icons.info_outline,
                    title: 'Misafir oturum',
                    subtitle: 'Profil bilgileri icin giris yapin.',
                  )
                else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Ad Soyad'),
                      subtitle: Text(
                        user.fullName.isEmpty ? '-' : user.fullName,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('E-posta'),
                      subtitle: Text(user.mail.isEmpty ? '-' : user.mail),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: const Text('Bakiye'),
                      subtitle: Text(user.balance.toStringAsFixed(2)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Vehicle', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car_outlined),
                    title: const Text('Araclarim'),
                    subtitle: const Text('Arac ekle / duzenle'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const VehicleScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _connectorController = TextEditingController(text: 'Type 2');
  final _currentTypeController = TextEditingController(text: 'AC');
  final _maxPowerController = TextEditingController();
  final _batteryCapacityController = TextEditingController();
  final _tokenStorage = TokenStorage();
  final _userService = UserService();
  final _vehicleService = VehicleService();

  late Future<List<Vehicle>> _vehiclesFuture = _loadVehicles();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _connectorController.dispose();
    _currentTypeController.dispose();
    _maxPowerController.dispose();
    _batteryCapacityController.dispose();
    super.dispose();
  }

  Future<List<Vehicle>> _loadVehicles() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) return [];
    return _userService.getUserVehicles(userId);
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) {
      _showMessage('Arac eklemek icin giris yapmalisiniz');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _vehicleService.createVehicle(
        VehicleInput(
          userId: userId,
          model: _nameController.text.trim(),
          plate: _plateController.text.trim().toUpperCase(),
          maxChargingPower: double.parse(_maxPowerController.text.trim()),
          batteryCapacity: double.parse(_batteryCapacityController.text.trim()),
          connectorType: _connectorController.text.trim(),
          currentType: _currentTypeController.text.trim(),
        ),
      );

      _nameController.clear();
      _plateController.clear();
      _maxPowerController.clear();
      _batteryCapacityController.clear();
      if (!mounted) return;
      setState(() {
        _vehiclesFuture = _loadVehicles();
      });
      _showMessage('Arac eklendi');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    try {
      await _vehicleService.deleteVehicle(vehicleId);
      if (!mounted) return;
      setState(() {
        _vehiclesFuture = _loadVehicles();
      });
      _showMessage('Arac silindi');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Vehicle'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add Vehicle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Name',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Plate Number',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _connectorController,
                    decoration: const InputDecoration(
                      labelText: 'Connector Type',
                      prefixIcon: Icon(Icons.power),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Current Type',
                      prefixIcon: Icon(Icons.electrical_services_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxPowerController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max Charging Power (kW)',
                      prefixIcon: Icon(Icons.bolt_outlined),
                    ),
                    validator: _positiveNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _batteryCapacityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Battery Capacity (kWh)',
                      prefixIcon: Icon(Icons.battery_charging_full_outlined),
                    ),
                    validator: _positiveNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _addVehicle,
              icon: const Icon(Icons.add),
              label: Text(_isSaving ? 'Saving...' : 'Add Vehicle'),
            ),
            const SizedBox(height: 24),
            Text('My Vehicles', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<Vehicle>>(
              future: _vehiclesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageCard(
                    icon: Icons.error_outline,
                    title: 'Araclar yuklenemedi',
                    subtitle: snapshot.error.toString(),
                  );
                }

                final vehicles = snapshot.data ?? [];
                if (vehicles.isEmpty) {
                  return const _MessageCard(
                    icon: Icons.directions_car_filled,
                    title: 'No vehicle added yet',
                    subtitle: 'Your vehicles will appear here.',
                  );
                }

                return Column(
                  children: vehicles
                      .map(
                        (vehicle) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.directions_car_filled),
                            title: Text(vehicle.model),
                            subtitle: Text(
                              '${vehicle.plate} - ${vehicle.connectorType} - ${vehicle.maxChargingPower} kW',
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteVehicle(vehicle.id),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
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
