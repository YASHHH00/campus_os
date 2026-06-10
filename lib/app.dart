import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/home/presentation/home_screen.dart';
import 'features/laptop_sync/presentation/bloc/sync_bloc.dart';
import 'features/lost_found/presentation/bloc/lost_found_bloc.dart';
import 'features/expense_splitter/presentation/bloc/expense_bloc.dart';
import 'features/timetable/presentation/bloc/timetable_bloc.dart';
import 'features/note_scanner/presentation/bloc/note_scanner_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'injection_container.dart' as di;

class CampusOsApp extends StatelessWidget {
  const CampusOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SyncBloc>(
          create: (_) => di.sl<SyncBloc>(),
        ),
        BlocProvider<LostFoundBloc>(
          create: (_) => di.sl<LostFoundBloc>(),
        ),
        BlocProvider<ExpenseBloc>(
          create: (_) => di.sl<ExpenseBloc>(),
        ),
        BlocProvider<TimetableBloc>(
          create: (_) => di.sl<TimetableBloc>(),
        ),
        BlocProvider<NoteScannerBloc>(
          create: (_) => di.sl<NoteScannerBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Campus OS',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
