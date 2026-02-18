import socket
import json
import time

HOST = "127.0.0.1"
PORT = 5005

START = time.perf_counter()

# Motor limits
I_MAX_A = 360.0      # max current 
V_MAX_V = 830.0      # max voltage 

def clamp(x, lo, hi):
    return lo if x < lo else hi if x > hi else x

def compute_outputs(apps_v, steer_v):
    # Inputs
    # apps_v: 0 to 1
    # steer_v: -1 to 1

    apps = clamp(float(apps_v), 0.0, 1.0)
    steer = clamp(float(steer_v), -1.0, 1.0)

   
    # Current scales (0..I_MAX)
    # Voltage scales (0..V_MAX)
    motor_current_a = apps * I_MAX_A
    motor_voltage_v = apps * V_MAX_V

    return motor_current_a, motor_voltage_v

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(1)
    print(f"Python Listening on {HOST}:{PORT}")

    conn, addr = server.accept()
    with conn:
        print("Python Connected:", addr)
        buf = b""

        while True:
            chunk = conn.recv(4096)
            if not chunk:
                print("PythonClient disconnected")
                break
            buf += chunk

            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                if not line.strip():
                    continue

                try:
                    msg = json.loads(line.decode("utf-8"))
                except Exception as e:
                    print("Python Bad JSON:", e)
                    continue

                if msg.get("type") != "sensor_packet":
                    continue

                seq = int(msg.get("seq", 0))
                apps_v = msg.get("apps_v", 0.0)
                steer_v = msg.get("steer_v", 0.0)

                motor_current_a, motor_voltage_v = compute_outputs(apps_v, steer_v)
                
                t_ms = int((time.perf_counter() - START) * 1000)

                reply = {
                    "type": "motor_packet",
                    "seq": seq,
                    "t_ms": t_ms,
                    "motor_current_a": motor_current_a,
                    "motor_voltage_v": motor_voltage_v
                }

                conn.sendall((json.dumps(reply, separators=(",", ":")) + "\n").encode("utf-8"))