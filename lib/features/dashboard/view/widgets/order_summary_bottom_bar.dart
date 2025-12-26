import 'package:flutter/material.dart';

/// Bottom summary bar showing total orders and amount
class OrderSummaryBottomBar extends StatelessWidget {
  final int totalOrders;
  final double totalAmount;
  final String orderLabel;
  final String amountLabel;

  const OrderSummaryBottomBar({
    super.key,
    required this.totalOrders,
    required this.totalAmount,
    this.orderLabel = 'Total Running Orders',
    this.amountLabel = 'Estimated Total',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(top: 28, bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Amount section
            _buildStatItem(
              context,
              label: amountLabel,
              value: '₹${totalAmount.toStringAsFixed(0)}',
              textTheme: textTheme,
            ),
            // Divider
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
            ),
            // Order count section
            _buildStatItem(
              context,
              label: orderLabel,
              value: '$totalOrders',
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
