locals {
  subnet_cidrs = concat(var.public_subnet_cidrs, var.private_subnet_cidrs)
  # Convert IPv4 network starts to integers to validate containment and overlap.
  subnet_starts = [for cidr in local.subnet_cidrs : sum([
    for index, octet in split(".", cidrhost(cidr, 0)) : tonumber(octet) * pow(256, 3 - index)
  ])]
  subnet_ends = [for index, cidr in local.subnet_cidrs : local.subnet_starts[index] + pow(2, 32 - tonumber(split("/", cidr)[1])) - 1]
  vpc_start   = sum([for index, octet in split(".", cidrhost(var.vpc_cidr, 0)) : tonumber(octet) * pow(256, 3 - index)])
  vpc_end     = local.vpc_start + pow(2, 32 - tonumber(split("/", var.vpc_cidr)[1])) - 1
}
