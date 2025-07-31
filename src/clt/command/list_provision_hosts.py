import sys
import os
import yaml
from argparse import ArgumentParser
from typing import Any
from tabulate import tabulate
from icmplib import ping
from tqdm import tqdm

_Node = dict[str, Any]
_GroupedNodes = dict[str, list[_Node]]


def load_file(filepath: str) -> dict[str, Any] | None:
    data: dict[str, Any]

    try:
        with open(filepath, "r") as host_file:
            data = yaml.safe_load(host_file)
        return data
    except Exception as e:
        print(f"Erorr loading file at path: {host_filepath}")
        print(e)
        return None


def group_by_parent(host_data: _Node) -> _GroupedNodes:
    grouped_data: _GroupedNodes = {}

    # The double pass is to handle children being defined before parents.
    for target_name, target_data in host_data.items():
        parent: str = target_data.get("parent", None)

        if parent:
            continue

        grouped_data[target_name] = []

    for target_name, target_data in host_data.items():
        parent: str = target_data.get("parent", None)

        if parent and parent in grouped_data:
            target_data["name"] = target_name
            # target_data["alive"] = is_alive
            grouped_data[parent].append(target_data)

    return grouped_data


def ping_hostname(hostname: str) -> str:
    if ping(hostname, count=1, privileged=False).is_alive:
        return "Y"
    return "N"


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-p", "--ping", default=False, action="store_true")
    args, _ = parser.parse_known_args()

    host_filepath: str = os.environ["PRV_HOST_FILE"]
    host_data: dict[str, Any] | None = load_file(host_filepath)

    if not host_data:
        sys.exit(1)

    table_data: list[tuple[str, str, str, str, str, str]] = []
    grouped_data: _GroupedNodes = group_by_parent(host_data)

    # TODO: This is kind of yucky
    for target_name, target_data in tqdm(
        host_data.items(), desc="Processing targets", leave=False
    ):
        if "parent" in target_data:
            continue

        target_hostname = target_data["hostname"]
        children: list[_Node] = grouped_data[target_name]
        is_alive: str = "--"

        if args.ping:
            is_alive = ping_hostname(target_hostname)

        table_data.append(
            (
                target_name,
                "",
                target_data["description"],
                target_data["type"],
                target_hostname,
                is_alive,
            )
        )

        for child in children:
            child_hostname: str = child["hostname"]
            child_alive: str = "--"

            if args.ping:
                child_alive: str = ping_hostname(child_hostname)

            table_data.append(
                (
                    "",
                    child["name"],
                    child["description"],
                    child["type"],
                    child_hostname,
                    child_alive,
                )
            )

    print(
        tabulate(
            table_data,
            headers=["Target", "Child", "Description", "Type", "Hostname", "Alive"],
        )
    )
