-- ================================================================
-- PROJET 8 : SECURITE DYNAMIQUE - HOPITAL IBN SINA RABAT
-- Migration 01 : Schema en etoile + Roles + RLS
-- ================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ROLES POSTGRESQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_medecin') THEN CREATE ROLE role_medecin; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_administratif') THEN CREATE ROLE role_administratif; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_chercheur') THEN CREATE ROLE role_chercheur; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_infirmier') THEN CREATE ROLE role_infirmier; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_directeur') THEN CREATE ROLE role_directeur; END IF;
END
\$\$;

-- DIMENSION TEMPS
CREATE TABLE dim_temps (
  temps_id      SERIAL PRIMARY KEY,
  date_complete DATE NOT NULL UNIQUE,
  annee         SMALLINT NOT NULL,
  trimestre     SMALLINT NOT NULL,
  mois          SMALLINT NOT NULL,
  nom_mois      VARCHAR(20) NOT NULL,
  semaine       SMALLINT NOT NULL,
  jour_semaine  SMALLINT NOT NULL,
  nom_jour      VARCHAR(20) NOT NULL,
  est_weekend   BOOLEAN NOT NULL DEFAULT false,
  est_ferie     BOOLEAN NOT NULL DEFAULT false,
  saison        VARCHAR(10)
);

-- DIMENSION REGION
CREATE TABLE dim_region (
  region_id   SERIAL PRIMARY KEY,
  code_region VARCHAR(10) UNIQUE NOT NULL,
  nom_region  VARCHAR(100) NOT NULL,
  chef_lieu   VARCHAR(100) NOT NULL
);

-- DIMENSION VILLE
CREATE TABLE dim_ville (
  ville_id  SERIAL PRIMARY KEY,
  region_id INTEGER NOT NULL REFERENCES dim_region(region_id),
  nom_ville VARCHAR(100) NOT NULL,
  code_postal VARCHAR(10)
);

-- DIMENSION PATIENT
CREATE TABLE dim_patient (
  patient_id     SERIAL PRIMARY KEY,
  uuid_patient   UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  nom            VARCHAR(100),
  prenom         VARCHAR(100),
  cin            VARCHAR(20),
  telephone      VARCHAR(20),
  email          VARCHAR(150),
  adresse        TEXT,
  date_naissance DATE,
  sexe           CHAR(1) CHECK (sexe IN ('M','F')),
  groupe_sanguin VARCHAR(5),
  allergies      TEXT,
  antecedents    TEXT,
  ville_id       INTEGER REFERENCES dim_ville(ville_id),
  mutuelle       VARCHAR(100),
  ramed          BOOLEAN DEFAULT false,
  token_anonyme  VARCHAR(64) UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  date_creation  TIMESTAMPTZ DEFAULT NOW(),
  actif          BOOLEAN DEFAULT true
);

-- DIMENSION SERVICE
CREATE TABLE dim_service (
  service_id   SERIAL PRIMARY KEY,
  code_service VARCHAR(20) UNIQUE NOT NULL,
  nom_service  VARCHAR(150) NOT NULL,
  type_service VARCHAR(50),
  batiment     VARCHAR(50),
  capacite_lits INTEGER DEFAULT 0,
  chef_service VARCHAR(200),
  actif        BOOLEAN DEFAULT true
);

-- DIMENSION MEDECIN
CREATE TABLE dim_medecin (
  medecin_id       SERIAL PRIMARY KEY,
  matricule        VARCHAR(20) UNIQUE NOT NULL,
  nom              VARCHAR(100) NOT NULL,
  prenom           VARCHAR(100) NOT NULL,
  specialite       VARCHAR(100) NOT NULL,
  grade            VARCHAR(50),
  service_id       INTEGER REFERENCES dim_service(service_id),
  email_pro        VARCHAR(150) UNIQUE NOT NULL,
  date_recrutement DATE,
  ordre_medecins   VARCHAR(30) UNIQUE NOT NULL,
  actif            BOOLEAN DEFAULT true
);

-- DIMENSION DIAGNOSTIC
CREATE TABLE dim_diagnostic (
  diagnostic_id SERIAL PRIMARY KEY,
  code_cim10    VARCHAR(10) UNIQUE NOT NULL,
  libelle       VARCHAR(300) NOT NULL,
  libelle_court VARCHAR(100) NOT NULL,
  categorie     VARCHAR(100) NOT NULL,
  gravite       VARCHAR(20),
  chronique     BOOLEAN DEFAULT false,
  infectieux    BOOLEAN DEFAULT false
);

-- DIMENSION ACTE
CREATE TABLE dim_acte (
  acte_id      SERIAL PRIMARY KEY,
  code_acte    VARCHAR(20) UNIQUE NOT NULL,
  libelle      VARCHAR(300) NOT NULL,
  famille      VARCHAR(100) NOT NULL,
  tarif_cnops  NUMERIC(10,2),
  necessite_bloc BOOLEAN DEFAULT false
);

