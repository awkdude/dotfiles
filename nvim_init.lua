package main

import "odinlib:util"
import "odinlib:file_load"
import "core:log"
import "core:fmt"
import "core:os"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"
import "base:runtime"
import "core:time"
import "core:strings"
import "core:odin/tokenizer"
import "core:odin/ast"
import "core:odin/parser"
import "gfx"
import stbi "vendor:stb/image"
import "core:slice"
import mu "vendor:microui"
import sdl "vendor:sdl3"

PLATFORM_BACKEND :: #config(BACKEND, "native")
USE_RENDERDOC    :: #config(RENDERDOC, false)
OjENGL_VERSION   :: [2]int {3, 3}
SIM_UPDATE_HZ :: 60
SIM_UPDATE_INTERVAL :: (time.Duration)(cast(f32)time.Second/cast(f32)SIM_UPDATE_HZ)
SIM_LAG_MAX :: 30 * SIM_UPDATE_INTERVAL
odin_context: runtime.Context

// Vertex :: file_load.OBJ_Vertex

Sim_Tick :: int

Game_Context :: struct {
    running: bool,
    scene: Scene,
    mouse_position: util.vec2,
    theta: f32,
    ui: UI_Context,
    mu_window: ^mu.Container,
    init_info: App_Init,
    update_info: App_Update,
    sdl_gamepad: ^sdl.Gamepad,
    orientation: util.vec3f,
    _input_state: [2]util.Input_State,
    input, old_input: ^util.Input_State,
    sdl_haptic: ^sdl.Haptic,
    current_camera: ^Entity,
    camera_entity: Entity,
    camera_is_controlled: bool,
    menu: ^Menu, 
    menu_active: bool,
    menu_scale: f32,
    menu_stack: [dynamic; 8]^Menu,
    font_offsets: map[rune]vec2,
    cube_anim: Sprite_Animator,
    last_frame_cputick: time.Tick,
    simticks: Sim_Tick,
    lag: time.Duration,
    frame_counter: int,
    paused: bool,
    input_source_type: Input_Source_Type,
    // car: Model,
}

game: ^Game_Context

App_Init :: struct {
    set_clipboard_text: proc(text: string) -> bool,
    get_clipboard_text: proc() -> (string, bool),
    pixel_format: util.Pixel_Format,
    gfx_context: ^gfx.Gfx,
}

App_Update :: struct {
    window_dims: util.vec2,
    gamepad_state: util.Gamepad_State,
    is_gamepad_connected: bool,
    framebuffer: util.Pixmap,
    gfx_context: ^gfx.Gfx,
}

