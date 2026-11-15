import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/validators.dart';
import '../widgets/auth_footer.dart';
import '../widgets/auth_page.dart';
import '../widgets/back_next_row.dart';
import '../widgets/labeled_field.dart';
import '../widgets/register_header.dart';
import '../theme/app_colors.dart';
import 'account_type.dart';
import 'documents_screen.dart';

/// Step 2: organisation details + contact and login.
/// Used for BOTH account types - the labels/hints come from account_type.dart.
class OrganisationScreen extends StatefulWidget {
  final AccountType accountType;
  const OrganisationScreen({super.key, required this.accountType});

  @override
  State<OrganisationScreen> createState() => _OrganisationScreenState();
}

class _OrganisationScreenState extends State<OrganisationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AccountConfig _config = widget.accountType.config;
  late final List<TextEditingController> _orgCtrls = List.generate(
    _config.orgFields.length,
    (_) => TextEditingController(),
  );
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in _orgCtrls) {
      c.dispose();
    }
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Everything the user typed, ready to send to your backend at the end.
    final data = <String, String>{
      for (var i = 0; i < _config.orgFields.length; i++)
        _config.orgFields[i].key: _orgCtrls[i].text.trim(),
      'contact_person': _contactCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DocumentsScreen(accountType: widget.accountType, orgData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RegisterHeader(step: 2, stepTitle: 'Organisation'),
            const SizedBox(height: 12),
            const SectionLabel('Organisation'),
            const SizedBox(height: 14),
            ...List.generate(_config.orgFields.length, (i) {
              final spec = _config.orgFields[i];
              return LabeledField(
                label: spec.label,
                helper: spec.helper,
                placeholder: spec.placeholder,
                controller: _orgCtrls[i],
                keyboardType: spec.keyboardType,
                textCapitalization: TextCapitalization.words,
                validator: Validators.notEmpty(spec.requiredMessage),
              );
            }),
            const SizedBox(height: 4),
            const SectionLabel('Contact and login'),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Contact person',
              placeholder: 'Your name',
              helper: 'Person who will handle verification and manage this account.',
              controller: _contactCtrl,
              textCapitalization: TextCapitalization.words,
              validator: Validators.notEmpty('Please enter the contact name'),
            ),
            LabeledField(
              label: 'Phone number',
              placeholder: '012-3456789',
              helper: 'Malaysian number we can reach you on, e.g. 012-3456789.',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
              validator: Validators.phone,
            ),
            LabeledField(
              label: 'Work email',
              helper:
                  'You will use this to log in and get verification updates.',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            LabeledField(
              label: 'Password',
              helper: 'At least 8 characters, with letters and numbers.',
              controller: _passCtrl,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 8),
            BackNextRow(nextLabel: 'Continue', onNext: _continue),
            const SizedBox(height: 16),
            const AuthFooter(),
          ],
        ),
      ),
    );
  }
}
