import 'package:flutter/material.dart';

/// 言語設定を管理するサービス
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  // 現在の言語コード (デフォルト: 日本語)
  String _currentLanguage = 'ja';
  
  String get currentLanguage => _currentLanguage;
  
  /// サポートされている言語
  static const Map<String, Map<String, String>> supportedLanguages = {
    'ja': {'name': '日本語', 'flag': '🇯🇵'},
    'en': {'name': 'English', 'flag': '🇺🇸'},
    'zh': {'name': '中文', 'flag': '🇨🇳'},
    'es': {'name': 'Español', 'flag': '🇪🇸'},
  };
  
  /// 言語を変更
  void changeLanguage(String languageCode) {
    if (supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }
  
  /// 翻訳テキストを取得
  String translate(String key) {
    return translations[key]?[_currentLanguage] ?? key;
  }
  
  /// 完全翻訳テーブル
  static const Map<String, Map<String, String>> translations = {
    // ============ 共通 ============
    'save': {'ja': '保存', 'en': 'Save', 'zh': '保存', 'es': 'Guardar'},
    'delete': {'ja': '削除', 'en': 'Delete', 'zh': '删除', 'es': 'Eliminar'},
    'edit': {'ja': '編集', 'en': 'Edit', 'zh': '编辑', 'es': 'Editar'},
    'add': {'ja': '追加', 'en': 'Add', 'zh': '添加', 'es': 'Añadir'},
    'submit': {'ja': '送信', 'en': 'Submit', 'zh': '提交', 'es': 'Enviar'},
    'back': {'ja': '戻る', 'en': 'Back', 'zh': '返回', 'es': 'Volver'},
    'next': {'ja': '次へ', 'en': 'Next', 'zh': '下一步', 'es': 'Siguiente'},
    'confirm': {'ja': '確認', 'en': 'Confirm', 'zh': '确认', 'es': 'Confirmar'},
    'cancel': {'ja': 'キャンセル', 'en': 'Cancel', 'zh': '取消', 'es': 'Cancelar'},
    'close': {'ja': '閉じる', 'en': 'Close', 'zh': '关闭', 'es': 'Cerrar'},
    'login': {'ja': 'ログイン', 'en': 'Login', 'zh': '登录', 'es': 'Iniciar sesión'},
    'logout': {'ja': 'ログアウト', 'en': 'Logout', 'zh': '退出登录', 'es': 'Cerrar sesión'},
    'yes': {'ja': 'はい', 'en': 'Yes', 'zh': '是', 'es': 'Sí'},
    'no': {'ja': 'いいえ', 'en': 'No', 'zh': '否', 'es': 'No'},
    'search': {'ja': '検索', 'en': 'Search', 'zh': '搜索', 'es': 'Buscar'},
    'filter': {'ja': 'フィルタ', 'en': 'Filter', 'zh': '筛选', 'es': 'Filtrar'},
    'clear': {'ja': 'クリア', 'en': 'Clear', 'zh': '清除', 'es': 'Limpiar'},
    'required': {'ja': '必須', 'en': 'Required', 'zh': '必填', 'es': 'Requerido'},
    'optional': {'ja': '任意', 'en': 'Optional', 'zh': '可选', 'es': 'Opcional'},
    'loading': {'ja': '読み込み中...', 'en': 'Loading...', 'zh': '加载中...', 'es': 'Cargando...'},
    'error': {'ja': 'エラー', 'en': 'Error', 'zh': '错误', 'es': 'Error'},
    'success': {'ja': '成功', 'en': 'Success', 'zh': '成功', 'es': 'Éxito'},
    'update': {'ja': '更新', 'en': 'Update', 'zh': '更新', 'es': 'Actualizar'},
    'complete': {'ja': '完了', 'en': 'Complete', 'zh': '完成', 'es': 'Completar'},
    'print': {'ja': '印刷', 'en': 'Print', 'zh': '打印', 'es': 'Imprimir'},
    'download': {'ja': 'ダウンロード', 'en': 'Download', 'zh': '下载', 'es': 'Descargar'},
    
    // ============ 患者アクセス画面 ============
    'patient_access_title': {'ja': '患者情報入力', 'en': 'Patient Information', 'zh': '患者信息输入', 'es': 'Información del paciente'},
    'facility_code': {'ja': '施設コード', 'en': 'Facility Code', 'zh': '设施代码', 'es': 'Código de instalación'},
    'facility_code_hint': {'ja': '6桁の施設コード', 'en': '6-digit facility code', 'zh': '6位设施代码', 'es': 'Código de 6 dígitos'},
    'patient_id': {'ja': '患者ID', 'en': 'Patient ID', 'zh': '患者ID', 'es': 'ID del paciente'},
    'patient_id_hint': {'ja': '例: P12345', 'en': 'e.g. P12345', 'zh': '例如：P12345', 'es': 'ej. P12345'},
    'patient_name': {'ja': '患者氏名', 'en': 'Patient Name', 'zh': '患者姓名', 'es': 'Nombre del paciente'},
    'patient_name_hint': {'ja': '例: 山田太郎', 'en': 'e.g. John Doe', 'zh': '例如：张三', 'es': 'ej. Juan Pérez'},
    'start_questionnaire': {'ja': '問診を開始', 'en': 'Start Questionnaire', 'zh': '开始问卷', 'es': 'Iniciar cuestionario'},
    'facility_not_found': {'ja': '施設が見つかりません', 'en': 'Facility not found', 'zh': '未找到设施', 'es': 'Instalación no encontrada'},
    'please_enter_all_fields': {'ja': 'すべての項目を入力してください', 'en': 'Please enter all fields', 'zh': '请填写所有项目', 'es': 'Por favor complete todos los campos'},
    'exit_confirmation': {'ja': '入力を中断しますか？', 'en': 'Exit input?', 'zh': '退出输入？', 'es': '¿Salir de la entrada?'},
    'data_will_not_be_saved': {'ja': '入力された患者情報は保存されません。\n本当に戻りますか？', 'en': 'Patient information will not be saved.\nReally go back?', 'zh': '患者信息将不会保存。\n真的要返回吗？', 'es': 'La información del paciente no se guardará.\n¿Realmente volver?'},
    'input_not_saved': {'ja': '入力中の内容は保存されません。\n本当に戻りますか？', 'en': 'Input will not be saved.\nReally go back?', 'zh': '输入内容将不会保存。\n真的要返回吗？', 'es': 'La entrada no se guardará.\n¿Realmente volver?'},
    'next_to_questionnaire': {'ja': '次へ（問診票選択）', 'en': 'Next (Select Questionnaire)', 'zh': '下一步（选择问卷）', 'es': 'Siguiente (Seleccionar cuestionario)'},
    
    // ============ 問診票選択画面 ============
    'questionnaire_selection_title': {'ja': '問診票を選択', 'en': 'Select Questionnaire', 'zh': '选择问卷', 'es': 'Seleccionar cuestionario'},
    'select_questionnaire_message': {'ja': '回答する問診票を選択してください', 'en': 'Please select a questionnaire to answer', 'zh': '请选择要回答的问卷', 'es': 'Por favor seleccione un cuestionario'},
    'questionnaire_selection': {'ja': '問診票選択', 'en': 'Questionnaire Selection', 'zh': '问卷选择', 'es': 'Selección de cuestionario'},
    'individual_answer_note': {'ja': '各問診票は個別に回答できます', 'en': 'Each questionnaire can be answered individually', 'zh': '每份问卷可以单独回答', 'es': 'Cada cuestionario se puede responder individualmente'},
    'sections': {'ja': 'セクション', 'en': 'sections', 'zh': '部分', 'es': 'secciones'},
    'submitted': {'ja': '送信済み', 'en': 'Submitted', 'zh': '已提交', 'es': 'Enviado'},
    'already_submitted': {'ja': 'この問診票は既に送信済みです', 'en': 'This questionnaire has already been submitted', 'zh': '此问卷已提交', 'es': 'Este cuestionario ya ha sido enviado'},
    'no_questionnaires': {'ja': '問診票がありません', 'en': 'No questionnaires available', 'zh': '没有问卷', 'es': 'No hay cuestionarios'},
    'questionnaire_not_found': {'ja': '問診票が見つかりません', 'en': 'Questionnaire not found', 'zh': '未找到问卷', 'es': 'Cuestionario no encontrado'},
    'loading_questionnaires': {'ja': '問診票を読み込み中...', 'en': 'Loading questionnaires...', 'zh': '加载问卷中...', 'es': 'Cargando cuestionarios...'},
    'back_to_selection': {'ja': '問診票選択に戻る', 'en': 'Back to selection', 'zh': '返回选择', 'es': 'Volver a la selección'},
    
    // ============ 問診票回答画面 ============
    'questionnaire_title': {'ja': '問診票', 'en': 'Questionnaire', 'zh': '问卷', 'es': 'Cuestionario'},
    'section': {'ja': 'セクション', 'en': 'Section', 'zh': '部分', 'es': 'Sección'},
    'question': {'ja': '質問', 'en': 'Question', 'zh': '问题', 'es': 'Pregunta'},
    'please_answer': {'ja': '回答してください', 'en': 'Please answer', 'zh': '请回答', 'es': 'Por favor responda'},
    'detail_input': {'ja': '詳細を入力', 'en': 'Enter details', 'zh': '输入详细信息', 'es': 'Ingrese detalles'},
    'detail_input_label': {'ja': '詳細入力', 'en': 'Detail Input', 'zh': '详细输入', 'es': 'Entrada detallada'},
    'free_text_input': {'ja': '自由に記入してください', 'en': 'Please write freely', 'zh': '请自由填写', 'es': 'Por favor escriba libremente'},
    'weight_kg': {'ja': '体重（kg）', 'en': 'Weight (kg)', 'zh': '体重（公斤）', 'es': 'Peso (kg)'},
    'consent_required': {'ja': '同意が必要です', 'en': 'Consent required', 'zh': '需要同意', 'es': 'Se requiere consentimiento'},
    'submit_confirmation': {'ja': '送信確認', 'en': 'Confirm Submission', 'zh': '确认提交', 'es': 'Confirmar envío'},
    'submit_confirmation_message': {'ja': 'この内容で送信してもよろしいですか？', 'en': 'Are you sure you want to submit?', 'zh': '确定要提交吗？', 'es': '¿Está seguro de que desea enviar?'},
    'submit_success': {'ja': '送信完了', 'en': 'Submitted Successfully', 'zh': '提交成功', 'es': 'Enviado con éxito'},
    'submit_success_message': {'ja': 'ご回答ありがとうございました。\n医療スタッフが確認いたします。', 'en': 'Thank you for your response.\nMedical staff will review it.', 'zh': '感谢您的回答。\n医务人员将进行审核。', 'es': 'Gracias por su respuesta.\nEl personal médico lo revisará.'},
    'answer_all_questions': {'ja': 'すべての質問に回答してください', 'en': 'Please answer all questions', 'zh': '请回答所有问题', 'es': 'Por favor responda todas las preguntas'},
    'interrupt_questionnaire': {'ja': '問診票を中断しますか？', 'en': 'Interrupt questionnaire?', 'zh': '中断问卷？', 'es': '¿Interrumpir cuestionario?'},
    'interrupt_answer': {'ja': '問診票回答を中断しますか？', 'en': 'Interrupt questionnaire response?', 'zh': '中断问卷回答？', 'es': '¿Interrumpir respuesta del cuestionario?'},
    'yes_answer_detail': {'ja': '「はい」を選択した場合、詳細を記入できます', 'en': 'If you select "Yes", you can enter details', 'zh': '如果选择"是"，可以输入详细信息', 'es': 'Si selecciona "Sí", puede ingresar detalles'},
    'show_detail_on_yes': {'ja': 'Yes選択時に詳細入力欄を表示', 'en': 'Show detail input on Yes', 'zh': '"是"时显示详细输入', 'es': 'Mostrar entrada de detalle en Sí'},
    
    // ============ 管理者ログイン画面 ============
    'admin_login_title': {'ja': '医療従事者ログイン', 'en': 'Healthcare Staff Login', 'zh': '医务人员登录', 'es': 'Inicio de sesión del personal médico'},
    'email': {'ja': 'メールアドレス', 'en': 'Email', 'zh': '电子邮件', 'es': 'Correo electrónico'},
    'email_hint': {'ja': 'admin@example.com', 'en': 'admin@example.com', 'zh': 'admin@example.com', 'es': 'admin@example.com'},
    'password': {'ja': 'パスワード', 'en': 'Password', 'zh': '密码', 'es': 'Contraseña'},
    'password_hint': {'ja': '6文字以上', 'en': '6+ characters', 'zh': '6个字符以上', 'es': '6+ caracteres'},
    'login_failed': {'ja': 'ログインに失敗しました', 'en': 'Login failed', 'zh': '登录失败', 'es': 'Error de inicio de sesión'},
    'invalid_email_password': {'ja': 'メールアドレスまたはパスワードが正しくありません', 'en': 'Invalid email or password', 'zh': '电子邮件或密码不正确', 'es': 'Correo o contraseña incorrectos'},
    'facility_registration': {'ja': '医療機関 新規登録', 'en': 'New Facility Registration', 'zh': '医疗机构新注册', 'es': 'Nuevo registro de instalación'},
    'register_and_start': {'ja': '登録して開始', 'en': 'Register and Start', 'zh': '注册并开始', 'es': 'Registrar e iniciar'},
    'already_have_account': {'ja': '既にアカウントをお持ちの方はこちら', 'en': 'Already have an account? Click here', 'zh': '已有账户？点击这里', 'es': '¿Ya tiene una cuenta? Haga clic aquí'},
    'to_admin_screen': {'ja': '管理画面へ', 'en': 'To Admin Screen', 'zh': '前往管理界面', 'es': 'Ir a la pantalla de administración'},
    'registration_complete': {'ja': '登録完了', 'en': 'Registration Complete', 'zh': '注册完成', 'es': 'Registro completado'},
    
    // ============ 管理者メニュー画面 ============
    'admin_menu_title': {'ja': '管理メニュー', 'en': 'Admin Menu', 'zh': '管理菜单', 'es': 'Menú de administración'},
    'response_list': {'ja': '回答一覧', 'en': 'Response List', 'zh': '回答列表', 'es': 'Lista de respuestas'},
    'view_patient_responses': {'ja': '患者の回答を確認', 'en': 'View patient responses', 'zh': '查看患者回答', 'es': 'Ver respuestas de pacientes'},
    'questionnaire_management': {'ja': '問診票管理', 'en': 'Questionnaire Management', 'zh': '问卷管理', 'es': 'Gestión de cuestionarios'},
    'create_edit_questionnaires': {'ja': '問診票の作成・編集', 'en': 'Create and edit questionnaires', 'zh': '创建和编辑问卷', 'es': 'Crear y editar cuestionarios'},
    'facility_info': {'ja': '施設情報', 'en': 'Facility Information', 'zh': '设施信息', 'es': 'Información de instalación'},
    'view_facility_settings': {'ja': '施設情報の確認', 'en': 'View facility settings', 'zh': '查看设施设置', 'es': 'Ver configuración de instalación'},
    'prioritize_important': {'ja': '注意が必要な回答を優先的に確認', 'en': 'Prioritize important responses', 'zh': '优先确认重要回答', 'es': 'Priorizar respuestas importantes'},
    
    // ============ 回答一覧画面 ============
    'search_by_name_or_id': {'ja': '患者氏名またはIDで検索', 'en': 'Search by name or ID', 'zh': '按姓名或ID搜索', 'es': 'Buscar por nombre o ID'},
    'start_date': {'ja': '開始日', 'en': 'Start Date', 'zh': '开始日期', 'es': 'Fecha de inicio'},
    'end_date': {'ja': '終了日', 'en': 'End Date', 'zh': '结束日期', 'es': 'Fecha de fin'},
    'today': {'ja': '当日', 'en': 'Today', 'zh': '今天', 'es': 'Hoy'},
    'past_week': {'ja': '過去1週間', 'en': 'Past Week', 'zh': '过去一周', 'es': 'Última semana'},
    'past_month': {'ja': '過去1ヶ月', 'en': 'Past Month', 'zh': '过去一个月', 'es': 'Último mes'},
    'show_only_yes_answers': {'ja': 'Yes回答がある回答のみ表示', 'en': 'Show only with Yes answers', 'zh': '仅显示有"是"回答', 'es': 'Mostrar solo con respuestas Sí'},
    'filter_by_questionnaire': {'ja': '問診票で絞り込み', 'en': 'Filter by questionnaire', 'zh': '按问卷筛选', 'es': 'Filtrar por cuestionario'},
    'all_questionnaires': {'ja': 'すべての問診票', 'en': 'All Questionnaires', 'zh': '所有问卷', 'es': 'Todos los cuestionarios'},
    'clear_filters': {'ja': 'フィルタをクリア', 'en': 'Clear Filters', 'zh': '清除筛选', 'es': 'Limpiar filtros'},
    'export_all_csv': {'ja': '全件CSV出力', 'en': 'Export All CSV', 'zh': '导出所有CSV', 'es': 'Exportar todo CSV'},
    'selection_mode': {'ja': '選択モード', 'en': 'Selection Mode', 'zh': '选择模式', 'es': 'Modo selección'},
    'export_csv': {'ja': 'CSV出力', 'en': 'Export CSV', 'zh': '导出CSV', 'es': 'Exportar CSV'},
    'export_pdf': {'ja': 'PDF出力', 'en': 'Export PDF', 'zh': '导出PDF', 'es': 'Exportar PDF'},
    'responses_count': {'ja': '件の回答', 'en': ' responses', 'zh': ' 条回答', 'es': ' respuestas'},
    'selected_count': {'ja': '件選択中', 'en': ' selected', 'zh': ' 已选', 'es': ' seleccionados'},
    'yes_answers': {'ja': 'Yes回答', 'en': 'Yes Answers', 'zh': '"是"回答', 'es': 'Respuestas Sí'},
    'confirmed': {'ja': '確認済', 'en': 'Confirmed', 'zh': '已确认', 'es': 'Confirmado'},
    'memo': {'ja': 'メモ', 'en': 'Memo', 'zh': '备注', 'es': 'Nota'},
    'staff_memo': {'ja': '医療従事者メモ', 'en': 'Staff Memo', 'zh': '医务人员备注', 'es': 'Nota del personal'},
    'no_responses': {'ja': '回答データがありません', 'en': 'No responses', 'zh': '没有回答数据', 'es': 'No hay respuestas'},
    'no_matching_responses': {'ja': '検索条件に一致する回答がありません', 'en': 'No matching responses', 'zh': '没有符合条件的回答', 'es': 'No hay respuestas coincidentes'},
    
    // ============ 施設情報・設定画面 ============
    'facility_name': {'ja': '施設名', 'en': 'Facility Name', 'zh': '设施名称', 'es': 'Nombre de instalación'},
    'facility_id': {'ja': '施設ID', 'en': 'Facility ID', 'zh': '设施ID', 'es': 'ID de instalación'},
    'address': {'ja': '住所', 'en': 'Address', 'zh': '地址', 'es': 'Dirección'},
    'phone': {'ja': '電話番号', 'en': 'Phone', 'zh': '电话', 'es': 'Teléfono'},
    'facility_code_for_patients': {'ja': '患者用施設コード', 'en': 'Patient Facility Code', 'zh': '患者设施代码', 'es': 'Código para pacientes'},
    'share_code_message': {'ja': 'このコードを患者さんにお伝えください', 'en': 'Share this code with patients', 'zh': '请将此代码告知患者', 'es': 'Comparta este código con los pacientes'},
    'admin_name': {'ja': '管理者名', 'en': 'Admin Name', 'zh': '管理员姓名', 'es': 'Nombre de admin'},
    'admin_email': {'ja': '管理者メール', 'en': 'Admin Email', 'zh': '管理员邮箱', 'es': 'Correo de admin'},
    'update_facility_info': {'ja': '施設情報を更新', 'en': 'Update Facility Info', 'zh': '更新设施信息', 'es': 'Actualizar info de instalación'},
    'facility_updated': {'ja': '施設情報を更新しました', 'en': 'Facility info updated', 'zh': '设施信息已更新', 'es': 'Info de instalación actualizada'},
    'facility_list': {'ja': '医療機関一覧（管理者用）', 'en': 'Facility List (Admin)', 'zh': '医疗机构列表（管理员）', 'es': 'Lista de instalaciones (Admin)'},
    
    // ============ 問診票管理画面 ============
    'questionnaires': {'ja': '問診票一覧', 'en': 'Questionnaires', 'zh': '问卷列表', 'es': 'Cuestionarios'},
    'create_new_questionnaire': {'ja': '新規作成', 'en': 'Create New', 'zh': '新建', 'es': 'Crear nuevo'},
    'no_questionnaires_created': {'ja': 'まだ問診票が作成されていません', 'en': 'No questionnaires created yet', 'zh': '尚未创建问卷', 'es': 'Aún no se han creado cuestionarios'},
    'create_first_questionnaire': {'ja': '最初の問診票を作成', 'en': 'Create first questionnaire', 'zh': '创建第一个问卷', 'es': 'Crear primer cuestionario'},
    'edit_questionnaire': {'ja': '問診票を編集', 'en': 'Edit Questionnaire', 'zh': '编辑问卷', 'es': 'Editar cuestionario'},
    'delete_questionnaire': {'ja': '問診票を削除', 'en': 'Delete Questionnaire', 'zh': '删除问卷', 'es': 'Eliminar cuestionario'},
    'delete_confirmation': {'ja': '削除確認', 'en': 'Confirm Delete', 'zh': '确认删除', 'es': 'Confirmar eliminación'},
    'delete_questionnaire_message': {'ja': 'この問診票を削除してもよろしいですか？', 'en': 'Delete this questionnaire?', 'zh': '确定要删除此问卷吗？', 'es': '¿Eliminar este cuestionario?'},
    'questionnaire_saved': {'ja': '問診票を保存しました', 'en': 'Questionnaire saved', 'zh': '问卷已保存', 'es': 'Cuestionario guardado'},
    'add_section': {'ja': 'セクション追加', 'en': 'Add Section', 'zh': '添加部分', 'es': 'Añadir sección'},
    'delete_section': {'ja': 'セクションを削除', 'en': 'Delete Section', 'zh': '删除部分', 'es': 'Eliminar sección'},
    'section_deleted': {'ja': 'セクションを削除しました', 'en': 'Section deleted', 'zh': '部分已删除', 'es': 'Sección eliminada'},
    'add_question': {'ja': '質問追加', 'en': 'Add Question', 'zh': '添加问题', 'es': 'Añadir pregunta'},
    'delete_question': {'ja': '質問を削除', 'en': 'Delete Question', 'zh': '删除问题', 'es': 'Eliminar pregunta'},
    'required_field': {'ja': '必須項目', 'en': 'Required Field', 'zh': '必填项', 'es': 'Campo obligatorio'},
    'required_answer': {'ja': '患者がこの質問に必ず回答する必要があります', 'en': 'Patient must answer this question', 'zh': '患者必须回答此问题', 'es': 'El paciente debe responder esta pregunta'},
    'show_ad': {'ja': '広告を表示', 'en': 'Show Ad', 'zh': '显示广告', 'es': 'Mostrar anuncio'},
    'edit_ad_content': {'ja': '広告内容を編集', 'en': 'Edit Ad Content', 'zh': '编辑广告内容', 'es': 'Editar contenido del anuncio'},
    
    // ============ 患者基本情報編集 ============
    'edit_patient_info': {'ja': '患者情報を編集', 'en': 'Edit Patient Info', 'zh': '编辑患者信息', 'es': 'Editar información del paciente'},
    'patient_basic_info': {'ja': '患者基本情報', 'en': 'Patient Basic Info', 'zh': '患者基本信息', 'es': 'Información básica del paciente'},
    'patient_info_updated': {'ja': '患者情報を更新しました', 'en': 'Patient info updated', 'zh': '患者信息已更新', 'es': 'Información del paciente actualizada'},
    'update_patient_info': {'ja': '患者情報を更新', 'en': 'Update Patient Info', 'zh': '更新患者信息', 'es': 'Actualizar info del paciente'},
    'enter_patient_id': {'ja': '患者IDを入力してください', 'en': 'Please enter patient ID', 'zh': '请输入患者ID', 'es': 'Por favor ingrese el ID del paciente'},
    'enter_patient_name': {'ja': '患者氏名を入力してください', 'en': 'Please enter patient name', 'zh': '请输入患者姓名', 'es': 'Por favor ingrese el nombre del paciente'},
    'enter_weight': {'ja': '体重を入力してください', 'en': 'Please enter weight', 'zh': '请输入体重', 'es': 'Por favor ingrese el peso'},
    'weight_must_be_number': {'ja': '体重は数値で入力してください', 'en': 'Weight must be a number', 'zh': '体重必须为数字', 'es': 'El peso debe ser un número'},
    'weight_must_be_positive': {'ja': '体重は0より大きい値を入力してください', 'en': 'Weight must be greater than 0', 'zh': '体重必须大于0', 'es': 'El peso debe ser mayor que 0'},
    'answer_content': {'ja': '回答内容', 'en': 'Answer Content', 'zh': '回答内容', 'es': 'Contenido de respuesta'},
    'answer': {'ja': '回答', 'en': 'Answer', 'zh': '回答', 'es': 'Respuesta'},
    'detail': {'ja': '詳細', 'en': 'Detail', 'zh': '详细', 'es': 'Detalle'},
    'submission_time': {'ja': '回答日時', 'en': 'Submission Time', 'zh': '回答时间', 'es': 'Hora de envío'},
    'edit_basic_info': {'ja': '基本情報を編集', 'en': 'Edit Basic Info', 'zh': '编辑基本信息', 'es': 'Editar información básica'},
    'basic_info_update_failed': {'ja': '基本情報の更新に失敗しました', 'en': 'Failed to update basic information', 'zh': '更新基本信息失败', 'es': 'No se pudo actualizar la información básica'},
    'edit_answer': {'ja': '回答を編集', 'en': 'Edit Answer', 'zh': '编辑回答', 'es': 'Editar respuesta'},
    'enter_answer': {'ja': '回答を入力してください', 'en': 'Please enter answer', 'zh': '请输入回答', 'es': 'Por favor ingrese respuesta'},
    'answer_updated': {'ja': '回答を更新しました', 'en': 'Answer updated', 'zh': '回答已更新', 'es': 'Respuesta actualizada'},
    'answer_update_failed': {'ja': '回答の更新に失敗しました', 'en': 'Failed to update answer', 'zh': '更新回答失败', 'es': 'No se pudo actualizar la respuesta'},
    'patient_basic_info_settings': {'ja': '患者基本情報設定', 'en': 'Patient Basic Info Settings', 'zh': '患者基本信息设置', 'es': 'Configuración de información básica del paciente'},
    'standard_fields': {'ja': '標準項目', 'en': 'Standard Fields', 'zh': '标准字段', 'es': 'Campos estándar'},
    'custom_fields': {'ja': 'カスタム項目', 'en': 'Custom Fields', 'zh': '自定义字段', 'es': 'Campos personalizados'},
    'custom_fields_description': {'ja': '患者情報に独自の項目を追加できます', 'en': 'Add custom fields to patient information', 'zh': '为患者信息添加自定义字段', 'es': 'Agregar campos personalizados a la información del paciente'},
    'add_field': {'ja': '項目を追加', 'en': 'Add Field', 'zh': '添加字段', 'es': 'Agregar campo'},
    'add_custom_field': {'ja': 'カスタム項目を追加', 'en': 'Add Custom Field', 'zh': '添加自定义字段', 'es': 'Agregar campo personalizado'},
    'edit_custom_field': {'ja': 'カスタム項目を編集', 'en': 'Edit Custom Field', 'zh': '编辑自定义字段', 'es': 'Editar campo personalizado'},
    'no_custom_fields': {'ja': 'カスタム項目はありません', 'en': 'No custom fields', 'zh': '无自定义字段', 'es': 'No hay campos personalizados'},
    'add_custom_field_hint': {'ja': '上部の「項目を追加」ボタンまたは下記のボタンから追加できます', 'en': 'Click "Add Field" button above or below to add', 'zh': '点击上方或下方的"添加字段"按钮进行添加', 'es': 'Haga clic en el botón "Agregar campo" arriba o abajo para agregar'},
    'add_first_field': {'ja': '最初の項目を追加', 'en': 'Add First Field', 'zh': '添加第一个字段', 'es': 'Agregar primer campo'},
    'field_label': {'ja': '項目名', 'en': 'Field Label', 'zh': '字段标签', 'es': 'Etiqueta del campo'},
    'field_type': {'ja': '項目タイプ', 'en': 'Field Type', 'zh': '字段类型', 'es': 'Tipo de campo'},
    'enter_field_label': {'ja': '項目名を入力してください', 'en': 'Please enter field label', 'zh': '请输入字段标签', 'es': 'Por favor ingrese etiqueta del campo'},
    'text': {'ja': 'テキスト', 'en': 'Text', 'zh': '文本', 'es': 'Texto'},
    'number': {'ja': '数値', 'en': 'Number', 'zh': '数字', 'es': 'Número'},
    'date': {'ja': '日付', 'en': 'Date', 'zh': '日期', 'es': 'Fecha'},
    'textarea': {'ja': '複数行テキスト', 'en': 'Textarea', 'zh': '多行文本', 'es': 'Área de texto'},
    'type': {'ja': 'タイプ', 'en': 'Type', 'zh': '类型', 'es': 'Tipo'},
    'settings_saved': {'ja': '設定を保存しました', 'en': 'Settings saved', 'zh': '设置已保存', 'es': 'Configuración guardada'},
    'save_failed': {'ja': '保存に失敗しました', 'en': 'Failed to save', 'zh': '保存失败', 'es': 'Error al guardar'},
    'date_of_birth': {'ja': '生年月日', 'en': 'Date of Birth', 'zh': '出生日期', 'es': 'Fecha de nacimiento'},
    'date_of_birth_hint': {'ja': '患者の生年月日', 'en': 'Patient date of birth', 'zh': '患者出生日期', 'es': 'Fecha de nacimiento del paciente'},
    'weight_hint': {'ja': '患者の体重（kg）', 'en': 'Patient weight (kg)', 'zh': '患者体重（kg）', 'es': 'Peso del paciente (kg)'},
    'config_not_found': {'ja': '設定が見つかりません', 'en': 'Configuration not found', 'zh': '未找到配置', 'es': 'Configuración no encontrada'},
    'patient_info_instruction': {'ja': '問診票回答の前に、基本的な情報をご入力ください', 'en': 'Please enter basic information before questionnaire', 'zh': '请在问卷前输入基本信息', 'es': 'Por favor ingrese información básica antes del cuestionario'},
    'name_example': {'ja': '山田太郎', 'en': 'John Smith', 'zh': '张三', 'es': 'Juan Pérez'},
    'select_date': {'ja': '日付を選択', 'en': 'Select date', 'zh': '选择日期', 'es': 'Seleccionar fecha'},
    'is_required': {'ja': 'は必須です', 'en': ' is required', 'zh': '是必填项', 'es': ' es obligatorio'},
    'must_be_number': {'ja': '数値を入力してください', 'en': 'Must be a number', 'zh': '必须为数字', 'es': 'Debe ser un número'},
    'confirm_delete': {'ja': '削除確認', 'en': 'Confirm Delete', 'zh': '确认删除', 'es': 'Confirmar eliminación'},
    'confirm_delete_custom_field': {'ja': 'このカスタム項目を削除してもよろしいですか？', 'en': 'Are you sure you want to delete this custom field?', 'zh': '确定要删除此自定义字段吗？', 'es': '¿Está seguro de que desea eliminar este campo personalizado?'},
    'enabled': {'ja': '有効', 'en': 'Enabled', 'zh': '已启用', 'es': 'Habilitado'},
    'disabled': {'ja': '無効', 'en': 'Disabled', 'zh': '已禁用', 'es': 'Deshabilitado'},
    'exit': {'ja': '終了', 'en': 'Exit', 'zh': '退出', 'es': 'Salir'},
  };
}
