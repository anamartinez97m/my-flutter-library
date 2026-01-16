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
  String get status => 'Estado';

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
  String get import_from_csv_hint => 'Columnas esperadas: read, title, author, publisher, genre, saga, n_saga, format_saga, isbn13, number of pages, original publication year, language, place, binding, loaned';

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
  String get year => 'Año';

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
  String get add => 'Agregar';

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
}
