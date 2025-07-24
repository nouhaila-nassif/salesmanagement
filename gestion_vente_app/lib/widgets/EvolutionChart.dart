import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import '../models/client.dart';
import '../models/commande_dto.dart';

class EvolutionChartParPeriode extends StatefulWidget {
  final List<CommandeDTO> commandes;

  const EvolutionChartParPeriode({required this.commandes});

  @override
  State<EvolutionChartParPeriode> createState() => _EvolutionChartParPeriodeState();
}

class _EvolutionChartParPeriodeState extends State<EvolutionChartParPeriode> {
  String _selectedPeriod = 'Mois';
  String _selectedStatut = 'Tous';

  // Statuts correspondant à ton enum Java (ajoute 'Tous' pour tout afficher)
  final List<String> _statuts = [
    'Tous',
    'EN_ATTENTE',
    'VALIDEE',
    'LIVREE',
    'ANNULEE',
    'NON_LIVREE',
  ];

  // Optionnel: labels lisibles pour l’affichage
  final Map<String, String> _statutsLabels = {
    'Tous': 'Tous',
    'EN_ATTENTE': 'En attente',
    'VALIDEE': 'Validée',
    'LIVREE': 'Livrée',
    'ANNULEE': 'Annulée',
    'NON_LIVREE': 'Non livrée',
  };

  @override
  Widget build(BuildContext context) {
    // Filtrer les commandes selon le statut sélectionné
    final filteredCommandes = _selectedStatut == 'Tous'
        ? widget.commandes
        : widget.commandes.where((c) => c.statut == _selectedStatut).toList();

    // Grouper les commandes filtrées par période choisie
    final Map<String, int> groupedData = _groupCommandes(filteredCommandes, _selectedPeriod);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + Dropdowns période + statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Évolution des Commandes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items: ['Jour', 'Mois', 'Année']
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text("Par $value"),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedStatut,
                      items: _statuts
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_statutsLabels[value] ?? value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatut = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: groupedData.isNotEmpty ? groupedData.length.toDouble() - 1 : 0,
                  minY: 0,
                  maxY: groupedData.isNotEmpty
                      ? groupedData.values.reduce(max).toDouble() + 2
                      : 10,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index < 0 || index >= groupedData.length) return const Text('');
                          return Text(
                            groupedData.keys.elementAt(index),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(value.toInt().toString()),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      spots: groupedData.values
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                          .toList(),
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

  Map<String, int> _groupCommandes(List<CommandeDTO> commandes, String period) {
    final Map<String, int> result = {};

    for (var commande in commandes) {
      DateTime? date;
      if (commande.dateCreation is DateTime) {
        date = commande.dateCreation as DateTime;
      } else if (commande.dateCreation is String) {
        try {
          date = DateTime.parse(commande.dateCreation);
        } catch (_) {
          continue; // Ignore si date invalide
        }
      } else {
        continue; // Ignore données invalides
      }

      String key;
      switch (period) {
        case 'Jour':
          key = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
          break;
        case 'Année':
          key = date.year.toString();
          break;
        case 'Mois':
        default:
          key = "${date.month.toString().padLeft(2, '0')}/${date.year}";
          break;
      }

      result[key] = (result[key] ?? 0) + 1;
    }

    final sortedKeys = result.keys.toList()
      ..sort((a, b) {
        if (period == 'Année') return int.parse(a).compareTo(int.parse(b));
        if (period == 'Jour') {
          final partsA = a.split('/').map(int.parse).toList();
          final partsB = b.split('/').map(int.parse).toList();
          return DateTime(0, partsA[1], partsA[0]).compareTo(DateTime(0, partsB[1], partsB[0]));
        }
        final partsA = a.split('/').map(int.parse).toList();
        final partsB = b.split('/').map(int.parse).toList();
        return DateTime(partsA[1], partsA[0]).compareTo(DateTime(partsB[1], partsB[0]));
      });

    return {for (var k in sortedKeys) k: result[k]!};
  }
}
