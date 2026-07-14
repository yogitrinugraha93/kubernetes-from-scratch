# Kubernetes from Scratch with kubeadm

This repository documents the process of building a Kubernetes cluster from scratch using `kubeadm` on self-managed VPS infrastructure.

The infrastructure is provisioned with Terraform, configured with Ansible, and the Kubernetes cluster is bootstrapped with kubeadm. Each phase is documented as the project evolves, including design decisions, implementation details, and the issues I run into along the way.

The goal isn't just to get a cluster running. I also want to understand how the individual components interact, and what actually happens when things fail.

It started as a personal lab, but I decided to document everything so I could rebuild the cluster from scratch at any time and hopefully make the process useful for others as well.

Current progress is in the [Roadmap](#roadmap) below.

![Kubernetes](https://img.shields.io/badge/Kubernetes-kubeadm-326CE5)
![IaC](https://img.shields.io/badge/Terraform%20%2B%20Ansible-7B42BC)
![CNI](https://img.shields.io/badge/CNI-Calico-orange)
![Status](https://img.shields.io/badge/status-in%20progress-yellow)

## What you'll find here

This isn't a step-by-step tutorial.

It's a hands-on project that documents the decisions, trade-offs, mistakes, and operational tasks involved in building and running a Kubernetes cluster from scratch.

## Why kubeadm instead of a managed service

Managed Kubernetes is the right choice for many production environments, but it also hides a lot of the moving parts.

With kubeadm, I'm responsible for everything, from provisioning the servers to bringing up the control plane, configuring networking, and troubleshooting failures.

That's exactly the experience I wanted from this project.

## Architecture

Starting with three nodes — one control plane and two workers — with a clear path to grow into a
HA multi-master setup later.

| Node | Role | Main components |
|---|---|---|
| control-plane | master | kube-apiserver, etcd, scheduler, controller-manager |
| worker-1 | worker | kubelet, kube-proxy, containerd |
| worker-2 | worker | kubelet, kube-proxy, containerd |

![Cluster architecture](./assets/architecture.png)

**Technology stack:**

| Layer | Choice | Why |
|---|---|---|
| Servers | Contabo Cloud VPS (Singapore) | Affordable VPS with low latency from Indonesia |
| Provisioning | Terraform (`contabo/contabo` provider) | Servers as code — reproducible, easy to tear down |
| Configuration | Ansible, over SSH | Keeps server configuration repeatable without depending on a specific cloud provider |
| Bootstrap | kubeadm | Full ownership of every control-plane component |
| Runtime | containerd (systemd cgroup driver) | Lightweight and the default runtime recommended by Kubernetes |
| Networking | Calico | Real NetworkPolicy support, not just basic pod networking |

## Roadmap

Shipped in phases so each step is small enough to finish and verify on its own.

- [x] **Phase 0 — Foundations.** Repo, IaC skeleton, project write-up.
- [ ] **Phase 1 — Infrastructure.** Terraform provisions the three VPS and hands back their IPs.
- [ ] **Phase 2 — Base config.** Ansible: disable swap, kernel/sysctl tuning, containerd, and the
  kubeadm/kubelet/kubectl toolchain on every node.
- [ ] **Phase 3 — Bootstrap.** `kubeadm init` on the control plane, then join both workers.
- [ ] **Phase 4 — Networking.** Deploy Calico, confirm cross-node pod traffic, add a NetworkPolicy.
- [ ] **Phase 5 — Day-2 operations.** etcd snapshot & restore, a zero-downtime upgrade, certificate
  renewal, least-privilege RBAC, and persistent storage tested with a stateful pod.
- [ ] **Phase 6 — Wrap-up.** Architecture diagram, a short walkthrough, and a final pass.

Phase 5 is the part I care about most. Building a cluster is one thing; keeping it healthy is where most of the operational work actually happens.

## Repository layout

```
terraform/    VPS provisioning
ansible/      roles, playbooks, inventory
scripts/      helper / idempotent bootstrap scripts
manifests/    RBAC, StorageClass, NetworkPolicy, sample app
assets/       architecture diagram, screenshots
Makefile      make infra-up / cluster-up / verify / destroy   (arrives in Phase 1)
```

**On safety:** nothing sensitive is committed. No API credentials, join tokens, certificates,
kubeconfigs, or real server IPs — those live in git-ignored files, and the repo only ships example
templates.

## Where this goes next

Once the base cluster is stable, I'd like to extend it into something closer to a real production environment: HA control planes, external etcd, a monitoring stack (Prometheus + Grafana), a later migration from Calico to Cilium, GitOps with ArgoCD, backups, and eventually cluster autoscaling.

There's no fixed timeline, and I'll keep adding pieces as I learn and validate them.

## About

I'm an Infrastructure Engineer with an interest in infrastructure automation and reliable systems.

This repository is part of my ongoing effort to deepen that knowledge by building things from scratch instead of relying only on managed services.

I'm always happy to connect with people working on Kubernetes, cloud infrastructure, or platform engineering.

Contact: yogitrinugraha93@gmail.com · [LinkedIn](https://www.linkedin.com/in/yogi-tri-nugraha-eddy-soetopo-222a44116)
