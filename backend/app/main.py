from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import asyncpg, httpx, hashlib, os
from datetime import datetime
from typing import Optional
from jose import jwt, JWTError
from elasticsearch import AsyncElasticsearch
import redis.asyncio as aioredis

DATABASE_URL  = os.getenv('DATABASE_URL','postgresql://hopital_admin:HopitalMaroc2024!@localhost:5432/hopital_maroc')
KEYCLOAK_URL  = os.getenv('KEYCLOAK_URL','http://localhost:8080')
REALM         = os.getenv('KEYCLOAK_REALM','hopital-maroc')
ES_URL        = os.getenv('ELASTICSEARCH_URL','http://localhost:9200')
REDIS_URL     = os.getenv('REDIS_URL','redis://localhost:6379')

db_pool = None
es_client = None
redis_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_pool, es_client, redis_client
    db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
    es_client = AsyncElasticsearch([ES_URL])
    redis_client = await aioredis.from_url(REDIS_URL, decode_responses=True)
    print('✅ Backend Hopital Ibn Sina demarre')
    yield
    await db_pool.close()
    await es_client.close()
    await redis_client.close()

app = FastAPI(
    title='API Hopital Ibn Sina - Rabat',
    description='Systeme BI securise avec controle acces dynamique par role',
    version='1.0.0',
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['http://localhost:3000'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

ROLE_MAPPING = {
    'medecin':       'role_medecin',
    'administratif': 'role_administratif',
    'chercheur':     'role_chercheur',
    'infirmier':     'role_infirmier',
    'directeur':     'role_directeur',
}

VUE_MAPPING = {
    'role_medecin':       'vue_patient_medecin',
    'role_directeur':     'vue_patient_medecin',
    'role_administratif': 'vue_patient_administratif',
    'role_chercheur':     'vue_patient_chercheur',
    'role_infirmier':     'vue_patient_administratif',
}

async def get_public_key():
    cached = await redis_client.get('keycloak_pk')
    if cached:
        return cached
    async with httpx.AsyncClient() as client:
        r = await client.get(f'{KEYCLOAK_URL}/realms/{REALM}')
        pk = r.json()['public_key']
        pem = f'-----BEGIN PUBLIC KEY-----\n{pk}\n-----END PUBLIC KEY-----'
        await redis_client.setex('keycloak_pk', 3600, pem)
        return pem

async def verify_token(request: Request) -> dict:
    auth = request.headers.get('Authorization','')
    if not auth.startswith('Bearer '):
        raise HTTPException(status_code=401, detail='Token manquant')
    token = auth.split(' ')[1]
    try:
        pk = await get_public_key()
        payload = jwt.decode(token, pk, algorithms=['RS256'], options={'verify_aud': False})
        roles = payload.get('realm_access',{}).get('roles',[])
        app_roles = [r for r in roles if r in ROLE_MAPPING]
        if not app_roles:
            raise HTTPException(status_code=403, detail='Aucun role applicatif')
        return {
            'sub':      payload['sub'],
            'username': payload.get('preferred_username',''),
            'nom':      payload.get('family_name',''),
            'prenom':   payload.get('given_name',''),
            'role':     app_roles[0],
        }
    except JWTError as e:
        raise HTTPException(status_code=401, detail=f'Token invalide: {e}')

async def query_as_role(role_pg: str, sql: str, *args):
    async with db_pool.acquire() as conn:
        await conn.execute(f'SET ROLE {role_pg}')
        rows = await conn.fetch(sql, *args)
        await conn.execute('RESET ROLE')
        return [dict(r) for r in rows]

async def audit(user: dict, action: str, endpoint: str, ip: str, nb: int=0, patient_id: int=None):
    ts = datetime.utcnow().isoformat()
    try:
        res = await es_client.search(index='hopital-audit',
            body={'sort':[{'timestamp':'desc'}],'size':1,'_source':['hash_courant']})
        dernier = res['hits']['hits'][0]['_source'].get('hash_courant','') if res['hits']['hits'] else ''
    except:
        dernier = ''
    contenu = f'{ts}|{user["username"]}|{user["role"]}|{action}|{endpoint}|{dernier}'
    hash_c = hashlib.sha256(contenu.encode()).hexdigest()
    try:
        await es_client.index(index='hopital-audit', document={
            'timestamp':ts,'utilisateur':user['username'],
            'role':user['role'],'action':action,'endpoint':endpoint,
            'patient_id':patient_id,'ip':ip,'nb_lignes':nb,
            'hash_precedent':dernier,'hash_courant':hash_c
        })
    except:
        pass

@app.get('/health')
async def health():
    return {'status':'ok','hopital':'Ibn Sina - Rabat','version':'1.0.0'}

@app.get('/api/me')
async def me(user: dict = Depends(verify_token)):
    return user

@app.get('/api/patients')
async def get_patients(
    request: Request,
    page: int = 1,
    limit: int = 50,
    search: Optional[str] = None,
    user: dict = Depends(verify_token)
):
    role_pg = ROLE_MAPPING[user['role']]
    vue     = VUE_MAPPING[role_pg]
    offset  = (page-1)*limit
    if search and user['role'] in ['medecin','administratif','directeur']:
        sql = f'SELECT * FROM {vue} WHERE nom ILIKE \ OR prenom ILIKE \ OR cin ILIKE \ ORDER BY 1 LIMIT {limit} OFFSET {offset}'
        data = await query_as_role(role_pg, sql, f'%{search}%')
    else:
        data = await query_as_role(role_pg, f'SELECT * FROM {vue} ORDER BY 1 LIMIT {limit} OFFSET {offset}')
    await audit(user,'SELECT','patients',request.client.host,len(data))
    return {'role':user['role'],'vue':vue,'page':page,'count':len(data),'data':data}

@app.get('/api/patients/{patient_id}')
async def get_patient(patient_id: int, request: Request, user: dict = Depends(verify_token)):
    if user['role'] == 'chercheur':
        raise HTTPException(status_code=403, detail='Acces interdit aux chercheurs')
    role_pg = ROLE_MAPPING[user['role']]
    vue     = VUE_MAPPING[role_pg]
    data    = await query_as_role(role_pg, f'SELECT * FROM {vue} WHERE patient_id = \', patient_id)
    if not data:
        raise HTTPException(status_code=404, detail='Patient non trouve')
    consultations = await query_as_role(role_pg, '''
        SELECT fc.consultation_id, fc.date_entree, fc.type_visite, fc.mode_sortie,
               s.nom_service, m.prenom||' '||m.nom AS medecin,
               d.libelle_court AS diagnostic, fc.cout_total
        FROM faits_consultation fc
        JOIN dim_service s ON fc.service_id = s.service_id
        JOIN dim_medecin m ON fc.medecin_id = m.medecin_id
        LEFT JOIN dim_diagnostic d ON fc.diagnostic_id = d.diagnostic_id
        WHERE fc.patient_id = \ ORDER BY fc.date_entree DESC LIMIT 20
    ''', patient_id)
    await audit(user,'SELECT_DETAIL','patients',request.client.host,1,patient_id)
    return {'patient':data[0],'consultations':consultations,'role':user['role']}

@app.get('/api/dashboard/kpis')
async def kpis(request: Request, annee: int=2024, user: dict = Depends(verify_token)):
    role_pg = ROLE_MAPPING[user['role']]
    result  = {}
    if user['role'] in ['medecin','directeur','administratif']:
        rows = await query_as_role(role_pg, '''
            SELECT COUNT(*) AS total, COUNT(DISTINCT patient_id) AS patients_uniques,
                   ROUND(AVG(duree_sejour_h)::NUMERIC,1) AS duree_moy,
                   COUNT(*) FILTER (WHERE type_visite='Urgence') AS urgences,
                   COUNT(*) FILTER (WHERE mode_sortie='Decede') AS deces,
                   ROUND(AVG(cout_total)::NUMERIC,2) AS cout_moyen
            FROM faits_consultation fc
            JOIN dim_temps dt ON fc.temps_id=dt.temps_id WHERE dt.annee=\
        ''', annee)
        result['activite'] = rows[0]
    if user['role'] in ['directeur','administratif']:
        rows = await query_as_role(role_pg, '''
            SELECT ROUND(SUM(cout_total)::NUMERIC,2) AS chiffre_affaires,
                   ROUND(SUM(montant_rembourse)::NUMERIC,2) AS total_rembourse,
                   ROUND(SUM(reste_a_charge)::NUMERIC,2) AS reste_a_charge_total
            FROM faits_consultation fc
            JOIN dim_temps dt ON fc.temps_id=dt.temps_id WHERE dt.annee=\
        ''', annee)
        result['financier'] = rows[0]
    if user['role'] in ['medecin','chercheur','directeur']:
        rows = await query_as_role(role_pg, '''
            SELECT d.libelle_court, COUNT(*) AS nb_cas,
                   ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(),1) AS pct
            FROM faits_consultation fc
            JOIN dim_temps dt ON fc.temps_id=dt.temps_id
            LEFT JOIN dim_diagnostic d ON fc.diagnostic_id=d.diagnostic_id
            WHERE dt.annee=\ AND d.libelle_court IS NOT NULL
            GROUP BY d.libelle_court ORDER BY nb_cas DESC LIMIT 10
        ''', annee)
        result['top_diagnostics'] = rows
    if user['role'] in ['medecin','infirmier','directeur']:
        rows = await query_as_role(role_pg, '''
            SELECT s.nom_service, COUNT(*) AS nb,
                   ROUND(AVG(fc.duree_sejour_h)::NUMERIC,1) AS duree_moy
            FROM faits_consultation fc
            JOIN dim_service s ON fc.service_id=s.service_id
            JOIN dim_temps dt ON fc.temps_id=dt.temps_id
            WHERE dt.annee=\ GROUP BY s.nom_service ORDER BY nb DESC
        ''', annee)
        result['par_service'] = rows
    await audit(user,'SELECT','dashboard_kpis',request.client.host)
    return {'annee':annee,'role':user['role'],'kpis':result}

@app.get('/api/dashboard/tendances')
async def tendances(request: Request, user: dict = Depends(verify_token)):
    role_pg = ROLE_MAPPING[user['role']]
    rows = await query_as_role(role_pg, '''
        SELECT dt.annee, dt.mois, dt.nom_mois,
               COUNT(*) AS consultations,
               COUNT(DISTINCT fc.patient_id) AS patients,
               COUNT(*) FILTER (WHERE fc.type_visite='Urgence') AS urgences,
               ROUND(AVG(fc.cout_total)::NUMERIC,2) AS cout_moyen
        FROM faits_consultation fc
        JOIN dim_temps dt ON fc.temps_id=dt.temps_id
        GROUP BY dt.annee,dt.mois,dt.nom_mois ORDER BY dt.annee,dt.mois
    ''')
    await audit(user,'SELECT','tendances',request.client.host)
    return {'data':rows,'role':user['role']}

@app.get('/api/audit')
async def get_audit(request: Request, page: int=1, limit: int=100, user: dict = Depends(verify_token)):
    if user['role'] != 'directeur':
        raise HTTPException(status_code=403, detail='Reserve a la direction')
    res = await es_client.search(index='hopital-audit', body={
        'query':{'match_all':{}},
        'sort':[{'timestamp':'desc'}],
        'from':(page-1)*limit,'size':limit
    })
    return {'total':res['hits']['total']['value'],'data':[h['_source'] for h in res['hits']['hits']]}
