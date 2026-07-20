# From Docker to Kubernetes — a self-managed infrastructure journey

*One Terraform + Ansible foundation that runs a real product on Docker today, and grows into a hand-built Kubernetes cluster when the traffic earns it.*

This repository documents how I build and run infrastructure from scratch on self-managed VPS. The same Terraform + Ansible foundation provisions the servers; what those servers become is decided by which Ansible playbook I run against them.

It backs a real product, KOMUNA, and follows how that product actually grows. Today KOMUNA runs as a Docker Compose deployment on one or two VPS — at its current traffic that's the right-sized choice, and putting a small app on Kubernetes would just be over-engineering it. The Kubernetes side is the migration path I'm building and rehearsing now, on the same infrastructure, so that when the app outgrows a single host the move is a planned step rather than a scramble.

So the repository has two tracks on one shared foundation:

- **A Docker deployment** — a single host running the app with Docker Compose behind a reverse proxy, reachable over HTTPS in a browser. This is what KOMUNA runs on today.
- **A Kubernetes lab** — a multi-node cluster bootstrapped with `kubeadm` (1 control plane + 2 workers). This is where I learn the internals and prove out the migration target.

The goal isn't just to get things running. I also want to understand how the components interact and what actually happens when they fail — the knowledge that makes a migration like this safe to attempt.

