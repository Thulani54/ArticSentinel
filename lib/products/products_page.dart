import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../gasmon/gas_theme.dart';
import '../services/shared_preferences.dart';
import '../widgets/device_illustration.dart';
import '../widgets/mobile_forms.dart';
import 'product_catalog.dart';
import 'product_enquiry_api.dart';

/// Public catalogue, also reachable from the signed-in navigation.
class ProductsPage extends StatelessWidget {
  const ProductsPage({
    super.key,
    this.onLinkDevice,
    this.onBack,
    this.enquiryApi,
  });

  final ValueChanged<String>? onLinkDevice;
  final VoidCallback? onBack;
  final ProductEnquiryApi? enquiryApi;

  void _requestInformation(BuildContext context, ProductDefinition product) {
    showMobileDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductEnquiryDialog(
        initialProductType: product.type,
        api: enquiryApi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GasPalette.page,
        appBar: AppBar(
          title: const Text('Products'),
          leading: onBack == null
              ? null
              : IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Iconsax.arrow_left),
                ),
          backgroundColor: Colors.white,
          foregroundColor: GasPalette.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Choose what you want to monitor',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 29,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                        color: GasPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Explore the equipment supported by ArticSentinel. '
                      'Tell us what you need and our team will help you choose.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        height: 1.55,
                        color: GasPalette.ink2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Available readings depend on the sensors connected to your device.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.5,
                        color: GasPalette.ink2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    for (final product in ProductCatalog.products)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _ProductCard(
                          product: product,
                          onRequest: () =>
                              _requestInformation(context, product),
                          onLink: onLinkDevice == null
                              ? null
                              : () => onLinkDevice!(product.type),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onRequest,
    this.onLink,
  });

  final ProductDefinition product;
  final VoidCallback onRequest;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('product-${product.type}'),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GasPalette.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: GasPalette.panelAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DeviceIllustration(type: product.type, size: 68),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(product.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: GasPalette.ink,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(product.summary,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.5,
                    color: GasPalette.ink2)),
            const SizedBox(height: 16),
            for (final feature in product.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Iconsax.tick_circle,
                          size: 17, color: GasPalette.good),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(feature,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              height: 1.5,
                              color: GasPalette.ink)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: ValueKey('request-${product.type}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GasPalette.primary,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: GasPalette.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: onRequest,
              child: const Text('Request information'),
            ),
            if (onLink != null) ...[
              const SizedBox(height: 4),
              TextButton(
                  onPressed: onLink,
                  child: const Text('I have this device — link it')),
            ],
          ],
        ),
      );
}

class ProductEnquiryDialog extends StatefulWidget {
  const ProductEnquiryDialog({
    super.key,
    required this.initialProductType,
    this.api,
  });

  final String initialProductType;
  final ProductEnquiryApi? api;

  @override
  State<ProductEnquiryDialog> createState() => _ProductEnquiryDialogState();
}

