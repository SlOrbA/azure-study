module "front" {
  source = "../../rgs/front"
}

module "app" {
  source = "../../rgs/app"
}

module "db" {
  source = "../../rgs/db"
}
