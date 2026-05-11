import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appName = 'BACHELIER JEAN LUC';
const bool defaultScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  runApp(const BachelierApp());
}

class BachelierApp extends StatefulWidget {
  const BachelierApp({super.key, this.screenshotMode = defaultScreenshotMode});

  final bool screenshotMode;

  @override
  State<BachelierApp> createState() => _BachelierAppState();
}

class _BachelierAppState extends State<BachelierApp> {
  late final Future<AppController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _loadController();
  }

  Future<AppController> _loadController() async {
    final preferences = widget.screenshotMode
        ? null
        : await SharedPreferences.getInstance();
    final controller = AppController(
      preferences: preferences,
      screenshotMode: widget.screenshotMode,
    );
    await controller.load();
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7BA0),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF355C7D),
          onPrimary: Colors.white,
          secondary: const Color(0xFFD65F0D),
          onSecondary: Colors.white,
          tertiary: const Color(0xFF2F7D73),
          surface: const Color(0xFFFBFAF7),
          surfaceContainerHighest: const Color(0xFFE9EEF2),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF7F4EF),
          foregroundColor: Color(0xFF17212F),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E7ED)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: FutureBuilder<AppController>(
        future: _controllerFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingScreen();
          }
          return HomeShell(controller: snapshot.data!);
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

enum RecordType { attendance, patient, maintenance, shipment }

extension RecordTypeMeta on RecordType {
  String get title => switch (this) {
    RecordType.attendance => 'Attendance',
    RecordType.patient => 'Patients',
    RecordType.maintenance => 'Maintenance',
    RecordType.shipment => 'Shipments',
  };

  String get singular => switch (this) {
    RecordType.attendance => 'attendance log',
    RecordType.patient => 'patient record',
    RecordType.maintenance => 'maintenance request',
    RecordType.shipment => 'shipment entry',
  };

  String get titleField => switch (this) {
    RecordType.attendance => 'Staff member or team',
    RecordType.patient => 'Patient or case reference',
    RecordType.maintenance => 'Request title',
    RecordType.shipment => 'Shipment reference',
  };

  String get ownerField => switch (this) {
    RecordType.attendance => 'Shift or department',
    RecordType.patient => 'Responsible staff',
    RecordType.maintenance => 'Assigned technician',
    RecordType.shipment => 'Carrier or route',
  };

  String get detailField => switch (this) {
    RecordType.attendance => 'Shift notes',
    RecordType.patient => 'Visit notes',
    RecordType.maintenance => 'Issue details',
    RecordType.shipment => 'Shipment contents',
  };

  IconData get icon => switch (this) {
    RecordType.attendance => Icons.fact_check_outlined,
    RecordType.patient => Icons.assignment_ind_outlined,
    RecordType.maintenance => Icons.handyman_outlined,
    RecordType.shipment => Icons.local_shipping_outlined,
  };
}

RecordType recordTypeFromName(String value) {
  return RecordType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => RecordType.attendance,
  );
}

List<String> statusOptionsFor(RecordType type) => switch (type) {
  RecordType.attendance => ['Scheduled', 'Checked in', 'Checked out'],
  RecordType.patient => ['Waiting', 'In service', 'Released'],
  RecordType.maintenance => ['Open', 'In progress', 'Resolved'],
  RecordType.shipment => ['Prepared', 'In transit', 'Delivered'],
};

