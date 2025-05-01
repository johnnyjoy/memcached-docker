# 🐳 memcached-docker

**A deep-optimized Memcached (1.6.38) Docker suite focused on stripping the server down to its absolute essentials—producing some of the smallest and most secure Memcached images available. Each variant is engineered to remove unnecessary features, binaries, and files, creating ultra-compact, scratch-based containers ready for production.**

**Built for:**

- ✅ **Maximum minimalism:** Images as small as ~124 KB (`amd64`).
- ✅ **No clutter:** Zero shell, zero OS—just Memcached.
- ✅ **Container-native configuration:** Full environment variable support (no CLI args required).
- ✅ **Variants:** `micro`, `slim`, `tls`, `full`—scale up or down to match your needs.

**Multi-arch support:**

| Architecture        | |
|---------------------|-----------------------------|
| `linux/386`         | ✅ |
| `linux/amd64`       | ✅ |
| `linux/arm/v6`      | ✅ |
| `linux/arm/v7`      | ✅ |
| `linux/arm64/v8`    | ✅ |
| `linux/ppc64le`     | ✅ |
| `linux/s390x`       | ✅ |


---

This aims to sound **sharp and purposeful** (like what Alpine and Distroless aim for) and explains both *what it is* and *why it exists*. Do you want to highlight any **specific use case** (like Kubernetes or serverless) more prominently too?
---

## 📌 Purpose

**Purpose:** This project’s core mission is to **shrink Memcached as much as possible** while keeping it **fast, secure, and flexible**—ideal for cloud, edge, and microservice environments.

- ✅ **Zero-config:** Fully operational out of the box with **environment variable support**.
- ✅ **Optimized builds:** From minimal (`micro`) to fully-featured (`full`).
- ✅ **Platform-agnostic:** Multi-architecture support (x86, ARM, etc.).

---

## 🚀 Why Tiny & Scratch-Based?

### 🔹 **Ultra-Small Image Size**

| Architecture       | Image Size        |
|--------------------|-------------------|
| `linux/amd64`      | 🚀 **123.97 KB** ✅ |
| `linux/386`        | 133.05 KB         |
| `linux/arm/v7`     | 132.77 KB         |
| `linux/arm/v6`     | 129.43 KB         |
| `linux/arm64/v8`   | 126.94 KB         |
| `linux/ppc64le`    | 135.63 KB         |
| `linux/s390x`      | 161.00 KB         |

✅ **~124 KB for `amd64`? That’s next-level lightweight.**

**Benefits:**

- 🚀 **Faster pulls & deploys:** Minimal size means near-instant startup—critical for CI/CD and edge.
- 🔒 **Smaller attack surface:** Fewer bits = fewer vulnerabilities.
- 🌍 **Low bandwidth/storage:** Ideal for constrained environments (IoT, microVMs, etc.).

---

### 🔹 **Scratch Base Advantages**

- 🧼 **Nothing extra:** `scratch` = no shell, no libc, no package manager—only Memcached itself.
- 🔐 **Locked down:** No way to `exec` or misuse the image—great for high-security setups.
- 🛠 **Predictable:** No hidden base layers; what you ship is exactly what runs.
- ✅ **Audit-friendly:** Minimal image = simpler compliance and auditing.

---

## 🚀 Image Variants

| **Image Tag**               | **Features**                                                                                                             |
|-----------------------------|------------------------------------------------------------------------------------------------------------------------|
| `tigersmile/memcached:micro` | 🟢 Minimal build:<br>- **TCP only** (no UDP/socket)<br>- Binary & text protocols<br>- No TLS, SASL, or extstore          |
| `tigersmile/memcached:slim`  | 🟢 Mid-tier:<br>- **TCP only**<br>- Enhanced features for higher load<br>- No TLS                                       |
| `tigersmile/memcached:tls`   | 🟢 Adds TLS:<br>- **TCP only**<br>- TLS encryption<br>- No SASL                                                         |
| `tigersmile/memcached:full`  | 🟢 Fully-featured:<br>- **TCP only**<br>- TLS + SASL + extstore                                                         |

🛑 **Note:** All variants exclusively support **TCP traffic**—no UNIX socket or UDP support.

---

## 🛠 Features

- ✅ **Environment-driven configuration** (no CLI args needed)
- ✅ **TLS support** (tls/full)
- ✅ **SASL support** (full)
- ✅ **Extstore support** (full)
- ✅ **Alpine-based minimal size**
- ✅ **Scratch containers** (no shell, no extras)

---

## 📥 Usage Example

```bash
docker run -d \
  --name my-memcached \
  -e MEMCACHED_MEMORY_LIMIT=512 \
  -e MEMCACHED_CONNECTIONS=1024 \
  tigersmile/memcached:micro
```

**CLI arguments are optional:**

```bash
docker run -d \
  --name my-memcached \
  tigersmile/memcached:micro -m 512 -c 1024
```

---

## 🔐 TLS Setup

1️⃣ Generate certs:

```bash
mkdir certs
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout certs/server.key -out certs/server.crt \
  -subj "/CN=localhost"
```

2️⃣ Launch TLS container:

```bash
docker run -d \
  --name memcached-tls \
  -e MEMCACHED_TLS=1 \
  -e MEMCACHED_TLS_CERT=/certs/server.crt \
  -e MEMCACHED_TLS_KEY=/certs/server.key \
  -v $(pwd)/certs:/certs:ro \
  tigersmile/memcached:tls
```

