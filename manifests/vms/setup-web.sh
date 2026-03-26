#!/bin/bash
apt-get update -y && apt-get install -y nginx
systemctl enable nginx && systemctl start nginx
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Architecture 3-Tiers OpenShift</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;background:#0a0a1a;color:#fff}
header{background:linear-gradient(135deg,#1a1a3e,#c00);padding:40px 20px;text-align:center}
header h1{font-size:2.2em;margin-bottom:10px}
header p{color:#ccc;font-size:1em}
.status{background:#111;padding:15px;text-align:center;border-bottom:2px solid #c00;display:flex;justify-content:center;gap:30px;flex-wrap:wrap}
.status span{color:#00ff88;font-weight:bold;font-size:.9em}
.container{max-width:1100px;margin:0 auto;padding:20px}
.section{background:#111;border:1px solid #222;border-radius:10px;padding:25px;margin:20px 0}
.section h2{color:#c00;margin-bottom:15px;font-size:1.3em;border-bottom:1px solid #333;padding-bottom:10px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:15px;margin:15px 0}
.card{background:#1a1a2e;border:1px solid #333;border-radius:8px;padding:20px;text-align:center;transition:border-color .3s}
.card:hover{border-color:#c00}
.card .icon{font-size:2.5em;margin-bottom:10px}
.card h3{color:#c00;margin-bottom:8px}
.card p{color:#aaa;font-size:.85em;line-height:1.6}
.badge{display:inline-block;background:#00ff88;color:#000;padding:2px 8px;border-radius:20px;font-size:.75em;margin-top:8px;font-weight:bold}
.arch{display:flex;align-items:center;justify-content:center;gap:10px;flex-wrap:wrap;padding:15px 0}
.tier{background:#1a1a2e;border:2px solid #c00;border-radius:8px;padding:12px 16px;text-align:center;min-width:120px}
.tier h4{color:#c00;font-size:.85em}
.tier p{color:#ccc;font-size:.75em;margin-top:4px}
.arrow{color:#c00;font-size:1.8em}
table{width:100%;border-collapse:collapse;margin-top:10px}
th{background:#c00;color:#fff;padding:10px;text-align:left;font-size:.85em}
td{padding:10px;border-bottom:1px solid #222;color:#ccc;font-size:.85em}
tr:hover td{background:#1a1a1a}
.running{color:#00ff88;font-weight:bold}
footer{background:#111;text-align:center;padding:20px;color:#555;border-top:2px solid #c00;margin-top:20px}
footer span{color:#c00}
</style>
</head>
<body>
<header>
<h1>Architecture 3-Tiers sur OpenShift</h1>
<p>Deploye sur Red Hat OpenShift Service on AWS</p>
</header>
<div class="status">
<span>&#x2705; Firewall: RUNNING</span>
<span>&#x2705; Serveur Web: RUNNING</span>
<span>&#x2705; Base de donnees: RUNNING</span>
<span>&#x2705; OpenShift: CONNECTED</span>
</div>
<div class="container">
<div class="section">
<h2>Description des 3 Tiers</h2>
<div class="cards">
<div class="card">
<div class="icon">&#x1F6E1;</div>
<h3>Tier 1 - Firewall</h3>
<p>Ubuntu 22.04 + iptables<br>Filtre le trafic reseau<br>NAT vers Internet<br>Isolation DMZ/LAN</p>
<span class="badge">VM KubeVirt</span>
</div>
<div class="card">
<div class="icon">&#x1F310;</div>
<h3>Tier 2 - Serveur Web</h3>
<p>Ubuntu 22.04 + Nginx<br>Zone DMZ securisee<br>Accessible depuis Internet<br>Port 80/HTTP</p>
<span class="badge">VM KubeVirt</span>
</div>
<div class="card">
<div class="icon">&#x1F5C4;</div>
<h3>Tier 3 - Base de donnees</h3>
<p>MySQL 8.0<br>Reseau LAN prive<br>Jamais accessible depuis Internet<br>Port 3306</p>
<span class="badge">Deployment</span>
</div>
</div>
</div>
<div class="section">
<h2>Schema de l Architecture</h2>
<div class="arch">
<div class="tier"><h4>Internet</h4><p>Requete HTTP</p></div>
<div class="arrow">&#x2192;</div>
<div class="tier"><h4>Firewall</h4><p>Tier 1 iptables</p></div>
<div class="arrow">&#x2192;</div>
<div class="tier"><h4>Web DMZ</h4><p>Tier 2 Nginx</p></div>
<div class="arrow">&#x2192;</div>
<div class="tier"><h4>MySQL LAN</h4><p>Tier 3 prive</p></div>
</div>
</div>
<div class="section">
<h2>Informations du Deploiement</h2>
<table>
<tr><th>Composant</th><th>Technologie</th><th>Statut</th><th>Zone</th></tr>
<tr><td>Firewall</td><td>Ubuntu 22.04 + iptables</td><td class="running">Running</td><td>NAT/DMZ/LAN</td></tr>
<tr><td>Serveur Web</td><td>Ubuntu 22.04 + Nginx</td><td class="running">Running</td><td>DMZ</td></tr>
<tr><td>Base de donnees</td><td>MySQL 8.0</td><td class="running">Running</td><td>LAN prive</td></tr>
<tr><td>Plateforme</td><td>Red Hat OpenShift on AWS</td><td class="running">Active</td><td>Cloud</td></tr>
<tr><td>Depot GitHub</td><td>Infrastructure as Code</td><td class="running">Synchronise</td><td>-</td></tr>
</table>
</div>
</div>
<footer>
<p>Projet realise par <span>Bienvenu Diatta</span></p>
<p style="margin-top:5px">Module <span>Administration Cloud et Virtualisation</span> - Red Hat OpenShift Service on AWS</p>
</footer>
</body>
</html>
HTMLEOF
systemctl restart nginx
