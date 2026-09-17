extends SceneTree
func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(900, 900))
	call_deferred("run")
func run() -> void:
	var vp := get_root()
	var arena := Arena3D.new()
	vp.add_child(arena)
	await process_frame
	arena.instalar(load("res://assets/personagem/lutador.glb"))
	arena.ligar(true); arena.preparar()
	var mundo := arena.find_child("Mundo", true, false)
	arena.remove_child(mundo); vp.add_child(mundo)
	var lut := arena.lutador
	arena.remove_child(lut); mundo.add_child(lut)
	await process_frame
	lut.guardar(false)
	for i in range(40):
		lut.atualizar(1.0/60.0); await process_frame
	# camera fechada no rosto
	var cam: Camera3D = arena.camera
	cam.fov = 30.0
	cam.position = Vector3(0.0, 1.66, 1.05)
	cam.look_at(Vector3(0.0, 1.62, 0.0), Vector3.UP)
	await process_frame
	await process_frame
	vp.get_texture().get_image().save_png("res://.telas/rosto.png")
	print("salvo rosto")
	quit(0)