app_init :: proc(init_info: App_Init) -> bool {
    odin_context = context
    setup_steam()
    init_sdl_input()
    game = new_clone(Game_Context{})
    game.init_info = init_info
    handle_platform_command({type=.Rename_Window, title="RACER3D"})
    handle_platform_command({type=.Change_Window_Icon, path="assets/textures/icon.ico"})
    game.running = true
    game.last_frame_cputick = time.tick_now()
    game.lag = SIM_UPDATE_INTERVAL
    game.paused = false

    scene_init(&game.scene)
    game.menu = &MAIN_MENU
    game.menu_active = false
    game.menu_scale = 2.0
    init_font()
    new_model_from_meshes(
        &game.scene,
        {
            Mesh {
                vertices=[]Vertex {
                    Vertex{
                        position={-0.5, -0.5, 0.0},
                        tex_coord={0.0, 0.0},
                        // normal={1.0, 0.0, 0.0, 1.0},
                    },
                    Vertex{
                        position={0.5, -0.5, 0.0},
                        tex_coord={1.0, 0.0},
                        // normal={0.0, 1.0, 0.0, 1.0},
                    },
                    Vertex{
                        position={0.5, 0.5, 0.0},
                        tex_coord={1.0, 1.0},
                        // normal={1.0, 1.0, 0.0, 1.0},
                    },
                    Vertex{
                        position={-0.5, 0.5, 0.0},
                        tex_coord={0.0, 1.0},
                        // normal={0.0, 0.0, 1.0, 1.0},
                    },
                },
                indices=[]u32 {
                    0, 1, 2,
                    0, 2, 3,
                },
            },
        },
        "square"
    )
    gl.Disable(gl.CULL_FACE)
    // gl.CullFace(gl.BACK)
    // gl.FrontFace(gl.CCW)

    ui_init(
        &game.ui,
        "assets/fonts/CourierPrime-Regular.ttf",
        proc(_: rawptr, text: string) -> bool {
            return game.init_info.set_clipboard_text(text)
        },
        proc(_: rawptr) -> (string, bool) {
            return game.init_info.get_clipboard_text()
        }
    )

    fail_index: Maybe(int)
    load_textures_from_paths(
        &game.scene,
        {
            {"assets/textures/face.qoi", "face"},
            {"assets/textures/cube1.png", "cube_tex"},
            {"assets/textures/cube2.png", "cube_tex2"},
            {"assets/textures/cube3.png", "cube_tex3"},
        },
        init_info.pixel_format,
    )

    _, model_err := new_model_from_file(&game.scene, "assets/models/sphere.gltf", "cube_model")
    assert(model_err == nil)
    _, shader_err := new_shader(
        &game.scene,
        util.Source_Shader{
            vertex_source_path="assets/shaders/shader.vert",
            fragment_source_path="assets/shaders/shader.frag",
        },
        "shader"
    )
    assert(shader_err == nil)
    
    game.input = &game._input_state[0]
    game.old_input = &game._input_state[1]
    game.input.transient = {}

    game.camera_entity = {
        position = util.vec3f{0, 0, 3},
        camera = {
            fov = 50*math.RAD_PER_DEG,
            right = {1.0, 0.0, 0.0},
            up = {0.0, 1.0, 0.0},
            front = {0.0, 0.0, -1.0},
        }
    }

    return true
}

assert_eq :: proc(value: $T, expected: T, loc := #caller_location) {
    log.debug("In", #procedure)
    source, err := os.read_entire_file_from_path(loc.file_path, context.allocator)
    if err != nil {
        log.panic("Assertion fail at", loc)
    }
    walk_ast :: proc(file: ^ast.File) {
        ast_file, _ := os.open("ast.txt", {.Create, .Write})
        defer os.close(ast_file)
        Visit_Data :: struct {
            src: string,
            file: ^os.File, // ^ast.File,
        }
        vdata := Visit_Data {src=file.src, file=ast_file}
        visitor := ast.Visitor {
            data = cast(rawptr)&vdata,
            visit = proc(v: ^ast.Visitor, node: ^ast.Node) -> ^ast.Visitor {
                vdata := cast(^Visit_Data)v.data
                str, _ := strings.substring(vdata.src, node.pos.offset, node.end.offset)
                os.write( vdata.file, transmute([]u8)str)
                // log.debug(node)
                return v
            }
        }
        ast.walk(&visitor, file)
    }
    t: tokenizer.Tokenizer
    tokenizer.init(&t, cast(string)source, loc.file_path)
    count := 0
    p: parser.Parser
    file: ast.File
    file.src = cast(string)source
    file.derived = &file
    parser.parse_file(&p, &file)
    // walk_ast(&file)
    for count < 5 {
        token := tokenizer.scan(&t)
        if token.pos.line == cast(int)loc.line && token.pos.column == cast(int)loc.column {
            count += 1
        }
        if count > 0 {
            log.debugf("TOKEN %v:%v", count, token.text)
            count += 1
        }
        if token.kind == .EOF {
            break
        }
    }
    log.assertf(value == expected, "%s is %v instead of %v\n%v", "???", value, expected, loc)
    // TODO: print 5 or so tokens after loc
}

app_shutdown :: proc() {

}

move_camera :: proc(camera_entity: ^Entity) {
    speed :: 0.01
    PITCH_ANGLE_LIMIT:: 80.0 * math.RAD_PER_DEG
    left_stick := input_stick(.Left)
    right_stick := input_stick(.Right)
    // camera_entity.camera.right = linalg.cross(camera_entsty.camera.front, camera_entity.camera.up)
    move_v := util.vec3f {
        left_stick.x, // game.input.gamepad.axes[.LEFT_X],
        0.0,
        left_stick.y // game.input.gamepad.axes[.LEFT_Y]
    }
    camera_entity.orientation.x += (right_stick.y * speed) 
    camera_entity.orientation.y += (right_stick.x * speed) 
    camera_entity.orientation.x = math.clamp(
        camera_entity.orientation.x,
        -PITCH_ANGLE_LIMIT,
        PITCH_ANGLE_LIMIT
    )
    pitch := camera_entity.orientation.x
    yaw := camera_entity.orientation.y
    assert_eq(yaw, 0.0)
    direction := vec3f {
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch),
        math.sin(yaw) * math.cos(pitch),
    }
    camera_entity.camera.front = linalg.vector_normalize0(direction)
    
    camera_entity.position += move_v * speed
}

