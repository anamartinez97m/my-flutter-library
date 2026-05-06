# 📚 My Book Vault

<div align="center">

**A comprehensive Flutter application for managing your personal book library**

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.2+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

Desarrollado por **Ana Martínez Montañez** como proyecto personal  
© 2026 Ana Martínez Montañez. Todos los derechos reservados.

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

La aplicación no solo te permite catalogar y organizar tus libros, sino que también incluye un **sistema de recomendaciones aleatorias**, **estadísticas avanzadas de lectura**, **sincronización en la nube** con Firebase, y **autocompletado de metadatos** desde Google Books y Open Library.

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
  - Formato (físico, digital, audiolibro, etc.)
  - Número de páginas y año de publicación original
  - Fecha de adquisición (año o fecha completa)
  - Precio de compra
  - Estado de lectura (leído, leyendo, pendiente, etc.)
  - Portada e información de préstamo

#### Autocompletado de Metadatos desde API
- **Escaneo de código de barras** (ISBN) con la cámara del dispositivo
- **Búsqueda automática** al introducir o escanear un ISBN:
  - Estrategia híbrida: **Google Books** como fuente principal, **Open Library** como fallback
  - Rellena automáticamente título, autores, editorial, páginas, año, idioma, sinopsis y portada
  - Solo rellena campos vacíos, nunca sobreescribe datos manuales
- Portada y sinopsis almacenadas en la base de datos local

#### Gestión de Sagas y Series
- Organización de libros por **sagas** y **universos de sagas**
- Numeración de libros dentro de una saga
- **Formato de saga** con valores localizados (Independiente, Bilogía, Trilogía, Tetralogía, Pentalogía, Hexalogía, Saga)
- Soporte para **bundles** (colecciones de varios libros en un solo volumen):
  - Gestión de títulos individuales dentro del bundle
  - Fechas de lectura independientes por libro
  - Páginas y años de publicación por volumen
  - Autores específicos para cada libro del bundle

#### Historial de Lectura
- **Historial completo de fechas de lectura** por libro (tabla `book_read_dates`)
- Soporte para **relecturas**: múltiples entradas de fecha por libro
- **Contador de relecturas** actualizado automáticamente
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
- **Formato**, **Idioma**, **Género**, **Lugar**, **Estado de lectura**
- **Editorial**, **Saga**, **Universo de saga**, **Formato de saga**
- **Páginas vacías**, **Año de publicación vacío**, **Precio**
- **Bundles**, **Lectura en tándem**
- **Formato de saga sin saga**: detectar libros con tipo de saga pero sin nombre de saga
- **Formato de saga sin número**: libros sin numeración dentro de la saga
- **Saga sin formato de saga**: libros con saga pero sin tipo de saga asignado
- **Valoración**: filtrar por puntuación
- Filtros configurables individualmente desde Ajustes → Gestionar Filtros de Home

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

Pantalla rediseñada con arquitectura de **carousel multi-pantalla** y cálculos separados en `StatisticsCalculator`. Basada en el historial real de fechas de lectura (`book_read_dates`).

#### Dashboard Principal
- **Total de libros** y **último libro añadido**
- **QuickStatsRow**: 4 métricas rápidas configurables (mantener pulsado para cambiar entre 15 opciones)
- Secciones navegables con swipe y dot indicators

#### Secciones de Carousel
- **Actividad Lectora**: libros/páginas por año, velocidad de lectura, tiempo medio, mapa de calor mensual
- **Desglose de Biblioteca**: por estado, formato, lugar, idioma y tabla formato×idioma
- **Top Rankings**: géneros, editoriales y autores más leídos
- **Valoraciones y Páginas**: distribución de ratings y páginas, libros extremos
- **Sagas y Series**: completitud de sagas, serie vs. independiente
- **Patrones de Lectura**: estacional, rachas, maratón lector, mood reading
- **Campeones**: mejores y peores libros por distintos criterios

#### Métricas Destacadas
- **Velocidad de lectura** (páginas/día), **tiempo medio para terminar un libro**
- **Rachas de lectura** (streak actual y máximo)
- **Mapa de calor mensual** (basado en historial real, soporte relecturas)
- **Estadísticas de precio** e inversión en libros

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
- Todas las cadenas de texto localizadas, incluidos valores de formato de saga

