# Déploiement d'une architecture réseau 3-tiers virtualisée sur OpenShift

> Projet de fin de module — OpenShift Virtualization (KubeVirt)

## Description

Ce projet déploie une architecture réseau multi-VM sur OpenShift Virtualization, reproduisant un environnement d'entreprise composé d'une passerelle/firewall, d'un serveur web et d'un serveur de base de données. Chaque VM est provisionnée depuis GitHub et configurée pour communiquer selon une topologie LAN/DMZ sécurisée.

## Architecture

```
Internet (NAT)
      │
      ▼
┌─────────────────────────────────┐
│  VM1 — Passerelle / Firewall    │  pfSense ou iptables
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
│                 │      │  VM3 — Serveur BD     │
│  VM2 — Web      │ ───► │  MySQL                │
│  Nginx + Node   │      │  192.168.10.10        │
│  192.168.100.10 │      └──────────────────────┘
└─────────────────┘
```

## Prérequis

- Cluster OpenShift 4.x avec **OpenShift Virtualization** activé (opérateur KubeVirt installé)
- Opérateur **Multus CNI** installé (pour les réseaux secondaires DMZ/LAN)
- `oc` CLI configuré et connecté au cluster
- Accès `cluster-admin` ou droits suffisants sur le namespace

## Structure du dépôt

```
openshift-3tiers/
├── README.md
├── manifests/
│   ├── network/
│   │   ├── 00-namespace.yaml                        # Namespace du projet
│   │   ├── 01-nad-dmz.yaml                          # NetworkAttachmentDefinition DMZ (192.168.100.0/24)
│   │   ├── 02-nad-lan.yaml                          # NetworkAttachmentDefinition LAN (192.168.10.0/24)
│   │   ├── 03-networkpolicy-deny-all.yaml           # Bloquer tout le trafic par défaut
│   │   └── 04-networkpolicy-allow-web-db.yaml       # Autoriser web → MySQL:3306
│   ├── vms/
│   │   ├── 05-secret-mysql.yaml                     # Secret mot de passe MySQL
│   │   ├── 06-vm-firewall.yaml                      # VM1 — Passerelle/Firewall
│   │   ├── 07-vm-web.yaml                           # VM2 — Nginx + Node.js (DMZ)
│   │   └── 08-vm-db.yaml                            # VM3 — MySQL (LAN)
│   └── services/
│       ├── 09-svc-web.yaml                          # Service exposant Nginx
│       ├── 10-svc-db.yaml                           # Service interne MySQL
│       └── 11-route-web.yaml                        # Route OpenShift (accès Internet)
└── screenshots/
    ├── 01-namespace.png
    ├── 02-nad-dmz-lan.png
    ├── 03-vm-firewall-running.png
    ├── 04-vm-web-running.png
    ├── 05-vm-db-running.png
    ├── 06-route-accessible.png
    ├── 07-networkpolicies.png
    └── 08-topology.png
```

## Déploiement

> **Important** : respecter l'ordre de déploiement — réseau d'abord, VMs ensuite, services à la fin.

### 1. Créer le namespace

```bash
oc apply -f manifests/network/00-namespace.yaml
oc project openshift-3tiers
```

### 2. Déployer les réseaux (NAD + NetworkPolicies)

```bash
oc apply -f manifests/network/
```

Vérification :

```bash
oc get network-attachment-definitions
oc get networkpolicies
```

### 3. Créer le secret MySQL

```bash
oc apply -f manifests/vms/05-secret-mysql.yaml
```

### 4. Démarrer les VMs

```bash
oc apply -f manifests/vms/
```

Vérifier que les VMs sont en cours d'exécution :

```bash
oc get vms
oc get vmis   # VirtualMachineInstances (VMs actives)
```

### 5. Déployer les services et la route

```bash
oc apply -f manifests/services/
```

Récupérer l'URL d'accès public :

```bash
oc get route web-route -o jsonpath='{.spec.host}'
```

## Parties du projet

| Partie | Contenu |
|--------|---------|
| **Partie 1 — Virtualisation** | Création des VMs avec KubeVirt (`VirtualMachine` YAML) |
| **Partie 2 — Déploiement des services** | Installation de Nginx, Node.js, MySQL dans les VMs |
| **Partie 3 — Réseaux** | Configuration DMZ/LAN via NetworkAttachmentDefinitions et NetworkPolicies |
| **Partie 4 — Intégration GitHub** | Provisioning automatique via cloud-init depuis ce dépôt |

## Sécurité réseau

Les NetworkPolicies appliquent les règles suivantes :

- **Deny all** : tout le trafic entre pods/VMs est bloqué par défaut
- **Allow web → db** : seule la VM2 (web) peut joindre la VM3 (MySQL) sur le port 3306
- La VM1 (firewall) assure le NAT et le filtrage entre Internet, la DMZ et le LAN

## Vérifications utiles

```bash
# État des VMs
oc get vms -n openshift-3tiers

# Accéder à la console d'une VM
virtctl console vm-firewall

# SSH dans une VM (si configuré)
virtctl ssh vm-web

# Logs d'une VMI
oc describe vmi vm-db
```

## Auteur

Projet réalisé dans le cadre du module **Administration Cloud & Virtualisation**.
