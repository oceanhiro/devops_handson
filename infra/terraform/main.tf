//TODO:
// NATゲートウェイ
// 内部NWのデフォルトルートをNATゲートウェイにする
// インスタンス作成(web-app,db,ci)
// インスタンスにセキュリティグループ紐付け
//NEXT:
// リファクタリングする(module機能を使って再利用性を高める)
// 環境ごとの差分を吸収できるようにする
// tfstateをS3で管理できるようにする

variable "region" {
    default = "ap-northeast-1" 
}

provider "aws" {
    region     = "${var.region}" 
}

resource "aws_vpc" "devops_handson_vpc" {
    cidr_block           = "10.0.0.0/16" 
    instance_tenancy     = "default" 
    enable_dns_support   = "true" 
    enable_dns_hostnames = "false" 
    tags {
        Name = "devops_handson_vpc" 
    }
}

resource "aws_internet_gateway" "devops_handson_gw" {
    vpc_id = "${aws_vpc.devops_handson_vpc.id}" 
}

resource "aws_subnet" "public_a" {
    vpc_id            = "${aws_vpc.devops_handson_vpc.id}" 
    cidr_block        = "10.0.1.0/24" 
    availability_zone = "ap-northeast-1a" 
}

resource "aws_subnet" "private_a" {
    vpc_id            = "${aws_vpc.devops_handson_vpc.id}" 
    cidr_block        = "10.0.2.0/24" 
    availability_zone = "ap-northeast-1a" 
}

resource "aws_route_table" "public_route" {
    vpc_id = "${aws_vpc.devops_handson_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = "${aws_internet_gateway.devops_handson_gw.id}" 
    }
    tags {
        Name = "public_route"
    }
} 

resource "aws_route_table" "private_route" {
    vpc_id = "${aws_vpc.devops_handson_vpc.id}"
    tags {
        Name = "private_route"
    }
}

resource "aws_route_table_association" "public_a" {
    subnet_id      = "${aws_subnet.public_a.id}" 
    route_table_id = "${aws_route_table.public_route.id}" 
}

resource "aws_route_table_association" "private_a" {
    subnet_id      = "${aws_subnet.private_a.id}" 
    route_table_id = "${aws_route_table.private_route.id}" 
}

resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg"
  description = "for web app sg."
  vpc_id      = "${aws_vpc.devops_handson_vpc.id}"
}

// Allow any internal network flow.
resource "aws_security_group_rule" "ingress_any_any_self" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  type              = "ingress"
}

// Allow egress all
resource "aws_security_group_rule" "egress_all_all_all" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

// Allow TCP:80 (HTTP)
resource "aws_security_group_rule" "ingress_tcp_80_cidr" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

// Allow TCP:443 (HTTPS)
resource "aws_security_group_rule" "ingress_tcp_443_cidr" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

// Allow TCP:8080 (HTTP-ALT)
resource "aws_security_group_rule" "ingress_tcp_8080_cidr" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "for db sg."
  vpc_id      = "${aws_vpc.devops_handson_vpc.id}"
}

// Allow TCP:5432 (PostgreSQL)
resource "aws_security_group_rule" "ingress_tcp_5432_cidr" {
  security_group_id = "${aws_security_group.db_sg.id}"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  type              = "ingress"
}


//resource "aws_instance" "hello-terraform" {
//    ami           = "ami-29d1e34e" 
//    instance_type = "t2.micro" 
//    key_name      = "keypair_ocean_key.pem" 
//    vpc_security_group_ids = [
//        "${aws_security_group.admin.id}" 
//    ]
//    subnet_id = "${aws_subnet.public_a.id}" 
//    associate_public_ip_address = "true" 
//    root_block_device = {
//        volume_size = "8" 
//    }
//    tags {
//        Name = "hello-terraform" 
//    }
//}

//output "public ip of hello-terraform" {
//    value = "${aws_instance.hello-terraform.public.ip}" 
//}
