extends Control

const SAVE_PATH := "user://worlds.json"
const SKIN_PATHS := ["res://assets/skins/skin_1.png", "res://assets/skins/skin_2.png"]

var worlds: Array = []
var selected_skin := 0
var selected_mode := "Hayatta Kalma"
var selected_generator := "Varsayılan"
var name_input: LineEdit
var seed_input: LineEdit
var mode_select: OptionButton
var generator_select: OptionButton
var skin_preview: TextureRect

func _ready() -> void:
    _load_worlds()
    show_main()

func clear_screen() -> void:
    for child in get_children():
        child.queue_free()

func make_screen(title_text: String) -> VBoxContainer:
    clear_screen()
    var bg := ColorRect.new()
    bg.color = Color("#172d43")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 38)
    margin.add_theme_constant_override("margin_right", 38)
    margin.add_theme_constant_override("margin_top", 26)
    margin.add_theme_constant_override("margin_bottom", 26)
    add_child(margin)

    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#79a3df")
    style.border_color = Color("#263f68")
    style.set_border_width_all(5)
    style.set_corner_radius_all(18)
    panel.add_theme_stylebox_override("panel", style)
    margin.add_child(panel)

    var inner := MarginContainer.new()
    inner.add_theme_constant_override("margin_left", 28)
    inner.add_theme_constant_override("margin_right", 28)
    inner.add_theme_constant_override("margin_top", 22)
    inner.add_theme_constant_override("margin_bottom", 22)
    panel.add_child(inner)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    inner.add_child(box)

    var title := Label.new()
    title.text = title_text
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Color("#ffffff"))
    title.add_theme_font_size_override("font_size", 32)
    box.add_child(title)
    return box

func add_button(parent: Control, caption: String, callback: Callable, is_disabled := false) -> Button:
    var button := Button.new()
    button.text = caption
    button.disabled = is_disabled
    button.custom_minimum_size = Vector2(0, 52)
    button.add_theme_font_size_override("font_size", 21)
    parent.add_child(button)
    button.pressed.connect(callback)
    return button

func add_spacer(parent: Control) -> void:
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(spacer)

func show_main() -> void:
    var box := make_screen("VOXEL DÜNYA")
    add_spacer(box)
    add_button(box, "TEK OYUNCULU", show_worlds)
    add_button(box, "ÇOK OYUNCULU  🔒  (İleride eklenecek)", func(): pass, true)
    add_button(box, "SUNUCU BARINDIRMA  🔒  (İleride eklenecek)", func(): pass, true)
    add_button(box, "Karakter görünümü", show_character)
    add_button(box, "Çıkış", func(): get_tree().quit())
    add_spacer(box)
    var footer := Label.new()
    footer.text = "İlk prototip • Menü ve dünya oluşturma"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(footer)

func show_character() -> void:
    var box := make_screen("KARAKTER GÖRÜNÜMÜ")
    var info := Label.new()
    info.text = "Şimdilik gönderdiğin iki görünüm kullanılacak. Cinsiyet seçimi yok."
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(info)

    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 50)
    box.add_child(row)

    for i in range(SKIN_PATHS.size()):
        var column := VBoxContainer.new()
        column.custom_minimum_size = Vector2(220, 220)
        row.add_child(column)
        var preview := TextureRect.new()
        preview.texture = load(SKIN_PATHS[i])
        preview.custom_minimum_size = Vector2(180, 180)
        preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        column.add_child(preview)
        var label := Label.new()
        label.text = "Görünüm %d%s" % [i + 1, "  ✓" if selected_skin == i else ""]
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(label)
        var choose := Button.new()
        choose.text = "Bu görünümü seç"
        choose.pressed.connect(func(): selected_skin = i; show_character())
        column.add_child(choose)

    add_spacer(box)
    add_button(box, "Geri", show_main)

func show_worlds() -> void:
    var box := make_screen("TEK OYUNCULU • DÜNYALARIM")
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)

    if worlds.is_empty():
        var empty := Label.new()
        empty.text = "Henüz dünya oluşturmadın."
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        list.add_child(empty)

    for i in range(worlds.size()):
        var world: Dictionary = worlds[i]
        var row := HBoxContainer.new()
        list.add_child(row)
        var info := Label.new()
        info.text = "%s    •    %s" % [world.get("name", "World"), world.get("mode", "Hayatta Kalma")]
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.add_theme_font_size_override("font_size", 20)
        row.add_child(info)
        var play := Button.new()
        play.text = "Oyna"
        play.pressed.connect(func(): show_world_placeholder(i))
        row.add_child(play)
        var edit := Button.new()
        edit.text = "Düzenle"
        edit.pressed.connect(func(): edit_world(i))
        row.add_child(edit)
        var delete := Button.new()
        delete.text = "Sil"
        delete.pressed.connect(func(): confirm_delete(i))
        row.add_child(delete)

    add_button(box, "＋ Yeni Dünya Oluştur", show_create, worlds.size() >= 20)
    if worlds.size() >= 20:
        var limit := Label.new()
        limit.text = "En fazla 20 dünya oluşturabilirsin."
        limit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(limit)
    add_button(box, "Geri", show_main)

