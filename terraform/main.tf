# Networking Configuration - Primary
module "networking_primary" {
  source = "./modules/networking"

  providers = {
    aws = aws.primary
  }

  region_name = var.primary_region
  vpc_cidr    = var.vpc_cidr_primary
}

# Networking Configuration - Secondary
module "networking_secondary" {
  source = "./modules/networking"

  providers = {
    aws = aws.secondary
  }

  region_name = var.secondary_region
  vpc_cidr    = var.vpc_cidr_secondary
}

# Storage Configuration
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "storage" {
  source = "./modules/storage"

  providers = {
    aws           = aws.primary
    aws.secondary = aws.secondary
  }

  project_name          = var.project_name
  primary_bucket_name    = "${var.project_name}-primary-${random_string.suffix.result}"
  secondary_bucket_name  = "${var.project_name}-secondary-${random_string.suffix.result}"
  random_suffix          = random_string.suffix.result
}

# Database Configuration
module "database" {
  source = "./modules/database"

  providers = {
    aws           = aws.primary
    aws.secondary = aws.secondary
  }

  project_name              = var.project_name
  db_password               = var.db_password
  primary_vpc_id            = module.networking_primary.vpc_id
  primary_private_subnets   = module.networking_primary.private_subnets
  primary_rds_sg_id         = module.networking_primary.rds_sg_id
  secondary_vpc_id          = module.networking_secondary.vpc_id
  secondary_private_subnets = module.networking_secondary.private_subnets
  secondary_rds_sg_id       = module.networking_secondary.rds_sg_id
  random_suffix             = random_string.suffix.result
}

# Compute Configuration - Primary
module "compute_primary" {
  source = "./modules/compute"

  providers = {
    aws = aws.primary
  }

  region_name     = var.primary_region
  vpc_id          = module.networking_primary.vpc_id
  public_subnets  = module.networking_primary.public_subnets
  private_subnets = module.networking_primary.private_subnets
  ec2_sg_id       = module.networking_primary.ec2_sg_id
  alb_sg_id       = module.networking_primary.alb_sg_id
  db_endpoint     = module.database.primary_endpoint
  db_password     = var.db_password
  random_suffix   = random_string.suffix.result
}

# Compute Configuration - Secondary
module "compute_secondary" {
  source = "./modules/compute"

  providers = {
    aws = aws.secondary
  }

  region_name     = var.secondary_region
  vpc_id          = module.networking_secondary.vpc_id
  public_subnets  = module.networking_secondary.public_subnets
  private_subnets = module.networking_secondary.private_subnets
  ec2_sg_id       = module.networking_secondary.ec2_sg_id
  alb_sg_id       = module.networking_secondary.alb_sg_id
  db_endpoint     = module.database.secondary_endpoint
  db_password     = var.db_password
  random_suffix   = random_string.suffix.result
}

# DNS & Failover Configuration
module "dns" {
  source = "./modules/dns"

  providers = {
    aws = aws.primary
  }

  dns_name              = var.dns_domain
  primary_alb_dns       = module.compute_primary.alb_dns_name
  primary_alb_zone_id   = module.compute_primary.alb_zone_id
  secondary_alb_dns     = module.compute_secondary.alb_dns_name
  secondary_alb_zone_id = module.compute_secondary.alb_zone_id
}

module "monitoring_primary" {
  source = "./modules/monitoring"
  providers = { aws = aws.primary }

  region_name       = var.primary_region
  alb_arn_suffix    = module.compute_primary.alb_arn_suffix
  alb_tg_arn_suffix = module.compute_primary.alb_tg_arn_suffix
  db_instance_id    = module.database.primary_instance_id
  is_primary        = true
  project_name      = var.project_name
  random_suffix     = random_string.suffix.result
}

module "monitoring_secondary" {
  source = "./modules/monitoring"
  providers = { aws = aws.secondary }

  region_name       = var.secondary_region
  alb_arn_suffix    = module.compute_secondary.alb_arn_suffix
  alb_tg_arn_suffix = module.compute_secondary.alb_tg_arn_suffix
  db_instance_id    = module.database.secondary_instance_id
  is_primary        = false
  project_name      = var.project_name
  random_suffix     = random_string.suffix.result
}

/*
# Resilience Hub Bonus
module "resilience_hub" {
  source = "./resilience_hub"
  providers = { aws = aws.primary }
  project_name = var.project_name
}
*/
