# openshift-3tiers
# Déploiement d'une architecture réseau 3-tiers virtualisée sur OpenShift

## Description

Ce projet déploie une architecture réseau multi-VM sur **OpenShift Virtualization (Developer Sandbox)**,
reproduisant un environnement d'entreprise sécurisé composé de :

- Une **passerelle/firewall** simulée par des NetworkPolicies OpenShift
- Un **serveur web** (Nginx) accessible depuis Internet via une Route
- Un **serveur de base de données** MySQL, accessible uniquement en interne

Chaque composant est provisionné via des manifests YAML versionnés sur GitHub et configuré
selon une topologie **LAN/DMZ sécurisée**, illustrant les principes de segmentation réseau,
de déploiement de services et d'administration système en environnement cloud.

---

## Architecture
```
Internet
    |
    | (Route OpenShift - HTTPS)
    |
+---v-------------------------+
|   Serveur Web — VM 2        |   Zone DMZ  192.168.100.0/24
|   Nginx + Node.js           |
|   Service: web-service:80   |
+---+---------+---------------+
    |         |
    |         | (port 3306 — NetworkPolicy allow-web-to-db)
    |         |
+---v---------v---------------+
|   Base de données — VM 3    |   Zone LAN  192.168.10.0/24
|   MySQL 8                   |
|   Service: mysql-service    |
|   Pas de Route (interne)    |
+-----------------------------+

Sécurité : NetworkPolicy deny-all + allow-web-to-db (port 3306 uniquement)
```

---

## Structure du dépôt
```
openshift-3tiers/
├── README.md
├── manifests/
│   ├── 00-mysql-secret.yaml          # Secret pour le mot de passe MySQL
│   ├── 01-mysql-deployment.yaml      # Déploiement MySQL (VM3)
│   ├── 02-mysql-service.yaml         # Service interne MySQL
│   ├── 03-web-deployment.yaml        # Déploiement Nginx (VM2)
│   ├── 04-web-service.yaml           # Service web
│   ├── 05-web-route.yaml             # Route OpenShift (accès Internet)
│   ├── 06-networkpolicy-deny-all.yaml     # Bloquer tout le trafic
│   └── 07-networkpolicy-allow-web-db.yaml # Autoriser web → MySQL:3306
└── screenshots/
    ├── 01-namespace.png
    ├── 02-mysql-running.png
    ├── 03-web-running.png
    ├── 04-route-accessible.png
    ├── 05-networkpolicies.png
    └── 06-topology.png
```

---

## Prérequis

- Compte [Red Hat Developer Sandbox](https://developers.redhat.com/developer-sandbox)
- `oc` CLI installé (optionnel, tout peut se faire via la console web)
- Compte GitHub

---

## Déploiement — étape par étape

### 1. Créer le namespace

Dans OpenShift Console → **Developer → Project → Create Project**
Nom : `mon-projet-securite`

### 2. Appliquer les manifests dans l'ordre
```bash
oc apply -f manifests/00-mysql-secret.yaml
oc apply -f manifests/01-mysql-deployment.yaml
oc apply -f manifests/02-mysql-service.yaml
oc apply -f manifests/03-web-deployment.yaml
oc apply -f manifests/04-web-service.yaml
oc apply -f manifests/05-web-route.yaml
oc apply -f manifests/06-networkpolicy-deny-all.yaml
oc apply -f manifests/07-networkpolicy-allow-web-db.yaml
```

Ou manuellement via **+Add → Import YAML** dans la console.

### 3. Vérifier le déploiement
```bash
oc get pods
oc get svc
oc get route
oc get networkpolicy
```

---

## Parties du projet

| Partie |      Contenu | Fichiers |
|--------|     ---------|----------|
| Partie 1 —   Virtualisation | Déploiement des VMs (Pods) sur OpenShift | `01` à `04` |
| Partie 2 —   Déploiement des services | Nginx web server + MySQL database | `03` à `04` |
| Partie 3 —   Réseaux | Services, Route, segmentation LAN/DMZ | `02`, `04`, `05` |
| Partie 4 — Intégration GitHub | Manifests versionnés, README, structure | Ce dépôt |

---

## Sécurité

- **deny-all** : tout le trafic entrant est bloqué par défaut
- **allow-web-to-db** : seul le pod `web` peut contacter `database` sur le port `3306`
- MySQL n'a **aucune Route** → inaccessible depuis Internet
- Le mot de passe MySQL est stocké dans un **Secret** Kubernetes (pas en clair dans le YAML de déploiement)

---

## Technologies utilisées

- Red Hat OpenShift (Developer Sandbox)
- Kubernetes Deployments, Services, Routes, NetworkPolicies, Secrets
- MySQL 8
- Nginx
- GitHub (versioning des manifests)

---

## Auteur
Mr Babou

Projet de fin de module — Administration Système & Réseaux Cloud
