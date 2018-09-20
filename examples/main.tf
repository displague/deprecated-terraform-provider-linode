data "linode_regions" "us-east" {}
data "linode_instance_types" "g6-nanode-1" {}
data "linode_image" "linode/ubuntu18.04" {}

resource "linode_nodebalancer" "foo-nb" {
  label                = "${random_pet.project.id}"
  region               = "${var.region}"
  client_conn_throttle = 0

  # group              = "foo"
}

resource "linode_nodebalancer_config" "foo-https" {
  port            = 443
  nodebalancer_id = "${linode_nodebalancer.foo-nb.id}"
  protocol        = "http"
  algorithm       = "roundrobin"
  stickiness      = "http_cookie"
  check           = "http_body"
  check_interval  = "90"
  check_timeout   = "10"
  check_attempts  = "3"
  check_path      = "/test"
  check_body      = "it works"
  check_passive   = true
  cipher_suite    = "recommended"

  # ssl_cert FUTURE pair with letsencrypt resource
  # ssl_key FUTURE pair with letsencrypt resource
  # https://opencredo.com/letsencrypt-terraform/
}

resource "linode_nodebalancer_config" "foo-http" {
  port            = 80
  nodebalancer_id = "${linode_nodebalancer.foo-nb.id}"
  protocol        = "http"
  algorithm       = "roundrobin"
  stickiness      = "http_cookie"
  check           = "http_body"
  check_interval  = "90"
  check_timeout   = "10"
  check_attempts  = "3"
  check_path      = "/test"
  check_body      = "it works"
  check_passive   = true
}

resource "linode_nodebalancer_node" "foo-http-www" {
  # LABEL becomes foo-80-www
  count           = "${var.nginx_count}"
  nodebalancer_id = "${linode_nodebalancer.foo-nb.id}"
  config_id       = "${linode_nodebalancer_config.foo-https.id}"
  label           = "${random_pet.project.id}_http_${var.nginx_count}"

  address = "${element(linode_instance.nginx.*.private_ip_address, count.index)}:80"
  weight  = 50
  mode    = "accept"
}

resource "linode_nodebalancer_node" "foo-https-www" {
  # LABEL becomes foo-80-www
  count           = "${var.nginx_count}"
  nodebalancer_id = "${linode_nodebalancer.foo-nb.id}"
  config_id       = "${linode_nodebalancer_config.foo-http.id}"
  label           = "${random_pet.project.id}_https_${var.nginx_count}"

  address = "${element(linode_instance.nginx.*.private_ip_address, count.index)}:80"
  weight  = 50
  mode    = "accept"
}

resource "linode_domain" "foo-com" {
  soa_email   = "${random_pet.project.id}@${substr(sha256(random_pet.project.id),0,8)}example.com"
  ttl_sec     = "30"
  expire_sec  = "30"
  refresh_sec = "30"
  domain      = "${random_pet.project.id}example.com"
  type = "master"

  # group              = "foo"
  # interesting that the bare address "@" could be set this way..
  # but terraform would have to do this behind the scenes
  # ip_address = "${linode_instance.haproxy-www.ipv4_address}"
}

resource "linode_domain_record" "A-root" {
  domain_id   = "${linode_domain.foo-com.id}"
  record_type = "A"
  name        = ""
  target      = "${linode_nodebalancer.foo-nb.ipv4}"
}

resource "linode_domain_record" "A-nginx" {
  count       = "${var.nginx_count}"
  domain_id   = "${linode_domain.foo-com.id}"
  name        = "${element(linode_instance.nginx.*.label, count.index)}"
  record_type = "A"
  target      = "${element(linode_instance.nginx.*.ip_address, count.index)}"
}

resource "linode_domain_record" "AAAA-root" {
  domain_id   = "${linode_domain.foo-com.id}"
  record_type = "AAAA"
  name        = ""
  target      = "${linode_nodebalancer.foo-nb.ipv6}"
}

resource "linode_domain_record" "CNAME-www" {
  domain_id   = "${linode_domain.foo-com.id}"
  record_type = "CNAME"
  name        = "www"
  target      = "${linode_domain.foo-com.domain}"
}

resource "linode_instance" "nginx" {
  count  = "${var.nginx_count}"
  label  = "${random_pet.project.id}-nginx-${count.index + 1}"

  group              = "foo"
  region             = "${linode_nodebalancer.foo-nb.region}"
  type               = "g6-nanode-1"
  private_ip = true
  
  disk {
    label = "boot"
    size = 3000 // @TODO(displague) howto do this "${linode_image["linode/ubuntu18.04"].size}"
    authorized_keys            = "${chomp(file(var.ssh_key))}"
    root_pass      = "${random_string.password.result}"
    image  = "linode/ubuntu18.04"
  }

  config {
    label = "nginx"
    kernel = "linode/latest-64bit"
    devices {
      sda = { disk_label = "boot" },
      sdb = { volume_id = "${element(linode_volume.nginx-vol.*.id, count.index)}" }
    }
  }

  provisioner "remote-exec" {
    inline = [
      # install nginx
      "export PATH=$PATH:/usr/bin",

      "apt-get -q update",
      "ls /dev/disk/by-id/",
      "mkfs /dev/disk/by-id/scsi-0Linode_Volume_nginx-vol-${count.index}",
      "mkdir -p /srv/www",
      "echo /dev/disk/by-id/scsi-0Linode_Volume_nginx-vol-${count.index} /srv/www ext4 defaults 0 2 | sudo tee -a /etc/fstab",
      "mount -a",
      "echo it works node ${count.index + 1} > /srv/www/index.html",
      "apt-get -q -y install nginx",
    ]
  }
}

resource "linode_volume" "nginx-vol" {
  count     = "${var.nginx_count}"
  region    = "${linode_nodebalancer.foo-nb.region}"
  size      = 10
  label     = "${random_pet.project.id}-vol-${count.index}"
}

resource "linode_volume" "simple-vol-lateattachment" {
  region    = "${linode_instance.simple.region}"
  size      = 10
  label     = "${random_pet.project.id}-simple"
  linode_id = "${linode_instance.simple.id}"

  connection {
    host = "${linode_instance.simple.ip_address}"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "timeout 180 sh -c 'while ! ls /dev/disk/by-id/scsi-0Linode_Volume_${self.label}; do sleep 1; done'",
      "sudo mkfs /dev/disk/by-id/scsi-0Linode_Volume_${self.label}",
      "mkdir -p /srv/www",
      "echo /dev/disk/by-id/scsi-0Linode_Volume_${self.label} /srv/www ext4 defaults 0 2 | sudo tee -a /etc/fstab",
      "mount -a",
      "echo it works, so simple > /srv/www/index.html",
    ]
  }
}

resource "linode_instance" "simple" {
  image  = "linode/ubuntu18.04"
  label  = "${random_pet.project.id}-simple"

  group              = "foo"
  region             = "${var.region}"
  type               = "g6-nanode-1"
  authorized_keys    = "${chomp(file(var.ssh_key))}"
  root_pass      = "${random_string.password.result}"

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "apt-get -q update",
      "echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections",
      "apt-get -q -y install unattended-upgrades nginx",
    ]
  }
}