class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.details,
    required this.status,
    required this.priority,
    required this.targetDate,
    required this.createdAt,
  });

  final String id;
  final RecordType type;
  final String title;
  final String owner;
  final String details;
  final String status;
  final String priority;
  final String targetDate;
  final DateTime createdAt;

  bool get isClosed {
    return status == 'Checked out' ||
        status == 'Released' ||
        status == 'Resolved' ||
        status == 'Delivered';
  }

  OperationRecord copyWith({
    RecordType? type,
    String? title,
    String? owner,
    String? details,
    String? status,
    String? priority,
    String? targetDate,
  }) {
    return OperationRecord(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      details: details ?? this.details,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'owner': owner,
      'details': details,
      'status': status,
      'priority': priority,
      'targetDate': targetDate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OperationRecord.fromJson(Map<String, Object?> json) {
    return OperationRecord(
      id:
          json['id'] as String? ??
          'record-${DateTime.now().microsecondsSinceEpoch}',
      type: recordTypeFromName(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? 'Untitled record',
      owner: json['owner'] as String? ?? 'Unassigned',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'Normal',
      targetDate: json['targetDate'] as String? ?? 'Today',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AppController extends ChangeNotifier {
  AppController({required this.preferences, required this.screenshotMode});

  final SharedPreferences? preferences;
  final bool screenshotMode;

  static const _recordsKey = 'records_v1';
  static const _siteNameKey = 'site_name_v1';
  static const _closedNotesKey = 'closed_notes_v1';
  static const _compactRowsKey = 'compact_rows_v1';

  List<OperationRecord> _records = <OperationRecord>[];
  String _siteName = 'Main office';
  bool _closedNotesRequired = true;
  bool _compactRows = false;

  List<OperationRecord> get records => List.unmodifiable(_records);
  String get siteName => _siteName;
  bool get closedNotesRequired => _closedNotesRequired;
  bool get compactRows => _compactRows;

  Future<void> load() async {
    if (screenshotMode) {
      _records = sampleRecords();
      _siteName = 'Operations desk';
      _closedNotesRequired = true;
      _compactRows = false;
      return;
    }

    final rawRecords = preferences?.getString(_recordsKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      _records = starterRecords();
    } else {
      final decoded = jsonDecode(rawRecords) as List<dynamic>;
      _records = decoded
          .whereType<Map<String, dynamic>>()
          .map(OperationRecord.fromJson)
          .toList();
    }
    _siteName = preferences?.getString(_siteNameKey) ?? 'Main office';
    _closedNotesRequired = preferences?.getBool(_closedNotesKey) ?? true;
    _compactRows = preferences?.getBool(_compactRowsKey) ?? false;
  }

  List<OperationRecord> recordsFor(RecordType type) {
    return _records.where((record) => record.type == type).toList();
  }

  int openCountFor(RecordType type) {
    return recordsFor(type).where((record) => !record.isClosed).length;
  }

  int get openCount => _records.where((record) => !record.isClosed).length;

  List<OperationRecord> get urgentRecords {
    return _records
        .where((record) => record.priority == 'High' && !record.isClosed)
        .take(6)
        .toList();
  }

  Future<void> upsertRecord(OperationRecord record) async {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      _records = [record, ..._records];
    } else {
      _records = [..._records]..[index] = record;
    }
    await _saveRecords();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    _records = _records.where((record) => record.id != id).toList();
    await _saveRecords();
    notifyListeners();
  }

  Future<void> advanceStatus(OperationRecord record) async {
    final statuses = statusOptionsFor(record.type);
    final currentIndex = statuses.indexOf(record.status);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1).clamp(0, statuses.length - 1);
    await upsertRecord(record.copyWith(status: statuses[nextIndex]));
  }

  Future<void> updateSiteName(String value) async {
    _siteName = value.trim().isEmpty ? 'Main office' : value.trim();
    if (!screenshotMode) {
      await preferences?.setString(_siteNameKey, _siteName);
    }
    notifyListeners();
  }

  Future<void> updateClosedNotesRequired(bool value) async {
    _closedNotesRequired = value;
    if (!screenshotMode) {
      await preferences?.setBool(_closedNotesKey, value);
    }
    notifyListeners();
  }

  Future<void> updateCompactRows(bool value) async {
    _compactRows = value;
    if (!screenshotMode) {
      await preferences?.setBool(_compactRowsKey, value);
    }
    notifyListeners();
  }

  Future<void> clearLocalRecords() async {
    _records = <OperationRecord>[];
    await _saveRecords();
    notifyListeners();
  }

  Future<void> _saveRecords() async {
    if (screenshotMode) {
      return;
    }
    await preferences?.setString(
      _recordsKey,
      jsonEncode(_records.map((record) => record.toJson()).toList()),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(appName),
                Text(
                  widget.controller.siteName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardTab(controller: widget.controller),
              LogsTab(controller: widget.controller),
              MaintenanceTab(controller: widget.controller),
              ShipmentsTab(controller: widget.controller),
              SettingsTab(controller: widget.controller),
            ],
          ),
          floatingActionButton: _selectedIndex == 4
              ? null
              : FloatingActionButton.extended(
                  key: const ValueKey('add-record'),
                  onPressed: () => showRecordSheet(
                    context,
                    controller: widget.controller,
                    type: _typeForCurrentTab(),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('New record'),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                key: ValueKey('nav-today'),
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Today',
              ),
              NavigationDestination(
                key: ValueKey('nav-logs'),
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Logs',
              ),
              NavigationDestination(
                key: ValueKey('nav-work'),
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: 'Work',
              ),
              NavigationDestination(
                key: ValueKey('nav-shipments'),
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: 'Shipments',
              ),
              NavigationDestination(
                key: ValueKey('nav-settings'),
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  RecordType _typeForCurrentTab() {
    return switch (_selectedIndex) {
      1 => RecordType.attendance,
      2 => RecordType.maintenance,
      3 => RecordType.shipment,
      _ => RecordType.patient,
    };
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = controller.urgentRecords;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        MetricCard(
          label: 'Open items',
          value: controller.openCount.toString(),
          icon: Icons.timelapse_outlined,
        ),
        const SizedBox(height: 10),
        MetricCard(
          label: 'High priority',
          value: urgent.length.toString(),
          icon: Icons.priority_high_outlined,
        ),
        const SizedBox(height: 10),
        MetricCard(
          label: 'Patients',
          value: controller.openCountFor(RecordType.patient).toString(),
          icon: RecordType.patient.icon,
        ),
        const SizedBox(height: 10),
        MetricCard(
          label: 'Shipments',
          value: controller.openCountFor(RecordType.shipment).toString(),
          icon: RecordType.shipment.icon,
        ),
        const SizedBox(height: 20),
        Text('Priority board', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (urgent.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No high priority items',
            message: 'New records marked high priority will appear here.',
          )
        else
          ...urgent.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                record: record,
                compact: controller.compactRows,
                onTap: () => openDetail(context, controller, record),
              ),
            ),
          ),
        const SizedBox(height: 14),
        Text('Quick capture', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: RecordType.values
              .map(
                (type) => FilledButton.tonalIcon(
                  onPressed: () => showRecordSheet(
                    context,
                    controller: controller,
                    type: type,
                  ),
                  icon: Icon(type.icon),
                  label: Text(type.title),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              foregroundColor: colorScheme.primary,
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class LogsTab extends StatefulWidget {
  const LogsTab({super.key, required this.controller});

  final AppController controller;

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  RecordType _selectedType = RecordType.attendance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<RecordType>(
            segments: const [
              ButtonSegment(
                value: RecordType.attendance,
                icon: Icon(Icons.fact_check_outlined),
                label: Text('Attendance'),
              ),
              ButtonSegment(
                value: RecordType.patient,
                icon: Icon(Icons.assignment_ind_outlined),
                label: Text('Patients'),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (value) {
              setState(() => _selectedType = value.first);
            },
          ),
        ),
        Expanded(
          child: OperationsList(
            controller: widget.controller,
            type: _selectedType,
          ),
        ),
      ],
    );
  }
}

class MaintenanceTab extends StatelessWidget {
  const MaintenanceTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return OperationsList(controller: controller, type: RecordType.maintenance);
  }
}

class ShipmentsTab extends StatelessWidget {
  const ShipmentsTab({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return OperationsList(controller: controller, type: RecordType.shipment);
  }
}

class OperationsList extends StatelessWidget {
  const OperationsList({
    super.key,
    required this.controller,
    required this.type,
  });

  final AppController controller;
  final RecordType type;

  @override
  Widget build(BuildContext context) {
    final records = controller.recordsFor(type);
    if (records.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        children: [
          EmptyState(
            icon: type.icon,
            title: 'No ${type.title.toLowerCase()} yet',
            message: 'Add a ${type.singular} to keep this work stream current.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RecordCard(
            record: record,
            compact: controller.compactRows,
            onTap: () => openDetail(context, controller, record),
          ),
        );
      },
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.record,
    required this.compact,
    required this.onTap,
  });

  final OperationRecord record;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _typeColor(
                  record.type,
                  colorScheme,
                ).withValues(alpha: 0.14),
                foregroundColor: _typeColor(record.type, colorScheme),
                child: Icon(record.type.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        PriorityPill(priority: record.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.owner} - ${record.targetDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusPill(
                            status: record.status,
                            closed: record.isClosed,
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PriorityPill extends StatelessWidget {
  const PriorityPill({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'High' => const Color(0xFFB42318),
      'Low' => const Color(0xFF2F7D73),
      _ => const Color(0xFF596678),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.closed});

  final String status;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final color = closed
        ? const Color(0xFF2F7D73)
        : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _siteController;

  @override
  void initState() {
    super.initState();
    _siteController = TextEditingController(text: widget.controller.siteName);
  }

  @override
  void dispose() {
    _siteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _siteController,
                  decoration: const InputDecoration(
                    labelText: 'Site name',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: controller.updateSiteName,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      controller.updateSiteName(_siteController.text),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save workspace'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Require closing notes'),
                subtitle: const Text(
                  'Keep handoffs complete before records are closed.',
                ),
                value: controller.closedNotesRequired,
                onChanged: controller.updateClosedNotesRequired,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Compact record rows'),
                subtitle: const Text(
                  'Show more operations records on each screen.',
                ),
                value: controller.compactRows,
                onChanged: controller.updateCompactRows,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Records stay on this device. The app does not require an account, cloud sync, analytics, advertising identifiers, or Android permissions.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.records.isEmpty
                      ? null
                      : controller.clearLocalRecords,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear local records'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showRecordSheet(
  BuildContext context, {
  required AppController controller,
  required RecordType type,
  OperationRecord? record,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return RecordEditorSheet(
        controller: controller,
        initialType: type,
        record: record,
      );
    },
  );
}

class RecordEditorSheet extends StatefulWidget {
  const RecordEditorSheet({
    super.key,
    required this.controller,
    required this.initialType,
    this.record,
  });

  final AppController controller;
  final RecordType initialType;
  final OperationRecord? record;

  @override
  State<RecordEditorSheet> createState() => _RecordEditorSheetState();
}

class _RecordEditorSheetState extends State<RecordEditorSheet> {
  late RecordType _type;
  late String _status;
  late String _priority;
  late final TextEditingController _titleController;
  late final TextEditingController _ownerController;
  late final TextEditingController _detailsController;
  late final TextEditingController _targetDateController;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? widget.initialType;
    _status = record?.status ?? statusOptionsFor(_type).first;
    _priority = record?.priority ?? 'Normal';
    _titleController = TextEditingController(text: record?.title ?? '');
    _ownerController = TextEditingController(text: record?.owner ?? '');
    _detailsController = TextEditingController(text: record?.details ?? '');
    _targetDateController = TextEditingController(
      text: record?.targetDate ?? formatDate(DateTime.now()),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _detailsController.dispose();
    _targetDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.record == null
                        ? 'New ${_type.singular}'
                        : 'Edit ${_type.singular}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RecordType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Work stream',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: RecordType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.title)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _type = value;
                  _status = statusOptionsFor(_type).first;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('field-title'),
              controller: _titleController,
              decoration: InputDecoration(labelText: _type.titleField),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('field-owner'),
              controller: _ownerController,
              decoration: InputDecoration(labelText: _type.ownerField),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetDateController,
              decoration: const InputDecoration(
                labelText: 'Target date',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statusOptionsFor(_type)
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['Low', 'Normal', 'High']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('field-details'),
              controller: _detailsController,
              decoration: InputDecoration(labelText: _type.detailField),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title before saving.')),
      );
      return;
    }
    final existing = widget.record;
    final record = OperationRecord(
      id: existing?.id ?? 'record-${DateTime.now().microsecondsSinceEpoch}',
      type: _type,
      title: title,
      owner: _ownerController.text.trim().isEmpty
          ? 'Unassigned'
          : _ownerController.text.trim(),
      details: _detailsController.text.trim(),
      status: _status,
      priority: _priority,
      targetDate: _targetDateController.text.trim().isEmpty
          ? formatDate(DateTime.now())
          : _targetDateController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await widget.controller.upsertRecord(record);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

void openDetail(
  BuildContext context,
  AppController controller,
  OperationRecord record,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetailScreen(controller: controller, recordId: record.id),
    ),
  );
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.controller,
    required this.recordId,
  });

  final AppController controller;
  final String recordId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final record = controller.records.firstWhere(
          (item) => item.id == recordId,
          orElse: () => controller.records.first,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(record.type.title),
            actions: [
              IconButton(
                onPressed: () => showRecordSheet(
                  context,
                  controller: controller,
                  type: record.type,
                  record: record,
                ),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _typeColor(
                              record.type,
                              Theme.of(context).colorScheme,
                            ).withValues(alpha: 0.14),
                            foregroundColor: _typeColor(
                              record.type,
                              Theme.of(context).colorScheme,
                            ),
                            child: Icon(record.type.icon),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              record.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusPill(
                            status: record.status,
                            closed: record.isClosed,
                          ),
                          PriorityPill(priority: record.priority),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DetailLine(
                        label: record.type.ownerField,
                        value: record.owner,
                      ),
                      DetailLine(
                        label: 'Target date',
                        value: record.targetDate,
                      ),
                      DetailLine(
                        label: 'Created',
                        value: formatDate(record.createdAt),
                      ),
                      const Divider(height: 28),
                      Text(
                        record.type.detailField,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.details.isEmpty
                            ? 'No additional details recorded.'
                            : record.details,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: record.isClosed
                    ? null
                    : () => controller.advanceStatus(record),
                icon: const Icon(Icons.trending_flat),
                label: Text(
                  record.isClosed ? 'Status complete' : 'Advance status',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await controller.deleteRecord(record.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete record'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

Color _typeColor(RecordType type, ColorScheme colorScheme) => switch (type) {
  RecordType.attendance => colorScheme.primary,
  RecordType.patient => const Color(0xFF2F7D73),
  RecordType.maintenance => colorScheme.secondary,
  RecordType.shipment => const Color(0xFF6E4CA4),
};

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

List<OperationRecord> starterRecords() {
  final now = DateTime.now();
  return [
    OperationRecord(
      id: 'starter-attendance',
      type: RecordType.attendance,
      title: 'Morning reception team',
      owner: 'Front office',
      details: 'Track arrivals and late handoffs before the lunch changeover.',
      status: 'Checked in',
      priority: 'Normal',
      targetDate: formatDate(now),
      createdAt: now.subtract(const Duration(hours: 4)),
    ),
    OperationRecord(
      id: 'starter-maintenance',
      type: RecordType.maintenance,
      title: 'Sterile storage cabinet',
      owner: 'Facilities',
      details: 'Door gasket needs inspection before end of day.',
      status: 'Open',
      priority: 'High',
      targetDate: formatDate(now),
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
  ];
}

List<OperationRecord> sampleRecords() {
  final base = DateTime(2026, 5, 11, 9);
  return [
    OperationRecord(
      id: 'sample-1',
      type: RecordType.attendance,
      title: 'Morning clinical team',
      owner: 'North desk',
      details:
          'Seven staff checked in. One replacement needed for late afternoon intake.',
      status: 'Checked in',
      priority: 'High',
      targetDate: 'May 11, 2026',
      createdAt: base,
    ),
    OperationRecord(
      id: 'sample-2',
      type: RecordType.attendance,
      title: 'Evening intake desk',
      owner: 'South desk',
      details:
          'Coverage confirmed for reception and intake. Night handoff pending.',
      status: 'Scheduled',
      priority: 'Normal',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(minutes: 12)),
    ),
    OperationRecord(
      id: 'sample-3',
      type: RecordType.patient,
      title: 'Case BL-204',
      owner: 'J. Martin',
      details:
          'Admission paperwork complete. Waiting for final discharge review.',
      status: 'In service',
      priority: 'High',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(minutes: 20)),
    ),
    OperationRecord(
      id: 'sample-4',
      type: RecordType.patient,
      title: 'Case BL-207',
      owner: 'M. Garnier',
      details: 'Lab packet received. Waiting for physician review.',
      status: 'Waiting',
      priority: 'Normal',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(minutes: 28)),
    ),
    OperationRecord(
      id: 'sample-5',
      type: RecordType.maintenance,
      title: 'Cold room sensor check',
      owner: 'Facilities',
      details:
          'Temperature variance flagged during morning review. Verify sensor and seal.',
      status: 'In progress',
      priority: 'High',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(minutes: 40)),
    ),
    OperationRecord(
      id: 'sample-6',
      type: RecordType.maintenance,
      title: 'Reception printer queue',
      owner: 'IT support',
      details: 'Clear stalled labels and confirm print station is ready.',
      status: 'Open',
      priority: 'Normal',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(minutes: 52)),
    ),
    OperationRecord(
      id: 'sample-7',
      type: RecordType.maintenance,
      title: 'Lift inspection note',
      owner: 'Building team',
      details: 'Inspection vendor requested access confirmation before noon.',
      status: 'Resolved',
      priority: 'Low',
      targetDate: 'May 10, 2026',
      createdAt: base.subtract(const Duration(hours: 2)),
    ),
    OperationRecord(
      id: 'sample-8',
      type: RecordType.shipment,
      title: 'Shipment JL-8842',
      owner: 'Route C',
      details:
          'Documents packed. Driver confirmed pickup window between 14:00 and 15:00.',
      status: 'Prepared',
      priority: 'Normal',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(hours: 1)),
    ),
    OperationRecord(
      id: 'sample-9',
      type: RecordType.patient,
      title: 'Case BL-208',
      owner: 'A. Legrand',
      details: 'Follow-up call completed and notes attached to local handoff.',
      status: 'Released',
      priority: 'Low',
      targetDate: 'May 10, 2026',
      createdAt: base.subtract(const Duration(days: 1)),
    ),
    OperationRecord(
      id: 'sample-10',
      type: RecordType.shipment,
      title: 'Supply return SR-19',
      owner: 'Central depot',
      details: 'Return crates labelled and ready for the evening collection.',
      status: 'In transit',
      priority: 'High',
      targetDate: 'May 12, 2026',
      createdAt: base.add(const Duration(hours: 2)),
    ),
    OperationRecord(
      id: 'sample-11',
      type: RecordType.shipment,
      title: 'Lab courier LC-53',
      owner: 'Route A',
      details: 'Courier checked in. Cold-pack chain verified at dispatch.',
      status: 'Delivered',
      priority: 'Low',
      targetDate: 'May 11, 2026',
      createdAt: base.add(const Duration(hours: 3)),
    ),
  ];
}
