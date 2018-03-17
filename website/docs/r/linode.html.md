---
layout: "linode"
page_title: "Linode: linode_linode"
sidebar_current: "docs-linode-resource-linode"
description: |-
  Manages a Linode instance.
---

# linode\_linode

Provides a Linode instance resource.  This can be used to create,
modify, and delete Linodes. For more information, see [Getting Started with Linode](https://linode.com/docs/getting-started/)
and [Linode APIv3 docs](https://www.linode.com/api).

Linodes also support `[provisioning](/docs/provisioners/index.html).

## Example Usage

The following example shows how one might use this resource to configure a Linode instance.

```hcl
resource "linode_linode" "web" {
	image = "Ubuntu 14.04 LTS"
	kernel = "Latest 64 bit"
	region = "Dallas, TX, USA"
	size = 2048
	ssh_key = "ssh-rsa AAAA...Gw== user@example.local"
	root_password = "terraform-test"

	name = "foobaz"
	group = "integration"
	status = "on"
	swap_size = 256
	private_networking = true

	// ip_address = "8.8.8.8"
	// plan_storage = 24576
	// plan_storage_utilized = 24576
	// private_ip_address = "192.168.10.50"
}
```

## Argument Reference

The following arguments are supported:

* `image` - (Required) The image to use when creating the linode.  This can also be an ImageID.  *Changing `image` forces the creation of a new Linode.*

* `kernel` - (Required) The kernel to start the linode with. Specify `"Latest 64-bit"` or `"Latest 32-bit"` for the most recent Linode provided kernel.

* `region` - (Required) The region that the linode will be created in *Changing `region` forces the creation of a new Linode.*

* `size` - (Required) The Linode plan size in terms of MB of RAM (e.g. 2048, 4096, 8192.  A plan will be chosen that matches this amount.)

* `ssh_key` - (Required) The full text of the public key to add to the root user. *Changing `ssh_key` forces the creation of a new Linode.*

* `root_password` - (Required) The initial password for the `root` user account. *Changing `ssh_key` forces the creation of a new Linode.*

  A `root_password` is required by Linode APIv3. You'll likely want to modify this on the server during provisioning and then disable password logins in favor of SSH keys.

- - -

* `name` - (Optional) The name of the Linode.

* `group` - (Optional) The group of the Linode.

* `private_networking` - (Optional) A boolean controlling whether or not to enable private networking. It can be enabled on an existing Linode but it can't be disabled.

* `helper_distro` - (Optional) A boolean used to enable the Distro Filesystem helper.   This corrects fstab and inittab/upstart entries depending on the distribution or kernel being booted. You want this unless you're providing your own kernel.

* `manage_private_ip_automatically` - (Optional) A boolean used to enable the Network Helper.  This automatically creates network configuration files for your distro and places them into your filesystem. Enabling this in a change will reboot your Linode.

* `disk_expansion` - (Optional) A boolean that when true will automatically expand the root volume if the size of the Linode plan is increased.  Setting this value will prevent downsizing without manually shrinking the volume prior to decreasing the size.

* `swap_size` - (Optional) Sets the size of the swap partition on a Linode in MB.  At this time, this cannot be modified by Terraform after initial provisioning.  If manually modified via the Web GUI, this value will reflect such modification.  This value can be set to 0 to create a Linode without a swap partition.  Defaults to 256.


## Attributes

This resource exports the following attributes:

* `status` - A string representing the power status of the Linode (`"on"`, `"off"`)

* `ip_address` - A string containing the Linode's public IP address.

* `private_ip_address` - A string containing the Linode's private IP address if private networking is enabled.

* `plan_storage` - An integer reflecting the size of the Linode's storage capacity in MB, based on the Linode plan.

* `plan_storage_utilized` - An integer sum of the size of all the Linode's disks, given in MB.


## Import

Linodes can be imported using the Linode `id`, e.g.

```
terraform import linode_linode.mylinode 1234567
```