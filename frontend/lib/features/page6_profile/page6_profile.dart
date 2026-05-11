import 'package:flutter/material.dart';

import '../../data/api/token_storage.dart';
import '../../data/models/user.dart';
import '../../data/models/vehicle.dart';
import '../../data/services/user_service.dart';
import '../../data/services/vehicle_service.dart';
import '../../widgets/app_app_bar.dart';
import '../../data/models/payment.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/coupon_service.dart';
import '../../data/models/coupon.dart';
import 'chatbot_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStorage = TokenStorage();
  final _userService = UserService();

  late Future<AppUser?> _userFuture = _loadUser();

  Future<AppUser?> _loadUser() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId == 0) return null;
    return _userService.getUser(userId);
  }

  Future<void> _logout() async {
    await _tokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
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
                      title: const Text('E-Mail'),
                      subtitle: Text(user.mail.isEmpty ? '-' : user.mail),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: const Text('Balance'),
                      subtitle: Text(user.balance.toStringAsFixed(2)),
                      trailing: const Icon(Icons.add),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AddBalanceScreen(),
                          ),
                        );

                        if (!mounted) return;

                        setState(() {
                          _userFuture = _loadUser();
                        });
                      },
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
                const SizedBox(height: 24),
                Text('Payments', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.payment_outlined),
                    title: const Text('My payments'),
                    subtitle: const Text(
                      'Transaction History / Wallet Transactions',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PaymentsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text('Support', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Customer Support'),
                    subtitle: const Text('Chat with EV Assistant'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (_) => const ChatbotSheet(),
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

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _paymentService = PaymentService();
  final _couponService = CouponService();
  final Map<int, CouponApplyResult> _appliedCoupons = {};
  late Future<List<Payment>> _paymentsFuture = _loadPayments();
  bool _isProcessing = false;

  Future<List<Payment>> _loadPayments() async {
    final payments = await _paymentService.getMyPayments();

    final appliedCoupons = <int, CouponApplyResult>{};

    for (final payment in payments) {
      if (payment.couponId == null) continue;

      try {
        final coupon = await _couponService.getCoupon(payment.couponId!);

        final preview = await _couponService.previewCoupon(
          paymentId: payment.id,
          code: coupon.code,
          orderAmount: payment.amount,
        );

        appliedCoupons[payment.id] = preview;
      } catch (_) {
        // Kupon silindiyse veya preview hata verirse ödeme yine normal gösterilsin.
      }
    }

    if (mounted) {
      setState(() {
        _appliedCoupons
          ..clear()
          ..addAll(appliedCoupons);
      });
    }

    return payments;
  }

  Future<void> _completePayment(int paymentId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _paymentService.completePayment(paymentId);

      if (!mounted) return;

      setState(() {
        _paymentsFuture = _loadPayments();
      });

      _showMessage('Payment Completed');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _removeCoupon(Payment payment) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _paymentService.removeCoupon(payment.id);

      if (!mounted) return;

      setState(() {
        _appliedCoupons.remove(payment.id);
        _paymentsFuture = _loadPayments();
      });

      _showMessage('Kupon kaldırıldı');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showCouponDialog(Payment payment) async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _CouponCodeDialog(),
    );

    if (code == null || code.isEmpty) return;

    await _previewAndApplyCoupon(payment: payment, code: code);
  }

  Future<void> _previewAndApplyCoupon({
    required Payment payment,
    required String code,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final preview = await _couponService.previewCoupon(
        paymentId: payment.id,
        code: code,
        orderAmount: payment.amount,
      );

      if (!mounted) return;

      final shouldApply = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Kupon Önizleme'),
            content: Text(
              'Kupon kodu: $code\n'
              'İlk tutar: ${payment.amount.toStringAsFixed(2)} TL\n'
              'İndirim: ${preview.discountAmount.toStringAsFixed(2)} TL\n'
              'Yeni tutar: ${preview.finalAmount.toStringAsFixed(2)} TL',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Uygula'),
              ),
            ],
          );
        },
      );

      if (shouldApply != true) return;

      final appliedCoupon = await _couponService.applyCoupon(
        paymentId: payment.id,
        code: code,
        orderAmount: payment.amount,
      );

      if (!mounted) return;

      setState(() {
        _appliedCoupons[payment.id] = appliedCoupon;
        _paymentsFuture = _loadPayments();
      });

      _showMessage('Kupon uygulandı');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canPay(Payment payment) {
    return payment.status.toUpperCase() == 'PENDING';
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Payments'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _paymentsFuture = _loadPayments();
            });
            await _paymentsFuture;
          },
          child: FutureBuilder<List<Payment>>(
            future: _paymentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _MessageCard(
                      icon: Icons.error_outline,
                      title: 'Payments can\'t loaded!',
                      subtitle: snapshot.error.toString(),
                    ),
                  ],
                );
              }

              final payments = snapshot.data ?? [];

              if (payments.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _MessageCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'There aren\'t any payments.',
                      subtitle: 'You can see your payments here.',
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Ödemelerim',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ...payments.map((payment) {
                    final canPay = _canPay(payment);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.receipt_long_outlined),
                              title: Builder(
                                builder: (context) {
                                  final hasCoupon = payment.couponId != null;
                                  final appliedCoupon = hasCoupon
                                      ? _appliedCoupons[payment.id]
                                      : null;

                                  if (!hasCoupon || appliedCoupon == null) {
                                    return Text(
                                      '${payment.amount.toStringAsFixed(2)} TL',
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${appliedCoupon.finalAmount.toStringAsFixed(2)} TL',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Eski tutar: ${payment.amount.toStringAsFixed(2)} TL',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              subtitle: Builder(
                                builder: (context) {
                                  final hasCoupon = payment.couponId != null;
                                  final appliedCoupon = hasCoupon
                                      ? _appliedCoupons[payment.id]
                                      : null;

                                  return Text(
                                    'Status: ${payment.status}\n'
                                    'Reservation ID: ${payment.reservationId}'
                                    '${hasCoupon ? '\nCoupon ID: ${payment.couponId}' : ''}'
                                    '${appliedCoupon == null ? '' : '\nDiscount: ${appliedCoupon.discountAmount.toStringAsFixed(2)} TL'}',
                                  );
                                },
                              ),
                              isThreeLine: true,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: !_isProcessing && canPay
                                        ? () {
                                            if (payment.couponId == null) {
                                              _showCouponDialog(payment);
                                            } else {
                                              _removeCoupon(payment);
                                            }
                                          }
                                        : null,
                                    icon: Icon(
                                      payment.couponId == null
                                          ? Icons.confirmation_number_outlined
                                          : Icons.remove_circle_outline,
                                    ),
                                    label: Text(
                                      payment.couponId == null
                                          ? 'Kupon Ekle'
                                          : 'Kuponu Çıkart',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: canPay && !_isProcessing
                                        ? () => _completePayment(payment.id)
                                        : null,
                                    icon: const Icon(Icons.payment_outlined),
                                    label: Text(
                                      _isProcessing && canPay
                                          ? 'Processing'
                                          : 'Make payment',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AddBalanceScreen extends StatefulWidget {
  const AddBalanceScreen({super.key});

  @override
  State<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceScreenState extends State<AddBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _userService = UserService();

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _positiveAmount(String? value) {
    final amount = double.tryParse((value ?? '').trim());

    if (amount == null || amount <= 0) {
      return 'Pozitif bir tutar girin';
    }

    return null;
  }

  Future<void> _addBalance() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.addBalance(amount);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount added.')));

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Add amount.'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add amount.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'TL',
                ),
                validator: _positiveAmount,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _addBalance,
              icon: const Icon(Icons.add),
              label: Text(_isSaving ? 'Adding...' : 'Add amount.'),
            ),
          ],
        ),
      ),
    );
  }
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

class _CouponCodeDialog extends StatefulWidget {
  const _CouponCodeDialog();

  @override
  State<_CouponCodeDialog> createState() => _CouponCodeDialogState();
}

class _CouponCodeDialogState extends State<_CouponCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();

    if (code.isEmpty) return;

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(code);
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kupon Ekle'),
      content: TextField(
        controller: _codeController,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Kupon Kodu',
          prefixIcon: Icon(Icons.confirmation_number_outlined),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Devam')),
      ],
    );
  }
}
