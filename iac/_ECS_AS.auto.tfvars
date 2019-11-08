# AUTOSCALING

worker_autoscaling_min_count = {
    dev  = 0
    prod = 3
}
worker_autoscaling_max_count = {
    dev  = 2
    prod = 6
}


# SCALE UP

# in percentange
worker_autoscaling_cpu_high_threshold = {
    dev  = 80
    prod = 60
}
# in seconds
worker_autoscaling_cpu_high_period = {
    dev  = 60
    prod = 60
}
worker_autoscaling_cpu_high_period_counts = {
    dev  = 2
    prod = 2
}
# Time (in secs) between scaling activities
worker_autoscaling_up_cooldown = {
    dev  = 60
    prod = 60
}
# Number of instances to add
worker_autoscaling_up_adjustment = {
    dev  = 1
    prod = 2
}


# SCALE DOWN

worker_autoscaling_cpu_low_threshold = {
    dev  = 10
    prod = 10
}
worker_autoscaling_cpu_low_period = {
    dev  = 60
    prod = 60
}
worker_autoscaling_cpu_low_period_counts = {
    dev  = 2
    prod = 2
}
worker_autoscaling_down_cooldown = {
    dev  = 1
    prod = 1
}
worker_autoscaling_down_adjustment = {
    dev  = -1
    prod = -1
}