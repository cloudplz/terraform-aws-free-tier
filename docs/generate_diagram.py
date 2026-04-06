#!/usr/bin/env python3
"""Generate architecture diagram for terraform-aws-free-tier module."""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda, EC2
from diagrams.aws.database import Aurora, Dynamodb, RDSPostgresqlInstance, ElastiCache
from diagrams.aws.integration import SNS, SQS, EventbridgeScheduler, StepFunctions
from diagrams.aws.ml import Bedrock
from diagrams.aws.network import APIGateway, CloudFront, InternetGateway
from diagrams.aws.security import Cognito, IAM, SecretsManager
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch, CloudwatchAlarm
from diagrams.aws.cost import Budgets
from diagrams.onprem.client import Users

# ── Edge styles ────────────────────────────────────────────────────
EDGE_HTTPS  = Edge(color="darkorange", style="bold", label="HTTPS")
EDGE_CDN    = Edge(color="deepskyblue", style="bold")
EDGE_OAC    = Edge(color="deepskyblue", style="dashed", label="OAC (sigv4)")
EDGE_AUTH   = Edge(color="blue", style="dashed", label="auth")
EDGE_SG_PG  = Edge(color="firebrick", style="dotted", label="SG :5432")
EDGE_SG_VAL = Edge(color="gold4", style="dotted", label="SG :6379")
EDGE_EVENT  = Edge(color="mediumpurple", style="dashed")
EDGE_ALERT  = Edge(color="red", style="dashed", label="alert")
EDGE_SSH    = Edge(color="dimgray", label="SSH / HTTP")

GRAPH_ATTR = {
    "pad": "0.5",
    "nodesep": "0.6",
    "ranksep": "1.2",
    "dpi": "100",
}

with Diagram(
    name="AWS Free-Tier Infrastructure — terraform-aws-free-tier",
    filename="architecture",
    outformat=["png"],
    show=False,
    direction="TB",
    graph_attr=GRAPH_ATTR,
):

    users = Users("Users / Internet")

    # ── CDN & Storage ──────────────────────────────────────────────
    with Cluster("Storage & CDN"):
        cf  = CloudFront("CloudFront\nPriceClass_100")
        s3  = S3("S3 Bucket\n(SSE-S3, no versioning)")
        ddb = Dynamodb("DynamoDB\n25 RCU / 25 WCU\npk + sk composite")

    users >> EDGE_CDN >> cf >> EDGE_OAC >> s3

    # ── Identity ───────────────────────────────────────────────────
    with Cluster("Authentication"):
        cognito = Cognito("Cognito User Pool\nHosted UI\n(SRP + refresh)")

    # ── Serverless Compute ─────────────────────────────────────────
    with Cluster("Serverless Compute"):
        apigw = APIGateway("API Gateway\nHTTP API (v2)\nGET /")
        lam   = Lambda("Lambda\nNode.js 22.x\n128 MB")
        eb    = EventbridgeScheduler("EventBridge\nScheduler\n(every 5 min)")
        sfn   = StepFunctions("Step Functions\nStandard")

    users >> EDGE_HTTPS >> apigw
    cognito >> EDGE_AUTH >> apigw
    apigw >> Edge(color="darkorange", label="proxy") >> lam
    eb   >> EDGE_EVENT >> lam
    sfn  >> EDGE_EVENT >> lam

    # ── VPC ────────────────────────────────────────────────────────
    with Cluster("VPC 10.0.0.0/16  (No NAT Gateway)"):
        igw = InternetGateway("Internet Gateway")

        with Cluster("Public Subnets  (2-4 AZs)"):
            ec2 = EC2("EC2 t4g.micro\nAmazon Linux 2023\nnginx")

        with Cluster("Private Subnets  (2-4 AZs)"):
            rds    = RDSPostgresqlInstance("RDS PostgreSQL 17\ndb.t4g.micro\n20 GB gp2")
            aurora = Aurora("Aurora Serverless v2\nPostgreSQL 16.6\n0.5-4 ACU")
            cache  = ElastiCache("ElastiCache Valkey 8\ncache.t3.micro")

        users >> EDGE_SSH >> igw >> ec2
        ec2 >> EDGE_SG_PG  >> rds
        ec2 >> EDGE_SG_PG  >> aurora
        ec2 >> EDGE_SG_VAL >> cache

    # ── Messaging ──────────────────────────────────────────────────
    with Cluster("Messaging & Alerts"):
        sqs_main = SQS("SQS Main Queue\n(24 h retention)")
        sqs_dlq  = SQS("SQS DLQ\n(14 day retention)")
        sns      = SNS("SNS Topic")

    sqs_main >> Edge(color="red", label="redrive (3x)") >> sqs_dlq

    # ── Observability ──────────────────────────────────────────────
    with Cluster("Observability & Governance"):
        cw_logs  = Cloudwatch("CloudWatch Logs\n(app + lambda)")
        cw_alarm = CloudwatchAlarm("CW Alarm\nEC2 CPU > 80%")
        budget   = Budgets("Budgets\nzero-spend ($0.01)")

    cw_alarm >> EDGE_ALERT >> sns
    budget   >> EDGE_ALERT >> sns

    # ── AI ─────────────────────────────────────────────────────────
    bedrock = Bedrock("Bedrock\nInvocation Logging")

    # ── Security & Secrets ─────────────────────────────────────────
    with Cluster("Security"):
        iam     = IAM("IAM Roles\nEC2 · Lambda · Scheduler\nStep Functions · Bedrock")
        secrets = SecretsManager("Secrets Manager\nRDS · Aurora · ElastiCache\n(ephemeral passwords)")

    # ── Cross-cluster connections ──────────────────────────────────
    secrets - Edge(style="dotted", color="seagreen") - rds
    secrets - Edge(style="dotted", color="seagreen") - aurora
    secrets - Edge(style="dotted", color="seagreen") - cache
