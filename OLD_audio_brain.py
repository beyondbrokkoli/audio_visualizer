import socket
import time
import math

UDP_IP = "127.0.0.1"
UDP_PORT = 1337

# We use DGRAM for UDP!
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

print("--- PYTHON AUDIO BRAIN ONLINE ---")
print(f"Broadcasting to {UDP_IP}:{UDP_PORT} at 60Hz...")

t = 0.0
while True:
    # ====================================================
    # MOCK AUDIO DATA (Replace with Miniaudio FFT)
    # ====================================================
    # Simulating a heavy kick drum (bass) every 0.5s (120 BPM)
    bass = max(0.0, math.sin(t * math.pi * 4.0)) 
    mid = max(0.0, math.sin(t * math.pi * 2.0)) * 0.5
    treble = max(0.0, math.cos(t * math.pi * 8.0)) * 0.3

    # ====================================================
    # THE PACKET
    # ====================================================
    # Format as a clean string to survive lua_pushstring!
    payload = f"{bass:.3f},{mid:.3f},{treble:.3f}"
    
    # Fire and forget over UDP
    sock.sendto(payload.encode('utf-8'), (UDP_IP, UDP_PORT))

    # Sleep to simulate roughly 60Hz streaming
    t += 0.016 
    time.sleep(0.016)
