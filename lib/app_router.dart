/// App Router
/// Defines all navigation routes using go_router for the Khata app.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/business/presentation/screens/business_list_screen.dart';
import 'features/business/presentation/screens/add_edit_business_screen.dart';
import 'features/customers/presentation/screens/customer_list_screen.dart';
import 'features/customers/presentation/screens/supplier_list_screen.dart';
import 'features/customers/presentation/screens/add_edit_party_screen.dart';
import 'features/transactions/presentation/screens/party_ledger_screen.dart';
import 'features/cashbook/presentation/screens/cashbook_screen.dart';
import 'features/cashbook/presentation/screens/add_cash_entry_screen.dart';
import 'features/cashbook/domain/entities/cash_entry_entity.dart';
import 'features/stock/presentation/screens/stock_screen.dart';
import 'features/stock/presentation/screens/add_edit_product_screen.dart';
import 'features/stock/presentation/screens/product_ledger_screen.dart';
import 'features/stock/presentation/screens/stock_in_screen.dart';
import 'features/stock/presentation/screens/stock_out_screen.dart';
import 'features/invoice/presentation/screens/invoice_list_screen.dart';
import 'features/invoice/presentation/screens/create_invoice_screen.dart';
import 'features/invoice/presentation/screens/invoice_preview_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/transactions/presentation/screens/give_screen.dart';
import 'features/transactions/presentation/screens/receive_screen.dart';
import 'features/register/presentation/screens/khareed_list_screen.dart';
import 'features/register/presentation/screens/add_edit_khareed_screen.dart';
import 'features/register/presentation/screens/farokht_list_screen.dart';
import 'features/register/presentation/screens/add_edit_farokht_screen.dart';
import 'features/register/presentation/screens/kharcha_list_screen.dart';
import 'features/register/presentation/screens/add_edit_kharcha_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isGoingToAuth = state.matchedLocation == '/auth';
    final isGoingToSplash = state.matchedLocation == '/';
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';
    
    if (isGoingToSplash || isGoingToOnboarding) return null; // Let splash/onboarding decide initial routing
    
    if (!isLoggedIn && !isGoingToAuth) {
      return '/auth';
    }
    
    if (isLoggedIn && isGoingToAuth) {
      return '/home';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'businesses',
          name: 'businessList',
          builder: (context, state) => const BusinessListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addBusiness',
              builder: (context, state) => const AddEditBusinessScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              name: 'editBusiness',
              builder: (context, state) =>
                  AddEditBusinessScreen(businessId: state.pathParameters['id']),
            ),
          ],
        ),
        GoRoute(
          path: 'customers',
          name: 'customerList',
          builder: (context, state) => const CustomerListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addCustomer',
              builder: (context, state) =>
                  const AddEditPartyScreen(isCustomer: true),
            ),
            GoRoute(
              path: 'edit/:id',
              name: 'editCustomer',
              builder: (context, state) => AddEditPartyScreen(
                isCustomer: true,
                partyId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'ledger/:id',
              name: 'customerLedger',
              builder: (context, state) =>
                  PartyLedgerScreen(partyId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'suppliers',
          name: 'supplierList',
          builder: (context, state) => const SupplierListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addSupplier',
              builder: (context, state) =>
                  const AddEditPartyScreen(isCustomer: false),
            ),
            GoRoute(
              path: 'edit/:id',
              name: 'editSupplier',
              builder: (context, state) => AddEditPartyScreen(
                isCustomer: false,
                partyId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'ledger/:id',
              name: 'supplierLedger',
              builder: (context, state) =>
                  PartyLedgerScreen(partyId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'cashbook',
          name: 'cashbook',
          builder: (context, state) => const CashbookScreen(),
          routes: [
            GoRoute(
              path: 'add_cash_entry',
              name: 'addCashEntry',
              builder: (context, state) {
                final entry = state.extra as CashEntryEntity?;
                return AddCashEntryScreen(existingEntry: entry);
              },
            ),
          ],
        ),
        // ─── Stock Routes ───
        GoRoute(
          path: 'stock',
          name: 'stockList',
          builder: (context, state) => const StockScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addProduct',
              builder: (context, state) => const AddEditProductScreen(),
            ),
            GoRoute(
              path: 'edit/:id',
              name: 'editProduct',
              builder: (context, state) => AddEditProductScreen(
                  productId: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'ledger/:id',
              name: 'productLedger',
              builder: (context, state) => ProductLedgerScreen(
                  productId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'in/:id',
              name: 'stockIn',
              builder: (context, state) => StockInScreen(
                  productId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'out/:id',
              name: 'stockOut',
              builder: (context, state) => StockOutScreen(
                  productId: state.pathParameters['id']!),
            ),
          ],
        ),
        // ─── Invoice Routes ───
        GoRoute(
          path: 'invoices',
          name: 'invoiceList',
          builder: (context, state) => const InvoiceListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'createInvoice',
              builder: (context, state) => const CreateInvoiceScreen(),
            ),
            GoRoute(
              path: 'preview/:id',
              name: 'invoicePreview',
              builder: (context, state) => InvoicePreviewScreen(
                  invoiceId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // ─── Party Give/Receive Routes ───
    GoRoute(
      path: '/parties/give/:partyId',
      name: 'give',
      builder: (context, state) => GiveScreen(
        partyId: state.pathParameters['partyId']!,
      ),
    ),
    GoRoute(
      path: '/parties/receive/:partyId',
      name: 'receive',
      builder: (context, state) => ReceiveScreen(
        partyId: state.pathParameters['partyId']!,
      ),
    ),
    // ─── Register Routes (Khareed / Farokht / Kharcha) ───
    GoRoute(
      path: '/khareed',
      builder: (_, __) => const KhareedListScreen(),
    ),
    GoRoute(
      path: '/khareed/add',
      builder: (_, __) => const AddEditKhareedScreen(),
    ),
    GoRoute(
      path: '/khareed/edit/:id',
      builder: (ctx, state) => AddEditKhareedScreen(
          editId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/farokht',
      builder: (_, __) => const FarokhtListScreen(),
    ),
    GoRoute(
      path: '/farokht/add',
      builder: (_, __) => const AddEditFarokhtScreen(),
    ),
    GoRoute(
      path: '/farokht/edit/:id',
      builder: (ctx, state) => AddEditFarokhtScreen(
          editId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/kharcha',
      builder: (_, __) => const KharchaListScreen(),
    ),
    GoRoute(
      path: '/kharcha/add',
      builder: (_, __) => const AddEditKharchaScreen(),
    ),
    GoRoute(
      path: '/kharcha/edit/:id',
      builder: (ctx, state) => AddEditKharchaScreen(
          editId: state.pathParameters['id']),
    ),
  ],
);
