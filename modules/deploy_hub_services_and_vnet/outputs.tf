output "hub_vnet_resource_id" {
  value = module.hub_vnet.resource_id
}

output "route_server_resource_id" {
  value = module.create_route_server.resource_id
}

output "route_server_ips" {
  value = module.create_route_server.resource.virtual_router_ips
}