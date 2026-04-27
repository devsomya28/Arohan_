from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List
import json
import asyncio

router = APIRouter(prefix="/ws")

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@router.websocket("/live-incidents")
async def websocket_endpoint(websocket: WebSocket):
    # In a real-world scenario, you would authenticate the websocket connection here
    # Since websockets don't support standard Authorization headers in browser JS easily,
    # tokens are usually passed as query parameters: ws://...?token=...
    
    await manager.connect(websocket)
    try:
        while True:
            # We wait for messages from the client if needed (e.g., ping/pong or filter commands)
            data = await websocket.receive_text()
            
            # Example: client could send "ping" and we reply "pong" to keep connection alive
            if data == "ping":
                await manager.send_personal_message("pong", websocket)
                
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# A background task could monitor Firebase Realtime Database and broadcast changes
# This function would be started in main.py startup event
async def listen_for_incident_updates():
    # Placeholder for a function that listens to Firebase Realtime DB changes
    # and calls await manager.broadcast(json.dumps(incident_update))
    pass
