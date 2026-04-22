import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/theme/app_theme.dart';

class AssignTeamDialog extends StatefulWidget {
  final int incidentId;

  const AssignTeamDialog({super.key, required this.incidentId});

  @override
  State<AssignTeamDialog> createState() => _AssignTeamDialogState();

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    int incidentId,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AssignTeamDialog(incidentId: incidentId),
    );
  }
}

class _AssignTeamDialogState extends State<AssignTeamDialog> {
  int? _selectedTeamId;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadRescueTeams();
    });
  }

  Future<void> _assignTeam() async {
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a responder organization')),
      );
      return;
    }

    setState(() => _isAssigning = true);

    final adminProvider = context.read<AdminProvider>();
    final result = await adminProvider.assignRescueTeam(
      incidentId: widget.incidentId,
      rescueTeamId: _selectedTeamId!,
    );

    setState(() => _isAssigning = false);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.of(context).pop(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Team assigned successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'Failed to assign team'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final teams = adminProvider.rescueTeams;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.group_add_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Assign Organization',
                    style: PremiumAppTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (adminProvider.isLoadingRescueTeams)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (adminProvider.rescueTeamsError != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  adminProvider.rescueTeamsError!,
                  style: PremiumAppTheme.bodyMedium.copyWith(color: Colors.red),
                ),
              )
            else if (teams.isEmpty)
              PremiumWidgets.emptyState(
                title: 'No Organizations',
                message: 'No responder organizations available to assign.',
                icon: Icons.group_off_rounded,
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final teamId =
                        team['teamId'] ??
                        team['team_id'] ??
                        team['rescueTeamId'] ??
                        team['rescue_team_id'];
                    final teamName =
                        team['teamName'] ?? team['team_name'] ?? 'Unknown Team';
                    final isActive =
                        team['isActive'] ?? team['is_active'] ?? false;
                    final isSelected = _selectedTeamId == teamId;

                    return PremiumWidgets.premiumCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: isSelected
                          ? Colors.red.shade50
                          : PremiumAppTheme.cardBackground,
                      onTap: () {
                        setState(() => _selectedTeamId = teamId);
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: isActive ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teamName,
                                  style: PremiumAppTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    PremiumWidgets.statusIndicator(
                                      status: isActive ? 'active' : 'inactive',
                                      text: isActive ? 'Active' : 'Inactive',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.red.shade700,
                              size: 28,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PremiumWidgets.premiumButton(
                    text: 'Cancel',
                    onPressed: () {
                      if (!_isAssigning) Navigator.of(context).pop();
                    },
                    backgroundColor: PremiumAppTheme.textDisabled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PremiumWidgets.premiumButton(
                    text: 'Assign',
                    onPressed: () => _assignTeam(),
                    isLoading: _isAssigning,
                    backgroundColor: Colors.red.shade700,
                    icon: Icons.check,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
