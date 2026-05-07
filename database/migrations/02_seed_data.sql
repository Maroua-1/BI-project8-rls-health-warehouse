-- ================================================================
-- SEED : DONNEES MAROCAINES REALISTES
-- Hopital Universitaire Ibn Sina - Rabat
-- 5000 patients, 50000+ consultations, 2020-2024
-- ================================================================

-- DIMENSION TEMPS (2020-2024)
INSERT INTO dim_temps (date_complete,annee,trimestre,mois,nom_mois,semaine,jour_semaine,nom_jour,est_weekend,est_ferie,saison)
SELECT
  d::DATE,
  EXTRACT(YEAR FROM d)::SMALLINT,
  EXTRACT(QUARTER FROM d)::SMALLINT,
  EXTRACT(MONTH FROM d)::SMALLINT,
  CASE EXTRACT(MONTH FROM d)::INT
    WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Fevrier' WHEN 3 THEN 'Mars'
    WHEN 4 THEN 'Avril' WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin'
    WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Aout' WHEN 9 THEN 'Septembre'
    WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Decembre'
  END,
  EXTRACT(WEEK FROM d)::SMALLINT,
  EXTRACT(DOW FROM d)::SMALLINT + 1,
  CASE EXTRACT(DOW FROM d)::INT
    WHEN 0 THEN 'Dimanche' WHEN 1 THEN 'Lundi' WHEN 2 THEN 'Mardi'
    WHEN 3 THEN 'Mercredi' WHEN 4 THEN 'Jeudi' WHEN 5 THEN 'Vendredi'
    WHEN 6 THEN 'Samedi'
  END,
  EXTRACT(DOW FROM d) IN (0,6),
  d::DATE IN ('2020-01-01','2020-05-01','2020-07-30','2020-08-20','2020-11-06',
              '2021-01-01','2021-05-01','2021-07-30','2021-08-20','2021-11-06',
              '2022-01-01','2022-05-01','2022-07-30','2022-08-20','2022-11-06',
              '2023-01-01','2023-05-01','2023-07-30','2023-08-20','2023-11-06',
              '2024-01-01','2024-05-01','2024-07-30','2024-08-20','2024-11-06'),
  CASE EXTRACT(MONTH FROM d)::INT
    WHEN 12 THEN 'Hiver' WHEN 1 THEN 'Hiver' WHEN 2 THEN 'Hiver'
    WHEN 3 THEN 'Printemps' WHEN 4 THEN 'Printemps' WHEN 5 THEN 'Printemps'
    WHEN 6 THEN 'Ete' WHEN 7 THEN 'Ete' WHEN 8 THEN 'Ete'
    WHEN 9 THEN 'Automne' WHEN 10 THEN 'Automne' WHEN 11 THEN 'Automne'
  END
FROM generate_series('2020-01-01'::date,'2024-12-31'::date,'1 day'::interval) d;

-- REGIONS DU MAROC
INSERT INTO dim_region (code_region,nom_region,chef_lieu) VALUES
('RSK','Rabat-Sale-Kenitra','Rabat'),
('CD','Casablanca-Settat','Casablanca'),
('MTE','Marrakech-Safi','Marrakech'),
('FMK','Fes-Meknes','Fes'),
('TE','Tanger-Tetouan-Al Hoceima','Tanger'),
('OR','Oriental','Oujda'),
('BK','Beni Mellal-Khenifra','Beni Mellal'),
('SD','Souss-Massa','Agadir'),
('DS','Draa-Tafilalet','Errachidia'),
('GS','Guelmim-Oued Noun','Guelmim'),
('LS','Laayoune-Sakia El Hamra','Laayoune'),
('DA','Dakhla-Oued Ed-Dahab','Dakhla');

