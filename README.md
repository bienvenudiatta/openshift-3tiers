# Déploiement d'une architecture réseau 3-tiers sur OpenShift

> Projet de fin de module — OpenShift (Red Hat Developer Sandbox)

## Description

Ce projet déploie une architecture réseau 3-tiers sur OpenShift, reproduisant
un environnement d'entreprise composé d'une passerelle/firewall, d'un serveur
web et d'un serveur de base de données. Chaque service est provisionné depuis
GitHub et configuré pour communiquer selon une topologie LAN/DMZ sécurisée
grâce aux NetworkPolicies OpenShift.

## Architecture
```
Internet
      │
      ▼
┌─────────────────────────────────┐
│  Tier 1 — Firewall              │  Ubuntu 22.04 + iptables
│  Filtre le trafic entrant       │
│  NAT vers Internet              │
└────────────┬────────────────────┘
             │
     ┌───────┴──────────────────────┐
     │                              │
     ▼                              ▼
┌─────────────────┐      ┌──────────────────────┐
│  Zone DMZ       │      │  Réseau LAN           │
│                 │      │                       │
│  Tier 2 — Web   │ ───► │  Tier 3 — Base de     │
│  Nginx          │      │  données MySQL 8.0    │
│  Port 80        │      │  Port 3306            │
└─────────────────┘      └──────────────────────┘
```

## Prérequis

- Compte Red Hat Developer Sandbox (gratuit)
- `oc` CLI configuré et connecté au cluster
- Accès au namespace `bienvenucloud-dev`

## Structure du dépôt
```
openshift-3tiers/
├── README.md
├── manifests/
│   ├── network/
│   │   ├── 00-namespace.yaml                        # Namespace du projet
│   │   ├── 01-nad-dmz.yaml                          # NetworkAttachmentDefinition DMZ
│   │   ├── 02-nad-lan.yaml                          # NetworkAttachmentDefinition LAN
│   │   ├── 03-networkpolicy-deny-all.yaml           # Bloquer tout le trafic par défaut
│   │   └── 04-networkpolicy-allow-web-db.yaml       # Autoriser web → MySQL:3306
│   ├── vms/
│   │   ├── 05-secret-mysql.yaml                     # Secret mot de passe MySQL
│   │   ├── 06-deployment-firewall.yaml              # Tier 1 — Firewall Ubuntu + iptables
│   │   ├── 07-deployment-web.yaml                   # Tier 2 — Nginx (DMZ)
│   │   └── 08-deployment-db.yaml                    # Tier 3 — MySQL (LAN)
│   └── services/
│       ├── 09-svc-web.yaml                          # Service exposant Nginx
│       ├── 10-svc-db.yaml                           # Service interne MySQL
│       └── 11-route-web.yaml                        # Route OpenShift (accès Internet)
└── screenshots/
    ├── 01-namespace.png
    ├── 02-networkpolicies.png
    ├── 03-firewall-running.png
    ├── 04-web-running.png
    ├── 05-db-running.png
    ├── 06-route-accessible.png
    └── 07-topology.png
```

## Déploiement

> **Important** : respecter l'ordre — réseau d'abord, deployments ensuite, services à la fin.

### 1. Se connecter au Sandbox
```bash
oc login --token=<ton-token> --server=https://api.rm3.7wse.p1.openshiftapps.com:6443
oc project bienvenucloud-dev
```

### 2. Cloner le dépôt
```bash
git clone https://github.com/bienvenudiatta/openshift-3tiers.git
cd openshift-3tiers
```

### 3. Déployer les NetworkPolicies
```bash
oc apply -f manifests/network/03-networkpolicy-deny-all.yaml
oc apply -f manifests/network/04-networkpolicy-allow-web-db.yaml
```

Vérification :
```bash
oc get networkpolicies
```

### 4. Créer le secret MySQL
```bash
oc apply -f manifests/vms/05-secret-mysql.yaml
```

### 5. Déployer les services applicatifs
```bash
oc apply -f manifests/vms/
```

Vérification :
```bash
oc get deployments
oc get pods
```

### 6. Déployer les services et la route
```bash
oc apply -f manifests/services/
```

Récupérer l'URL publique :
```bash
oc get route web-route -o jsonpath='{.spec.host}'
```

## Parties du projet

| Partie | Contenu |
|--------|---------|
| **Partie 1 — Virtualisation** | Création des Deployments (Firewall, Web, MySQL) |
| **Partie 2 — Déploiement des services** | Nginx, iptables, MySQL via images Docker |
| **Partie 3 — Réseaux** | NetworkPolicies DMZ/LAN + Services + Route |
| **Partie 4 — Intégration GitHub** | Provisioning automatique depuis ce dépôt |

## Sécurité réseau

- **Deny all** : tout le trafic est bloqué par défaut
- **Allow web → db** : seul le Tier 2 peut joindre MySQL sur le port 3306
- **Firewall** : NAT et filtrage iptables entre Internet, DMZ et LAN

## Vérifications utiles
```bash
# État des deployments
oc get deployments -n bienvenucloud-dev

# État des pods
oc get pods -n bienvenucloud-dev

# Logs du firewall
oc logs deployment/firewall

# Logs du serveur web
oc logs deployment/web

# URL publique
oc get route web-route
```

## Auteur

Projet réalisé dans le cadre du module **Administration Cloud & Virtualisation**.
