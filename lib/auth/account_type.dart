import 'package:flutter/material.dart';

enum AccountType { foodBusiness, charity }

class FieldSpec {
  final String key;
  final String label;
  final String? placeholder;
  final String helper;
  final String requiredMessage;
  final TextInputType keyboardType;
  const FieldSpec({
    required this.key,
    required this.label,
    required this.helper,
    required this.requiredMessage,
    this.placeholder,
    this.keyboardType = TextInputType.text,
  });
}

class DocSpec {
  final String title;
  final String helper;
  const DocSpec(this.title, this.helper);
}

class AccountConfig {
  final List<FieldSpec> orgFields;
  final List<DocSpec> documents;
  const AccountConfig({required this.orgFields, required this.documents});
}

/// Edit the labels, hints and required documents for each account type HERE.
const _foodBusiness = AccountConfig(
  orgFields: [
    FieldSpec(
      key: 'company_name',
      label: 'Company name',
      helper: 'Registered name, exactly as shown on your SSM certificate.',
      requiredMessage: 'Please enter your company name',
    ),
    FieldSpec(
      key: 'registration_no',
      label: 'SSM registration no.',
      helper: '12-digit number on your SSM certificate, e.g. 202301012345.',
      requiredMessage: 'Please enter your SSM registration number',
    ),
    FieldSpec(
      key: 'business_type',
      label: 'Business type',
      helper: 'e.g. Supermarket, bakery, restaurant or food manufacturer.',
      requiredMessage: 'Please enter your business type',
    ),
    FieldSpec(
      key: 'address',
      label: 'Business address',
      helper: 'Full address of your main premises, with postcode and state.',
      requiredMessage: 'Please enter your business address',
      keyboardType: TextInputType.streetAddress,
    ),
  ],
  documents: [
    DocSpec(
      'SSM certificate (Form 9 or 13)',
      'Company registration certificate from SSM.',
    ),
    DocSpec(
      'Business or premises licence',
      'Valid licence issued by your local council.',
    ),
    DocSpec(
      "Director's or owner's ID (NRIC or passport)",
      'NRIC front and back, or passport photo page.',
    ),
    DocSpec(
      'Halal or food safety certificate',
      'e.g. JAKIM Halal or MeSTI certificate.',
    ),
  ],
);

const _charity = AccountConfig(
  orgFields: [
    FieldSpec(
      key: 'company_name',
      label: 'Organisation name',
      helper: 'Name exactly as shown on your registration certificate.',
      requiredMessage: 'Please enter your organisation name',
    ),
    FieldSpec(
      key: 'registration_no',
      label: 'Registration no.',
      helper: 'Your ROS or SSM registration number from your certificate.',
      requiredMessage: 'Please enter your registration number',
    ),
    FieldSpec(
      key: 'business_type',
      label: 'Organisation type',
      helper: 'e.g. Food bank, soup kitchen, shelter or community NGO.',
      requiredMessage: 'Please enter your organisation type',
    ),
    FieldSpec(
      key: 'address',
      label: 'Organisation address',
      helper:
          'Full address of your office or distribution centre, with '
          'postcode and state.',
      requiredMessage: 'Please enter your organisation address',
      keyboardType: TextInputType.streetAddress,
    ),
  ],
  documents: [
    DocSpec(
      'Registration certificate (ROS or SSM)',
      'Proof that your organisation is legally registered.',
    ),
    DocSpec(
      'Proof of address',
      'Recent utility bill or tenancy agreement for your office.',
    ),
    DocSpec(
      "Representative's ID (NRIC or passport)",
      'NRIC front and back, or passport photo page.',
    ),
    DocSpec(
      'Authorisation letter',
      'Signed letter on your letterhead authorising you to register.',
    ),
  ],
);

extension AccountTypeX on AccountType {
  AccountConfig get config =>
      this == AccountType.foodBusiness ? _foodBusiness : _charity;
}
