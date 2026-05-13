import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_snackbar.dart';
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

const _connectorTypeOptions = [
  'TYPE_1',
  'TYPE_2',
  'CCS1',
  'CCS2',
  'CHADEMO',
  'NACS',
  'GB_T_AC',
  'GB_T_DC',
  'TESLA_ROADSTER',
  'TESLA_TYPE_2',
];

const _currentTypeOptions = ['AC', 'DC'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStorage = TokenStorage();
  final _userService = UserService();

  late Future<AppUser?> _userFuture = _loadUser();
  bool _isDeletingAccount = false;

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

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          title: const Text('Delete Account?'),
          content: const Text(
            'This action will deactivate your account and log you out. '
            'Your account can no longer be used unless reactivated by support.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _userService.deactivateCurrentUser();
      await _tokenStorage.clear();

      if (!mounted) return;

      AppSnackBar.showSuccess(context, 'Account deactivated.');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, error.toString());
      setState(() {
        _isDeletingAccount = false;
      });
    }
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
                Text('Profile Information', style: textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  _MessageCard(
                    icon: Icons.error_outline,
                    title: 'Profile could not be loaded',
                    subtitle: snapshot.error.toString(),
                  )
                else if (user == null)
                  const _MessageCard(
                    icon: Icons.info_outline,
                    title: 'Guest session',
                    subtitle: 'Sign in to view profile information.',
                  )
                else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Full Name'),
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
                    title: const Text('My Vehicles'),
                    subtitle: const Text('Add or edit vehicles'),
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
                const SizedBox(height: 32),
                Text(
                  'Danger Zone',
                  style: textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isDeletingAccount ? null : _confirmDeleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: _isDeletingAccount
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_forever_outlined),
                  label: Text(
                    _isDeletingAccount ? 'Deleting...' : 'Delete Account',
                  ),
                ),
                const SizedBox(height: 24),
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
  late Future<List<Payment>> _paymentsFuture = _loadPayments();
  late Future<List<Coupon>> _couponsFuture = _loadCoupons();
  bool _isProcessing = false;

  bool _isPaid(Payment payment) {
    final status = payment.status.toUpperCase();

    return status == 'PAID' ||
        status == 'COMPLETED' ||
        status == 'SUCCESS' ||
        status == 'SUCCEEDED';
  }

  Future<List<Coupon>> _loadCoupons() {
    return _couponService.getMyCoupons();
  }

  Future<void> _refreshPaymentsAndCoupons() async {
    setState(() {
      _paymentsFuture = _loadPayments();
      _couponsFuture = _loadCoupons();
    });

    await Future.wait([_paymentsFuture, _couponsFuture]);
  }

  Widget _buildPaymentList(
    List<Payment> payments, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: payments.map(_buildPaymentCard).toList(),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
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
                  final hasDiscount =
                      payment.couponId != null && payment.discountAmount > 0;

                  if (!hasDiscount) {
                    return Text(_formatAmount(payment.amount));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatAmount(payment.finalAmount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Original amount: ${_formatAmount(payment.amount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  );
                },
              ),
              subtitle: Text(
                'Status: ${payment.status}\n'
                'Reservation ID: ${payment.reservationId}'
                '${payment.couponCode == null ? '' : '\nCoupon: ${payment.couponCode}'}'
                '${payment.discountAmount <= 0 ? '' : '\nDiscount: ${_formatAmount(payment.discountAmount)}'}',
              ),
              isThreeLine: true,
            ),
            const SizedBox(height: 8),

            if (canPay)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !_isProcessing
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
                            ? 'Add Coupon'
                            : 'Remove Coupon',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: !_isProcessing
                          ? () => _completePayment(payment.id)
                          : null,
                      icon: const Icon(Icons.payment_outlined),
                      label: Text(
                        _isProcessing ? 'Processing' : 'Make payment',
                      ),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Paid'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<Payment>> _loadPayments() {
    return _paymentService.getMyPayments();
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
        _paymentsFuture = _loadPayments();
      });

      _showMessage('Coupon removed');
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
            title: const Text('Coupon Preview'),
            content: Text(
              'Coupon Code: $code\n'
              'First Amount: ${payment.amount.toStringAsFixed(2)} TL\n'
              'Discount: ${preview.discountAmount.toStringAsFixed(2)} TL\n'
              'New Amount: ${preview.finalAmount.toStringAsFixed(2)} TL',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );

      if (shouldApply != true) return;

      await _couponService.applyCoupon(
        paymentId: payment.id,
        code: code,
        orderAmount: payment.amount,
      );

      if (!mounted) return;

      setState(() {
        _paymentsFuture = _loadPayments();
      });

      _showMessage('Coupon applied');
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
    AppSnackBar.showInfo(context, message);
  }

  bool _canPay(Payment payment) {
    return payment.status.toUpperCase() == 'PENDING';
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} TL';
  }

  Widget _buildCouponCard(Coupon coupon) {
    final isUsable = _isCouponUsable(coupon);

    return Card(
      child: ListTile(
        leading: Icon(
          isUsable
              ? Icons.confirmation_number
              : Icons.confirmation_number_outlined,
        ),
        title: Text(coupon.code),
        subtitle: Text(
          'Status: ${_couponStatus(coupon)}\n'
          'Discount: ${_formatCouponDiscount(coupon)}\n'
          'Minimum Amount: ${_formatAmount(coupon.minOrderAmount)}\n'
          'Validity Date: ${_formatCouponDate(coupon.validFrom)} - ${_formatCouponDate(coupon.validUntil)}\n'
          'Usage: ${coupon.usedCount}/${coupon.usageLimit ?? '∞'}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Copy code',
          icon: const Icon(Icons.copy),
          onPressed: () => _copyCouponCode(coupon.code),
        ),
      ),
    );
  }

  bool _isCouponExpired(Coupon coupon) {
    final validUntil = DateTime.tryParse(coupon.validUntil);
    if (validUntil == null) return false;

    return validUntil.isBefore(DateTime.now());
  }

  bool _isCouponNotStarted(Coupon coupon) {
    final validFrom = DateTime.tryParse(coupon.validFrom);
    if (validFrom == null) return false;

    return validFrom.isAfter(DateTime.now());
  }

  bool _isCouponUsedUp(Coupon coupon) {
    final usageLimit = coupon.usageLimit;
    if (usageLimit == null) return false;

    return coupon.usedCount >= usageLimit;
  }

  bool _isCouponUsable(Coupon coupon) {
    return coupon.isActive &&
        !_isCouponExpired(coupon) &&
        !_isCouponNotStarted(coupon) &&
        !_isCouponUsedUp(coupon);
  }

  String _couponStatus(Coupon coupon) {
    if (!coupon.isActive) return 'Inactive';
    if (_isCouponNotStarted(coupon)) return 'Not started';
    if (_isCouponExpired(coupon)) return 'Expired';
    if (_isCouponUsedUp(coupon)) return 'Usage rights have expired.';

    return 'Active';
  }

  String _formatCouponDiscount(Coupon coupon) {
    if (coupon.discountType.toUpperCase() == 'PERCENTAGE') {
      return '%${coupon.discountValue.toStringAsFixed(0)}';
    }

    return _formatAmount(coupon.discountValue);
  }

  String _formatCouponDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Future<void> _copyCouponCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coupon code copied')));
  }

  Widget _buildCouponsTab() {
    return FutureBuilder<List<Coupon>>(
      future: _couponsFuture,
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
                title: 'Coupons could not be loaded',
                subtitle: snapshot.error.toString(),
              ),
            ],
          );
        }

        final coupons = snapshot.data ?? [];

        if (coupons.isEmpty) {
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _MessageCard(
                icon: Icons.confirmation_number_outlined,
                title: 'You don\'t have any coupons',
                subtitle: 'Your coupons will appear here.',
              ),
            ],
          );
        }

        coupons.sort((a, b) {
          final aUsable = _isCouponUsable(a);
          final bUsable = _isCouponUsable(b);

          if (aUsable == bUsable) {
            return a.code.compareTo(b.code);
          }

          return aUsable ? -1 : 1;
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: coupons.map(_buildCouponCard).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Payments'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPaymentsAndCoupons,
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
                      title: 'Payments could not be loaded',
                      subtitle: snapshot.error.toString(),
                    ),
                  ],
                );
              }

              final payments = snapshot.data ?? [];

              final unpaidPayments = payments
                  .where((payment) => !_isPaid(payment))
                  .toList();
              final paidPayments = payments.where(_isPaid).toList();

              return DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'My Payments',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Unpaid (${unpaidPayments.length})'),
                        Tab(text: 'Paid (${paidPayments.length})'),
                        const Tab(text: 'My Coupons'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPaymentList(
                            unpaidPayments,
                            emptyTitle: 'There aren\'t any unpaid payments',
                            emptySubtitle: 'Your payments will appear here.',
                          ),
                          _buildPaymentList(
                            paidPayments,
                            emptyTitle: 'There aren\'t any paid payments',
                            emptySubtitle:
                                'Your completed payments will appear here.',
                          ),
                          _buildCouponsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
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
      return 'Enter a positive amount';
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

      AppSnackBar.showSuccess(context, 'Balance added.');

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      AppSnackBar.showError(context, error.toString());
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
      appBar: const AppAppBar(title: 'Add Balance'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Add Balance',
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
                  labelText: 'Amount',
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
              label: Text(_isSaving ? 'Adding...' : 'Add Balance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _connectorController = TextEditingController(text: 'TYPE_2');
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
    _brandController.dispose();
    _nameController.dispose();
    _modelController.dispose();
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
      _showMessage('You must sign in to add a vehicle');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _vehicleService.createVehicle(
        VehicleInput(
          userId: userId,
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          plate: _plateController.text.trim().toUpperCase(),
          maxChargingPower: double.parse(_maxPowerController.text.trim()),
          batteryCapacity: double.parse(_batteryCapacityController.text.trim()),
          connectorType: _normalizeConnectorType(_connectorController.text),
          currentType: _currentTypeController.text.trim().toUpperCase(),
        ),
      );

      _brandController.clear();
      _nameController.clear();
      _modelController.clear();
      _plateController.clear();
      _connectorController.text = _connectorTypeOptions.first;
      _currentTypeController.text = _currentTypeOptions.first;
      _maxPowerController.clear();
      _batteryCapacityController.clear();
      if (!mounted) return;
      setState(() {
        _vehiclesFuture = _loadVehicles();
      });
      _showMessage('Vehicle added');
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
      _showMessage('Vehicle deleted');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    AppSnackBar.showInfo(context, message);
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }

  String _normalizeConnectorType(String value) {
    return value.trim().toUpperCase().replaceAll(' ', '_');
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
                    decoration: _vehicleInputDecoration(
                      context,
                      labelText: 'Vehicle Name',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _brandController,
                    decoration: _vehicleInputDecoration(
                      context,
                      labelText: 'Vehicle Brand',
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _modelController,
                    decoration: _vehicleInputDecoration(
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
                    decoration: _vehicleInputDecoration(
                      context,
                      labelText: 'Plate Number',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _connectorController.text,
                    isExpanded: true,
                    decoration: _vehicleInputDecoration(
                      context,
                      labelText: 'Connector Type',
                      prefixIcon: Icon(Icons.power),
                    ),
                    items: _connectorTypeOptions
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _connectorController.text = value;
                    },
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _currentTypeController.text,
                    isExpanded: true,
                    decoration: _vehicleInputDecoration(
                      context,
                      labelText: 'Current Type',
                      prefixIcon: Icon(Icons.electrical_services_outlined),
                    ),
                    items: _currentTypeOptions
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _currentTypeController.text = value;
                    },
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
                    decoration: _vehicleInputDecoration(
                      context,
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _vehicleInputDecoration(
                      context,
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
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
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
                    title: 'Vehicles could not be loaded',
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

InputDecoration _vehicleInputDecoration(
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
      title: const Text('Add Coupon'),
      content: TextField(
        controller: _codeController,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Coupon Code',
          prefixIcon: Icon(Icons.confirmation_number_outlined),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
