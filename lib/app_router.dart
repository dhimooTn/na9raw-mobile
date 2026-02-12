import 'package:go_router/go_router.dart';
import '../../models/course_model.dart';

// LAYOUTS
import 'layouts/visitor_layout.dart';
import 'layouts/auth_layout.dart';
import 'layouts/student_layout.dart';
import 'layouts/teacher_layout.dart';
import 'layouts/admin_layout.dart';

// VISITOR
import 'views/visitor/home_view.dart';
import 'views/visitor/about_view.dart';
import 'views/visitor/blog_view.dart';
import 'views/visitor/contact_view.dart';
import 'views/visitor/explore_courses_view.dart';
import 'views/visitor/course_detail_view.dart';
import 'views/visitor/subscription_plans_view.dart';
import 'views/visitor/signin_view.dart';
import 'views/visitor/signup_view.dart';

// STUDENT
import 'views/student/dashboard_view.dart';
import 'views/student/my_courses_view.dart';
import 'views/student/profile_view.dart';
import 'views/student/plans_view.dart';
import 'views/student/teach_view.dart';
import 'views/student/cart_view.dart';

// TEACHER
import 'views/teacher/dashboard_view.dart' as teacher;
import 'views/teacher/my_courses_view.dart' as teacher;
import 'views/teacher/create_course_view.dart';
import 'views/teacher/create_quiz_view.dart';
import 'views/teacher/profile_view.dart' as teacher;

// ADMIN
import 'views/admin/dashboard_view.dart' as admin;
import 'views/admin/course_management_view.dart';
import 'views/admin/user_management_view.dart';
import 'views/admin/payments_view.dart';
import 'views/admin/promotion_view.dart';
import 'views/admin/profile_view.dart' as admin;

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    /// AUTH ROUTES (with AuthLayout - no bars)
    ShellRoute(
      builder: (context, state, child) => AuthLayout(child: child),
      routes: [
        GoRoute(
          path: '/signin',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SignInView(),
          ),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SignUpView(),
          ),
        ),
      ],
    ),

    /// VISITOR ROUTES (with VisitorLayout)
    ShellRoute(
      builder: (context, state, child) => VisitorLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeView(),
          ),
        ),
        GoRoute(
          path: '/about',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const AboutView(),
          ),
        ),
        GoRoute(
          path: '/blog',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const BlogView(),
          ),
        ),
        GoRoute(
          path: '/contact',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ContactView(),
          ),
        ),
        GoRoute(
          path: '/courses',
          pageBuilder: (context, state) {
            final category = state.uri.queryParameters['category'];
            return NoTransitionPage(
              key: state.pageKey,
              child: ExploreCoursesView(initialCategory: category),
            );
          },
        ),
        GoRoute(
          path: '/courses/:id',
          pageBuilder: (context, state) {
            final courseId = state.pathParameters['id'] ?? '';
            return NoTransitionPage(
              key: state.pageKey,
              child: CourseDetailView(courseId: courseId),
            );
          },
        ),
        GoRoute(
          path: '/plans',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SubscriptionPlansView(),
          ),
        ),
      ],
    ),

    /// STUDENT ROUTES (with StudentLayout)
    ShellRoute(
      builder: (context, state, child) => StudentLayout(child: child),
      routes: [
        GoRoute(
          path: '/student',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const StudentDashboardView(),
          ),
        ),
        GoRoute(
          path: '/student/mycourses',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const MyCoursesView(),
          ),
        ),
        GoRoute(
          path: '/student/course/:id',
          pageBuilder: (context, state) {
            final courseId = state.pathParameters['id'] ?? '';
            return NoTransitionPage(
              key: state.pageKey,
              child: CourseDetailView(courseId: courseId),
            );
          },
        ),
        GoRoute(
          path: '/student/cart',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CartView(),
          ),
        ),
        GoRoute(
          path: '/student/profile',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProfileView(),
          ),
        ),
        GoRoute(
          path: '/student/plans',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const PlansView(),
          ),
        ),
        GoRoute(
          path: '/student/teach',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TeachView(),
          ),
        ),
      ],
    ),

    /// TEACHER ROUTES (with TeacherLayout)
    ShellRoute(
      builder: (context, state, child) => TeacherLayout(child: child),
      routes: [
        GoRoute(
          path: '/teacher',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const teacher.DashboardView(),
          ),
        ),
        GoRoute(
          path: '/teacher/my-courses',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const teacher.MyCoursesView(),
          ),
        ),
        // Route pour créer un nouveau cours
        GoRoute(
          path: '/teacher/create-course',
          pageBuilder: (context, state) {
            // Récupérer les données extra si présentes
            final extra = state.extra as Map<String, dynamic>?;
            final course = extra?['course'] as CourseModel?;
            final isEditing = extra?['isEditing'] as bool? ?? false;

            return NoTransitionPage(
              key: state.pageKey,
              child: CreateCourseView(
                course: course,
                isEditing: isEditing,
              ),
            );
          },
        ),
        GoRoute(
          path: '/teacher/create-quiz',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CreateQuizView(),
          ),
        ),
        GoRoute(
          path: '/teacher/profile',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const teacher.ProfileView(),
          ),
        ),
      ],
    ),

    /// ADMIN ROUTES (with AdminLayout)
    ShellRoute(
      builder: (context, state, child) => AdminLayout(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const admin.DashboardView(),
          ),
        ),
        GoRoute(
          path: '/admin/courses',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CourseManagementView(),
          ),
        ),
        GoRoute(
          path: '/admin/users',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const UserManagementView(),
          ),
        ),
        GoRoute(
          path: '/admin/payments',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const PaymentsView(),
          ),
        ),
        GoRoute(
          path: '/admin/promotions',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const PromotionView(),
          ),
        ),
        GoRoute(
          path: '/admin/profile',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const admin.ProfileView(),
          ),
        ),
      ],
    ),
  ],
);