#### Modo Administrador
- Desbloquea filtros avanzados, herramientas de biblioteca y fuente de metadatos en detalles
- Activable desde Ajustes → Modo Administrador

#### Otras Preferencias
- **Símbolo de moneda** configurable (€, $, £, etc.)
- **Límite de TBR** configurable
- **Filtros de Home** y **orden por defecto** persistentes

### 💾 Copias de Seguridad y Sincronización

#### Backup Automático
- Frecuencia configurable: **Desactivado / Diario / Semanal / Mensual**
- Copia local en `Documents/auto_backups/` con rotación de 5 copias
- Copia en **Firebase Storage** si el usuario está autenticado con Google
- Cada backup incluye la base de datos SQLite + JSON de configuración
- Protección contra backups vacíos accidentales

#### Backup Manual y Nube
- **Crear backup** y **restaurar backup** desde archivo local
- **Subir backup** / **descargar backup** desde Firebase Storage
- Autenticación con **Google Sign-In**

### 📤 Importación y Exportación

#### Importación desde CSV
- Importar múltiples libros desde un archivo CSV
- Compatible con el formato exportado por la propia app, formato legacy y Goodreads
- Detección automática de duplicados por ISBN
- Reporte detallado (importados, omitidos, duplicados)

#### Exportación a CSV
- Exportar toda la biblioteca con todos los campos
- Compatible con Excel y Google Sheets

### 🔧 Herramientas de Biblioteca

Accesibles desde Ajustes → **Herramientas de Biblioteca** (requiere Modo Admin):

- **Asignación masiva**: Selecciona campo → valor → libros → aplica a todos de una vez
- **Rellenar campos vacíos**: Asistente agrupado por autor con chips de sugerencia
- **Sugerencias inteligentes**: Motor de análisis con umbral de confianza ≥70%, acepta/rechaza por sugerencia

#### Gestión de Datos
- **Eliminar todos los datos**: Borrado completo con doble confirmación
- **Gestión de dropdowns**: Añadir, editar y eliminar valores de estados, idiomas, formatos, etc.

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
- **Providers**: `BookProvider`, `ThemeProvider`, `LocaleProvider`
- **Services**:
  - `NotificationService`: notificaciones locales
  - `BookMetadataService`: orquestador API híbrida (Google Books + Open Library)
  - `GoogleBooksService` / `OpenLibraryService`: fuentes de metadatos
  - `BackupService`: backup local + Firebase Storage
  - `GoogleAuthService`: autenticación con Google
- **Helpers**: `StatisticsCalculator` (cálculo separado de la UI), `SuggestionEngine`
- **Utils**: `StatusHelper`, `FormatSagaHelper`, `DateFormatter`, `CSVImportHelper`

