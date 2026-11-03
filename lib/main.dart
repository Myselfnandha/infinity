import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/providers.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: InfinityApp(),
    ),
  );
}

class InfinityApp extends ConsumerStatefulWidget {
  const InfinityApp({super.key});

  @override
  ConsumerState<InfinityApp> createState() => _InfinityAppState();
}

class _InfinityAppState extends ConsumerState<InfinityApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tdlibServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      title: 'Infinity',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: const CupertinoThemeData(),
    );
  }
}
