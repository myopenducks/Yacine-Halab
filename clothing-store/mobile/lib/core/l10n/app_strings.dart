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
  String get monthLabel => isFrench ? 'Mois' : 'Month';
  String get yearLabel => isFrench ? 'Année' : 'Year';
  String get thisWeek => isFrench ? 'Cette semaine' : 'This week';
  String get thisMonth => isFrench ? 'Ce mois-ci' : 'This month';
  String get range => isFrench ? 'Période' : 'Range';
  String get all => isFrench ? 'Tout' : 'All';
  String get debts => isFrench ? 'Dettes' : 'Debts';
  String get allCategories => isFrench ? 'Toutes les catégories' : 'All categories';
  String get noCategories => isFrench ? 'Aucune catégorie' : 'No categories';
  String get search => isFrench ? 'Rechercher…' : 'Search…';
  String get refresh => isFrench ? 'Actualiser' : 'Refresh';
  String get retry => isFrench ? 'Réessayer' : 'Retry';
  String get couldNotLoadDashboard => isFrench
      ? 'Impossible de charger le tableau de bord'
      : 'Could not load dashboard';
  List<String> get monthNames => isFrench
      ? const [
          'Janvier',
          'Février',
          'Mars',
          'Avril',
          'Mai',
          'Juin',
          'Juillet',
          'Août',
          'Septembre',
          'Octobre',
          'Novembre',
          'Décembre',
        ]
      : const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
  List<String> get shortMonthNames => isFrench
      ? const [
          'Janv',
          'Févr',
          'Mars',
          'Avr',
          'Mai',
          'Juin',
          'Juil',
          'Août',
          'Sept',
          'Oct',
          'Nov',
          'Déc',
        ]
      : const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

  // ── Products ────────────────────────────────────────────────────
  String get products => isFrench ? 'Produits' : 'Products';
  String get editProduct => isFrench ? 'Modifier le produit' : 'Edit product';
  String get changeCategory => isFrench ? 'Changer de catégorie' : 'Change Category';
  String get addCategory => isFrench ? 'Ajouter une catégorie' : 'Add category';
  String get categoryName => isFrench ? 'Nom de la catégorie' : 'Category name';
  String get manageCategories => isFrench ? 'Gérer les catégories' : 'Manage categories';
  String get deleteCategory => isFrench ? 'Supprimer la catégorie' : 'Delete category';
  String get deleteCategoryConfirm => isFrench
      ? 'Les produits de cette catégorie seront déplacés vers "Autre". Continuer ?'
      : 'Products in this category will be moved to "Other". Continue?';
  String get categoryCreated => isFrench ? 'Catégorie créée avec succès' : 'Category created successfully';
  String get categoryDeleted => isFrench ? 'Catégorie supprimée avec succès' : 'Category deleted successfully';
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

  // ── Auth & Login ───────────────────────────────────────────────
  String get welcomeBack => isFrench ? 'Bon retour' : 'Welcome back';
  String get signInPrompt => isFrench ? 'Connectez-vous pour gérer votre boutique.' : 'Sign in to manage your store.';
  String get username => isFrench ? 'Nom d\'utilisateur' : 'Username';
  String get password => isFrench ? 'Mot de passe' : 'Password';
  String get signIn => isFrench ? 'Se connecter' : 'Sign In';
  String get continueAsGuest => isFrench ? 'Continuer en tant qu\'invité' : 'Continue as Guest';
  String get usernameRequired => isFrench ? 'Veuillez saisir votre nom d\'utilisateur' : 'Please enter your username';
  String get passwordRequired => isFrench ? 'Veuillez saisir votre mot de passe' : 'Please enter your password';
  String get inventoryAndSales => isFrench ? 'Gestion & Ventes' : 'Inventory & sales';

  // ── Profile & Settings ──────────────────────────────────────────
  String get profile => isFrench ? 'Profil' : 'Profile';
  String get store => isFrench ? 'Boutique' : 'Store';
  String get appSection => isFrench ? 'Application' : 'App';
  String get appSettings => isFrench ? 'Paramètres de l\'application' : 'App Settings';
  String get theme => isFrench ? 'Thème' : 'Theme';
  String get language => isFrench ? 'Langue' : 'Language';
  String get languageLabel => isFrench ? 'Langue' : 'Language / Langue';
  String get themeSubtitle => isFrench ? 'Clair, sombre ou système' : 'Light, dark, or system';
  String get about => isFrench ? 'À propos' : 'About';
  String get appInfo => isFrench ? 'Informations sur l\'application' : 'App info';
  String get signOut => isFrench ? 'Se déconnecter' : 'Sign Out';
  String get signOutConfirm => isFrench
      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
      : 'Are you sure you want to sign out?';
  String get productsInventory => isFrench ? 'Inventaire des produits' : 'Products inventory';
  String get browseAndManageStock => isFrench ? 'Parcourir et gérer le stock' : 'Browse and manage stock';
  String get lowStockAlerts => isFrench ? 'Alertes stock faible' : 'Low stock alerts';
  String get itemsRunningLow => isFrench ? 'Articles bientôt épuisés' : 'Items running low';
  String get displayName => isFrench ? 'Nom d\'affichage' : 'Display name';
  String get yourName => isFrench ? 'Votre nom' : 'Your name';
  String get displayNameHelper => isFrench
      ? 'Affiché dans l\'application. L\'identifiant de connexion reste le même.'
      : 'Shown in the app. Login username stays the same.';
  String get nameUpdated => isFrench ? 'Nom mis à jour' : 'Name updated';
  String get photoUpdated => isFrench ? 'Photo mise à jour' : 'Photo updated';
  String get aboutDescription => isFrench
      ? 'Gestion des stocks et des ventes pour boutique de vêtements.'
      : 'Inventory and sales management for a small clothing shop.';
  String get loginLabel => isFrench ? 'Identifiant : ' : 'Login: ';
  String get signedOutStatus => isFrench ? 'Déconnecté' : 'Signed out';
  String get save => isFrench ? 'Enregistrer' : 'Save';
  String get apply => isFrench ? 'Appliquer' : 'Apply';
  String get english => 'English 🇬🇧';
  String get french => 'Français 🇫🇷';
  String get systemDefault => isFrench ? 'Système par défaut' : 'System default';
  String get light => isFrench ? 'Clair' : 'Light';
  String get dark => isFrench ? 'Sombre' : 'Dark';

  // ── Expenses (Mes Dépenses / مصاريفي) ───────────────────────────
  String get myExpenses => isFrench ? 'Mes Dépenses' : 'My Expenses';
  String get addExpense => isFrench ? 'Ajouter une dépense' : 'Add Expense';
  String get editExpense => isFrench ? 'Modifier la dépense' : 'Edit Expense';
  String get expenseTitle => isFrench ? 'Motif de la dépense' : 'Expense title / reason';
  String get recipientSupplier => isFrench ? 'Bénéficiaire / Fournisseur' : 'Recipient / Supplier / Person';
  String get expenseCategory => isFrench ? 'Catégorie de dépense' : 'Expense Category';
  String get expenseDate => isFrench ? 'Date de dépense' : 'Expense Date';
  String get totalExpenses => isFrench ? 'Total des Dépenses' : 'Total Expenses';
  String get netProfit => isFrench ? 'Bénéfice Net' : 'Net Profit';
  String get netRevenue => isFrench ? 'Revenu Net' : 'Net Revenue';
  String get noExpenses => isFrench ? 'Aucune dépense enregistrée' : 'No expenses recorded';
  String get expenseAdded => isFrench ? 'Dépense ajoutée avec succès' : 'Expense added successfully';
  String get expenseUpdated => isFrench ? 'Dépense mise à jour' : 'Expense updated';
  String get expenseDeleted => isFrench ? 'Dépense supprimée' : 'Expense deleted';
  String get deleteExpenseConfirm => isFrench
      ? 'Êtes-vous sûr de vouloir supprimer cette dépense ?'
      : 'Are you sure you want to delete this expense?';

  // Expense Categories
  String get catSupplier => isFrench ? 'Fournisseur' : 'Supplier';
  String get catRent => isFrench ? 'Loyer' : 'Rent';
  String get catBills => isFrench ? 'Factures & Charges' : 'Bills & Utilities';
  String get catTransport => isFrench ? 'Transport' : 'Transport';
  String get catPersonal => isFrench ? 'Retrait Personnel' : 'Personal';
  String get catOther => isFrench ? 'Autre' : 'Other';

  // ── Customer Debts Hub (دفتر الديون) ────────────────────────────
  String get customerDebts => isFrench ? 'Dettes Clients' : 'Customer Debts';
  String get debtsBook => isFrench ? 'Carnet de Crédit' : 'Credit Book';
  String get searchCustomer => isFrench ? 'Rechercher par nom de client…' : 'Search by customer name…';
  String get totalDueDebts => isFrench ? 'Total des Créances Dues' : 'Total Due Receivables';
  String get noDebtsFound => isFrench ? 'Aucune dette en cours 🎉' : 'No pending debts 🎉';
  String get recordInstallment => isFrench ? 'Verser un acompte' : 'Record Installment';
  String get installmentRecorded => isFrench ? 'Versement enregistré avec succès ✓' : 'Installment recorded successfully ✓';
  String get fullySettled => isFrench ? 'Entièrement Réglé' : 'Fully Settled';
  String get partiallyPaid => isFrench ? 'Partiellement payé' : 'Partially Paid';
  String get pendingPayment => isFrench ? 'En attente' : 'Pending';

  // ── History & Sold Items ─────────────────────────────────────────
  String get clearHistory => isFrench ? 'Vider tout l\'historique' : 'Clear entire history';
  String get clearHistoryConfirm => isFrench
      ? 'Êtes-vous sûr de vouloir supprimer tout l\'historique des ventes ? Cette action est irréversible.'
      : 'Are you sure you want to delete the entire sales history? This cannot be undone.';
  String get restockCheckbox => isFrench ? 'Restituer les articles au stock' : 'Restock items back to inventory';
  String get historyCleared => isFrench ? 'Historique des ventes vidé avec succès' : 'Sales history cleared successfully';
  String get soldItemsBreakdown => isFrench ? 'Articles vendus en détail' : 'Sold Items Breakdown';
  String get noSoldItems => isFrench ? 'Aucun article vendu sur cette période' : 'No items sold during this period';
  String get lowStockItems => isFrench ? 'Articles en stock faible' : 'Low Stock Items';
  String get allInStock => isFrench ? 'Tous les produits ont un stock suffisant ✓' : 'All products have sufficient stock ✓';
  String get quantitySold => isFrench ? 'Quantité vendue' : 'Quantity sold';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale.languageCode == 'fr');
});
