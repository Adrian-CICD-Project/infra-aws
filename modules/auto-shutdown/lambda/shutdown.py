"""
Auto-shutdown EKS – odpowiednik Azure Automation Runbook.
Skaluje managed node group każdego klastra do 0 (desired=0, min=0),
co wyłącza węzły EC2 i ogranicza koszty. Control plane EKS pozostaje
(nie da się go zatrzymać), ale to węzły generują główny koszt godzinowy.
"""
import os
import boto3

eks = boto3.client("eks")


def handler(event, context):
    clusters = os.environ["CLUSTER_NAMES"].split(",")
    node_group = os.environ["NODE_GROUP_NAME"]

    for cluster in clusters:
        cluster = cluster.strip()
        if not cluster:
            continue
        print(f"Scaling node group '{node_group}' in cluster '{cluster}' to 0")
        eks.update_nodegroup_config(
            clusterName=cluster,
            nodegroupName=node_group,
            scalingConfig={"minSize": 0, "desiredSize": 0, "maxSize": 1},
        )
        print(f"Cluster '{cluster}' node group scaled to 0")

    return {"status": "ok", "clusters": clusters}
