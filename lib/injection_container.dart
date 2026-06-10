import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

// Core
import 'core/integration/integration_orchestrator.dart';
import 'core/network/supabase_client.dart';
import 'core/network/webrtc_service.dart';
import 'core/storage/isar_service.dart';
import 'core/storage/prefs_service.dart';

// Note Scanner
import 'features/note_scanner/data/datasources/ocr_remote_source.dart';
import 'features/note_scanner/domain/usecases/get_flashcards_usecase.dart';
import 'features/note_scanner/domain/usecases/get_summary_usecase.dart';
import 'features/note_scanner/domain/usecases/scan_note_usecase.dart';
import 'features/note_scanner/presentation/bloc/note_scanner_bloc.dart';

// Timetable
import 'features/timetable/domain/usecases/add_event_usecase.dart';
import 'features/timetable/domain/usecases/extract_deadline_usecase.dart';
import 'features/timetable/presentation/bloc/timetable_bloc.dart';

// Expense Splitter
import 'features/expense_splitter/domain/usecases/scan_receipt_usecase.dart';
import 'features/expense_splitter/domain/usecases/split_expense_usecase.dart';
import 'features/expense_splitter/presentation/bloc/expense_bloc.dart';

// Lost & Found
import 'features/lost_found/domain/usecases/claim_item_usecase.dart';
import 'features/lost_found/domain/usecases/post_lost_item_usecase.dart';
import 'features/lost_found/presentation/bloc/lost_found_bloc.dart';

// Laptop Sync
import 'features/laptop_sync/data/webrtc_sync_service.dart';
import 'features/laptop_sync/presentation/bloc/sync_bloc.dart';

final sl = GetIt.instance;

Future<void> init(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  // ── Core Services ──────────────────────────────────────────────────────────

  sl.registerLazySingleton(() => DatabaseService());
  sl.registerLazySingleton(() => PrefsService());
  sl.registerLazySingleton(() => SupabaseClientService());
  sl.registerLazySingleton(() => WebRtcService());
  
  // External
  sl.registerLazySingleton(() => flutterLocalNotificationsPlugin);

  // ── Note Scanner ───────────────────────────────────────────────────────────

  // Data
  sl.registerLazySingleton(() => OcrRemoteSource(webRtcService: sl()));

  // Usecases
  sl.registerLazySingleton(() => ScanNoteUsecase(
        databaseService: sl(),
        ocrRemoteSource: sl(),
      ));
  sl.registerLazySingleton(() => GetFlashcardsUsecase(databaseService: sl()));
  sl.registerLazySingleton(() => GetSummaryUsecase(databaseService: sl()));

  // BLoC
  sl.registerFactory(() => NoteScannerBloc(
        scanNoteUsecase: sl(),
        getFlashcardsUsecase: sl(),
        getSummaryUsecase: sl(),
        databaseService: sl(),
      ));

  // ── Timetable ──────────────────────────────────────────────────────────────

  // Usecases
  sl.registerLazySingleton(() => AddEventUsecase(
        databaseService: sl(),
        prefsService: sl(),
        notificationsPlugin: sl(),
      ));
  sl.registerLazySingleton(() => ExtractDeadlineUsecase(
        databaseService: sl(),
        ocrRemoteSource: sl(),
      ));

  // BLoC
  sl.registerFactory(() => TimetableBloc(
        addEventUsecase: sl(),
        extractDeadlineUsecase: sl(),
        databaseService: sl(),
      ));

  // ── Expense Splitter ───────────────────────────────────────────────────────

  // Usecases
  sl.registerLazySingleton(() => const SplitExpenseUsecase());
  sl.registerLazySingleton(() => ScanReceiptUsecase(ocrRemoteSource: sl()));

  // BLoC
  sl.registerFactory(() => ExpenseBloc(
        splitExpenseUsecase: sl(),
        scanReceiptUsecase: sl(),
        databaseService: sl(),
      ));

  // ── Lost & Found ───────────────────────────────────────────────────────────

  // Usecases
  sl.registerLazySingleton(() => PostLostItemUsecase(
        databaseService: sl(),
        supabaseService: sl(),
      ));
  sl.registerLazySingleton(() => ClaimItemUsecase(
        databaseService: sl(),
        supabaseService: sl(),
      ));

  // BLoC
  sl.registerFactory(() => LostFoundBloc(
        postLostItemUsecase: sl(),
        claimItemUsecase: sl(),
        databaseService: sl(),
        supabaseService: sl(),
      ));

  // ── Laptop Sync ────────────────────────────────────────────────────────────

  // Service
  sl.registerLazySingleton(() => WebRtcSyncService(
        webRtcService: sl(),
        supabaseService: sl(),
        databaseService: sl(),
      ));

  // BLoC
  sl.registerFactory(() => SyncBloc(syncService: sl()));

  // ── Integration Orchestrator ───────────────────────────────────────────────

  sl.registerLazySingleton(() => IntegrationOrchestrator(
        timetableBloc: sl(),
        expenseBloc: sl(),
      ));
}
