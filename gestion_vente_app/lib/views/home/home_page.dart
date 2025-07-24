import 'dart:math';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_vente_app/models/commande_dto.dart';
import 'package:gestion_vente_app/models/utilisateur_response.dart';
import '../../models/client.dart';
import '../../services/client_service.dart';
import '../../services/commande_service.dart';
import '../../services/utilisateur_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/EvolutionChart.dart';
import '../../widgets/navigation_bar.dart';

class HomePage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments}) onNavigate;

  const HomePage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Client>> _clientsFuture;
  late Future<List<CommandeDTO>> _commandesFuture;
  late Future<List<UtilisateurResponse>> _utilisateursFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Widget _buildEvolutionChartParPeriode(List<CommandeDTO> commandes) {
  return EvolutionChartParPeriode(commandes: commandes);
}


  void _loadData() {
    _clientsFuture = ClientService.getAllClients();
    _commandesFuture = CommandeService.getCommandes();
    _utilisateursFuture = UtilisateurService.getAllUtilisateurs();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
    await Future.wait([_clientsFuture, _commandesFuture, _utilisateursFuture]);
  }

  Map<String, int> countBy<T>(List<T> items, String Function(T) keySelector) {
    final map = <String, int>{};
    for (var item in items) {
      final key = keySelector(item);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Tableau de Bord'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
          onPressed: _refreshData,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Déconnexion',
          onPressed: () async {
            await AuthService.logout();
            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
          },
        ),
      ],
    ),
    drawer: MainNavigationBar(
      userRole: widget.userRole,
      userName: widget.userName,
      onLogout: widget.onLogout,
      onNavigate: widget.onNavigate,
      currentRoute: ModalRoute.of(context)?.settings.name ?? "/home",
      newOrdersCount: 5,
    ),
    body: Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMainKPISection(),

               

                _buildStatisticsSection(currentUserRole: 'ADMIN'),
                _buildChartsSection(),
              ],
            ),
          ),
        ),

        // Bulle assistant flottante à droite
