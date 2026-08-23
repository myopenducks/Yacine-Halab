import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class AppStrings {
  const AppStrings(this.isFrench);

  final bool isFrench;

  // ── Navigation ──────────────────────────────────────────────────
  String get navHome => isFrench ? 'Accueil' : 'Home';
  String get navProducts => isFrench ? 'Produits' : 'Products';
  String get navSale => isFrench ? 'Vente' : 'Sale';
  String get navHistory => isFrench ? 'Historique' : 'History';
  String get navProfile => isFrench ? 'Profil' : 'Profile';

  // ── Dashboard ───────────────────────────────────────────────────
  String get helloWelcome => isFrench ? 'Bonjour, Bienvenue 👋' : 'Hello, Welcome 👋';
  String get todayOverview => isFrench ? "Aujourd'hui" : 'Today overview';
  String get sales => isFrench ? 'Ventes' : 'Sales';
  String get profit => isFrench ? 'Bénéfice' : 'Profit';
  String get itemsSold => isFrench ? 'Articles vendus' : 'Items sold';
  String get lowStock => isFrench ? 'Stock faible' : 'Low stock';
  String get stockByCategory => isFrench ? 'Stock par catégorie' : 'Stock by category';
  String get quickActions => isFrench ? 'Actions rapides' : 'Quick actions';
  String get newSale => isFrench ? 'Nouvelle vente' : 'New sale';
  String get addProduct => isFrench ? 'Ajouter produit' : 'Add product';

  // ── Periods ─────────────────────────────────────────────────────
  String get today => isFrench ? "Aujourd'hui" : 'Today';
  String get week => isFrench ? 'Semaine' : 'Week';
  String get month => isFrench ? 'Mois' : 'Month';
  String get pickMonth => isFrench ? 'Choisir mois' : 'Pick month';
  String get range => isFrench ? 'Période' : 'Range';
  String get all => isFrench ? 'Tout' : 'All';
  String get debts => isFrench ? 'Dettes' : 'Debts';

  // ── Sales & Cart ────────────────────────────────────────────────
  String get searchProducts => isFrench ? 'Rechercher des produits…' : 'Search products…';
  String get cartItems => isFrench ? 'Articles du panier' : 'Cart items';
  String get confirmSale => isFrench ? 'Confirmer la vente' : 'Confirm Sale';
  String get customerName => isFrench ? 'Nom du client' : 'Customer Name';
  String get notes => isFrench ? 'Notes / Remarques' : 'Notes';
  String get amountPaid => isFrench ? 'Montant payé (DA)' : 'Amount Paid (DA)';
  String get outstandingDebt => isFrench ? 'Dette restante' : 'Outstanding Debt';
  String get paid => isFrench ? 'Payé' : 'Paid';
  String get due => isFrench ? 'Restant' : 'Due';
  String get recordPayment => isFrench ? 'Enregistrer paiement' : 'Record Payment';
  String get markFullyPaid => isFrench ? 'Marquer comme payé' : 'Mark as Fully Paid';
  String get availableProducts => isFrench ? 'Produits disponibles' : 'Available Products';
  String get inStock => isFrench ? 'En stock' : 'In stock';
  String get outOfStock => isFrench ? 'Rupture de stock' : 'Out of stock';

  // ── Profile & Settings ──────────────────────────────────────────
  String get store => isFrench ? 'Boutique' : 'Store';
  String get appSettings => isFrench ? 'Application' : 'App';
  String get theme => isFrench ? 'Thème' : 'Theme';
  String get language => isFrench ? 'Langue' : 'Language';
  String get about => isFrench ? 'À propos' : 'About';
  String get signOut => isFrench ? 'Se déconnecter' : 'Sign Out';
  String get productsInventory => isFrench ? 'Inventaire des produits' : 'Products inventory';
  String get lowStockAlerts => isFrench ? 'Alertes stock faible' : 'Low stock alerts';
  String get english => 'English 🇬🇧';
  String get french => 'Français 🇫🇷';
  String get systemDefault => isFrench ? 'Système par défaut' : 'System default';
  String get light => isFrench ? 'Clair' : 'Light';
  String get dark => isFrench ? 'Sombre' : 'Dark';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale.languageCode == 'fr');
});
