import 'package:flutter/material.dart';

import '../../data/models/statistics.dart';
import '../../data/services/statistics_service.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final _statisticsService = StatisticsService();
  final _stationIdController = TextEditingController();

  late int _year;
  late int _month;
  late Future<AdminStatistics> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _statisticsFuture = _loadStatistics();
  }

  @override
  void dispose() {
    _stationIdController.dispose();
    super.dispose();
  }

  Future<AdminStatistics> _loadStatistics() {
    return _statisticsService.getAdminStatistics(year: _year, month: _month);
  }

  Future<void> _refreshStatistics() async {
    setState(() {
      _statisticsFuture = _loadStatistics();
    });

    await _statisticsFuture;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;

      if (_month < 1) {
        _month = 12;
        _year -= 1;
      }

      if (_month > 12) {
        _month = 1;
        _year += 1;
      }

      _statisticsFuture = _loadStatistics();
    });
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$_month/$_year',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(AdminOverviewStatistics overview) {
    final metrics = [
      (Icons.people_outline, 'Users', _formatNumber(overview.totalUsers)),
      (
        Icons.business_outlined,
        'Companies',
        '${overview.activeCompanies}/${overview.totalCompanies}',
      ),
      (
        Icons.ev_station_outlined,
        'Stations',
        '${overview.availableStations}/${overview.totalStations}',
      ),
      (
        Icons.power_outlined,
        'Chargers',
        '${overview.availableChargers}/${overview.totalChargers}',
      ),
      (
        Icons.flash_on_outlined,
        'Active Sessions',
        _formatNumber(overview.activeSessions),
      ),
      (
        Icons.event_available_outlined,
        'Reservations',
        _formatNumber(overview.totalReservations),
      ),
      (
        Icons.payments_outlined,
        'Revenue',
        _formatNumber(overview.monthlyRevenue),
      ),
      (
        Icons.bolt_outlined,
        'Energy kWh',
        _formatNumber(overview.totalEnergyConsumed),
      ),
    ];

    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 132,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(
          icon: metric.$1,
          label: metric.$2,
          value: metric.$3,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStationOverviewLauncher() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _stationIdController,
                decoration: const InputDecoration(
                  labelText: 'Station ID',
                  prefixIcon: Icon(Icons.ev_station_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                final stationId = int.tryParse(
                  _stationIdController.text.trim(),
                );
                if (stationId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a station ID.')),
                  );
                  return;
                }

                _showStationOverview(stationId);
              },
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStationOverview(int stationId) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Station #$stationId Overview'),
          content: SizedBox(
            width: 420,
            child: FutureBuilder<StationOverviewStatistics>(
              future: _statisticsService.getAdminStationOverview(
                stationId: stationId,
                year: _year,
                month: _month,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }

                final overview = snapshot.data;
                if (overview == null) {
                  return const Text('No station overview found.');
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overview.stationAddress.isNotEmpty)
                        Text(
                          overview.stationAddress,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(height: 12),
                      _buildOverviewRow('Company ID', overview.companyId),
                      _buildOverviewRow(
                        'Chargers',
                        '${overview.availableChargers}/${overview.totalChargers} available',
                      ),
                      _buildOverviewRow(
                        'Occupied Chargers',
                        overview.occupiedChargers,
                      ),
                      _buildOverviewRow(
                        'Closed Chargers',
                        overview.closedChargers,
                      ),
                      const Divider(),
                      _buildOverviewRow(
                        'Reservations',
                        overview.totalReservations,
                      ),
                      _buildOverviewRow(
                        'Active Reservations',
                        overview.activeReservations,
                      ),
                      _buildOverviewRow(
                        'Cancelled Reservations',
                        overview.cancelledReservations,
                      ),
                      _buildOverviewRow(
                        'Completed Reservations',
                        overview.completedReservations,
                      ),
                      const Divider(),
                      _buildOverviewRow(
                        'Active Sessions',
                        overview.activeSessions,
                      ),
                      _buildOverviewRow(
                        'Completed Sessions',
                        overview.completedSessions,
                      ),
                      const Divider(),
                      _buildOverviewRow(
                        'Monthly Revenue',
                        _formatNumber(overview.monthlyRevenue),
                      ),
                      _buildOverviewRow(
                        'Total Revenue',
                        _formatNumber(overview.totalRevenue),
                      ),
                      _buildOverviewRow(
                        'Monthly Usage',
                        overview.monthlyUsageCount,
                      ),
                      _buildOverviewRow(
                        'Total Usage',
                        overview.totalUsageCount,
                      ),
                      _buildOverviewRow(
                        'Monthly Energy kWh',
                        _formatNumber(overview.monthlyEnergyConsumed),
                      ),
                      _buildOverviewRow(
                        'Total Energy kWh',
                        _formatNumber(overview.totalEnergyConsumed),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewRow(String label, Object value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value.toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRevenueList(List<CompanyRevenue> items) {
    return _buildListSection(
      emptyText: 'No company revenue found.',
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.business_outlined),
          title: Text(
            item.companyName.isEmpty
                ? 'Company #${item.companyId}'
                : item.companyName,
          ),
          trailing: Text(_formatNumber(item.revenue)),
        );
      },
    );
  }

  Widget _buildStationRevenueList(List<StationRevenue> items) {
    return _buildListSection(
      emptyText: 'No station revenue found.',
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.ev_station_outlined),
          title: Text(
            item.stationAddress.isEmpty
                ? 'Station #${item.stationId}'
                : item.stationAddress,
          ),
          trailing: Text(_formatNumber(item.revenue)),
          onTap: () => _showStationOverview(item.stationId),
        );
      },
    );
  }

  Widget _buildStationUsageList(List<StationUsage> items) {
    return _buildListSection(
      emptyText: 'No station usage found.',
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.timeline_outlined),
          title: Text(
            item.stationAddress.isEmpty
                ? 'Station #${item.stationId}'
                : item.stationAddress,
          ),
          trailing: Text(_formatNumber(item.usageCount)),
          onTap: () => _showStationOverview(item.stationId),
        );
      },
    );
  }

  Widget _buildStatusList(List<StatusCount> items) {
    return _buildListSection(
      emptyText: 'No status data found.',
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          title: Text(_formatStatus(item.status)),
          trailing: Text(_formatNumber(item.count)),
        );
      },
    );
  }

  Widget _buildListSection({
    required int itemCount,
    required String emptyText,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    if (itemCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(emptyText),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: itemBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: RefreshIndicator(
        onRefresh: _refreshStatistics,
        child: FutureBuilder<AdminStatistics>(
          future: _statisticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  Text(
                    'Statistics could not be loaded.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final statistics = snapshot.data;
            if (statistics == null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  const Text('No statistics found.'),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 8),
                _buildOverview(statistics.overview),
                _buildSectionTitle('Station Overview'),
                _buildStationOverviewLauncher(),
                _buildSectionTitle('Revenue By Company'),
                _buildCompanyRevenueList(statistics.companyRevenue),
                _buildSectionTitle('Revenue By Station'),
                _buildStationRevenueList(statistics.stationRevenue),
                _buildSectionTitle('Station Usage'),
                _buildStationUsageList(statistics.stationUsage),
                _buildSectionTitle('Charger Status'),
                _buildStatusList(statistics.chargerStatuses),
                _buildSectionTitle('Reservation Status'),
                _buildStatusList(statistics.reservationStatuses),
              ],
            );
          },
        ),
      ),
    );
  }
}
