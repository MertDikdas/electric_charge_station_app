import 'package:flutter/material.dart';

import '../../data/models/coupon.dart';
import '../../data/services/coupon_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final _couponService = CouponService();
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderAmountController = TextEditingController(text: '0');
  final _maxDiscountAmountController = TextEditingController();
  final _usageLimitController = TextEditingController(text: '1');

  late Future<List<Coupon>> _couponsFuture;
  String _discountType = 'PERCENTAGE';
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _couponsFuture = _couponService.getCoupons();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _codeController.dispose();
    _discountValueController.dispose();
    _minOrderAmountController.dispose();
    _maxDiscountAmountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  void _reloadCoupons() {
    setState(() {
      _couponsFuture = _couponService.getCoupons();
    });
  }

  Future<void> _refreshCoupons() async {
    _reloadCoupons();
    await _couponsFuture;
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  int? _parseOptionalInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String _formatDate(DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _validFrom : _validUntil;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _validFrom = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _validFrom.hour,
          _validFrom.minute,
        );
        if (!_validUntil.isAfter(_validFrom)) {
          _validUntil = _validFrom.add(const Duration(days: 30));
        }
      } else {
        _validUntil = DateTime(picked.year, picked.month, picked.day, 23, 59);
      }
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _userIdController.clear();
    _codeController.clear();
    _discountValueController.clear();
    _minOrderAmountController.text = '0';
    _maxDiscountAmountController.clear();
    _usageLimitController.text = '1';
    setState(() {
      _discountType = 'PERCENTAGE';
      _validFrom = DateTime.now();
      _validUntil = DateTime.now().add(const Duration(days: 30));
      _isActive = true;
    });
  }

  Future<void> _createCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_validUntil.isAfter(_validFrom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid until must be after valid from.')),
      );
      return;
    }

    final userId = int.parse(_userIdController.text.trim());
    final code = _codeController.text.trim().toUpperCase();
    final discountValue = _parseOptionalDouble(_discountValueController.text)!;
    final minOrderAmount =
        _parseOptionalDouble(_minOrderAmountController.text) ?? 0;
    final maxDiscountAmount = _parseOptionalDouble(
      _maxDiscountAmountController.text,
    );
    final usageLimit = _parseOptionalInt(_usageLimitController.text);

    setState(() => _isSaving = true);

    try {
      await _couponService.createCoupon(
        Coupon(
          id: 0,
          userId: userId,
          code: code,
          discountType: _discountType,
          discountValue: discountValue,
          validFrom: _validFrom.toIso8601String(),
          validUntil: _validUntil.toIso8601String(),
          minOrderAmount: minOrderAmount,
          maxDiscountAmount: maxDiscountAmount,
          usageLimit: usageLimit,
          isActive: _isActive,
          usedCount: 0,
        ),
      );

      if (!mounted) return;
      _resetForm();
      _reloadCoupons();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon assigned to user #$userId.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCoupon(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Coupon'),
          content: Text('Delete ${coupon.code} for user #${coupon.userId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _couponService.deleteCoupon(coupon.id);
      if (!mounted) return;
      _reloadCoupons();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Coupon deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String? _requiredPositiveNumber(String? value) {
    final number = _parseOptionalDouble(value ?? '');
    if (number == null) return 'Required.';
    if (number <= 0) return 'Must be greater than 0.';
    if (_discountType == 'PERCENTAGE' && number > 100) {
      return 'Percentage cannot exceed 100.';
    }
    return null;
  }

  Widget _buildCouponForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign Coupon',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final userId = int.tryParse(value?.trim() ?? '');
                  if (userId == null || userId <= 0) {
                    return 'Enter a valid user id.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Coupon code',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  final code = value?.trim().toUpperCase() ?? '';
                  final isValid = RegExp(r'^[A-Z0-9_-]{3,32}$').hasMatch(code);
                  if (!isValid) {
                    return 'Use 3-32 uppercase letters, numbers, _ or -.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Discount type',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PERCENTAGE',
                    child: Text('Percentage'),
                  ),
                  DropdownMenuItem(
                    value: 'FIXED_AMOUNT',
                    child: Text('Fixed amount'),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _discountType = value);
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountValueController,
                decoration: const InputDecoration(
                  labelText: 'Discount value',
                  prefixIcon: Icon(Icons.percent_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _requiredPositiveNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minOrderAmountController,
                decoration: const InputDecoration(
                  labelText: 'Minimum order amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final number = _parseOptionalDouble(value ?? '') ?? 0;
                  if (number < 0) return 'Cannot be negative.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDiscountAmountController,
                decoration: const InputDecoration(
                  labelText: 'Maximum discount amount',
                  prefixIcon: Icon(Icons.price_check_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final number = _parseOptionalDouble(value ?? '');
                  if (number != null && number <= 0) {
                    return 'Must be greater than 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageLimitController,
                decoration: const InputDecoration(
                  labelText: 'Usage limit',
                  prefixIcon: Icon(Icons.repeat_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = _parseOptionalInt(value ?? '');
                  if ((value ?? '').trim().isNotEmpty &&
                      (number == null || number <= 0)) {
                    return 'Must be greater than 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _pickDate(isStart: true),
                      icon: const Icon(Icons.event_outlined),
                      label: Text('From ${_formatDate(_validFrom)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text('Until ${_formatDate(_validUntil)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _createCoupon,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_card_outlined),
                label: const Text('Assign Coupon'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponTile(Coupon coupon) {
    final discount = coupon.discountType == 'PERCENTAGE'
        ? '%${coupon.discountValue.toStringAsFixed(0)}'
        : coupon.discountValue.toStringAsFixed(2);
    final usageLimit = coupon.usageLimit?.toString() ?? '∞';

    return Card(
      child: ListTile(
        leading: Icon(
          coupon.isActive
              ? Icons.confirmation_number_outlined
              : Icons.block_outlined,
        ),
        title: Text('${coupon.code} · User #${coupon.userId}'),
        subtitle: Text(
          '$discount · Usage ${coupon.usedCount}/$usageLimit · '
          '${coupon.isActive ? 'Active' : 'Inactive'}',
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteCoupon(coupon),
        ),
      ),
    );
  }

  Widget _buildCouponList() {
    return FutureBuilder<List<Coupon>>(
      future: _couponsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Coupons could not be loaded: ${snapshot.error}'),
          );
        }

        final coupons = snapshot.data ?? [];
        if (coupons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No coupons found.'),
          );
        }

        return Column(children: coupons.map(_buildCouponTile).toList());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reloadCoupons,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCoupons,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCouponForm(),
            const SizedBox(height: 16),
            Text('All Coupons', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildCouponList(),
          ],
        ),
      ),
    );
  }
}
