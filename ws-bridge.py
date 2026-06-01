#!/usr/bin/env python3
import asyncio
import websockets
import sys
import os

async def bridge(websocket, path):
    target_host = os.environ.get('TARGET_HOST', '127.0.0.1')
    target_port = int(os.environ.get('TARGET_PORT', 2222))

    try:
        reader, writer = await asyncio.open_connection(target_host, target_port)

        async def ws_to_tcp():
            try:
                while True:
                    data = await websocket.recv()
                    writer.write(data)
                    await writer.drain()
            except:
                pass

        async def tcp_to_ws():
            try:
                while True:
                    data = await reader.read(4096)
                    if not data:
                        break
                    await websocket.send(data)
            except:
                pass

        await asyncio.gather(ws_to_tcp(), tcp_to_ws())
    except Exception as e:
        print(f"Bridge error: {e}", file=sys.stderr)
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except:
            pass

async def main():
    port = int(os.environ.get('LISTEN_PORT', 2223))
    async with websockets.serve(bridge, '127.0.0.1', port):
        await asyncio.Future()

if __name__ == '__main__':
    asyncio.run(main())
