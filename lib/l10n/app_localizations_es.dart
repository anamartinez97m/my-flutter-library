// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get app_title => 'My Book Vault';

  @override
  String get home => 'Inicio';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get random => 'Aleatorio';

  @override
  String get settings => 'Ajustes';

  @override
  String get search_by_title => 'Título';

  @override
  String get search_by_isbn => 'ISBN/ASIN';

  @override
  String get search_by_author => 'Autor';

  @override
  String get search_label => 'Buscar';

  @override
  String get search_hint => 'Buscar libros...';

  @override
  String get add_book => 'Añadir Libro';

  @override
  String get edit_book => 'Editar Libro';

  @override
  String get delete_book => 'Eliminar Libro';

  @override
  String get unknown_title => 'Título Desconocido';

  @override
  String get book_name => 'Nombre';

  @override
  String get isbn => 'ISBN';

  @override
  String isbn_with_colon(Object isbn) {
    return 'ISBN: $isbn';
  }

  @override
  String get author => 'Autor';

  @override
  String author_with_colon(Object author) {
    return 'Autor: $author';
  }

  @override
  String get saga => 'Saga';

  @override
  String get saga_universe => 'Universo de la Saga';

  @override
  String saga_with_colon(Object saga) {
    return 'Saga: $saga';
  }

  @override
  String get saga_number => 'Número de Saga';

  @override
  String get pages => 'Páginas';

  @override
  String get publication_year => 'Año de Publicación';

  @override
  String get editorial => 'Editorial';

  @override
  String get genre => 'Género';

  @override
  String genre_with_colon(Object genre) {
    return 'Género: $genre';
  }

  @override
  String get place => 'Lugar';

  @override
  String get format => 'Formato';

  @override
  String format_with_colon(Object format) {
    return 'Formato: $format';
  }

  @override
  String get format_saga => 'Formato Saga';

  @override
  String get status => 'Estado de Lectura';

  @override
  String get loaned => 'Prestado';

  @override
  String get date_created => 'Fecha de Creación';

  @override
  String language_with_colon(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get my_rating => 'Mi Valoración';

  @override
  String get times_read => 'Veces Leído';

  @override
  String get date_started_reading => 'Fecha de Inicio de Lectura';

  @override
  String get date_finished_reading => 'Fecha de Finalización de Lectura';

  @override
  String get my_review => 'Mi Reseña';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clear => 'Limpiar';

  @override
  String get apply => 'Aplicar';

  @override
  String get delete => 'Eliminar';

  @override
  String get add => 'Agregar';

  @override
  String get duration_label => 'Duración';

  @override
  String get enter_valid_number => 'Por favor ingresa un número válido (1 o mayor)';

  @override
  String get import_csv => 'Importar desde CSV';

  @override
  String get export_csv => 'Exportar a CSV';

  @override
  String get create_backup => 'Crear Copia de Seguridad';

  @override
  String get backup_canceled => 'Copia de Seguridad Cancelada';

  @override
  String backup_created_successfully(Object backup_path) {
    return 'Copia de Seguridad Creada Exitosamente!\n $backup_path';
  }

  @override
  String get replace_database => 'Reemplazar Base de Datos';

  @override
  String get database_restored_successfully => 'Base de Datos Restaurada Exitosamente!';

  @override
  String import_backup_error(Object error) {
    return 'Error importando copia de seguridad: $error';
  }

  @override
  String error_importing_backup(Object error) {
    return 'Error importando copia de seguridad: $error';
  }

  @override
  String get import_backup => 'Importar Copia de Seguridad';

  @override
  String get import_database_backup => 'Importar Base de Datos';

  @override
  String get import_backup_confirmation => 'Esta acción reemplazará tu base de datos actual con la copia de seguridad. Todos los datos actuales se perderán. ¿Estás seguro?';

  @override
  String get select_backup_file => 'Seleccionar archivo de copia de seguridad';

  @override
  String get delete_all_data => 'Eliminar Todos los Datos';

  @override
  String get creating_backup => 'Creando Copia de Seguridad...';

  @override
  String get importing_books => 'Importando Libros...';

  @override
  String get importing_backup => 'Importando Copia de Seguridad...';

  @override
  String get deleting_all_data => 'Eliminando Todos los Datos...';

  @override
  String get delete_all_data_confirmation => 'Esta acción eliminará permanentemente todos los libros de tu biblioteca. Esta acción no se puede deshacer!\n\n¿Estás seguro de que quieres continuar?';

  @override
  String deleted_books(Object count) {
    return 'Eliminados $count libros exitosamente';
  }

  @override
  String error_creating_backup(Object error) {
    return 'Error al crear la copia de seguridad: $error';
  }

  @override
  String error_importing_csv(Object error) {
    return 'Error al importar CSV: $error';
  }

  @override
  String error_deleting_data(Object error) {
    return 'Error al eliminar los datos: $error';
  }

  @override
  String import_completed(Object importedCount, Object skippedCount) {
    return 'Importación completada!\nImportados: $importedCount libros\nSaltados: $skippedCount filas';
  }

  @override
  String get import_completed_with_duplicates => 'Importación completada con duplicados!';

  @override
  String imported_books(Object importedCount) {
    return 'Importados: $importedCount libros';
  }

  @override
  String skipped_rows(Object skippedCount) {
    return 'Saltados: $skippedCount filas';
  }

  @override
  String duplicates_found(Object duplicateCount) {
    return 'Duplicados encontrados: $duplicateCount libros';
  }

  @override
  String get duplicate_books_not_imported => 'Libros duplicados (no importados):';

  @override
  String get books_already_exist => 'Estos libros ya existen en tu biblioteca. Puedes añadirlos manualmente si lo deseas.';

  @override
  String more_books(Object count) {
    return '... y $count más';
  }

  @override
  String get ok => 'OK';

  @override
  String get permanently_delete_all_books_from_the_database => 'Eliminar permanentemente todos los libros de la base de datos';

  @override
  String get light_theme_colors => 'Colores de Tema Claro';

  @override
  String get dark_theme_colors => 'Colores de Tema Oscuro';

  @override
  String get theme_mode => 'Modo de Tema';

  @override
  String get create_database_backup => 'Crear Copia de Seguridad';

  @override
  String get save_a_copy_of_your_library_database => 'Guardar una copia de tu base de datos de biblioteca';

  @override
  String get manage_dropdown_values => 'Gestionar valores de desplegable';

  @override
  String get manage_dropdown_values_hint => 'Gestionar valores de desplegable para estado, idioma, lugar, formato y formato saga.';

  @override
  String get import_from_csv_hint => 'Columnas CSV personalizado: Title, Author, ISBN, ASIN, Saga, N_Saga, Saga Universe, Format Saga, Status, Editorial, Language, Place, Format, Genre, Pages, Original Publication Year, Loaned, Date Read Initial, Date Read Final, Read Count, My Rating, My Review, Notes, Price, Release Date, Is Bundle, Bundle Count, TBR, Is Tandem, Cover URL, Description, Created At';

  @override
  String get import_from_csv_tbreleased => 'Para libros no publicados use estado TBReleased';

  @override
  String get import_from_csv => 'Importar libro desde CSV';

  @override
  String get import_from_csv_file => 'Importar libros desde un archivo CSV';

  @override
  String get restore_a_copy_of_your_library_database => 'Restaurar una copia de tu base de datos de biblioteca';

  @override
  String get theme => 'Tema';

  @override
  String get theme_light => 'Claro';

  @override
  String get theme_dark => 'Oscuro';

  @override
  String get theme_system => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get total_books => 'Total de Libros';

  @override
  String get latest_book_added => 'Último Libro Añadido';

  @override
  String get books_by_status => 'Libros por Estado';

  @override
  String get books_by_language => 'Libros por Idioma';

  @override
  String get books_by_format => 'Libros por Formato';

  @override
  String get no_books_in_database => 'No hay libros en la base de datos';

  @override
  String get top_10_editorials => 'Top 10 Editoriales';

  @override
  String get top_10_authors => 'Top 10 Autores';

  @override
  String get get_random_book => 'Obtener Libro Aleatorio';

  @override
  String get filters => 'Filtros';

  @override
  String get any => 'Cualquiera';

  @override
  String get confirm_delete => '¿Estás seguro de que quieres eliminar este libro?';

  @override
  String get confirm_delete_all => 'Esto eliminará permanentemente TODOS los libros de tu biblioteca. ¡Esta acción no se puede deshacer!\\n\\n¿Estás seguro de que quieres continuar?';

  @override
  String get book_added_successfully => '¡Libro añadido con éxito!';

  @override
  String get book_updated_successfully => '¡Libro actualizado con éxito!';

  @override
  String get book_deleted_successfully => '¡Libro eliminado con éxito!';

  @override
  String get no_books_found => 'No se encontraron libros';

  @override
  String get no_data => 'Sin datos';

  @override
  String get reading_information => 'Información de Lectura (Opcional)';

  @override
  String get add_read => 'Añadir Lectura';

  @override
  String get tap_hearts_to_rate => 'Toca los corazones para valorar (toca de nuevo para medio corazón)';

  @override
  String get top_5_genres => 'Top 5 Géneros';

  @override
  String get about_box_children => 'Aplicación desarrollada con Flutter/Dart.\n Permite gestionar tu biblioteca personal y recibir recomendaciones de lectura personalizadas.';

  @override
  String get sort_and_filter => 'Ordenar y Filtrar';

  @override
  String get empty => 'Vacío';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get isbn_asin => 'ISBN/ASIN';

  @override
  String get bundle => 'Paquete';

  @override
  String get tandem => 'Tándem';

  @override
  String get saga_format_without_saga => 'Formato de Saga Sin Saga';

  @override
  String get saga_format_without_n_saga => 'Formato de Saga Sin N_Saga';

  @override
  String get saga_without_format_saga => 'Saga Sin Formato de Saga';

  @override
  String get publication_year_empty => 'Año de Publicación';

  @override
  String get rating_filter => 'Valoración';

  @override
  String pages_with_colon(Object pages) {
    return 'Páginas: $pages';
  }

  @override
  String get max_tbr_books_description => 'Número máximo de libros que puedes marcar como \'Por Leer\' a la vez:';

  @override
  String max_tbr_books_subtitle(Object tbrLimit) {
    return 'Libros máximos en \'Por Leer\': $tbrLimit';
  }

  @override
  String get set_tbr_limit => 'Establecer Límite TBR';

  @override
  String get tbr_limit => 'Límite TBR';

  @override
  String get books => 'libros';

  @override
  String get please_enter_valid_number => 'Por favor ingresa un número válido mayor a 0';

  @override
  String get maximum_limit_200_books => 'Límite máximo es de 200 libros';

  @override
  String get range_1_200_books => 'Rango: 1-200 libros';

  @override
  String get this_is_a_bundle => 'Esto es un paquete';

  @override
  String get check_if_this_book_contains_multiple_books => 'Marca si este libro contiene múltiples libros en un volumen';

  @override
  String get number_of_books_in_bundle => 'Número de libros en el paquete';

  @override
  String get saga_numbers_optional => 'Números de saga (opcional)';

  @override
  String get saga_number_n_saga => 'Número de saga (N_Saga)';

  @override
  String get book_title => 'Título del libro';

  @override
  String get authors => 'Autor(es)';

  @override
  String get original_publication_year => 'Año de publicación original';

  @override
  String get started => 'Iniciado';

  @override
  String get finished => 'Terminado';

  @override
  String get search_books_by_title => 'Buscar libros por título';

  @override
  String get stop_timer => 'Detener temporizador';

  @override
  String get do_you_want_to_stop_the_reading_timer => '¿Quieres detener el temporizador de lectura?';

  @override
  String get stop => 'Detener';

  @override
  String get timer_is_running => 'El temporizador está en ejecución';

  @override
  String get exit => 'Salir';

  @override
  String get start => 'Iniciar';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get stop_save => 'Detener y guardar';

  @override
  String get quick_add => 'Agregar rápido';

  @override
  String add_book_s(Object count) {
    return 'Agregar $count libro(s)';
  }

  @override
  String get bundle_book_details => 'Detalles del libro del paquete';

  @override
  String select_label(Object label) {
    return 'Seleccionar $label';
  }

  @override
  String get full_date => 'Fecha completa';

  @override
  String get year_only => 'Solo año';

  @override
  String get add_session => 'Agregar sesión';

  @override
  String get enter_year => 'Ingresar año';

  @override
  String get please_enter_valid_year => 'Por favor ingresa un año válido';

  @override
  String get edit => 'Editar';

  @override
  String get close => 'Cerrar';

  @override
  String get proceed => 'Continuar';

  @override
  String get create => 'Crear';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get warning => 'Advertencia';

  @override
  String get info => 'Información';

  @override
  String get loading => 'Cargando';

  @override
  String get search => 'Buscar';

  @override
  String get filter => 'Filtrar';

  @override
  String get sort => 'Ordenar';

  @override
  String get reset => 'Restablecer';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get stop_timer_question => '¿Detener temporizador?';

  @override
  String get confirm_restore => 'Confirmar Restauración';

  @override
  String get confirm_restore_message => 'Esto reemplazará tu base de datos actual. ¡Asegúrate de tener una copia de seguridad!';

  @override
  String get restore => 'Restaurar';

  @override
  String get add_another => 'Añadir otro';

  @override
  String get go_to_home => 'Ir al inicio';

  @override
  String get missing_information => 'Información faltante';

  @override
  String get enable_release_notification => 'Habilitar notificación de lanzamiento';

  @override
  String get add_to_tbr => 'Añadir a TBR (Para Leer)';

  @override
  String get tbr_limit_reached => 'Límite TBR alcanzado';

  @override
  String get mark_as_tandem_book => 'Marcar como libro Tándem';

  @override
  String get scan_isbn => 'Escanear ISBN';

  @override
  String get customize_home_filters => 'Personalizar filtros de inicio';

  @override
  String get select_all => 'Seleccionar todo';

  @override
  String get clear_all => 'Limpiar todo';

  @override
  String books_removed_from_tbr(Object bookName) {
    return '$bookName eliminado de TBR';
  }

  @override
  String error_occurred(Object error) {
    return 'Error: $error';
  }

  @override
  String tbr_books_count(Object count) {
    return '$count';
  }

  @override
  String get no_books_from_decade => 'No hay libros leídos de esta década';

  @override
  String decade_book_count(Object decade, Object totalCount) {
    return '$decade ($totalCount libros)';
  }

  @override
  String get migrate_bundle_books => '¿Migrar libros del paquete?';

  @override
  String get migrate => 'Migrar';

  @override
  String successful_migrations(Object count) {
    return '✅ Exitosos: $count';
  }

  @override
  String skipped_migrations(Object count) {
    return '⏭️  Omitidos: $count';
  }

  @override
  String failed_migrations(Object count) {
    return '❌ Fallidos: $count';
  }

  @override
  String get import_from_goodreads => 'Importar desde Goodreads';

  @override
  String get import_all_books => 'Importar todos los libros';

  @override
  String get import_books_from_tag => 'Importar libros de una etiqueta específica';

  @override
  String add_dropdown_value(Object valueType) {
    return 'Añadir $valueType';
  }

  @override
  String edit_dropdown_value(Object valueType) {
    return 'Editar $valueType';
  }

  @override
  String get cannot_delete => 'No se puede eliminar';

  @override
  String get delete_value => 'Eliminar valor';

  @override
  String get replace_with_existing_value => 'Reemplazar con valor existente';

  @override
  String get create_new_value => 'Crear nuevo valor';

  @override
  String get delete_completely => 'Eliminar completamente (puede fallar)';

  @override
  String get new_year_challenge => 'Nuevo reto anual';

  @override
  String edit_year_challenge(Object year) {
    return 'Editar reto $year';
  }

  @override
  String get delete_challenge => 'Eliminar reto';

  @override
  String get year_challenges => 'Retos anuales';

  @override
  String best_book_of_year(Object year) {
    return 'Mejor libro de $year';
  }

  @override
  String get best_book_competition => 'Competencia del Mejor Libro';

  @override
  String get winner => 'Ganador';

  @override
  String get nominees => 'Nominados';

  @override
  String get tournament_tree => 'Árbol del Torneo';

  @override
  String get quarterly_winners => 'Ganadores Trimestrales';

  @override
  String get semifinals => 'Semifinales';

  @override
  String get last => 'Final';

  @override
  String get monthly_winners => 'Ganadores Mensuales';

  @override
  String no_books_read_year(Object year) {
    return 'No hay libros leídos en $year';
  }

  @override
  String get no_competition_data => 'No hay datos de competencia disponibles';

  @override
  String error_loading_competition(Object error) {
    return 'Error al cargar datos de competencia: $error';
  }

  @override
  String get update_available_title => 'Actualización Disponible';

  @override
  String get update_available_message => 'Una nueva versión de My Book Vault está disponible. Actualiza ahora para obtener las últimas funciones y mejoras.';

  @override
  String get update_now => 'Actualizar';

  @override
  String get update_later => 'Más tarde';

  @override
  String get admin_mode => 'Modo Administrador';

  @override
  String get admin_mode_subtitle => 'Habilitar funciones avanzadas como importación CSV de administrador';

  @override
  String get admin_csv_import => 'Importación CSV Admin';

  @override
  String get admin_csv_import_subtitle => 'Revisar y editar cada libro antes de importar';

  @override
  String get default_values => 'Valores Predeterminados';

  @override
  String get default_values_subtitle => 'Límite TBR, Orden, Filtros de Inicio, Campos de Tarjeta';

  @override
  String get import_export => 'Importar/Exportar';

  @override
  String get import_export_subtitle => 'CSV y Copia de Seguridad';

  @override
  String get customize_home_filters_subtitle => 'Seleccionar qué filtros mostrar en la pantalla de inicio';

  @override
  String get customize_card_fields => 'Personalizar Campos de Tarjeta';

  @override
  String get customize_card_fields_subtitle => 'Seleccionar qué datos mostrar en las tarjetas de libros';

  @override
  String fields_selected(Object count) {
    return '$count campos seleccionados';
  }

  @override
  String get default_sort_order => 'Orden Predeterminado';

  @override
  String get default_sort_order_subtitle => 'Establecer el orden predeterminado para tu lista de libros';

  @override
  String get sort_by => 'Ordenar Por';

  @override
  String get date_added => 'Fecha de Adición';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Descendente';

  @override
  String get export_to_csv => 'Exportar a CSV';

  @override
  String get export_to_excel => 'Exportar a Excel';

  @override
  String get preparing_csv_export => 'Preparando exportación CSV...';

  @override
  String get no_books_to_export => 'No hay libros para exportar';

  @override
  String get export_canceled => 'Exportación cancelada';

  @override
  String exported_books(Object count, Object path) {
    return 'Exportados $count libros a:\n$path';
  }

  @override
  String error_exporting_csv(Object error) {
    return 'Error al exportar a CSV: $error';
  }

  @override
  String get permission_required => 'Permiso Requerido';

  @override
  String get storage_permission_backup => 'Se necesita permiso de almacenamiento para crear copias de seguridad. ¿Desea conceder el permiso?';

  @override
  String get storage_permission_export => 'Se necesita permiso de almacenamiento para exportar archivos CSV. ¿Desea conceder el permiso?';

  @override
  String get grant_permission => 'Conceder Permiso';

  @override
  String get select_folder_save_backup => 'Seleccionar carpeta para guardar copia de seguridad';

  @override
  String get select_csv_file => 'Seleccionar archivo CSV';

  @override
  String get select_folder_save_csv => 'Seleccionar carpeta para guardar CSV';

  @override
  String get select_folder_save_excel_csv => 'Seleccionar carpeta para guardar CSV de Excel';

  @override
  String get please_select_csv_file => 'Por favor seleccione un archivo CSV';

  @override
  String get importing_books_from_csv => 'Importando libros desde CSV...';

  @override
  String get import_completed_title => 'Importación Completada';

  @override
  String import_result_message(Object imported, Object updated, Object skipped) {
    return 'Importados: $imported libros\nActualizados: $updated libros\nOmitidos: $skipped filas';
  }

  @override
  String get select_tag => 'Seleccionar etiqueta';

  @override
  String get deleting_all_books => 'Eliminando todos los libros...';

  @override
  String get goodreads_csv_hint => 'Columnas CSV de Goodreads: Title, Author, ISBN13, ASIN, My Rating, Publisher, Binding, Number of Pages, Original Publication Year, Date Read, Date Added, Bookshelves, Exclusive Shelf, My Review, Read Count. Los libros deben tener \"owned\" o \"read-loaned\" en estanterías para ser importados';

  @override
  String get manage_rating_field_names => 'Gestionar Nombres de Campos de Valoración';

  @override
  String get manage_rating_field_names_subtitle => 'Añadir, editar o eliminar nombres de criterios de valoración';

  @override
  String get manage_club_names => 'Gestionar Nombres de Clubes';

  @override
  String get manage_club_names_subtitle => 'Renombrar o eliminar clubes de lectura';

  @override
  String get migrate_bundle_books_title => 'Migrar Libros de Paquete';

  @override
  String get migrate_bundle_books_subtitle => 'Convertir paquetes antiguos al nuevo sistema';

  @override
  String get available => 'Disponible';

  @override
  String get migrate_reading_sessions => 'Migrar Sesiones de Lectura';

  @override
  String get migrate_reading_sessions_subtitle => 'Mover sesiones de lectura a libros individuales';

  @override
  String get migrate_reading_sessions_question => '¿Migrar Sesiones de Lectura?';

  @override
  String get no_sessions_to_migrate => 'No hay sesiones de lectura para migrar. ¡Todas las sesiones ya están en libros individuales!';

  @override
  String get migrating_reading_sessions => 'Migrando sesiones de lectura...';

  @override
  String get migration_successful => '¡Migración Exitosa!';

  @override
  String get migration_completed_with_errors => 'Migración Completada con Errores';

  @override
  String get what_will_happen => 'Qué sucederá:';

  @override
  String get migration_description => '• Las sesiones de lectura se copiarán a libros individuales\n• Las sesiones antiguas de paquetes se eliminarán\n• Esto corrige inconsistencias en el historial de lectura de paquetes';

  @override
  String get migration_safe_info => 'ℹ️ Esto es seguro y se puede ejecutar varias veces';

  @override
  String successful_bundles(Object count) {
    return '✅ Exitosos: $count paquetes';
  }

  @override
  String skipped_bundles(Object count) {
    return '⏭️  Omitidos: $count paquetes';
  }

  @override
  String failed_bundles(Object count) {
    return '❌ Fallidos: $count paquetes';
  }

  @override
  String total_sessions_migrated(Object count) {
    return '📚 Total de sesiones migradas: $count';
  }

  @override
  String get errors_label => 'Errores:';

  @override
  String error_migrating_reading_sessions(Object error) {
    return 'Error al migrar sesiones de lectura: $error';
  }

  @override
  String get warm_earth => 'Tierra Cálida';

  @override
  String get vibrant_sunset => 'Atardecer Vibrante';

  @override
  String get soft_pastel => 'Pastel Suave';

  @override
  String get deep_ocean => 'Océano Profundo';

  @override
  String get custom => 'Personalizado';

  @override
  String get mystic_purple => 'Púrpura Místico';

  @override
  String get deep_sea => 'Mar Profundo';

  @override
  String get warm_autumn => 'Otoño Cálido';

  @override
  String get edit_custom_light_palette => 'Editar Paleta Clara Personalizada';

  @override
  String get edit_custom_dark_palette => 'Editar Paleta Oscura Personalizada';

  @override
  String get primary => 'Primario';

  @override
  String get secondary => 'Secundario';

  @override
  String get tertiary => 'Terciario';

  @override
  String get pick_a_color => 'Elegir un Color';

  @override
  String get pick_a_custom_color => 'Elegir un Color Personalizado';

  @override
  String get hue => 'Tono';

  @override
  String get application_name => 'My Random Library';

  @override
  String get application_legalese => '© 2025 Ana Martínez Montañez. Todos los derechos reservados.';

  @override
  String get books_by_decade => 'Libros por Década';

  @override
  String get decade_label => 'Década: ';

  @override
  String get re_read_books => 'Libros Releídos';

  @override
  String get authors_title => 'Autores';

  @override
  String get saga_completion => 'Completitud de Sagas';

  @override
  String get books_by_saga => 'Libros por Saga';

  @override
  String get bundle_migration => 'Migración de Paquetes';

  @override
  String get books_by_year => 'Libros por Año';

  @override
  String get reading_status_required => 'Estado de Lectura *';

  @override
  String get status_is_required => 'El estado es obligatorio';

  @override
  String get add_rating_criterion => 'Añadir Criterio de Valoración';

  @override
  String get no_books_match_filters => 'Ningún libro coincide con los filtros seleccionados';

  @override
  String get specific_number_of_books => 'Número específico de libros';

  @override
  String get unknown_show_as_question => 'Desconocido (mostrar como \"?\")';

  @override
  String get for_sagas_unknown_length => 'Para sagas con longitud desconocida o variable';

  @override
  String get continue_label => 'Continuar';

  @override
  String confirm_delete_value(Object value) {
    return '¿Estás seguro de que quieres eliminar \"$value\"?';
  }

  @override
  String get this_will_fail_constraint => 'Esto fallará si las restricciones de la base de datos lo impiden';

  @override
  String get field_name => 'Nombre del Campo';

  @override
  String get add_rating_field_name => 'Añadir Nombre de Campo de Valoración';

  @override
  String get edit_rating_field_name => 'Editar Nombre de Campo de Valoración';

  @override
  String get delete_rating_field_name => 'Eliminar Nombre de Campo de Valoración';

  @override
  String field_name_already_exists(Object name) {
    return 'El nombre de campo \"$name\" ya existe';
  }

  @override
  String added_value(Object value) {
    return 'Añadido \"$value\"';
  }

  @override
  String error_adding_field_name(Object error) {
    return 'Error al añadir nombre de campo: $error';
  }

  @override
  String updated_value(Object oldValue, Object newValue) {
    return 'Actualizado \"$oldValue\" a \"$newValue\"';
  }

  @override
  String error_updating_field_name(Object error) {
    return 'Error al actualizar nombre de campo: $error';
  }

  @override
  String confirm_delete_field(Object name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String field_used_in_ratings(Object count) {
    return 'Este campo se usa en $count valoración(es). Se eliminarán.';
  }

  @override
  String deleted_value(Object value) {
    return 'Eliminado \"$value\"';
  }

  @override
  String error_deleting_field_name(Object error) {
    return 'Error al eliminar nombre de campo: $error';
  }

  @override
  String get about_rating_fields => 'Acerca de los Campos de Valoración';

  @override
  String get about_rating_fields_description => 'Estos son los nombres de criterios disponibles al valorar libros. Puedes añadir nombres personalizados o editar los existentes. Los cambios se aplicarán a todas las valoraciones futuras.';

  @override
  String get no_rating_field_names => 'Aún no hay nombres de campos de valoración';

  @override
  String get default_suggestion => 'Sugerencia predeterminada';

  @override
  String get add_field_name => 'Añadir Nombre de Campo';

  @override
  String get rename_club => 'Renombrar Club';

  @override
  String get club_name => 'Nombre del Club';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete_club => 'Eliminar Club';

  @override
  String delete_club_message(Object clubName, Object count, Object bookWord) {
    return '¿Eliminar \"$clubName\"?\n\nEsto eliminará $count $bookWord de este club.';
  }

  @override
  String club_already_exists(Object name) {
    return 'El club \"$name\" ya existe';
  }

  @override
  String renamed_club(Object oldName, Object newName) {
    return 'Renombrado \"$oldName\" a \"$newName\"';
  }

  @override
  String error_renaming_club(Object error) {
    return 'Error al renombrar club: $error';
  }

  @override
  String error_deleting_club(Object error) {
    return 'Error al eliminar club: $error';
  }

  @override
  String get no_clubs_yet => 'Aún no hay clubes';

  @override
  String get add_books_to_clubs_hint => 'Añade libros a clubes desde los detalles del libro';

  @override
  String get book_word => 'libro';

  @override
  String get books_word => 'libros';

  @override
  String get target_books_required => 'Libros Objetivo *';

  @override
  String get target_pages_optional => 'Páginas Objetivo (opcional)';

  @override
  String get notes_optional => 'Notas (opcional)';

  @override
  String get notes_hint => 'Cualquier nota sobre este reto';

  @override
  String get custom_challenges => 'Retos Personalizados';

  @override
  String get custom_challenges_hint => 'Añadir objetivos de lectura personalizados (ej., \"Leer 5 clásicos\", \"Terminar 3 series\")';

  @override
  String get goal_name => 'Nombre del objetivo';

  @override
  String get goal_name_hint => 'ej., Leer 5 clásicos';

  @override
  String get target => 'Objetivo';

  @override
  String get unit => 'Unidad';

  @override
  String get unit_hint => 'ej., libros, capítulos, páginas';

  @override
  String get enter_valid_target_books => 'Por favor ingrese un número válido de libros objetivo';

  @override
  String get enter_valid_target_or_custom => 'Por favor ingrese libros objetivo válidos o añada retos personalizados';

  @override
  String get challenge_created => '¡Reto creado exitosamente!';

  @override
  String error_creating_challenge(Object error) {
    return 'Error al crear reto: $error';
  }

  @override
  String get challenge_updated => '¡Reto actualizado exitosamente!';

  @override
  String error_updating_challenge(Object error) {
    return 'Error al actualizar reto: $error';
  }

  @override
  String confirm_delete_challenge(Object year) {
    return '¿Estás seguro de que quieres eliminar el reto de $year?';
  }

  @override
  String get challenge_deleted => 'Reto eliminado';

  @override
  String error_deleting_challenge(Object error) {
    return 'Error al eliminar reto: $error';
  }

  @override
  String get current_progress => 'Progreso Actual';

  @override
  String get update => 'Actualizar';

  @override
  String get challenge_progress_updated => '¡Progreso del reto actualizado!';

  @override
  String get current_label => 'Actual';

  @override
  String get books_label => 'Libros:';

  @override
  String get pages_label => 'Páginas:';

  @override
  String get new_challenge => 'Nuevo Reto';

  @override
  String get bundle_reading_sessions => 'Sesiones de Lectura del Paquete';

  @override
  String book_n(Object n) {
    return 'Libro $n';
  }

  @override
  String session_n(Object n) {
    return 'Sesión $n';
  }

  @override
  String get no_reading_sessions => 'Sin sesiones de lectura';

  @override
  String get not_set => 'No establecido';

  @override
  String get start_date => 'Fecha de Inicio';

  @override
  String get end_date => 'Fecha de Fin';

  @override
  String get started_reading => '¡Lectura iniciada!';

  @override
  String get marked_as_finished => '¡Marcado como terminado!';

  @override
  String get marked_as_read => '¡Marcado como leído!';

  @override
  String error_refetching_metadata(Object error) {
    return 'Error al obtener metadatos: $error';
  }

  @override
  String get reading_history => 'Historial de Lectura';

  @override
  String get reading_sessions => 'Sesiones de Lectura';

  @override
  String get no_reading_history => 'Sin historial de lectura';

  @override
  String get no_sessions_recorded => 'Sin sesiones registradas';

  @override
  String get description => 'Descripción';

  @override
  String get show_more => 'Mostrar más';

  @override
  String get show_less => 'Mostrar menos';

  @override
  String get no_description_available => 'Sin descripción disponible';

  @override
  String get books_in_bundle => 'Libros en el Paquete';

  @override
  String get notes => 'Notas';

  @override
  String get price_label => 'Precio';

  @override
  String get original_book => 'Libro Original';

  @override
  String get view_original => 'Ver Original';

  @override
  String get start_reading => 'Iniciar Lectura';

  @override
  String get mark_as_finished => 'Marcar como Terminado';

  @override
  String get mark_as_read => 'Marcar como Leído';

  @override
  String get confirm_finish_title => 'Terminar Lectura';

  @override
  String get confirm_mark_read_title => 'Marcar como Leído';

  @override
  String get reading_clubs => 'Clubes de Lectura';

  @override
  String get add_to_club => 'Añadir a Club';

  @override
  String get new_club => 'Nuevo Club';

  @override
  String get enter_club_name => 'Ingrese nombre del club';

  @override
  String get remove_from_club => '¿Eliminar del club?';

  @override
  String removed_from_club(Object club) {
    return 'Eliminado de $club';
  }

  @override
  String added_to_club(Object club) {
    return 'Añadido a $club';
  }

  @override
  String total_bundles(Object count) {
    return 'Total de paquetes: $count';
  }

  @override
  String individual_books_created(Object count) {
    return '📚 Libros individuales creados: $count';
  }

  @override
  String migration_failed(Object error) {
    return 'Migración fallida: $error';
  }

  @override
  String get pages_empty => 'Páginas Vacías';

  @override
  String get is_bundle => 'Es Paquete';

  @override
  String get is_tandem => 'Es Tándem';

  @override
  String get publication_year_empty_filter => 'Año de Publicación Vacío';

  @override
  String get publication_date => 'Fecha de Publicación';

  @override
  String get read_count => 'Veces Leído';

  @override
  String get reading_progress => 'Progreso de Lectura';

  @override
  String get enter_book_title => 'Ingrese título del libro';

  @override
  String get enter_author_names => 'Ingrese nombre(s) del autor, separar con comas';

  @override
  String get select_month => 'Seleccionar Mes';

  @override
  String get no_books_this_month => 'No hay libros leídos este mes';

  @override
  String get select_winner => 'Seleccionar Ganador';

  @override
  String get confirm_selection => 'Confirmar Selección';

  @override
  String get past_years_winners => 'Ganadores de Años Anteriores';

  @override
  String get no_past_winners => 'Aún no hay ganadores anteriores';

  @override
  String migrate_sessions_description(Object sessions, Object bundles) {
    return 'Esto migrará $sessions sesión(es) de lectura de $bundles paquete(s) a libros individuales.';
  }

  @override
  String migrate_bundles_description(Object count) {
    return 'Esto convertirá $count paquetes antiguos al nuevo sistema.\n\nSe crearán registros individuales para cada libro del paquete.\n\nEsto no se puede deshacer.';
  }

  @override
  String get import_from_tag => 'Importar desde Etiqueta';

  @override
  String import_options(Object format) {
    return 'Opciones de Importación ($format)';
  }

  @override
  String get update_reading_progress => 'Actualizar Progreso de Lectura';

  @override
  String get percentage => 'Porcentaje';

  @override
  String get pages_label_short => 'Páginas';

  @override
  String get progress_percentage => 'Progreso (%)';

  @override
  String get current_page => 'Página Actual';

  @override
  String total_pages(Object count) {
    return 'Páginas totales: $count';
  }

  @override
  String get percentage_cannot_exceed_100 => 'El porcentaje no puede superar 100';

  @override
  String page_cannot_exceed(Object count) {
    return 'El número de página no puede superar $count';
  }

  @override
  String get progress_updated => '¡Progreso actualizado!';

  @override
  String get did_you_read_today => 'He leído hoy';

  @override
  String get did_you_read_this_book_today => '¿Leíste este libro hoy?';

  @override
  String get yes_label => 'SÍ';

  @override
  String get no_label => 'NO';

  @override
  String get marked_read_today => '¡Marcado como leído hoy!';

  @override
  String get marked_not_read_today => 'Marcado como no leído hoy.';

  @override
  String get edit_reading_sessions => 'Editar Sesiones de Lectura';

  @override
  String session_label(Object index) {
    return 'Sesión $index';
  }

  @override
  String get date_label => 'Fecha';

  @override
  String get time_hhmmss => 'Tiempo (HH:MM)';

  @override
  String get duration_hint => 'Ingresa duración como: 1h 30m 5s, 90m, o solo segundos';

  @override
  String get sessions_updated => '¡Sesiones actualizadas!';

  @override
  String get add_reading_session => 'Agregar Sesión de Lectura';

  @override
  String get session_added => '¡Sesión agregada!';

  @override
  String get reading_time => 'Tiempo de Lectura';

  @override
  String get reading_time_details => 'Detalles del Tiempo de Lectura';

  @override
  String book_took_days(Object days, Object dayWord) {
    return 'Este libro tomó $days $dayWord en leer.';
  }

  @override
  String calculation_method(Object method) {
    return 'Método de Cálculo: $method';
  }

  @override
  String days_with_time_tracking(Object count) {
    return 'Días con seguimiento de tiempo: $count';
  }

  @override
  String days_with_reading_flag(Object count) {
    return 'Días solo con marca de lectura: $count';
  }

  @override
  String days_marked_as_read(Object count) {
    return 'Días marcados como leídos: $count';
  }

  @override
  String start_date_label(Object date) {
    return 'Fecha de inicio: $date';
  }

  @override
  String end_date_label(Object date) {
    return 'Fecha de fin: $date';
  }

  @override
  String bundle_books_calculated(Object count) {
    return 'Paquete: $count libros calculados';
  }

  @override
  String get confirm_delete_title => 'Confirmar Eliminación';

  @override
  String get book_details => 'Detalles del Libro';

  @override
  String get fetching_cover => 'Obteniendo portada...';

  @override
  String get no_cover_image => 'Sin imagen de portada';

  @override
  String get failed_to_load_image => 'Error al cargar imagen';

  @override
  String get added_to_tbr => 'Añadido a TBR';

  @override
  String get removed_from_tbr => 'Eliminado de TBR';

  @override
  String get remove_from_tbr => 'Quitar de TBR';

  @override
  String get add_to_tbr_short => 'Añadir a TBR';

  @override
  String get tap_to_update_progress => 'Toca para actualizar progreso';

  @override
  String get day_word => 'día';

  @override
  String get days_word => 'días';

  @override
  String get original_publication_year_label => 'Año de Publicación Original';

  @override
  String get original_publication_date_label => 'Fecha de Publicación Original';

  @override
  String get confirm_finish_message => '¿Marcar este libro como terminado?';

  @override
  String get confirm_mark_read_message => '¿Marcar este libro como leído?';

  @override
  String error_deleting_book(Object error) {
    return 'Error al eliminar libro: $error';
  }

  @override
  String get refresh_metadata => 'Actualizar metadatos';

  @override
  String get tbr_list_subtitle => 'Este libro está en tu lista TBR';

  @override
  String get open_library => 'Open Library';

  @override
  String get google_books => 'Google Books';

  @override
  String get error_loading_bundle_books => 'Error al cargar libros del paquete';

  @override
  String get no_books_in_bundle => 'No hay libros en el paquete';

  @override
  String get no_status => 'Sin estado';

  @override
  String get created_label => 'Creado';

  @override
  String get bundle_timed_reading_sessions => 'Sesiones Cronometradas del Paquete';

  @override
  String get tbr_label => 'Por Leer';

  @override
  String get release_notification => 'Notificación de Lanzamiento';

  @override
  String scheduled_for(Object date) {
    return 'Programado para $date';
  }

  @override
  String get my_rating_label => 'Mi Calificación';

  @override
  String get fetching_description => 'Obteniendo descripción...';

  @override
  String total_reading_time(Object hours) {
    return 'Tiempo total de lectura: $hours horas';
  }

  @override
  String get finish_book => 'Terminar Libro';

  @override
  String get rating_breakdown => 'Desglose de Calificación';

  @override
  String get manual_rating => 'Calificación manual';

  @override
  String get auto_calculated => 'Auto-calculada';

  @override
  String get read_today_check => 'Leído hoy ✓';

  @override
  String copied_to_clipboard(Object value) {
    return 'Copiado: $value';
  }

  @override
  String get tandem_books => 'Libros en Tándem';

  @override
  String get read_together_with => 'Leer junto con estos libros';

  @override
  String get no_tandem_books => 'No hay otros libros en tándem en esta saga';

  @override
  String get rate_reading_experience => 'Califica tu experiencia de lectura:';

  @override
  String get no_rating_fields => 'No hay campos de calificación disponibles. Puedes añadirlos en Ajustes.';

  @override
  String get write_review_optional => 'Escribe una reseña (opcional):';

  @override
  String get share_your_thoughts => 'Comparte tus pensamientos...';

  @override
  String get saga_completion_setup => 'Configuración de Saga';

  @override
  String you_are_adding(Object name) {
    return 'Estás añadiendo: \"$name\"';
  }

  @override
  String get how_many_books_saga => '¿Cuántos libros debería mostrar esta saga en las estadísticas?';

  @override
  String get saga_completion_explanation => 'La tarjeta de completado de saga mostrará \"X / Y\" donde Y es el número que especifiques.';

  @override
  String get number_of_books => 'Número de libros';

  @override
  String get examples => 'Ejemplos:';

  @override
  String get value_label => 'Valor';

  @override
  String get value_added_successfully => 'Valor añadido correctamente';

  @override
  String get value_updated_successfully => 'Valor actualizado correctamente';

  @override
  String get value_deleted_successfully => 'Valor eliminado correctamente';

  @override
  String get core_status_warning => 'Estado principal: Solo cambiará la etiqueta, no el valor de la base de datos ni la lógica.';

  @override
  String get core_format_saga_warning => 'Formato saga principal: Solo se puede cambiar la etiqueta, este valor no se puede eliminar.';

  @override
  String get core_status_cannot_delete => 'Este es un valor de estado principal y no se puede eliminar. La lógica de la app depende de estos valores: Yes, No, Started, TBReleased, Abandoned, Repeated y Standby.';

  @override
  String get core_format_saga_cannot_delete => 'Este es un valor de formato saga principal y no se puede eliminar. La lógica de la app depende de estos valores: Standalone, Bilogy, Trilogy, Tetralogy, Pentalogy, Hexalogy, 6+ y Saga.';

  @override
  String get core_value_cannot_delete => 'El valor principal no se puede eliminar';

  @override
  String get select_category => 'Seleccionar Categoría';

  @override
  String value_in_use(Object value, Object count) {
    return 'El valor \"$value\" es usado por $count libro(s).';
  }

  @override
  String get what_would_you_like_to_do => '¿Qué te gustaría hacer?';

  @override
  String get replace_with_existing => 'Reemplazar con valor existente';

  @override
  String get select_replacement => 'Seleccionar reemplazo';

  @override
  String get new_value => 'Nuevo valor';

  @override
  String get delete_may_fail => 'Esto fallará si las restricciones de la base de datos lo impiden';

  @override
  String get please_select_replacement => 'Por favor selecciona un valor de reemplazo';

  @override
  String get please_enter_new_value => 'Por favor ingresa un nuevo valor';

  @override
  String get year_label => 'Año';

  @override
  String get target_books => 'Libros Objetivo';

  @override
  String get target_pages => 'Páginas Objetivo';

  @override
  String get optional => 'opcional';

  @override
  String get any_notes_about_challenge => 'Cualquier nota sobre este reto';

  @override
  String get add_custom_reading_goals => 'Añade metas de lectura personalizadas (ej., \"Leer 5 clásicos\", \"Terminar 3 series\")';

  @override
  String get no_challenges_yet => 'Aún no hay retos';

  @override
  String get create_first_challenge => '¡Crea tu primer reto de lectura!';

  @override
  String get field_name_hint => 'ej., Romance, Acción, Suspenso';

  @override
  String updated_field_name(Object oldName, Object newName) {
    return 'Actualizado \"$oldName\" a \"$newName\"';
  }

  @override
  String confirm_delete_club(Object clubName, Object count) {
    return '¿Eliminar \"$clubName\"?\n\nEsto eliminará $count libro(s) de este club.';
  }

  @override
  String book_count_label(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'libros',
      one: 'libro',
    );
    return '$count $_temp0';
  }

  @override
  String get what_would_you_like_next => '¿Qué te gustaría hacer ahora?';

  @override
  String get reading_status => 'Estado de Lectura';

  @override
  String get original_book_required => 'Libro Original (requerido para estado Repetido)';

  @override
  String get missing_required_fields => 'Campos Obligatorios Faltantes';

  @override
  String get please_fill_required_fields => 'Por favor completa los siguientes campos obligatorios:';

  @override
  String get tandem_requires_saga => 'Los libros en tándem deben tener una Saga o Universo de Saga.\n\nPor favor completa al menos uno de estos campos para marcar este libro como Tándem.';

  @override
  String get search_original_book => 'Buscar el libro original...';

  @override
  String get original_book_is_required => 'El libro original es obligatorio';

  @override
  String get asin => 'ASIN';

  @override
  String get search_or_add_author => 'Escribe para buscar o añadir autor';

  @override
  String get select_publisher => 'Seleccionar editorial';

  @override
  String get genres => 'Género(s)';

  @override
  String get search_or_add_genre => 'Escribe para buscar o añadir género';

  @override
  String get original_publication_date => 'Fecha de Publicación Original (para notificaciones)';

  @override
  String get release_date => 'Fecha de Lanzamiento';

  @override
  String get select_release_date => 'Seleccionar fecha de lanzamiento';

  @override
  String get get_notified_when_released => 'Recibe una notificación cuando se publique este libro';

  @override
  String get notification_date_time => 'Fecha y Hora de Notificación';

  @override
  String get select_notification_date => 'Seleccionar fecha y hora de notificación';

  @override
  String get book_lists => 'Listas de Libros';

  @override
  String get mark_for_reading_list => 'Marcar este libro para tu lista de lectura';

  @override
  String tbr_limit_message(Object limit) {
    return 'Has alcanzado tu límite de TBR de $limit libros.\n\nPor favor desmarca algunos libros en la pantalla Mis Libros para añadir más.';
  }

  @override
  String get mark_as_tandem => 'Marcar como Libro Tándem';

  @override
  String get tandem_description => 'Leer junto con otros libros de esta saga';

  @override
  String get reading_information_optional => 'Información de Lectura (Opcional)';

  @override
  String get rating => 'Valoración';

  @override
  String get no_ratings_yet => 'Sin valoraciones aún';

  @override
  String get average => 'Promedio';

  @override
  String get criterion => 'Criterio';

  @override
  String get general_rating => 'Valoración General';

  @override
  String get manual => 'manual';

  @override
  String get override_auto_calculation => 'Anular cálculo automático';

  @override
  String get manually_set_rating => 'Establecer la valoración general manualmente';

  @override
  String get write_your_thoughts => 'Escribe tus opiniones sobre este libro...';

  @override
  String get price => 'Precio';

  @override
  String get enter_book_price => 'Ingresa el precio del libro';

  @override
  String get add_notes_hint => 'Añade cualquier nota adicional sobre este libro...';

  @override
  String get point_camera_at_barcode => 'Apunta la cámara al código de barras';

  @override
  String get test_notification_sent => '¡Notificación de prueba enviada!';

  @override
  String get test_notification => 'Notificación de Prueba';

  @override
  String get timed_reading_sessions => 'Sesiones de Lectura Cronometradas';

  @override
  String get update_book => 'Actualizar Libro';

  @override
  String get reading_session_saved => 'Sesión de lectura guardada';

  @override
  String get stop_timer_confirm => '¿Quieres detener el temporizador de lectura?';

  @override
  String get reading_timer => 'Temporizador de Lectura';

  @override
  String get timer_exit_confirm => 'El temporizador sigue contando. ¿Estás seguro de que quieres salir sin detenerlo?';

  @override
  String get exit_label => 'Salir';

  @override
  String get stop_and_save => 'Detener y Guardar';

  @override
  String get backup_created => 'Copia de seguridad creada correctamente';

  @override
  String get restore_canceled => 'Restauración cancelada';

  @override
  String get restore_warning => 'Esto reemplazará tu base de datos actual. ¡Asegúrate de tener una copia de seguridad!';

  @override
  String get restore_database => 'Restaurar Base de Datos';

  @override
  String get restore_from_backup => 'Restaurar desde una copia anterior';

  @override
  String get backup_restored_successfully => 'Copia de seguridad restaurada correctamente';

  @override
  String get select => 'Seleccionar';

  @override
  String get session => 'Sesión';

  @override
  String book_already_in_club(Object clubName) {
    return 'El libro ya está en \"$clubName\"';
  }

  @override
  String get club_membership_updated => 'Membresía del club actualizada';

  @override
  String remove_book_from_club(Object clubName) {
    return '¿Eliminar este libro de \"$clubName\"?';
  }

  @override
  String get remove => 'Eliminar';

  @override
  String get not_in_any_clubs => 'No está en ningún club aún';

  @override
  String get bundle_description => 'Marca si este libro contiene varios libros en un volumen';

  @override
  String get eg_3 => 'ej., 3';

  @override
  String get eg_1_or_1_5 => 'ej., 1 o 1.5';

  @override
  String get eg_2020 => 'ej., 2020';

  @override
  String get map_status_values => 'Mapear Valores de Estado';

  @override
  String get match_csv_status_values => 'Asocia los valores de estado de tu CSV con los estados de la app:';

  @override
  String get leave_empty_if_not_used => 'Deja vacío si no se usa en tu CSV';

  @override
  String get continue_import => 'Continuar Importación';

  @override
  String get edit_club_membership => 'Editar Membresía del Club';

  @override
  String get add_to_reading_club => 'Añadir a Club de Lectura';

  @override
  String get enter_or_select_club_name => 'Ingresa o selecciona nombre del club';

  @override
  String get please_enter_club_name => 'Por favor ingresa un nombre de club';

  @override
  String get target_date_optional => 'Fecha Objetivo (Opcional)';

  @override
  String get select_date => 'Seleccionar fecha';

  @override
  String get reading_progress_percent => 'Progreso de Lectura (%)';

  @override
  String get please_enter_progress => 'Por favor ingresa el progreso';

  @override
  String get progress_must_be_0_100 => 'El progreso debe estar entre 0 y 100';

  @override
  String get track_reading_progress => 'Registra tu progreso de lectura para este club';

  @override
  String get how_import_books => '¿Cómo te gustaría importar tus libros?';

  @override
  String get select_or_enter_tag => 'Selecciona o ingresa una etiqueta:';

  @override
  String get available_tags => 'Etiquetas disponibles';

  @override
  String get or_enter_custom_tag => 'O ingresa una etiqueta personalizada';

  @override
  String get eg_owned_wishlist => 'ej., propio, lista de deseos';

  @override
  String get please_select_or_enter_tag => 'Por favor selecciona o ingresa una etiqueta';

  @override
  String get import_label => 'Importar';

  @override
  String get add_books_to => 'Añadir Libros a';

  @override
  String books_selected(Object count) {
    return '$count libro(s) seleccionado(s)';
  }

  @override
  String get search_for_books_to_add => 'Buscar libros para añadir';

  @override
  String get unknown => 'Desconocido';

  @override
  String add_n_books(Object count) {
    return 'Añadir $count Libro(s)';
  }

  @override
  String get book => 'Libro';

  @override
  String tbr_limit_set_to(Object limit) {
    return 'Límite TBR establecido en $limit libros';
  }

  @override
  String get all_label => 'Todos';

  @override
  String get read_label => 'Leídos';

  @override
  String get based_on_publication_year => 'Basado en el año de publicación original';

  @override
  String get create_challenge => 'Crear Desafío';

  @override
  String get seasonal_reading_patterns => 'Patrones de Lectura Estacional';

  @override
  String avg_books_per_season(Object count) {
    return 'Promedio: $count libros por temporada';
  }

  @override
  String get most => 'Más';

  @override
  String get least => 'Menos';

  @override
  String get per_year => 'por año';

  @override
  String get seasonal_reading_preferences => 'Preferencias de Lectura Estacional';

  @override
  String get you_read_most_in => 'Lees más en';

  @override
  String get no_reading_data_available => 'No hay datos de lectura disponibles';

  @override
  String get reading_goals_progress => 'Progreso de Metas de Lectura';

  @override
  String get available_now => 'Disponible Ahora';

  @override
  String get set_and_track_reading_goals => 'Establece y sigue metas de lectura';

  @override
  String get annual_book_page_challenges => 'Desafíos anuales de libros y páginas';

  @override
  String get tap_to_manage_challenges => 'Toca para gestionar desafíos';

  @override
  String get reading_efficiency_score => 'Puntuación de Eficiencia de Lectura';

  @override
  String get books_faster_than_average => 'de libros leídos más rápido que tu ritmo promedio';

  @override
  String get what_does_this_mean => '¿Qué significa esto?';

  @override
  String get efficiency_explanation => 'Esto compara la velocidad de lectura de cada libro con tu promedio general. Porcentajes más altos significan que lees consistentemente a tu ritmo típico o por encima.';

  @override
  String based_on_n_books(Object count) {
    return 'Basado en $count libros con datos completos';
  }

  @override
  String get average_rating => 'Calificación Promedio';

  @override
  String based_on_rated_books(Object count) {
    return 'Basado en $count libros calificados';
  }

  @override
  String get monthly_reading_heatmap => 'Mapa de Calor de Lectura Mensual';

  @override
  String get books_finished_per_month => 'Libros terminados por mes';

  @override
  String get less => 'Menos';

  @override
  String get more => 'Más';

  @override
  String get reading_insights => 'Perspectivas de Lectura';

  @override
  String get reading_streaks => 'Rachas de Lectura';

  @override
  String get days => 'días';

  @override
  String get best => 'Mejor';

  @override
  String get re_reads => 'Relecturas';

  @override
  String get series_vs_standalone => 'Series vs Independientes';

  @override
  String get series => 'series';

  @override
  String get standalone => 'independientes';

  @override
  String get personal_bests => 'Récords Personales';

  @override
  String get most_in_month => 'Más en un mes';

  @override
  String get fastest => 'Más rápido';

  @override
  String get next_milestone_owned => 'Próximo Hito (Libros Propios)';

  @override
  String get to_go => 'restantes';

  @override
  String get next_milestone_read => 'Próximo Hito (Libros Leídos)';

  @override
  String get binge_reading_series => 'Lectura Maratón (Series)';

  @override
  String get binge_reading_description => 'de libros terminados en 14 días del anterior';

  @override
  String get best_past_books => 'Mejores Libros Pasados';

  @override
  String get reading_goals_progress_title => 'Progreso de Metas de Lectura';

  @override
  String no_challenge_set_for_year(Object year) {
    return 'Sin desafío establecido para $year';
  }

  @override
  String get reading_goals => 'Metas de Lectura';

  @override
  String get dnf_rate => 'Tasa de Abandono';

  @override
  String get books_by_rating_distribution => 'Libros por Distribución de Calificación';

  @override
  String get page_count_distribution => 'Distribución por Número de Páginas';

  @override
  String get book_extremes => 'Extremos de Libros';

  @override
  String get oldest => 'Más Antiguo';

  @override
  String get newest => 'Más Reciente';

  @override
  String get shortest => 'Más Corto';

  @override
  String get longest => 'Más Largo';

  @override
  String no_books_read_in_year(Object year) {
    return 'Sin libros leídos en $year';
  }

  @override
  String and_n_more(Object count) {
    return 'y $count más';
  }

  @override
  String get reading_time_of_day => 'Hora de Lectura del Día';

  @override
  String get coming_soon => 'Próximamente';

  @override
  String get track_when_you_read_most => 'Registra cuándo lees más';

  @override
  String get morning_afternoon_night_owl => '¿Mañana, tarde o noctámbulo?';

  @override
  String get requires_chronometer => 'Requiere función de cronómetro';

  @override
  String get saga_completion_rate => 'Tasa de Completado de Sagas';

  @override
  String get completed => 'Completadas';

  @override
  String get in_progress => 'En Progreso';

  @override
  String get not_started => 'Sin Empezar';

  @override
  String get my_books => 'Mis Libros';

  @override
  String get no_re_read_books_yet => 'Aún no hay libros releídos';

  @override
  String read_n_times(Object count) {
    return 'Leído $count veces';
  }

  @override
  String get decade => 'Década';

  @override
  String get past_years_competitions => 'Competiciones de Años Anteriores';

  @override
  String get no_past_competitions_found => 'No se encontraron competiciones anteriores';

  @override
  String get no_winner_set => 'Sin ganador establecido';

  @override
  String get no_books_for_author => 'No se encontraron libros de este autor';

  @override
  String added_books_to_saga(Object count, Object type) {
    return 'Añadidos $count libro(s) a $type';
  }

  @override
  String no_books_in_saga(Object type) {
    return 'No se encontraron libros en esta $type';
  }

  @override
  String get no_completed_sagas => 'Aún no hay sagas completadas';

  @override
  String get no_sagas_in_progress => 'No hay sagas en progreso';

  @override
  String get no_unstarted_sagas => 'No hay sagas sin empezar';

  @override
  String get complete_label => 'completado';

  @override
  String get year => 'Año';

  @override
  String get no_books_in_year => 'Sin libros leídos este año';

  @override
  String get year_winner => 'Ganador del Año';

  @override
  String get final_round => 'Final';

  @override
  String get please_select_book => 'Por favor selecciona un libro';

  @override
  String select_winner_title(Object period) {
    return 'Seleccionar Ganador de $period';
  }

  @override
  String selected_as_winner(Object name) {
    return '¡$name seleccionado como ganador!';
  }

  @override
  String get no_monthly_winners_quarter => 'Sin ganadores mensuales para este trimestre';

  @override
  String get no_quarterly_winners => 'Sin ganadores trimestrales disponibles';

  @override
  String get no_semifinal_winners => 'Sin ganadores de semifinal disponibles';

  @override
  String select_yearly_winner(Object year) {
    return 'Seleccionar Ganador Anual de $year';
  }

  @override
  String get semifinal => 'Semifinal';

  @override
  String get no_books_currently_reading => 'No hay libros leyendo actualmente';

  @override
  String get no_books_on_standby => 'No hay libros en espera';

  @override
  String get reading_label => 'Leyendo';

  @override
  String get standby_label => 'En espera';

  @override
  String get tbr_title => 'Por Leer (TBR)';

  @override
  String get no_books_in_tbr => 'No hay libros en TBR';

  @override
  String get add_books_to_clubs => 'Añade libros a clubs desde los detalles del libro';

  @override
  String get clubs => 'Clubs';

  @override
  String get random_book_picker => 'Selector de Libro Aleatorio';

  @override
  String get random_book_description => 'Aplica filtros y obtén una sugerencia aleatoria';

  @override
  String get and_all_genres => 'Y: debe tener todos los géneros seleccionados';

  @override
  String get or_any_genre => 'O: coincide con cualquier género seleccionado';

  @override
  String get and_not_practical => 'Y: no práctico (un libro tiene un estado)';

  @override
  String get or_any_status => 'O: coincide con cualquier estado seleccionado';

  @override
  String get tbr_filter_label => 'TBR (Por Leer)';

  @override
  String get yes_in_tbr => 'Sí - En TBR';

  @override
  String get no_not_in_tbr => 'No - No en TBR';

  @override
  String get publication_year_decade => 'Año de Publicación (por década)';

  @override
  String get or_select_specific_books => 'O selecciona libros específicos';

  @override
  String get search_select_books_description => 'Busca y selecciona libros por título para elegir aleatoriamente de tu lista personalizada';

  @override
  String get select_books => 'Seleccionar Libros';

  @override
  String get type_to_search_books => 'Escribe para buscar libros por título';

  @override
  String random_from_selected(Object count) {
    return 'Aleatorio de Seleccionados ($count)';
  }

  @override
  String get try_another => 'Probar Otro';

  @override
  String get tap_to_view_details => 'Toca la tarjeta para ver detalles';

  @override
  String get migration_completed_errors => 'Migración Completada con Errores';

  @override
  String get about_bundle_migration => 'Sobre la Migración de Bundles';

  @override
  String get current_status => 'Estado Actual';

  @override
  String get old_style_bundles => 'Bundles estilo antiguo';

  @override
  String get new_style_bundles => 'Bundles estilo nuevo';

  @override
  String get individual_bundle_books => 'Libros individuales de bundles';

  @override
  String get migrating => 'Migrando...';

  @override
  String migrate_n_bundles(Object count) {
    return 'Migrar $count Bundles';
  }

  @override
  String get no_migration_needed => '¡Todos los bundles usan el nuevo sistema!\nNo se necesita migración.';

  @override
  String get last_migration_result => 'Último Resultado de Migración';

  @override
  String get resume_import => '¿Reanudar Importación?';

  @override
  String get start_fresh => 'Empezar de Nuevo';

  @override
  String get import_all => 'Importar Todo';

  @override
  String get no_csv_file_selected => 'Ningún archivo CSV seleccionado';

  @override
  String get clear_reviewed_books => '¿Limpiar Libros Revisados?';

  @override
  String get clear_reviewed_books_description => 'Esto limpiará todos los libros revisados de todas las sesiones de importación. Usa esto si el conteo parece incorrecto.';

  @override
  String get cleared_reviewed_books => 'Se limpiaron todos los libros revisados';

  @override
  String get clear_reviewed_books_cache => 'Limpiar Caché de Libros Revisados';

  @override
  String book_x_of_y(Object current, Object total) {
    return 'Libro $current de $total';
  }

  @override
  String n_to_import(Object count) {
    return '$count por importar';
  }

  @override
  String get import_up_to_here => 'Importar Hasta Aquí';

  @override
  String get ignore => 'Ignorar';

  @override
  String get next_label => 'Siguiente';

  @override
  String get import_this_book => 'Importar este libro';

  @override
  String get storage_permission_needed => 'Se necesita permiso de almacenamiento para crear copias de seguridad. ¿Deseas conceder el permiso?';

  @override
  String get import_error => 'Error de Importación';

  @override
  String get cloud_sync => 'Sincronización en la Nube';

  @override
  String get cloud_sync_subtitle => 'Copia de seguridad y restauración con Google';

  @override
  String get sign_in_with_google => 'Iniciar sesión con Google';

  @override
  String get sign_out => 'Cerrar Sesión';

  @override
  String signed_in_as(Object email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get backup_to_cloud => 'Copia de Seguridad en la Nube';

  @override
  String get restore_from_cloud => 'Restaurar desde la Nube';

  @override
  String get upload_your_library => 'Sube tu biblioteca a Google Cloud';

  @override
  String get download_your_library => 'Descarga tu biblioteca desde Google Cloud';

  @override
  String last_cloud_backup(Object date) {
    return 'Última copia en la nube: $date';
  }

  @override
  String get no_cloud_backup => 'No se encontró copia en la nube';

  @override
  String get cloud_backup_success => 'Copia de seguridad subida correctamente';

  @override
  String get cloud_restore_success => 'Biblioteca restaurada desde la nube';

  @override
  String get cloud_restore_warning => 'Esto reemplazará TODOS tus datos actuales con la copia de la nube. No se puede deshacer.';

  @override
  String get cloud_backup_in_progress => 'Subiendo copia de seguridad...';

  @override
  String get cloud_restore_in_progress => 'Descargando copia de seguridad...';

  @override
  String get sign_in_required => 'Inicia sesión para usar la copia en la nube';

  @override
  String get sign_in_failed => 'Error al iniciar sesión';

  @override
  String get no_internet => 'Sin conexión a internet';

  @override
  String cloud_backup_books(Object count) {
    return '$count libros';
  }

  @override
  String get reading_reminders => 'Recordatorios de Lectura';

  @override
  String get reading_reminders_subtitle => 'Notificaciones diarias para seguir tu lectura';

  @override
  String get enable_reading_reminders => 'Activar Recordatorios de Lectura';

  @override
  String get enable_reading_reminders_subtitle => 'Recibe una notificación diaria preguntando si has leído hoy';

  @override
  String get reminder_time => 'Hora del Recordatorio';

  @override
  String get reminder_time_subtitle => 'Hora para recibir la notificación diaria';

  @override
  String get reminder_books_option => 'Qué Libros Recordar';

  @override
  String get reminder_all_started => 'Todos los libros iniciados';

  @override
  String get reminder_last_started => 'Solo el último libro iniciado';

  @override
  String get reminder_all_started_subtitle => 'Una notificación por libro con estado Iniciado';

  @override
  String get reminder_last_started_subtitle => 'Solo el libro iniciado más recientemente';

  @override
  String get have_you_read_today => '¿Has leído hoy?';

  @override
  String have_you_read_today_book(Object bookTitle) {
    return '¿Has leído hoy?: $bookTitle';
  }

  @override
  String get tap_to_open_book => 'Toca para ver los detalles del libro';

  @override
  String get reading_reminder_enabled => 'Recordatorios de lectura activados';

  @override
  String get reading_reminder_disabled => 'Recordatorios de lectura desactivados';

  @override
  String get no_started_books_for_reminder => 'No hay libros con estado Iniciado para recordar';

  @override
  String get fetch_book_info => 'Buscar información del libro';

  @override
  String get fetching_book_info => 'Buscando información del libro...';

  @override
  String get book_info_found => 'Información encontrada y campos rellenados';

  @override
  String get no_book_info_found => 'No se encontró información para este ISBN';

  @override
  String get isbn_required_for_fetch => 'Introduce un ISBN primero';

  @override
  String get section_reading_activity => 'Actividad de Lectura';

  @override
  String get section_library_breakdown => 'Desglose de Biblioteca';

  @override
  String get section_top_rankings => 'Rankings';

  @override
  String get section_ratings_pages => 'Valoraciones y Páginas';

  @override
  String get section_sagas_series => 'Sagas y Series';

  @override
  String get section_reading_patterns => 'Patrones e Insights de Lectura';

  @override
  String get section_coming_soon => 'Próximamente';

  @override
  String get section_best_book_champions => 'Mejores Libros del Año';

  @override
  String get quick_stat_total_owned => 'Total';

  @override
  String get quick_stat_total_read => 'Leídos';

  @override
  String get quick_stat_this_year => 'Este Año';

  @override
  String get quick_stat_avg_rating => 'Media';

  @override
  String get quick_stat_streak => 'Racha';

  @override
  String get quick_stat_best_streak => 'Mejor Racha';

  @override
  String get quick_stat_velocity => 'Velocidad';

  @override
  String get quick_stat_avg_days => 'Media Días';

  @override
  String get quick_stat_books_year => 'Libros/Año';

  @override
  String get quick_stat_dnf => 'DNF';

  @override
  String get quick_stat_rereads => 'Relecturas';

  @override
  String get quick_stat_series => 'Series';

  @override
  String get quick_stat_sagas_done => 'Sagas';

  @override
  String get quick_stat_milestone_owned => 'Meta Total';

  @override
  String get quick_stat_milestone_read => 'Meta Lectura';

  @override
  String get quick_stat_choose => 'Elige una estadística';

  @override
  String get quick_stat_long_press_hint => 'Mantén pulsado para cambiar';

  @override
  String get no_data_available => 'No hay datos disponibles';

  @override
  String get books_read_per_year => 'Libros Leídos por Año';

  @override
  String get pages_read_per_year => 'Páginas Leídas por Año';

  @override
  String get reading_efficiency => 'Eficiencia de Lectura';

  @override
  String get reading_velocity => 'Velocidad de Lectura';

  @override
  String get avg_days_to_finish => 'Media de Días para Terminar';

  @override
  String get avg_books_per_year => 'Media de Libros por Año';

  @override
  String get books_by_place => 'Libros por Lugar';

  @override
  String get format_by_language => 'Formato por Idioma';

  @override
  String get daily_reading_heatmap => 'Días leídos en un año';

  @override
  String days_read_summary(Object days, Object total, Object percent) {
    return 'Leídos $days días de $total ($percent%)';
  }

  @override
  String get quick_stat_days_read => 'Días Leídos';

  @override
  String get show_price_statistics => 'Mostrar Estadísticas de Precios';

  @override
  String get show_price_statistics_subtitle => 'Mostrar una sección de estadísticas de precios en tu panel de estadísticas';

  @override
  String get currency_setting => 'Símbolo de Moneda';

  @override
  String get currency_setting_subtitle => 'Elige qué símbolo de moneda mostrar para los precios';

  @override
  String get custom_currency_hint => 'Símbolo personalizado';

  @override
  String get no_price_data => 'Aún no hay libros con datos de precio. Añade precios a tus libros para ver estadísticas.';

  @override
  String get section_price_statistics => 'Estadísticas de Precios';

  @override
  String get price_by_format => 'Precio Medio por Formato';

  @override
  String get price_by_year => 'Gasto por Año';

  @override
  String get price_by_month => 'Gasto por Mes';

  @override
  String get price_extremes => 'Destacados de Precios';

  @override
  String get total_spent => 'Total Gastado';

  @override
  String get most_expensive => 'Más Caro';

  @override
  String get least_expensive => 'Más Barato';

  @override
  String get price_range_evolution => 'Evolución de Rangos de Precio';

  @override
  String get time_slot_morning => 'Mañana';

  @override
  String get time_slot_afternoon => 'Tarde';

  @override
  String get time_slot_night => 'Noche';

  @override
  String get time_slot_late_night => 'Madrugada';

  @override
  String get no_session_data => 'Aún no hay datos de sesiones de lectura. Usa el cronómetro para registrar tus sesiones.';

  @override
  String favorite_reading_time(Object slot) {
    return 'Favorito: $slot';
  }
}