![IaC](https://img.shields.io/badge/Terraform%20%2B%20Ansible-7B42BC)
![Docker](https://img.shields.io/badge/Docker-Compose%20%2B%20Caddy-2496ED)
![Kubernetes](https://img.shields.io/badge/Kubernetes-kubeadm-326CE5)
![CNI](https://img.shields.io/badge/CNI-Calico-orange)
![Status](https://img.shields.io/badge/status-in%20progress-yellow)

## The problem I wanted to solve

Managed Kubernetes (EKS, GKE, and friends) is the right call for a lot of production work, but it hides exactly the parts you need to understand when something breaks at 2am — the control plane, etcd, the CNI, the certificates. I've used managed clusters without ever having brought one up by hand, and that gap bothered me.

At the same time, most real projects I work on don't need Kubernetes at all. A small SaaS just needs to be online, cheaply, over HTTPS. Reaching for a managed cluster there is overkill and an unnecessary monthly bill.

So I wanted one reproducible IaC foundation that could do both: ship a real application on a plain VPS today without much ceremony, and let me learn Kubernetes at the level where I own every component — so the day the app genuinely needs a cluster, I've already built and broken that path myself, not on production traffic.

## Who it's for

- **Me, first** — as a place to build the depth of knowledge managed services let you skip, and to grow a set of automation I can reuse on client work.
- **Engineers** who want to see how a kubeadm cluster is actually assembled and operated, not just consumed.
- **Small teams / solo builders** (this is the setup I use for KOMUNA) who need a real app running affordably and don't want a managed-Kubernetes bill to do it.

## What I built

Both modes start from the same Terraform code. Terraform's only job is to hand back plain Ubuntu servers on a private network — it doesn't know or care what runs on them. The difference lives entirely in Ansible:

- `ansible-playbook k8s.yml` turns the servers into a Kubernetes cluster.
- `ansible-playbook docker.yml` turns a server into a Docker host serving an app over HTTPS.

Keeping the provisioning identical and swapping only the configuration layer is what makes the automation reusable, and it's the part I'd expect to carry over to real client work.

## Why Docker first, Kubernetes later

Matching the infrastructure to the actual traffic is a decision in itself. A small app on one or two VPS is served perfectly well by Docker Compose; a Kubernetes cluster there would be more moving parts to operate for no real benefit. So Docker is the right answer for now, and saying so out loud is part of the point.

Kubernetes earns its place later — when traffic, availability requirements, or the number of services make a single host the bottleneck. Because both tracks sit on the same Terraform foundation, that migration is incremental rather than a rewrite: the servers are already provisioned the same way, so moving from a Docker host to a cluster is largely a change of the Ansible layer and the node map. Rehearsing it in the lab now means the first time I do it won't be the time it counts.

## Key features

- **One infrastructure, two deployment modes.** The same Terraform provisions either a Kubernetes cluster or a Docker host; only the playbook changes.
- **Fleet described as data.** Nodes are a Terraform `for_each` map, so scaling from 3 to 30 is editing a map entry, not rewriting code.
- **A real kubeadm cluster.** Control plane bootstrapped by hand, Calico for pod networking, and NetworkPolicy for namespace isolation.
- **Day-2 operations, not just day-1.** etcd snapshot and restore, a zero-downtime upgrade with drain/uncordon, certificate renewal, and least-privilege RBAC.
- **The Docker path ends in a working URL.** Docker Compose for the app, a persistent volume for its data, and Caddy in front for automatic HTTPS.
- **Built to be destroyed.** Hetzner's hourly billing means the default state is torn down; I rebuild from code whenever I need the environment.

## Architecture and tech choices

The Kubernetes lab starts with three nodes — one control plane and two workers — with a clear path to grow into an HA multi-master setup later.

| Node | Role | Main components |
|---|---|---|
| control-plane | master | kube-apiserver, etcd, scheduler, controller-manager |
| worker-1 | worker | kubelet, kube-proxy, containerd |
| worker-2 | worker | kubelet, kube-proxy, containerd |

![Cluster architecture](./assets/architecture.png)

| Layer | Choice | Why |
|---|---|---|
| Servers | Hetzner Cloud (Singapore) | Cheap, hourly billing, low latency from Indonesia, and a solid Terraform provider |
| Provisioning | Terraform (`hetznercloud/hcloud` provider) | Servers as code — reproducible, and cheap to tear down and rebuild |
| Configuration | Ansible, over SSH | Repeatable server config without tying the setup to one cloud provider |
| Kubernetes bootstrap | kubeadm | Full ownership of every control-plane component |
| Container runtime | containerd (systemd cgroup driver) | Lightweight, the runtime Kubernetes recommends by default |
| Kubernetes networking | Calico | Real NetworkPolicy support, not just basic pod networking |
| App deployment | Docker Compose + Caddy | Simple to run a real app; Caddy gets and renews HTTPS certificates on its own |

A couple of the choices worth calling out: I keep the firewall in Ansible (`ufw`) rather than the Hetzner Cloud Firewall so Terraform stays mode-agnostic — the two modes need very different rules. And I use cloud-init only to make a fresh server reachable by Ansible; everything else is Ansible, so there's a single place to read the configuration. The full reasoning, including what I deliberately left out, lives in my design notes.

## Challenges and the decisions behind them

- **CNI and pod-CIDR mismatch.** The classic reason nodes sit `NotReady` after `kubeadm init` is the pod network CIDR not matching the CNI config. It's the first real debugging most people hit on a self-managed cluster, and getting it right is the difference between a cluster that works and one that silently doesn't.
- **Load balancing on a public VPS.** `Service type=LoadBalancer` and MetalLB's L2 mode assume an L2 network you control; a public VPS doesn't give you that. Rather than fight it, I document the limitation and use the honest alternatives (the Hetzner load balancer, or ingress on a node's public IP). Knowing *why* it doesn't work is worth more than a hack that does.
- **Keeping Terraform mode-agnostic.** The whole design rests on Terraform not knowing whether it's building a cluster or a Docker host. That constraint forced some decisions — firewall in Ansible, one shared private network, volumes made optional — that keep the two tracks from leaking into the provisioning layer.
- **Deciding what *not* to build.** No modules yet, no dynamic inventory, no GitOps. On a handful of VMs those are complexity without payoff. I wrote down the trigger for adding each one instead of adding it now.

## What it demonstrates

Part of this is a real deployment and part is a learning lab, so the honest measure isn't a vanity metric — it's that it keeps something real online while staying reproducible and cheap:

- **It runs a real product.** The Docker track isn't a toy — it's what KOMUNA is served from, which keeps the day-2 concerns (backups, HTTPS renewal, redeploys) honest rather than hypothetical.
- **Rebuildable from zero.** The entire app host or lab can be recreated from an empty Hetzner project using only the code in this repo.
- **Cheap enough to treat as disposable.** Because Hetzner bills by the hour, a full working session costs a few cents rather than a month of VPS rental, so I can destroy and rebuild without thinking about it.
- **Provider-agnostic automation.** The Ansible layer doesn't depend on Hetzner, so the same roles carry over to other providers and to client work.
- **A migration path that's been rehearsed.** Because both tracks share one foundation, the Docker → Kubernetes move is a practiced, incremental step rather than a first-time gamble on production.

## Demo

Recordings and screenshots are added here as each phase is completed and recorded. The architecture diagram above is the current artifact; the clips below fill in as the tracks progress.

<!-- Screenshots / asciinema links go here as phases ship, e.g.:
- terraform apply bringing up the servers
- first `kubectl get nodes -o wide`
- etcd snapshot -> delete a resource -> restore
- the KOMUNA app loading over HTTPS
-->

_Coming as the phases below are recorded._

## Roadmap

Shipped in phases, so each step is small enough to finish and verify on its own. The two tracks share the same provisioning and can be worked on independently.

**Foundations**

- [x] **Phase 0 — Foundations.** Repo, `.gitignore` for secrets, IaC skeleton, project write-up.

**Track A — Kubernetes lab**

- [ ] **A1 — Provision.** Terraform provisions three servers on a private network and hands back their IPs.
- [ ] **A2 — Base config.** Ansible: shared base setup, then disable swap, kernel/sysctl tuning, containerd, and the kubeadm/kubelet/kubectl toolchain on every node.
- [ ] **A3 — Bootstrap.** `kubeadm init` on the control plane, then join both workers.
- [ ] **A4 — Networking.** Deploy Calico, confirm cross-node pod traffic, add a NetworkPolicy.
- [ ] **A5 — Day-2 operations.** etcd snapshot & restore, a zero-downtime upgrade, certificate renewal, least-privilege RBAC, and persistent storage tested with a stateful pod.
- [ ] **A6 — Destroy.** Tear the lab down; the repo and the recorded output are the permanent record.

**Track B — Docker deployment**

- [ ] **B1 — Provision.** Same Terraform, one server plus a data volume for persistent storage.
- [ ] **B2 — Install Docker.** Ansible: shared base setup, then Docker Engine, the Compose plugin, firewall, and the mounted data volume.
- [ ] **B3 — Deploy.** Render the Compose stack (app + database on the volume) and bring it up.
- [ ] **B4 — Reverse proxy + HTTPS.** Put Caddy in front; the app loads over HTTPS with an automatic certificate.
- [ ] **B5 — CI/CD.** A GitHub Actions workflow that redeploys on push to `main`.
- [ ] **B6 — Destroy.** Tear the environment down, after backing up the data volume.

Phase A5 is the part I care about most. Building a cluster is one thing; keeping it healthy is where most of the operational work actually happens.

## Repository layout

```
terraform/    VPS provisioning (shared by both tracks)
ansible/      roles, inventory, and the two entrypoints: k8s.yml and docker.yml
scripts/      helper / idempotent bootstrap scripts
manifests/    Kubernetes: RBAC, StorageClass, NetworkPolicy, sample app
assets/       architecture diagram, screenshots
Makefile      make infra-up / cluster-up / verify / destroy   (arrives in Phase A1)
```

**On safety:** nothing sensitive is committed. No cloud API tokens, join tokens, certificates,
kubeconfigs, application secrets, or real server IPs — those live in git-ignored files, and the repo
only ships example templates.

## Where this goes next

Once the base tracks are stable, I'd like to push each a bit further: an HA control plane with external etcd, a monitoring stack (Prometheus + Grafana), and a migration from Calico to Cilium on the Kubernetes side; and on the Docker side, using Hetzner volumes and snapshots properly, plus ephemeral demo environments that spin up on demand and destroy themselves afterwards.

There's no fixed timeline, and I'll keep adding pieces as I learn and validate them.

## About

I'm an Infrastructure Engineer with an interest in infrastructure automation and reliable systems.

This repository is part of my ongoing effort to deepen that knowledge by building things from scratch instead of relying only on managed services.

I'm always happy to connect with people working on Kubernetes, cloud infrastructure, or platform engineering.

Contact: yogitrinugraha93@gmail.com · [LinkedIn](https://www.linkedin.com/in/yogi-tri-nugraha-eddy-soetopo-222a44116)