app_update_render :: proc(update_info: App_Update) -> bool {
    game.frame_counter += 1
    game.update_info = update_info

    update_gamepad_input()
    if gamepad_input_did_change() {
        game.input_source_type = .Gamepad
    } 
    if input_pause() {
        game.menu_active = !game.menu_active
    }
    if input_button_pressed(.SELECT) {
        game.camera_is_controlled = !game.camera_is_controlled 
    }
    now := time.tick_now()
    diff := time.tick_diff(game.last_frame_cputick, now)
    game.lag += diff
    game.last_frame_cputick = now
    do_update_sim := !game.paused
    for do_update_sim && game.lag >= SIM_UPDATE_INTERVAL {
        if game.lag > SIM_LAG_MAX {
            game.lag = SIM_UPDATE_INTERVAL
        }
        sim_update()
        game.simticks += 1
        game.lag -= SIM_UPDATE_INTERVAL
    }
    v: f32 = 0.1 // cast(f32)game.mouse_position.x / cast(f32)update_info.window_dims.x
    gl.Viewport(0, 0, update_info.window_dims.x, update_info.window_dims.y)
    gl.ClearColor(0.0, v, 0.0, 1.0)
    gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    source_shader := find_resource(util.Source_Shader, "shader")
    gfx.check_source_shader_update(source_shader)
    shader_program := source_shader.program
    gl.UseProgram(shader_program)
    proj_matrix := linalg.matrix4_perspective_f32(
        game.camera_entity.camera.fov, // 90.0 * math.RAD_PER_DEG,
        cast(f32)update_info.window_dims.x/cast(f32)update_info.window_dims.y,
        0.1,
        100.0
    )
    view_matrix := 
    linalg.matrix4_look_at(
        // game.camera_entity.position,
        // game.camera_entity.position + game.camera_entity.camera.front,
        // game.camera_entity.camera.up,
        game.camera_entity.position,
        game.camera_entity.position + game.camera_entity.camera.front,
        game.camera_entity.camera.up,
    )
     // linalg.matrix4_translate(game.camera_entity.position) // util.vec3f{0.0, 0.0, -3.0})
    model_matrix: util.mat4 = 1
    shear_matrix: util.mat4 = 1 
    // shear_matrix[0, 2] = util.time_sin()
    // model_matrix *= util.matrix4_shear(xy=util.time_sin(min=-1.0))
    // model_matrix *= linalg.matrix4_translate(util.vec3f{0.0, util.time_sin(), 0.0})
    // model_matrix *= linalg.matrix4_rotate(math.PI, game.orientation.yxz)
    model_matrix *= linalg.matrix4_from_yaw_pitch_roll(game.orientation.x, game.orientation.y, 0)
    // model_matrix *= linalg.matrix4_scale(util.vec3f{util.time_sin(), 1.0, 1.0})
    util.shader_uniform(shader_program, "u_texture", 0)
    util.shader_uniform(shader_program, "u_heightmap", 1)
    util.shader_uniform(shader_program, "u_proj", &proj_matrix)
    util.shader_uniform(shader_program, "u_view", &view_matrix)
    util.shader_uniform(shader_program, "u_model", &model_matrix)
    util.shader_uniform(shader_program, "u_theta", game.theta)
    model := find_resource(Model, "cube_model")
    texture := find_resource(Texture, "face")
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture.tex_id)

    // gl.BindVertexArray(game.mesh.vao)
    // gl.ActiveTexture(gl.TEXTURE0)
    // gl.BindTexture(gl.TEXTURE_2D, game.tex_id1)
    // gl.ActiveTexture(gl.TEXTURE1)
    // gl.BindTexture(gl.TEXTURE_2D, game.heightmap_texid)
    // gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    draw_model(model)
    process_ui()
    menu_update_render()
    game.theta += math.TAU / 120.0
    free_all(context.temp_allocator)
    // TODO: swap input state pointers
    game.input, game.old_input = game.old_input, game.input
    game.input.transient = {}
    return game.running
}

