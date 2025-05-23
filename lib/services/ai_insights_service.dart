import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/expense.dart';

final aiInsightsServiceProvider = Provider<AIInsightsService>((ref) => AIInsightsService());

class AIInsightsService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKey = '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';
  
  Future<String> generateFinancialInsights({
    required List<Category> categories,
    required List<Expense> expenses,
    required double totalBudget,
    required double totalSpent,
  }) async {
    try {
      // Prepare the financial data for analysis
      final financialData = _prepareFinancialData(
        categories: categories,
        expenses: expenses,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
      );
      
      // Create the prompt for the AI
      final prompt = _createFinancialAnalysisPrompt(financialData);
      
      // Make API call to OpenRouter
      final response = await _makeAPICall(prompt);
      
      return response;
    } catch (e) {
      throw Exception('Failed to generate financial insights: $e');
    }
  }
  
  Map<String, dynamic> _prepareFinancialData({
    required List<Category> categories,
    required List<Expense> expenses,
    required double totalBudget,
    required double totalSpent,
  }) {
    // Calculate spending by category
    Map<String, double> spendingByCategory = {};
    Map<String, String> categoryNames = {};
    
    for (var category in categories) {
      spendingByCategory[category.id] = 0.0;
      categoryNames[category.id] = category.name;
    }
    
    for (var expense in expenses) {
      spendingByCategory[expense.categoryId] = 
          (spendingByCategory[expense.categoryId] ?? 0.0) + expense.amount;
    }
    
    // Calculate category performance
    List<Map<String, dynamic>> categoryAnalysis = [];
    for (var category in categories) {
      final spent = spendingByCategory[category.id] ?? 0.0;
      final budget = category.monthlyBudget;
      final utilization = budget > 0 ? (spent / budget * 100) : 0.0;
      
      categoryAnalysis.add({
        'name': category.name,
        'budget': budget,
        'spent': spent,
        'utilization_percentage': utilization,
        'over_budget': spent > budget,
        'remaining': budget - spent,
      });
    }
    
    // Sort by spending amount
    categoryAnalysis.sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));
    
    // Calculate recent spending trends (last 30 days)
    final recentExpenses = expenses.where((expense) {
      return expense.date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
    }).toList();
    
    final avgDailySpending = recentExpenses.isNotEmpty 
        ? recentExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount) / 30
        : 0.0;
    
    return {
      'total_budget': totalBudget,
      'total_spent': totalSpent,
      'budget_utilization': totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0,
      'remaining_budget': totalBudget - totalSpent,
      'total_expenses_count': expenses.length,
      'recent_expenses_count': recentExpenses.length,
      'average_daily_spending': avgDailySpending,
      'category_analysis': categoryAnalysis,
      'analysis_period': 'Current Month',
    };
  }
  
  String _createFinancialAnalysisPrompt(Map<String, dynamic> financialData) {
    return '''
You are a professional financial advisor analyzing a user's spending patterns and budget. Based on the following financial data, provide a comprehensive financial insights report with specific, actionable recommendations.

FINANCIAL DATA:
- Total Monthly Budget: \$${financialData['total_budget'].toStringAsFixed(2)}
- Total Spent This Month: \$${financialData['total_spent'].toStringAsFixed(2)}
- Budget Utilization: ${financialData['budget_utilization'].toStringAsFixed(1)}%
- Remaining Budget: \$${financialData['remaining_budget'].toStringAsFixed(2)}
- Total Transactions: ${financialData['total_expenses_count']}
- Average Daily Spending: \$${financialData['average_daily_spending'].toStringAsFixed(2)}

CATEGORY BREAKDOWN:
${_formatCategoryData(financialData['category_analysis'])}

Please provide a comprehensive financial report with the following sections:

## 📊 SPENDING ANALYSIS
Analyze the current spending patterns, identify trends, and highlight areas of concern or success.

## 🎯 BUDGET OPTIMIZATION
Provide specific recommendations for adjusting spending and optimizing the budget allocation across categories.

## 💰 INVESTMENT OPPORTUNITIES
Based on the remaining budget and spending patterns, suggest practical investment strategies and savings opportunities.

## ⚠️ RISK ASSESSMENT
Identify potential financial risks and areas where spending might become problematic.

## 📈 ACTION PLAN
Provide a prioritized list of 3-5 actionable steps the user can take immediately to improve their financial situation.

## 🔮 FUTURE PROJECTIONS
Project how the current spending patterns might affect long-term financial goals.

Keep the tone professional yet friendly, use specific dollar amounts from the data, and make all recommendations practical and achievable. Use emojis to make sections easily scannable.
''';
  }
  
  String _formatCategoryData(List<Map<String, dynamic>> categoryAnalysis) {
    return categoryAnalysis.map((category) {
      return '- ${category['name']}: \$${category['spent'].toStringAsFixed(2)} / \$${category['budget'].toStringAsFixed(2)} (${category['utilization_percentage'].toStringAsFixed(1)}% used)${category['over_budget'] ? ' - OVER BUDGET' : ''}';
    }).join('\n');
  }
  
  Future<String> _makeAPICall(String prompt) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'X-Title': 'Budget Tracker AI Insights',
    };
    
    final body = {
      'model': 'meta-llama/llama-4-scout:free',
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.7,
    };
    
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('API call failed: ${response.statusCode} - ${response.body}');
    }
  }
}

class AIInsightResult {
  final String content;
  final DateTime generatedAt;
  final bool isSuccess;
  final String? error;
  
  AIInsightResult({
    required this.content,
    required this.generatedAt,
    required this.isSuccess,
    this.error,
  });
  
  factory AIInsightResult.success(String content) {
    return AIInsightResult(
      content: content,
      generatedAt: DateTime.now(),
      isSuccess: true,
    );
  }
  
  factory AIInsightResult.error(String error) {
    return AIInsightResult(
      content: '',
      generatedAt: DateTime.now(),
      isSuccess: false,
      error: error,
    );
  }
} 