#### 3. **Data Layer**
- **Repositories**: `BookRepository`, `ReadingSessionRepository`, `YearChallengeRepository`, `BookRatingFieldRepository`
- **Models**: `Book`, `ReadDate`, `ReadingSession`, `YearChallenge`, `CustomChallenge`, `BookMetadata`, `BookRatingField`
- **Database**: `DatabaseHelper` (Singleton SQLite, versión 39)

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
├── config/
│   └── app_theme.dart
│
├── db/
│   ├── database_helper.dart        # Singleton SQLite (v39)
│   └── migrations/
│
├── helpers/
│   ├── statistics_calculator.dart  # Toda la lógica de cálculo de estadísticas
│   └── suggestion_engine.dart      # Motor de sugerencias inteligentes
│
├── l10n/
│   ├── app_en.arb
│   ├── app_es.arb
│   ├── app_localizations.dart
│   ├── app_localizations_en.dart
│   └── app_localizations_es.dart
│
├── model/
│   ├── book.dart
│   ├── book_metadata.dart          # Respuesta de APIs de metadatos
│   ├── book_rating_field.dart
│   ├── custom_challenge.dart
│   ├── read_date.dart
│   ├── reading_session.dart
│   └── year_challenge.dart
│
├── providers/
│   ├── book_provider.dart
│   ├── locale_provider.dart
│   └── theme_provider.dart
│
├── repositories/
│   ├── book_rating_field_repository.dart
│   ├── book_repository.dart
│   ├── reading_session_repository.dart
│   └── year_challenge_repository.dart
│
├── screens/
│   ├── add_book.dart
│   ├── admin_csv_import.dart
│   ├── book_detail.dart
│   ├── books_by_author.dart
│   ├── books_by_decade.dart
│   ├── books_by_saga.dart
│   ├── books_by_year.dart
│   ├── bundle_migration_screen.dart
│   ├── edit_book.dart
│   ├── fill_empty_wizard_screen.dart   # Herramienta: rellenar campos vacíos
│   ├── home.dart
│   ├── manage_dropdowns.dart
│   ├── navigation.dart
│   ├── random.dart
│   ├── reverse_assign_screen.dart      # Herramienta: asignación masiva
│   ├── saga_completion_detail.dart
│   ├── settings.dart
│   ├── smart_suggestions_screen.dart   # Herramienta: sugerencias inteligentes
│   ├── statistics.dart                 # Dashboard + secciones carousel
│   ├── statistics_section_screen.dart  # Pantalla genérica de carousel
│   └── year_challenges.dart
│
├── services/
│   ├── backup_service.dart             # Backup local + Firebase Storage
│   ├── book_metadata_service.dart      # Orquestador API híbrida
│   ├── google_auth_service.dart
│   ├── google_books_service.dart
│   ├── notification_service.dart
│   └── open_library_service.dart
│
├── utils/
│   ├── bundle_migration.dart
│   ├── csv_import_helper.dart
│   ├── date_formatter.dart
│   ├── format_saga_helper.dart         # Localización de valores format_saga
│   ├── reading_session_migration.dart
│   └── status_helper.dart
│
├── widgets/
│   ├── autocomplete_text_field.dart
│   ├── booklist.dart
│   ├── bundle_input_widget_v2.dart
│   ├── bundle_read_dates_widget.dart
│   ├── chip_autocomplete_field.dart
│   ├── chronometer_widget.dart
│   ├── heart_rating_input.dart
│   ├── quick_add_book_dialog.dart
│   ├── read_dates_widget.dart
│   ├── reading_session_history_widget.dart
│   ├── tbr_limit_setting.dart
│   └── statistics/
│       ├── quick_stats_row.dart         # 4 métricas configurables
│       └── [otras tarjetas de estadísticas]
│
└── main.dart

assets/
└── scripts/
    └── 1_creation.sql

