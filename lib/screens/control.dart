import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../constants/Constants.dart';
import '../widgets/compact_header.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String _error = '';

  // Devices (type 1 and type 3)
  List<DeviceInfo> _devices = [];
  DeviceInfo? _selectedDevice;

  // Relay status (for device3)
  bool _relayStatus = true;
  Map<String, dynamic>? _relayStatusData;

  // Device 1 control status
  Map<String, dynamic>? _device1ControlStatus;

  // Schedules
  List<RelaySchedule> _schedules = [];

  // History
  List<RelayHistoryItem> _history = [];

  // Device 1 control history
  List<Device1ControlHistoryItem> _device1ControlHistory = [];

  // Device 1 defrost schedules
  List<DefrostSchedule> _defrostSchedules = [];

  // Device 1 automation rules
  List<AutomationRule> _automationRules = [];

  // Device 5 relay states (16 relays)
  Map<int, bool> _device5RelayStates = {};
  List<Map<String, dynamic>> _device5History = [];

  // Schedule form
  String _scheduleType = 'once';
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _recurringTime = TimeOfDay.now();
  int _durationMinutes = 60;
  Set<String> _selectedDays = {};
  bool _targetRelayStatus = false;

  // Harvest-based turnoff
  Map<String, dynamic>? _harvestTurnoffStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _loadDevices();
      if (_selectedDevice != null) {
        if (_selectedDevice!.deviceType == 'device1') {
          // Load device1 specific data
          await Future.wait([
            _loadDevice1ControlStatus(),
            _loadDevice1ControlHistory(),
            _loadDefrostSchedules(),
            _loadAutomationRules(),
          ]);
        } else if (_selectedDevice!.deviceType == 'device5') {
          // Load device5 specific data
          await Future.wait([
            _loadDevice5RelayStatus(),
            _loadDevice5History(),
          ]);
        } else if (_selectedDevice!.deviceType == 'device3') {
          // Load device3 specific data
          await Future.wait([
            _loadRelayStatus(),
            _loadSchedules(),
            _loadHistory(),
            _loadHarvestTurnoffStatus(),
          ]);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDevices() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/list/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'include_unit_details': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Include both device1 and device3
          final devices = (data['devices'] as List)
              .where((d) => d['device_type'] == 'device3' || d['device_type'] == 'device1' || d['device_type'] == 'device5')
              .map((d) => DeviceInfo.fromJson(d))
              .toList();

          setState(() {
            _devices = devices;
            if (_selectedDevice == null && devices.isNotEmpty) {
              _selectedDevice = devices.first;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  Future<void> _loadRelayStatus() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/relay-status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _relayStatusData = data['relay_status'];
            _relayStatus = data['relay_status']['current_status'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading relay status: $e');
    }
  }

  Future<void> _loadSchedules() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/relay-schedules/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _schedules = (data['schedules'] as List)
                .map((s) => RelaySchedule.fromJson(s))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/relay-history/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'limit': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _history = (data['history'] as List)
                .map((h) => RelayHistoryItem.fromJson(h))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _loadHarvestTurnoffStatus() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/harvest-turnoff/status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _harvestTurnoffStatus = data['harvest_turnoff'];
          });
        }
      }
    } catch (e) {
      print('Error loading harvest turnoff status: $e');
    }
  }

  Future<void> _loadDevice1ControlStatus() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-control/status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _device1ControlStatus = data['control_status'];
          });
        }
      }
    } catch (e) {
      print('Error loading device1 control status: $e');
    }
  }

  Future<void> _loadDevice1ControlHistory() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-control/history/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'limit': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _device1ControlHistory = (data['history'] as List)
                .map((h) => Device1ControlHistoryItem.fromJson(h))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading device1 control history: $e');
    }
  }

  Future<void> _loadDefrostSchedules() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-defrost/schedules/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _defrostSchedules = (data['schedules'] as List)
                .map((s) => DefrostSchedule.fromJson(s))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading defrost schedules: $e');
    }
  }

  Future<void> _loadAutomationRules() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-automation/rules/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _automationRules = (data['rules'] as List)
                .map((r) => AutomationRule.fromJson(r))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading automation rules: $e');
    }
  }

  Future<void> _createDefrostSchedule(String scheduleType, List<TimeOfDay> times, int duration, List<String> days) async {
    if (_selectedDevice == null) return;

    setState(() => _isLoading = true);

    try {
      // Convert times to comma-separated string
      final scheduledTimes = times.map((t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
      ).join(',');

      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-defrost/schedule/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'schedule_type': scheduleType,
          'times_per_day': times.length,
          'scheduled_times': scheduledTimes,
          'duration_minutes': duration,
          'days_of_week': days.join(','),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Defrost schedule created (${times.length}x per day)');
          await _loadDefrostSchedules();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error creating schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDefrostSchedule(int scheduleId) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-defrost/schedule/delete/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'schedule_id': scheduleId,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Schedule deleted');
        await _loadDefrostSchedules();
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAutomationRule(String name, String triggerType, String sensor, double threshold, bool turnOn, double hysteresis) async {
    if (_selectedDevice == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-automation/rule/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'name': name,
          'trigger_type': triggerType,
          'sensor': sensor,
          'threshold_value': threshold,
          'turn_compressor_on': turnOn,
          'hysteresis': hysteresis,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Automation rule created');
          await _loadAutomationRules();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error creating rule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutomationRule(int ruleId, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-automation/rule/toggle/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'rule_id': ruleId,
          'is_active': isActive,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar(isActive ? 'Rule enabled' : 'Rule disabled');
        await _loadAutomationRules();
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _deleteAutomationRule(int ruleId) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-automation/rule/delete/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'rule_id': ruleId,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Rule deleted');
        await _loadAutomationRules();
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _toggleDevice1Defrost(bool newStatus) async {
    if (_selectedDevice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-control/toggle-defrost/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'defrost_switch': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Backend message already includes info about compressor being turned off if applicable
          _showSuccessSnackBar(data['message'] ?? 'Defrost mode updated');
          await _loadData();
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to toggle defrost');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showErrorSnackBar(errorData['error'] ?? 'Failed to toggle defrost');
        } catch (_) {
          _showErrorSnackBar('Failed to toggle defrost');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDevice1Compressor(bool newStatus) async {
    if (_selectedDevice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device1-control/toggle-compressor/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'comp_switch': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Backend message already includes info about defrost being turned off if applicable
          _showSuccessSnackBar(data['message'] ?? 'Compressor updated');
          await _loadData();
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to toggle compressor');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showErrorSnackBar(errorData['error'] ?? 'Failed to toggle compressor');
        } catch (_) {
          _showErrorSnackBar('Failed to toggle compressor');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================
  // DEVICE 5 METHODS
  // ============================================

  Future<void> _loadDevice5RelayStatus() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device5-relay-status/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final states = data['relay_states'] as Map<String, dynamic>;
          setState(() {
            _device5RelayStates = {};
            states.forEach((key, value) {
              _device5RelayStates[int.parse(key)] = value ?? false;
            });
          });
        }
      }
    } catch (e) {
      print('Error loading device5 relay status: $e');
    }
  }

  Future<void> _loadDevice5History() async {
    if (_selectedDevice == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device5-relay-history/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'limit': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _device5History = List<Map<String, dynamic>>.from(data['history'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading device5 history: $e');
    }
  }

  Future<void> _toggleDevice5Relay(int relayNumber, bool newStatus) async {
    if (_selectedDevice == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device5-relay-toggle/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'relay_number': relayNumber,
          'relay_status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar(data['message'] ?? 'Relay $relayNumber toggled');
          await Future.wait([_loadDevice5RelayStatus(), _loadDevice5History()]);
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to toggle relay');
        }
      } else {
        _showErrorSnackBar('Failed to toggle relay');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDevice5AllRelays(bool status) async {
    if (_selectedDevice == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/device5-relay-toggle-all/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'relay_status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar(data['message'] ?? 'All relays toggled');
          await Future.wait([_loadDevice5RelayStatus(), _loadDevice5History()]);
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to toggle all relays');
        }
      } else {
        _showErrorSnackBar('Failed to toggle all relays');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setHarvestTurnoff(bool enabled, {int? harvestCount}) async {
    if (_selectedDevice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/harvest-turnoff/set/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'enabled': enabled,
          if (harvestCount != null) 'harvest_count': harvestCount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar(data['message'] ?? 'Harvest turnoff updated');
          await _loadHarvestTurnoffStatus();
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to update harvest turnoff');
        }
      } else {
        _showErrorSnackBar('Failed to update harvest turnoff');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRelay(bool newStatus, {int? durationMinutes}) async {
    if (_selectedDevice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/toggle-relay/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'device_id': _selectedDevice!.id,
          'relay_status': newStatus,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar(data['message'] ?? 'Relay toggled successfully');
          await _loadData();
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to toggle relay');
        }
      } else {
        _showErrorSnackBar('Failed to toggle relay');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSchedule() async {
    if (_selectedDevice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final body = {
        'business_id': Constants.myBusiness.businessUid,
        'device_id': _selectedDevice!.id,
        'relay_status': _targetRelayStatus,
        'schedule_type': _scheduleType,
      };

      if (_scheduleType == 'once') {
        body['scheduled_datetime'] = _scheduledDateTime.toIso8601String();
      } else if (_scheduleType == 'duration') {
        body['duration_minutes'] = _durationMinutes;
      } else if (_scheduleType == 'recurring_daily') {
        body['recurring_time'] =
            '${_recurringTime.hour.toString().padLeft(2, '0')}:${_recurringTime.minute.toString().padLeft(2, '0')}';
      } else if (_scheduleType == 'recurring_weekly') {
        body['recurring_time'] =
            '${_recurringTime.hour.toString().padLeft(2, '0')}:${_recurringTime.minute.toString().padLeft(2, '0')}';
        body['recurring_days'] = _selectedDays.join(',');
      }

      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/relay-schedule/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar(data['message'] ?? 'Schedule created successfully');
          Navigator.pop(context);
          await _loadSchedules();
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to create schedule');
        }
      } else {
        _showErrorSnackBar('Failed to create schedule');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/devices/relay-schedule/delete/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'business_id': Constants.myBusiness.businessUid,
          'schedule_id': scheduleId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Schedule cancelled');
          await _loadSchedules();
        } else {
          _showErrorSnackBar(data['error'] ?? 'Failed to cancel schedule');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading && _devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _devices.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CompactHeader(
                            title: "Control",
                            description: _selectedDevice?.deviceType == 'device1'
                                ? "Monitor control switches for Device 1"
                                : _selectedDevice?.deviceType == 'device5'
                                    ? "16-Relay Controller"
                                    : "Manage relay control for ice machines",
                            icon: CupertinoIcons.power,
                          ),
                          const SizedBox(height: 24),
                          _buildDeviceSelector(),
                          const SizedBox(height: 24),
                          if (_selectedDevice?.deviceType == 'device1') ...[
                            _buildDevice1ControlCard(),
                            const SizedBox(height: 24),
                            _buildDefrostScheduleSection(),
                            const SizedBox(height: 24),
                            _buildAutomationRulesSection(),
                            const SizedBox(height: 24),
                            _buildDevice1HistorySection(),
                          ] else if (_selectedDevice?.deviceType == 'device5') ...[
                            _buildDevice5ControlCard(),
                            const SizedBox(height: 24),
                            _buildDevice5HistorySection(),
                          ] else ...[
                            _buildStatusCard(),
                            const SizedBox(height: 24),
                            _buildTabSection(),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.power,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Control Devices Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control is available for Device 1, Device 3, and Device 5',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Device',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DeviceInfo>(
            value: _selectedDevice,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _devices.map((device) {
              return DropdownMenuItem(
                value: device,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: device.deviceType == 'device1'
                            ? Colors.blue.withOpacity(0.1)
                            : device.deviceType == 'device5'
                                ? Colors.indigo.withOpacity(0.1)
                                : Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        device.deviceType == 'device1' ? 'D1' : device.deviceType == 'device5' ? 'D5' : 'D3',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: device.deviceType == 'device1' ? Colors.blue : device.deviceType == 'device5' ? Colors.indigo : Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDevice = value;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_selectedDevice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _relayStatus
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_relayStatus ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDevice!.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relayStatus ? 'Machine is ON' : 'Machine is OFF',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 1.3,
                child: Switch(
                  value: _relayStatus,
                  onChanged: _isLoading ? null : (value) => _toggleRelay(value),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white30,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusInfo(
                'Last ON',
                _relayStatusData?['last_on'] != null
                    ? _formatDateTime(_relayStatusData!['last_on'])
                    : 'Never',
              ),
              _buildStatusInfo(
                'Last OFF',
                _relayStatusData?['last_off'] != null
                    ? _formatDateTime(_relayStatusData!['last_off'])
                    : 'Never',
              ),
              _buildStatusInfo(
                'Off Today',
                '${_relayStatusData?['times_off_today'] ?? 0}x',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Never';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Constants.ctaColorLight,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Constants.ctaColorLight,
            tabs: const [
              Tab(text: 'Quick Actions'),
              Tab(text: 'Schedules'),
              Tab(text: 'History'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickActions(),
                _buildSchedules(),
                _buildHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: CupertinoIcons.power,
            title: 'Turn OFF Indefinitely',
            subtitle: 'Machine stays off until manually turned on',
            onTap: () => _toggleRelay(false),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: CupertinoIcons.clock,
            title: 'Turn OFF for Duration',
            subtitle: 'Auto-turns on after specified time',
            onTap: () => _showDurationDialog(),
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: CupertinoIcons.calendar,
            title: 'Schedule ON/OFF',
            subtitle: 'Set specific date and time',
            onTap: () => _showScheduleDialog(),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: CupertinoIcons.repeat,
            title: 'Create Recurring Schedule',
            subtitle: 'Daily or weekly automation',
            onTap: () => _showRecurringDialog(),
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildHarvestTurnoffCard(),
        ],
      ),
    );
  }

  Widget _buildHarvestTurnoffCard() {
    final isEnabled = _harvestTurnoffStatus?['enabled'] ?? false;
    final harvestsRemaining = _harvestTurnoffStatus?['harvests_remaining'] ?? 0;
    final progressPercent = _harvestTurnoffStatus?['progress_percent'] ?? 0;
    final threshold = _harvestTurnoffStatus?['turn_off_after_harvests'];
    final harvestsSinceEnable = _harvestTurnoffStatus?['harvests_since_enable'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled ? Colors.teal.shade300 : Colors.grey.shade200,
          width: isEnabled ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isEnabled ? Colors.teal.shade50 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.snow, color: Colors.teal, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turn OFF After Harvests',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isEnabled
                          ? '$harvestsRemaining harvests remaining'
                          : 'Auto-turn off after set number of harvests',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _isLoading ? null : () => _setHarvestTurnoff(false),
                  tooltip: 'Disable',
                )
              else
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  onPressed: _isLoading ? null : () => _showHarvestTurnoffDialog(),
                ),
            ],
          ),
          if (isEnabled && threshold != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressPercent > 80 ? Colors.orange : Colors.teal,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$harvestsSinceEnable / $threshold harvests',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$progressPercent%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: progressPercent > 80 ? Colors.orange : Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showHarvestTurnoffDialog() {
    int harvestCount = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Turn OFF After Harvests'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The machine will automatically turn off after the specified number of harvest cycles.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Number of harvests:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: harvestCount > 1
                          ? () => setDialogState(() => harvestCount--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$harvestCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: harvestCount < 100
                          ? () => setDialogState(() => harvestCount++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [3, 5, 10, 15, 20].map((count) {
                    return ChoiceChip(
                      label: Text('$count'),
                      selected: harvestCount == count,
                      onSelected: (s) => setDialogState(() => harvestCount = count),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setHarvestTurnoff(true, harvestCount: harvestCount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Enable'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================
  // DEVICE 1 CONTROL WIDGETS
  // ============================================

  Widget _buildDevice1ControlCard() {
    if (_selectedDevice == null) return const SizedBox.shrink();

    final defrostSwitch = _device1ControlStatus?['defrost_switch'] ?? false;
    final compSwitch = _device1ControlStatus?['comp_switch'] ?? false;
    final lastUpdated = _device1ControlStatus?['last_updated'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDevice!.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Control Switches',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: _isLoading ? null : () => _loadData(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Defrost Switch - Toggleable
          _buildDevice1SwitchToggle(
            title: 'Defrost Mode',
            subtitle: defrostSwitch ? 'Active - Defrost cycle running' : 'Inactive - Tap to activate',
            isOn: defrostSwitch,
            icon: CupertinoIcons.snow,
            activeColor: Colors.cyan,
            onToggle: (value) => _toggleDevice1Defrost(value),
          ),

          const SizedBox(height: 16),

          // Compressor Switch - Toggleable
          _buildDevice1SwitchToggle(
            title: 'Compressor',
            subtitle: compSwitch ? 'Running' : 'Stopped - Tap to start',
            isOn: compSwitch,
            icon: CupertinoIcons.gear_alt,
            activeColor: Colors.green,
            onToggle: (value) => _toggleDevice1Compressor(value),
          ),

          if (lastUpdated != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Last updated: ${_formatDateTime(lastUpdated)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDevice1SwitchToggle({
    required String title,
    required String subtitle,
    required bool isOn,
    required IconData icon,
    required Color activeColor,
    required Function(bool) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOn ? activeColor.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOn ? activeColor.withOpacity(0.3) : Colors.grey.shade200,
          width: isOn ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOn ? activeColor.withOpacity(0.2) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isOn ? activeColor : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOn ? activeColor : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isOn ? activeColor.withOpacity(0.8) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: isOn,
              onChanged: _isLoading ? null : onToggle,
              activeColor: activeColor,
              activeTrackColor: activeColor.withOpacity(0.3),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefrostScheduleSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Defrost Schedules',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.cyan),
                  onPressed: () => _showAddDefrostScheduleDialog(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_defrostSchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.snow, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No defrost schedules',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a schedule',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _defrostSchedules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final schedule = _defrostSchedules[index];
                final timesDisplay = schedule.scheduledTimesList.isNotEmpty
                    ? schedule.scheduledTimesList.join(', ')
                    : schedule.scheduledTime ?? 'Not set';
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.snow, color: Colors.cyan, size: 16),
                        Text(
                          '${schedule.timesPerDay}x',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.cyan),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    timesDisplay,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${schedule.scheduleTypeDisplay} • ${schedule.durationMinutes} min${schedule.daysOfWeek != null && schedule.daysOfWeek!.isNotEmpty ? " • ${schedule.daysOfWeek}" : ""}',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteDefrostSchedule(schedule.id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAutomationRulesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(CupertinoIcons.bolt, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Automation Rules',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: () => _showAddAutomationRuleDialog(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_automationRules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.bolt, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No automation rules',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add rules to auto-control compressor',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _automationRules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rule = _automationRules[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: rule.turnCompressorOn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      rule.turnCompressorOn ? CupertinoIcons.play_fill : CupertinoIcons.stop_fill,
                      color: rule.turnCompressorOn ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    rule.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${rule.sensorDisplay} ${rule.triggerType.contains("high") ? ">" : "<"} ${rule.thresholdValue}',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: rule.isActive,
                        onChanged: (v) => _toggleAutomationRule(rule.id, v),
                        activeColor: Colors.green,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _deleteAutomationRule(rule.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddDefrostScheduleDialog() {
    List<TimeOfDay> selectedTimes = [const TimeOfDay(hour: 6, minute: 0)];
    int duration = 15;
    String scheduleType = 'daily';
    Set<String> selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.snow, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Schedule Defrost', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Set automatic defrost cycles', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Schedule Type Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: ['daily', 'weekly'].map((type) {
                            final isSelected = scheduleType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(() => scheduleType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: isSelected ? [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                    ] : null,
                                  ),
                                  child: Text(
                                    type == 'daily' ? 'Daily' : 'Weekly',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.cyan.shade700 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Times Per Day Header
                      Row(
                        children: [
                          Text('Defrost Times', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${selectedTimes.length}x per day',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Time Cards
                      ...selectedTimes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.cyan.shade700),
                                ),
                              ),
                            ),
                            title: Text(
                              time.format(context),
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Tap to change', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                            trailing: selectedTimes.length > 1
                                ? IconButton(
                                    icon: Icon(Icons.remove_circle_rounded, color: Colors.red.shade400, size: 28),
                                    onPressed: () => setDialogState(() => selectedTimes.removeAt(index)),
                                  )
                                : null,
                            onTap: () async {
                              final newTime = await showTimePicker(
                                context: context,
                                initialTime: time,
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(primary: Colors.cyan),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (newTime != null) {
                                setDialogState(() => selectedTimes[index] = newTime);
                              }
                            },
                          ),
                        );
                      }).toList(),

                      // Add Time Button
                      if (selectedTimes.length < 10)
                        GestureDetector(
                          onTap: () => setDialogState(() => selectedTimes.add(const TimeOfDay(hour: 12, minute: 0))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.cyan, style: BorderStyle.solid, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_rounded, color: Colors.cyan.shade600, size: 24),
                                const SizedBox(width: 8),
                                Text('Add Another Time', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.cyan.shade700)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Duration Selector
                      Text('Duration', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [10, 15, 20, 30, 45, 60].map((d) {
                            final isSelected = duration == d;
                            return GestureDetector(
                              onTap: () => setDialogState(() => duration = d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)]) : null,
                                  color: isSelected ? null : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$d min',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Weekly Days Selector
                      if (scheduleType == 'weekly') ...[
                        const SizedBox(height: 24),
                        Text('Days', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
                            final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
                            final day = days[entry.key];
                            final isSelected = selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () => setDialogState(() {
                                if (isSelected) selectedDays.remove(day);
                                else selectedDays.add(day);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)]) : null,
                                  color: isSelected ? null : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _createDefrostSchedule(scheduleType, selectedTimes, duration, selectedDays.toList());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Create Schedule', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
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

  void _showAddAutomationRuleDialog() {
    String name = '';
    String triggerType = 'pressure_high';
    String sensor = 'compressor_high';
    double threshold = 300;
    bool turnOn = false;
    double hysteresis = 5;
    final nameController = TextEditingController();
    final thresholdController = TextEditingController(text: '300');

    final sensorOptions = [
      {'value': 'compressor_high', 'label': 'High Pressure', 'icon': CupertinoIcons.gauge, 'unit': 'PSI'},
      {'value': 'compressor_low', 'label': 'Low Pressure', 'icon': CupertinoIcons.gauge, 'unit': 'PSI'},
      {'value': 'temperature_air', 'label': 'Air Temp', 'icon': CupertinoIcons.thermometer, 'unit': '°C'},
      {'value': 'temperature_coil', 'label': 'Coil Temp', 'icon': CupertinoIcons.thermometer, 'unit': '°C'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Automation Rule', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Auto-control compressor', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rule Name
                      Text('Rule Name', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        onChanged: (v) => name = v,
                        decoration: InputDecoration(
                          hintText: 'e.g., High Pressure Protection',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sensor Selection
                      Text('Monitor Sensor', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: sensorOptions.map((opt) {
                          final isSelected = sensor == opt['value'];
                          return GestureDetector(
                            onTap: () => setDialogState(() {
                              sensor = opt['value'] as String;
                              threshold = sensor.contains('pressure') ? 300 : 5;
                              thresholdController.text = threshold.toString();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]) : null,
                                color: isSelected ? null : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(opt['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      opt['label'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Threshold
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Threshold', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: thresholdController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => threshold = double.tryParse(v) ?? threshold,
                                  decoration: InputDecoration(
                                    suffixText: sensor.contains('pressure') ? 'PSI' : '°C',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Condition', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => triggerType = sensor.contains('pressure') ? 'pressure_high' : 'temp_high'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: triggerType.contains('high') ? Colors.white : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: triggerType.contains('high') ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                                            ),
                                            child: Icon(Icons.arrow_upward, color: triggerType.contains('high') ? Colors.red : Colors.grey, size: 20),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => triggerType = sensor.contains('pressure') ? 'pressure_low' : 'temp_low'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: triggerType.contains('low') ? Colors.white : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: triggerType.contains('low') ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                                            ),
                                            child: Icon(Icons.arrow_downward, color: triggerType.contains('low') ? Colors.blue : Colors.grey, size: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action
                      Text('Action', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => turnOn = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  gradient: turnOn ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF43A047)]) : null,
                                  color: turnOn ? null : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: turnOn ? Colors.transparent : Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(CupertinoIcons.power, color: turnOn ? Colors.white : Colors.grey, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Turn ON', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: turnOn ? Colors.white : Colors.grey.shade700)),
                                    Text('Start compressor', style: GoogleFonts.inter(fontSize: 11, color: turnOn ? Colors.white70 : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => turnOn = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  gradient: !turnOn ? const LinearGradient(colors: [Color(0xFFF44336), Color(0xFFE53935)]) : null,
                                  color: !turnOn ? null : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: !turnOn ? Colors.transparent : Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(CupertinoIcons.stop_fill, color: !turnOn ? Colors.white : Colors.grey, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Turn OFF', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: !turnOn ? Colors.white : Colors.grey.shade700)),
                                    Text('Stop compressor', style: GoogleFonts.inter(fontSize: 11, color: !turnOn ? Colors.white70 : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isEmpty) {
                                _showErrorSnackBar('Please enter a rule name');
                                return;
                              }
                              Navigator.pop(context);
                              _createAutomationRule(nameController.text, triggerType, sensor, threshold, turnOn, hysteresis);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Create Rule', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
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

  Widget _buildDevice1HistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Control History',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_device1ControlHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.clock, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No History Yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _device1ControlHistory.length > 10 ? 10 : _device1ControlHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _device1ControlHistory[index];
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.defrostSwitch ? Colors.cyan : Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.compSwitch ? Colors.green : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      _buildMiniStatusChip('Defrost', item.defrostSwitch, Colors.cyan),
                      const SizedBox(width: 8),
                      _buildMiniStatusChip('Comp', item.compSwitch, Colors.green),
                    ],
                  ),
                  trailing: Text(
                    _formatDateTime(item.receivedAt),
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusChip(String label, bool isOn, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOn ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOn ? activeColor.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? activeColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ${isOn ? "ON" : "OFF"}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isOn ? activeColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DEVICE 5 WIDGETS
  // ============================================

  Widget _buildDevice5ControlCard() {
    if (_selectedDevice == null) return const SizedBox.shrink();

    final onCount = _device5RelayStates.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDevice!.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Relay Controller - $onCount/16 ON',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _isLoading ? null : () => _loadData(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // All ON / All OFF buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _toggleDevice5AllRelays(true),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text('All ON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _toggleDevice5AllRelays(false),
                  icon: const Icon(Icons.flash_off, size: 18),
                  label: const Text('All OFF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-column grid of 16 relay toggle cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final relayNum = index + 1;
              final isOn = _device5RelayStates[relayNum] ?? false;
              return _buildDevice5RelayTile(relayNum, isOn);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDevice5RelayTile(int relayNumber, bool isOn) {
    return Container(
      decoration: BoxDecoration(
        color: isOn ? Colors.indigo.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOn ? Colors.indigo.withOpacity(0.4) : Colors.grey.shade200,
          width: isOn ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'R$relayNumber',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isOn ? Colors.indigo : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isOn ? 'ON' : 'OFF',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isOn ? Colors.green : Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 4),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: isOn,
              onChanged: _isLoading ? null : (val) => _toggleDevice5Relay(relayNumber, val),
              activeColor: Colors.indigo,
              activeTrackColor: Colors.indigo.withOpacity(0.3),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevice5HistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Relay History',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_device5History.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.clock, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No History Yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _device5History.length > 20 ? 20 : _device5History.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _device5History[index];
                final isOn = item['action'] == 'relay_on';
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isOn ? Icons.flash_on : Icons.flash_off,
                      color: isOn ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item['reason'] ?? (isOn ? 'Relay ON' : 'Relay OFF'),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item['performed_by'] ?? 'System',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Text(
                    _formatDateTime(item['timestamp']),
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showDurationDialog() {
    int minutes = 60;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn OFF for Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select how long to turn off the machine:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDurationChip(15, minutes, (v) {
                          setDialogState(() => minutes = v);
                        }),
                        _buildDurationChip(30, minutes, (v) {
                          setDialogState(() => minutes = v);
                        }),
                        _buildDurationChip(60, minutes, (v) {
                          setDialogState(() => minutes = v);
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDurationChip(120, minutes, (v) {
                          setDialogState(() => minutes = v);
                        }),
                        _buildDurationChip(240, minutes, (v) {
                          setDialogState(() => minutes = v);
                        }),
                        _buildDurationChip(480, minutes, (v) {
                          setDialogState(() => minutes = v);
                        }),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleRelay(false, durationMinutes: minutes);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Turn OFF'),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, int selected, Function(int) onSelect) {
    final isSelected = minutes == selected;
    String label;
    if (minutes < 60) {
      label = '${minutes}m';
    } else {
      label = '${minutes ~/ 60}h';
    }
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (s) => onSelect(minutes),
    );
  }

  void _showScheduleDialog() {
    _scheduleType = 'once';
    _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
    _targetRelayStatus = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Schedule Relay Action'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target State:'),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _targetRelayStatus,
                        onChanged: (v) => setDialogState(() => _targetRelayStatus = v!),
                      ),
                      const Text('Turn ON'),
                      const SizedBox(width: 16),
                      Radio<bool>(
                        value: false,
                        groupValue: _targetRelayStatus,
                        onChanged: (v) => setDialogState(() => _targetRelayStatus = v!),
                      ),
                      const Text('Turn OFF'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Schedule Date & Time:'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _scheduledDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_scheduledDateTime),
                        );
                        if (time != null) {
                          setDialogState(() {
                            _scheduledDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy HH:mm').format(_scheduledDateTime)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _createSchedule,
                child: const Text('Create Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecurringDialog() {
    _scheduleType = 'recurring_daily';
    _recurringTime = TimeOfDay.now();
    _targetRelayStatus = false;
    _selectedDays = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Recurring Schedule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target State:'),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _targetRelayStatus,
                        onChanged: (v) => setDialogState(() => _targetRelayStatus = v!),
                      ),
                      const Text('Turn ON'),
                      const SizedBox(width: 16),
                      Radio<bool>(
                        value: false,
                        groupValue: _targetRelayStatus,
                        onChanged: (v) => setDialogState(() => _targetRelayStatus = v!),
                      ),
                      const Text('Turn OFF'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Schedule Type:'),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'recurring_daily',
                        groupValue: _scheduleType,
                        onChanged: (v) => setDialogState(() => _scheduleType = v!),
                      ),
                      const Text('Daily'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'recurring_weekly',
                        groupValue: _scheduleType,
                        onChanged: (v) => setDialogState(() => _scheduleType = v!),
                      ),
                      const Text('Weekly'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Time:'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _recurringTime,
                      );
                      if (time != null) {
                        setDialogState(() => _recurringTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 8),
                          Text(_recurringTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                  if (_scheduleType == 'recurring_weekly') ...[
                    const SizedBox(height: 16),
                    Text('Days:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
                          .map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day.toUpperCase()),
                          selected: isSelected,
                          onSelected: (s) {
                            setDialogState(() {
                              if (s) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _createSchedule,
                child: const Text('Create Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSchedules() {
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Schedules',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: schedule.relayStatus
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                schedule.relayStatus ? Icons.power : Icons.power_off,
                color: schedule.relayStatus ? Colors.green : Colors.red,
              ),
            ),
            title: Text(schedule.scheduleTypeDisplay),
            subtitle: Text(_formatScheduleDetails(schedule)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteSchedule(schedule.id),
            ),
          ),
        );
      },
    );
  }

  String _formatScheduleDetails(RelaySchedule schedule) {
    if (schedule.scheduledDatetime != null) {
      return 'At ${_formatDateTime(schedule.scheduledDatetime)}';
    } else if (schedule.recurringTime != null) {
      if (schedule.recurringDays != null) {
        return '${schedule.recurringTime} on ${schedule.recurringDays}';
      }
      return 'Daily at ${schedule.recurringTime}';
    } else if (schedule.endDatetime != null) {
      return 'Until ${_formatDateTime(schedule.endDatetime)}';
    }
    return 'Created ${_formatDateTime(schedule.createdAt)}';
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.clock,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No History Yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              item.actionDisplay == 'ON' ? Icons.power : Icons.power_off,
              color: item.actionDisplay == 'ON' ? Colors.green : Colors.red,
            ),
            title: Text('Turned ${item.actionDisplay}'),
            subtitle: Text('${item.performedBy} - ${item.reason ?? ''}'),
            trailing: Text(
              _formatDateTime(item.timestamp),
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

// Data models
class DeviceInfo {
  final int id;
  final String deviceId;
  final String name;
  final String deviceType;
  final bool isOnline;
  final bool relayStatus;

  DeviceInfo({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.deviceType,
    required this.isOnline,
    required this.relayStatus,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'],
      deviceId: json['device_id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Device',
      deviceType: json['device_type'] ?? '',
      isOnline: json['is_online'] ?? false,
      relayStatus: json['relay_status'] ?? true,
    );
  }
}

class RelaySchedule {
  final int id;
  final bool relayStatus;
  final String scheduleType;
  final String scheduleTypeDisplay;
  final String? scheduledDatetime;
  final int? durationMinutes;
  final String? endDatetime;
  final String? recurringTime;
  final String? recurringDays;
  final bool isExecuted;
  final bool isActive;
  final String createdAt;

  RelaySchedule({
    required this.id,
    required this.relayStatus,
    required this.scheduleType,
    required this.scheduleTypeDisplay,
    this.scheduledDatetime,
    this.durationMinutes,
    this.endDatetime,
    this.recurringTime,
    this.recurringDays,
    required this.isExecuted,
    required this.isActive,
    required this.createdAt,
  });

  factory RelaySchedule.fromJson(Map<String, dynamic> json) {
    return RelaySchedule(
      id: json['id'],
      relayStatus: json['relay_status'] ?? true,
      scheduleType: json['schedule_type'] ?? '',
      scheduleTypeDisplay: json['schedule_type_display'] ?? '',
      scheduledDatetime: json['scheduled_datetime'],
      durationMinutes: json['duration_minutes'],
      endDatetime: json['end_datetime'],
      recurringTime: json['recurring_time'],
      recurringDays: json['recurring_days'],
      isExecuted: json['is_executed'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class RelayHistoryItem {
  final int id;
  final String action;
  final String actionDisplay;
  final String performedBy;
  final String? reason;
  final String timestamp;

  RelayHistoryItem({
    required this.id,
    required this.action,
    required this.actionDisplay,
    required this.performedBy,
    this.reason,
    required this.timestamp,
  });

  factory RelayHistoryItem.fromJson(Map<String, dynamic> json) {
    return RelayHistoryItem(
      id: json['id'],
      action: json['action'] ?? '',
      actionDisplay: json['action_display'] ?? '',
      performedBy: json['performed_by'] ?? 'System',
      reason: json['reason'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class Device1ControlHistoryItem {
  final int id;
  final bool defrostSwitch;
  final bool compSwitch;
  final String receivedAt;

  Device1ControlHistoryItem({
    required this.id,
    required this.defrostSwitch,
    required this.compSwitch,
    required this.receivedAt,
  });

  factory Device1ControlHistoryItem.fromJson(Map<String, dynamic> json) {
    return Device1ControlHistoryItem(
      id: json['id'],
      defrostSwitch: json['defrost_switch'] ?? false,
      compSwitch: json['comp_switch'] ?? false,
      receivedAt: json['received_at'] ?? '',
    );
  }
}

class DefrostSchedule {
  final int id;
  final String scheduleType;
  final String scheduleTypeDisplay;
  final int timesPerDay;
  final String? scheduledTimes;
  final List<String> scheduledTimesList;
  final String? scheduledTime;
  final String? scheduledDatetime;
  final int durationMinutes;
  final String? daysOfWeek;
  final bool isActive;
  final String? lastExecutedAt;

  DefrostSchedule({
    required this.id,
    required this.scheduleType,
    required this.scheduleTypeDisplay,
    required this.timesPerDay,
    this.scheduledTimes,
    required this.scheduledTimesList,
    this.scheduledTime,
    this.scheduledDatetime,
    required this.durationMinutes,
    this.daysOfWeek,
    required this.isActive,
    this.lastExecutedAt,
  });

  factory DefrostSchedule.fromJson(Map<String, dynamic> json) {
    return DefrostSchedule(
      id: json['id'],
      scheduleType: json['schedule_type'] ?? 'daily',
      scheduleTypeDisplay: json['schedule_type_display'] ?? 'Daily',
      timesPerDay: json['times_per_day'] ?? 1,
      scheduledTimes: json['scheduled_times'],
      scheduledTimesList: json['scheduled_times_list'] != null
          ? List<String>.from(json['scheduled_times_list'])
          : [],
      scheduledTime: json['scheduled_time'],
      scheduledDatetime: json['scheduled_datetime'],
      durationMinutes: json['duration_minutes'] ?? 15,
      daysOfWeek: json['days_of_week'],
      isActive: json['is_active'] ?? true,
      lastExecutedAt: json['last_executed_at'],
    );
  }
}

class AutomationRule {
  final int id;
  final String name;
  final String triggerType;
  final String triggerTypeDisplay;
  final String sensor;
  final String sensorDisplay;
  final double thresholdValue;
  final bool turnCompressorOn;
  final double hysteresis;
  final int delaySeconds;
  final bool isActive;
  final String? lastTriggeredAt;
  final int triggerCount;

  AutomationRule({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.triggerTypeDisplay,
    required this.sensor,
    required this.sensorDisplay,
    required this.thresholdValue,
    required this.turnCompressorOn,
    required this.hysteresis,
    required this.delaySeconds,
    required this.isActive,
    this.lastTriggeredAt,
    required this.triggerCount,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'],
      name: json['name'] ?? '',
      triggerType: json['trigger_type'] ?? '',
      triggerTypeDisplay: json['trigger_type_display'] ?? '',
      sensor: json['sensor'] ?? '',
      sensorDisplay: json['sensor_display'] ?? '',
      thresholdValue: (json['threshold_value'] ?? 0).toDouble(),
      turnCompressorOn: json['turn_compressor_on'] ?? false,
      hysteresis: (json['hysteresis'] ?? 5).toDouble(),
      delaySeconds: json['delay_seconds'] ?? 30,
      isActive: json['is_active'] ?? true,
      lastTriggeredAt: json['last_triggered_at'],
      triggerCount: json['trigger_count'] ?? 0,
    );
  }
}
