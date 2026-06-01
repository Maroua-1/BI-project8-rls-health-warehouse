import json, random, hashlib, subprocess, sys
from datetime import datetime, timedelta

try:
    from sklearn.ensemble import IsolationForest
    from sklearn.preprocessing import StandardScaler
    import numpy as np
except:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "scikit-learn", "numpy"])
    from sklearn.ensemble import IsolationForest
    from sklearn.preprocessing import StandardScaler
    import numpy as np

print("=" * 55)
print("  ML - Detection Anomalies - CHU Ibn Sina Rabat")
print("=" * 55)

# RECUPERER LOGS ELASTICSEARCH
def get_logs():
    try:
        import urllib.request
        url = "http://localhost:9200/hopital-audit/_search?size=1000"
        with urllib.request.urlopen(url, timeout=3) as r:
            data = json.loads(r.read())
            logs = [h["_source"] for h in data["hits"]["hits"]]
            print(f"Elasticsearch : {len(logs)} logs reels recuperes")
            return logs
    except:
        print("Elasticsearch : utilisation donnees simulees")
        return None

def logs_simules():
    users = [
        ("dr.benali",     "medecin",       True),
        ("marie.admin",   "administratif", True),
        ("prof.rhanem",   "chercheur",     True),
        ("sophie.inf",    "infirmier",     True),
        ("directeur.chu", "directeur",     True),
        ("dr.suspect",    "medecin",       False),
        ("user.hack",     "chercheur",     False),
    ]
    logs = []
    base = datetime.now() - timedelta(days=30)
    for username, role, normal in users:
        nb = random.randint(20, 80) if normal else random.randint(300, 600)
        for i in range(nb):
            heure = random.randint(7, 19) if normal else random.choice([1,2,3,23,0])
            patients = random.randint(1, 15) if normal else random.randint(100, 300)
            logs.append({
                "utilisateur": username,
                "role": role,
                "timestamp": (base + timedelta(days=random.randint(0,30), hours=heure)).isoformat(),
                "nb_lignes": patients,
                "duree_ms": random.uniform(100, 2000) if normal else random.uniform(30, 100),
                "ip": "172.18.0.1" if normal else f"185.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}"
            })
    print(f"Logs simules : {len(logs)} entrees")
    return logs

# PREPARER FEATURES
def preparer(logs):
    stats = {}
    for log in logs:
        u = log.get("utilisateur", "inconnu")
        if u not in stats:
            stats[u] = {"role": log.get("role","?"), "heures":[], "patients":[], "durees":[], "ips":set(), "dates":[]}
        try:
            dt = datetime.fromisoformat(log["timestamp"][:19])
            stats[u]["heures"].append(dt.hour)
            stats[u]["dates"].append(dt)
        except:
            stats[u]["heures"].append(12)
        stats[u]["patients"].append(log.get("nb_lignes", 0) or 0)
        stats[u]["durees"].append(log.get("duree_ms", 500) or 500)
        stats[u]["ips"].add(log.get("ip","0.0.0.0"))

    users, features = [], []
    for u, d in stats.items():
        if len(d["heures"]) < 2:
            continue
        nb = len(d["heures"])
        h = d["heures"]
        ratio_nuit = sum(1 for x in h if x < 6 or x >= 22) / nb
        dates = d["dates"]
        delta = max((max(dates)-min(dates)).days, 1) if len(dates)>1 else 1
        users.append({
            "username": u, "role": d["role"],
            "nb_acces": nb,
            "patients_moy": round(float(np.mean(d["patients"])),1),
            "heure_moy": round(float(np.mean(h)),1),
            "ratio_nuit": round(ratio_nuit, 3),
            "duree_moy": round(float(np.mean(d["durees"])),1),
            "acces_par_jour": round(nb/delta, 1),
            "nb_ips": len(d["ips"])
        })
        features.append([nb, np.mean(d["patients"]), np.mean(h),
                         ratio_nuit*100, np.mean(d["durees"])/100,
                         nb/delta, np.var(h), len(d["ips"])])
    return users, np.array(features)

# ISOLATION FOREST
def analyser(users, features):
    if len(features) < 3:
        return users
    scaler = StandardScaler()
    fn = scaler.fit_transform(features)
    model = IsolationForest(n_estimators=100, contamination=0.15, random_state=42)
    model.fit(fn)
    preds = model.predict(fn)
    scores = model.decision_function(fn)
    smin, smax = scores.min(), scores.max()
    for i, u in enumerate(users):
        u["anomalie"] = bool(preds[i] == -1)
        u["score_risque"] = int((1-(scores[i]-smin)/(smax-smin+1e-9))*100)
        raisons = []
        if u["ratio_nuit"] > 0.3:
            raisons.append(f"Acces nocturnes : {int(u['ratio_nuit']*100)}%")
        if u["acces_par_jour"] > 50:
            raisons.append(f"Trop d acces/jour : {u['acces_par_jour']}")
        if u["patients_moy"] > 50:
            raisons.append(f"Trop de patients/acces : {u['patients_moy']}")
        if u["nb_ips"] > 3:
            raisons.append(f"Connexions depuis {u['nb_ips']} IPs")
        u["raisons"] = raisons if raisons else ["Comportement statistiquement anormal"]
    return users

# RAPPORT
def rapport(users):
    tries = sorted(users, key=lambda x: x.get("score_risque",0), reverse=True)
    anomalies = [u for u in tries if u.get("anomalie")]
    normaux = [u for u in tries if not u.get("anomalie")]

    print("\n" + "="*55)
    print("  RAPPORT ANOMALIES - CHU IBN SINA RABAT")
    print(f"  {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*55)
    print(f"\nUtilisateurs analyses : {len(users)}")
    print(f"Anomalies detectees   : {len(anomalies)}")
    print(f"Comportements normaux : {len(normaux)}")

    if anomalies:
        print("\n--- ALERTES SUSPECTS ---")
        for u in anomalies:
            print(f"\n SUSPECT : {u['username']} ({u['role']})")
            print(f"   Score risque   : {u['score_risque']}/100")
            print(f"   Nb acces       : {u['nb_acces']}")
            print(f"   Patients/acces : {u['patients_moy']}")
            print(f"   Acces nocturnes: {int(u['ratio_nuit']*100)}%")
            for r in u["raisons"]:
                print(f"   ! {r}")

    print("\n--- UTILISATEURS NORMAUX ---")
    for u in normaux:
        print(f"  OK {u['username']:20} | Risque: {u['score_risque']:3}/100 | Acces: {u['nb_acces']}")

    with open("ml/anomaly_report.json", "w", encoding="utf-8") as f:
        json.dump({"date": datetime.now().isoformat(), "hopital": "CHU Ibn Sina Rabat",
                   "modele": "Isolation Forest", "total": len(users),
                   "anomalies": len(anomalies), "utilisateurs": tries}, f, ensure_ascii=False, indent=2)

    print(f"\nRapport sauvegarde : ml/anomaly_report.json")
    print("="*55)
    print("ANALYSE ML TERMINEE !")

# MAIN
logs = get_logs() or logs_simules()
users, features = preparer(logs)
users = analyser(users, features)
rapport(users)