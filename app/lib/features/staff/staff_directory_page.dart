import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/employee_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/services.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/logger.dart';
import '../../core/responsive.dart';

const int _pageSize = 20;

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});
  @override
  ConsumerState<StaffDirectoryScreen> createState() =>
      _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Employee> _allEmployees = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  Timer? _debounce;
  Set<String> _roleFilters = {};
  Set<String> _wageFilters = {};
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetch();
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        !_loading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
      _allEmployees = [];
    });
    try {
      final staffService = ref.read(staffServiceProvider);
      final employees = await staffService.list(
        limit: _pageSize,
        offset: 0,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _allEmployees = employees;
          _offset = employees.length;
          _hasMore = employees.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    unawaited(HapticFeedback.lightImpact());
    setState(() => _loadingMore = true);
    try {
      final staffService = ref.read(staffServiceProvider);
      final employees = await staffService.list(
        limit: _pageSize,
        offset: _offset,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _allEmployees.addAll(employees);
          _offset = _allEmployees.length;
          _hasMore = employees.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('Staff load-more failed', e, st);
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    await _fetch();
  }

  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _fetch();
    });
  }

  Future<void> _openFilters() async {
    unawaited(HapticFeedback.selectionClick());
    final result = await showAdaptiveSheet<_FilterResult>(
      context: context,
      builder: (ctx) => _FilterSheet(
        roleFilters: _roleFilters,
        wageFilters: _wageFilters,
        showInactive: _showInactive,
        onApply: (roles, wages, showInactive) =>
            Navigator.pop(ctx, _FilterResult(roles, wages, showInactive)),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _roleFilters = result.roles;
      _wageFilters = result.wages;
      _showInactive = result.showInactive;
    });
  }

  List<Employee> get _filtered {
    final filtered = _allEmployees.where((e) {
      if (_roleFilters.isNotEmpty && !_roleFilters.contains(e.role)) {
        return false;
      }
      if (_wageFilters.isNotEmpty && !_wageFilters.contains(e.wageType)) {
        return false;
      }
      if (!_showInactive && !e.isActive) return false;
      return true;
    }).toList();
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;
    final grouped = _groupByLetter(_filtered);
    final hasActiveFilters =
        _roleFilters.isNotEmpty || _wageFilters.isNotEmpty || _showInactive;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        color: cs.primary,
        backgroundColor: cs.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: AppScrollPhysics.physics(
            parent: const AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(
                alpha: 0.85,
              ),
              pinned: true,
              elevation: 0,
              expandedHeight: 140,
              collapsedHeight: 70,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    title: Text(
                      'Directory',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    background: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 64),
                        child: _PremiumSearchBar(
                          cs: cs,
                          focusNode: _searchFocus,
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        PhosphorIconsRegular.slidersHorizontal,
                        color: hasActiveFilters
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      onPressed: _openFilters,
                    ),
                    if (hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            if (_loading)
              const ShimmerLoading(itemCount: 8, height: 82)
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsDuotone.warningCircle,
                        size: 48,
                        color: cs.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load staff',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$_error',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _fetch,
                        icon: const Icon(
                          PhosphorIconsFill.arrowClockwise,
                          size: 18,
                        ),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_filtered.isEmpty)
                SliverFillRemaining(
                  child: _EmptySearchState(
                    cs: cs,
                    tt: tt,
                    isSearching: _searchQuery.isNotEmpty,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final letter = grouped.keys.elementAt(index);
                      final staffList = grouped[letter]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                            child: Text(
                              letter,
                              style: tt.titleSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          ...List.generate(staffList.length, (i) {
                            return FluidSlideIn(
                              delay: (index * 20 + i * 50)
                                  .clamp(0, 400)
                                  .toInt(),
                              child: _StaffDirectoryTile(
                                cs: cs,
                                tt: tt,
                                employee: staffList[i],
                              ),
                            );
                          }),
                        ],
                      );
                    }, childCount: grouped.keys.length),
                  ),
                ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'staff_directory_fab',
              onPressed: () async {
                unawaited(HapticFeedback.heavyImpact());
                final result = await context.push<bool>('/add_employee');
                if (result == true && mounted) unawaited(_fetch());
              },
              backgroundColor: cs.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(PhosphorIconsBold.userPlus, color: cs.onPrimary),
            )
          : null,
    );
  }

  Map<String, List<Employee>> _groupByLetter(List<Employee> employees) {
    final map = <String, List<Employee>>{};
    for (final e in employees) {
      final letter = e.name.isNotEmpty ? e.name[0].toUpperCase() : '#';
      map.putIfAbsent(letter, () => []).add(e);
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in sorted) e.key: e.value};
  }
}

