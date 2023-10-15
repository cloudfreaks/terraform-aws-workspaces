output "ids" {
  value       = [
    for item in aws_workspaces_workspace.workspaces: item.id
  ]
  description = "The workspaces ID"
}

output "ip_addresses" {
  value       = [
    for item in aws_workspaces_workspace.workspaces: item.ip_address
  ]
  description = "IP address of the WorkSpace"
}

output "computer_names" {
  value       = [
    for item in aws_workspaces_workspace.workspaces: item.computer_name
  ]
  description = "The name of the WorkSpace, as seen by the operating system"
}

output "states" {
  value       = [
    for item in aws_workspaces_workspace.workspaces: item.state
  ]
  description = "The operational state of the WorkSpace"
}