class _ProductEnquiryDialogState extends State<ProductEnquiryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _message = TextEditingController();
  late final ProductEnquiryApi _api;
  late String _productType;
  bool _consent = false;
  bool _submitting = false;
  String? _error;
  String? _requestId;
  String? _requestSignature;
  ProductEnquiryReceipt? _receipt;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ProductEnquiryApi();
    _productType = ProductCatalog.byType(widget.initialProductType)?.type ??
        ProductCatalog.products.first.type;
    _prefillContact();
  }

  Future<void> _prefillContact() async {
    SharedPreferences preferences;
    try {
      preferences = await SharedPreferences.getInstance();
    } catch (_) {
      return; // Prefilling is optional; the public form still works.
    }
    final signedIn =
        preferences.getBool(Sharedprefs.sharedPreferenceUserLoggedInKey) ??
            false;
    final token =
        preferences.getString(Sharedprefs.sharedPreferenceAuthTokenKey) ?? '';
    if (!mounted || !signedIn || token.isEmpty) return;
    // A slow session read must not replace anything the visitor has typed.
    final fields = <TextEditingController, String>{
      _name: Sharedprefs.sharedPreferenceUserNameKey,
      _email: Sharedprefs.sharedPreferenceUserEmailKey,
      _phone: Sharedprefs.sharedPreferenceCellphoneNumberKey,
      _company: Sharedprefs.sharedPreferenceBusinessNameKey,
    };
    for (final field in fields.entries) {
      if (field.key.text.isEmpty) {
        field.key.text = preferences.getString(field.value) ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _company, _message]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (_submitting || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    // Keep the same identifier when a response is lost, so Retry cannot send
    // duplicate emails. Editing the request creates a new submission.
    final signature = jsonEncode([
      _name.text.trim(),
      _email.text.trim(),
      _phone.text.trim(),
      _company.text.trim(),
      _productType,
      _message.text.trim(),
    ]);
    if (_requestSignature != signature) {
      _requestId = const Uuid().v4();
      _requestSignature = signature;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final receipt = await _api.submit(ProductEnquiry(
        requestId: _requestId!,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        company: _company.text.trim(),
        productType: _productType,
        message: _message.text.trim(),
      ));
      if (mounted) setState(() => _receipt = receipt);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ProductEnquiryException
            ? error.message
            : 'We could not confirm your request. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: GasPalette.panelAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: GasPalette.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: GasPalette.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: GasPalette.primary)),
        errorMaxLines: 3,
      );

  Widget _field({
    required String label,
    required String id,
    required TextEditingController controller,
    required int maxLength,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          key: ValueKey('enquiry-$id'),
          controller: controller,
          enabled: !_submitting,
          decoration: _decoration(label).copyWith(counterText: ''),
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction:
              maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final phone = isPhoneLayout(context);
    return PopScope(
      canPop: !_submitting,
      child: MobileDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 580,
          height:
              phone ? double.infinity : MediaQuery.sizeOf(context).height * .86,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: GasPalette.primary,
                    surface: Colors.white,
                  ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 8, 12),
                  child: Row(children: [
                    const Expanded(
                      child: Text('Request information',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: GasPalette.ink)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: GasPalette.border),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: _receipt == null ? _buildForm() : _buildReceipt(),
                  ),
                ),
                const Divider(height: 1, color: GasPalette.border),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton(
                    key: const ValueKey('enquiry-submit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: GasPalette.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    onPressed: _submitting
                        ? null
                        : _receipt != null
                            ? () => Navigator.of(context).pop()
                            : _send,
                    child: _submitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Sending request…'),
                            ],
                          )
                        : Text(_receipt != null
                            ? 'Done'
                            : _error != null
                                ? 'Try again'
                                : 'Send request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() => Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us a little about what you need. The ArticSentinel team '
                'will contact you using the details below.',
                style: TextStyle(
                    fontFamily: 'Inter', color: GasPalette.ink2, height: 1.5),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                key: const ValueKey('enquiry-product'),
                initialValue: _productType,
                isExpanded: true,
                decoration: _decoration('Product'),
                items: [
                  for (final product in ProductCatalog.products)
                    DropdownMenuItem(
                      value: product.type,
                      child:
                          Text(product.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _productType = value);
                      },
              ),
              const SizedBox(height: 18),
              _field(
                label: 'Your name',
                id: 'name',
                controller: _name,
                maxLength: 120,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter your name.' : null,
              ),
              _field(
                label: 'Email address',
                id: 'email',
                controller: _email,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch((value ?? '').trim())
                    ? null
                    : 'Enter a valid email address.',
              ),
              _field(
                label: 'Phone number (optional)',
                id: 'phone',
                controller: _phone,
                maxLength: 40,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              _field(
                label: 'Company (optional)',
                id: 'company',
                controller: _company,
                maxLength: 160,
                autofillHints: const [AutofillHints.organizationName],
              ),
              _field(
                label: 'How can we help?',
                id: 'message',
                controller: _message,
                maxLength: 2000,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                validator: (value) => (value ?? '').trim().length < 10
                    ? 'Tell us what you need in at least 10 characters.'
                    : null,
              ),
              FormField<bool>(
                initialValue: false,
                validator: (_) => _consent
                    ? null
                    : 'Allow the team to contact you about this request.',
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      key: const ValueKey('enquiry-consent'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _consent,
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() => _consent = value ?? false);
                              field.didChange(_consent);
                            },
                      title: const Text(
                        'ArticSentinel may contact me about this request.',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 12),
                        child: Text(field.errorText!,
                            style: const TextStyle(
                                color: GasPalette.critInk, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GasPalette.critSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: GasPalette.critInk, height: 1.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildReceipt() => Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 32,
                backgroundColor: GasPalette.goodSoft,
                child: Icon(Iconsax.tick_circle,
                    color: GasPalette.goodInk, size: 34),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Request received',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: GasPalette.ink)),
            const SizedBox(height: 12),
            const Text(
              'Your request is with ArticSentinel. Our team will contact you '
              'about the product you selected.',
              style: TextStyle(
                  fontFamily: 'Inter', color: GasPalette.ink2, height: 1.6),
            ),
            const SizedBox(height: 24),
            Text(ProductCatalog.byType(_productType)!.title,
                style: const TextStyle(
                    color: GasPalette.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_email.text.trim(),
                style: const TextStyle(color: GasPalette.ink2)),
            const SizedBox(height: 24),
            const Text('Request reference',
                style: TextStyle(color: GasPalette.ink2, fontSize: 12)),
            const SizedBox(height: 6),
            SelectableText(_receipt!.reference,
                style: const TextStyle(color: GasPalette.ink, fontSize: 12)),
          ],
        ),
      );
}
