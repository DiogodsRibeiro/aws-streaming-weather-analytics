# ⛅ Real Time Weather Analytics

> Pipeline de dados em tempo real para análise meteorológica utilizando AWS Services

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Arquitetura](#arquitetura)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Pré-requisitos](#pré-requisitos)
- [Instalação e Configuração](#instalação-e-configuração)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Fluxo de Dados](#fluxo-de-dados)
- [Queries Athena](#queries-athena)
- [Monitoramento](#monitoramento)
- [Custos Estimados](#custos-estimados)
- [Troubleshooting](#troubleshooting)
- [Contribuindo](#contribuindo)

---

## 🎯 Sobre o Projeto

Este projeto implementa uma solução completa de **engenharia de dados em tempo real** para análise meteorológica. O sistema consome dados de uma API de clima, processa informações em tempo real, emite alertas automáticos baseados em condições climáticas críticas e armazena os dados de forma estruturada para análises ad-hoc.

### Principais Funcionalidades

- 🌡️ **Ingestão em Tempo Real**: Coleta contínua de dados meteorológicos via API Tomorrow.io
- 📨 **Alertas Inteligentes**: Notificações automáticas por email quando condições climáticas críticas são detectadas
- 💾 **Data Lake Estruturado**: Armazenamento em camadas (Raw → Gold) com particionamento inteligente
- 🔄 **ETL Automatizado**: Transformação e estruturação de dados com AWS Glue
- 📊 **Análise SQL**: Queries ad-hoc com Amazon Athena sobre dados em formato Parquet
- 📈 **Monitoramento**: Logs e métricas em tempo real via CloudWatch

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRODUCER LAYER                            │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │ EventBridge  │────────>│   Lambda     │                      │
│  │  (Scheduler) │         │  Producer    │                      │
│  └──────────────┘         └──────┬───────┘                      │
│                                   │                              │
│                                   v                              │
│                          ┌────────────────┐                      │
│                          │    Kinesis     │                      │
│                          │  Data Stream   │                      │
│                          │    (broker)    │                      │
│                          └────────┬───────┘                      │
│                                   │                              │
└───────────────────────────────────┼──────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    v                               v
┌───────────────────────────────┐   ┌──────────────────────────────┐
│    REAL-TIME CONSUMER         │   │     BATCH CONSUMER           │
│  ┌─────────────────────────┐  │   │  ┌────────────────────────┐  │
│  │  Lambda                 │  │   │  │  Lambda                │  │
│  │  consumer_realtime      │  │   │  │  consumer_batch        │  │
│  └──────────┬──────────────┘  │   │  └──────────┬─────────────┘  │
│             │                 │   │             │                │
│             v                 │   │             v                │
│  ┌─────────────────────────┐  │   │  ┌────────────────────────┐  │
│  │  Amazon SNS             │  │   │  │  S3 Bucket             │  │
│  │  (Email Alerts)         │  │   │  │  raw/year/month/day/   │  │
│  └─────────────────────────┘  │   │  └──────────┬─────────────┘  │
└───────────────────────────────┘   └─────────────┼────────────────┘
                                                   │
                                                   v
┌─────────────────────────────────────────────────────────────────┐
│                        ETL LAYER (AWS GLUE)                      │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │   Crawler    │────────>│  Data        │                      │
│  │  raw_crawler │         │  Catalog     │                      │
│  └──────────────┘         │  (raw_db)    │                      │
│                           └──────┬───────┘                      │
│                                  │                              │
│                                  v                              │
│                           ┌──────────────┐                      │
│                           │  Glue Job    │                      │
│                           │ weather_job  │                      │
│                           └──────┬───────┘                      │
│                                  │                              │
│                                  v                              │
│                           ┌──────────────┐                      │
│                           │  S3 Bucket   │                      │
│                           │  gold/       │                      │
│                           │  (Parquet)   │                      │
│                           └──────┬───────┘                      │
│                                  │                              │
│  ┌──────────────┐         ┌──────v───────┐                      │
│  │   Crawler    │────────>│  Data        │                      │
│  │ gold_crawler │         │  Catalog     │                      │
│  └──────────────┘         │  (gold_db)   │                      │
│                           └──────┬───────┘                      │
└──────────────────────────────────┼──────────────────────────────┘
                                   │
                                   v
                            ┌──────────────┐
                            │   Athena     │
                            │  (SQL Queries)│
                            └──────────────┘
```

### Fluxo de Dados Detalhado

1. **Ingestão**: Lambda Producer coleta dados da API Tomorrow.io a cada intervalo programado
2. **Streaming**: Dados são enviados para Kinesis Data Stream (broker)
3. **Processamento Dual**:
   - **Real-time**: Lambda detecta condições críticas e envia alertas via SNS
   - **Batch**: Lambda salva dados brutos no S3 (camada Raw) com particionamento temporal
4. **Catalogação**: Crawler escaneia a camada Raw e registra schema no Glue Data Catalog
5. **Transformação**: Glue Job processa dados (flatten JSON, conversões) e salva em Parquet na camada Gold
6. **Análise**: Athena permite queries SQL sobre os dados estruturados

---

## 🛠️ Tecnologias Utilizadas

### AWS Services

| Serviço | Função | Detalhes |
|---------|--------|----------|
| **Lambda** | Processamento serverless | Producer, Consumer Real-time, Consumer Batch |
| **Kinesis Data Stream** | Message Broker | Stream "broker" para dados em tempo real |
| **S3** | Data Lake | Armazenamento em camadas Raw e Gold |
| **SNS** | Notificações | Alertas por email sobre condições climáticas |
| **Glue** | ETL | Job de transformação + Crawlers + Data Catalog |
| **Athena** | Query Engine | Análise SQL sobre dados no S3 |
| **IAM** | Segurança | Roles e políticas de acesso |
| **CloudWatch** | Observabilidade | Logs, métricas e alarmes |
| **EventBridge** | Scheduler | Trigger periódico do Producer |

### Linguagens e Frameworks

- **Python 3.9+**: Lambdas e Glue Jobs
- **PySpark**: Transformações no Glue
- **Boto3**: SDK AWS para Python
- **Requests**: HTTP client para API externa

### API Externa

- **Tomorrow.io Weather API**: Fonte de dados meteorológicos em tempo real

---

## ✅ Pré-requisitos

Antes de começar, você precisará:

- [ ] Conta AWS ativa
- [ ] AWS CLI instalado e configurado
- [ ] Python 3.9+ instalado localmente
- [ ] Chave de API da Tomorrow.io ([criar conta aqui](https://app.tomorrow.io/home))
- [ ] Git instalado
- [ ] Editor de código (VSCode recomendado)

---

## 🚀 Instalação e Configuração

### 1. Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/real-time-weather-analytics.git
cd real-time-weather-analytics
```

### 2. Configurar AWS CLI

```bash
aws configure
# AWS Access Key ID: SUA_ACCESS_KEY
# AWS Secret Access Key: SUA_SECRET_KEY
# Default region name: us-east-2
# Default output format: json
```

### 3. Criar Kinesis Data Stream

```bash
aws kinesis create-stream \
    --stream-name broker \
    --shard-count 1 \
    --region us-east-2
```

### 4. Criar S3 Bucket

```bash
# Substitua NOME_UNICO por um nome único
aws s3 mb s3://weatherrt2025 --region us-east-2
```

### 5. Criar IAM Roles

#### Role para Lambda Producer

```bash
aws iam create-role \
    --role-name lambda-producer-role \
    --assume-role-policy-document file://policies/lambda-trust-policy.json

aws iam attach-role-policy \
    --role-name lambda-producer-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Criar política inline para Kinesis
aws iam put-role-policy \
    --role-name lambda-producer-role \
    --policy-name kinesis-put-record \
    --policy-document file://policies/kinesis-put-policy.json
```

#### Role para Lambda Consumer Real-time

```bash
aws iam create-role \
    --role-name lambda-consumer-realtime-role \
    --assume-role-policy-document file://policies/lambda-trust-policy.json

aws iam attach-role-policy \
    --role-name lambda-consumer-realtime-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Adicionar permissões SNS e Kinesis
aws iam put-role-policy \
    --role-name lambda-consumer-realtime-role \
    --policy-name sns-kinesis-access \
    --policy-document file://policies/sns-kinesis-policy.json
```

#### Role para Lambda Consumer Batch

```bash
aws iam create-role \
    --role-name lambda-consumer-batch-role \
    --assume-role-policy-document file://policies/lambda-trust-policy.json

aws iam attach-role-policy \
    --role-name lambda-consumer-batch-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Adicionar permissões S3 e Kinesis
aws iam put-role-policy \
    --role-name lambda-consumer-batch-role \
    --policy-name s3-kinesis-access \
    --policy-document file://policies/s3-kinesis-policy.json
```

#### Role para Glue

```bash
aws iam create-role \
    --role-name glue-etl-role \
    --assume-role-policy-document file://policies/glue-trust-policy.json

aws iam attach-role-policy \
    --role-name glue-etl-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

aws iam attach-role-policy \
    --role-name glue-etl-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### 6. Criar Tópico SNS

```bash
# Criar tópico
aws sns create-topic --name snsalerta --region us-east-2

# Subscrever seu email
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-2:SEU_ACCOUNT_ID:snsalerta \
    --protocol email \
    --notification-endpoint seu-email@exemplo.com

# Confirme a inscrição no email recebido
```

### 7. Deploy das Lambdas

#### Lambda Producer

```bash
cd lambdas/producer
pip install -r requirements.txt -t .
zip -r producer.zip .

aws lambda create-function \
    --function-name producer \
    --runtime python3.9 \
    --role arn:aws:iam::SEU_ACCOUNT_ID:role/lambda-producer-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://producer.zip \
    --timeout 30 \
    --memory-size 128 \
    --environment Variables={TOMORROW_API_KEY=SUA_API_KEY} \
    --region us-east-2
```

#### Lambda Consumer Real-time

```bash
cd ../consumer_realtime
zip -r consumer_realtime.zip lambda_function.py

aws lambda create-function \
    --function-name consumer_realtime \
    --runtime python3.9 \
    --role arn:aws:iam::SEU_ACCOUNT_ID:role/lambda-consumer-realtime-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://consumer_realtime.zip \
    --timeout 60 \
    --memory-size 256 \
    --environment Variables={PRECIPITATION_PROBABILITY=70,RAIN_INTENSITY=5,WIND_GUST=10,WIND_SPEED=10} \
    --region us-east-2
```

#### Lambda Consumer Batch

```bash
cd ../consumer_batch
zip -r consumer_batch.zip lambda_function.py

aws lambda create-function \
    --function-name consumer_batch \
    --runtime python3.9 \
    --role arn:aws:iam::SEU_ACCOUNT_ID:role/lambda-consumer-batch-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://consumer_batch.zip \
    --timeout 300 \
    --memory-size 512 \
    --environment Variables={BUCKET_NAME=weatherrt2025} \
    --region us-east-2
```

### 8. Configurar Triggers do Kinesis

```bash
# Trigger para Consumer Real-time
aws lambda create-event-source-mapping \
    --function-name consumer_realtime \
    --event-source-arn arn:aws:kinesis:us-east-2:SEU_ACCOUNT_ID:stream/broker \
    --starting-position LATEST \
    --batch-size 10

# Trigger para Consumer Batch
aws lambda create-event-source-mapping \
    --function-name consumer_batch \
    --event-source-arn arn:aws:kinesis:us-east-2:SEU_ACCOUNT_ID:stream/broker \
    --starting-position LATEST \
    --batch-size 100
```

### 9. Configurar EventBridge (Scheduler)

```bash
# Criar regra para executar Producer a cada 5 minutos
aws events put-rule \
    --name weather-producer-schedule \
    --schedule-expression "rate(5 minutes)"

# Adicionar permissão para EventBridge invocar Lambda
aws lambda add-permission \
    --function-name producer \
    --statement-id weather-producer-schedule \
    --action lambda:InvokeFunction \
    --principal events.amazonaws.com \
    --source-arn arn:aws:events:us-east-2:SEU_ACCOUNT_ID:rule/weather-producer-schedule

# Adicionar target (Lambda)
aws events put-targets \
    --rule weather-producer-schedule \
    --targets "Id"="1","Arn"="arn:aws:lambda:us-east-2:SEU_ACCOUNT_ID:function:producer"
```

### 10. Configurar AWS Glue

#### Criar Database

```bash
aws glue create-database \
    --database-input '{"Name":"raw_db","Description":"Raw weather data"}'

aws glue create-database \
    --database-input '{"Name":"gold_db","Description":"Processed weather data"}'
```

#### Criar Crawler Raw

```bash
aws glue create-crawler \
    --name raw_crawler \
    --role arn:aws:iam::SEU_ACCOUNT_ID:role/glue-etl-role \
    --database-name raw_db \
    --targets '{"S3Targets":[{"Path":"s3://weatherrt2025/raw/"}]}' \
    --schedule "cron(0 */6 * * ? *)"
```

#### Upload e Deploy do Glue Job

```bash
# Upload do script para S3
aws s3 cp glue/weather_job.py s3://weatherrt2025/scripts/

# Criar Glue Job
aws glue create-job \
    --name weather_job \
    --role arn:aws:iam::SEU_ACCOUNT_ID:role/glue-etl-role \
    --command Name=glueetl,ScriptLocation=s3://weatherrt2025/scripts/weather_job.py,PythonVersion=3 \
    --default-arguments '{"--job-language":"python","--enable-metrics":"","--enable-spark-ui":"true","--enable-continuous-cloudwatch-log":"true"}' \
    --max-capacity 2.0
```

#### Criar Crawler Gold

```bash
aws glue create-crawler \
    --name gold_crawler \
    --role arn:aws:iam::SEU_ACCOUNT_ID:role/glue-etl-role \
    --database-name gold_db \
    --targets '{"S3Targets":[{"Path":"s3://weatherrt2025/gold/"}]}' \
    --schedule "cron(0 */6 * * ? *)"
```

### 11. Executar Primeira Ingestão

```bash
# Invocar Producer manualmente
aws lambda invoke \
    --function-name producer \
    --region us-east-2 \
    response.json

# Verificar resposta
cat response.json
```

---

## 📁 Estrutura do Projeto

```
real-time-weather-analytics/
│
├── lambdas/
│   ├── producer/
│   │   ├── lambda_function.py
│   │   └── requirements.txt
│   ├── consumer_realtime/
│   │   └── lambda_function.py
│   └── consumer_batch/
│       └── lambda_function.py
│
├── glue/
│   └── weather_job.py
│
├── policies/
│   ├── lambda-trust-policy.json
│   ├── glue-trust-policy.json
│   ├── kinesis-put-policy.json
│   ├── sns-kinesis-policy.json
│   └── s3-kinesis-policy.json
│
├── athena-queries/
│   ├── views.sql
│   └── analytics.sql
│
├── docs/
│   ├── architecture.png
│   └── deployment-guide.md
│
├── .gitignore
├── README.md
└── LICENSE
```

---

## 🔄 Fluxo de Dados

### 1. Producer (Ingestão)

```python
# Lambda Producer - Executado a cada 5 minutos
API Tomorrow.io → Lambda → Kinesis Stream (broker)
```

**Dados coletados**:
- Temperatura atual e sensação térmica
- Umidade e ponto de orvalho
- Precipitação (probabilidade e intensidade)
- Vento (velocidade, rajadas, direção)
- Visibilidade e cobertura de nuvens
- Índice UV
- Coordenadas geográficas
- Timestamp

### 2. Consumer Real-time (Alertas)

```python
# Trigger: Kinesis Stream
# Batch Size: 10 registros
# Processamento: < 1 segundo

Kinesis → Lambda → Verificação de Thresholds → SNS → Email
```

**Condições de Alerta**:
- Probabilidade de precipitação ≥ 70%
- Intensidade de chuva ≥ 5 mm/h
- Rajadas de vento ≥ 10 m/s
- Velocidade do vento ≥ 10 m/s

### 3. Consumer Batch (Armazenamento)

```python
# Trigger: Kinesis Stream
# Batch Size: 100 registros
# Formato: JSON

Kinesis → Lambda → S3 (raw/year=YYYY/month=MM/day=DD/)
```

**Estrutura de Particionamento**:
```
s3://weatherrt2025/raw/
├── year=2025/
│   ├── month=11/
│   │   ├── day=06/
│   │   │   ├── weather_data_2025-11-06T18:14:00.json
│   │   │   └── weather_data_2025-11-06T18:19:00.json
```

### 4. ETL (Transformação)

```python
# Glue Job - Executado após Crawler Raw
# Input: JSON (Raw Layer)
# Output: Parquet (Gold Layer)

Raw JSON → Glue Job → Flatten + Type Casting → Parquet (particionado)
```

**Transformações realizadas**:
- Flatten de JSON aninhado
- Conversão de tipos de dados
- Extração de year/month/day do timestamp
- Remoção de campos desnecessários
- Compressão em formato Parquet

---

## 📊 Queries Athena

### Setup Inicial

```sql
-- Database já criado pelos crawlers: gold_db

-- Reparar partições (executar após cada ETL)
MSCK REPAIR TABLE gold_db.weather_data;
```

### Views Sugeridas

#### 1. Condições Atuais

```sql
CREATE OR REPLACE VIEW gold_db.current_conditions AS
SELECT 
    time,
    temperature,
    temperatureapparent,
    humidity,
    precipitationprobability,
    windspeed,
    windgust,
    weathercode,
    visibility
FROM gold_db.weather_data
WHERE year = YEAR(CURRENT_DATE)
  AND month = MONTH(CURRENT_DATE)
  AND day = DAY_OF_MONTH(CURRENT_DATE)
ORDER BY time DESC
LIMIT 1;
```

#### 2. Estatísticas Diárias

```sql
CREATE OR REPLACE VIEW gold_db.daily_statistics AS
SELECT 
    CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE) as date,
    ROUND(AVG(temperature), 2) as avg_temp,
    ROUND(MAX(temperature), 2) as max_temp,
    ROUND(MIN(temperature), 2) as min_temp,
    ROUND(AVG(humidity), 2) as avg_humidity,
    ROUND(AVG(windspeed), 2) as avg_wind_speed,
    ROUND(MAX(windgust), 2) as max_wind_gust,
    ROUND(SUM(rainintensity), 2) as total_rain,
    COUNT(*) as measurements
FROM gold_db.weather_data
GROUP BY year, month, day
ORDER BY year DESC, month DESC, day DESC;
```

#### 3. Alertas Históricos

```sql
CREATE OR REPLACE VIEW gold_db.historical_alerts AS
SELECT 
    time,
    temperature,
    precipitationprobability,
    rainintensity,
    windspeed,
    windgust,
    CASE 
        WHEN precipitationprobability >= 70 THEN 'High Precipitation Risk'
        WHEN rainintensity >= 5 THEN 'Heavy Rain'
        WHEN windgust >= 10 THEN 'Strong Wind Gusts'
        WHEN windspeed >= 10 THEN 'High Wind Speed'
    END as alert_type
FROM gold_db.weather_data
WHERE precipitationprobability >= 70
   OR rainintensity >= 5
   OR windgust >= 10
   OR windspeed >= 10
ORDER BY time DESC;
```

#### 4. Análise Semanal

```sql
CREATE OR REPLACE VIEW gold_db.weekly_trends AS
SELECT 
    DATE_TRUNC('week', 
        CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                    LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                    LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE)
    ) as week_start,
    ROUND(AVG(temperature), 2) as avg_temp,
    ROUND(AVG(humidity), 2) as avg_humidity,
    ROUND(AVG(windspeed), 2) as avg_wind,
    ROUND(SUM(rainintensity), 2) as total_rain,
    COUNT(*) as measurements
FROM gold_db.weather_data
GROUP BY DATE_TRUNC('week', 
    CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE))
ORDER BY week_start DESC;
```

#### 5. Condições Extremas

```sql
CREATE OR REPLACE VIEW gold_db.extreme_conditions AS
SELECT 
    'Highest Temperature' as condition_type,
    time,
    temperature as value,
    'Celsius' as unit
FROM gold_db.weather_data
WHERE temperature = (SELECT MAX(temperature) FROM gold_db.weather_data)

UNION ALL

SELECT 
    'Lowest Temperature',
    time,
    temperature,
    'Celsius'
FROM gold_db.weather_data
WHERE temperature = (SELECT MIN(temperature) FROM gold_db.weather_data)

UNION ALL

SELECT 
    'Highest Wind Gust',
    time,
    windgust,
    'm/s'
FROM gold_db.weather_data
WHERE windgust = (SELECT MAX(windgust) FROM gold_db.weather_data)

UNION ALL

SELECT 
    'Heaviest Rain',
    time,
    rainintensity,
    'mm/h'
FROM gold_db.weather_data
WHERE rainintensity = (SELECT MAX(rainintensity) FROM gold_db.weather_data);
```

#### 6. Análise de Conforto Térmico

```sql
CREATE OR REPLACE VIEW gold_db.thermal_comfort AS
SELECT 
    time,
    temperature,
    temperatureapparent,
    humidity,
    ROUND(temperatureapparent - temperature, 2) as comfort_index,
    CASE 
        WHEN temperatureapparent - temperature > 5 THEN 'Muito Desconfortável'
        WHEN temperatureapparent - temperature > 2 THEN 'Desconfortável'
        WHEN ABS(temperatureapparent - temperature) <= 2 THEN 'Confortável'
        ELSE 'Fresco'
    END as comfort_level
FROM gold_db.weather_data
ORDER BY time DESC;
```

### Queries Analíticas

```sql
-- 1. Distribuição de temperatura por hora do dia
SELECT 
    EXTRACT(HOUR FROM time) as hour_of_day,
    ROUND(AVG(temperature), 2) as avg_temp,
    ROUND(MIN(temperature), 2) as min_temp,
    ROUND(MAX(temperature), 2) as max_temp
FROM gold_db.weather_data
GROUP BY EXTRACT(HOUR FROM time)
ORDER BY hour_of_day;

-- 2. Dias com maior probabilidade de chuva
SELECT 
    CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE) as date,
    ROUND(AVG(precipitationprobability), 2) as avg_rain_probability,
    ROUND(SUM(rainintensity), 2) as total_rain
FROM gold_db.weather_data
GROUP BY year, month, day
HAVING AVG(precipitationprobability) > 50
ORDER BY avg_rain_probability DESC;

-- 3. Correlação vento e temperatura
SELECT 
    CASE 
        WHEN temperature < 10 THEN 'Frio'
        WHEN temperature BETWEEN 10 AND 20 THEN 'Ameno'
        WHEN temperature BETWEEN 20 AND 30 THEN 'Quente'
        ELSE 'Muito Quente'
    END as temp_range,
    ROUND(AVG(windspeed), 2) as avg_wind_speed,
    COUNT(*) as occurrences
FROM gold_db.weather_data
GROUP BY CASE 
    WHEN temperature < 10 THEN 'Frio'
    WHEN temperature BETWEEN 10 AND 20 THEN 'Ameno'
    WHEN temperature BETWEEN 20 AND 30 THEN 'Quente'
    ELSE 'Muito Quente'
END;

-- 4. Análise de visibilidade
SELECT 
    CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE) as date,
    ROUND(AVG(visibility), 2) as avg_visibility,
    ROUND(MIN(visibility), 2) as min_visibility,
    COUNT(CASE WHEN visibility < 5 THEN 1 END) as low_visibility_count
FROM gold_db.weather_data
GROUP BY year, month, day
ORDER BY avg_visibility ASC
LIMIT 10;
```

---

## 📈 Monitoramento

### CloudWatch Logs

Cada Lambda gera logs automáticos:

```
/aws/lambda/producer
/aws/lambda/consumer_realtime
/aws/lambda/consumer_batch
```

### Métricas do Kinesis

```bash
# Visualizar métricas do stream
aws cloudwatch get-metric-statistics \
    --namespace AWS/Kinesis \
    --metric-name IncomingRecords \
    --dimensions Name=StreamName,Value=broker \
    --start-time 2025-11-06T00:00:00Z \
    --end-time 2025-11-06T23:59:59Z \
    --period 3600 \
    --statistics Sum
```

### Alarmes Recomendados

```bash
# Alarme: Lambda com muitos erros
aws cloudwatch put-metric-alarm \
    --alarm-name lambda-producer-errors \
    --alarm-description "Alert when producer lambda has too many errors" \
    --metric-name Errors \
    --namespace AWS/Lambda \
    --statistic Sum \
    --period 300 \
    --threshold 5 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --dimensions Name=FunctionName,Value=producer

# Alarme: Kinesis com alto iterator age
aws cloudwatch put-metric-alarm \
    --alarm-name kinesis-iterator-age \
    --alarm-description "Alert when Kinesis iterator age is too high" \
    --metric-name GetRecords.IteratorAgeMilliseconds \
    --namespace AWS/Kinesis \
    --statistic Average \
    --period 300 \
    --threshold 60000 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --dimensions Name=StreamName,Value=broker
```

### Dashboard CloudWatch

Crie um dashboard customizado:

1. Acesse CloudWatch Console
2. Dashboards → Create dashboard
3. Adicione widgets para:
   - Lambda invocations (Producer, Consumers)
   - Lambda errors e duração
   - Kinesis incoming/outgoing records
   - S3 bucket size (Raw e Gold)
   - SNS published messages

---

## 💰 Custos Estimados

### Cálculo Mensal (estimativa para uso 24/7)

| Serviço | Uso | Custo Mensal (USD) |
|---------|-----|-------------------|
| **Lambda Producer** | 8.640 execuções/mês (5 min), 128MB, 5s | ~$0.10 |
| **Lambda Consumers** | 8.640 execuções/mês cada, 256-512MB | ~$0.50 |
| **Kinesis Data Stream** | 1 shard, 8.640 registros/mês | ~$15.00 |
| **S3 Storage** | 10GB Raw + 5GB Gold | ~$0.35 |
| **Glue Crawlers** | 4 execuções/dia, 2 crawlers | ~$0.88 |
| **Glue ETL Job** | 4 execuções/dia, 2 DPUs, 5 min | ~$4.00 |
| **Athena** | 100GB scanned/mês | ~$0.50 |
| **SNS** | 1.000 notificações/mês | ~$0.50 |
| **CloudWatch** | Logs padrão | ~$2.00 |
| **TOTAL ESTIMADO** | | **~$23.83/mês** |

> **Nota**: Custos podem variar conforme região e uso real. Use a [AWS Pricing Calculator](https://calculator.aws) para estimativas precisas.

### Otimizações de Custo

- ✅ Use S3 Intelligent-Tiering para dados antigos
- ✅ Configure lifecycle policies para mover dados para Glacier após 90 dias
- ✅ Reduza frequência do Producer se não precisar de dados a cada 5 minutos
- ✅ Use Athena com compressão Parquet (já implementado)
- ✅ Monitore e ajuste memory/timeout das Lambdas

---

## 🔧 Troubleshooting

### Problema: Lambda não consegue acessar Kinesis

**Erro**: `Cannot access stream arn:aws:kinesis...`

**Solução**:
```bash
# Adicionar política inline ao role da Lambda
aws iam put-role-policy \
    --role-name NOME_DO_ROLE \
    --policy-name KinesisAccess \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "kinesis:GetRecords",
                "kinesis:GetShardIterator",
                "kinesis:DescribeStream",
                "kinesis:DescribeStreamSummary",
                "kinesis:ListShards",
                "kinesis:SubscribeToShard"
            ],
            "Resource": "arn:aws:kinesis:us-east-2:*:stream/broker"
        }]
    }'
