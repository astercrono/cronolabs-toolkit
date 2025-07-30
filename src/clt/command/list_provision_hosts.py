import sys
import os
import yaml
from typing import Any
from tabulate import tabulate

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
            grouped_data[parent].append(target_data)

    return grouped_data


if __name__ == "__main__":
    host_filepath: str = os.environ["PRV_HOST_FILE"]
    host_data: dict[str, Any] | None = load_file(host_filepath)

    if not host_data:
        sys.exit(1)

    table_data: list[tuple[str, str, str, str]] = []
    grouped_data: _GroupedNodes = group_by_parent(host_data)

    for target_name, target_data in host_data.items():
        if "parent" in target_data:
            continue

        children: list[_Node] = grouped_data[target_name]

        table_data.append(
            (target_name, "", target_data["description"], target_data["type"])
        )

        for child in children:
            table_data.append(("", child["name"], child["description"], child["type"]))

    print(tabulate(table_data, headers=["Target", "Child", "Description", "Type"]))
