provider "aws" {
	region = "ap-south-1"
	profile = "default"
	}

resource "aws_s3_bucket" "task-1-s3-bucket" {
  bucket = "task-1-s3-bucket"
  acl    = "public-read"
  versioning {
  	enabled = true
  }

  tags = {
    Name        = "task-1-s3-bucket"
  }
  provisioner "local-exec" {
        command     = "wget https://raw.githubusercontent.com/Harishankar4274/HMC_Task-1/master/images/Harishankar_Dubey.png > /root/HMC_Task-1/s3_cloudfront_launch/certificate.png"
    }
provisioner "local-exec" {
        when        =   destroy
        command     =   "echo Y | rm -rf /root/HMC_Task-1/s3_cloudfront_launch/certificate.png"
    }
}

resource "aws_s3_bucket_object" "image-upload" {

	depends_on = [
		aws_s3_bucket.task-1-s3-bucket
	]

  bucket = "task-1-s3-bucket"
  key    = "certificate.jpeg"
  source = "/root/HMC_Task-1/s3_cloudfront_launch/Harishankar_Dubey.png.1"
  acl 	 = "public-read"
  content_type = "image/jpeg"
 }

////cloudfront

variable "var1" {default = "S3-"}
locals {
    s3_origin_id = "${var.var1}${aws_s3_bucket.task-1-s3-bucket.bucket}"
    image_url = "${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_bucket_object.image-upload.key}"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id
        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
       min_ttl = 0
       default_ttl = 3600
       max_ttl = 86400
      compress = true
        viewer_protocol_policy = "allow-all"
    }
enabled             = true
origin {
        domain_name = aws_s3_bucket.task-1-s3-bucket.bucket_domain_name
        origin_id   = local.s3_origin_id
    }
restrictions {
        geo_restriction {
        restriction_type = "whitelist"
        locations = ["IN"]
        }
    }
viewer_certificate {
        cloudfront_default_certificate = true
    }
/*
connection {
type = "ssh"
user = "ec2-user"
private_key = file("/root/HMC_Task-1/keypair/new-key-pair.pem")
host = aws_instance.task_1_instance.public_ip	
}


provisioner "remote-exec" {
	inline = [
	"sudo su << EOF",
	"echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.image-upload.key}'>\"  >> /var/www/html/index.php",
	"EOF",
	]
}

provisioner "local-exec" {
		command = "firefox ${aws_instance.web_server.public_ip}"
	}
*/
}

output "cloudfront_object_domain_name" {
	value = aws_cloudfront_distribution.s3_distribution.domain_name
}
