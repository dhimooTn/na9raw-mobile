// cart_view.dart - UPDATED with real user data and enrollment creation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/course_model.dart';
import '/models/enrollment_model.dart';
import '/models/user_model.dart';
import '/services/cart_service.dart';
import '/services/paymee_service.dart';
import '/services/enrollment_service.dart';
import '/services/user_service.dart';
import '/widgets/paymee_webview.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final CartService _cartService = CartService();
  final PaymeeService _paymeeService = PaymeeService();
  final EnrollmentService _enrollmentService = EnrollmentService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProcessingPayment = false;
  UserModel? _currentUser;
  String? _paymentToken; // Store payment token for verification

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChanged);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await _userService.getUserById(user.uid);
        setState(() {
          _currentUser = userData;
        });
      } catch (e) {
        debugPrint('Error loading user: $e');
      }
    }
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<CourseModel> get cartItems => _cartService.cartItems;
  double get totalPrice => _cartService.totalPrice;

  void _removeItem(String id) {
    _cartService.removeFromCart(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from cart'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleCheckout() async {
    if (cartItems.isEmpty) return;

    // Check if user is logged in
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to complete your purchase'),
          backgroundColor: Colors.orange,
        ),
      );
      context.go('/login');
      return;
    }

    // Ensure user data is loaded
    if (_currentUser == null) {
      await _loadCurrentUser();
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load user information'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Generate unique order ID
      final orderId = 'ORDER_${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}';

      // Create payment with Paymee using real user data
      final paymentResponse = await _paymeeService.createPayment(
        amount: totalPrice,
        orderNote: 'Purchase of ${cartItems.length} course(s): ${cartItems.map((c) => c.title).join(", ")}',
        firstName: _currentUser!.displayName?.split(' ').first ?? 'User',
        lastName: _currentUser!.displayName?.split(' ').skip(1).join(' ') ?? '',
        email: _currentUser!.email,
        phone:   '+21600000000', // Use actual phone or default
        webhookUrl: 'https://your-backend.com/api/paymee/webhook', // TODO: Your webhook endpoint
        orderId: orderId,
      );

      if (paymentResponse == null) {
        throw Exception('Failed to create payment session');
      }

      // Store payment token for verification
      _paymentToken = paymentResponse.token;

      setState(() {
        _isProcessingPayment = false;
      });

      // Open WebView for payment
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymeeWebView(
            paymentUrl: paymentResponse.paymentUrl,
            onPaymentResult: (success, transactionId) =>
                _handlePaymentResult(success, transactionId, orderId),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handlePaymentResult(bool success, String? transactionId, String orderId) async {
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show processing message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing payment and creating enrollments...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final userRef = _firestore.doc('users/${currentUser.uid}');
      final purchasedCourses = List<CourseModel>.from(cartItems);

      // Create enrollments for each course
      for (final course in purchasedCourses) {
        final courseRef = _firestore.doc('courses/${course.id}');

        // Check if already enrolled
        final existingEnrollment = await _enrollmentService.getUserCourseEnrollment(
          currentUser.uid,
          course.id,
        );

        if (existingEnrollment == null) {
          // Create new enrollment
          final enrollmentRef = await _enrollmentService.createEnrollment(
            userRef: userRef,
            courseRef: courseRef,
            accessType: AccessType.single,
            paymentRef: null, // You can create a payment document and reference it here
            progress: 0.0,
            completedLessons: [],
            status: EnrollmentStatus.active,
            completedQuizzes: [],
            quizAttempts: [],
          );

          // Add enrollment to user's coursesEnrolled array
          await _userService.addEnrolledCourse(currentUser.uid, enrollmentRef);

          debugPrint('✅ Created enrollment for course: ${course.title}');
        } else {
          debugPrint('ℹ️ User already enrolled in: ${course.title}');
        }
      }

      // Clear cart after successful enrollment
      _cartService.clearCart();

      if (!mounted) return;

      // Show success dialog
      _showSuccessDialog(purchasedCourses, totalPrice);
    } catch (e) {
      debugPrint('Error creating enrollments: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful but enrollment error: $e'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showSuccessDialog(List<CourseModel> purchasedCourses, double totalAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
        ),
        title: const Text(
          'Purchase Successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your payment of \$${totalAmount.toStringAsFixed(2)} has been processed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'You are now enrolled in:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...purchasedCourses.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/student/mycourses');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to My Courses',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        centerTitle: true,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(colorScheme)
          : _buildCartContent(colorScheme),
    );
  }

  Widget _buildEmptyCart(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Browse courses and add them to your cart',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/courses'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Courses'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.2),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cartItems.length} ${cartItems.length == 1 ? 'course' : 'courses'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Total: \$${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              Badge(
                label: Text(cartItems.length.toString()),
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.shopping_cart,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItem(item, colorScheme);
            },
          ),
        ),
        _buildCheckoutSection(colorScheme),
      ],
    );
  }

  Widget _buildCheckoutSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', '\$${totalPrice.toStringAsFixed(2)}', colorScheme),
                const SizedBox(height: 8),
                _buildSummaryRow('Discount', '-\$0.00', colorScheme, isDiscount: true),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow('Total', '\$${totalPrice.toStringAsFixed(2)}', colorScheme, isBold: true, isLarge: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/courses'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue Shopping', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CourseModel course, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                course.thumbnail ?? 'https://via.placeholder.com/100',
                width: 100,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 70,
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.image, color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${course.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeItem(course.id),
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Remove from cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ColorScheme colorScheme,
      {bool isBold = false, bool isLarge = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.red : colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.red : colorScheme.primary,
          ),
        ),
      ],
    );
  }
}