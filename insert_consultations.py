import subprocess
import random
from datetime import datetime, timedelta
import os

print('Debut insertion consultations...')

types_visite = ['Consultation','Urgence','Hospitalisation','Chirurgie','Teleconsultation']
modes_entree = ['Spontane','Refere','SAMU','Transfert']
modes_sortie = ['Gueri','Ameliore','Transfere','Decede','Contre AV','En cours']
prises_charge = ['RAMED','AMO','Mutuelles','Payant','IPM']

random.seed(42)
date_debut = datetime(2020, 1, 1)
BATCH_SIZE = 1000
TOTAL = 50000

cols = "temps_id,patient_id,medecin_id,service_id,diagnostic_id,type_visite,mode_entree,date_entree,date_sortie,duree_sejour_h,tension_sys,tension_dia,temperature,spo2,glycemie,poids_kg,score_glasgow,mode_sortie,cout_actes,cout_medicaments,cout_hebergement,cout_total,prise_en_charge,montant_rembourse,reste_a_charge"

for batch_num in range(0, TOTAL, BATCH_SIZE):
    values = []
    for i in range(BATCH_SIZE):
        jours = random.randint(0, 1826)
        date_entree = date_debut + timedelta(days=jours, hours=random.randint(0,23))
        date_sortie = date_entree + timedelta(hours=random.randint(1,120))
        temps_id = jours + 1
        patient_id = random.randint(1, 38236)
        medecin_id = random.randint(1, 29)
        service_id = random.randint(1, 22)
        diag_id = random.randint(1, 30)
        type_v = random.choice(types_visite)
        mode_e = random.choice(modes_entree)
        mode_s = random.choice(modes_sortie)
        prise_c = random.choice(prises_charge)
        duree = round(random.uniform(1, 120), 1)
        tension_sys = random.randint(110, 180)
        tension_dia = random.randint(65, 100)
        temp = round(random.uniform(36.5, 39.5), 1)
        spo2 = random.randint(90, 100)
        glycemie = round(random.uniform(4.5, 18.0), 1)
        poids = round(random.uniform(55, 110), 1)
        glasgow = random.randint(9, 15)
        cout_actes = round(random.uniform(150, 1500), 2)
        cout_meds = round(random.uniform(50, 600), 2)
        cout_heberg = round(random.uniform(0, 800), 2)
        cout_total = round(cout_actes + cout_meds + cout_heberg, 2)
        rembourse = round(cout_total * random.uniform(0.5, 0.85), 2) if prise_c != 'Payant' else 0
        reste = round(cout_total - rembourse, 2)

        v = "({},{},{},{},{},".format(temps_id,patient_id,medecin_id,service_id,diag_id)
        v += "'{}','{}',".format(type_v,mode_e)
        v += "'{}',".format(date_entree.strftime('%Y-%m-%d %H:%M:%S'))
        v += "'{}',".format(date_sortie.strftime('%Y-%m-%d %H:%M:%S'))
        v += "{},{},{},{},{},".format(duree,tension_sys,tension_dia,temp,spo2)
        v += "{},{},{},'{}',".format(glycemie,poids,glasgow,mode_s)
        v += "{},{},{},{},".format(cout_actes,cout_meds,cout_heberg,cout_total)
        v += "'{}',{},{})".format(prise_c,rembourse,reste)
        values.append(v)

    sql = "INSERT INTO faits_consultation ({}) VALUES {};\n".format(cols, ','.join(values))

    # Ecrire le SQL dans un fichier temporaire
    tmp_file = 'tmp_batch.sql'
    with open(tmp_file, 'w', encoding='utf-8') as f:
        f.write(sql)

    # Copier le fichier dans le container
    subprocess.run(['docker','cp', tmp_file, 'hopital_postgres:/tmp/batch.sql'], capture_output=True)

    # Executer depuis le container
    result = subprocess.run(
        ['docker','exec','hopital_postgres','psql','-U','hopital_admin','-d','hopital_maroc','-f','/tmp/batch.sql'],
        capture_output=True, text=True
    )

    num = batch_num // BATCH_SIZE + 1
    total_lots = TOTAL // BATCH_SIZE
    if 'INSERT' in result.stdout:
        print("Lot {}/{} OK : {} consultations inserees".format(num, total_lots, batch_num + BATCH_SIZE))
    else:
        print("ERREUR lot {}: {}".format(num, result.stderr[:200]))

# Nettoyage
if os.path.exists('tmp_batch.sql'):
    os.remove('tmp_batch.sql')

print('Verification finale...')
result = subprocess.run(
    ['docker','exec','hopital_postgres','psql','-U','hopital_admin','-d','hopital_maroc','-c','SELECT COUNT(*) FROM faits_consultation;'],
    capture_output=True, text=True
)
print(result.stdout)
print('TERMINE !')