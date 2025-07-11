import eventlet
eventlet.monkey_patch()

from flask import Flask, request, jsonify
from flask_socketio import SocketIO

app = Flask(__name__)

# Initiate SocketIO
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

status = "OFF"  # First State

@app.route('/')
def home():
    return "Server is running"

# HTTP route (POST)
@app.route('/set_status', methods=['POST'])
def set_status_http():
    global status
    data = request.get_json()
    if data and "status" in data and data["status"] in ["ON", "OFF"]:
        status = data["status"]
        print(f"Status berubah menjadi: {status}")
        socketio.emit('status_update', {"status": status})  # Kirim ke semua klien WebSocket
        return jsonify({"message": "Status updated", "status": status})
    return jsonify({"message": "Invalid status"}), 400

# HTTP GET route (GET)
@app.route('/get_status', methods=['GET'])
def get_status():
    return jsonify({"status": status})

# WebSocket Event when clients are connected
@socketio.on('connect')
def handle_connect():
    print("Client Connected")
    socketio.emit('status_update', {"status": status})  # Sent to all clients

# WebSocket event changing status
@socketio.on('set_status')
def set_status_ws(data):
    global status
    if data in ["ON", "OFF"]:
        status = data
        print(f"Status berubah menjadi: {status}")
        socketio.emit('status_update', {"status": status})  # send update to all clients

# Sent to all clients
@socketio.on('get_status')
def send_status():
    socketio.emit('status_update', {"status": status})

if __name__ == '__main__':
    socketio.run(app, host="0.0.0.0", port=5000, debug=True)
