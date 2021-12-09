构建 WeNet 镜像，里面包含了 srilm 工具。构建时请根据实际环境修改 Dockerfile 里的 PyTorch 版本，然后下载下列软件包到 src\_code 文件夹（这样做主要是防止构建镜像时因为网络错误出错）

```
boost_1_75_0.tar.gz
glog-0.4.0.zip
googletest-release-1.10.0.zip
libtorch-cxx11-abi-shared-with-deps-1.10.0+cpu.zip
openfst-1.6.5.zip
```

下载下列软件包到 srilm 文件夹：

```
srilm-1.7.3.tar.gz
```

最后运行下列命令进行构建：

```
./build.sh
```

构建镜像后可以用下列代码运行 websocket server （需要先下载预训练模型）

```bash
#!/bin/bash

docker run --rm --runtime=nvidia \
    --network host \
    --name wenet_websocket_server \
    --shm-size="16g" \
    --env GLOG_logtostderr=1 \
    --env GLOG_v=2 \
    -v${PWD}:/workspace \
    wenet websocket_server_main \
        --port 8001 \
        --chunk_size 0 \
        --num_left_chunks 0 \
        --beam 8 \
        --model_path exp/20210815_unified_conformer_server/final.zip \
        --dict_path exp/20210815_unified_conformer_server/words.txt
```

websocket client 示例：

```python
import asyncio
import json
import wave

import websockets


start_signal = {
    "signal": "start",
    "nbest": 1,
    "continuous_decoding": False,
}
end_signal = {
    "signal": "end",
}


async def send_wav(conn, wav_file, interval):
    await conn.send(json.dumps(start_signal))
    print("send:", start_signal)

    with wave.open(wav_file) as f:
        frame_rate = f.getframerate()
        # num_frames = f.getnframes()
        num_frames_per_time = int(frame_rate * interval / 1000)

        i = 1
        while True:
            data = f.readframes(num_frames_per_time)
            if data == b"":
                break
            await conn.send(data)
            print("send:", i)
            i += 1
            await asyncio.sleep(0.1)

    await conn.send(json.dumps(end_signal))
    print("send:", end_signal)


async def recv(conn):
    while True:
        res_bytes = await conn.recv()
        res = json.loads(res_bytes)
        print("receive:", res)
        if res["type"] == "speech_end":
            break


async def main():
    wav_file = "/Users/pan/Data/aishell/BAC009S0708W0407.8000.wav"
    ws_addr = "ws://127.0.0.1:8001"
    interval = 100  # 100ms
    async with websockets.connect(ws_addr) as conn:
        task1 = asyncio.create_task(send_wav(conn, wav_file, interval))
        task2 = asyncio.create_task(recv(conn))
        await task1
        await task2


if __name__ == "__main__":
    asyncio.run(main())
```
