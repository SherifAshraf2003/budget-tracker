import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'current_month';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'current_month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(lastMonth.year, lastMonth.month + 1, 0);
        break;
      case 'last_3_months':
        _startDate = DateTime(now.year, now.month - 2, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last_6_months':
        _startDate = DateTime(now.year, now.month - 5, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final currentMonthExpensesAsyncValue = ref.watch(currentMonthExpensesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Insights',
            onPressed: () => Navigator.pushNamed(context, '/ai-insights'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'current_month',
                child: Text('Current Month'),
              ),
              const PopupMenuItem(
                value: 'last_month',
                child: Text('Last Month'),
              ),
              const PopupMenuItem(
                value: 'last_3_months',
                child: Text('Last 3 Months'),
              ),
              const PopupMenuItem(
                value: 'last_6_months',
                child: Text('Last 6 Months'),
              ),
            ],
          ),
        ],
      ),
      body: categoriesAsyncValue.when(
        data: (categories) => currentMonthExpensesAsyncValue.when(
          data: (expenses) => _buildReportsContent(categories, expenses),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error loading expenses: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading categories: $error')),
      ),
    );
  }

  Widget _buildReportsContent(List<Category> categories, List<Expense> expenses) {
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    // Filter expenses by selected period
    final filteredExpenses = expenses.where((expense) {
      return expense.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate analytics data
    final analyticsData = _calculateAnalytics(categories, filteredExpenses);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Header
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          
          // Overview Cards
          _buildOverviewCards(analyticsData),
          const SizedBox(height: 24),
          
          // Budget Performance
          _buildBudgetPerformanceCard(analyticsData),
          const SizedBox(height: 24),
          
          // Category Breakdown
          _buildCategoryBreakdownCard(categories, analyticsData),
          const SizedBox(height: 24),
          
          // Spending Trends
          _buildSpendingTrendsCard(filteredExpenses),
          const SizedBox(height: 24),
          
          // Insights & Recommendations
          _buildInsightsCard(analyticsData, categories),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Add categories and expenses to see reports',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    String periodText;
    switch (_selectedPeriod) {
      case 'current_month':
        periodText = 'Current Month';
        break;
      case 'last_month':
        periodText = 'Last Month';
        break;
      case 'last_3_months':
        periodText = 'Last 3 Months';
        break;
      case 'last_6_months':
        periodText = 'Last 6 Months';
        break;
      default:
        periodText = 'Current Month';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> analyticsData) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Spent',
                '\$${analyticsData['totalSpent'].toStringAsFixed(2)}',
                Icons.payment,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Total Budget',
                '\$${analyticsData['totalBudget'].toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Budget Used',
                '${analyticsData['budgetUsedPercentage'].toInt()}%',
                Icons.pie_chart,
                analyticsData['budgetUsedPercentage'] > 100 
                    ? Colors.red 
                    : analyticsData['budgetUsedPercentage'] > 80 
                        ? Colors.orange 
                        : Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Categories',
                '${analyticsData['totalCategories']}',
                Icons.category,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPerformanceCard(Map<String, dynamic> analyticsData) {
    final performance = analyticsData['categoryPerformance'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Budget Performance',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...performance.map((perf) => _buildPerformanceRow(perf)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(Map<String, dynamic> performance) {
    final category = performance['category'] as Category;
    final spent = performance['spent'] as double;
    final budget = category.monthlyBudget;
    final percentage = budget > 0 ? (spent / budget * 100) : 0.0;
    final isOverBudget = spent > budget;
    
    Color statusColor = isOverBudget 
        ? Colors.red 
        : percentage > 80 
            ? Colors.orange 
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _parseColor(category.color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _parseIcon(category.icon),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${spent.toStringAsFixed(2)} / \$${budget.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(List<Category> categories, Map<String, dynamic> analyticsData) {
    final spendingByCategory = analyticsData['spendingByCategory'] as Map<String, double>;
    final totalSpent = analyticsData['totalSpent'] as double;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Spending Breakdown',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalSpent > 0) ...[
              // Simple bar chart representation
              ...categories.where((cat) => spendingByCategory[cat.id] != null && spendingByCategory[cat.id]! > 0)
                  .map((category) {
                final spent = spendingByCategory[category.id] ?? 0.0;
                final percentage = (spent / totalSpent * 100);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _parseColor(category.color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '\$${spent.toStringAsFixed(2)} (${percentage.toInt()}%)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_parseColor(category.color)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              Center(
                child: Text(
                  'No expenses for selected period',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendsCard(List<Expense> expenses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Spending Trends',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDailySpendingChart(expenses),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySpendingChart(List<Expense> expenses) {
    // Group expenses by day for the last 7 days
    final Map<DateTime, double> dailySpending = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailySpending[date] = 0.0;
    }
    
    for (final expense in expenses) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (dailySpending.containsKey(expenseDate)) {
        dailySpending[expenseDate] = dailySpending[expenseDate]! + expense.amount;
      }
    }
    
    final maxAmount = dailySpending.values.isEmpty ? 1.0 : dailySpending.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        // Simple bar chart
        SizedBox(
          height: 140, // Increased height to accommodate all elements
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailySpending.entries.map((entry) {
              final barHeight = maxAmount > 0 ? (entry.value / maxAmount * 80) : 0.0; // Reduced max bar height to 80
              return Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amount text
                    Container(
                      height: 20, // Fixed height for amount text
                      child: Text(
                        '\$${entry.value.toInt()}',
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Bar container
                    Container(
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Day text
                    Container(
                      height: 16, // Fixed height for day text
                      child: Text(
                        '${entry.key.day}',
                        style: const TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Last 7 Days',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic> analyticsData, List<Category> categories) {
    final insights = _generateInsights(analyticsData, categories);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Insights & Recommendations',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(insight)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(insight['icon'], color: insight['color'], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['message'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAnalytics(List<Category> categories, List<Expense> expenses) {
    final spendingByCategory = <String, double>{};
    double totalSpent = 0.0;
    
    for (final expense in expenses) {
      spendingByCategory[expense.categoryId] = 
          (spendingByCategory[expense.categoryId] ?? 0.0) + expense.amount;
      totalSpent += expense.amount;
    }
    
    final totalBudget = categories.fold<double>(0.0, (sum, cat) => sum + cat.monthlyBudget);
    final budgetUsedPercentage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    
    final categoryPerformance = categories.map((category) {
      final spent = spendingByCategory[category.id] ?? 0.0;
      return {
        'category': category,
        'spent': spent,
        'budget': category.monthlyBudget,
        'percentage': category.monthlyBudget > 0 ? (spent / category.monthlyBudget * 100) : 0.0,
      };
    }).toList();
    
    categoryPerformance.sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));
    
    return {
      'totalSpent': totalSpent,
      'totalBudget': totalBudget,
      'budgetUsedPercentage': budgetUsedPercentage,
      'totalCategories': categories.length,
      'spendingByCategory': spendingByCategory,
      'categoryPerformance': categoryPerformance,
    };
  }

  List<Map<String, dynamic>> _generateInsights(Map<String, dynamic> analyticsData, List<Category> categories) {
    final insights = <Map<String, dynamic>>[];
    final totalSpent = analyticsData['totalSpent'] as double;
    final totalBudget = analyticsData['totalBudget'] as double;
    final budgetUsedPercentage = analyticsData['budgetUsedPercentage'] as double;
    final spendingByCategory = analyticsData['spendingByCategory'] as Map<String, double>;
    
    // Budget performance insights
    if (budgetUsedPercentage > 100) {
      insights.add({
        'icon': Icons.warning,
        'color': Colors.red,
        'message': 'You\'ve exceeded your total budget by ${(budgetUsedPercentage - 100).toInt()}%. Consider adjusting your spending or increasing budgets.',
      });
    } else if (budgetUsedPercentage > 80) {
      insights.add({
        'icon': Icons.info,
        'color': Colors.orange,
        'message': 'You\'ve used ${budgetUsedPercentage.toInt()}% of your budget. You\'re approaching your limit.',
      });
    } else {
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'message': 'Great job! You\'re staying within budget at ${budgetUsedPercentage.toInt()}% usage.',
      });
    }
    
    // Category-specific insights
    final overBudgetCategories = categories.where((cat) {
      final spent = spendingByCategory[cat.id] ?? 0.0;
      return spent > cat.monthlyBudget;
    }).toList();
    
    if (overBudgetCategories.isNotEmpty) {
      insights.add({
        'icon': Icons.category,
        'color': Colors.red,
        'message': '${overBudgetCategories.length} categories are over budget. Consider reviewing: ${overBudgetCategories.take(2).map((c) => c.name).join(', ')}.',
      });
    }
    
    // Top spending category
    if (spendingByCategory.isNotEmpty) {
      final topCategoryId = spendingByCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b).key;
      final topCategory = categories.firstWhere((c) => c.id == topCategoryId);
      final topSpent = spendingByCategory[topCategoryId]!;
      final percentage = totalSpent > 0 ? (topSpent / totalSpent * 100) : 0;
      
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'message': '${topCategory.name} is your highest expense at ${percentage.toInt()}% of total spending (\$${topSpent.toStringAsFixed(2)}).',
      });
    }
    
    // Savings opportunity
    if (budgetUsedPercentage < 70) {
      final savings = totalBudget - totalSpent;
      insights.add({
        'icon': Icons.savings,
        'color': Colors.green,
        'message': 'You have \$${savings.toStringAsFixed(2)} left in your budget. Consider saving or investing this amount.',
      });
    }
    
    return insights;
  }

  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt':
        return Icons.receipt;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'flight':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
} 