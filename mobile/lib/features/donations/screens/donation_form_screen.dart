import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:esewa_wallet/esewa_wallet.dart';
import '../../auth/auth_provider.dart';
import '../donation_provider.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../services/donation_service.dart';
import '../models/campaign_model.dart';

class DonationFormScreen extends StatefulWidget {
  final CampaignModel? campaign;

  const DonationFormScreen({super.key, this.campaign});

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final DonationService _donationService = DonationService();

  Map<String, dynamic>? _bankInfo;
  String _paymentMethod = 'esewa_wallet';

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  Future<void> _loadBankInfo() async {
    try {
      final info = await _donationService.getBankInfo();
      if (mounted) setState(() => _bankInfo = info);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final donationProvider = Provider.of<DonationProvider>(context);

    return Scaffold(
      appBar: PremiumAppBar(
        title: widget.campaign != null ? 'Donate to ${widget.campaign!.title}' : 'Global Donation',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.campaign != null) ...[
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.campaign!.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: widget.campaign!.progressPercentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(PremiumAppTheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Raised: \$${widget.campaign!.raisedAmount.toStringAsFixed(0)} / Target: \$${widget.campaign!.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Choose an amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                       Expanded(child: _buildAmountCard(10, 'Clean Water')),
                       const SizedBox(width: 12),
                       Expanded(child: _buildAmountCard(50, 'Medical Kit')),
                       const SizedBox(width: 12),
                       Expanded(child: _buildAmountCard(100, 'Shelter')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Donation Form
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FormBuilder(
                  key: _formKey,
                  initialValue: {
                    'donorName': user?.name ?? '',
                    'donorEmail': user?.email ?? '',
                    'paymentMethod': 'esewa_wallet',
                    'bankReference': '',
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Payment Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'donorName',
                        decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'donorEmail',
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.email(),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'amount',
                        decoration: const InputDecoration(
                          labelText: 'Custom Amount',
                          prefixText: r'$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          FormBuilderValidators.min(1),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: 'paymentMethod',
                        decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                        onChanged: (v) {
                          if (v != null) setState(() => _paymentMethod = v);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'card',
                            child: Row(children: [
                              Icon(Icons.credit_card, size: 20),
                              SizedBox(width: 8),
                              Expanded(child: Text('Card (eSewa checkout)')),
                            ]),
                          ),
                          DropdownMenuItem(
                            value: 'esewa_wallet',
                            child: Row(children: [
                              Icon(Icons.account_balance_wallet, size: 20),
                              SizedBox(width: 8),
                              Text('eSewa Wallet'),
                            ]),
                          ),
                          DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Row(children: [
                              Icon(Icons.account_balance, size: 20),
                              SizedBox(width: 8),
                              Text('Bank transfer'),
                            ]),
                          ),
                        ],
                        validator: FormBuilderValidators.required(),
                      ),
                      if (_paymentMethod == 'bank_transfer') ...[
                        const SizedBox(height: 16),
                        if (_bankInfo != null && (_bankInfo!['bankName']?.toString().isNotEmpty ?? false))
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Transfer to:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                const SizedBox(height: 8),
                                Text('Bank: ${_bankInfo!['bankName'] ?? '—'}'),
                                Text('Account name: ${_bankInfo!['accountName'] ?? '—'}'),
                                Text('Account: ${_bankInfo!['accountNumber'] ?? '—'}'),
                                if ((_bankInfo!['branch'] ?? '').toString().isNotEmpty)
                                  Text('Branch: ${_bankInfo!['branch']}'),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'bankReference',
                          decoration: const InputDecoration(
                            labelText: 'Transfer reference / remark',
                            hintText: 'Enter the reference from your bank receipt',
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.required(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (_paymentMethod == 'esewa_wallet' || _paymentMethod == 'card')
                        const Text(
                          'eSewa UAT test: ID 9806800001 / MPIN 1122 / token 123456',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: donationProvider.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState?.saveAndValidate() ??
                                      false) {
                                    final formData = _formKey.currentState!.value;
                                    final rawAmount = formData['amount'];
                                    final amount = double.tryParse(
                                          rawAmount?.toString() ?? '0',
                                        ) ??
                                        0.0;
                                    final paymentMethod =
                                        formData['paymentMethod'] as String?;
                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(context);

                                    if (amount <= 0) {
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Amount must be greater than 0',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    final submitData = Map<String, dynamic>.from(
                                      formData,
                                    )
                                      ..['amount'] = amount
                                      ..['donorName'] =
                                          (formData['donorName'] as String?)
                                              ?.trim() ??
                                          ''
                                      ..['donorEmail'] =
                                          (formData['donorEmail'] as String?)
                                              ?.trim() ??
                                          ''
                                      ..['campaignId'] = widget.campaign?.id;

                                    if (paymentMethod == 'esewa_wallet' ||
                                        paymentMethod == 'card') {
                                      try {
                                        final pendingDonation =
                                            await donationProvider
                                                .initiateEsewaDonation({
                                          'donorName': submitData['donorName'],
                                          'donorEmail': submitData['donorEmail'],
                                          'amount': amount,
                                          'paymentMethod': paymentMethod,
                                          'campaignId': widget.campaign?.id,
                                          'transactionId':
                                              'TXN-${DateTime.now().millisecondsSinceEpoch}',
                                        });

                                        final transactionUuid =
                                            pendingDonation.transactionId ??
                                                'TXN-${DateTime.now().millisecondsSinceEpoch}';

                                        final paymentData = PaymentData(
                                          amount: amount.toStringAsFixed(2),
                                          taxAmount: AppConfig.esewaTaxAmount,
                                          totalAmount:
                                              amount.toStringAsFixed(2),
                                          transactionUuid: transactionUuid,
                                          productCode: AppConfig.esewaProductCode,
                                          productServiceCharge:
                                              AppConfig.esewaProductServiceCharge,
                                          productDeliveryCharge:
                                              AppConfig.esewaProductDeliveryCharge,
                                          successUrl:
                                              AppConfig.esewaSuccessUrl,
                                          failureUrl:
                                              AppConfig.esewaFailureUrl,
                                          secretKey:
                                              AppConfig.esewaSecretKey,
                                        );

                                        final paymentService =
                                            ESewaPayment.dev(
                                          paymentData: paymentData,
                                        );

                                        if (!context.mounted) return;

                                        paymentService.initiatePayment(
                                          context,
                                          appBar: AppBar(
                                            title: Text(
                                              paymentMethod == 'card'
                                                  ? 'Pay with eSewa (card)'
                                                  : 'Pay with eSewa',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                          progressBarColor:
                                              PremiumAppTheme.primary,
                                          onSuccess: (response) async {
                                            if (!mounted) {
                                              return;
                                            }
                                            final transactionCode =
                                                _extractEsewaTransactionCode(
                                                  response,
                                                );
                                            final status =
                                                _normalizeEsewaStatus(
                                                  _extractEsewaStatus(
                                                    response,
                                                  ),
                                                );

                                            try {
                                              await donationProvider
                                                  .confirmEsewaDonation({
                                                'donationId':
                                                    pendingDonation.id,
                                                'transactionUuid':
                                                    transactionUuid,
                                                'transactionCode':
                                                    transactionCode,
                                                'status': status,
                                              });

                                              if (context.mounted) {
                                                scaffoldMessenger
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Donation successful! Thank you.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                navigator.pop();
                                              }
                                            } catch (error) {
                                              if (context.mounted) {
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Payment verification failed: ${error.toString().replaceAll('Exception: ', '')}',
                                                    ),
                                                    backgroundColor:
                                                        Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          onFailure: (failure) async {
                                            try {
                                              await donationProvider
                                                  .failEsewaDonation({
                                                'donationId':
                                                    pendingDonation.id,
                                                'status': 'failed',
                                              });
                                            } catch (_) {}

                                            if (mounted) {
                                              scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Payment Failed: ${failure.error}',
                                                  ),
                                                  backgroundColor:
                                                      Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      } catch (e) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Unable to start eSewa payment: ${e.toString().replaceAll('Exception: ', '')}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }

                                      return;
                                    }

                                    if (paymentMethod == 'bank_transfer') {
                                      final ref = (formData['bankReference'] as String?)?.trim() ?? '';
                                      if (ref.isEmpty) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Enter your bank transfer reference',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      submitData['paymentMethod'] = 'bank_transfer';
                                      submitData['bankReference'] = ref;
                                      try {
                                        await donationProvider.createDonation(submitData);
                                        if (!context.mounted) return;
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Bank transfer recorded. It will show as pending until admin confirms.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        navigator.pop();
                                      } catch (e) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString().replaceAll('Exception: ', '')}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: PremiumAppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: donationProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Confirm Donation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _normalizeEsewaStatus(String? status) {
    final normalized = (status ?? '').toLowerCase().trim();
    if (normalized == 'complete' || normalized == 'completed') return 'completed';
    if (normalized == 'failed' || normalized == 'failure') return 'failed';
    return 'completed';
  }

  String? _extractEsewaTransactionCode(dynamic response) {
    try { return (response as dynamic).transactionCode?.toString(); } catch (_) {}
    return null;
  }

  String? _extractEsewaStatus(dynamic response) {
    try { return (response as dynamic).status?.toString(); } catch (_) {}
    return null;
  }

  Widget _buildAmountCard(double amount, String impact) {
    return InkWell(
      onTap: () {
        _formKey.currentState?.fields['amount']?.didChange(amount.toString());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Text('\$${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PremiumAppTheme.primary)),
            const SizedBox(height: 4),
            Text(impact, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
