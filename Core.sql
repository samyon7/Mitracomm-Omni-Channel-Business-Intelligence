-- DATABASE SYSTEM: MITRACOMM BUSINESS INTELLIGENCE & ENTERPRISE ECOSYSTEM
-- Dialect: MySQL 8.0+

DROP VIEW IF EXISTS view_bi_hr_recruitment_funnel;
DROP VIEW IF EXISTS view_bi_chatbot_performance;
DROP VIEW IF EXISTS view_bi_balanced_scorecard_summary;

DROP TABLE IF EXISTS fact_kpi_monthly_records;
DROP TABLE IF EXISTS bsc_kpis;
DROP TABLE IF EXISTS bsc_perspectives;
DROP TABLE IF EXISTS ai_chatbot_logs;
DROP TABLE IF EXISTS interactions;
DROP TABLE IF EXISTS operational_agents;
DROP TABLE IF EXISTS channels;
DROP TABLE IF EXISTS hr_recruitment_assessments;
DROP TABLE IF EXISTS candidates;
DROP TABLE IF EXISTS client_contracts;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS master_services;

CREATE TABLE master_services (
    service_id INT AUTO_INCREMENT PRIMARY KEY,
    service_code VARCHAR(30) NOT NULL UNIQUE,
    service_name VARCHAR(150) NOT NULL,
    service_category ENUM('Business Process Services', 'Transactional Process', 'IT Solutions', 'Value Added Services (VAS)') NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    client_code VARCHAR(30) NOT NULL UNIQUE,
    company_name VARCHAR(150) NOT NULL,
    industry ENUM('Banking & Finance', 'Telecommunication', 'E-Commerce', 'Government', 'Retail', 'Logistics') NOT NULL,
    contact_person VARCHAR(100),
    contact_email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE client_contracts (
    contract_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    service_id INT NOT NULL,
    contract_number VARCHAR(50) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    sla_percentage_target DECIMAL(5,2) DEFAULT 95.00,
    status ENUM('Active', 'Expired', 'Terminated') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contracts_client FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE,
    CONSTRAINT fk_contracts_service FOREIGN KEY (service_id) REFERENCES master_services(service_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE candidates (
    candidate_id INT AUTO_INCREMENT PRIMARY KEY,
    nik VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    position_applied VARCHAR(100) NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE hr_recruitment_assessments (
    assessment_id INT AUTO_INCREMENT PRIMARY KEY,
    candidate_id INT NOT NULL,
    cv_score_ai DECIMAL(5,2) COMMENT 'Skor parsing CV oleh AI Model (0-100)',
    wa_confirmation_status ENUM('Pending', 'Confirmed', 'Declined') DEFAULT 'Pending',
    psychotest_score DECIMAL(5,2) COMMENT 'Hasil Psikotes online',
    camera_ai_proctor_score DECIMAL(5,2) COMMENT 'Integritas via model kamera AI',
    scoring_1_interview DECIMAL(5,2) COMMENT 'Scoring 1: First Interview Text/AI',
    user_interview_score DECIMAL(5,2) COMMENT 'Scoring 2: User Interview Human',
    final_interview_score DECIMAL(5,2) COMMENT 'Final Assessment Scoring',
    final_decision ENUM('Screening', 'Psikotest', 'User Interview', 'Final Interview', 'Accepted', 'Rejected') DEFAULT 'Screening',
    contract_signed BOOLEAN DEFAULT FALSE,
    company_email_created VARCHAR(100) NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_hr_candidate FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE operational_agents (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    agent_badge_id VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(100) NOT NULL,
    role ENUM('Agent Inbound', 'Agent Outbound', 'Team Leader', 'QA Specialist') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE channels (
    channel_id INT AUTO_INCREMENT PRIMARY KEY,
    channel_code VARCHAR(30) NOT NULL UNIQUE,
    channel_name ENUM('WhatsApp', 'LiveChat', 'Inbound Call', 'Outbound Call', 'Email', 'Social Media') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE interactions (
    interaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    channel_id INT NOT NULL,
    agent_id INT NULL COMMENT 'Null jika ditangani full bot',
    customer_identifier VARCHAR(100) NOT NULL COMMENT 'Nomor HP / Email customer',
    interaction_start TIMESTAMP NOT NULL,
    interaction_end TIMESTAMP NULL,
    handling_time_seconds INT DEFAULT 0,
    resolution_status ENUM('Resolved', 'Escalated', 'Pending', 'Dropped') DEFAULT 'Pending',
    csat_rating TINYINT NULL CHECK (csat_rating BETWEEN 1 AND 5),
    CONSTRAINT fk_interactions_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
    CONSTRAINT fk_interactions_channel FOREIGN KEY (channel_id) REFERENCES channels(channel_id),
    CONSTRAINT fk_interactions_agent FOREIGN KEY (agent_id) REFERENCES operational_agents(agent_id)
) ENGINE=InnoDB;

CREATE TABLE ai_chatbot_logs (
    chat_log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    interaction_id BIGINT NOT NULL,
    session_token VARCHAR(64) NOT NULL,
    user_question TEXT NOT NULL,
    llm_model_used VARCHAR(50) DEFAULT 'Gemma-2-9B-Instruct',
    intent_detected VARCHAR(100),
    confidence_score DECIMAL(5,4),
    generated_output_type ENUM('SOP Text', 'Scheduling', 'Document PDF', 'Excel Sheet', 'Email Invitation') NOT NULL,
    bot_response_payload TEXT NOT NULL,
    response_latency_ms INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chatlog_interaction FOREIGN KEY (interaction_id) REFERENCES interactions(interaction_id) ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE bsc_perspectives (
    perspective_id INT AUTO_INCREMENT PRIMARY KEY,
    perspective_code VARCHAR(20) NOT NULL UNIQUE,
    perspective_name ENUM('Financial', 'Customer Relationship', 'Internal Processes', 'Education & Growth') NOT NULL,
    weight_percentage DECIMAL(5,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE bsc_kpis (
    kpi_id INT AUTO_INCREMENT PRIMARY KEY,
    perspective_id INT NOT NULL,
    kpi_code VARCHAR(30) NOT NULL UNIQUE,
    kpi_name VARCHAR(150) NOT NULL,
    measurement_unit VARCHAR(30) NOT NULL,
    target_value DECIMAL(10,2) NOT NULL,
    calculation_formula VARCHAR(255),
    CONSTRAINT fk_kpi_perspective FOREIGN KEY (perspective_id) REFERENCES bsc_perspectives(perspective_id)
) ENGINE=InnoDB;

CREATE TABLE fact_kpi_monthly_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    kpi_id INT NOT NULL,
    period_year_month CHAR(7) NOT NULL COMMENT 'Format YYYY-MM',
    actual_value DECIMAL(10,2) NOT NULL,
    target_value DECIMAL(10,2) NOT NULL,
    achievement_percentage DECIMAL(5,2) GENERATED ALWAYS AS ((actual_value / target_value) * 100) STORED,
    status ENUM('Exceeded', 'Achieved', 'Underperformed') NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fact_kpi FOREIGN KEY (kpi_id) REFERENCES bsc_kpis(kpi_id)
) ENGINE=InnoDB;

-- Indeks Tambahan untuk Query Analitis
CREATE INDEX idx_interaction_time ON interactions(interaction_start, resolution_status);
CREATE INDEX idx_chatbot_intent ON ai_chatbot_logs(intent_detected, confidence_score);
CREATE INDEX idx_kpi_period ON fact_kpi_monthly_records(period_year_month);


INSERT INTO master_services (service_code, service_name, service_category, description) VALUES
('BPS-CC-01', 'Full Managed Contact Center', 'Business Process Services', 'Layanan contact center end-to-end lengkap infrastruktur & agent'),
('BPS-DE-02', 'Digital Omnichannel Engagement', 'Business Process Services', 'Pengelolaan interaksi media sosial, chat, dan email'),
('TX-TC-01', 'Telecollection Services', 'Transactional Process', 'Layanan penagihan terarah berbasis outbound predictive dialer'),
('TX-TS-02', 'Telesales & Telemarketing', 'Transactional Process', 'Layanan penjualan produk keuangan/telekomunikasi via outbound'),
('IT-CC-01', 'Hosted Contact Center & AI', 'IT Solutions', 'Sistem platform contact center cloud & integrasi AI bot N8N'),
('VAS-TR-01', 'Motivational & Softskill Training', 'Value Added Services (VAS)', 'Program training akselerasi performa agent'),
('VAS-LR-02', 'Laptop Rental & Premises', 'Value Added Services (VAS)', 'Penyediaan perangkat kerja agent tersertifikasi security');


INSERT INTO clients (client_code, company_name, industry, contact_person, contact_email) VALUES
('CL-BNI-01', 'PT Bank Mega Sentosa Tbk', 'Banking & Finance', 'Hendra Gunawan', 'hendra.g@megasentosa.co.id'),
('CL-TEL-02', 'PT Telekomunikasi Nusantara Digital', 'Telecommunication', 'Siti Rahma', 'siti.rahma@nusantaradigital.net'),
('CL-ECO-03', 'PT Belanja Cepat Indonesia', 'E-Commerce', 'Budi Hartono', 'budi.h@belanjacepat.id'),
('CL-FIN-04', 'PT Dana Pay Pintar', 'Banking & Finance', 'Jessica Tan', 'jessica@danapay.co.id');


INSERT INTO client_contracts (client_id, service_id, contract_number, start_date, end_date, sla_percentage_target, status) VALUES
(1, 1, 'CTR-MTR-2024-001', '2024-01-01', '2025-12-31', 98.00, 'Active'),
(1, 3, 'CTR-MTR-2024-002', '2024-02-01', '2025-01-31', 95.00, 'Active'),
(2, 5, 'CTR-MTR-2024-003', '2024-03-15', '2025-03-14', 99.50, 'Active'),
(3, 2, 'CTR-MTR-2024-004', '2024-04-01', '2025-04-01', 95.00, 'Active'),
(4, 4, 'CTR-MTR-2024-005', '2024-05-01', '2024-11-30', 90.00, 'Active');


INSERT INTO channels (channel_code, channel_name) VALUES
('CH-WA', 'WhatsApp'),
('CH-LC', 'LiveChat'),
('CH-IN-CALL', 'Inbound Call'),
('CH-OUT-CALL', 'Outbound Call'),
('CH-EML', 'Email');


INSERT INTO operational_agents (agent_badge_id, full_name, email, role, is_active) VALUES
('AGT-001', 'Rian Firmansyah', 'rian.f@mitracomm.internal', 'Agent Inbound', TRUE),
('AGT-002', 'Anisa Tri Wulandari', 'anisa.w@mitracomm.internal', 'Agent Inbound', TRUE),
('AGT-003', 'Dimas Pratama', 'dimas.p@mitracomm.internal', 'Agent Outbound', TRUE),
('AGT-004', 'Dewi Anggraini', 'dewi.a@mitracomm.internal', 'QA Specialist', TRUE);


INSERT INTO candidates (nik, full_name, email, phone_number, position_applied) VALUES
('3171012304950001', 'Fajar Ramadhan', 'fajar.ramadhan@gmail.com', '081289123401', 'Call Center Specialist'),
('3171012304950002', 'Nabila Putri', 'nabila.putri@yahoo.com', '081289123402', 'Customer Service Omnichannel'),
('3171012304950003', 'Bayu Wicaksono', 'bayu.wicak@outlook.com', '081289123403', 'Telemarketing Officer'),
('3171012304950004', 'Putri Ayu Lestari', 'putri.ayu@gmail.com', '081289123404', 'Call Center Specialist');


INSERT INTO hr_recruitment_assessments 
(candidate_id, cv_score_ai, wa_confirmation_status, psychotest_score, camera_ai_proctor_score, scoring_1_interview, user_interview_score, final_interview_score, final_decision, contract_signed, company_email_created) 
VALUES
(1, 88.50, 'Confirmed', 82.00, 95.00, 85.00, 88.00, 89.00, 'Accepted', TRUE, 'fajar.ramadhan@mitracomm.co.id'),
(2, 92.00, 'Confirmed', 89.00, 98.00, 90.00, 92.00, 94.00, 'Accepted', TRUE, 'nabila.putri@mitracomm.co.id'),
(3, 71.00, 'Confirmed', 60.00, 80.00, 65.00, 58.00, 55.00, 'Rejected', FALSE, NULL),
(4, 84.00, 'Confirmed', 78.00, 91.00, 80.00, 82.00, NULL, 'Final Interview', FALSE, NULL);


INSERT INTO interactions 
(client_id, channel_id, agent_id, customer_identifier, interaction_start, interaction_end, handling_time_seconds, resolution_status, csat_rating) 
VALUES
(1, 1, NULL, '+628111222333', '2024-05-10 08:30:00', '2024-05-10 08:32:15', 135, 'Resolved', 5),
(1, 3, 1, '+628111222444', '2024-05-10 08:45:00', '2024-05-10 08:52:00', 420, 'Resolved', 4),
(2, 2, NULL, 'guest_session_9821', '2024-05-10 09:00:00', '2024-05-10 09:04:30', 270, 'Resolved', 5),
(3, 1, 2, '+628190987654', '2024-05-10 09:15:00', '2024-05-10 09:28:00', 780, 'Escalated', 2),
(4, 4, 3, '+628571234567', '2024-05-10 10:00:00', '2024-05-10 10:05:40', 340, 'Resolved', 5);

INSERT INTO ai_chatbot_logs 
(interaction_id, session_token, user_question, llm_model_used, intent_detected, confidence_score, generated_output_type, bot_response_payload, response_latency_ms) 
VALUES
(1, 'sess_wa_token_001', 'Bagaimana prosedur penutupan kartu kredit yang hilang?', 'Gemma-2-9B-Instruct', 'SOP_BLOCK_CARD', 0.9850, 'SOP Text', 'Prosedur pemblokiran kartu darurat: 1. Konfirmasi identitas 2. Akses menu blokir di Mobile Banking atau sebutkan nomor referensi darurat...', 420),
(1, 'sess_wa_token_001', 'Tolong buatkan jadwal appointment ke kantor cabang terdekat', 'Gemma-2-9B-Instruct', 'SCHEDULE_APPOINTMENT', 0.9620, 'Scheduling', 'Jadwal temu berhasil dibuat: Cabang Sudirman, 11 Mei 2024 pukul 10:00 WIB. Nomor antrean virtual: A-042.', 610),
(3, 'sess_lc_token_002', 'Berapa tarif roaming internasional paket data Asia Tenggara?', 'BERT-Mitracomm-FineTuned', 'FAQ_ROAMING_RATE', 0.9410, 'Document PDF', 'Berikut ringkasan tarif paket roaming Asia Tenggara. File PDF syarat & ketentuan telah digenerate: https://mitracomm.storage/docs/roaming-asean-2024.pdf', 380);


INSERT INTO bsc_perspectives (perspective_code, perspective_name, weight_percentage) VALUES
('BSC-FIN', 'Financial', 25.00),
('BSC-CUS', 'Customer Relationship', 30.00),
('BSC-INT', 'Internal Processes', 25.00),
('BSC-LRN', 'Education & Growth', 20.00);


INSERT INTO bsc_kpis (perspective_id, kpi_code, kpi_name, measurement_unit, target_value, calculation_formula) VALUES
(1, 'KPI-FIN-01', 'Net Profit Margin Operational BPO', 'Percentage', 22.00, '(Net Income / Operational Revenue) * 100'),
(2, 'KPI-CUS-01', 'Customer Satisfaction Score (CSAT)', 'Score (1-5)', 4.50, 'Average of total client customer ratings'),
(2, 'KPI-CUS-02', 'Service Level Agreement (SLA) Compliance', 'Percentage', 95.00, '(Interactions meeting SLA / Total) * 100'),
(3, 'KPI-INT-01', 'Chatbot First Contact Resolution (FCR)', 'Percentage', 75.00, '(Bot Resolved Cases / Total Bot Sessions) * 100'),
(3, 'KPI-INT-02', 'Average Handling Time (AHT) Inbound', 'Seconds', 300.00, 'Total handle time / Total incoming calls'),
(4, 'KPI-LRN-01', 'Agent Training Hours per FTE', 'Hours', 16.00, 'Total training hours completed / Headcount'),
(4, 'KPI-LRN-02', 'HR Recruitment AI Acceptance Accuracy', 'Percentage', 90.00, '(Accurate probationary pass / AI recommended) * 100');


INSERT INTO fact_kpi_monthly_records (kpi_id, period_year_month, actual_value, target_value, status) VALUES
(1, '2024-04', 23.50, 22.00, 'Exceeded'),
(2, '2024-04', 4.62, 4.50, 'Exceeded'),
(3, '2024-04', 96.20, 95.00, 'Exceeded'),
(4, '2024-04', 78.40, 75.00, 'Exceeded'),
(5, '2024-04', 320.00, 300.00, 'Underperformed'),
(6, '2024-04', 18.00, 16.00, 'Exceeded'),
(7, '2024-04', 92.50, 90.00, 'Exceeded'),
(1, '2024-05', 21.80, 22.00, 'Achieved'),
(2, '2024-05', 4.45, 4.50, 'Achieved'),
(3, '2024-05', 94.80, 95.00, 'Achieved'),
(4, '2024-05', 81.10, 75.00, 'Exceeded'),
(5, '2024-05', 295.00, 300.00, 'Exceeded'),
(6, '2024-05', 15.50, 16.00, 'Achieved'),
(7, '2024-05', 93.00, 90.00, 'Exceeded');

CREATE VIEW view_bi_balanced_scorecard_summary AS
SELECT 
    f.period_year_month,
    p.perspective_name,
    k.kpi_code,
    k.kpi_name,
    k.measurement_unit,
    f.target_value,
    f.actual_value,
    f.achievement_percentage,
    f.status
FROM fact_kpi_monthly_records f
JOIN bsc_kpis k ON f.kpi_id = k.kpi_id
JOIN bsc_perspectives p ON k.perspective_id = p.perspective_id;

CREATE VIEW view_bi_chatbot_performance AS
SELECT 
    l.llm_model_used,
    l.intent_detected,
    l.generated_output_type,
    COUNT(l.chat_log_id) AS total_requests,
    ROUND(AVG(l.confidence_score), 4) AS avg_confidence,
    ROUND(AVG(l.response_latency_ms), 2) AS avg_latency_ms,
    ROUND(AVG(i.csat_rating), 2) AS related_csat
FROM ai_chatbot_logs l
JOIN interactions i ON l.interaction_id = i.interaction_id
GROUP BY l.llm_model_used, l.intent_detected, l.generated_output_type;

CREATE VIEW view_bi_hr_recruitment_funnel AS
SELECT 
    c.position_applied,
    COUNT(c.candidate_id) AS total_applicants,
    ROUND(AVG(h.cv_score_ai), 2) AS avg_ai_cv_score,
    ROUND(AVG(h.psychotest_score), 2) AS avg_psychotest,
    ROUND(AVG(h.user_interview_score), 2) AS avg_user_interview,
    SUM(CASE WHEN h.final_decision = 'Accepted' THEN 1 ELSE 0 END) AS total_accepted,
    SUM(CASE WHEN h.contract_signed = TRUE THEN 1 ELSE 0 END) AS total_hired
FROM candidates c
JOIN hr_recruitment_assessments h ON c.candidate_id = h.candidate_id
GROUP BY c.position_applied;
