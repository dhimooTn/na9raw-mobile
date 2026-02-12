// widgets/paymee_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymeeWebView extends StatefulWidget {
  final String paymentUrl;
  final Function(bool success, String? transactionId) onPaymentResult;

  const PaymeeWebView({
    super.key,
    required this.paymentUrl,
    required this.onPaymentResult,
  });

  @override
  State<PaymeeWebView> createState() => _PaymeeWebViewState();
}

class _PaymeeWebViewState extends State<PaymeeWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Check if we reached the loader page (payment completed)
            if (url.contains('/loader') && !_paymentCompleted) {
              _paymentCompleted = true;
              _handlePaymentCompletion();
            }
          },
          onNavigationRequest: (NavigationRequest request) {

            // Check for loader URL
            if (request.url.contains('/loader') && !_paymentCompleted) {
              _paymentCompleted = true;
              _handlePaymentCompletion();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentCompletion() {
    // Wait a moment to ensure webhook is processed
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Close the webview
        Navigator.of(context).pop();

        // Notify parent that payment process is complete
        // The actual verification should be done via webhook
        widget.onPaymentResult(true, null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paymee Payment'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment gateway...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close webview
              widget.onPaymentResult(false, null);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}