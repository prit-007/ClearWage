import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/employee_model.dart';
import '../../providers/providers.dart';
import '../../core/app_config.dart';
import 'employee_profile_page.dart';
import 'add_employee_page.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/helpers.dart';

const int _pageSize = 20;

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});
  @override
  ConsumerState<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  String _searchQuery = '';
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  List<Employee> _allEmployees = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore && _hasMore && _searchQuery.isEmpty) {
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
      final employees = await staffService.list(limit: _pageSize, offset: 0);
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
    if (_loadingMore || !_hasMore) return;
    HapticFeedback.lightImpact();
    setState(() => _loadingMore = true);
    try {
      final staffService = ref.read(staffServiceProvider);
      final employees = await staffService.list(limit: _pageSize, offset: _offset);
      if (mounted) {
        setState(() {
          _allEmployees.addAll(employees);
          _offset = _allEmployees.length;
          _hasMore = employees.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _fetch();
  }

  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v.toLowerCase());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (v.isNotEmpty && _allEmployees.length < 100) {
        _fetchAllForSearch();
      }
    });
  }

  Future<void> _fetchAllForSearch() async {
    try {
      final staffService = ref.read(staffServiceProvider);
      final employees = await staffService.list(limit: 100000, offset: 0);
      if (mounted) {
        setState(() {
          _allEmployees = employees;
          _hasMore = false;
        });
      }
    } catch (_) {}
  }

  List<Employee> get _filtered {
    if (_searchQuery.isEmpty) return _allEmployees;
    return _allEmployees
        .where((e) =>
            e.name.toLowerCase().contains(_searchQuery) ||
            (e.designation?.toLowerCase().contains(_searchQuery) ?? false) ||
            e.role.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        color: cs.primary,
        backgroundColor: cs.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.85),
              pinned: true,
              elevation: 0,
              expandedHeight: 140,
              collapsedHeight: 70,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    title: Text('Directory', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                    background: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 64),
                        child: _PremiumSearchBar(
                          cs: cs,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(PhosphorIconsRegular.slidersHorizontal, color: cs.onSurfaceVariant),
                  onPressed: () => HapticFeedback.selectionClick(),
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
                      PhosphorIcon(PhosphorIconsDuotone.warningCircle, size: 48, color: cs.error),
                      const SizedBox(height: 16),
                      Text('Failed to load staff', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text('$_error', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _fetch,
                        icon: const Icon(PhosphorIconsFill.arrowClockwise, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_filtered.isEmpty)
                SliverFillRemaining(child: _EmptySearchState(cs: cs, tt: tt, isSearching: _searchQuery.isNotEmpty))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final grouped = _groupByLetter(_filtered);
                        final letter = grouped.keys.elementAt(index);
                        final staffList = grouped[letter]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
                              child: Text(
                                letter,
                                style: tt.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                              ),
                            ),
                            ...List.generate(staffList.length, (i) {
                              return FluidSlideIn(
                                delay: (index * 20 + i * 50).clamp(0, 400).toInt(),
                                child: _StaffDirectoryTile(cs: cs, tt: tt, employee: staffList[i]),
                              );
                            }),
                          ],
                        );
                      },
                      childCount: _groupByLetter(_filtered).keys.length,
                    ),
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
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
                if (result == true && mounted) _fetch();
              },
              backgroundColor: cs.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  const _PremiumSearchBar({required this.cs, required this.onChanged, required this.focusNode});

  @override
  State<_PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<_PremiumSearchBar> {
  final _searchCtrl = TextEditingController();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
    _searchCtrl.addListener(() {
      final hasTextNow = _searchCtrl.text.isNotEmpty;
      if (_hasText != hasTextNow) {
        setState(() => _hasText = hasTextNow);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCirc,
      height: 52,
      decoration: BoxDecoration(
        color: _isFocused ? widget.cs.surface : widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? widget.cs.primary.withValues(alpha: 0.5) : widget.cs.outlineVariant.withValues(alpha: 0.3),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [BoxShadow(color: widget.cs.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: widget.focusNode,
        textInputAction: TextInputAction.search,
        cursorColor: widget.cs.primary,
        style: TextStyle(fontWeight: FontWeight.w600, color: widget.cs.onSurface, letterSpacing: -0.3),
        decoration: InputDecoration(
          hintText: 'Search by name or role...',
          hintStyle: TextStyle(color: widget.cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w500),
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
                icon: Icon(PhosphorIconsFill.xCircle, size: 18, color: widget.cs.onSurfaceVariant),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {
                  if (!_hasText) return;
                  HapticFeedback.lightImpact();
                  _searchCtrl.clear();
                  widget.onChanged('');
                  widget.focusNode.unfocus();
                },
              ),
            ),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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

  const _StaffDirectoryTile({required this.cs, required this.tt, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDaily = employee.wageType == 'daily';
    final typeColor = isDaily ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final initials = getInitials(employee.name);
    final photoUrl = resolveMediaUrl(employee.photoUrl ?? '', ref.watch(serverUrlProvider));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeProfileScreen(employeeId: employee.id)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isNotEmpty
                      ? null
                      : Text(initials, style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary, fontSize: 14)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text(employee.designation ?? employee.role, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\u20B9${employee.wageAmount.toStringAsFixed(0)}', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDaily ? 'DAILY' : 'MONTHLY',
                        style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

  const _EmptySearchState({required this.cs, required this.tt, required this.isSearching});

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
              isSearching ? PhosphorIconsDuotone.magnifyingGlass : PhosphorIconsDuotone.usersThree,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(isSearching ? 'No matches found' : 'No staff members yet',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(isSearching ? 'Try checking for typos or use a different term.' : 'Tap the + button to onboard your first employee.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
