-- This is the coinmetrics BTC community data imported into BigQuery, as described in tutorial #3
WITH cm AS (
SELECT
  date,
  PriceUSD
FROM
-- ** YOU WILL HAVE TO REPLACE THE PROJECT NAME HERE TO REFLECT YOUR OWN BIGQUERY TABLE **
  `replace_this_project.bitcoin.cm_btc`),

fees AS
(SELECT
  -- Transaction date
  DATE(tx.block_timestamp) AS date,

  -- Fee in sats/vByte. Rounded to nearest integer and capped at 1k to reduce row size
  IF(ROUND(tx.fee / tx.virtual_size, 0) > 1000, 1000, ROUND(tx.fee / tx.virtual_size, 0)) AS sats_per_vbyte,
  -- Fee bucket in sats/vByte
  CASE
    WHEN tx.fee / tx.virtual_size = 0 THEN '0'
    WHEN tx.fee / tx.virtual_size < 2 THEN '0-2'
    WHEN tx.fee / tx.virtual_size < 4 THEN '2-4'
    WHEN tx.fee / tx.virtual_size < 6 THEN '4-6'
    WHEN tx.fee / tx.virtual_size < 9 THEN '6-9'
    WHEN tx.fee / tx.virtual_size < 12 THEN '9-12'
    WHEN tx.fee / tx.virtual_size < 18 THEN '12-18'
    WHEN tx.fee / tx.virtual_size < 24 THEN '18-24'
    WHEN tx.fee / tx.virtual_size < 30 THEN '24-30'
    WHEN tx.fee / tx.virtual_size < 40 THEN '30-40'
    WHEN tx.fee / tx.virtual_size < 50 THEN '40-50'
    WHEN tx.fee / tx.virtual_size < 60 THEN '50-60'
    WHEN tx.fee / tx.virtual_size < 80 THEN '60-80'
    WHEN tx.fee / tx.virtual_size < 100 THEN '80-100'
    WHEN tx.fee / tx.virtual_size < 130 THEN '100-130'
    WHEN tx.fee / tx.virtual_size < 170 THEN '130-170'
    WHEN tx.fee / tx.virtual_size < 220 THEN '170-220'
    WHEN tx.fee / tx.virtual_size < 350 THEN '220-350'
    WHEN tx.fee / tx.virtual_size < 600 THEN '350-600'
    WHEN tx.fee / tx.virtual_size >= 600 THEN '600+'
    ELSE 'NA' END AS sats_per_vbyte_bucket,

  -- Fee in USD/vbye. Rounded to nearest tenth of a dollar and capped at $100 to reduce row size
  IF(ROUND((tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size, 6) > 100, 100, ROUND((tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size, 6)) AS usd_per_vbyte,
  -- Fee bucket in USD/vByte
  CASE
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size = 0 THEN '$0'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.00005 THEN '$0-$0.00005'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.00008 THEN '$0.00005-$0.00008'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0001 THEN '$0.00008-$0.0001'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.00015 THEN '$0.0001-$0.00015'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0002 THEN '$0.00015-$0.0002'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.00025 THEN '$0.0002-$0.00025'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0003 THEN '$0.00025-$0.0003'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0004 THEN '$0.0003-$0.0004'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0005 THEN '$0.0004-$0.0005'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.00065 THEN '$0.0005-$0.00065'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0009 THEN '$0.00065-$0.0009'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.001 THEN '$0.0009-$0.001'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0015 THEN '$0.001-$0.0015'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.002 THEN '$0.0015-$0.002'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.003 THEN '$0.002-$0.003'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.0045 THEN '$0.003-$0.0045'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.007 THEN '$0.0045-$0.007'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.01 THEN '$0.007-$0.01'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size < 0.15 THEN '$0.01-$0.15'
    WHEN (tx.fee * cm.PriceUSD / 100000000) / tx.virtual_size >= 0.15 THEN '$0.15+'
    ELSE 'NA' END AS usd_per_vbyte_bucket,
  tx.fee AS fee,
  tx.fee * cm.PriceUSD / 100000000 AS fee_usd,
  tx.virtual_size AS virtual_size
FROM
  `bigquery-public-data.crypto_bitcoin.transactions` AS tx
JOIN
  cm
ON
  DATE(tx.block_timestamp) = cm.date
WHERE
  NOT(tx.is_coinbase))

-- Run and save this query for the data in part 1
SELECT
  month,
  bucket,
  bucket_type,
  tx_count
FROM

    (SELECT
      -- Aggregate per month to make data more manageable
      DATE_TRUNC(date, MONTH) AS month,
      sats_per_vbyte_bucket AS bucket,
      'sats' AS bucket_type,
      SUM(1) AS tx_count
    FROM
      fees
    GROUP BY
      month,
      bucket,
      bucket_type)

UNION ALL

    (SELECT
      -- Aggregate per month to make data more manageable
      DATE_TRUNC(date, MONTH) AS month,
      usd_per_vbyte_bucket AS bucket,
      'usd' AS bucket_type,
      SUM(1) AS tx_count
    FROM
      fees
    GROUP BY
      month,
      bucket,
      bucket_type)

ORDER BY
  month ASC, bucket_type, bucket
;

-- Run and save this query for the data in part 2
-- SELECT
--   date,
--   SUM(fee) AS sum_fees_sats,
--   SUM(fee_usd) AS sum_fees_usd,
--   SUM(virtual_size) AS sum_block_vbytes
-- FROM
--   fees
-- GROUP BY
--   date
-- ORDER BY
--   date ASC;