output "rikconfig" {
  value = <<YAML
cluster:
  name: ${local.cluster_name}
  server: http://${openstack_compute_floatingip_v2.master_static.address}:5000/
  YAML
}