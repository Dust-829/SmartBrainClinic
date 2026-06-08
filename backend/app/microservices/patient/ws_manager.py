from fastapi import WebSocket
from typing import Dict, List
import logging

logger = logging.getLogger("patient.ws_manager")

class ConnectionManager:
    def __init__(self):
        # 记录每个排班房间对应的活跃 WebSocket 列表
        # room_id 一般为 scheduling_actual_id
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: int):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)
        logger.info(f"✅ WebSocket connected to room {room_id}. Total clients in room: {len(self.active_connections[room_id])}")

    def disconnect(self, websocket: WebSocket, room_id: int):
        if room_id in self.active_connections:
            if websocket in self.active_connections[room_id]:
                self.active_connections[room_id].remove(websocket)
            if not self.active_connections[room_id]:
                del self.active_connections[room_id]
            logger.info(f"❌ WebSocket disconnected from room {room_id}.")

    async def broadcast(self, room_id: int, message: str):
        """
        向指定排班房间内的所有患者广播消息
        """
        if room_id in self.active_connections:
            clients = self.active_connections[room_id]
            logger.info(f"📢 Broadcasting to room {room_id} ({len(clients)} clients): {message}")
            for connection in clients:
                try:
                    await connection.send_text(message)
                except Exception as e:
                    logger.warning(f"⚠️ Error broadcasting to client: {e}")

manager = ConnectionManager()