-- DIMENSION MEDICAMENT
CREATE TABLE dim_medicament (
  medicament_id  SERIAL PRIMARY KEY,
  dci            VARCHAR(200) NOT NULL,
  nom_commercial VARCHAR(200),
  classe_atc     VARCHAR(10),
  forme          VARCHAR(50),
  dosage         VARCHAR(50),
  prix_unitaire  NUMERIC(8,2),
  remboursable   BOOLEAN DEFAULT false
);

-- TABLE DE FAITS PRINCIPALE
CREATE TABLE faits_consultation (
  consultation_id  BIGSERIAL PRIMARY KEY,
  temps_id         INTEGER NOT NULL REFERENCES dim_temps(temps_id),
  patient_id       INTEGER NOT NULL REFERENCES dim_patient(patient_id),
  medecin_id       INTEGER NOT NULL REFERENCES dim_medecin(medecin_id),
  service_id       INTEGER NOT NULL REFERENCES dim_service(service_id),
  diagnostic_id    INTEGER REFERENCES dim_diagnostic(diagnostic_id),
  type_visite      VARCHAR(30),
  mode_entree      VARCHAR(30),
  date_entree      TIMESTAMPTZ NOT NULL,
  date_sortie      TIMESTAMPTZ,
  duree_sejour_h   NUMERIC(8,2),
  tension_sys      SMALLINT,
  tension_dia      SMALLINT,
  temperature      NUMERIC(4,1),
  spo2             SMALLINT,
  glycemie         NUMERIC(5,1),
  poids_kg         NUMERIC(5,1),
  score_glasgow    SMALLINT,
  mode_sortie      VARCHAR(30),
  cout_actes       NUMERIC(10,2),
  cout_medicaments NUMERIC(10,2),
  cout_hebergement NUMERIC(10,2),
  cout_total       NUMERIC(10,2),
  prise_en_charge  VARCHAR(30),
  montant_rembourse NUMERIC(10,2),
  reste_a_charge   NUMERIC(10,2),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- FAITS PRESCRIPTION
CREATE TABLE faits_prescription (
  prescription_id BIGSERIAL PRIMARY KEY,
  consultation_id BIGINT NOT NULL REFERENCES faits_consultation(consultation_id),
  medicament_id   INTEGER NOT NULL REFERENCES dim_medicament(medicament_id),
  medecin_id      INTEGER NOT NULL REFERENCES dim_medecin(medecin_id),
  temps_id        INTEGER NOT NULL REFERENCES dim_temps(temps_id),
  posologie       VARCHAR(200),
  duree_jours     SMALLINT,
  quantite        SMALLINT,
  cout_total      NUMERIC(8,2),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- FAITS ACTE REALISE
CREATE TABLE faits_acte_realise (
  acte_realise_id BIGSERIAL PRIMARY KEY,
  consultation_id BIGINT NOT NULL REFERENCES faits_consultation(consultation_id),
  acte_id         INTEGER NOT NULL REFERENCES dim_acte(acte_id),
  medecin_id      INTEGER NOT NULL REFERENCES dim_medecin(medecin_id),
  temps_id        INTEGER NOT NULL REFERENCES dim_temps(temps_id),
  quantite        SMALLINT DEFAULT 1,
  montant_facture NUMERIC(10,2),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- INDEX
CREATE INDEX idx_faits_temps     ON faits_consultation(temps_id);
CREATE INDEX idx_faits_patient   ON faits_consultation(patient_id);
CREATE INDEX idx_faits_medecin   ON faits_consultation(medecin_id);
CREATE INDEX idx_faits_service   ON faits_consultation(service_id);
CREATE INDEX idx_faits_date      ON faits_consultation(date_entree);
CREATE INDEX idx_patient_token   ON dim_patient(token_anonyme);

-- ACTIVER RLS
ALTER TABLE dim_patient        ENABLE ROW LEVEL SECURITY;
ALTER TABLE faits_consultation ENABLE ROW LEVEL SECURITY;
ALTER TABLE faits_prescription ENABLE ROW LEVEL SECURITY;
ALTER TABLE dim_patient        FORCE ROW LEVEL SECURITY;
ALTER TABLE faits_consultation FORCE ROW LEVEL SECURITY;

-- POLITIQUES MEDECIN
CREATE POLICY medecin_patient ON dim_patient
  FOR ALL TO role_medecin USING (true) WITH CHECK (true);
CREATE POLICY medecin_consultation ON faits_consultation
  FOR ALL TO role_medecin USING (true) WITH CHECK (true);
CREATE POLICY medecin_prescription ON faits_prescription
  FOR ALL TO role_medecin USING (true);

-- POLITIQUES ADMINISTRATIF
CREATE POLICY admin_patient ON dim_patient
  FOR SELECT TO role_administratif USING (actif = true);
CREATE POLICY admin_consultation ON faits_consultation
  FOR SELECT TO role_administratif USING (true);

-- POLITIQUES CHERCHEUR
CREATE POLICY chercheur_patient ON dim_patient
  FOR SELECT TO role_chercheur USING (actif = true);
CREATE POLICY chercheur_consultation ON faits_consultation
  FOR SELECT TO role_chercheur USING (true);

-- POLITIQUES INFIRMIER
CREATE POLICY infirmier_consultation ON faits_consultation
  FOR SELECT TO role_infirmier USING (true);

-- POLITIQUES DIRECTEUR
CREATE POLICY directeur_patient ON dim_patient
  FOR SELECT TO role_directeur USING (true);
CREATE POLICY directeur_consultation ON faits_consultation
  FOR SELECT TO role_directeur USING (true);

-- VUES SECURISEES

-- Vue medecin : tout visible
CREATE OR REPLACE VIEW vue_patient_medecin AS
SELECT p.*, v.nom_ville, r.nom_region
FROM dim_patient p
LEFT JOIN dim_ville v ON p.ville_id = v.ville_id
LEFT JOIN dim_region r ON v.region_id = r.region_id
WHERE p.actif = true;

-- Vue administratif : sans donnees medicales
CREATE OR REPLACE VIEW vue_patient_administratif AS
SELECT
  p.patient_id, p.nom, p.prenom, p.cin,
  p.telephone, p.email, p.adresse,
  p.date_naissance, p.sexe,
  '***' AS groupe_sanguin,
  NULL::TEXT AS allergies,
  NULL::TEXT AS antecedents,
  p.mutuelle, p.ramed,
  v.nom_ville, r.nom_region
FROM dim_patient p
LEFT JOIN dim_ville v ON p.ville_id = v.ville_id
LEFT JOIN dim_region r ON v.region_id = r.region_id
WHERE p.actif = true;

-- Vue chercheur : totalement anonymisee
CREATE OR REPLACE VIEW vue_patient_chercheur AS
SELECT
  p.token_anonyme AS patient_ref,
  EXTRACT(YEAR FROM AGE(p.date_naissance))::INT AS age,
  p.sexe, p.groupe_sanguin,
  p.mutuelle, p.ramed,
  v.nom_ville, r.nom_region
FROM dim_patient p
LEFT JOIN dim_ville v ON p.ville_id = v.ville_id
LEFT JOIN dim_region r ON v.region_id = r.region_id
WHERE p.actif = true;

-- PERMISSIONS
GRANT CONNECT ON DATABASE hopital_maroc TO role_medecin, role_administratif, role_chercheur, role_infirmier, role_directeur;
GRANT USAGE ON SCHEMA public TO role_medecin, role_administratif, role_chercheur, role_infirmier, role_directeur;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_medecin, role_administratif, role_chercheur, role_infirmier, role_directeur;
GRANT INSERT, UPDATE ON faits_consultation, faits_prescription, faits_acte_realise TO role_medecin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO role_medecin;

-- FONCTIONS MASQUAGE
CREATE OR REPLACE FUNCTION masquer_cin(cin_original TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS \$\$
BEGIN
  RETURN REPEAT('*', LENGTH(cin_original) - 4) || RIGHT(cin_original, 4);
END;
\$\$;

CREATE OR REPLACE FUNCTION masquer_telephone(tel TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS \$\$
BEGIN
  IF tel IS NULL THEN RETURN NULL; END IF;
  RETURN LEFT(tel, 3) || REPEAT('*', LENGTH(tel) - 5) || RIGHT(tel, 2);
END;
\$\$;

-- AUDIT TABLE
CREATE TABLE audit_log (
  audit_id         BIGSERIAL PRIMARY KEY,
  timestamp        TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  utilisateur      VARCHAR(100) NOT NULL,
  role_utilisateur VARCHAR(50) NOT NULL,
  action           VARCHAR(20) NOT NULL,
  table_cible      VARCHAR(100),
  patient_id       INTEGER,
  ip_address       TEXT,
  details          JSONB,
  hash_precedent   VARCHAR(64),
  hash_courant     VARCHAR(64) UNIQUE NOT NULL
);

GRANT INSERT ON audit_log TO role_medecin, role_administratif, role_chercheur, role_infirmier, role_directeur;
GRANT SELECT ON audit_log TO role_directeur;
GRANT USAGE ON SEQUENCE audit_log_audit_id_seq TO role_medecin, role_administratif, role_chercheur, role_infirmier, role_directeur;

DO \$\$ BEGIN
  RAISE NOTICE 'Schema cree avec succes - Hopital Ibn Sina Rabat';
END \$\$;
