# 📚 My Book Vault

<div align="center">

**A comprehensive Flutter application for managing your personal book library**

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.2+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

Desarrollado por **Ana Martínez Montañez** como proyecto personal  
© 2025 Ana Martínez Montañez. Todos los derechos reservados.

[Características](#-características-principales) • [Instalación](#-instalación) • [Uso](#-guía-de-uso) • [Arquitectura](#-arquitectura) • [Contribuir](#-contribuir)

</div>

---

## 📖 Tabla de Contenidos

- [Descripción](#-descripción)
- [Características Principales](#-características-principales)
- [Requisitos del Sistema](#-requisitos-del-sistema)
- [Instalación](#-instalación)
- [Guía de Uso](#-guía-de-uso)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Base de Datos](#-base-de-datos)
- [Internacionalización](#-internacionalización)
- [Temas y Personalización](#-temas-y-personalización)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Roadmap](#-roadmap)
- [Autor](#-autor)

---

## 📱 Descripción

**My Book Vault** es una aplicación móvil multiplataforma desarrollada con [Flutter/Dart](https://docs.flutter.dev/) que transforma la gestión de tu biblioteca personal en una experiencia dinámica e inteligente. 

La aplicación no solo te permite catalogar y organizar tus libros, sino que también incluye un **sistema de recomendaciones aleatorias** que te sugiere tu próxima lectura basándose en filtros personalizados como género, autor, idioma, formato, número de páginas y más.

### 🎯 ¿Para quién es esta aplicación?

- **Lectores ávidos** que desean mantener un registro organizado de su colección
- **Coleccionistas de libros** que necesitan gestionar grandes bibliotecas personales
- **Book clubs** que buscan decidir qué leer a continuación
- **Personas indecisas** que tienen muchos libros pendientes y necesitan ayuda para elegir
- **Amantes de las estadísticas** que quieren analizar sus hábitos de lectura

---

## ✨ Características Principales

### 📚 Gestión Completa de Biblioteca

#### Catálogo de Libros
- **Añadir libros** con información detallada:
  - Título, autor(es), género(s)
  - ISBN/ASIN para identificación única
  - Editorial, idioma, lugar de compra
  - Formato (físico, digital, audiolibro)
  - Número de páginas
  - Año de publicación original
  - Estado de lectura (leído, leyendo, pendiente, etc.)
  - Información de préstamo

#### Gestión de Sagas y Series
- Organización de libros por **sagas** y **universos de sagas**
- Numeración de libros dentro de una saga
- Formato de saga (individual, omnibus, integral, etc.)
- Soporte para **bundles** (colecciones de varios libros en un solo volumen):
  - Gestión de títulos individuales dentro del bundle
  - Fechas de lectura independientes por libro
  - Páginas y años de publicación por volumen
  - Autores específicos para cada libro del bundle

#### Información de Lectura
- **Fechas de inicio y fin** de lectura
- **Contador de relecturas** para cada libro
- **Sistema de valoración** con corazones (escala de 0.5 a 5)
- **Reseñas personales** para cada libro
- **Sesiones de lectura** con cronómetro integrado:
  - Seguimiento del tiempo de lectura en tiempo real
  - Historial de sesiones por libro
  - Estadísticas de tiempo de lectura

#### Funciones Avanzadas
- **TBR (To Be Released)**: Marca libros que aún no han sido publicados
- **Lectura en tándem**: Identifica libros leídos simultáneamente
- **Notificaciones**: Recordatorios personalizables para libros pendientes
- **Libros repetidos**: Vinculación de ediciones duplicadas al libro original

### 🔍 Búsqueda y Filtrado Avanzado

#### Búsqueda Múltiple
- Búsqueda por **título**
- Búsqueda por **ISBN/ASIN**
- Búsqueda por **autor**

#### Filtros Personalizables
- **Formato**: Físico, digital, audiolibro, etc.
- **Idioma**: Español, inglés, etc.
- **Género**: Fantasía, ciencia ficción, romance, etc.
- **Lugar**: Tienda o lugar de adquisición
- **Estado de lectura**: Leído, leyendo, pendiente, abandonado, etc.
- **Editorial**: Filtrar por casa editorial
- **Saga**: Buscar libros de una saga específica
- **Universo de saga**: Agrupar sagas relacionadas
- **Formato de saga**: Individual, omnibus, integral, etc.
- **Páginas vacías**: Encontrar libros sin información de páginas
- **Bundles**: Filtrar colecciones de libros
- **Lectura en tándem**: Identificar lecturas simultáneas
- **Formato de saga sin saga**: Detectar inconsistencias
- **Formato de saga sin número**: Encontrar libros sin numeración

#### Ordenamiento Flexible
- Ordenar por **nombre**, **autor**, **fecha de creación**, **fecha de lectura**, **valoración**, **páginas**, **año de publicación**
- Orden **ascendente** o **descendente**
- **Persistencia de filtros**: Los filtros y el orden se mantienen entre sesiones

### 🎲 Recomendador Aleatorio

El corazón de la aplicación: un sistema inteligente que te ayuda a decidir qué leer a continuación.

#### Modos de Selección
1. **Aleatorio con filtros**: Aplica múltiples filtros para acotar las opciones
2. **Lista personalizada**: Selecciona manualmente un grupo de libros y elige uno al azar

#### Filtros del Recomendador
- Formato, idioma, género, lugar, estado
- Editorial, formato de saga
- Rango de páginas (mínimo y máximo)
- Rango de años de publicación
- Autor específico
- TBR (libros no publicados)

#### Visualización del Resultado
- Muestra el libro seleccionado con toda su información
- Acceso directo a los detalles completos del libro
- Botón para generar una nueva recomendación

### 📊 Estadísticas Detalladas

#### Métricas Generales
- **Total de libros** en la biblioteca
- **Último libro añadido**
- **Distribución por estado** (leído, leyendo, pendiente, etc.)
- **Distribución por idioma**
- **Distribución por formato**
- Visualización en **gráficos de pastel** con porcentajes o valores absolutos

#### Estadísticas de Lectura
- **Libros leídos por año** (gráfico de barras)
- **Páginas leídas por año** (gráfico de barras)
- **Libros por década** de publicación
- **Distribución de valoraciones** (gráfico de barras)
- **Distribución de páginas** (rangos: <200, 200-400, 400-600, >600)
- **Valoración promedio** de libros leídos
- **Libro más largo y más corto** leídos
- **Libro mejor y peor valorado**

#### Análisis Avanzado
- **Completitud de sagas**: Porcentaje de sagas completadas
- **Lectura estacional**: Libros leídos por estación del año
- **Preferencias estacionales**: Géneros favoritos por estación
- **Mapa de calor mensual**: Actividad de lectura por mes y año
- **Top 10 editoriales** más leídas
- **Top 10 autores** más leídos
- **Top 5 géneros** favoritos
- **Insights de lectura**: Análisis automático de patrones

#### Visualización de Datos
- Gráficos interactivos con **fl_chart**
- Navegación a vistas detalladas (libros por año, década, saga)
- Exportación de datos para análisis externo

### 🏆 Retos de Lectura

#### Retos Anuales
- Establecer **meta de libros** para el año
- Establecer **meta de páginas** para el año
- Seguimiento del progreso en tiempo real
- Visualización gráfica del avance
- Notas personales sobre el reto

#### Retos Personalizados
- Crear **retos personalizados** con criterios específicos:
  - Nombre del reto
  - Descripción detallada
  - Meta numérica
  - Progreso actual
  - Completado o en curso
- Múltiples retos por año
- Edición y eliminación de retos

### 🎨 Personalización

#### Temas
- **Tema claro** con colores personalizables
- **Tema oscuro** con colores personalizables
- **Modo sistema**: Se adapta automáticamente al tema del dispositivo
- Persistencia de la configuración del tema

#### Idiomas
- **Español** (es)
- **Inglés** (en)
- Cambio de idioma en tiempo real sin reiniciar la aplicación
- Todas las cadenas de texto localizadas

### 💾 Importación y Exportación

#### Importación desde CSV
- Importar múltiples libros desde un archivo CSV
- Detección automática de duplicados por ISBN
- Reporte detallado de importación:
  - Libros importados exitosamente
  - Filas omitidas (datos incompletos)
  - Duplicados detectados
- Formato CSV esperado con columnas específicas

#### Exportación a CSV
- Exportar toda la biblioteca a CSV
- Incluye todos los campos de información
- Compatible con hojas de cálculo (Excel, Google Sheets)

#### Copias de Seguridad
- **Crear backup** de la base de datos SQLite
- **Restaurar backup** desde archivo
- Confirmación antes de sobrescribir datos
- Almacenamiento en directorio de documentos del dispositivo

#### Gestión de Datos
- **Eliminar todos los datos**: Borrado completo de la biblioteca
- Confirmación doble para evitar pérdidas accidentales
- Gestión de valores de dropdowns (estados, idiomas, lugares, formatos)

### 📱 Características de la Interfaz

#### Navegación
- **Bottom Navigation Bar** con 4 secciones principales:
  - Home (Biblioteca)
  - Estadísticas
  - Aleatorio (Recomendador)
  - Ajustes
- Navegación fluida entre pantallas
- Persistencia del estado de navegación

#### Componentes Personalizados
- **Autocomplete fields** para autores y géneros
- **Chip autocomplete** para selección múltiple
- **Heart rating input** para valoraciones
- **Chronometer widget** para sesiones de lectura
- **Bundle input widgets** para gestión de colecciones
- **Quick add book dialog** para añadir libros rápidamente

#### Listas y Vistas
- **BookList widget** reutilizable con diferentes configuraciones
- Vista de **detalles del libro** con toda la información
- Listas de **libros por año**, **década** y **saga**
- Scroll infinito y rendimiento optimizado

### 🔔 Notificaciones

- Sistema de **notificaciones locales** integrado
- Recordatorios para libros pendientes
- Configuración de fecha y hora específicas
- Permisos de notificación gestionados automáticamente
- Soporte para **wakelock** durante sesiones de lectura

### 🔄 Migraciones de Datos

- Sistema de **migraciones automáticas** para actualizaciones de base de datos
- Migración de sesiones de lectura
- Migración de datos de bundles
- Preservación de datos durante actualizaciones

---

## 💻 Requisitos del Sistema

### Requisitos Mínimos

#### Para Desarrollo
- **Flutter SDK**: 3.7.2 o superior
- **Dart SDK**: 3.7.2 o superior
- **Android Studio** / **VS Code** con extensiones de Flutter
- **Git** para control de versiones

#### Para Ejecución
- **Android**: API 21 (Android 5.0 Lollipop) o superior
- **iOS**: iOS 12.0 o superior
- **macOS**: macOS 10.14 o superior
- **Linux**: Distribuciones modernas con soporte GTK
- **Windows**: Windows 10 o superior
- **Web**: Navegadores modernos (Chrome, Firefox, Safari, Edge)

### Espacio en Disco
- **Aplicación**: ~50 MB
- **Base de datos**: Variable según el tamaño de la biblioteca (típicamente <10 MB)

---

## 🚀 Instalación

### Clonar el Repositorio

```bash
git clone https://github.com/anamartinez97m/my-flutter-library.git
cd my-flutter-library
```

### Instalar Dependencias

```bash
flutter pub get
```

### Generar Archivos de Localización

```bash
flutter gen-l10n
```

### Ejecutar la Aplicación

#### En modo desarrollo
```bash
flutter run
```

#### Para un dispositivo específico
```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en un dispositivo específico
flutter run -d <device_id>
```

#### Compilar para producción

**Android (APK)**
```bash
flutter build apk --release
```

**Android (App Bundle)**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

**macOS**
```bash
flutter build macos --release
```

**Linux**
```bash
flutter build linux --release
```

**Windows**
```bash
flutter build windows --release
```

**Web**
```bash
flutter build web --release
```

---

## 📖 Guía de Uso

### Primer Uso

1. **Iniciar la aplicación**: Al abrir por primera vez, se creará automáticamente la base de datos local
2. **Configurar idioma**: Ve a Ajustes → Idioma y selecciona tu preferencia
3. **Configurar tema**: Ve a Ajustes → Tema y elige entre claro, oscuro o sistema
4. **Añadir tu primer libro**: Toca el botón "+" en la pantalla principal

### Añadir un Libro

1. **Navega a Home** y toca el botón flotante "+"
2. **Completa la información básica**:
   - Título (obligatorio)
   - Autor(es) - puedes añadir múltiples autores
   - Género(s) - puedes añadir múltiples géneros
   - ISBN o ASIN
3. **Añade detalles adicionales**:
   - Editorial, idioma, lugar de compra
   - Formato (físico, digital, etc.)
   - Número de páginas
   - Año de publicación
   - Estado de lectura
4. **Información de saga** (opcional):
   - Nombre de la saga
   - Número en la saga
   - Universo de saga
   - Formato de saga
5. **Información de lectura** (opcional):
   - Fechas de inicio y fin
   - Valoración (0.5 a 5 corazones)
   - Número de veces leído
   - Reseña personal
6. **Opciones avanzadas**:
   - Marcar como bundle
   - Marcar como TBR
   - Marcar como lectura en tándem
   - Configurar notificación
7. **Guardar**: Toca el botón "Guardar"

### Buscar y Filtrar Libros

1. **Búsqueda rápida**:
   - Usa la barra de búsqueda en la parte superior
   - Selecciona el tipo de búsqueda (Título, ISBN/ASIN, Autor)
   - Escribe tu consulta
2. **Aplicar filtros**:
   - Toca el icono de filtro
   - Selecciona los criterios deseados
   - Los filtros se aplican automáticamente
3. **Ordenar resultados**:
   - Toca el icono de ordenamiento
   - Selecciona el campo y dirección
4. **Limpiar búsqueda/filtros**:
   - Usa el botón "Limpiar" en la barra de búsqueda

### Usar el Recomendador Aleatorio

1. **Navega a la pestaña "Random"**
2. **Configurar filtros** (opcional):
   - Selecciona formato, idioma, género, etc.
   - Establece rangos de páginas o años
   - Marca "TBR" si quieres incluir libros no publicados
3. **Modo lista personalizada** (opcional):
   - Activa "Usar lista personalizada"
   - Selecciona los libros que quieres incluir
4. **Obtener recomendación**:
   - Toca "Obtener Libro Aleatorio"
   - El sistema seleccionará un libro basado en tus criterios
5. **Ver detalles**:
   - Toca el libro recomendado para ver toda su información
6. **Nueva recomendación**:
   - Toca nuevamente el botón para obtener otra sugerencia

### Ver Estadísticas

1. **Navega a la pestaña "Estadísticas"**
2. **Explora las métricas**:
   - Desplázate para ver diferentes gráficos
   - Toca los gráficos para más detalles
3. **Cambiar visualización**:
   - Usa los switches para alternar entre porcentajes y valores absolutos
   - Filtra por libros leídos o todos los libros
4. **Navegar a detalles**:
   - Toca en "Libros por año" o "Libros por década" para ver listas detalladas

### Gestionar Retos de Lectura

1. **Navega a Ajustes → Retos de Lectura**
2. **Crear un reto anual**:
   - Selecciona el año
   - Establece meta de libros y/o páginas
   - Añade notas (opcional)
   - Guarda el reto
3. **Añadir retos personalizados**:
   - Toca "Añadir Reto Personalizado"
   - Define nombre, descripción y meta
   - Actualiza el progreso manualmente
4. **Ver progreso**:
   - El progreso se calcula automáticamente basándose en tus lecturas
   - Los gráficos muestran tu avance

### Importar/Exportar Datos

#### Importar desde CSV
1. **Navega a Ajustes → Importar desde CSV**
2. **Selecciona el archivo CSV**
3. **Revisa el reporte de importación**
4. **Confirma o cancela**

#### Crear Backup
1. **Navega a Ajustes → Crear Backup**
2. **Confirma la acción**
3. **El archivo se guardará en tu carpeta de Documentos**

#### Restaurar Backup
1. **Navega a Ajustes → Importar Backup**
2. **ADVERTENCIA**: Esto sobrescribirá todos tus datos actuales
3. **Selecciona el archivo de backup**
4. **Confirma la restauración**

### Usar el Cronómetro de Lectura

1. **Abre los detalles de un libro**
2. **Toca el icono del cronómetro**
3. **Inicia la sesión de lectura**:
   - El cronómetro comenzará a contar
   - La pantalla permanecerá activa (wakelock)
4. **Pausar/Reanudar**:
   - Toca el botón de pausa
   - Toca nuevamente para reanudar
5. **Finalizar sesión**:
   - Toca el botón de stop
   - El tiempo se guardará automáticamente
6. **Ver historial**:
   - Accede al historial de sesiones desde los detalles del libro

---

## 🏗️ Arquitectura

### Patrón de Diseño

La aplicación sigue una arquitectura **Provider + Repository** con separación clara de responsabilidades:

```
┌─────────────────────────────────────────────────────────┐
│                     Presentation Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Screens    │  │   Widgets    │  │  Dialogs     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     Business Logic Layer                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Providers   │  │   Services   │  │    Utils     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Repositories │  │    Models    │  │   Database   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Capas de la Aplicación

#### 1. **Presentation Layer** (UI)
- **Screens**: Pantallas completas de la aplicación
- **Widgets**: Componentes reutilizables de UI
- **Dialogs**: Ventanas modales y alertas

#### 2. **Business Logic Layer**
- **Providers**: Gestión de estado con Provider pattern
  - `BookProvider`: Estado global de libros
  - `ThemeProvider`: Gestión de temas
  - `LocaleProvider`: Gestión de idiomas
- **Services**: Servicios de la aplicación
  - `NotificationService`: Gestión de notificaciones
- **Utils**: Utilidades y helpers
  - `DateFormatter`: Formateo de fechas
  - `StatusHelper`: Helpers para estados
  - `CSVImportHelper`: Importación de CSV
  - Migraciones de datos

#### 3. **Data Layer**
- **Repositories**: Acceso a datos
  - `BookRepository`: CRUD de libros
  - `ReadingSessionRepository`: Gestión de sesiones
  - `YearChallengeRepository`: Gestión de retos
- **Models**: Modelos de datos
  - `Book`: Modelo de libro
  - `ReadingSession`: Modelo de sesión de lectura
  - `YearChallenge`: Modelo de reto anual
  - `CustomChallenge`: Modelo de reto personalizado
  - `ReadDate`: Modelo de fecha de lectura
- **Database**: Capa de persistencia
  - `DatabaseHelper`: Singleton para SQLite

### Flujo de Datos

```
User Interaction → Screen → Provider → Repository → Database
                                ↓
                            UI Update
```

1. El usuario interactúa con la UI (Screen/Widget)
2. La Screen llama a un método del Provider
3. El Provider ejecuta lógica de negocio y llama al Repository
4. El Repository interactúa con la base de datos
5. Los datos fluyen de vuelta y el Provider notifica a los listeners
6. La UI se actualiza automáticamente

### Gestión de Estado

- **Provider**: Para estado global y compartido
- **StatefulWidget**: Para estado local de componentes
- **ChangeNotifier**: Para notificar cambios a los listeners

---

## 📁 Estructura del Proyecto

```
lib/
├── config/                      # Configuración de la aplicación
│   └── app_theme.dart          # Definición de temas
│
├── db/                         # Capa de base de datos
│   ├── database_helper.dart    # Helper singleton de SQLite
│   └── migrations/             # Scripts de migración
│
├── l10n/                       # Internacionalización
│   ├── app_en.arb             # Strings en inglés
│   ├── app_es.arb             # Strings en español
│   ├── app_localizations.dart  # Clase base de localización
│   ├── app_localizations_en.dart
│   └── app_localizations_es.dart
│
├── model/                      # Modelos de datos
│   ├── book.dart              # Modelo de libro
│   ├── custom_challenge.dart   # Modelo de reto personalizado
│   ├── read_date.dart         # Modelo de fecha de lectura
│   ├── reading_session.dart    # Modelo de sesión de lectura
│   └── year_challenge.dart     # Modelo de reto anual
│
├── providers/                  # Gestión de estado
│   ├── book_provider.dart     # Provider de libros
│   ├── locale_provider.dart    # Provider de idioma
│   └── theme_provider.dart     # Provider de tema
│
├── repositories/               # Acceso a datos
│   ├── book_repository.dart
│   ├── reading_session_repository.dart
│   └── year_challenge_repository.dart
│
├── screens/                    # Pantallas de la aplicación
│   ├── add_book.dart          # Añadir libro
│   ├── admin_csv_import.dart   # Importación CSV
│   ├── book_detail.dart       # Detalles del libro
│   ├── books_by_decade.dart    # Libros por década
│   ├── books_by_saga.dart      # Libros por saga
│   ├── books_by_year.dart      # Libros por año
│   ├── bundle_migration_screen.dart
│   ├── edit_book.dart         # Editar libro
│   ├── home.dart              # Pantalla principal
│   ├── manage_dropdowns.dart   # Gestión de dropdowns
│   ├── my_books.dart          # Mis libros
│   ├── navigation.dart        # Navegación principal
│   ├── random.dart            # Recomendador aleatorio
│   ├── settings.dart          # Ajustes
│   ├── statistics.dart        # Estadísticas
│   └── year_challenges.dart    # Retos anuales
│
├── services/                   # Servicios de la aplicación
│   └── notification_service.dart
│
├── utils/                      # Utilidades
│   ├── bundle_migration.dart
│   ├── csv_import_helper.dart
│   ├── date_formatter.dart
│   ├── reading_session_migration.dart
│   └── status_helper.dart
│
├── widgets/                    # Componentes reutilizables
│   ├── autocomplete_text_field.dart
│   ├── booklist.dart
│   ├── bundle_input_widget.dart
│   ├── bundle_input_widget_v2.dart
│   ├── bundle_read_dates_widget.dart
│   ├── chip_autocomplete_field.dart
│   ├── chronometer_widget.dart
│   ├── heart_rating_input.dart
│   ├── quick_add_book_dialog.dart
│   ├── reading_session_history_widget.dart
│   ├── star_rating_input.dart
│   └── statistics/            # Widgets de estadísticas
│       ├── average_rating_card.dart
│       ├── book_extremes_card.dart
│       ├── books_by_decade_card.dart
│       ├── latest_book_card.dart
│       ├── monthly_heatmap_card.dart
│       ├── page_distribution_card.dart
│       ├── rating_distribution_card.dart
│       ├── reading_goals_card.dart
│       ├── reading_insights_card.dart
│       ├── reading_time_placeholder_card.dart
│       ├── responsive_stat_grid.dart
│       ├── saga_completion_card.dart
│       ├── seasonal_preferences_card.dart
│       ├── seasonal_reading_card.dart
│       └── total_books_card.dart
│
└── main.dart                   # Punto de entrada

assets/
└── scripts/
    └── 1_creation.sql         # Script de creación de BD

android/                        # Configuración Android
ios/                           # Configuración iOS
linux/                         # Configuración Linux
macos/                         # Configuración macOS
web/                           # Configuración Web
windows/                       # Configuración Windows
```

---

## 🗄️ Base de Datos

### Tecnología
- **SQLite** con el paquete `sqflite`
- Base de datos local almacenada en el dispositivo
- Migraciones automáticas para actualizaciones

### Esquema de Tablas

#### Tabla: `book`
Tabla principal que almacena la información de los libros.

```sql
CREATE TABLE book (
  book_id INTEGER PRIMARY KEY AUTOINCREMENT,
  status_id VARCHAR(50) NOT NULL,
  name VARCHAR(50) NOT NULL DEFAULT 'unknown',
  editorial_id VARCHAR(50),
  saga VARCHAR(50),
  n_saga VARCHAR(50),
  saga_universe VARCHAR(50),
  format_saga_id VARCHAR(50),
  isbn VARCHAR(50),
  asin VARCHAR(50),
  pages INTEGER,
  original_publication_year INTEGER,
  loaned BOOLEAN,
  language_id VARCHAR(50),
  place_id VARCHAR(50),
  format_id VARCHAR(50),
  created_at TEXT DEFAULT (datetime('now')),
  date_read_initial TEXT,
  date_read_final TEXT,
  read_count INTEGER,
  my_rating REAL,
  my_review TEXT,
  is_bundle BOOLEAN,
  bundle_count INTEGER,
  bundle_numbers TEXT,
  bundle_start_dates TEXT,
  bundle_end_dates TEXT,
  bundle_pages TEXT,
  bundle_publication_years TEXT,
  bundle_titles TEXT,
  bundle_authors TEXT,
  tbr BOOLEAN,
  is_tandem BOOLEAN,
  original_book_id INTEGER,
  notification_enabled BOOLEAN,
  notification_datetime TEXT,
  bundle_parent_id INTEGER,
  FOREIGN KEY (status_id) REFERENCES status (status_id),
  FOREIGN KEY (editorial_id) REFERENCES editorial (editorial_id),
  FOREIGN KEY (language_id) REFERENCES language (language_id),
  FOREIGN KEY (place_id) REFERENCES place (place_id),
  FOREIGN KEY (format_id) REFERENCES format (format_id),
  FOREIGN KEY (format_saga_id) REFERENCES format_saga (format_id)
);
```

#### Tablas de Lookup
Tablas para valores de dropdown:
- `status`: Estados de lectura (leído, leyendo, pendiente, etc.)
- `author`: Autores
- `editorial`: Editoriales
- `genre`: Géneros literarios
- `language`: Idiomas
- `place`: Lugares de compra
- `format`: Formatos (físico, digital, audiolibro, etc.)
- `format_saga`: Formatos de saga (individual, omnibus, integral, etc.)

#### Tablas de Relación
- `books_by_author`: Relación muchos a muchos entre libros y autores
- `books_by_genre`: Relación muchos a muchos entre libros y géneros

#### Tabla: `reading_session`
Almacena las sesiones de lectura con cronómetro.

```sql
CREATE TABLE reading_session (
  session_id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  duration_seconds INTEGER,
  is_active INTEGER DEFAULT 1,
  clicked_at TEXT,
  FOREIGN KEY (book_id) REFERENCES book (book_id)
);
```

#### Tabla: `year_challenge`
Almacena los retos de lectura anuales.

```sql
CREATE TABLE year_challenge (
  challenge_id INTEGER PRIMARY KEY AUTOINCREMENT,
  year INTEGER NOT NULL,
  target_books INTEGER NOT NULL,
  target_pages INTEGER,
  created_at TEXT NOT NULL,
  notes TEXT,
  custom_challenges TEXT
);
```

### Índices
- `idx_book_isbn`: Índice en el campo ISBN para búsquedas rápidas

---

## 🌍 Internacionalización

La aplicación soporta múltiples idiomas mediante el sistema de localización de Flutter.

### Idiomas Soportados
- **Español** (es) - Idioma por defecto
- **Inglés** (en)

### Archivos de Localización
- `lib/l10n/app_es.arb`: Strings en español
- `lib/l10n/app_en.arb`: Strings en inglés

### Añadir un Nuevo Idioma

1. Crear archivo ARB en `lib/l10n/`:
   ```
   app_[locale].arb
   ```

2. Copiar las claves del archivo `app_en.arb` y traducir los valores

3. Añadir el locale a `main.dart`:
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('es'),
     Locale('fr'), // Nuevo idioma
   ],
   ```

4. Regenerar los archivos de localización:
   ```bash
   flutter gen-l10n
   ```

### Uso en el Código

```dart
import 'package:myrandomlibrary/l10n/app_localizations.dart';

// En un widget
Text(AppLocalizations.of(context)!.app_title)
```

---

## 🎨 Temas y Personalización

### Sistema de Temas

La aplicación incluye un sistema completo de temas con soporte para modo claro, oscuro y sistema.

#### Modos de Tema
- **Light**: Tema claro con colores brillantes
- **Dark**: Tema oscuro para reducir fatiga visual
- **System**: Se adapta automáticamente al tema del sistema operativo

#### Personalización de Colores

Los colores se definen en `lib/config/app_theme.dart`:

```dart
class AppTheme {
  // Colores del tema claro
  static const Color primaryLight = Color(0xFF6200EE);
  static const Color secondaryLight = Color(0xFF03DAC6);
  
  // Colores del tema oscuro
  static const Color primaryDark = Color(0xFFBB86FC);
  static const Color secondaryDark = Color(0xFF03DAC6);
}
```

#### Cambiar Tema

El tema se gestiona mediante `ThemeProvider`:

```dart
// Cambiar a tema claro
themeProvider.setThemeMode(AppThemeMode.light);

// Cambiar a tema oscuro
themeProvider.setThemeMode(AppThemeMode.dark);

// Usar tema del sistema
themeProvider.setThemeMode(AppThemeMode.system);
```

### Tipografía

La aplicación utiliza Material Design 3 con tamaños de fuente personalizados:
- **Headline Large**: 24px
- **Headline Medium**: 20px
- **Headline Small**: 18px
- **Title Large**: 18px
- **Title Medium**: 16px
- **Title Small**: 14px
- **Body Large**: 14px
- **Body Medium**: 13px
- **Body Small**: 12px

---

## 🛠️ Tecnologías Utilizadas

### Framework y Lenguaje
- **Flutter** 3.7.2+ - Framework de UI multiplataforma
- **Dart** 3.7.2+ - Lenguaje de programación

### Dependencias Principales

#### Gestión de Estado
- **provider** ^6.1.2 - Gestión de estado reactivo

#### Base de Datos
- **sqflite** ^2.4.2 - Base de datos SQLite
- **path** ^1.9.1 - Manipulación de rutas de archivos
- **path_provider** ^2.1.4 - Acceso a directorios del sistema

#### Internacionalización
- **flutter_localizations** - Localización de Flutter
- **intl** ^0.19.0 - Internacionalización y formateo

#### UI y Gráficos
- **fl_chart** ^0.69.0 - Gráficos y visualizaciones
- **cupertino_icons** ^1.0.8 - Iconos de iOS

#### Importación/Exportación
- **file_picker** ^8.0.0 - Selector de archivos
- **csv** ^6.0.0 - Lectura y escritura de CSV

#### Notificaciones
- **flutter_local_notifications** ^17.2.3 - Notificaciones locales
- **timezone** ^0.9.4 - Manejo de zonas horarias

#### Utilidades
- **shared_preferences** ^2.2.2 - Almacenamiento de preferencias
- **permission_handler** ^11.3.1 - Gestión de permisos
- **wakelock_plus** ^1.2.8 - Mantener pantalla activa

### Dependencias de Desarrollo
- **flutter_test** - Testing de Flutter
- **flutter_lints** ^5.0.0 - Reglas de linting

---

## 🗺️ Roadmap

### Versión Actual: 1.0.0+1
Estado: **En desarrollo**

### Características Planificadas

#### Versión 1.1.0
- [ ] Integración con APIs de libros (Google Books, Open Library)
- [ ] Búsqueda de libros por código de barras
- [ ] Importación automática de metadatos
- [ ] Sincronización en la nube (Firebase/Supabase)

#### Versión 1.2.0
- [ ] Compartir libros y recomendaciones en redes sociales
- [ ] Exportación de estadísticas en PDF
- [ ] Widgets de pantalla de inicio (Android/iOS)
- [ ] Modo offline mejorado

#### Versión 1.3.0
- [ ] Integración con Goodreads
- [ ] Sistema de etiquetas personalizadas
- [ ] Búsqueda avanzada con operadores booleanos
- [ ] Filtros guardados y favoritos

#### Versión 2.0.0
- [ ] Modo multibiblioteca (gestionar varias bibliotecas)
- [ ] Compartir biblioteca con otros usuarios
- [ ] Sistema de préstamos con recordatorios
- [ ] Integración con bibliotecas públicas

#### Futuro
- [ ] Recomendaciones basadas en IA
- [ ] Reconocimiento de texto (OCR) para añadir libros
- [ ] Modo de lectura social (book clubs virtuales)
- [ ] Integración con e-readers (Kindle, Kobo)

---

## 👩‍💻 Autor

**Ana Martínez Montañez**

Desarrolladora de software apasionada por la lectura y la tecnología. Este proyecto nace de la necesidad personal de gestionar una biblioteca creciente y la indecisión constante sobre qué leer a continuación.

### Contacto
- **GitHub**: [@anamartinez97m](https://github.com/anamartinez97m)
- **LinkedIn**: [Ana Martínez](https://www.linkedin.com/in/ana-m-2b8a528b/)

---

## 📄 Licencia

© 2025 Ana Martínez Montañez. Todos los derechos reservados.

Este proyecto es **propietario** y está desarrollado como proyecto personal. No está permitida la redistribución, modificación o uso comercial sin autorización expresa del autor.

---

## 🙏 Agradecimientos

- A la comunidad de Flutter por el excelente framework
- A todos los desarrolladores de las librerías utilizadas
- A los lectores que inspiran este proyecto

---

<div align="center">

**¿Tienes preguntas o sugerencias?**

[Abrir un Issue](https://github.com/anamartinez97m/my-flutter-library/issues) • [Ver Documentación](https://github.com/anamartinez97m/my-flutter-library)

Hecho con ❤️ y ☕ por Ana Martínez Montañez

</div>