-- VILLES
INSERT INTO dim_ville (region_id,nom_ville,code_postal) VALUES
((SELECT region_id FROM dim_region WHERE code_region='RSK'),'Rabat','10000'),
((SELECT region_id FROM dim_region WHERE code_region='RSK'),'Sale','11000'),
((SELECT region_id FROM dim_region WHERE code_region='RSK'),'Kenitra','14000'),
((SELECT region_id FROM dim_region WHERE code_region='RSK'),'Temara','12000'),
((SELECT region_id FROM dim_region WHERE code_region='CD'),'Casablanca','20000'),
((SELECT region_id FROM dim_region WHERE code_region='CD'),'Mohammedia','28800'),
((SELECT region_id FROM dim_region WHERE code_region='CD'),'El Jadida','24000'),
((SELECT region_id FROM dim_region WHERE code_region='MTE'),'Marrakech','40000'),
((SELECT region_id FROM dim_region WHERE code_region='MTE'),'Safi','46000'),
((SELECT region_id FROM dim_region WHERE code_region='FMK'),'Fes','30000'),
((SELECT region_id FROM dim_region WHERE code_region='FMK'),'Meknes','50000'),
((SELECT region_id FROM dim_region WHERE code_region='TE'),'Tanger','90000'),
((SELECT region_id FROM dim_region WHERE code_region='TE'),'Tetouan','93000'),
((SELECT region_id FROM dim_region WHERE code_region='OR'),'Oujda','60000'),
((SELECT region_id FROM dim_region WHERE code_region='SD'),'Agadir','80000'),
((SELECT region_id FROM dim_region WHERE code_region='BK'),'Beni Mellal','23000'),
((SELECT region_id FROM dim_region WHERE code_region='DS'),'Errachidia','52000'),
((SELECT region_id FROM dim_region WHERE code_region='DS'),'Ouarzazate','45000'),
((SELECT region_id FROM dim_region WHERE code_region='GS'),'Guelmim','81000'),
((SELECT region_id FROM dim_region WHERE code_region='LS'),'Laayoune','70000');

-- SERVICES HOSPITALIERS
INSERT INTO dim_service (code_service,nom_service,type_service,batiment,capacite_lits,chef_service) VALUES
('URG','Urgences Medicales','Urgences','Batiment A',40,'Pr. Hassan Zerouali'),
('URG-C','Urgences Chirurgicales','Urgences','Batiment A',20,'Pr. Mohamed Benbella'),
('CARD','Cardiologie','Medecine','Batiment B',35,'Pr. Fatima Benali'),
('NEU','Neurologie','Medecine','Batiment B',30,'Pr. Ahmed Rhanem'),
('PNEUM','Pneumologie','Medecine','Batiment B',32,'Pr. Rachida Ouazzani'),
('GASTRO','Gastro-enterologie','Medecine','Batiment C',28,'Pr. Karim Tahiri'),
('NEPH','Nephrologie','Medecine','Batiment C',25,'Pr. Samira Kettani'),
('ENDO','Endocrinologie-Diabetologie','Medecine','Batiment C',22,'Pr. Youssef Lahlou'),
('HEMATO','Hematologie','Medecine','Batiment D',30,'Pr. Omar Messaoudi'),
('INFECT','Maladies Infectieuses','Medecine','Batiment E',40,'Pr. Latifa Benomar'),
('CHIR-G','Chirurgie Generale','Chirurgie','Batiment F',35,'Pr. Driss Benchekroun'),
('CHIR-O','Chirurgie Orthopedique','Chirurgie','Batiment F',30,'Pr. Mustapha Khattabi'),
('GYNE','Gynecologie-Obstetrique','Chirurgie','Batiment G',50,'Pr. Amina Filali'),
('PED','Pediatrie','Medecine','Batiment H',45,'Pr. Sophia Benchekroun'),
('NEO','Neonatologie','Medecine','Batiment H',20,'Pr. Noureddine Alaoui'),
('PSY','Psychiatrie','Medecine','Batiment I',35,'Pr. Zineb Tazi'),
('ONCO','Oncologie','Medecine','Batiment J',40,'Pr. Abderrahim Elomrani'),
('RADIO','Radiologie','Plateau technique','Batiment K',0,'Pr. Hassan Ennouali'),
('LABO','Laboratoire','Plateau technique','Batiment K',0,'Pr. Ilham Bouzid'),
('REA','Reanimation','Medecine','Batiment M',15,'Pr. Brahim El Harti'),
('CONS','Consultations Externes','Consultation externe','Batiment N',0,'Dr. Aicha Berrada'),
('ADMIN','Direction Administrative','Administratif','Batiment O',0,'M. Khalid Bensouda');

