import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final List<DonationRequest> _requests = List.of(donationRequests);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      subtitle: 'Inventory · Donate',
      body: Column(
        children: [
          Expanded(
            child: ListCard(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: _requests.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: kBorder),
                itemBuilder: (_, i) {
                  final r = _requests[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        ItemThumb(path: r.image),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: kText)),
                              const SizedBox(height: 2),
                              Text('Request by: ${r.requestedBy}',
                                  style: const TextStyle(
                                      fontSize: 8, color: kGrey)),
                              Text('quantity: ${r.quantity} packs',
                                  style: const TextStyle(
                                      fontSize: 8, color: kGrey)),
                            ],
                          ),
                        ),
                        GreenPillButton(
                          label: 'Confirm donation',
                          height: 22,
                          fontSize: 9,
                          onPressed: () {
                            // TODO: save donation to backend
                            setState(() => _requests.removeAt(i));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('${r.name} donation confirmed')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}