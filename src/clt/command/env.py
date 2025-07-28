import os
from tabulate import tabulate


def trim_value(value: str) -> str:
    newline_index: int = value.find(os.linesep)
    return value if newline_index < 0 else value[:newline_index] + "..."


if __name__ == "__main__":
    env_vars: list[tuple[str, str]] = [
        (k, trim_value(v))
        for k, v in os.environ.items()
        if k.startswith("APP_") or k.startswith("APPC_")
    ]
    print(tabulate(env_vars, headers=["Name", "Value"]))
