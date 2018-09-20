package linode

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/linode/linodego"
)

func dataSourceLinodeInstanceType() *schema.Resource {
	return &schema.Resource{
		Read: dataSourceLinodeInstanceTypeRead,

		Schema: map[string]*schema.Schema{
			"label": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
			"disk": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"class": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
			"price": &schema.Schema{
				Type:     schema.TypeList,
				MaxItems: 1,
				Computed: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"hourly": {
							Type:     schema.TypeFloat,
							Computed: true,
						},
						"monthly": {
							Type:     schema.TypeFloat,
							Computed: true,
						},
					},
				},
			},
			"addons": &schema.Schema{
				Type:     schema.TypeList,
				MaxItems: 1,
				Computed: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"backups": {
							Type:     schema.TypeList,
							MaxItems: 1,
							Computed: true,
							Elem: &schema.Resource{
								Schema: map[string]*schema.Schema{
									"price": &schema.Schema{
										Type:     schema.TypeList,
										MaxItems: 1,
										Computed: true,
										Elem: &schema.Resource{
											Schema: map[string]*schema.Schema{
												"hourly": {
													Type:     schema.TypeFloat,
													Computed: true,
												},
												"monthly": {
													Type:     schema.TypeFloat,
													Computed: true,
												},
											},
										},
									},
								},
							},
						},
					},
				},
			},
			"network_out": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"memory": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"transfer": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
			"vcpus": &schema.Schema{
				Type:     schema.TypeInt,
				Computed: true,
			},
		},
	}
}

func dataSourceLinodeInstanceTypeRead(d *schema.ResourceData, meta interface{}) error {
	client := meta.(*linodego.Client)

	types, err := client.ListTypes(context.Background(), nil)
	if err != nil {
		return fmt.Errorf("Error listing ranges: %s", err)
	}

	reqType := d.Get("id").(string)

	for _, r := range types {
		if r.ID == reqType {
			d.SetId(r.ID)
			d.Set("label", r.Label)
			d.Set("disk", r.Disk)
			d.Set("memory", r.Memory)
			d.Set("vcpus", r.VCPUs)
			d.Set("network_out", r.NetworkOut)
			d.Set("transfer", r.Transfer)
			d.Set("class", r.Class)
			d.Set("price.0.hourly", r.Price.Hourly)
			d.Set("price.0.monthly", r.Price.Monthly)
			d.Set("addons.0.backups.0.price.0.hourly", r.Addons.Backups.Price.Hourly)
			d.Set("addons.0.backups.0.price.0.monthly", r.Addons.Backups.Price.Monthly)
			return nil
		}
	}

	d.SetId("")

	return fmt.Errorf("Instance Type %s was not found", reqType)
}