Positioned(
  right: 16,        // ← ici, à droite
  bottom: 32,
  child: FloatingActionButton(
    backgroundColor: Theme.of(context).primaryColor,
    heroTag: 'assistantChatBtn',
    onPressed: () {
      Navigator.pushNamed(context, '/ia');
    },
    tooltip: "Comment puis-je vous aider ?",
    child: const Icon(Icons.chat_bubble_outline, size: 28),
  ),
),

      ],
    ),
  );
}


  Widget _buildMainKPISection() {
    return FutureBuilder(
      future: Future.wait([_commandesFuture, _clientsFuture, _utilisateursFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('Chargement des KPI...');
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard('Erreur de chargement des données', _refreshData);
        }
        
        final commandes = snapshot.data?[0] as List<CommandeDTO>? ?? [];
        final clients = snapshot.data?[1] as List<Client>? ?? [];
        final utilisateurs = snapshot.data?[2] as List<UtilisateurResponse>? ?? [];
        
        final totalCommandes = commandes.length;
        final totalClients = clients.length;
        final totalUtilisateurs = utilisateurs.length;
        
        double totalCA = commandes.fold(0, (sum, cmd) => sum + (cmd.montantTotal ?? 0));
        double avgCA = totalCommandes > 0 ? totalCA / totalCommandes : 0;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📊 KPI Principaux",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildKPICard(
                    title: "Chiffre d'Affaires",
                    value: NumberFormat.currency(locale: 'fr', symbol: 'DH').format(totalCA),
                    icon: Icons.attach_money,
                    color: Colors.green,
                    trend: _calculateTrend(commandes, (c) => c.montantTotal ?? 0),
                  ),
                  _buildKPICard(
                    title: "Commandes",
                    value: totalCommandes.toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    trend: _calculateTrend(commandes, (c) => 1),
                  ),
                  _buildKPICard(
                    title: "Panier Moyen",
                    value: NumberFormat.currency(locale: 'fr', symbol: 'DH').format(avgCA),
                    icon: Icons.assessment,
                    color: Colors.orange,
                  ),
                  _buildKPICard(
                    title: "Clients",
                    value: totalClients.toString(),
                    icon: Icons.people,
                    color: Colors.purple,
                    trend: _calculateTrend(clients, (c) => 1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? trend,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 28, color: color),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trend > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trend > 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: trend > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${trend.abs().toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            color: trend > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTrend<T>(List<T> currentData, double Function(T) valueExtractor) {
    if (currentData.isEmpty || currentData.length < 2) return 0.0;
    
    final half = (currentData.length / 2).ceil();
    final firstHalf = currentData.sublist(0, half);
    final secondHalf = currentData.sublist(half);
    
    final firstSum = firstHalf.fold(0.0, (sum, item) => sum + valueExtractor(item));
    final secondSum = secondHalf.fold(0.0, (sum, item) => sum + valueExtractor(item));
    
    if (firstSum == 0) return 0.0;
    return ((secondSum - firstSum) / firstSum) * 100;
  }

Widget _buildStatisticsSection({required String currentUserRole}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "📈 Statistiques",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blueAccent),
              onPressed: _refreshData,
              tooltip: "Actualiser les statistiques",
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              // ✅ Version grands écrans : deux colonnes équilibrées avec même hauteur
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (currentUserRole == 'ADMIN')
                      Expanded(
                        flex: 1,
                        child: _buildUserStatsByRoleSection(),
                      ),
                    if (currentUserRole == 'ADMIN') const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: _buildClientStatsSection(),
                    ),
                  ],
                ),
              );
            } else if (constraints.maxWidth > 600) {
              // ✅ Version écrans moyens : deux colonnes équilibrées
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (currentUserRole == 'ADMIN')
                      Expanded(
                        flex: 1,
                        child: _buildUserStatsByRoleSection(),
                      ),
                    if (currentUserRole == 'ADMIN') const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildClientStatsSection(),
                    ),
                  ],
                ),
              );
            } else {
              // ✅ Version mobiles : disposition verticale en colonne, même hauteur forcée
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentUserRole == 'ADMIN')
                    SizedBox(
                      height: 250, // ✅ même hauteur forcée
                      child: _buildUserStatsByRoleSection(),
                    ),
                  if (currentUserRole == 'ADMIN') const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: _buildClientStatsSection(),
                  ),
                ],
              );
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildUserStatsByRoleSection() {
  return FutureBuilder<List<UtilisateurResponse>>(
    future: _utilisateursFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingCard('Chargement des utilisateurs...');
      } else if (snapshot.hasError) {
        return _buildErrorCard('Erreur chargement utilisateurs', _refreshData);
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return _buildEmptyCard('Aucun utilisateur trouvé');
      }

      final usersByRole = groupBy(snapshot.data!, (user) => user.role);
      final roles = usersByRole.keys.toList();
      final maxCount = usersByRole.values
          .map((list) => list.length)
          .reduce((a, b) => a > b ? a : b);

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.bar_chart, color: Colors.blueAccent, size: 22),
                  SizedBox(width: 6),
                  Text(
                    "Statistiques Utilisateurs par Rôle",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Total: ${snapshot.data!.length} utilisateurs",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: BarChart(
                  BarChartData(
                    maxY: (maxCount + 2).toDouble(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, _) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index >= 0 && index < roles.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  roles[index],
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(roles.length, (index) {
                      final role = roles[index];
                      final count = usersByRole[role]!.length;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: count.toDouble(),
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                _getRoleColor(role).withOpacity(0.7),
                                _getRoleColor(role),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    }),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey[800],
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, _, rod, __) {
                          final role = roles[group.x.toInt()];
                          final count = rod.toY.toInt();
                          return BarTooltipItem(
                            "$role\n$count utilisateurs",
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildClientStatsSection() {
  return FutureBuilder<List<Client>>(
    future: _clientsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingCard('Chargement des clients...');
      } else if (snapshot.hasError) {
        return _buildErrorCard('Erreur chargement clients', _refreshData);
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return _buildEmptyCard('Aucun client trouvé');
      }
      return _buildClientsStats(snapshot.data!);
    },
  );
}

Color _getRoleColor(String role) {
  switch (role) {
    case 'ADMIN':
      return Colors.redAccent;
    case 'SUPERVISEUR':
      return Colors.blueAccent;
    case 'PREVENDEUR':
      return Colors.green;
    case 'VENDEURDIRECT':
      return Colors.orange;
    case 'UNITMANAGER':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}
 
 double _calculateInterval(double maxValue) {
  if (maxValue <= 10) return 1;
  if (maxValue <= 20) return 2;
  if (maxValue <= 50) return 5;
  if (maxValue <= 100) return 10;
  return (maxValue / 10).roundToDouble();
}

Widget _buildClientsStats(List<Client> clients) {
 

  final clientsParType = countBy(clients, (c) => c.type);
  final sortedTypes = clientsParType.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final maxValue = sortedTypes.first.value.toDouble();
  final interval = _calculateInterval(maxValue);
  final colors = sortedTypes.map((e) => _getClientTypeColor(e.key)).toList();

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Répartition des Clients par Type",
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              _buildBarChartData(sortedTypes, maxValue, interval, colors),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(sortedTypes, colors),
        ],
      ),
    ),
  );
}

