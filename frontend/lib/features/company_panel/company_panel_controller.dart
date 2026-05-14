import 'package:flutter/foundation.dart';

import '../../data/models/charger.dart';
import '../../data/models/company_member.dart';
import '../../data/models/company_statistics.dart';
import '../../data/models/reservation.dart';
import '../../data/models/station.dart';
import '../../data/models/user.dart';
import '../../data/services/charger_service.dart';
import '../../data/services/company_service.dart';
import '../../data/services/reservation_service.dart';
import '../../data/services/station_service.dart';

class CompanyPanelController extends ChangeNotifier {
  CompanyPanelController({
    required this.currentUser,
    CompanyService? companyService,
    StationService? stationService,
    ChargerService? chargerService,
    ReservationService? reservationService,
  }) : _companyService = companyService ?? CompanyService(),
       _stationService = stationService ?? StationService(),
       _chargerService = chargerService ?? ChargerService(),
       _reservationService = reservationService ?? ReservationService();

  final AppUser currentUser;
  final CompanyService _companyService;
  final StationService _stationService;
  final ChargerService _chargerService;
  final ReservationService _reservationService;

  bool isLoading = false;
  String? error;
  List<CompanyEmployee> employees = [];
  List<Station> stations = [];
  List<Charger> chargers = [];
  List<Reservation> reservations = [];
  List<StationUsage> usage = [];
  CompanyRevenue revenue = const CompanyRevenue(
    revenue: 0,
    monthly: [],
    stations: [],
  );

  bool get isManager =>
      currentUser.effectiveRole == 'COMPANY_MANAGER' ||
      currentUser.effectiveRole == 'STATION_MANAGER';

  bool get isOperator =>
      currentUser.effectiveRole == 'COMPANY_OPERATOR' ||
      currentUser.effectiveRole == 'STATION_OPERATOR';

  bool get hasValidMembership => currentUser.companyId != null;

  int get activeChargers =>
      chargers.where((charger) => charger.status == 'AVAILABLE').length;

  int get offlineChargers => chargers
      .where(
        (charger) =>
            charger.status == 'OUT_OF_SERVICE' || charger.status == 'CLOSED',
      )
      .length;

  double get energyDelivered =>
      usage.fold(0, (sum, item) => sum + item.energyDelivered);

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _companyService.getMyCompanyStations(),
        if (isManager)
          _companyService.getMyCompanyEmployees()
        else
          Future.value(<CompanyEmployee>[]),
        _companyService.getStationUsage(),
        _companyService.getCompanyRevenue(year: DateTime.now().year),
      ]);

      stations = results[0] as List<Station>;
      employees = results[1] as List<CompanyEmployee>;
      usage = results[2] as List<StationUsage>;
      revenue = results[3] as CompanyRevenue;

      final chargerLists = await Future.wait(
        stations.map(
          (station) => _stationService.getStationChargers(station.id),
        ),
      );
      chargers = chargerLists.expand((items) => items).toList();

      final reservationLists = await Future.wait(
        chargers.map(
          (charger) => _reservationService
              .getCompanyChargerReservations(charger.id)
              .catchError((_) => <Reservation>[]),
        ),
      );
      reservations = reservationLists.expand((items) => items).toList();
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMember({required int userId, required String role}) async {
    final companyId = currentUser.companyId;
    if (companyId == null) throw StateError('Company membership required');
    await _companyService.addCompanyMember(
      companyId: companyId,
      userId: userId,
      role: role,
    );
    await load(silent: true);
  }

  Future<void> removeMember(CompanyEmployee employee) async {
    final companyId = currentUser.companyId;
    if (companyId == null) throw StateError('Company membership required');
    await _companyService.removeCompanyMember(
      companyId: companyId,
      userId: employee.member.userId,
      role: employee.member.role,
    );
    await load(silent: true);
  }

  Future<void> saveStation(Station station) async {
    if (station.id == 0) {
      await _stationService.createStation(station);
    } else {
      await _stationService.updateStation(station.id, station);
    }
    await load(silent: true);
  }

  Future<void> deleteStation(Station station) async {
    await _stationService.deleteStation(station.id);
    await load(silent: true);
  }

  Future<void> updateStationStatus(Station station, String status) async {
    await _stationService.updateStationStatus(station.id, status);
    await load(silent: true);
  }

  Future<void> saveCharger(Charger charger) async {
    if (charger.id == 0) {
      await _chargerService.createCharger(charger);
    } else {
      await _chargerService.updateCharger(charger.id, charger);
    }
    await load(silent: true);
  }

  Future<void> deleteCharger(Charger charger) async {
    await _chargerService.deleteCharger(charger.id);
    await load(silent: true);
  }

  Future<void> updateChargerStatus(Charger charger, String status) async {
    await _chargerService.updateChargerStatus(charger.id, status);
    await load(silent: true);
  }
}
