# 📦 Inventory Management System

A comprehensive Flutter-based inventory management solution with advanced features for modern businesses. Built with clean architecture principles and equipped with barcode generation, multi-format export capabilities, and real-time data synchronization.

<div align="center">






</div>

## ✨ Features

### 🏪 Core Inventory Management
- **Real-time Inventory Tracking** - Monitor stock levels, pricing, and item details
- **Advanced Search & Filtering** - Quick item discovery with multiple filter options
- **Category Management** - Organize products with hierarchical categories
- **Low Stock Alerts** - Automated notifications for items below minimum threshold
- **Bulk Operations** - Mass update, delete, and manage inventory items

### 📊 Data Management
- **CSV Import/Export** - Seamless data migration and backup capabilities
- **PDF Reports** - Professional inventory reports with barcode labels
- **Multi-language Support** - English and Arabic language support
- **Data Validation** - Comprehensive input validation and error handling

### 🏷️ Barcode System
- **Barcode Generation** - Multiple barcode formats (Code128, EAN-13, QR Code, etc.)
- **Label Printing** - Professional barcode labels with customizable layouts
- **Size Optimization** - Consistent label sizing across all formats
- **Export Integration** - Barcodes included in PDF exports

### 🎨 User Experience
- **Clean UI/UX** - Modern, intuitive interface design
- **Responsive Design** - Seamless experience across desktop and mobile
- **Dark/Light Mode** - User preference-based theming
- **Real-time Updates** - Live data synchronization across devices

## 🚀 Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **BLoC Pattern** - State management
- **Provider** - Dependency injection and state management
- **MVVM Architecture** - Clean code organization

### Backend & Database
- **Supabase** - Backend-as-a-Service
- **PostgreSQL** - Relational database
- **Real-time Subscriptions** - Live data updates

### Key Packages
```yaml
dependencies:
  flutter_bloc: ^8.1.6
  provider: ^6.1.5
  supabase_flutter: ^2.5.6
  syncfusion_flutter_barcodes: ^26.2.14
  file_picker: ^8.0.6
  csv: ^6.0.0
  pdf: ^3.10.8
  screenshot: ^3.0.0
  get_it: ^8.0.0
```

## 📱 Screenshots

<div align="center">
<img src="screenshots/dashboard.png" alt="Dashboard" width="300"/>
<img src="screenshots/inventory_table.png" alt="Inventory Table" width="300"/>
<img src="screenshots/barcode_generator.png" alt="Barcode Generator" width="300"/>
</div>

```

## 🏗️ Architecture

The project follows Clean Architecture principles with MVVM pattern:

```
lib/
├── core/                    # Core utilities and constants
│   ├── constants/
│   ├── errors/
│   └── utils/
├── data/                    # Data layer
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/                  # Business logic layer
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/            # UI layer
│   ├── blocs/
│   ├── pages/
│   ├── viewmodels/
│   └── widgets/
└── injection_container.dart # Dependency injection
```

### Key Architecture Patterns
- **Clean Architecture** - Separation of concerns with clear boundaries
- **MVVM Pattern** - Model-View-ViewModel for UI logic separation
- **BLoC Pattern** - Business Logic Components for state management
- **Repository Pattern** - Data access abstraction
- **Dependency Injection** - Loose coupling with GetIt

## 📖 Usage

### Adding New Inventory Items
1. Click the **"Add Item"** floating action button
2. Fill in product details (SKU, name, category, etc.)
3. Set stock levels and pricing information
4. Save to automatically generate barcode

### Importing Data
1. Navigate to **Import Data** in the app bar
2. Select CSV file with proper formatting
3. Review import preview
4. Confirm to add items to inventory

### Generating Reports
1. Click **Export Data** in the app bar
2. Choose export format:
   - **CSV**: Raw data export
   - **PDF**: Professional report
   - **PDF with Barcodes**: Labels for printing

### Barcode Management
1. Select any inventory item
2. Click **Barcode** action button
3. Choose barcode type (Code128, QR, etc.)
4. Generate, save, or print labels



### Feature Flags
```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const bool enableBarcodeScanner = true;
  static const bool enableMultiLanguage = true;
  static const bool enableDarkMode = true;
  static const int maxImportItems = 1000;
}
```



## 📚 API Documentation

### Core Services

#### InventoryService
- `getItems()` - Retrieve all inventory items
- `createItem(InventoryItem item)` - Add new item
- `updateItem(String id, InventoryItem item)` - Update existing item
- `deleteItem(String id)` - Remove item

#### ImportExportService
- `importFromCSV()` - Import items from CSV file
- `exportToCSV(List<InventoryItem> items)` - Export to CSV
- `exportToPDF(List<InventoryItem> items)` - Generate PDF report
- `exportToPDFWithBarcodes(List<InventoryItem> items)` - PDF with barcodes


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Supabase** - Excellent backend-as-a-service
- **Syncfusion** - Professional barcode generation
- **Open Source Community** - Inspiration and packages



<div align="center">


Made with ❤️ using Flutter

[Report Bug](https://github.com/yourusername/inventory-management-system/issues) -  [Request Feature](https://github.com/yourusername/inventory-management-system/issues) -  [Documentation](https://github.com/yourusername/inventory-management-system/wiki)

</div>
