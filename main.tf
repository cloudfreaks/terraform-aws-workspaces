data "aws_iam_policy_document" "workspaces" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workspaces_defaultrole" {
  name               = "workspaces_DefaultRole"
  assume_role_policy = data.aws_iam_policy_document.workspaces.json
}

resource "aws_iam_role_policy_attachment" "ws_service_access" {
  role       = aws_iam_role.workspaces_defaultrole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "ws_selfservice_access" {
  role       = aws_iam_role.workspaces_defaultrole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "aws_kms_key" "workspaces_kms" {
  count                   = var.create_volume_encryption_key ? 1 : 0
  description             = "Workspaces KMS"
  deletion_window_in_days = 7
  tags                    = module.this.tags
}

resource "aws_kms_alias" "workspaces_kms_alias" {
  count         = var.create_volume_encryption_key ? 1 : 0
  name          = "alias/gc/workspaces"
  target_key_id = aws_kms_key.workspaces_kms[*].key_id
}

locals {
  users_bundles = length(var.directory_user_names) == length(var.bundle_ids) ? zipmap(var.directory_user_names, var.bundle_ids) : zipmap(var.directory_user_names, [for s in var.directory_user_names : var.bundle_ids[0]])
}

resource "aws_workspaces_directory" "ws_directory" {
  directory_id = var.directory_id
  subnet_ids   = var.workspaces_subnet_ids

  tags = module.this.tags

  self_service_permissions {
    change_compute_type  = true
    increase_volume_size = true
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = true
  }

  workspace_access_properties {
    device_type_android    = "ALLOW"
    device_type_chromeos   = "ALLOW"
    device_type_ios        = "ALLOW"
    device_type_linux      = "ALLOW"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "ALLOW"
  }

  workspace_creation_properties {
    enable_internet_access              = true
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ws_service_access,
    aws_iam_role_policy_attachment.ws_selfservice_access
  ]
}

resource "aws_workspaces_workspace" "workspaces" {
  for_each = local.users_bundles

  directory_id                   = var.directory_id
  bundle_id                      = each.value
  user_name                      = each.key
  root_volume_encryption_enabled = var.root_volume_encryption_enabled
  user_volume_encryption_enabled = var.user_volume_encryption_enabled
  volume_encryption_key          = var.create_volume_encryption_key ? aws_kms_key.workspaces_kms[0].arn : ""

  dynamic "workspace_properties" {
    for_each = var.workspace_properties[*]
    content {
      compute_type_name                         = try(workspace_properties.value[each.key].compute_type_name, null)
      user_volume_size_gib                      = try(workspace_properties.value[each.key].user_volume_size_gib, null)
      root_volume_size_gib                      = try(workspace_properties.value[each.key].root_volume_size_gib, null)
      running_mode                              = try(workspace_properties.value[each.key].running_mode, "AUTO_STOP")
      running_mode_auto_stop_timeout_in_minutes = try(workspace_properties.value[each.key].running_mode_auto_stop_timeout_in_minutes, 60)
    }
  }

  tags = merge(
    module.this.tags,
    {
      ldap_owner = each.key
      bundle     = each.value
    },
  )


  depends_on = [
    aws_iam_role.workspaces_defaultrole,
    aws_workspaces_directory.ws_directory
  ]
}

