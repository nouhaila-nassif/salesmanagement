import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/visite_request.dart';
import '../services/visite_service.dart';

class CalendrierWidget extends StatefulWidget {
  final List<Visite> visites;
  final VoidCallback? onVisiteUpdated; // Callback pour notifier les changements

  const CalendrierWidget({
    super.key, 
    required this.visites,
    this.onVisiteUpdated,
  });

  @override
  State<CalendrierWidget> createState() => _CalendrierWidgetState();
}

class _CalendrierWidgetState extends State<CalendrierWidget> 
    with TickerProviderStateMixin {
  bool isAdmin = true;
  late final Map<DateTime, List<Visite>> _visitesParDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _buildVisitesParDate();
    _selectedDay = _focusedDay;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant CalendrierWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visites != widget.visites) {
      _buildVisitesParDate();
      setState(() {}); // Force rebuild
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _buildVisitesParDate() {
    _visitesParDate = <DateTime, List<Visite>>{};
    for (var visite in widget.visites) {
      final date = DateTime.utc(
        visite.datePlanifiee.year,
        visite.datePlanifiee.month,
        visite.datePlanifiee.day,
      );
      _visitesParDate.putIfAbsent(date, () => <Visite>[]).add(visite);
    }
  }

  List<Visite> _getVisitesForDay(DateTime day) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return _visitesParDate[utcDay] ?? <Visite>[];
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

  // Méthode améliorée pour afficher les détails avec plus d'informations
  void _showVisiteDetails(BuildContext context, Visite visite) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              getClientIcon(visite.typeClient),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visite.nomClient,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.category, 'Type', getLibelleType(visite.typeClient)),
                _buildDetailRow(Icons.location_on, 'Adresse', visite.adresse),
                _buildDetailRow(Icons.phone, 'Téléphone', visite.numeroTelephone),
                _buildDetailRow(Icons.email, 'Email', visite.email),
                _buildDetailRow(Icons.person, 'Vendeur', visite.nomVendeur),
                _buildDetailRow(
                  Icons.calendar_today, 
                  'Date', 
                  DateFormat('EEEE d MMMM y', 'fr_FR').format(visite.datePlanifiee),
                ),
                _buildStatutChip(visite.statut),
              ],
            ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutChip(String statut) {
    Color couleur;
    IconData icone;
    
    switch (statut) {
      case 'REALISEE':
        couleur = Colors.green;
        icone = Icons.check_circle;
        break;
      case 'REPORTEE':
        couleur = Colors.orange;
        icone = Icons.schedule;
        break;
      case 'ANNULEE':
        couleur = Colors.red;
        icone = Icons.cancel;
        break;
      default:
        couleur = Colors.green;
        icone = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Chip(
        avatar: Icon(icone, size: 16, color: Colors.white),
        label: Text(
          statut,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: couleur,
      ),
    );
  }

  // Méthode améliorée avec gestion d'erreur et loading
  Future<void> _changerStatut(Visite visite, String nouveauStatut) async {
    if (_isLoading) return; // Évite les appels multiples
    
    setState(() => _isLoading = true);
    
    try {
      final updatedVisite = await _apiService.modifierStatutVisite(
        visiteId: visite.id,
        nouveauStatut: nouveauStatut,
      );

      setState(() {
        // Met à jour dans la map _visitesParDate
        final selectedDayUtc = DateTime.utc(
          _selectedDay!.year, 
          _selectedDay!.month, 
          _selectedDay!.day
        );
        final index = _visitesParDate[selectedDayUtc]?.indexWhere((v) => v.id == visite.id);
        if (index != null && index >= 0) {
          _visitesParDate[selectedDayUtc]![index] = updatedVisite;
        }

        // Met à jour dans la liste principale
        final mainIndex = widget.visites.indexWhere((v) => v.id == visite.id);
        if (mainIndex >= 0) {
          widget.visites[mainIndex] = updatedVisite;
        }
      });

      // Notifie le parent si callback fourni
      widget.onVisiteUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Statut modifié en $nouveauStatut'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur : $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Méthode pour confirmer les actions importantes
  Future<void> _confirmerChangementStatut(Visite visite, String nouveauStatut) async {
    if (nouveauStatut == 'ANNULEE') {
      final confirme = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: Text('Êtes-vous sûr de vouloir annuler la visite chez ${visite.nomClient} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Oui, annuler'),
            ),
          ],
        ),
      );
      
      if (confirme == true) {
        await _changerStatut(visite, nouveauStatut);
      }
    } else {
      await _changerStatut(visite, nouveauStatut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitesPourJour = _selectedDay != null ? _getVisitesForDay(_selectedDay!) : <Visite>[];
    final today = DateTime.now();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Calendrier avec animations améliorées
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 6,
                shadowColor: theme.primaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor.withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 400,
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.7),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade700, width: 2),
                          ),
                          defaultDecoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          outsideDecoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          weekendDecoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.05),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          formatButtonTextStyle: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
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
              ),
            ),
          ),

          // En-tête de section avec statistiques
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDay == null
                            ? 'Sélectionnez une date'
                            : DateFormat('EEEE d MMMM y', 'fr_FR').format(_selectedDay!),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${visitesPourJour.length} visite${visitesPourJour.length > 1 ? 's' : ''} programmée${visitesPourJour.length > 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (visitesPourJour.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${visitesPourJour.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Liste des visites avec loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (visitesPourJour.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDay == null
                        ? 'Sélectionnez une date pour voir les visites'
                        : 'Aucune visite programmée ce jour',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: visitesPourJour.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final visite = visitesPourJour[index];
                return _buildVisiteCard(context, visite, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVisiteCard(BuildContext context, Visite visite, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 3,
        shadowColor: theme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showVisiteDetails(context, visite),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.primaryColor.withOpacity(0.02),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Indicateur de statut
                  Container(
                    width: 4,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _getStatutColor(visite.statut),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Icône du type de client
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: getClientIcon(visite.typeClient),
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations de la visite
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visite.nomClient,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getLibelleType(visite.typeClient),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visite.nomVendeur,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatutColor(visite.statut).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatutColor(visite.statut).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            visite.statut,
                            style: TextStyle(
                              color: _getStatutColor(visite.statut),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Boutons d'action améliorés
                  Column(
                    children: [
                      _buildActionButton(
                        Icons.check_circle,
                        Colors.green,
                        'Réalisée',
                        () => _confirmerChangementStatut(visite, 'REALISEE'),
                      ),
                      const SizedBox(height: 4),
                      _buildActionButton(
                        Icons.schedule,
                        Colors.orange,
                        'Reportée',
                        () => _confirmerChangementStatut(visite, 'REPORTEE'),
                      ),
                      const SizedBox(height: 4),
                      _buildActionButton(
                        Icons.cancel,
                        Colors.red,
                        'Annulée',
                        () => _confirmerChangementStatut(visite, 'ANNULEE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isLoading ? null : onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'REALISEE':
        return Colors.green;
      case 'REPORTEE':
        return Colors.orange;
      case 'ANNULEE':
        return Colors.red;
      default:
        return Colors.lightBlueAccent;
    }
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