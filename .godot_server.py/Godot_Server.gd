extends Node

var tcp: StreamPeerTCP = StreamPeerTCP.new()
var seq: int = 0
var rx_buf: PackedByteArray = PackedByteArray()

var motor_current_a: float = 0.0
var motor_voltage_v: float = 0.0

@export var send_hz: float = 60.0
var _accum: float = 0.0

func _ready() -> void:
    var err: int = tcp.connect_to_host("127.0.0.1", 5005)
    if err != OK:
        push_error("connect failed: %s" % err)
        return
    print("GODOT connect_to_host called")

func _process(delta: float) -> void:
    if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
        return

    _accum += delta
    var period: float = 1.0 / max(send_hz, 1.0)
    if _accum >= period:
        _accum -= period
        _send_sensor_packet()

    _poll_replies()

func _send_sensor_packet() -> void:
    var apps_v: float = clamp(Input.get_action_strength("throttle"), 0.0, 1.0)
    var steer_v: float = clamp(
        Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"),
        -1.0, 1.0
    )

    seq += 1
    var msg: Dictionary = {
        "type": "sensor_packet",
        "seq": seq,
        "apps_v": apps_v,
        "steer_v": steer_v
    }

    var line: String = JSON.stringify(msg) + "\n"
    tcp.put_data(line.to_utf8_buffer())

func _poll_replies() -> void:
    # Read bytes (tcp.get_data returns Array: [error_code:int, data:PackedByteArray])
    while true:
        var res: Array = tcp.get_data(4096)
        var err: int = int(res[0])
        var chunk: PackedByteArray = res[1] as PackedByteArray
        if err != OK or chunk.size() == 0:
            break
        rx_buf.append_array(chunk)

    # Parse complete lines
    while true:
        var idx: int = rx_buf.find(10) # '\n'
        if idx == -1:
            break

        var line_bytes: PackedByteArray = rx_buf.slice(0, idx)
        rx_buf = rx_buf.slice(idx + 1, rx_buf.size())

        var line: String = line_bytes.get_string_from_utf8().strip_edges()
        if line.is_empty():
            continue

        var parsed: Variant = JSON.parse_string(line)
        if typeof(parsed) != TYPE_DICTIONARY:
            continue

        var msg: Dictionary = parsed as Dictionary
        if msg.get("type", "") != "motor_packet":
            continue

        motor_current_a = float(msg.get("motor_current_a", 0.0))
        motor_voltage_v = float(msg.get("motor_voltage_v", 0.0))