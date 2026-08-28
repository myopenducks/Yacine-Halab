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
  String get revenue => isFrench ? 'Chiffre d\'affaires' : 'Revenue';
  String get totalStockValue => isFrench ? 'Valeur totale du stock' : 'Total Stock Value';
  String get itemsCount => isFrench ? 'articles' : 'items';
  String get noData => isFrench ? 'Aucune donnée' : 'No data';

  // ── Periods & Filters ───────────────────────────────────────────
  String get today => isFrench ? "Aujourd'hui" : 'Today';
  String get week => isFrench ? 'Semaine' : 'Week';
  String get month => isFrench ? 'Mois' : 'Month';
  String get pickMonth => isFrench ? 'Choisir mois' : 'Pick month';
  String get range => isFrench ? 'Période' : 'Range';
  String get all => isFrench ? 'Tout' : 'All';
  String get debts => isFrench ? 'Dettes' : 'Debts';
  String get allCategories => isFrench ? 'Toutes les catégories' : 'All categories';
  String get search => isFrench ? 'Rechercher…' : 'Search…';

  // ── Products ────────────────────────────────────────────────────
  String get products => isFrench ? 'Produits' : 'Products';
  String get editProduct => isFrench ? 'Modifier le produit' : 'Edit product';
  String get productName => isFrench ? 'Nom du produit' : 'Product name';
  String get category => isFrench ? 'Catégorie' : 'Category';
  String get selectCategory => isFrench ? 'Sélectionner une catégorie' : 'Select a category';
  String get purchasePrice => isFrench ? 'Prix d\'achat (DA)' : 'Purchase (DA)';
  String get sellingPrice => isFrench ? 'Prix de vente (DA)' : 'Selling (DA)';
  String get quantity => isFrench ? 'Quantité' : 'Quantity';
  String get imageUrlOptional => isFrench ? 'URL de l\'image (optionnel)' : 'Image URL (optional)';
  String get deleteProduct => isFrench ? 'Supprimer le produit' : 'Delete product';
  String get deleteProductConfirm => isFrench
      ? 'Êtes-vous sûr de vouloir supprimer ce produit ?'
      : 'Are you sure you want to delete this product?';
  String get productSaved => isFrench ? 'Produit enregistré avec succès' : 'Product saved successfully';
  String get productDeleted => isFrench ? 'Produit supprimé avec succès' : 'Product deleted successfully';
  String get moneyNote => isFrench
      ? 'Les montants sont enregistrés en Dinars Algériens (DA).'
      : 'Money is stored as whole DA (no decimals).';
  String get fillRequiredFields => isFrench
      ? 'Veuillez remplir tous les champs obligatoires'
      : 'Please fill in all required fields';
  String get noProductsFound => isFrench ? 'Aucun produit trouvé' : 'No products found';
  String get inStock => isFrench ? 'En stock' : 'In stock';
  String get outOfStock => isFrench ? 'Rupture de stock' : 'Out of stock';

  // ── Sales & Cart (with Dynamic Pricing) ─────────────────────────
  String get searchProducts => isFrench ? 'Rechercher des produits…' : 'Search products…';
  String get cartItems => isFrench ? 'Articles du panier' : 'Cart items';
  String get confirmSale => isFrench ? 'Confirmer la vente' : 'Confirm Sale';
  String get customerName => isFrench ? 'Nom du client' : 'Customer Name';
  String get customerOptional => isFrench ? 'Client (optionnel)' : 'Customer (optional)';
  String get notes => isFrench ? 'Notes' : 'Notes';
  String get notesOptional => isFrench ? 'Notes (optionnel)' : 'Notes (optional)';
  String get amountPaid => isFrench ? 'Montant payé (DA)' : 'Amount Paid (DA)';
  String get total => isFrench ? 'Total' : 'Total';
  String get outstandingDebt => isFrench ? 'Dette restante' : 'Outstanding Debt';
  String get paid => isFrench ? 'Payé' : 'Paid';
  String get due => isFrench ? 'Restant' : 'Due';
  String get remaining => isFrench ? 'Reste à payer' : 'Remaining';
  String get debtStatus => isFrench ? 'Dette en cours' : 'Unpaid Debt';
  String get paymentComplete => isFrench ? 'Paiement complet' : 'Fully Paid';
  String get recordPayment => isFrench ? 'Enregistrer paiement' : 'Record Payment';
  String get payFull => isFrench ? 'Régler tout' : 'Pay Full';
  String get markFullyPaid => isFrench ? 'Marquer comme payé' : 'Mark as Fully Paid';
  String get availableProducts => isFrench ? 'Produits disponibles' : 'Available Products';
  String get saveChanges => isFrench ? 'Enregistrer' : 'Save Changes';
  String get cancel => isFrench ? 'Annuler' : 'Cancel';
  String get confirm => isFrench ? 'Confirmer' : 'Confirm';
  String get delete => isFrench ? 'Supprimer' : 'Delete';
  String get items => isFrench ? 'Articles' : 'Items';
  String get editCustomerNotes => isFrench ? 'Modifier client et notes' : 'Edit Customer & Notes';
  String get clearCart => isFrench ? 'Vider le panier' : 'Clear cart';
  String get cartEmpty => isFrench ? 'Votre panier est vide' : 'Your cart is empty';
  String get editPrice => isFrench ? 'Modifier le prix' : 'Edit price';
  String get customPrice => isFrench ? 'Prix personnalisé' : 'Custom price';
  String get unitPriceLabel => isFrench ? 'Prix unitaire (DA)' : 'Unit Price (DA)';
  String get saleConfirmed => isFrench ? 'Vente enregistrée avec succès' : 'Sale confirmed successfully';
  String get enterValidPrice => isFrench ? 'Veuillez saisir un prix valide' : 'Please enter a valid price';

  // ── Sales History & Details ─────────────────────────────────────
  String get salesHistory => isFrench ? 'Historique des ventes' : 'Sales History';
  String get deleteSale => isFrench ? 'Supprimer la vente' : 'Delete Sale';
  String get deleteSaleConfirm => isFrench
      ? 'Êtes-vous sûr de vouloir supprimer cette vente ? Les articles seront remis en stock.'
      : 'Are you sure you want to delete this sale? Items will be restored to stock.';
  String get saleDeleted => isFrench
      ? 'Vente supprimée et stock restauré avec succès'
      : 'Sale deleted and stock restored successfully';
  String get saleDetails => isFrench ? 'Détails de la vente' : 'Sale Details';
  String get paymentHistory => isFrench ? 'Historique des règlements' : 'Payment History';
  String get addPayment => isFrench ? 'Ajouter un règlement' : 'Add Payment';
  String get paymentAdded => isFrench ? 'Règlement enregistré' : 'Payment recorded';
  String get paymentAmount => isFrench ? 'Montant du paiement (DA)' : 'Payment amount (DA)';
  String get noSalesRecorded => isFrench ? 'Aucune vente enregistrée' : 'No sales recorded yet';
  String get longPressToDelete => isFrench
      ? 'Appui long pour supprimer une vente'
      : 'Long press a sale to delete';

  // ── Profile & Settings ──────────────────────────────────────────
  String get store => isFrench ? 'Boutique' : 'Store';
  String get appSettings => isFrench ? 'Paramètres de l\'application' : 'App Settings';
  String get theme => isFrench ? 'Thème' : 'Theme';
  String get language => isFrench ? 'Langue' : 'Language';
  String get about => isFrench ? 'À propos' : 'About';
  String get signOut => isFrench ? 'Se déconnecter' : 'Sign Out';
  String get signOutConfirm => isFrench
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to sign out?';
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
