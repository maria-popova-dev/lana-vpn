import 'package:flutter/material.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnected = false;
  bool _isLoading = false;
  String _configText = '';
  String _displayIp = '0.0.0.0';

  final _authService = AuthService();
  final _wireguardPlugin = WireGuardFlutter.instance;

  @override
  void initState() {
    super.initState();
    _wireguardPlugin.initialize(interfaceName: 'LanaVpnInterface');
  }

  void _extractIpAddress(String config) {
    try {
      final regExp = RegExp(r'Address\s*=\s*([^\n]+)');
      final match = regExp.firstMatch(config);
      if (match != null && match.group(1) != null) {
        setState(() {
          _displayIp = match.group(1)!.replaceAll('/32', '').trim();
        });
      }
    } catch (e) {
      _displayIp = '10.0.0.3';
    }
  }

  void _toggleVpn() async {
    setState(() => _isLoading = true);

    try {
      if (_isConnected) {
        await _wireguardPlugin.stopVpn();
        setState(() {
          _isConnected = false;
          _configText = '';
          _displayIp = '0.0.0.0';
        });
      } else {
        final config = await _authService.getVpnConfig();

        if (config != null && !config.contains('Ошибка')) {

          await _wireguardPlugin.startVpn(
            serverAddress: '127.0.0.1:51820',
            wgQuickConfig: config,
            providerBundleIdentifier: 'com.example.lanavpn.WGExtension',
          );

          setState(() {
            _isConnected = true;
            _configText = config;
          });

          _extractIpAddress(config);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(config ?? 'Ошибка получения конфигурации')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Системная ошибка VPN: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lana VPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoading
                    ? 'ПОДГРУЗКА КОНФИГА...'
                    : (_isConnected ? 'ПОДКЛЮЧЕНО' : 'ОТКЛЮЧЕНО'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isLoading
                      ? Colors.orange
                      : (_isConnected ? Colors.greenAccent : Colors.grey),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: _isLoading ? null : _toggleVpn,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLoading
                        ? const Color(0xFF2A1F0A)
                        : (_isConnected ? const Color(0xFF1B5E20) : const Color(0xFF1A1A1E)),
                    border: Border.all(
                      color: _isLoading
                          ? Colors.orange
                          : (_isConnected ? Colors.greenAccent : const Color(0xFF6C63FF)),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isLoading
                            ? Colors.orange.withOpacity(0.2)
                            : (_isConnected
                            ? Colors.greenAccent.withOpacity(0.3)
                            : const Color(0xFF6C63FF).withOpacity(0.1)),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 5,
                      ),
                    )
                        : Icon(
                      Icons.power_settings_new,
                      size: 80,
                      color: _isConnected ? Colors.greenAccent : const Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (_isConnected && _configText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Card(
                    color: const Color(0xFF1A1A1E),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Соединение безопасно',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Протокол:', style: TextStyle(color: Colors.grey)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('WireGuard', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ваш VPN IP:', style: TextStyle(color: Colors.grey)),
                              Text(
                                _displayIp,
                                style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
