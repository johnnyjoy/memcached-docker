group "default" {
  targets = ["micro", "slim", "tls", "full"]
}

target "micro" {
  context = "."
  dockerfile = "Dockerfile"
  target = "micro"
  tags = [
    "tigersmile/memcached:1.6.38-micro",
    "tigersmile/memcached:micro"
  ]
  platforms = [
    "linux/386",
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64/v8",
    "linux/ppc64le",
    "linux/s390x"
  ]
  args = {
    VERSION = "1.6.38"
  }
}

target "slim" {
  context = "."
  dockerfile = "Dockerfile"
  target = "slim"
  tags = [
    "tigersmile/memcached:1.6.38-slim",
    "tigersmile/memcached:slim"
  ]
  platforms = [
    "linux/386",
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64/v8",
    "linux/ppc64le",
    "linux/s390x"
  ]
  args = {
    VERSION = "1.6.38"
  }
}

target "tls" {
  context = "."
  dockerfile = "Dockerfile"
  target = "tls"
  tags = [
    "tigersmile/memcached:1.6.38-tls",
    "tigersmile/memcached:tls"
  ]
  platforms = [
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64/v8",
    "linux/ppc64le",
    "linux/s390x"
  ]
  args = {
    VERSION = "1.6.38"
  }
}

target "full" {
  context = "."
  dockerfile = "Dockerfile"
  target = "full"
  tags = [
    "tigersmile/memcached:1.6.38",
    "tigersmile/memcached:latest"
  ]
  platforms = [
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64/v8",
    "linux/ppc64le",
    "linux/s390x"
  ]
  args = {
    VERSION = "1.6.38"
  }
}
