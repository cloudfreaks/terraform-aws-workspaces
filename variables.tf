variable "directory_id" {
  type        = string
  description = "(Required) The ID of the directory for the WorkSpace."
}

variable "workspaces_subnet_ids" {
  type        = list(string)
  description = <<EOF
  (Optional) The identifiers of the subnets where the workspaces will be deployed.
  If you're using AWS Managed Microsoft AD or Simple AD, your directory can be in dedicated private subnets,
  as long as they both have access to the subnets defined here. 
  Important: not all Availability zones are enabled for workspaces, see https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html
  Set this variable if you have strict requirements for where your workspaces will be deployed, otherwise the module will randomly assign 2 *valid* subnets.
  EOF
  default     = null
}

variable "bundle_ids" {
  type        = list(string)
  description = <<EOF
  (Required) The list of bundles IDs for each user defined into directory_user_names.
  If the number of IDs doesn't match the number of directory_user_names, or just a single bundle ID is provided, all users will get the same bundle
  EOF
}

variable "directory_user_names" {
  type        = list(string)
  description = <<EOF
    (Required) The list of user names for the WorkSpace. Each user name must exist in the directory for the WorkSpace.
    This module will create a workspace for each username, matching each user with the bundle_id(s) provided as list provided the number of the two lists mtaches.
    If only one bundle_id is provided, or the number doesn't match, all users will get the first bundle ID provided.
  EOF
}

variable "root_volume_encryption_enabled" {
  type        = bool
  description = <<EOF
  (Optional) Indicates whether the data stored on the root volume is encrypted.
  IMPORTANT: WORKSPACES LAUNCHED WITH ROOT VOLUME ENCRYPTION ENABLED MIGHT TAKE UP TO AN HOUR TO PROVISION.
  Defaults to false.
  EOF
  default     = false
}

variable "user_volume_encryption_enabled" {
  type        = bool
  description = "(Optional) Indicates whether the data stored on the user volume is encrypted. Defaults to false."
  default     = false
}

variable "create_volume_encryption_key" {
  type        = bool
  description = <<EOF
  Create a SYMMETRIC AWS KMS customer master key (CMK) to encrypt data stored on your WorkSpace.
  If root_volume_encryption_enabled or user_volume_encryption_enabled are set to true while this variable is set to false, the default KMS will be used.
  Defaults to false.
  EOF
  default     = false
}

variable "workspace_properties" {
  description = <<EOF
  Workspace properties configuration. Each user into the directory_user_names list has one or more bundles ID set into the bundle_ids list,
  for each user/bundle you can (re)define some specific values, such as the compute type or volumes size.
  If none of these parameters are set, Workspace will use the defaults bundle settings (https://aws.amazon.com/workspaces/features/#Amazon_WorkSpaces_Bundles).
  If running_mode isn't set it defaults to AUTO_STOP (you can set it to ALWAYS_ON), if the running_mode_auto_stop_timeout_in_minutes isn't set it defaults to 60 (minutes).
  See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_workspace for more info.
  
  In order to set these values, you need to create a map with the user as key and these parameters as values, for example:
  
  workspace_properties = {
    "Administrator" = {
      "running_mode" = "AUTO_STOP"
    }
    "another.user" = {
      "user_volume_size_gib"                      = 100
      "running_mode"                              = "ALWAYS_ON"
      "running_mode_auto_stop_timeout_in_minutes" = 60
    }
  }
  EOF

  type = map(object({
    compute_type_name                         = optional(string)
    user_volume_size_gib                      = optional(number)
    root_volume_size_gib                      = optional(number)
    running_mode                              = optional(string)
    running_mode_auto_stop_timeout_in_minutes = optional(number)
  }))
  
  default = {}
}
