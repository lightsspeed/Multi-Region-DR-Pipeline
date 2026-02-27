terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default Provider (Fallthrough)
provider "aws" {
  region = var.primary_region
  default_tags {
    tags = {
      Project     = "DR-Pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Primary Region
provider "aws" {
  region = var.primary_region
  alias  = "primary"

  default_tags {
    tags = {
      Project     = "DR-Pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Secondary Region
provider "aws" {
  region = var.secondary_region
  alias  = "secondary"

  default_tags {
    tags = {
      Project     = "DR-Pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
