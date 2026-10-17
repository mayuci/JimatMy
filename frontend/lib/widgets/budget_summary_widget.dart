import 'package:flutter/material.dart';

import '../models/planner_models.dart';

class BudgetSummaryWidget extends StatelessWidget {
  const BudgetSummaryWidget({
    required this.overview,
    required this.onEdit,
    super.key,
  });

  final PlannerOverview overview;
  final VoidCallback onEdit;

  String _rm(double value) => 'RM ${value.abs().toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final budget = overview.budget;
    final progress = budget == null || budget.amount <= 0
        ? 0.0
        : (overview.plannerEstimatedTotal / budget.amount).clamp(0.0, 1.0);
    return Card(
      color: const Color(0xFFE5F5EA),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monthly budget',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(budget == null ? Icons.add : Icons.edit_outlined),
                  label: Text(budget == null ? 'Set budget' : 'Edit budget'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Budget',
                    value: budget == null ? 'Not set' : _rm(budget.amount),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Estimated',
                    value: _rm(overview.plannerEstimatedTotal),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Remaining',
                    value: overview.remainingBudget == null
                        ? '--'
                        : overview.remainingBudget! < 0
                        ? 'Over budget'
                        : _rm(overview.remainingBudget!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress,
                color: overview.overBudget ? colors.error : colors.primary,
                backgroundColor: colors.surface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              budget == null || budget.amount <= 0
                  ? 'Set a budget to track monthly progress.'
                  : '${(overview.plannerEstimatedTotal / budget.amount * 100).toStringAsFixed(0)}% of monthly budget planned',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (overview.overBudget) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Over budget by ${_rm(overview.remainingBudget ?? 0)}',
                        style: TextStyle(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      Text(
        value,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}
