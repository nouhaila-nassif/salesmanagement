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
import '../../widgets/navigation_bar.dart';

class HomePage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments}) onNavigate;

  const HomePage({
    Key? key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  }) : super(key: key);

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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMainKPISection(),
             _buildStatisticsSection(
  currentUserRole: 'ADMIN' // Remplacez par la variable contenant le rôle réel
),
              _buildChartsSection(),
            ],
          ),
        ),
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
                    value: "${NumberFormat.currency(locale: 'fr', symbol: 'DH').format(totalCA)}",
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
                    value: "${NumberFormat.currency(locale: 'fr', symbol: 'DH').format(avgCA)}",
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📈 Statistiques",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Version pour grands écrans (affichage côte à côte)
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  if (currentUserRole == 'ADMIN') ...[
                    Expanded(
                      child: _buildUserStatsByRoleSection(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _buildClientStatsSection(),
                  ),
                ],
              );
            } 
            // Version pour petits écrans (affichage en colonne)
            else {
              return Column(
                children: [
                  if (currentUserRole == 'ADMIN') _buildUserStatsByRoleSection(),
                  if (currentUserRole == 'ADMIN') const SizedBox(height: 12),
                  _buildClientStatsSection(),
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
      
      // Compter les utilisateurs par rôle
      final usersByRole = groupBy(snapshot.data!, (user) => user.role);
      
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Statistiques Utilisateurs par Rôle",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Afficher le nombre total
              Text(
                "Total: ${snapshot.data!.length} utilisateurs",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Afficher la répartition par rôle
              ...usersByRole.entries.map((entry) {
                final role = entry.key;
                final count = entry.value.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getRoleColor(role),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$role: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(role),
                        ),
                      ),
                      Text('$count utilisateurs'),
                    ],
                  ),
                );
              }).toList(),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
          BarChartData(
  alignment: BarChartAlignment.spaceAround,
  maxY: sortedTypes.isNotEmpty ? sortedTypes.first.value.toDouble() * 1.1 : 10, // 10% de marge
  minY: 0,
  barTouchData: BarTouchData(
    enabled: true,
    touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
      // Gestion personnalisée du touché
    },
    touchTooltipData: BarTouchTooltipData(
      tooltipBgColor: Colors.blueGrey,
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        if (rod.toY == 0) return null; // Ne pas afficher pour les valeurs nulles
        return BarTooltipItem(
          '${sortedTypes[group.x.toInt()].key}\n${rod.toY.toInt()} clients',
          const TextStyle(color: Colors.white, fontSize: 12),
        );
      },
      tooltipMargin: 8,
      tooltipRoundedRadius: 8,
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      tooltipPadding: const EdgeInsets.all(8),
    ),
    handleBuiltInTouches: true, // Modifié pour mieux gérer les interactions
  ),
  titlesData: FlTitlesData(
    show: true,
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value.toInt() >= sortedTypes.length) return const SizedBox();
          final type = sortedTypes[value.toInt()].key;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _abbreviateClientType(type),
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
        reservedSize: 40,
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: _calculateInterval(sortedTypes.isNotEmpty 
            ? sortedTypes.first.value.toDouble() 
            : 10),
        getTitlesWidget: (value, meta) {
          return Text(
            value.toInt().toString(),
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
  ),
  borderData: FlBorderData(
    show: true,
    border: Border.all(color: const Color(0xff37434d), width: 0.5),
  ),
  gridData: FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: _calculateInterval(sortedTypes.isNotEmpty 
        ? sortedTypes.first.value.toDouble() 
        : 10),
    getDrawingHorizontalLine: (value) {
      return FlLine(
        color: Colors.grey.withOpacity(0.15),
        strokeWidth: 1,
      );
    },
  ),
  barGroups: sortedTypes.asMap().entries.map((entry) {
    final index = entry.key;
    final type = entry.value;
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: type.value.toDouble(),
          color: _getClientTypeColor(type.key),
          width: 20,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: sortedTypes.isNotEmpty 
                ? sortedTypes.first.value.toDouble() 
                : 10,
            color: Colors.grey.withOpacity(0.05),
          ),
        ),
      ],
    );
  }).toList(),
),
    ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: sortedTypes.map((entry) {
                final color = _getClientTypeColor(entry.key);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_abbreviateClientType(entry.key)} (${entry.value})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
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
                Expanded(
                  child: _buildMonthlyEvolutionChart(commandesParMois),
                ),
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
      if (cmd.dateCreation != null) {
        final date = DateTime.parse(cmd.dateCreation!);
        if (date.year == now.year) {
          result[date.month - 1] = (result[date.month - 1] ?? 0) + 1;
        }
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