```

### Problema: SNS não envia emails

**Verificações**:
1. Confirme inscrição no email
2. Verifique spam/lixeira
3. Teste publicação manual:
```bash
aws sns publish \
    --topic-arn arn:aws:sns:us-east-2:SEU_ACCOUNT_ID:snsalerta \
    --message "Test message"
```

### Problema: Crawler não detecta partições

**Solução**:
```bash
# Executar MSCK REPAIR TABLE no Athena
MSCK REPAIR TABLE gold_db.weather_data;

# Ou reconfigurar crawler para detectar partições
aws glue update-crawler \
    --name gold_crawler \
    --configuration '{"Version":1.0,"CrawlerOutput":{"Partitions":{"AddOrUpdateBehavior":"InheritFromTable"}}}'
```

### Problema: Glue Job falha

**Verificações**:
1. Verifique logs no CloudWatch: `/aws-glue/jobs/error` e `/aws-glue/jobs/output`
2. Confirme que schema do Raw existe no Catalog
3. Teste job com pequeno dataset primeiro

### Problema: Athena retorna "TABLE NOT FOUND"

**Solução**:
```sql
-- Listar databases
SHOW DATABASES;

-- Listar tabelas
SHOW TABLES IN gold_db;

-- Se não existir, execute o crawler
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

### Boas Práticas

- Siga PEP 8 para código Python
- Adicione testes unitários
- Documente novas funcionalidades
- Mantenha o README atualizado

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Seu Nome**
- LinkedIn: [seu-perfil](https://linkedin.com/in/seu-perfil)
- GitHub: [@seu-usuario](https://github.com/seu-usuario)
- Email: seu-email@exemplo.com

---

## 🙏 Agradecimentos

- [Tomorrow.io](https://tomorrow.io) pela API de dados meteorológicos
- AWS pela infraestrutura cloud
- Comunidade de Engenharia de Dados

---

## 📚 Recursos Adicionais

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Kinesis Data Streams Guide](https://docs.aws.amazon.com/streams/latest/dev/introduction.html)
- [AWS Glue ETL Best Practices](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)
- [Athena Performance Tuning](https://docs.aws.amazon.com/athena/latest/ug/performance-tuning.html)

---

<div align="center">

**⭐ Se este projeto foi útil, considere dar uma estrela!**

</div>
