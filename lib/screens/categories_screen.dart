import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final currentMonthExpensesAsyncValue = ref.watch(currentMonthExpensesProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Budgets'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsyncValue.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first category',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return currentMonthExpensesAsyncValue.when(
            data: (expenses) {
              // Calculate spending per category for current month
              Map<String, double> spendingByCategory = {};
              for (var expense in expenses) {
                spendingByCategory[expense.categoryId] = 
                    (spendingByCategory[expense.categoryId] ?? 0.0) + expense.amount;
              }

              return Column(
                children: [
                  // Summary header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Budget Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildOverviewStats(categories, spendingByCategory),
                      ],
                    ),
                  ),
                  
                  // Categories list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final spent = spendingByCategory[category.id] ?? 0.0;
                        return _buildEnhancedCategoryCard(context, ref, category, spent);
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading expenses: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildOverviewStats(List<Category> categories, Map<String, double> spendingByCategory) {
    final totalBudget = categories.fold<double>(0.0, (sum, cat) => sum + cat.monthlyBudget);
    final totalSpent = spendingByCategory.values.fold<double>(0.0, (sum, spent) => sum + spent);
    final overBudgetCategories = categories.where((cat) {
      final spent = spendingByCategory[cat.id] ?? 0.0;
      return spent > cat.monthlyBudget;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Budget', '\$${totalBudget.toStringAsFixed(2)}', Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Total Spent', '\$${totalSpent.toStringAsFixed(2)}', Colors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Over Budget', '$overBudgetCategories', Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.lerp(color, Colors.black, 0.3)!,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color.lerp(color, Colors.black, 0.2)!,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCategoryCard(BuildContext context, WidgetRef ref, Category category, double spent) {
    final budget = category.monthlyBudget;
    final progress = budget > 0 ? spent / budget : 0.0;
    final isOverBudget = spent > budget;
    final remaining = budget - spent;
    
    // Determine status and colors
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (progress > 1.0) {
      statusColor = Colors.red;
      statusText = 'OVER BUDGET';
      statusIcon = Icons.warning;
    } else if (progress > 0.8) {
      statusColor = Colors.orange;
      statusText = 'NEAR LIMIT';
      statusIcon = Icons.info;
    } else if (progress > 0.6) {
      statusColor = Colors.amber;
      statusText = 'ON TRACK';
      statusIcon = Icons.trending_up;
    } else {
      statusColor = Colors.green;
      statusText = 'ON TRACK';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category info and status
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _parseColor(category.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _parseIcon(category.icon),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit_budget':
                        _showEditBudgetDialog(context, ref, category);
                        break;
                      case 'quick_adjust':
                        if (isOverBudget) {
                          _showQuickBudgetAdjustDialog(context, ref, category, spent);
                        }
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context, ref, category);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_budget',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Budget'),
                        ],
                      ),
                    ),
                    if (isOverBudget)
                      const PopupMenuItem(
                        value: 'quick_adjust',
                        child: Row(
                          children: [
                            Icon(Icons.auto_fix_high, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Quick Adjust'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Spending vs Budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent This Month',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '\$${spent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '\$${budget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),

            const SizedBox(height: 8),

            // Status details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% used',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (isOverBudget)
                  Text(
                    'Over by \$${(-remaining).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    '\$${remaining.toStringAsFixed(2)} remaining',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;

    final colorOptions = [
      Colors.blue, Colors.green, Colors.red, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    ];

    final iconOptions = [
      Icons.restaurant, Icons.directions_car, Icons.movie, Icons.shopping_bag,
      Icons.receipt, Icons.fitness_center, Icons.flight, Icons.home, Icons.school,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Color selection
                const Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Icon selection
                const Text('Choose Icon:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: iconOptions.map((icon) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedIcon == icon ? selectedColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: selectedIcon == icon ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    );
                  }).toList(),
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
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty && 
                    budgetController.text.trim().isNotEmpty) {
                  final budget = double.tryParse(budgetController.text);
                  if (budget != null && budget >= 0) {
                    try {
                      final authService = ref.read(authServiceProvider);
                      final categoryService = ref.read(categoryServiceProvider);
                      
                      await categoryService.addCategory(
                        userId: authService.currentUser!.uid,
                        name: nameController.text.trim(),
                        icon: _iconToString(selectedIcon),
                        color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                        monthlyBudget: budget,
                      );
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding category: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, Category category) {
    final budgetController = TextEditingController(text: category.monthlyBudget.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${category.name} Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(budgetController.text);
              if (newBudget != null && newBudget >= 0) {
                try {
                  final authService = ref.read(authServiceProvider);
                  final categoryService = ref.read(categoryServiceProvider);
                  await categoryService.updateCategory(
                    userId: authService.currentUser!.uid,
                    categoryId: category.id,
                    monthlyBudget: newBudget,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating budget: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showQuickBudgetAdjustDialog(BuildContext context, WidgetRef ref, Category category, double currentSpent) {
    final suggestedBudget = (currentSpent * 1.1).ceil().toDouble(); // 10% buffer
    final conservative = (currentSpent * 1.05).ceil().toDouble(); // 5% buffer
    final generous = (currentSpent * 1.2).ceil().toDouble(); // 20% buffer
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Quick Budget Adjustment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve spent \$${currentSpent.toStringAsFixed(2)} this month, exceeding your \$${category.monthlyBudget.toStringAsFixed(2)} budget.',
            ),
            const SizedBox(height: 16),
            Text(
              'Suggested budget adjustments:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildQuickAdjustOption(context, ref, category, conservative, 'Conservative (+5%)', Colors.green),
            _buildQuickAdjustOption(context, ref, category, suggestedBudget, 'Recommended (+10%)', Colors.blue),
            _buildQuickAdjustOption(context, ref, category, generous, 'Generous (+20%)', Colors.orange),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdjustOption(BuildContext context, WidgetRef ref, Category category, double newBudget, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.attach_money, color: color, size: 16),
        ),
        title: Text(label),
        subtitle: Text('\$${newBudget.toStringAsFixed(2)} / month'),
        onTap: () async {
          try {
            final authService = ref.read(authServiceProvider);
            final categoryService = ref.read(categoryServiceProvider);
            await categoryService.updateCategory(
              userId: authService.currentUser!.uid,
              categoryId: category.id,
              monthlyBudget: newBudget,
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Budget adjusted to \$${newBudget.toStringAsFixed(2)}'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating budget: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final authService = ref.read(authServiceProvider);
                final categoryService = ref.read(categoryServiceProvider);
                await categoryService.deleteCategory(
                  userId: authService.currentUser!.uid,
                  categoryId: category.id,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting category: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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

  String _iconToString(IconData icon) {
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.directions_car) return 'directions_car';
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.shopping_bag) return 'shopping_bag';
    if (icon == Icons.receipt) return 'receipt';
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.flight) return 'flight';
    if (icon == Icons.home) return 'home';
    if (icon == Icons.school) return 'school';
    return 'category';
  }
} 