---

## 🗄️ Extstore Setup

```bash
docker run -d \
  --name memcached-full \
  -e MEMCACHED_EXTSTORE_PATH=/extstore:1G \
  -v /path/to/extstore:/extstore \
  tigersmile/memcached:full
```

Customizable with:

- `MEMCACHED_EXTSTORE_PAGE_SIZE`
- `MEMCACHED_EXTSTORE_WBUF_SIZE`

---

## 📊 Environment Variables Overview

| **Variable**                                | **Description**                                               | `micro` | `slim` | `tls` | `full` |
|---------------------------------------------|---------------------------------------------------------------|---------|--------|--------|---------|
| MEMCACHED_MEMORY_LIMIT                      | Memory limit (MB)                                             | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_CONNECTIONS                       | Max simultaneous connections                                  | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_THREADS                           | Number of worker threads                                      | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_PROTOCOL                          | Protocol (ascii, binary, auto)                                | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_REQS_PER_EVENT                    | Max requests per event                                        | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_FACTOR                            | Slab growth factor                                            | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_MAX_ITEM_SIZE                     | Max item size                                                 | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_MIN_ITEM_SIZE                     | Min item size                                                 | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_LISTEN_BACKLOG                    | Listen backlog size                                          | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_KEY_DELIMITER                     | Key delimiter character                                       | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_ALLOW_SHUTDOWN                    | Enable ASCII shutdown command                                 | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_DISABLE_CAS                       | Disable CAS                                                  | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_LOCK_PAGES                        | Lock paged memory                                             | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_ENABLE_COREDUMPS                  | Enable coredumps                                              | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_ENABLE_LARGEPAGES                 | Enable large pages                                            | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_DISABLE_FLUSH_ALL                 | Disable flush_all command                                     | ❌       | ✅      | ✅      | ✅       |
| MEMCACHED_DISABLE_DUMPING                   | Disable stats cachedump/lru_crawler metadump                  | ❌       | ✅      | ✅      | ✅       |
| MEMCACHED_DISABLE_WATCH                     | Disable watch commands                                        | ❌       | ✅      | ✅      | ✅       |
| MEMCACHED_VERBOSE                           | Verbosity level                                              | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_SASL                              | Enable SASL authentication                                    | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_TLS                               | Enable TLS                                                   | ❌       | ❌      | ✅      | ✅       |
| MEMCACHED_TLS_CERT                          | TLS certificate path                                          | ❌       | ❌      | ✅      | ✅       |
| MEMCACHED_TLS_KEY                           | TLS key path                                                  | ❌       | ❌      | ✅      | ✅       |
| MEMCACHED_TLS_CA                            | TLS CA certificate path                                       | ❌       | ❌      | ✅      | ✅       |
| MEMCACHED_TLS_VERIFY_MODE                   | TLS verify mode                                              | ❌       | ❌      | ✅      | ✅       |
| MEMCACHED_EXTSTORE_PATH                     | Extstore path + size                                          | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_PAGE_SIZE                | Extstore page size                                           | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_WBUF_SIZE                | Extstore write buffer size                                    | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_THREADS                  | Extstore thread count                                         | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_ITEM_SIZE                | Extstore item size                                           | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_ITEM_AGE                 | Extstore item age                                            | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_LOW_TTL                  | Extstore low TTL                                             | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_DROP_UNREAD              | Extstore drop unread flag                                     | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_RECACHE_RATE             | Extstore recache rate                                        | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_COMPACT_UNDER            | Extstore compact threshold                                    | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_DROP_UNDER               | Extstore drop threshold                                       | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_MAX_FRAG                 | Extstore max fragmentation                                   | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_EXTSTORE_MAX_SLEEP                | Extstore max sleep time                                       | ❌       | ❌      | ❌      | ✅       |
| MEMCACHED_SLAB_AUTOMOVE_FREERATIO           | Slab automove freeratio                                      | ✅       | ✅      | ✅      | ✅       |
| MEMCACHED_NAPI_IDS                          | NAPI IDs                                                     | ✅       | ✅      | ✅      | ✅       |

This table lists **all supported environment variables**, with checkmarks showing which variants implement each. Memcached maps them automatically if the feature is available.

## ⚠️ Notes

- **TCP-only:** All builds exclusively support TCP (no UNIX/UDP).
- **Scratch containers:** No shell or package manager.
- **Flexible config:** Env vars auto-map to CLI options; CLI args still work.
- **Ulimits:** High concurrency may require raising limits:

```yaml
ulimits:
  nofile:
    soft: 65535
    hard: 65535
```

---

## 🔗 Links

- 🐙 GitHub: [https://github.com/johnnyjoy/memcached-docker](https://github.com/johnnyjoy/memcached-docker)
- 🐋 Docker Hub: [tigersmile/memcached](https://hub.docker.com/r/tigersmile/memcached)

---

## ✅ Status

- ✅ Multi-arch builds: x86, ARM (32 & 64-bit), PPC, s390x.
- ✅ Fully environment-configurable.
- ✅ TLS & extstore tested.
- 🚧 SASL: implemented but pending full test suite.

---

Enjoy lightning-fast, container-optimized Memcached 🚀