BarChartData _buildBarChartData(
  List<MapEntry<String, int>> data,
  double maxValue,
  double interval,
  List<Color> colors,
) {
  return BarChartData(
    alignment: BarChartAlignment.spaceBetween,
    maxY: maxValue * 1.2, // 20% de marge pour meilleure visibilité
    minY: 0,
    barTouchData: BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: Colors.blueGrey,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final type = data[group.x.toInt()].key;
          return BarTooltipItem(
            '$type\n${rod.toY.toInt()} clients',
            const TextStyle(color: Colors.white),
          );
        },
      ),
      touchCallback: (event, response) {
        if (response != null && event is FlTapUpEvent) {
          // Gestion personnalisée du tap
        }
      },
    ),
    titlesData: FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= data.length) return const SizedBox();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(
                _abbreviateClientType(data[value.toInt()].key),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            );
          },
          reservedSize: 28,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: interval,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            );
          },
        ),
      ),
    ),
    borderData: FlBorderData(
      show: true,
      border: Border.all(
        color: Colors.grey.withOpacity(0.3),
        width: 0.8,
      ),
    ),
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: Colors.grey.withOpacity(0.1),
        strokeWidth: 1,
        dashArray: [4],
      ),
    ),
    barGroups: data.asMap().entries.map((entry) {
      final index = entry.key;
      final type = entry.value;
      return BarChartGroupData(
        x: index,
        barsSpace: 8,
        barRods: [
          BarChartRodData(
            toY: type.value.toDouble(),
            gradient: LinearGradient(
              colors: [
                colors[index].withOpacity(0.8),
                colors[index],
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 22,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue,
              color: Colors.grey.withOpacity(0.05),
            ),
          ),
        ],
        // CHANGEMENT ICI : enlever showingTooltipIndicators
        // Le tooltip s'affichera seulement au survol
      );
    }).toList(),
  );
}
Widget _buildLegend(List<MapEntry<String, int>> data, List<Color> colors) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colors[index],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_abbreviateClientType(type.key)} (${type.value})',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
  Widget _buildChartsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Graphiques des Commandes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<CommandeDTO>>(
            future: _commandesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingCard('Chargement des commandes...');
              } else if (snapshot.hasError) {
                return _buildErrorCard('Erreur chargement des commandes', _refreshData);
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyCard('Aucune commande trouvée');
              }
              return _buildCommandesCharts(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

 Widget _buildCommandesCharts(List<CommandeDTO> commandes) {
  final commandesParStatut = countBy(commandes, (c) => c.statut);
  final commandesParMois = _groupCommandesParMois(commandes);

  return LayoutBuilder(
    builder: (context, constraints) {
      // Afficher en ligne si l'écran est large (> 800px), sinon en colonne
      final isWideScreen = constraints.maxWidth > 800;

      return isWideScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Expanded(child: _buildEvolutionChartParPeriode(commandes)),

                const SizedBox(width: 16),
                Expanded(
                  child: _buildCommandesParStatutChart(commandesParStatut),
                ),
              ],
            )
          : Column(
              children: [
                _buildMonthlyEvolutionChart(commandesParMois),
                const SizedBox(height: 16),
                _buildCommandesParStatutChart(commandesParStatut),
              ],
            );
    },
  );
}

