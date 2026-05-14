import 'package:flutter/material.dart';

import '../../core/app_snackbar.dart';
import '../../data/models/charger.dart';
import '../../data/models/reservation.dart';
import '../../data/models/station.dart';
import '../../data/models/user.dart';
import 'company_panel_controller.dart';
import 'company_panel_widgets.dart';

class CompanyPanelShell extends StatefulWidget {
  const CompanyPanelShell({super.key, required this.currentUser});

  final AppUser currentUser;

  @override
  State<CompanyPanelShell> createState() => _CompanyPanelShellState();
}

class _CompanyPanelShellState extends State<CompanyPanelShell> {
  late final CompanyPanelController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();
    controller = CompanyPanelController(currentUser: widget.currentUser)
      ..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CompanyDashboard(controller: controller, onNavigate: _openPage),
      StatisticsPage(controller: controller),
      StationsManagementPage(controller: controller),
      ChargersManagementPage(controller: controller),
      ReservationsMonitoringPage(controller: controller),
      RevenueAnalyticsPage(controller: controller),
      if (controller.isManager) CompanyMembersPage(controller: controller),
    ];
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.query_stats),
        label: 'Stats',
      ),
      const NavigationDestination(
        icon: Icon(Icons.ev_station_outlined),
        label: 'Stations',
      ),
      const NavigationDestination(
        icon: Icon(Icons.electrical_services_outlined),
        label: 'Chargers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Reservations',
      ),
      const NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        label: 'Revenue',
      ),
      if (controller.isManager)
        const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Members',
        ),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.hasValidMembership) {
          return const CompanyScaffold(
            title: 'Company Panel',
            child: EmptyState(
              icon: Icons.lock_outline,
              title: 'Company access unavailable',
              subtitle: 'Your account has no active company membership.',
            ),
          );
        }
        final selectedIndex = index.clamp(0, pages.length - 1);
        return Scaffold(
          body: pages[selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: destinations,
          ),
        );
      },
    );
  }

  void _openPage(int pageIndex) {
    setState(() => index = pageIndex);
  }
}

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  final CompanyPanelController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      title: 'Company Dashboard',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => controller.load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: _PanelBody(
        controller: controller,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              DashboardTile(
                title: 'Employees',
                value: '${controller.employees.length}',
                icon: Icons.groups_outlined,
                onTap: () =>
                    controller.isManager ? onNavigate(6) : onNavigate(0),
              ),
              DashboardTile(
                title: 'Stations',
                value: '${controller.stations.length}',
                icon: Icons.ev_station_outlined,
                onTap: () => onNavigate(2),
              ),
              DashboardTile(
                title: 'Chargers',
                value: '${controller.chargers.length}',
                icon: Icons.electrical_services_outlined,
                onTap: () => onNavigate(3),
              ),
              DashboardTile(
                title: 'Reservations',
                value: '${controller.reservations.length}',
                icon: Icons.calendar_month_outlined,
                onTap: () => onNavigate(4),
              ),
              DashboardTile(
                title: 'Statistics',
                value: 'View',
                icon: Icons.query_stats,
                onTap: () => onNavigate(1),
              ),
              DashboardTile(
                title: 'Revenue',
                value: '₺${controller.revenue.revenue.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                onTap: () => onNavigate(5),
              ),
              DashboardTile(
                title: 'Usage Analytics',
                value: '${controller.usage.length}',
                icon: Icons.insights_outlined,
                onTap: () => onNavigate(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.controller});

  final CompanyPanelController controller;

  @override
  Widget build(BuildContext context) {
    final chargerStatus = <String, double>{};
    for (final charger in controller.chargers) {
      chargerStatus[charger.status] = (chargerStatus[charger.status] ?? 0) + 1;
    }
    return CompanyScaffold(
      title: 'Statistics',
      child: _PanelBody(
        controller: controller,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatsGrid(controller: controller),
              const SizedBox(height: 12),
              BarChartCard(
                title: 'Station Usage',
                values: {
                  for (final item in controller.usage)
                    item.stationName: item.usageCount.toDouble(),
                },
              ),
              LineChartCard(
                title: 'Revenue By Month',
                values: {
                  for (final item in controller.revenue.monthly)
                    '${item.month}': item.revenue,
                },
              ),
              BarChartCard(
                title: 'Revenue By Station',
                values: {
                  for (final item in controller.revenue.stations)
                    item.stationName: item.revenue,
                },
              ),
              PieChartCard(
                title: 'Charger Status Distribution',
                values: chargerStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyMembersPage extends StatefulWidget {
  const CompanyMembersPage({super.key, required this.controller});

  final CompanyPanelController controller;

  @override
  State<CompanyMembersPage> createState() => _CompanyMembersPageState();
}

class _CompanyMembersPageState extends State<CompanyMembersPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final employees = widget.controller.employees.where((employee) {
      final text = '${employee.user.fullName} ${employee.user.mail}'
          .toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();

    return CompanyScaffold(
      title: 'Company Members',
      actions: [
        IconButton(
          tooltip: 'Add member',
          onPressed: () => _showAddMemberSheet(context),
          icon: const Icon(Icons.person_add_alt_1),
        ),
      ],
      child: _PanelBody(
        controller: widget.controller,
        child: RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search employees',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
              const SizedBox(height: 12),
              if (employees.isEmpty)
                const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No employees found',
                  subtitle: 'Add company members to manage operations.',
                )
              else
                for (final employee in employees)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(employee.user.fullName),
                      subtitle: Text(employee.user.mail),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(status: employee.member.role),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () => _confirm(
                              context,
                              'Remove member?',
                              () => widget.controller.removeMember(employee),
                            ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context) {
    final userIdController = TextEditingController();
    var role = 'COMPANY_OPERATOR';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Company Member',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(
                      value: 'COMPANY_OPERATOR',
                      child: Text('Operator'),
                    ),
                    DropdownMenuItem(
                      value: 'COMPANY_MANAGER',
                      child: Text('Manager'),
                    ),
                  ],
                  onChanged: (value) =>
                      setModalState(() => role = value ?? role),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final userId = int.tryParse(userIdController.text.trim());
                    if (userId == null) return;
                    try {
                      await widget.controller.addMember(
                        userId: userId,
                        role: role,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (error) {
                      if (context.mounted) {
                        AppSnackBar.showError(context, error.toString());
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Member'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StationsManagementPage extends StatefulWidget {
  const StationsManagementPage({super.key, required this.controller});

  final CompanyPanelController controller;

  @override
  State<StationsManagementPage> createState() => _StationsManagementPageState();
}

class _StationsManagementPageState extends State<StationsManagementPage> {
  String query = '';
  String status = 'ALL';

  @override
  Widget build(BuildContext context) {
    final stations = widget.controller.stations.where((station) {
      final matchesQuery = '${station.name} ${station.address}'
          .toLowerCase()
          .contains(query.toLowerCase());
      final matchesStatus = status == 'ALL' || station.status == status;
      return matchesQuery && matchesStatus;
    }).toList();
    return CompanyScaffold(
      title: 'Stations',
      actions: [
        if (widget.controller.isManager)
          IconButton(
            tooltip: 'Add station',
            onPressed: () => _openStationForm(context),
            icon: const Icon(Icons.add_business_outlined),
          ),
      ],
      child: _PanelBody(
        controller: widget.controller,
        child: RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search station',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
              const SizedBox(height: 12),
              _StatusFilter(
                value: status,
                onChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: 12),
              if (stations.isEmpty)
                const EmptyState(
                  icon: Icons.ev_station_outlined,
                  title: 'No stations',
                  subtitle: 'Stations assigned to your company appear here.',
                )
              else
                for (final station in stations)
                  _StationCard(
                    station: station,
                    controller: widget.controller,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StationDetailPage(
                          controller: widget.controller,
                          station: station,
                        ),
                      ),
                    ),
                    onEdit: () => _openStationForm(context, station: station),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStationForm(BuildContext context, {Station? station}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AddEditStationPage(controller: widget.controller, station: station),
      ),
    );
  }
}

class StationDetailPage extends StatelessWidget {
  const StationDetailPage({
    super.key,
    required this.controller,
    required this.station,
  });

  final CompanyPanelController controller;
  final Station station;

  @override
  Widget build(BuildContext context) {
    final chargers = controller.chargers
        .where((charger) => charger.stationId == station.id)
        .toList();
    final reservations = controller.reservations
        .where(
          (reservation) =>
              chargers.any((charger) => charger.id == reservation.chargerId),
        )
        .toList();
    final stationUsage = controller.usage
        .where((item) => item.stationId == station.id)
        .fold<int>(0, (sum, item) => sum + item.usageCount);
    final revenue = controller.revenue.stations
        .where((item) => item.stationId == station.id)
        .fold<double>(0, (sum, item) => sum + item.revenue);
    return CompanyScaffold(
      title: station.name,
      actions: [
        if (controller.isManager)
          IconButton(
            tooltip: 'Add charger',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddEditChargerPage(
                  controller: controller,
                  stationId: station.id,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
      ],
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(station.address),
                  subtitle: Text('${station.latitude}, ${station.longitude}'),
                  trailing: StatusBadge(status: station.status),
                ),
              ),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  StatisticCard(
                    label: 'Chargers',
                    value: '${chargers.length}',
                    icon: Icons.electrical_services,
                  ),
                  StatisticCard(
                    label: 'Reservations',
                    value: '${reservations.length}',
                    icon: Icons.calendar_month,
                  ),
                  StatisticCard(
                    label: 'Usage Count',
                    value: '$stationUsage',
                    icon: Icons.insights,
                  ),
                  StatisticCard(
                    label: 'Monthly Revenue',
                    value: '₺${revenue.toStringAsFixed(0)}',
                    icon: Icons.payments,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Chargers', style: Theme.of(context).textTheme.titleMedium),
              for (final charger in chargers)
                _ChargerCard(controller: controller, charger: charger),
              const SizedBox(height: 12),
              Text(
                'Reservations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final reservation in reservations.take(12))
                _ReservationTile(
                  reservation: reservation,
                  charger: _chargerById(chargers, reservation.chargerId),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChargersManagementPage extends StatefulWidget {
  const ChargersManagementPage({super.key, required this.controller});

  final CompanyPanelController controller;

  @override
  State<ChargersManagementPage> createState() => _ChargersManagementPageState();
}

class _ChargersManagementPageState extends State<ChargersManagementPage> {
  String status = 'ALL';

  @override
  Widget build(BuildContext context) {
    final chargers = widget.controller.chargers
        .where((charger) => status == 'ALL' || charger.status == status)
        .toList();
    return CompanyScaffold(
      title: 'Chargers',
      actions: [
        if (widget.controller.isManager)
          IconButton(
            tooltip: 'Add charger',
            onPressed: () => _chooseStationForCharger(context),
            icon: const Icon(Icons.add),
          ),
      ],
      child: _PanelBody(
        controller: widget.controller,
        child: RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusFilter(
                value: status,
                onChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: 12),
              if (chargers.isEmpty)
                const EmptyState(
                  icon: Icons.electrical_services_outlined,
                  title: 'No chargers',
                  subtitle: 'Add chargers to stations to start operations.',
                )
              else
                for (final charger in chargers)
                  _ChargerCard(controller: widget.controller, charger: charger),
            ],
          ),
        ),
      ),
    );
  }

  void _chooseStationForCharger(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select Station', style: Theme.of(context).textTheme.titleLarge),
          for (final station in widget.controller.stations)
            ListTile(
              title: Text(station.name),
              subtitle: Text(station.address),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AddEditChargerPage(
                      controller: widget.controller,
                      stationId: station.id,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class ReservationsMonitoringPage extends StatefulWidget {
  const ReservationsMonitoringPage({super.key, required this.controller});

  final CompanyPanelController controller;

  @override
  State<ReservationsMonitoringPage> createState() =>
      _ReservationsMonitoringPageState();
}

class _ReservationsMonitoringPageState
    extends State<ReservationsMonitoringPage> {
  String status = 'ALL';
  int? chargerId;

  @override
  Widget build(BuildContext context) {
    final reservations = widget.controller.reservations.where((reservation) {
      final matchesStatus = status == 'ALL' || reservation.status == status;
      final matchesCharger =
          chargerId == null || reservation.chargerId == chargerId;
      return matchesStatus && matchesCharger;
    }).toList();
    return CompanyScaffold(
      title: 'Reservations',
      child: _PanelBody(
        controller: widget.controller,
        child: RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int?>(
                initialValue: chargerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Charger'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All chargers'),
                  ),
                  for (final charger in widget.controller.chargers)
                    DropdownMenuItem<int?>(
                      value: charger.id,
                      child: Text(
                        _chargerDisplayName(charger),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => chargerId = value),
              ),
              const SizedBox(height: 12),
              _ReservationStatusFilter(
                value: status,
                onChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: 12),
              if (reservations.isEmpty)
                const EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'No reservations',
                  subtitle: 'Reservation activity will appear here.',
                )
              else
                for (final entry in _groupReservations(
                  reservations,
                ).entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _chargerDisplayName(
                        _chargerById(widget.controller.chargers, entry.key),
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final reservation in entry.value)
                    _ReservationTile(
                      reservation: reservation,
                      charger: _chargerById(
                        widget.controller.chargers,
                        reservation.chargerId,
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class RevenueAnalyticsPage extends StatelessWidget {
  const RevenueAnalyticsPage({super.key, required this.controller});

  final CompanyPanelController controller;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      title: 'Revenue Analytics',
      child: _PanelBody(
        controller: controller,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatisticCard(
                label: 'Company Monthly Revenue',
                value: '₺${controller.revenue.revenue.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
              ),
              StatisticCard(
                label: 'Total kWh Delivered',
                value: controller.energyDelivered.toStringAsFixed(1),
                icon: Icons.bolt_outlined,
              ),
              LineChartCard(
                title: 'Monthly Revenue',
                values: {
                  for (final item in controller.revenue.monthly)
                    '${item.month}': item.revenue,
                },
              ),
              BarChartCard(
                title: 'Station Revenue Ranking',
                values: {
                  for (final item in controller.revenue.stations)
                    item.stationName: item.revenue,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddEditStationPage extends StatefulWidget {
  const AddEditStationPage({super.key, required this.controller, this.station});

  final CompanyPanelController controller;
  final Station? station;

  @override
  State<AddEditStationPage> createState() => _AddEditStationPageState();
}

class _AddEditStationPageState extends State<AddEditStationPage> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.station?.name ?? '');
  late final address = TextEditingController(
    text: widget.station?.address ?? '',
  );
  late final latitude = TextEditingController(
    text: widget.station?.latitude.toString() ?? '',
  );
  late final longitude = TextEditingController(
    text: widget.station?.longitude.toString() ?? '',
  );
  late String status = widget.station?.status ?? 'AVAILABLE';

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    latitude.dispose();
    longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      title: widget.station == null ? 'Add Station' : 'Edit Station',
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TextInput(
              controller: name,
              label: 'Station Name',
              icon: Icons.ev_station,
            ),
            _TextInput(
              controller: address,
              label: 'Address',
              icon: Icons.place_outlined,
            ),
            _TextInput(
              controller: latitude,
              label: 'Latitude',
              icon: Icons.map_outlined,
              number: true,
            ),
            _TextInput(
              controller: longitude,
              label: 'Longitude',
              icon: Icons.map_outlined,
              number: true,
            ),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _stationStatuses
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => status = value ?? status),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Station'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final companyId = widget.controller.currentUser.companyId;
    if (companyId == null) return;
    try {
      await widget.controller.saveStation(
        Station(
          id: widget.station?.id ?? 0,
          name: name.text.trim(),
          address: address.text.trim(),
          companyId: companyId,
          latitude: double.parse(latitude.text.trim()),
          longitude: double.parse(longitude.text.trim()),
          status: status,
          chargers: const [],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) AppSnackBar.showError(context, error.toString());
    }
  }
}

class AddEditChargerPage extends StatefulWidget {
  const AddEditChargerPage({
    super.key,
    required this.controller,
    required this.stationId,
    this.charger,
  });

  final CompanyPanelController controller;
  final int stationId;
  final Charger? charger;

  @override
  State<AddEditChargerPage> createState() => _AddEditChargerPageState();
}

class _AddEditChargerPageState extends State<AddEditChargerPage> {
  final formKey = GlobalKey<FormState>();
  late String connector = widget.charger?.connectorType ?? 'TYPE_2';
  late String currentType = widget.charger?.currentType ?? 'AC';
  late String status = widget.charger?.status ?? 'AVAILABLE';
  late final power = TextEditingController(
    text: widget.charger?.maxPower.toString() ?? '',
  );
  late final price = TextEditingController(
    text: widget.charger?.pricePerKwh.toString() ?? '',
  );

  @override
  void dispose() {
    power.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      title: widget.charger == null ? 'Add Charger' : 'Edit Charger',
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: connector,
              decoration: const InputDecoration(labelText: 'Connector Type'),
              items: _connectorTypes
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => connector = value ?? connector),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: currentType,
              decoration: const InputDecoration(labelText: 'Current Type'),
              items: _currentTypes
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => currentType = value ?? currentType),
            ),
            _TextInput(
              controller: power,
              label: 'Power Output (kW)',
              icon: Icons.bolt_outlined,
              number: true,
            ),
            _TextInput(
              controller: price,
              label: 'Price per kWh',
              icon: Icons.payments_outlined,
              number: true,
            ),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _stationStatuses
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => status = value ?? status),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Charger'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    try {
      await widget.controller.saveCharger(
        Charger(
          id: widget.charger?.id ?? 0,
          stationId: widget.stationId,
          connectorType: connector,
          currentType: currentType,
          maxPower: double.parse(power.text.trim()),
          pricePerKwh: double.parse(price.text.trim()),
          status: status,
          isReservedNow: widget.charger?.isReservedNow ?? false,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) AppSnackBar.showError(context, error.toString());
    }
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({required this.controller, required this.child});

  final CompanyPanelController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) return const PanelLoading();
        if (controller.error != null) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load panel',
            subtitle: controller.error!,
          );
        }
        return child;
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.controller});

  final CompanyPanelController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: [
        StatisticCard(
          label: 'Total Employees',
          value: '${controller.employees.length}',
          icon: Icons.groups_outlined,
        ),
        StatisticCard(
          label: 'Total Stations',
          value: '${controller.stations.length}',
          icon: Icons.ev_station_outlined,
        ),
        StatisticCard(
          label: 'Total Chargers',
          value: '${controller.chargers.length}',
          icon: Icons.electrical_services_outlined,
        ),
        StatisticCard(
          label: 'Active Chargers',
          value: '${controller.activeChargers}',
          icon: Icons.check_circle_outline,
        ),
        StatisticCard(
          label: 'Offline Chargers',
          value: '${controller.offlineChargers}',
          icon: Icons.highlight_off_outlined,
        ),
        StatisticCard(
          label: 'Total Reservations',
          value: '${controller.reservations.length}',
          icon: Icons.calendar_month_outlined,
        ),
        StatisticCard(
          label: 'Monthly Revenue',
          value: '₺${controller.revenue.revenue.toStringAsFixed(0)}',
          icon: Icons.payments_outlined,
        ),
        StatisticCard(
          label: 'Energy Delivered',
          value: controller.energyDelivered.toStringAsFixed(1),
          icon: Icons.bolt_outlined,
        ),
      ],
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.station,
    required this.controller,
    required this.onTap,
    required this.onEdit,
  });

  final Station station;
  final CompanyPanelController controller;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final chargers = controller.chargers
        .where((item) => item.stationId == station.id)
        .length;
    final reservations = controller.reservations.where((reservation) {
      return controller.chargers.any(
        (charger) =>
            charger.stationId == station.id &&
            charger.id == reservation.chargerId,
      );
    }).length;
    final revenue = controller.revenue.stations
        .where((item) => item.stationId == station.id)
        .fold<double>(0, (sum, item) => sum + item.revenue);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.ev_station_outlined),
        title: Text(station.name),
        subtitle: Text(
          '${station.address}\n$chargers chargers - $reservations reservations - ₺${revenue.toStringAsFixed(0)}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(status: station.status),
            if (controller.isManager)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }
                  if (value == 'delete') {
                    _confirm(
                      context,
                      'Delete station?',
                      () => controller.deleteStation(station),
                    );
                  }
                  if (_stationStatuses.contains(value)) {
                    controller.updateStationStatus(station, value);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  for (final item in _stationStatuses)
                    PopupMenuItem(value: item, child: Text('Set $item')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChargerCard extends StatelessWidget {
  const _ChargerCard({required this.controller, required this.charger});

  final CompanyPanelController controller;
  final Charger charger;

  @override
  Widget build(BuildContext context) {
    final reservationCount = controller.reservations
        .where((reservation) => reservation.chargerId == charger.id)
        .length;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.electrical_services_outlined),
        title: Text('${charger.connectorType} - ${charger.maxPower} kW'),
        subtitle: Text(
          '${charger.currentType} - $reservationCount reservations - ₺${charger.pricePerKwh}/kWh',
        ),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(status: charger.status),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddEditChargerPage(
                        controller: controller,
                        stationId: charger.stationId,
                        charger: charger,
                      ),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirm(
                    context,
                    'Delete charger?',
                    () => controller.deleteCharger(charger),
                  );
                } else {
                  controller.updateChargerStatus(charger, value);
                }
              },
              itemBuilder: (_) => [
                if (controller.isManager)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                for (final item in _stationStatuses)
                  PopupMenuItem(value: item, child: Text('Set $item')),
                if (controller.isManager)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation, required this.charger});

  final Reservation reservation;
  final Charger? charger;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: Text(
          _stationDisplayName(reservation, charger),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${reservation.date}  ${reservation.startTime} - ${reservation.endTime}\n${_chargerDisplayName(charger)}',
        ),
        isThreeLine: true,
        trailing: StatusBadge(status: reservation.status),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.number = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Required';
          if (number && double.tryParse(text) == null) return 'Enter a number';
          return null;
        },
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ScrollableSegmentedButton(
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'ALL', label: _segmentLabel('All')),
          ButtonSegment(value: 'AVAILABLE', label: _segmentLabel('Active')),
          ButtonSegment(value: 'MAINTENANCE', label: _segmentLabel('Maint.')),
          ButtonSegment(value: 'CLOSED', label: _segmentLabel('Closed')),
        ],
        selected: {value},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class _ReservationStatusFilter extends StatelessWidget {
  const _ReservationStatusFilter({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ScrollableSegmentedButton(
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'ALL', label: _segmentLabel('All')),
          ButtonSegment(value: 'PENDING', label: _segmentLabel('Pending')),
          ButtonSegment(value: 'COMPLETED', label: _segmentLabel('Done')),
          ButtonSegment(value: 'CANCELLED', label: _segmentLabel('Cancelled')),
        ],
        selected: {value},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class _ScrollableSegmentedButton extends StatelessWidget {
  const _ScrollableSegmentedButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }
}

Widget _segmentLabel(String text) {
  return SizedBox(
    width: 76,
    child: Center(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Future<void> _confirm(
  BuildContext context,
  String title,
  Future<void> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await action();
  } catch (error) {
    if (context.mounted) AppSnackBar.showError(context, error.toString());
  }
}

Map<int, List<Reservation>> _groupReservations(List<Reservation> reservations) {
  final grouped = <int, List<Reservation>>{};
  for (final reservation in reservations) {
    grouped.putIfAbsent(reservation.chargerId, () => []).add(reservation);
  }
  return grouped;
}

Charger? _chargerById(List<Charger> chargers, int id) {
  for (final charger in chargers) {
    if (charger.id == id) return charger;
  }
  return null;
}

String _chargerDisplayName(Charger? charger) {
  if (charger == null) return 'Charger';
  return [
    charger.stationName,
    charger.connectorType,
    charger.currentType,
    '${charger.maxPower.toStringAsFixed(0)} kW',
  ].where((value) => value.trim().isNotEmpty).join(' | ');
}

String _stationDisplayName(Reservation reservation, Charger? charger) {
  if (reservation.stationName.trim().isNotEmpty) {
    return reservation.stationName.trim();
  }
  if ((charger?.stationName.trim().isNotEmpty ?? false)) {
    return charger!.stationName.trim();
  }
  return 'Station';
}

const _stationStatuses = [
  'AVAILABLE',
  'OCCUPIED',
  'OUT_OF_SERVICE',
  'MAINTENANCE',
  'CLOSED',
];

const _connectorTypes = [
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

const _currentTypes = ['AC', 'DC'];
