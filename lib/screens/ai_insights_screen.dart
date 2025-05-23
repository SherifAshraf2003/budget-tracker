import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/ai_insights_service.dart';

class AIInsightsScreen extends ConsumerStatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  ConsumerState<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends ConsumerState<AIInsightsScreen> {
  bool _isGenerating = false;
  String _generatedInsights = '';
  String? _error;
  DateTime? _lastGenerated;

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final currentMonthExpensesAsyncValue = ref.watch(currentMonthExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Insights'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          if (_generatedInsights.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareInsights(),
            ),
          if (_generatedInsights.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyInsights(),
            ),
        ],
      ),
      body: categoriesAsyncValue.when(
        data: (categories) => currentMonthExpensesAsyncValue.when(
          data: (expenses) => _buildContent(categories, expenses),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Error loading expenses: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState('Error loading categories: $error'),
      ),
    );
  }

  Widget _buildContent(List<Category> categories, List<Expense> expenses) {
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    final totalBudget = categories.fold<double>(0.0, (sum, cat) => sum + cat.monthlyBudget);
    final totalSpent = expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(totalBudget, totalSpent, expenses.length),
          const SizedBox(height: 20),

          // Generate Button
          _buildGenerateButton(categories, expenses, totalBudget, totalSpent),
          const SizedBox(height: 20),

          // Results Section
          if (_isGenerating) _buildLoadingState(),
          if (_error != null) _buildErrorMessage(),
          if (_generatedInsights.isNotEmpty) _buildInsightsContent(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Financial Data Available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Add categories and expenses to generate AI insights',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(double totalBudget, double totalSpent, int transactionCount) {
    final budgetUtilization = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Financial Analysis',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Get personalized insights powered by Llama 4 Scout',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderStat('Budget', '\$${totalBudget.toStringAsFixed(2)}'),
                ),
                Expanded(
                  child: _buildHeaderStat('Spent', '\$${totalSpent.toStringAsFixed(2)}'),
                ),
                Expanded(
                  child: _buildHeaderStat('Usage', '${budgetUtilization.toInt()}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(List<Category> categories, List<Expense> expenses, double totalBudget, double totalSpent) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : () => _generateInsights(categories, expenses, totalBudget, totalSpent),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isGenerating 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating ? 'Generating AI Insights...' : 'Generate AI Financial Insights',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'AI is analyzing your financial data...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This may take a few moments',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Generation Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with timestamp
        Row(
          children: [
            Icon(Icons.auto_awesome, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text(
              'AI Generated Insights',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_lastGenerated != null)
              Text(
                'Generated ${_formatTimestamp(_lastGenerated!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Insights content
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: _generatedInsights,
                  styleSheet: MarkdownStyleSheet(
                    h1: GoogleFonts.roboto(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                    h2: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                    h3: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF424242),
                    ),
                    p: GoogleFonts.roboto(
                      fontSize: 16,
                      height: 1.6,
                      color: const Color(0xFF212121),
                    ),
                    listBullet: GoogleFonts.roboto(
                      fontSize: 16,
                      color: const Color(0xFF1E88E5),
                    ),
                    strong: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1565C0),
                    ),
                    em: GoogleFonts.roboto(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: const Color(0xFF424242),
                    ),
                    code: GoogleFonts.robotoMono(
                      fontSize: 14,
                      backgroundColor: const Color(0xFFF5F5F5),
                      color: const Color(0xFF1E88E5),
                    ),
                    blockquote: GoogleFonts.roboto(
                      fontSize: 16,
                      color: const Color(0xFF616161),
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        left: BorderSide(
                          color: Color(0xFF1E88E5),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                  selectable: true,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareInsights(),
                icon: const Icon(Icons.share),
                label: const Text('Share Report'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generateInsights(List<Category> categories, List<Expense> expenses, double totalBudget, double totalSpent) async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedInsights = '';
    });

    try {
      final aiService = ref.read(aiInsightsServiceProvider);
      final insights = await aiService.generateFinancialInsights(
        categories: categories,
        expenses: expenses,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
      );

      setState(() {
        _generatedInsights = insights;
        _lastGenerated = DateTime.now();
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _copyInsights() {
    if (_generatedInsights.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedInsights));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insights copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareInsights() {
    // For now, just copy to clipboard since share requires additional packages
    _copyInsights();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Insights copied to clipboard for sharing'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
} 