// Extrait le graphique mensuel dans une méthode séparée
Widget _buildMonthlyEvolutionChart(Map<int, int> commandesParMois) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Évolution Mensuelle",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: true),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final month = commandesParMois.keys.elementAt(value.toInt());
                        return Text(_getMonthAbbreviation(month));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: commandesParMois.length.toDouble() - 1,
                minY: 0,
                maxY: commandesParMois.values.reduce(max).toDouble() + 2,
                lineBarsData: [
                  LineChartBarData(
                    spots: commandesParMois.entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Fonction pour obtenir la couleur selon le statut
Widget _buildCommandesParClientChart(List<CommandeDTO> commandes, List<Client> clients) {
  final Map<String, int> commandesParClient = {};

  for (var cmd in commandes) {
    final clientIdStr = cmd.clientId?.toString() ?? 'unknown';
    commandesParClient[clientIdStr] = (commandesParClient[clientIdStr] ?? 0) + 1;
  }

  final clientNoms = { for (var c in clients) c.id.toString(): c.nom };

  final topClients = commandesParClient.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top10 = topClients.take(10).toList();

  return SizedBox(
    height: 300,
    child: BarChart(
      BarChartData(
        maxY: (top10.isNotEmpty) ? top10.first.value.toDouble() + 2 : 10,
        barGroups: top10.asMap().entries.map((entry) {
          int index = entry.key;
          var e = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: Colors.blue,
                width: 20,
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                int idx = value.toInt();
                if (idx < 0 || idx >= top10.length) return Container();
                final clientId = top10[idx].key;
                final nom = clientNoms[clientId] ?? 'Client $clientId';
                return SideTitleWidget(
                  axisSide: AxisSide.bottom,
                  child: Text(
                    nom,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    ),
  );
}

Color _getStatutColor(String statut) {
  // Convertir en minuscules et sans accents pour une comparaison plus large
  final statutLower = statut.toLowerCase().replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e');
  
  if (statutLower.contains('livre') || statutLower.contains('livré')) return Colors.green[400]!;
  if (statutLower.contains('en cours')) return Colors.orange[400]!;
  if (statutLower.contains('annule') || statutLower.contains('annulé') || statutLower.contains('annulee')) return Colors.red[400]!;
  if (statutLower.contains('en_attente')) return Colors.blue[400]!;
  if (statutLower.contains('expedie') || statutLower.contains('expédié')) return Colors.teal[400]!;
  if (statutLower.contains('retour')) return Colors.purple[400]!;
  if (statutLower.contains('valide') || statutLower.contains('validé')) return Colors.lightGreen[400]!;
  
  return Colors.grey[400]!; // Couleur par défaut
}

Widget _buildCommandesParStatutChart(Map<String, int> commandesParStatut) {
  final sortedStats = commandesParStatut.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Commandes par Statut",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sortedStats.first.value.toDouble() + 2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final statut = sortedStats[group.x.toInt()].key;
                      return BarTooltipItem(
                        '$statut\n${rod.toY.toInt()} commandes',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    // Cette callback permet de gérer le touché plus finement
                    if (response != null && event is FlTapUpEvent) {
                      // Le tooltip s'affichera seulement si une barre est touchée
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final statut = sortedStats[value.toInt()].key;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: -0.4,
                            child: Text(
                              statut,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 0.5),
                ),
                barGroups: sortedStats.asMap().entries.map((entry) {
                  final index = entry.key;
                  final statut = entry.value;
                  final color = _getStatutColor(statut.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: statut.value.toDouble(),
                        color: color,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



Map<int, int> _groupCommandesParMois(List<CommandeDTO> commandes) {
    final now = DateTime.now();
    final result = <int, int>{};
    
    // Initialiser les 12 derniers mois
    for (var i = 0; i < 12; i++) {
      result[i] = 0;
    }
    
    for (var cmd in commandes) {
      final date = DateTime.parse(cmd.dateCreation!);
      if (date.year == now.year) {
        result[date.month - 1] = (result[date.month - 1] ?? 0) + 1;
      }
        }
    
    return result;
  }


  Color _getClientTypeColor(String? type) {
    final cleaned = type?.toUpperCase().trim();
    switch (cleaned) {
      case 'WHS_WHOLESALERS':
        return Colors.indigo;
      case 'HFS_HIGH_FREQUENCY_STORES':
        return Colors.teal;
      case 'SMM_SUPERMARKETS':
        return Colors.orange;
      case 'PERF_PERFUMERIES':
        return Colors.pinkAccent;
      default:
        return Colors.grey;
    }
  }

  



  String _abbreviateClientType(String type) {
    if (type.length <= 10) return type;
    return type.split('_').map((e) => e[0]).join();
  }

 

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2023, month + 1));
  }

  String _getMonthAbbreviation(int month) {
    return DateFormat('MMM').format(DateTime(2023, month + 1));
  }

  Widget _buildLoadingCard(String message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback onRetry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 40, color: Colors.blue.shade400),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Badge({
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(child: child),
    );
  }
  
}
