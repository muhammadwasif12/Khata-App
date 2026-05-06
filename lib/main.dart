import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/business/data/models/business_model.dart';
import 'features/customers/data/models/party_model.dart';
import 'features/transactions/data/models/transaction_model.dart';
import 'features/cashbook/data/models/cash_entry_model.dart';
import 'features/stock/data/models/product_model.dart';
import 'features/stock/data/models/stock_entry_model.dart';
import 'features/invoice/data/models/invoice_model.dart';
import 'features/invoice/data/models/invoice_item_model.dart';
import 'features/register/data/models/khareed_model.dart';
import 'features/register/data/models/farokht_model.dart';
import 'features/register/data/models/kharcha_model.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/services/firebase_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(BusinessModelAdapter().typeId))
      Hive.registerAdapter(BusinessModelAdapter());
    if (!Hive.isAdapterRegistered(PartyModelAdapter().typeId))
      Hive.registerAdapter(PartyModelAdapter());
    if (!Hive.isAdapterRegistered(TransactionModelAdapter().typeId))
      Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(CashEntryModelAdapter().typeId))
      Hive.registerAdapter(CashEntryModelAdapter());
    if (!Hive.isAdapterRegistered(ProductModelAdapter().typeId))
      Hive.registerAdapter(ProductModelAdapter());
    if (!Hive.isAdapterRegistered(StockEntryModelAdapter().typeId))
      Hive.registerAdapter(StockEntryModelAdapter());
    if (!Hive.isAdapterRegistered(InvoiceModelAdapter().typeId))
      Hive.registerAdapter(InvoiceModelAdapter());
    if (!Hive.isAdapterRegistered(InvoiceItemModelAdapter().typeId))
      Hive.registerAdapter(InvoiceItemModelAdapter());
    if (!Hive.isAdapterRegistered(KhareedModelAdapter().typeId))
      Hive.registerAdapter(KhareedModelAdapter());
    if (!Hive.isAdapterRegistered(FarokhtModelAdapter().typeId))
      Hive.registerAdapter(FarokhtModelAdapter());
    if (!Hive.isAdapterRegistered(KharchaModelAdapter().typeId))
      Hive.registerAdapter(KharchaModelAdapter());

    if (!Hive.isBoxOpen(AppConstants.businessBox))
      await Hive.openBox<BusinessModel>(AppConstants.businessBox);
    if (!Hive.isBoxOpen(AppConstants.partyBox))
      await Hive.openBox<PartyModel>(AppConstants.partyBox);
    if (!Hive.isBoxOpen(AppConstants.transactionBox))
      await Hive.openBox<TransactionModel>(AppConstants.transactionBox);
    if (!Hive.isBoxOpen(AppConstants.cashEntryBox))
      await Hive.openBox<CashEntryModel>(AppConstants.cashEntryBox);
    if (!Hive.isBoxOpen(AppConstants.productBox))
      await Hive.openBox<ProductModel>(AppConstants.productBox);
    if (!Hive.isBoxOpen(AppConstants.stockEntryBox))
      await Hive.openBox<StockEntryModel>(AppConstants.stockEntryBox);
    if (!Hive.isBoxOpen(AppConstants.invoiceBox))
      await Hive.openBox<InvoiceModel>(AppConstants.invoiceBox);
    if (!Hive.isBoxOpen(AppConstants.invoiceItemBox))
      await Hive.openBox<InvoiceItemModel>(AppConstants.invoiceItemBox);
    if (!Hive.isBoxOpen(AppConstants.settingsBox))
      await Hive.openBox(AppConstants.settingsBox);
    if (!Hive.isBoxOpen('khareed')) await Hive.openBox<KhareedModel>('khareed');
    if (!Hive.isBoxOpen('farokht')) await Hive.openBox<FarokhtModel>('farokht');
    if (!Hive.isBoxOpen('kharcha')) await Hive.openBox<KharchaModel>('kharcha');

    runApp(
      DevicePreview(
        enabled: false,
        builder: (context) => const ProviderScope(child: KhataApp()),
      ),
    );
  } catch (e, stack) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'App Initialization Error:\n\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KhataApp extends ConsumerStatefulWidget {
  const KhataApp({super.key});

  @override
  ConsumerState<KhataApp> createState() => _KhataAppState();
}

class _KhataAppState extends ConsumerState<KhataApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Enable real-time auto sync
    FirebaseSyncService().enableAutoSync();

    // Auto-restore on fresh install with existing session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null &&
          Hive.box<BusinessModel>(AppConstants.businessBox).isEmpty) {
        FirebaseSyncService().restoreAllData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Automatically backup data to Firebase when app goes to background
      FirebaseSyncService().backupAllData().catchError((e) {
        debugPrint('Auto-backup failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      locale: DevicePreview.locale(context) ?? const Locale('ur', 'PK'),
      supportedLocales: const [Locale('ur', 'PK'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final preview = DevicePreview.appBuilder(context, child);
        return Directionality(textDirection: TextDirection.rtl, child: preview);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
