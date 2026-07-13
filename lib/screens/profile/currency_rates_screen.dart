import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/services/currency_api_service.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class CurrencyRatesScreen extends StatefulWidget {
  const CurrencyRatesScreen({super.key});

  static const routeName = '/currency-rates';

  @override
  State<CurrencyRatesScreen> createState() => _CurrencyRatesScreenState();
}

class _CurrencyRatesScreenState extends State<CurrencyRatesScreen> {
  final CurrencyApiService _currencyApiService = CurrencyApiService();
  final TextEditingController _eurAmountController =
      TextEditingController(text: '100');
  final TextEditingController _rsdAmountController =
      TextEditingController(text: '10000');
  late Future<CurrencyRates> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _ratesFuture = _currencyApiService.fetchEuroRates();
  }

  @override
  void dispose() {
    _eurAmountController.dispose();
    _rsdAmountController.dispose();
    super.dispose();
  }

  void _refreshRates() {
    setState(() {
      _ratesFuture = _currencyApiService.fetchEuroRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Rates'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshRates,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<CurrencyRates>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CurrencyErrorView(
              message: snapshot.error.toString(),
              onRetry: _refreshRates,
            );
          }

          final rates = snapshot.data!;
          final eurToRsd = rates.rates['RSD'] ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubtitleTextWidget(
                      label: 'LIVE API',
                      color: AppColors.darkPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    const SizedBox(height: 8),
                    const TitelesTextWidget(
                      label: 'Euro exchange rates',
                      fontSize: 24,
                    ),
                    const SizedBox(height: 8),
                    SubtitleTextWidget(
                      label:
                          'Base currency: ${rates.baseCode}. Updated: ${_formatDate(rates.lastUpdated)}',
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...rates.rates.entries.map(
                (entry) => _RateTile(
                  code: entry.key,
                  value: entry.value,
                  baseCode: rates.baseCode,
                ),
              ),
              const SizedBox(height: 20),
              _CurrencyConverterCard(
                controller: _eurAmountController,
                title: 'EUR to RSD calculator',
                inputLabel: 'Amount in EUR',
                inputIcon: Icons.euro_rounded,
                resultSuffix: 'RSD',
                convert: (amount) => amount * eurToRsd,
              ),
              const SizedBox(height: 12),
              _CurrencyConverterCard(
                controller: _rsdAmountController,
                title: 'RSD to EUR calculator',
                inputLabel: 'Amount in RSD',
                inputIcon: Icons.payments_outlined,
                resultSuffix: 'EUR',
                convert: (amount) => eurToRsd == 0 ? 0 : amount / eurToRsd,
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year. $hour:$minute';
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.code,
    required this.value,
    required this.baseCode,
  });

  final String code;
  final double value;
  final String baseCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              IconlyLight.wallet,
              color: AppColors.darkPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitelesTextWidget(label: code, fontSize: 17),
                SubtitleTextWidget(
                  label: '1 $baseCode = ${value.toStringAsFixed(2)} $code',
                  fontSize: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyConverterCard extends StatefulWidget {
  const _CurrencyConverterCard({
    required this.controller,
    required this.title,
    required this.inputLabel,
    required this.inputIcon,
    required this.resultSuffix,
    required this.convert,
  });

  final TextEditingController controller;
  final String title;
  final String inputLabel;
  final IconData inputIcon;
  final String resultSuffix;
  final double Function(double amount) convert;

  @override
  State<_CurrencyConverterCard> createState() => _CurrencyConverterCardState();
}

class _CurrencyConverterCardState extends State<_CurrencyConverterCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(widget.controller.text.trim()) ?? 0;
    final converted = widget.convert(amount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitelesTextWidget(
            label: widget.title,
            fontSize: 18,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: widget.inputLabel,
              prefixIcon: Icon(widget.inputIcon),
            ),
          ),
          const SizedBox(height: 16),
          SubtitleTextWidget(
            label: '${converted.toStringAsFixed(2)} ${widget.resultSuffix}',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.darkPrimary,
          ),
        ],
      ),
    );
  }
}

class _CurrencyErrorView extends StatelessWidget {
  const _CurrencyErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.darkPrimary,
              size: 42,
            ),
            const SizedBox(height: 12),
            SelectableText(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
