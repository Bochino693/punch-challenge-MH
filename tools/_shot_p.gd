extends SceneTree
func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1152, 1290))
	call_deferred("run")
func run() -> void:
	var vp := get_root()
	var arena := Arena3D.new()
	vp.add_child(arena)
	await process_frame
	if not arena.instalar(load("res://assets/personagem/lutador.glb")):
		print("FALHOU"); quit(1); return
	arena.ligar(true); arena.preparar()
	var mundo := arena.find_child("Mundo", true, false)
	arena.remove_child(mundo); vp.add_child(mundo)
	var lut := arena.lutador
	arena.remove_child(lut); mundo.add_child(lut)
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.telas"))
	lut.guardar(true)
	for i in range(60):
		lut.atualizar(1.0/60.0); arena._camera(); await process_frame
	await process_frame
	vp.get_texture().get_image().save_png("res://.telas/p_guarda.png")
	print("salvo")
	quit(0)