class _PremiumSearchBar extends StatefulWidget {
  final ColorScheme cs;
  final ValueChanged<String> onChanged;
  final FocusNode focusNode;
  final TextEditingController controller;

  const _PremiumSearchBar({
    required this.cs,
    required this.onChanged,
    required this.focusNode,
    required this.controller,
  });

  @override
  State<_PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<_PremiumSearchBar> {
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
    widget.controller.addListener(() {
      final hasTextNow = widget.controller.text.isNotEmpty;
      if (_hasText != hasTextNow) {
        setState(() => _hasText = hasTextNow);
      }
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(() {});
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCirc,
      height: 52,
      decoration: BoxDecoration(
        color: _isFocused
            ? widget.cs.surface
            : widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? widget.cs.primary.withValues(alpha: 0.5)
              : widget.cs.outlineVariant.withValues(alpha: 0.3),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: widget.cs.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textInputAction: TextInputAction.search,
        cursorColor: widget.cs.primary,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: widget.cs.onSurface,
          letterSpacing: -0.3,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or role...',
          hintStyle: TextStyle(
            color: widget.cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            PhosphorIconsRegular.magnifyingGlass,
            color: _isFocused ? widget.cs.primary : widget.cs.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: AnimatedScale(
            scale: _hasText ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _hasText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: Icon(
                  PhosphorIconsFill.xCircle,
                  size: 18,
                  color: widget.cs.onSurfaceVariant,
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {
                  if (!_hasText) return;
                  HapticFeedback.lightImpact();
                  widget.controller.clear();
                  widget.onChanged('');
                  widget.focusNode.unfocus();
                },
              ),
            ),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _StaffDirectoryTile extends ConsumerWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Employee employee;

  const _StaffDirectoryTile({
    required this.cs,
    required this.tt,
    required this.employee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDaily = employee.wageType == 'daily';
    final typeColor = isDaily
        ? const Color(0xFF10B981)
        : const Color(0xFF3B82F6);
    final wageText = employee.wageAmount > 0
        ? '\u20B9${employee.wageAmount.toStringAsFixed(0)}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/employee/${employee.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                EmployeeAvatar(
                  name: employee.name,
                  photoUrl: employee.photoUrl,
                  radius: 26,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                  textColor: cs.primary,
                  fontSize: 14,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.designation ?? employee.role,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wageText,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDaily ? 'DAILY' : 'MONTHLY',
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final bool isSearching;

  const _EmptySearchState({
    required this.cs,
    required this.tt,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              isSearching
                  ? PhosphorIconsDuotone.magnifyingGlass
                  : PhosphorIconsDuotone.usersThree,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No matches found' : 'No staff members yet',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try checking for typos or use a different term.'
                : 'Tap the + button to onboard your first employee.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  final Set<String> roles;
  final Set<String> wages;
  final bool showInactive;
  _FilterResult(this.roles, this.wages, this.showInactive);
}

class _FilterSheet extends StatefulWidget {
  final Set<String> roleFilters;
  final Set<String> wageFilters;
  final bool showInactive;
  final void Function(Set<String> roles, Set<String> wages, bool showInactive)
  onApply;

  const _FilterSheet({
    required this.roleFilters,
    required this.wageFilters,
    required this.showInactive,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _roles;
  late Set<String> _wages;
  late bool _inactive;

  @override
  void initState() {
    super.initState();
    _roles = Set.of(widget.roleFilters);
    _wages = Set.of(widget.wageFilters);
    _inactive = widget.showInactive;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'FILTER BY ROLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['employee', 'supervisor'].map((role) {
                final selected = _roles.contains(role);
                return FilterChip(
                  label: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  selected: selected,
                  selectedColor: cs.primaryContainer.withValues(alpha: 0.4),
                  checkmarkColor: cs.primary,
                  side: BorderSide(
                    color: selected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  onSelected: (v) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (v) {
                        _roles.add(role);
                      } else {
                        _roles.remove(role);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'FILTER BY WAGE TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['daily', 'monthly'].map((type) {
                final selected = _wages.contains(type);
                return FilterChip(
                  label: Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  selected: selected,
                  selectedColor: cs.primaryContainer.withValues(alpha: 0.4),
                  checkmarkColor: cs.primary,
                  side: BorderSide(
                    color: selected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  onSelected: (v) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (v) {
                        _wages.add(type);
                      } else {
                        _wages.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Show Inactive',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: _inactive,
                  onChanged: (v) => setState(() => _inactive = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onApply({}, {}, false);
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onApply(_roles, _wages, _inactive);
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
