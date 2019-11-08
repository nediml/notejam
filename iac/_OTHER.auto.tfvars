# Region where all resources will be provisioned
region = "eu-west-1"


# ROUTE53 

dns_zone = "nedim.online."

ssl_certificate_arn = {
    dev =  "arn:aws:acm:eu-west-1:266794412268:certificate/b4fcda8b-394e-46aa-8a7d-894324f44522"
    prod = ""
}

# GITLAB

# Gitlab project ID on gitlab server
gitlab_project_id  = "14718861"

