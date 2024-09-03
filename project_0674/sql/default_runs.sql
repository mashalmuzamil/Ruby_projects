CREATE TABLE `raw_ca__contra_costa__runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',

  `created_by`      VARCHAR(255)       DEFAULT 'Mashal Ahmad',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;
