# Déploiement d'une architecture réseau 3-tiers virtualisée sur OpenShift

> Projet de fin de module — OpenShift Virtualization (KubeVirt)

## Description

Ce projet déploie une architecture réseau multi-VM sur OpenShift Virtualization,
reproduisant un environnement d'entreprise composé d'une passerelle/firewall,
d'un serveur web et d'un serveur de base de données. Chaque VM est provisionnée
depuis GitHub et configurée pour communiquer selon une topologie LAN/DMZ sécurisée.

## Architecture
```
Internet (NAT)
      │
      ▼
┌─────────────────────────────────┐
│  VM1 — Passerelle / Firewall    │  Ubuntu 22.04 + iptables
│  eth0 : NAT (Internet)          │
│  eth1 : DMZ  192.168.100.0/24   │
│  eth2 : LAN  192.168.10.0/24    │
└────────────┬────────────────────┘
             │
     ┌───────┴──────────────────────┐
     │                              │
     ▼                              ▼
┌─────────────────┐      ┌──────────────────────┐
│  Zone DMZ       │      │  Réseau LAN           │
│  192.168.100.0  │      │  192.168.10.0/24      │
│  /24            │      │                       │
│  VM2 — Web      │ ───► │  VM3 — Serveur BD     │
│  Nginx          │      │  MySQL 8.0            │
│  192.168.100.10 │      │  192.168.10.10        │
└─────────────────┘      └──────────────────────┘
```

## Prérequis

- Compte Red Hat Developer Sandbox (gratuit)
- OpenShift Virtualization disponible sur le cluster
- Opérateur Multus CNI installé
- `oc` CLI configuré et connecté au cluster

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
│   │   ├── 06-vm-firewall.yaml                      # VM1 — Firewall Ubuntu + iptables
│   │   ├── 07-vm-web.yaml                           # VM2 — Nginx (DMZ)
│   │   └── 08-vm-db.yaml                            # VM3 — MySQL (LAN)
│   └── services/
│       ├── 09-svc-web.yaml                          # Service exposant Nginx
│       ├── 10-svc-db.yaml                           # Service interne MySQL
│       └── 11-route-web.yaml                        # Route OpenShift (accès Internet)
└── screenshots/
    ├── 01-namespace.png
    ├── 02-networkpolicies.png
    ├── 03-vm-firewall-running.png
    ├── 04-vm-web-running.png
    ├── 05-vm-db-running.png
    ├── 06-route-accessible.png
    └── 08-topology.png
```

## Déploiement

> **Important** : respecter l'ordre — réseau d'abord, VMs ensuite, services à la fin.

### 1. Se connecter au cluster
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

### 4. Créer le secret MySQL
```bash
oc apply -f manifests/vms/05-secret-mysql.yaml
```

### 5. Démarrer les VMs
```bash
oc apply -f manifests/vms/
```

Vérification :
```bash
oc get vms
oc get vmis
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
| **Partie 1 — Virtualisation** | Création des VMs avec KubeVirt |
| **Partie 2 — Déploiement des services** | Nginx, Node.js, MySQL via cloud-init |
| **Partie 3 — Réseaux** | DMZ/LAN via NAD et NetworkPolicies |
| **Partie 4 — Intégration GitHub** | Provisioning automatique depuis ce dépôt |

## Sécurité réseau

- **Deny all** : tout le trafic est bloqué par défaut
- **Allow web → db** : seul le Tier 2 peut joindre MySQL sur le port 3306
- **Firewall** : NAT et filtrage iptables entre Internet, DMZ et LAN

## Vérifications utiles
```bash
# État des VMs
oc get vms -n bienvenucloud-dev

# Accéder à la console d'une VM
virtctl console vm-firewall

# Logs d'une VM
oc describe vmi vm-db
```

## Auteur

Projet réalisé dans le cadre du module **Administration Cloud & Virtualisation**.
