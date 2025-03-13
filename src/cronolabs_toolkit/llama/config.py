from dataclasses import dataclass


@dataclass
class LlamaConfig:
    host: str = "localhost"
    port: int = 11434
