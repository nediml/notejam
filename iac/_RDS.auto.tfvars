# RDS 

# database name for the db application will write to
rds_database_name = {
    dev  = "notejam"
    prod = "notejam"
}
rds_master_username = {
    dev  = "notejam_dev"
    prod = "notejam_prod"
}
rds_storage_encrypted = {
    dev  = false
    prod = true
}

# BACKUP

# Time (in days) to keeps backups
rds_backup_retention_period = {
    dev  = 7
    prod = 30
}
rds_preferred_backup_window = {
    dev  = "07:00-09:00"
    prod = "07:00-09:00"
}
rds_deletion_protection = {
    dev  = false
    prod = true
}


# AVAILABILITY

rds_port = {
    dev  = 3306
    prod = 3306
}
rds_min_capacity = {
    dev  = 2
    prod = 4
}
rds_max_capacity = {
    dev  = 2
    prod = 10
}
rds_auto_pause = {
    dev  = true
    prod = false
}
rds_seconds_until_auto_pause = {
    dev  = 300
    prod = 0
}

