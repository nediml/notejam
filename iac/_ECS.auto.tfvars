# ECS WORKER

worker_cpu = {
    dev  = 256
    prod = 512
}
worker_memory = {
    dev  = 512
    prod = 1024
}
worker_port = {
    dev  = 8000
    prod = 8000
}


# DEPLOYMENT

# Min healthy ecs tasks during deployment
worker_deployment_min_healthy = {
    dev  = 0
    prod = 100
}
# Max healthy ecs tasks during deployment
worker_deployment_max_healthy = {
    dev  = 100
    prod = 200
}
# Time (in secs) to wait after ecs task startup
# before starting to run health checks on it
worker_health_check_grace_period = {
    dev  = 0
    prod = 30
}

worker_images_to_keep = {
    dev  = 5
    prod = 20
}


# PUBLIC ACCESSIBILITY

# Change of this option in most cases 
# will require change in vpc/subnet settings
worker_assign_public_ip = {
    dev  = false
    prod = false
}