import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/visite_request.dart';

class CalendrierWidget extends StatefulWidget {
  final List<Visite> visites;

  const CalendrierWidget({super.key, required this.visites});

  @override
  State<CalendrierWidget> createState() => _CalendrierWidgetState();
}

class _CalendrierWidgetState extends State<CalendrierWidget> with TickerProviderStateMixin {
  late final Map<DateTime, List<Visite>> _visitesParDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _buildVisitesParDate();
    _selectedDay = _focusedDay;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant CalendrierWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visites != widget.visites) {
      _buildVisitesParDate();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _buildVisitesParDate() {
    _visitesParDate = {};
    for (var visite in widget.visites) {
      final date = DateTime.utc(
        visite.datePlanifiee.year,
        visite.datePlanifiee.month,
        visite.datePlanifiee.day,
      );
      _visitesParDate.putIfAbsent(date, () => []).add(visite);
    }
  }

  List<Visite> _getVisitesForDay(DateTime day) {
    return _visitesParDate[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _animationController.forward(from: 0.0);
    }
  }

void _showVisiteDetails(BuildContext context, Visite visite) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(visite.nomClient),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type : ${getLibelleType(visite.typeClient)}'),
            Text('Adresse : ${visite.adresse}'),
            Text('Téléphone : ${visite.numeroTelephone}'),
            Text('Email : ${visite.email}'),
            Text('Vendeur : ${visite.nomVendeur}'),
            Text(
              'Date : ${DateFormat('EEEE d MMMM y', 'fr_FR').format(visite.datePlanifiee)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      );
    },
  );
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final visitesPourJour = _selectedDay != null ? _getVisitesForDay(_selectedDay!) : [];
  final today = DateTime.now();

  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 400,  // hauteur fixe pour que TableCalendar s'affiche bien
              child: TableCalendar<Visite>(
                firstDay: DateTime(today.year - 1),
                lastDay: DateTime(today.year + 2, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onDaySelected: _onDaySelected,
                eventLoader: _getVisitesForDay,
                locale: 'fr_FR',
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.5),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor, width: 1.5),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.3),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  defaultDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  outsideDecoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  weekendDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                _selectedDay == null
                    ? 'Aucune date sélectionnée'
                    : DateFormat(' d MMMM y', 'fr_FR').format(_selectedDay!),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  '${visitesPourJour.length} visite${visitesPourJour.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: theme.primaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        visitesPourJour.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    _selectedDay == null
                        ? 'Sélectionnez une date pour voir les visites'
                        : 'Aucune visite programmée ce jour',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(), // désactive scroll interne
                shrinkWrap: true, // adapte la hauteur au contenu
                itemCount: visitesPourJour.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  final visite = visitesPourJour[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showVisiteDetails(context, visite),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              getClientIcon(visite.typeClient),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visite.nomClient,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Type: ${getLibelleType(visite.typeClient)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vendeur: ${visite.nomVendeur}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    ),
  );
}

  String getLibelleType(String typeClient) {
    switch (typeClient) {
      case 'WHS_WHOLESALERS':
        return 'Grossiste';
      case 'HFS_HIGH_FREQUENCY_STORES':
        return 'Épicerie fréquente';
      case 'SMM_SUPERMARKETS':
        return 'Supermarché';
      case 'PERF_PERFUMERIES':
        return 'Parfumerie';
      case 'LIVREUR':
        return 'Livreur';
      default:
        return 'Inconnu';
    }
  }

  Icon getClientIcon(String typeClient) {
    switch (typeClient) {
      case 'WHS_WHOLESALERS':
        return const Icon(Icons.business_center, color: Colors.deepPurple);
      case 'HFS_HIGH_FREQUENCY_STORES':
        return const Icon(Icons.store, color: Colors.orange);
      case 'SMM_SUPERMARKETS':
        return const Icon(Icons.shopping_cart, color: Colors.green);
      case 'PERF_PERFUMERIES':
        return const Icon(Icons.spa, color: Colors.pink);
      case 'LIVREUR':
        return const Icon(Icons.delivery_dining, color: Colors.blue);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}
