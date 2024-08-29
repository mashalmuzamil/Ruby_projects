CREATE TABLE `mo_saac_case_party`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`        INT,
  `case_id`         VARCHAR(255), 
  # any columns
  `party_name`      VARCHAR(255),
  `party_type`      VARCHAR(255),
  `is_lawyer`       BOOLEAN,
  `party_law_firm`  VARCHAR(255),
  `party_city`      VARCHAR(255),
  `party_state`     VARCHAR(255),
  `party_zip`       VARCHAR(255),
  `party_address`   VARCHAR(255),
  `party_description`  VARCHAR(255),
  
  `data_source_url` TEXT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Mashal Ahmad',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,


  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by ';