-- MEDECINS
INSERT INTO dim_medecin (matricule,nom,prenom,specialite,grade,service_id,email_pro,date_recrutement,ordre_medecins) VALUES
('MED-001','Zerouali','Hassan','Medecine Urgence','PH',(SELECT service_id FROM dim_service WHERE code_service='URG'),'h.zerouali@chu-ibnsina.ma','2005-09-01','MA-URG-2005-001'),
('MED-002','Benbella','Mohamed','Chirurgie Urgence','PH',(SELECT service_id FROM dim_service WHERE code_service='URG-C'),'m.benbella@chu-ibnsina.ma','2008-03-15','MA-CHIR-2008-042'),
('MED-003','Bouhali','Amina','Medecine Urgence','PHU',(SELECT service_id FROM dim_service WHERE code_service='URG'),'a.bouhali@chu-ibnsina.ma','2010-09-01','MA-URG-2010-015'),
('MED-010','Benali','Fatima','Cardiologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='CARD'),'f.benali@chu-ibnsina.ma','2003-09-01','MA-CARD-2003-007'),
('MED-011','Hajjam','Mehdi','Cardiologie','PH',(SELECT service_id FROM dim_service WHERE code_service='CARD'),'m.hajjam@chu-ibnsina.ma','2007-09-01','MA-CARD-2007-023'),
('MED-012','Bennani','Zineb','Cardiologie','PH',(SELECT service_id FROM dim_service WHERE code_service='CARD'),'z.bennani@chu-ibnsina.ma','2011-09-01','MA-CARD-2011-055'),
('MED-020','Rhanem','Ahmed','Neurologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='NEU'),'a.rhanem@chu-ibnsina.ma','2004-09-01','MA-NEU-2004-012'),
('MED-021','El Fassi','Meryem','Neurologie','PH',(SELECT service_id FROM dim_service WHERE code_service='NEU'),'m.elfassi@chu-ibnsina.ma','2009-09-01','MA-NEU-2009-034'),
('MED-030','Ouazzani','Rachida','Pneumologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='PNEUM'),'r.ouazzani@chu-ibnsina.ma','2002-09-01','MA-PNEUM-2002-003'),
('MED-031','Chraibi','Salim','Pneumologie','PH',(SELECT service_id FROM dim_service WHERE code_service='PNEUM'),'s.chraibi@chu-ibnsina.ma','2008-09-01','MA-PNEUM-2008-031'),
('MED-040','Tahiri','Karim','Gastro-enterologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='GASTRO'),'k.tahiri@chu-ibnsina.ma','2006-09-01','MA-GASTRO-2006-019'),
('MED-050','Lahlou','Youssef','Endocrinologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='ENDO'),'y.lahlou@chu-ibnsina.ma','2005-09-01','MA-ENDO-2005-011'),
('MED-051','Ezzoubeir','Sanaa','Endocrinologie','PH',(SELECT service_id FROM dim_service WHERE code_service='ENDO'),'s.ezzoubeir@chu-ibnsina.ma','2010-09-01','MA-ENDO-2010-043'),
('MED-060','Messaoudi','Omar','Hematologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='HEMATO'),'o.messaoudi@chu-ibnsina.ma','2007-09-01','MA-HEMATO-2007-027'),
('MED-070','Benomar','Latifa','Maladies Infectieuses','PHU',(SELECT service_id FROM dim_service WHERE code_service='INFECT'),'l.benomar@chu-ibnsina.ma','2003-09-01','MA-INFECT-2003-008'),
('MED-080','Benchekroun','Driss','Chirurgie Generale','PHU',(SELECT service_id FROM dim_service WHERE code_service='CHIR-G'),'d.benchekroun@chu-ibnsina.ma','2001-09-01','MA-CHIR-2001-002'),
('MED-081','El Alami','Abdessalam','Chirurgie Generale','PH',(SELECT service_id FROM dim_service WHERE code_service='CHIR-G'),'a.elalami@chu-ibnsina.ma','2008-09-01','MA-CHIR-2008-039'),
('MED-090','Filali','Amina','Gynecologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='GYNE'),'a.filali@chu-ibnsina.ma','2004-09-01','MA-GYNE-2004-014'),
('MED-091','Berrada','Souad','Gynecologie','PH',(SELECT service_id FROM dim_service WHERE code_service='GYNE'),'s.berrada@chu-ibnsina.ma','2009-09-01','MA-GYNE-2009-036'),
('MED-100','Benchekroun','Sophia','Pediatrie','PHU',(SELECT service_id FROM dim_service WHERE code_service='PED'),'s.benchekroun@chu-ibnsina.ma','2004-09-01','MA-PED-2004-015'),
('MED-110','Elomrani','Abderrahim','Oncologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='ONCO'),'a.elomrani@chu-ibnsina.ma','2006-09-01','MA-ONCO-2006-021'),
('MED-111','Bensouda','Lamia','Oncologie','PH',(SELECT service_id FROM dim_service WHERE code_service='ONCO'),'l.bensouda@chu-ibnsina.ma','2011-09-01','MA-ONCO-2011-057'),
('MED-120','El Harti','Brahim','Reanimation','PHU',(SELECT service_id FROM dim_service WHERE code_service='REA'),'b.elharti@chu-ibnsina.ma','2005-09-01','MA-REA-2005-013'),
('MED-130','Tazi','Zineb','Psychiatrie','PHU',(SELECT service_id FROM dim_service WHERE code_service='PSY'),'z.tazi@chu-ibnsina.ma','2007-09-01','MA-PSY-2007-028'),
('MED-140','Hajjioui','Nadia','Rhumatologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='CARD'),'n.hajjioui@chu-ibnsina.ma','2008-09-01','MA-RHUM-2008-035'),
('MED-150','Kettani','Samira','Nephrologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='NEPH'),'s.kettani@chu-ibnsina.ma','2006-09-01','MA-NEPH-2006-020'),
('MED-160','Ennouali','Hassan','Radiologie','PHU',(SELECT service_id FROM dim_service WHERE code_service='RADIO'),'h.ennouali@chu-ibnsina.ma','2004-09-01','MA-RADIO-2004-016'),
('MED-170','Khattabi','Mustapha','Chirurgie Orthopedique','PHU',(SELECT service_id FROM dim_service WHERE code_service='CHIR-O'),'m.khattabi@chu-ibnsina.ma','2003-09-01','MA-CHIR-2003-009');

-- DIAGNOSTICS CIM-10
INSERT INTO dim_diagnostic (code_cim10,libelle,libelle_court,categorie,gravite,chronique,infectieux) VALUES
('E11.9','Diabete de type 2 sans complications','Diabete type 2','Maladies endocriniennes','Moderee',true,false),
('E11.65','Diabete type 2 avec hyperglycemie','Diabete decompense','Maladies endocriniennes','Severe',true,false),
('I10','Hypertension arterielle essentielle','HTA','Maladies cardiovasculaires','Moderee',true,false),
('I21.9','Infarctus aigu du myocarde','IDM','Maladies cardiovasculaires','Critique',false,false),
('I50.9','Insuffisance cardiaque','Insuffisance cardiaque','Maladies cardiovasculaires','Severe',true,false),
('I63.9','Infarctus cerebral','AVC ischemique','Maladies cerebrovasculaires','Critique',false,false),
('J18.9','Pneumonie sans precision','Pneumonie','Maladies respiratoires','Severe',false,true),
('J45.9','Asthme sans precision','Asthme','Maladies respiratoires','Moderee',true,false),
('J11.1','Grippe avec manifestations respiratoires','Grippe','Maladies respiratoires','Legere',false,true),
('K74.6','Cirrhose du foie','Cirrhose hepatique','Maladies digestives','Severe',true,false),
('K80.2','Calcul vesicule biliaire avec cholecystite','Cholecystite','Maladies digestives','Severe',false,false),
('N18.3','Maladie renale chronique stade 3','IRC stade 3','Maladies renales','Moderee',true,false),
('N18.5','Maladie renale chronique stade 5','IRC stade 5','Maladies renales','Critique',true,false),
('C34.1','Tumeur maligne poumon','Cancer poumon','Tumeurs malignes','Severe',false,false),
('C50.9','Tumeur maligne sein','Cancer sein','Tumeurs malignes','Severe',false,false),
('C18.9','Tumeur maligne colon','Cancer colon','Tumeurs malignes','Severe',false,false),
('A15.0','Tuberculose pulmonaire','Tuberculose','Maladies infectieuses','Severe',false,true),
('A09','Gastro-enterite infectieuse','GEA infectieuse','Maladies infectieuses','Legere',false,true),
('M54.5','Lombalgies','Lombalgies','Maladies osteo-articulaires','Legere',false,false),
('S72.0','Fracture col femur','Fracture col femur','Traumatismes','Severe',false,false),
('S06.0','Commotion cerebrale','Commotion cerebrale','Traumatismes','Moderee',false,false),
('O80','Accouchement normal','Accouchement','Obstetrique','Legere',false,false),
('F32.1','Episode depressif moyen','Depression','Troubles mentaux','Moderee',false,false),
('G40.9','Epilepsie sans precision','Epilepsie','Maladies neurologiques','Moderee',true,false),
('N39.0','Infection voies urinaires','Infection urinaire','Maladies urinaires','Legere',false,true),
('R55','Syncope et collapsus','Syncope','Symptomes','Moderee',false,false),
('Z34.0','Surveillance grossesse T1','Grossesse T1','Grossesse','Legere',false,false),
('L50.9','Urticaire','Urticaire','Maladies cutanees','Legere',false,false),
('B24','Maladie VIH non precisee','VIH/SIDA','Maladies infectieuses','Severe',true,true),
('I64','AVC non precise','AVC NOS','Maladies cerebrovasculaires','Critique',false,false);

-- MEDICAMENTS
INSERT INTO dim_medicament (dci,nom_commercial,classe_atc,forme,dosage,prix_unitaire,remboursable) VALUES
('Metformine','Glucophage','A10BB','Comprime','850mg',2.50,true),
('Insuline Glargine','Lantus','A10AE','Injectable','100UI/ml',185.00,true),
('Amlodipine','Amlor','C08CA','Comprime','5mg',3.20,true),
('Ramipril','Triatec','C09AA','Comprime','5mg',4.10,true),
('Atorvastatine','Tahor','C10AA','Comprime','40mg',5.80,true),
('Aspirine','Aspegic','B01AC','Sachet','100mg',0.85,true),
('Omeprazole','Mopral','A02BC','Gelule','20mg',2.30,true),
('Paracetamol','Doliprane','N02BE','Comprime','1000mg',1.20,true),
('Amoxicilline','Clamoxyl','J01CA','Gelule','500mg',3.50,true),
('Ciprofloxacine','Ciflox','J01MA','Comprime','500mg',7.20,true),
('Furosemide','Lasilix','C03CA','Comprime','40mg',1.10,true),
('Salbutamol','Ventoline','R03AC','Aerosol','100mcg',18.50,true),
('Ceftriaxone','Roсephine','J01DD','Injectable','1g',45.00,true),
('Heparine','Heparine sodique','B01AB','Injectable','5000UI/ml',22.00,true),
('Morphine','Chlorhydrate Morphine','N02AA','Injectable','10mg/1ml',8.50,true),
('Prednisolone','Solupred','H02AB','Comprime','20mg',1.95,true),
('Diclofenac','Voltarene','M01AB','Comprime','50mg',2.10,true),
('Acide valproique','Depakine','N03AG','Solution','200mg/ml',38.00,true),
('Levothyroxine','Levothyrox','H03AA','Comprime','100mcg',3.60,true),
('Ondansetron','Zophren','A04AA','Comprime','8mg',22.50,true);

-- ACTES MEDICAUX
INSERT INTO dim_acte (code_acte,libelle,famille,tarif_cnops,necessite_bloc) VALUES
('CS','Consultation medicale specialisee','Consultations',150,false),
('CSG','Consultation generaliste','Consultations',80,false),
('ECG','Electrocardiogramme','Explorations',120,false),
('ECHO-C','Echocardiographie','Explorations',450,false),
('RADIO-T','Radiographie thoracique','Imagerie',150,false),
('SCANNER','Scanner thoraco-abdomino-pelvien','Imagerie',1200,false),
('IRM','IRM cerebrale','Imagerie',1800,false),
('NFS','Numeration Formule Sanguine','Biologie',80,false),
('BILAN-D','Bilan diabetique HbA1c','Biologie',180,false),
('GASTRO','Fibroscopie gastrique','Endoscopie',600,true),
('COLO','Coloscopie totale','Endoscopie',750,true),
('CHOL','Cholecystectomie laparoscopique','Chirurgie',3500,true),
('APPEN','Appendicectomie','Chirurgie',2800,true),
('PTH','Prothese Totale de Hanche','Chirurgie',8000,true),
('DIALYSE','Hemodialyse seance','Soins specialises',320,false),
('CHIMIO','Cure de chimiotherapie','Soins specialises',2500,false),
('ACCOU','Accouchement voie basse','Obstetrique',1200,false),
('CESAR','Cesarienne','Obstetrique',4000,true),
('SUTURE','Sutures cutanees','Soins urgences',200,false),
('PLAT','Pose de platre','Soins urgences',350,false);

-- 5000 PATIENTS MAROCAINS
INSERT INTO dim_patient (nom,prenom,cin,telephone,email,adresse,date_naissance,sexe,groupe_sanguin,allergies,antecedents,ville_id,mutuelle,ramed)
SELECT
  (ARRAY['El Idrissi','Benali','Alaoui','El Fassi','Bensouda','Tazi','Bennani','El Harti',
         'Chraibi','Benomar','Lahlou','Berrada','Filali','Kettani','Tahiri','Bouzid',
         'Messaoudi','Ouali','Hajjam','El Mansouri','Zerouali','Chaoui','Benbella',
         'Maamar','Khalili','Essayegh','Mouline','Benabdallah','El Kabbaj','Fassi',
         'Benkirane','El Ghali','Cherkaoui','Amrani','Benhima','Ouazzani','Serghini',
         'El Ghazouani','Naciri','El Jadidi','Bennis','Regragui','Skalli','Bekkali',
         'El Rhazi','Belkadi','Belmahi','Sabri','Chafii','El Hachimi'])[floor(random()*50+1)::INT],
  CASE WHEN floor(random()*2)=0 THEN
    (ARRAY['Mohammed','Ahmed','Hassan','Youssef','Ibrahim','Khalid','Rachid','Omar',
           'Mustapha','Driss','Karim','Mehdi','Hamid','Abdelkader','Noureddine',
           'Brahim','Abdessalam','Salim','Tarik','Amine','Samir','Hicham','Ismail',
           'Anass','Othmane','Bilal','Adil','Reda','Ayoub','Ilias'])[floor(random()*30+1)::INT]
  ELSE
    (ARRAY['Fatima','Aicha','Khadija','Zineb','Meryem','Samira','Nadia','Rachida',
           'Souad','Houda','Leila','Amina','Sanaa','Imane','Laila','Hind','Sara',
           'Hafsa','Lamia','Siham','Chaima','Dounia','Nour','Yasmine','Malak',
           'Inas','Aya','Rania','Ghita','Rim'])[floor(random()*30+1)::INT]
  END,
  'MA'||LPAD(floor(random()*99999999)::TEXT,8,'0'),
  '06'||LPAD(floor(random()*99999999)::TEXT,8,'0'),
  'patient'||gs||'@gmail.com',
  floor(random()*999+1)::TEXT||' Rue '||
    (ARRAY['Mohammed V','Hassan II','Al Massira','Ibn Battouta','Allal Ben Abdellah',
           'Moulay Youssef','Al Qods','Abdelmoumen','Imam Malik','Al Fida'])[floor(random()*10+1)::INT],
  (NOW()-(INTERVAL '1 year'*(floor(random()*75)+15)))::DATE,
  CASE WHEN floor(random()*2)=0 THEN 'M' ELSE 'F' END,
  (ARRAY['A+','A-','B+','B-','AB+','AB-','O+','O-'])[floor(random()*8+1)::INT],
  CASE WHEN random()<0.15 THEN
    (ARRAY['Penicilline','Aspirine','Sulfamides','Latex','Iode','Morphine'])[floor(random()*6+1)::INT]
  ELSE NULL END,
  CASE WHEN random()<0.3 THEN
    (ARRAY['HTA','Diabete type 2','Asthme','Epilepsie','Hypothyroidie','Cardiopathie'])[floor(random()*6+1)::INT]
  ELSE NULL END,
  floor(random()*20+1)::INT,
  CASE WHEN random()<0.35 THEN
    (ARRAY['CNOPS','CNSS','FAR','CMR','MAMDA','Mutuelle Generale','RMA Watanya'])[floor(random()*7+1)::INT]
  ELSE NULL END,
  random()<0.25
FROM generate_series(1,5000) gs;

-- 50 000+ CONSULTATIONS (2020-2024)
INSERT INTO faits_consultation (
  temps_id,patient_id,medecin_id,service_id,diagnostic_id,
  type_visite,mode_entree,date_entree,date_sortie,duree_sejour_h,
  tension_sys,tension_dia,temperature,spo2,glycemie,poids_kg,score_glasgow,
  mode_sortie,cout_actes,cout_medicaments,cout_hebergement,cout_total,
  prise_en_charge,montant_rembourse,reste_a_charge
)
SELECT
  dt.temps_id,
  floor(random()*5000+1)::INT,
  floor(random()*28+1)::INT,
  floor(random()*22+1)::INT,
  floor(random()*30+1)::INT,
  (ARRAY['Urgence','Consultation','Hospitalisation','Chirurgie','Teleconsultation'])[floor(random()*5+1)::INT],
  (ARRAY['Spontane','Refere','SAMU','Transfert'])[floor(random()*4+1)::INT],
  dt.date_complete::TIMESTAMPTZ + (floor(random()*86400)||' seconds')::INTERVAL,
  dt.date_complete::TIMESTAMPTZ + (floor(random()*86400)||' seconds')::INTERVAL + (floor(random()*120)||' hours')::INTERVAL,
  round((random()*120)::NUMERIC,1),
  floor(random()*80+100)::SMALLINT,
  floor(random()*40+60)::SMALLINT,
  round((random()*3+36.5)::NUMERIC,1),
  floor(random()*10+90)::SMALLINT,
  round((random()*8+4.5)::NUMERIC,1),
  round((random()*60+50)::NUMERIC,1),
  floor(random()*7+9)::SMALLINT,
  (ARRAY['Gueri','Ameliore','Transfere','Decede','Contre AV','En cours'])[floor(random()*6+1)::INT],
  round((random()*1500+200)::NUMERIC,2),
  round((random()*800+50)::NUMERIC,2),
  round((random()*1200)::NUMERIC,2),
  round((random()*3000+300)::NUMERIC,2),
  (ARRAY['AMO','RAMED','Mutuelles','Payant','IPM'])[floor(random()*5+1)::INT],
  round((random()*2000)::NUMERIC,2),
  round((random()*800)::NUMERIC,2)
FROM dim_temps dt
CROSS JOIN generate_series(1,28) gs
WHERE dt.date_complete BETWEEN '2020-01-01' AND '2024-12-31'
AND random()<0.98;

-- PRESCRIPTIONS
INSERT INTO faits_prescription (consultation_id,medicament_id,medecin_id,temps_id,posologie,duree_jours,quantite,cout_total)
SELECT
  fc.consultation_id,
  floor(random()*20+1)::INT,
  fc.medecin_id,
  fc.temps_id,
  (ARRAY['1 cp matin','1 cp soir','2 cp/j','1 amp IV/8h','1 nebulisation 3x/j'])[floor(random()*5+1)::INT],
  floor(random()*30+5)::SMALLINT,
  floor(random()*60+10)::SMALLINT,
  round((random()*200+20)::NUMERIC,2)
FROM faits_consultation fc
WHERE random()<0.7;

-- ACTES REALISES
INSERT INTO faits_acte_realise (consultation_id,acte_id,medecin_id,temps_id,quantite,montant_facture)
SELECT
  fc.consultation_id,
  floor(random()*20+1)::INT,
  fc.medecin_id,
  fc.temps_id,
  1,
  round((random()*2000+100)::NUMERIC,2)
FROM faits_consultation fc
WHERE random()<0.6;

ANALYZE dim_patient;
ANALYZE faits_consultation;
ANALYZE faits_prescription;
ANALYZE faits_acte_realise;

DO \$\$ BEGIN
  RAISE NOTICE '✅ Donnees chargees - Hopital Ibn Sina Rabat';
  RAISE NOTICE '✅ 5000 patients marocains';
  RAISE NOTICE '✅ 50000+ consultations 2020-2024';
END \$\$;