sim_update :: proc() {
    left_stick := input_stick(.Left)
    right_stick := input_stick(.Right)
    // log.debug("Camera position:", game.camera_entity.position)
    log.debugf(
        "Camera front: (%.2f, %.2f, %.2f), orientation: (%.2f, %.2f, %.2f)",
        game.camera_entity.camera.front.x,
        game.camera_entity.camera.front.y,
        game.camera_entity.camera.front.z,
        game.camera_entity.orientation.x*math.DEG_PER_RAD,
        game.camera_entity.orientation.y*math.DEG_PER_RAD,
        game.camera_entity.orientation.z*math.DEG_PER_RAD,
    )
    if game.camera_is_controlled {
        move_camera(&game.camera_entity)
    } else {
        game.orientation += {left_stick.x, left_stick.y, 0.0} * 0.1
    }
    if touchpad_delta, ok := get_gamepad_touchpad_delta(.Right).?; ok {
        // game.orientation += {touchpad_delta.x, touchpad_delta.y, 0} * 1.4
        // game.orientation += {game.input.gamepad.gyroscope.x, game.input.gamepad.gyroscope.y, 0} * 0.01
    }
    game.theta += (1.0/60.0)
}

process_ui :: proc() {
    mu.begin(&game.ui.mu_ctx)
    txt := fmt.tprintf("Window dims: %v", game.update_info.window_dims)
    if mu.window(&game.ui.mu_ctx, txt, mu.Rect{0, 0, game.update_info.window_dims.x/2, game.update_info.window_dims.y/2}) {
        game.mu_window = mu.get_current_container(&game.ui.mu_ctx)
        mu.layout_row(&game.ui.mu_ctx, []i32{50, -1}, 0)
        mu.label(&game.ui.mu_ctx, txt)
        if .SUBMIT in mu.button(&game.ui.mu_ctx, "Press me!") {
            log.debug("Pressed button")
        }
        mu.layout_row(&game.ui.mu_ctx, []i32{50, -1}, 0)
        mu.checkbox(&game.ui.mu_ctx, "Camera", &game.camera_is_controlled)
        // ui_textf(&game.ui.mu_ctx, "Left touchpad: %v", get_gamepad_touchpad_delta(.Left))
        // ui_textf(&game.ui.mu_ctx, "Right touchpad: %v", get_gamepad_touchpad_delta(.Right))
        if memory_usage, ok := game.ui.renderer->get_memory_usage(); ok {
            ui_textf(&game.ui.mu_ctx, "Total memory: %v", memory_usage.total_available)
        }
    }
    mu.end(&game.ui.mu_ctx)
    ui_render(&game.ui, game.update_info.window_dims)
}

app_handle_event :: proc(event: util.Window_Event) {
    util.set_input_state_from_event(game.input, event)
    ui_handle_event(&game.ui, event)
    #partial switch event.type {
    case .Window_Close:
        game.running = false
    case .Key:
        if event.key.pressed {
            game.input_source_type = .Keyboard_Mouse
            switch event.key.keycode{
            case util.KEY_TAB: 
                microui_window := mu.get_container(&game.ui.mu_ctx, "Window")
                if microui_window != nil {
                    microui_window.open = !microui_window.open
                }
            case util.KEY_R:
                game.camera_is_controlled = false
                game.camera_entity = {
                    position = util.vec3f{0, 0, 5},
                    camera = {
                        fov = 50*math.RAD_PER_DEG,
                        right = {1.0, 0.0, 0.0},
                        up = {0.0, 1.0, 0.0},
                        front = {0.0, 0.0, -1.0},
                    }
                }
            }
        } else {
            switch event.key.keycode{
            case util.KEY_F4:
                game.running = false
            }
        }
    case .Mouse_Move:
        game.mouse_position = event.vec2
        game.input_source_type = .Keyboard_Mouse
    }
}