android/ · ios/ · linux/ · macos/ · web/ · windows/
```

---

## 🗄️ Base de Datos

### Tecnología
- **SQLite** con `sqflite`
- Versión actual del esquema: **39**
- Migraciones automáticas en `DatabaseHelper._onUpgrade`

### Tabla: `book` (principal)

Columnas relevantes (selección):

| Columna | Tipo | Descripción |
|---|---|---|
| `book_id` | INTEGER PK | ID del libro |
| `name` | TEXT | Título |
| `status_id` | INTEGER FK | Estado de lectura |
| `format_saga_id` | INTEGER FK | Tipo de saga |
| `cover_url` | TEXT | URL de portada (API) |
| `description` | TEXT | Sinopsis (API) |
| `metadata_source` | TEXT | `google_books` / `open_library` / `merged` |
| `metadata_fetched_at` | TEXT | Timestamp ISO 8601 |
| `acquired_date` | TEXT | `YYYY` o `YYYY-MM-DD` |
| `price` | REAL | Precio de compra |

### Tabla: `book_read_dates`
Historial completo de lectura (soporte para relecturas).

```sql
CREATE TABLE book_read_dates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  date_started TEXT,
  date_finished TEXT,
  FOREIGN KEY (book_id) REFERENCES book (book_id)
);
```

### Tabla: `reading_session`
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

### Tablas de Lookup
- `status` — valores core: `yes`, `no`, `started`, `tbreleased`, `abandoned`, `repeated`, `standby`
- `format_saga` — valores core: `Standalone`, `Bilogy`, `Trilogy`, `Tetralogy`, `Pentalogy`, `Hexalogy`, `Saga`
- `author`, `editorial`, `genre`, `language`, `place`, `format`

### Tablas de Relación
- `books_by_author`: muchos a muchos libros ↔ autores
- `books_by_genre`: muchos a muchos libros ↔ géneros

### Índices
- `idx_book_isbn`: búsquedas rápidas por ISBN

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
- **provider** ^6.1.2

#### Base de Datos
- **sqflite** ^2.4.2
- **path** ^1.9.1
- **path_provider** ^2.1.4

#### Internacionalización
- **flutter_localizations** (SDK)
- **intl** ^0.19.0

#### UI y Gráficos
- **fl_chart** ^0.69.0
- **cupertino_icons** ^1.0.8

#### Metadatos de Libros (API)
- **http** ^1.2.0 — peticiones a Google Books y Open Library
- **mobile_scanner** ^5.1.0 — escaneo de códigos de barras (ISBN)

#### Firebase y Autenticación
- **firebase_core** ^3.8.1
- **firebase_auth** ^5.4.1
- **firebase_storage** ^12.4.1
- **firebase_app_check** ^0.3.2+10
- **google_sign_in** ^6.2.2

#### Importación/Exportación
- **file_picker** ^8.0.0
- **csv** ^6.0.0

#### Notificaciones
- **flutter_local_notifications** ^17.2.3
- **timezone** ^0.9.4
- **flutter_timezone** ^3.0.1

#### Utilidades
- **shared_preferences** ^2.2.2
- **permission_handler** ^11.3.1
- **wakelock_plus** ^1.2.8
- **in_app_update** ^4.2.3

### Dependencias de Desarrollo
- **flutter_test** (SDK)
- **flutter_lints** ^5.0.0

---

## 🗺️ Roadmap

### Versión Actual: 1.0.0+14
Estado: **En desarrollo activo**

### ✅ Características ya implementadas

- [x] Integración con APIs de libros (Google Books + Open Library híbrido)
- [x] Escaneo de código de barras (ISBN) con la cámara
- [x] Autocompletado de metadatos (portada, sinopsis, autores, editorial, etc.)
- [x] Sincronización en la nube con Firebase Storage
- [x] Backup automático configurable (diario/semanal/mensual)
- [x] Autenticación con Google Sign-In
- [x] Estadísticas rediseñadas con carousel multi-pantalla
- [x] StatisticsCalculator separado de la UI
- [x] Herramientas de biblioteca (asignación masiva, rellenar vacíos, sugerencias inteligentes)
- [x] Historial completo de lectura con soporte para relecturas
- [x] Campo de fecha de adquisición
- [x] Estadísticas de precio e inversión
- [x] Localización de valores de formato de saga
- [x] Filtros avanzados configurables por el usuario
- [x] Modo administrador
- [x] Actualizaciones in-app

### 🔮 Características Planificadas

#### Próximas versiones
- [ ] Widgets de pantalla de inicio (Android/iOS)
- [ ] Exportación de estadísticas en PDF
- [ ] Compartir libros y recomendaciones en redes sociales
- [ ] Filtros guardados y favoritos
- [ ] Integración con Goodreads

#### Futuro
- [ ] Modo multibiblioteca
- [ ] Compartir biblioteca con otros usuarios
- [ ] Reconocimiento de texto (OCR) para añadir libros
- [ ] Integración con e-readers (Kindle, Kobo)
- [ ] Recomendaciones basadas en IA

---

## 👩‍💻 Autor

**Ana Martínez Montañez**

Desarrolladora de software apasionada por la lectura y la tecnología. Este proyecto nace de la necesidad personal de gestionar una biblioteca creciente y la indecisión constante sobre qué leer a continuación.

### Contacto
- **GitHub**: [@anamartinez97m](https://github.com/anamartinez97m)
- **LinkedIn**: [Ana Martínez](https://www.linkedin.com/in/ana-m-2b8a528b/)

---

## 📄 Licencia

© 2026 Ana Martínez Montañez. Todos los derechos reservados.

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
