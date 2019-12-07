data "template_file" "json_config" {
  vars {
    rds_vpc_ids = "${jsonencode(var.rds_vpc_ids)}"
  }

  template = <<INPUT
{ "detail": {"vpc_ids": $${rds_vpc_ids} }}
INPUT
}  

data "null_data_source" "lambda_file" {
  inputs {
    filename = "${substr("${path.module}/files/rds/consulRdsCreateService.zip", length(path.cwd) + 1, -1)}"
  }
}

resource "aws_iam_role" "consul_rds" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "xray_wo" {
  role       = "${aws_iam_role.consul_rds.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "vpc_exec" {
  role       = "${aws_iam_role.consul_rds.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ec2_ro" {
  role       = "${aws_iam_role.consul_rds.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "rds_ro" {
  role       = "${aws_iam_role.consul_rds.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ro" {
  role       = "${aws_iam_role.consul_rds.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = "${aws_iam_role.consul_rds.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "consulRdsCreateService" {
  filename         = "${data.null_data_source.lambda_file.outputs.filename}"
  function_name    = "consulRdsCreateService-${var.env}"
  role             = "${aws_iam_role.consul_rds.arn}"
  handler          = "consulRdsCreateService.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.null_data_source.lambda_file.outputs.filename}"))}"
  runtime          = "python2.7"
  timeout          = "60"

  vpc_config {
    subnet_ids         = ["${var.subnets}"]
    security_group_ids = ["${var.rds_sg}"]
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "rds_allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.consulRdsCreateService.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.consul_rds.arn}"
}

resource "aws_cloudwatch_event_rule" "consul_rds" {
  name                = "consulRdsCreateService-${var.env}"
  description         = "${var.env} Discover and Create RDS Services in Consul"
  schedule_expression = "rate(5 minutes)"
  role_arn            = "${aws_iam_role.consul_rds.arn}"
}

resource "aws_cloudwatch_event_target" "consul_rds" {
  target_id = "consulRdsCreateService-${var.env}"
  rule      = "${aws_cloudwatch_event_rule.consul_rds.name}"
  arn       = "${aws_lambda_function.consulRdsCreateService.arn}"
  input     = "${data.template_file.json_config.rendered}"
}
