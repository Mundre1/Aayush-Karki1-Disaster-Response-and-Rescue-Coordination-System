import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../campaign_provider.dart';
import 'my_campaign_requests_screen.dart';

class RequestCampaignScreen extends StatefulWidget {
  const RequestCampaignScreen({super.key});

  @override
  State<RequestCampaignScreen> createState() => _RequestCampaignScreenState();
}

class _RequestCampaignScreenState extends State<RequestCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CampaignProvider>(context, listen: false);
    
    try {
      await provider.requestCampaign(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        double.parse(_amountController.text.trim()),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign request submitted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyCampaignRequestsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(title: 'Raise Funds'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a Campaign',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PremiumAppTheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us why you need to raise funds. Your request will be reviewed by administrators within 24 hours.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              PremiumWidgets.premiumCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Campaign Title',
                        hintText: 'e.g., Local Community Flood Relief',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Target Amount',
                        prefixText: r'$ ',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Amount is required';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description & Justification',
                        hintText: 'Describe the cause and how the funds will be used...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 80),
                          child: Icon(Icons.description),
                        ),
                      ),
                      maxLines: 5,
                      validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Consumer<CampaignProvider>(
                builder: (context, provider, _) {
                  return PremiumWidgets.premiumButton(
                    text: 'Submit for Review',
                    onPressed: _submitRequest,
                    isLoading: provider.isLoading,
                    width: double.infinity,
                  );
                },
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'By submitting, you agree to our fundraising policies.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