func show_create() -> void:
    if worlds.size() >= 20:
        show_worlds()
        return
    var box := make_screen("YENİ DÜNYA OLUŞTUR")
    var form := GridContainer.new()
    form.columns = 2
    form.add_theme_constant_override("h_separation", 20)
    form.add_theme_constant_override("v_separation", 12)
    box.add_child(form)

    add_form_label(form, "Dünya adı")
    name_input = LineEdit.new()
    name_input.placeholder_text = "World%d" % (worlds.size() + 1)
    form.add_child(name_input)

    add_form_label(form, "Tohum (Seed)")
    seed_input = LineEdit.new()
    seed_input.placeholder_text = "Rastgele (istersen kendin yaz)"
    form.add_child(seed_input)

    add_form_label(form, "Harita oluşturucu")
    generator_select = OptionButton.new()
    for item in ["Varsayılan", "Vadiler", "Düz", "Süper düz"]:
        generator_select.add_item(item)
    generator_select.item_selected.connect(func(index): selected_generator = generator_select.get_item_text(index))
    form.add_child(generator_select)

    add_form_label(form, "Oyun modu")
    mode_select = OptionButton.new()
    mode_select.add_item("Hayatta Kalma")
    mode_select.add_item("Yaratıcı")
    mode_select.item_selected.connect(func(index): selected_mode = mode_select.get_item_text(index))
    form.add_child(mode_select)

    var details := Label.new()
    details.text = "Dünya boyutu: 1024 × 1024 blok\nBiyomlar kendiliğinden oluşur • Başlangıç: rastgele konum, sabah\nYer altı: mağaralar • Alt sınır: Y=-500 • Üst sınır: Y=60000"
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(details)
    add_spacer(box)
    add_button(box, "DÜNYAYI OLUŞTUR", create_world)
    add_button(box, "İptal", show_worlds)

func add_form_label(parent: Control, text_value: String) -> void:
    var label := Label.new()
    label.text = text_value
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    parent.add_child(label)

func create_world() -> void:
    if worlds.size() >= 20:
        show_worlds()
        return
    var world_name := name_input.text.strip_edges()
    if world_name.is_empty():
        world_name = "World%d" % (worlds.size() + 1)
    var seed_text := seed_input.text.strip_edges()
    if seed_text.is_empty():
        seed_text = str(randi())
    var mode_text := mode_select.get_item_text(mode_select.selected)
    var generator_text := generator_select.get_item_text(generator_select.selected)
    worlds.append({
        "name": world_name,
        "mode": mode_text,
        "seed": seed_text,
        "generator": generator_text,
        "skin": selected_skin
    })
    _save_worlds()
    show_worlds()

func edit_world(index: int) -> void:
    var box := make_screen("DÜNYAYI DÜZENLE")
    var world: Dictionary = worlds[index]
    var name_label := Label.new()
    name_label.text = "Dünya adı"
    box.add_child(name_label)
    var edit_name := LineEdit.new()
    edit_name.text = str(world.get("name", "World"))
    box.add_child(edit_name)

    var mode_label := Label.new()
    mode_label.text = "Oyun modu"
    box.add_child(mode_label)
    var mode_option := OptionButton.new()
    mode_option.add_item("Hayatta Kalma")
    mode_option.add_item("Yaratıcı")
    mode_option.select(1 if world.get("mode") == "Yaratıcı" else 0)
    box.add_child(mode_option)

    add_spacer(box)
    add_button(box, "Değişiklikleri kaydet", func():
        worlds[index]["name"] = edit_name.text.strip_edges() if not edit_name.text.strip_edges().is_empty() else "World%d" % (index + 1)
        worlds[index]["mode"] = mode_option.get_item_text(mode_option.selected)
        _save_worlds()
        show_worlds()
    )
    add_button(box, "Dünyayı sil", func(): confirm_delete(index))
    add_button(box, "Geri", show_worlds)

func confirm_delete(index: int) -> void:
    var dialog := ConfirmationDialog.new()
    dialog.title = "Dünyayı sil"
    dialog.dialog_text = "Bu dünyayı ve kayıtlarını kalıcı olarak silmek istiyor musun?"
    add_child(dialog)
    dialog.confirmed.connect(func():
        worlds.remove_at(index)
        _save_worlds()
        show_worlds()
    )
    dialog.popup_centered()

func show_world_placeholder(index: int) -> void:
    var box := make_screen(str(worlds[index].get("name", "Dünya")))
    var text_label := Label.new()
    text_label.text = "Dünya kaydı oluşturuldu.\n3D dünya, blok kırma ve yerleştirme sistemleri sonraki geliştirme aşamasında eklenecek."
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(text_label)
    add_button(box, "Dünyalarım'a dön", show_worlds)

func _save_worlds() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(worlds))

func _load_worlds() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        worlds = []
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file:
        var parsed = JSON.parse_string(file.get_as_text())
        worlds = parsed if parsed is Array else []
