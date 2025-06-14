FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    python3 python3-pip git cmake build-essential wget curl nano \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/ggerganov/llama.cpp.git
WORKDIR /app/llama.cpp
RUN make

RUN pip3 install fastapi uvicorn pydantic

RUN echo "\
from fastapi import FastAPI\n\
from pydantic import BaseModel\n\
import subprocess\n\n\
app = FastAPI()\n\n\
class PromptRequest(BaseModel):\n\
    prompt: str\n\n\
@app.post('/ask')\n\
async def ask_model(request: PromptRequest):\n\
    result = subprocess.run(\n\
        ['./build/bin/llama-simple', '-m', 'phi-2.Q4_K_M.gguf', '-n', '128', request.prompt],\n\
        capture_output=True,\n\
        text=True\n\
    )\n\
    return {'response': result.stdout}\n" > /app/llama.cpp/llama_server.py

COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

CMD ["/app/run.sh"]
