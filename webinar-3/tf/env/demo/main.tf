module "front" {
  source = "../../rgs/front"
}

module "app" {
  source = "../../rgs/app"
}

module "db" {
  source = "../../rgs/db"
}

module "ping" {
  source = "../../rgs/ping"
  env = "demo"
  location = "northeurope"
}
