// ignore_for_file: dangling_library_doc_comments, file_names

/// Exemplo de como integrar o device token registration no AuthProvider
/// 
/// Adicione este código ao seu AuthProvider após um login bem-sucedido:
/// 
/// ```dart
/// import 'package:shared_preferences/shared_preferences.dart';
/// import 'services/notification_service.dart';
/// 
/// class AuthProvider extends ChangeNotifier {
///   // ... código existente ...
/// 
///   Future<bool> login(String email, String password) async {
///     try {
///       // ... código de login ...
/// 
///       // Após login bem-sucedido, registrar device token
///       await _registerDeviceTokenWithBackend();
/// 
///       notifyListeners();
///       return true;
///     } catch (e) {
///       // ... tratamento de erro ...
///       return false;
///     }
///   }
/// 
///   Future<void> _registerDeviceTokenWithBackend() async {
///     try {
///       final prefs = await SharedPreferences.getInstance();
///       final token = prefs.getString('device_token');
/// 
///       if (token != null) {
///         // Enviar token para backend
///         final response = await _dio.post(
///           '/notifications/device-token',
///           data: {
///             'device_token': token,
///             'device_type': Platform.isIOS ? 'ios' : 'android',
///             'device_name': 'Device Name', // Opcional
///           },
///         );
/// 
///         if (response.statusCode == 200) {
///           print('Device token registrado com sucesso no backend');
///         }
///       }
///     } catch (e) {
///       print('Erro ao registrar device token: $e');
///     }
///   }
/// 
///   Future<void> logout() async {
///     try {
///       // ... código de logout ...
/// 
///       // Remover todos os device tokens do backend
///       await _dio.delete('/notifications/device-token');
/// 
///       notifyListeners();
///     } catch (e) {
///       // ... tratamento de erro ...
///     }
///   }
/// }
/// ```
/// 
/// Exemplo de eventos para Analytics:
/// 
/// ```dart
/// import 'services/notification_service.dart';
/// 
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
/// 
/// class _MyScreenState extends State<MyScreen> {
///   @override
///   void initState() {
///     super.initState();
///     // Log screen view
///     NotificationService().logScreenView(screenName: 'my_screen');
///   }
/// 
///   void onVideoPlayed(String videoId) {
///     // Log event
///     NotificationService().logEvent(
///       name: 'video_played',
///       parameters: {
///         'video_id': videoId,
///         'timestamp': DateTime.now().toIso8601String(),
///       },
///     );
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       // ... sua UI ...
///     );
///   }
/// }
/// ```
/// 
/// Exemplo de tratamento de erros com Crashlytics:
/// 
/// ```dart
/// import 'services/notification_service.dart';
/// 
/// try {
///   // Algum código que pode gerar erro
///   await doSomethingRisky();
/// } catch (e, stackTrace) {
///   NotificationService().recordException(e, stackTrace);
///   // Também pode mostrar um SnackBar para o usuário
/// }
/// ```
