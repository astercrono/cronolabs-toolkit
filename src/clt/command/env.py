import os
from tabulate import tabulate

if __name__ == "__main__":
    env_vars: list[tuple[str, str]] = [
        (k, v)
        for k, v in os.environ.items()
        if k.startswith("APP_") or k.startswith("APPC_")
    ]
    print(tabulate(env_vars, headers=["Name", "Value"]))
