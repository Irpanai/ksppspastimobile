import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import 'doku_webview_screen.dart';

/// Layar Webview Pembayaran (Midtrans kompatibilitas ke DOKU Checkout)
class MidtransWebViewScreen extends StatelessWidget {
  final SnapTokenResponse snapResponse;

  const MidtransWebViewScreen({
    super.key,
    required this.snapResponse,
  });

  @override
  Widget build(BuildContext context) {
    return DokuWebViewScreen(paymentResponse: snapResponse);
  }
}
