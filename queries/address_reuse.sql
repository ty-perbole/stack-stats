WITH

output AS (
  SELECT
      tx.hash AS transaction_hash
    , tx.block_timestamp AS block_ts
    , tx.block_number AS block_number
    , addresses AS address
    , outputs.value AS value
FROM    `bigquery-public-data.crypto_bitcoin.transactions` AS tx,
    tx.outputs AS outputs,
    UNNEST(outputs.addresses) AS addresses
-- WHERE    block_timestamp_month >= "2021-05-01"
),

address_stats AS (
SELECT
    address
  , MIN(block_number) AS first_block_used
  , COUNT(DISTINCT transaction_hash) AS num_txs
FROM output
GROUP BY 1)

SELECT
    DATE(block_ts) AS date

  , COUNT(output.address) AS address_count
  , SUM(IF(address_stats.first_block_used = block_number, 1, 0)) AS new_address_count
  , SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1, 1, 0)) AS reused_address_count
  , SAFE_DIVIDE(SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1, 1, 0)), COUNT(output.address)) AS pct_reused_count

  , COUNT(DISTINCT output.address) AS address_ucount
  , COUNT(DISTINCT IF(address_stats.first_block_used = block_number, output.address, Null)) AS new_address_ucount
  , COUNT(DISTINCT IF(address_stats.first_block_used < block_number AND num_txs > 1, output.address, Null)) AS reused_address_ucount
  , SAFE_DIVIDE(COUNT(DISTINCT IF(address_stats.first_block_used < block_number AND num_txs > 1, output.address, Null)), COUNT(DISTINCT output.address)) AS pct_reused_ucount

  , SUM(output.value) AS address_value
  , SUM(IF(address_stats.first_block_used = block_number, output.value, 0)) AS new_address_value
  , SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1, output.value, 0)) AS reused_address_value
  , SAFE_DIVIDE(SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1, output.value, 0)), SUM(output.value)) AS pct_reused_value

  , SUM(IF(num_txs <= 100, 1, 0)) AS address_count_small
  , SUM(IF(address_stats.first_block_used = block_number AND num_txs <= 100, 1, 0)) AS new_address_count_small
  , SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1 AND num_txs <= 100, 1, 0)) AS reused_address_count_small
  , SAFE_DIVIDE(SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1 AND num_txs <= 100, 1, 0)), SUM(IF(num_txs <= 100, 1, 0))) AS pct_reused_count_small

  , COUNT(DISTINCT IF(num_txs <= 100, output.address, NULL)) AS address_ucount_small
  , COUNT(DISTINCT IF(address_stats.first_block_used = block_number AND num_txs <= 100, output.address, Null)) AS new_address_ucount_small
  , COUNT(DISTINCT IF(address_stats.first_block_used < block_number AND num_txs > 1 AND num_txs <= 100, output.address, Null)) AS reused_address_ucount_small
  , SAFE_DIVIDE(COUNT(DISTINCT IF(address_stats.first_block_used < block_number AND num_txs > 1 AND num_txs <= 100, output.address, Null)), COUNT(DISTINCT IF(num_txs <= 100, output.address, NULL))) AS pct_reused_ucount_small

  , SUM(IF(num_txs <= 100, output.value, 0)) AS address_value_small
  , SUM(IF(address_stats.first_block_used = block_number AND num_txs <= 100, output.value, 0)) AS new_address_value_small
  , SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1 AND num_txs <= 100, output.value, 0)) AS reused_address_value_small
  , SAFE_DIVIDE(SUM(IF(address_stats.first_block_used < block_number AND num_txs > 1 AND num_txs <= 100, output.value, 0)), SUM(IF(num_txs <= 100, output.value, 0))) AS pct_reused_value_small
FROM output
LEFT JOIN address_stats
ON output.address = address_stats.address
GROUP BY 1
ORDER BY 1 ASC