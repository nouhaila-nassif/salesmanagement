import 'package:flutter/material.dart';
import '../../models/login_request.dart';
import '../../services/auth_service.dart';
import '../home/home_page.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;
  bool isLoading = false;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final request = LoginRequest(
        nomUtilisateur: _usernameController.text,
        motDePasse: _passwordController.text,
      );

      final token = await AuthService.login(request);
      final decodedToken = JwtDecoder.decode(token);
      final nomUser = decodedToken['sub'] ?? decodedToken['nom'];
      final roleUser = decodedToken['role'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
builder: (context) => HomePage(
  userRole: roleUser,
  userName: nomUser,
  onLogout: () async {
    await AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  },
  onNavigate: (route, {arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  },
),
        ),
      );
    } catch (e) {
      setState(() {
        error = 'Échec de la connexion';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

   Widget buildForm() {
    return SizedBox.expand( // ↔️↕️ prend toute la moitié droite (100% largeur & hauteur)
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white.withOpacity(0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // centré verticalement
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_box	, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Connexion',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    labelText: 'Nom utilisateur',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _login,
                    icon: const Icon(Icons.login),
                    label: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
 
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          if (isLargeScreen) {
            // 🖥️ Web/Desktop : image à gauche + formulaire
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('/login.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(child: buildForm()),
              ],
            );
          } else {
            // 📱 Mobile : image en arrière-plan
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  '/login.jpg',
                  fit: BoxFit.cover,
                ),
                Container(color: Colors.black.withOpacity(0.3)), // filtre foncé
                buildForm(),
              ],
            );
          }
        },
      ),
    );
  }
}
