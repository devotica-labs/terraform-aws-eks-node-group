#!/usr/bin/env python3
"""Render an EKS node group architecture diagram from a Terraform plan JSON.

Shows the node group attached to its cluster, the launch template + worker
EC2 nodes, the node IAM role, and a KMS edge when the disk uses a CMK.

Usage:
    python scripts/render-architecture.py <plan.json> <output-path-no-ext>
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2, EKS
from diagrams.aws.security import IAMRole, KMS


def load_resources(plan_path: Path) -> list[dict]:
    plan = json.loads(plan_path.read_text())
    root = plan.get("planned_values", {}).get("root_module", {})
    collected: list[dict] = []

    def walk(mod: dict) -> None:
        for r in mod.get("resources", []):
            collected.append(r)
        for child in mod.get("child_modules", []):
            walk(child)

    walk(root)
    return collected


def values(r: dict) -> dict:
    return r.get("values", {}) or {}


def render(plan_path: Path, out_no_ext: Path) -> None:
    resources = load_resources(plan_path)
    by_type: dict[str, list[dict]] = {}
    for r in resources:
        by_type.setdefault(r["type"], []).append(r)

    ngs = by_type.get("aws_eks_node_group", [])
    if not ngs:
        raise SystemExit("No aws_eks_node_group found in plan — nothing to render.")

    ng = values(ngs[0])
    name = ng.get("node_group_name") or "node-group"
    cluster_name = ng.get("cluster_name") or "eks"
    instance_types = ng.get("instance_types") or []
    capacity = ng.get("capacity_type", "ON_DEMAND")
    ami = ng.get("ami_type", "")
    scaling = (ng.get("scaling_config") or [{}])[0] if ng.get("scaling_config") else {}
    min_s = scaling.get("min_size")
    max_s = scaling.get("max_size")

    lt = by_type.get("aws_launch_template", [])
    lt_v = values(lt[0]) if lt else {}
    bdm = (lt_v.get("block_device_mappings") or [{}])
    ebs = (bdm[0].get("ebs") or [{}])[0] if bdm and bdm[0].get("ebs") else {}
    has_cmk = bool(ebs.get("kms_key_id"))
    has_role = bool(by_type.get("aws_iam_role"))

    badges = [f"{capacity.lower()}"]
    if instance_types:
        badges.append("/".join(instance_types[:2]))
    if min_s is not None and max_s is not None:
        badges.append(f"{min_s}-{max_s} nodes")
    if "ARM" in ami:
        badges.append("Graviton")
    badges.append("IMDSv2")
    if ebs.get("encrypted"):
        badges.append("disk enc" + ("+CMK" if has_cmk else ""))

    graph_attr = {
        "fontsize": "20",
        "splines": "ortho",
        "ranksep": "1.0",
        "nodesep": "0.6",
        "pad": "0.5",
    }

    out_no_ext.parent.mkdir(parents=True, exist_ok=True)
    with Diagram(
        f"terraform-aws-eks-node-group — {name} · {' · '.join(badges)}",
        filename=str(out_no_ext),
        show=False,
        direction="LR",
        outformat="png",
        graph_attr=graph_attr,
    ):
        cluster = EKS(f"EKS cluster\n{cluster_name}")

        with Cluster(f"Node group — {name}"):
            node = EC2("worker nodes\n(launch template)")
            cluster >> Edge(label="joins") >> node

            if has_role:
                IAMRole("node role\n(+SSM)") >> Edge(style="dashed", label="assumes") >> node

            if has_cmk:
                KMS("KMS key") >> Edge(style="dashed", label="encrypts disk") >> node


def main() -> None:
    if len(sys.argv) < 3:
        sys.stderr.write("Usage: render-architecture.py <plan.json> <output-path-without-ext>\n")
        sys.exit(2)
    render(Path(sys.argv[1]), Path(sys.argv[2]))


if __name__ == "__main__":
    main()
