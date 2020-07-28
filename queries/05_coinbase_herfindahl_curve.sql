WITH

dates AS (
  SELECT
    DATE(blocks.timestamp) AS date
  FROM
    `bigquery-public-data.crypto_bitcoin.blocks` AS blocks
  GROUP BY
    date
  ORDER BY
    date ASC
),

coinbase_output AS (
 SELECT
   tx.hash AS coinbase_tx_hash,
   tx.block_number AS coinbase_block_number,
   tx.block_timestamp AS coinbase_block_ts,
   DATE_DIFF(dates.date, DATE(tx.block_timestamp), DAY) AS days_since_coinbase,
   dates.date AS metric_date,
   outputs.index AS coinbase_output_index,
   outputs.value / 100000000 AS coinbase_output_value,
   tx.output_value / 100000000 AS coinbase_total_output_value
 FROM
   `bigquery-public-data.crypto_bitcoin.transactions` AS tx,
   tx.outputs AS outputs
 CROSS JOIN
   dates
 WHERE
   dates.date >= DATE(tx.block_timestamp)
   AND DATE_DIFF(dates.date, DATE(tx.block_timestamp), DAY) BETWEEN 0 AND 28 * 2
   AND tx.is_coinbase
   AND outputs.value > 0
   ),

tx AS (
 SELECT
   tx.block_number AS block_number,
   tx.block_timestamp AS block_timestamp,

   inputs.spent_transaction_hash AS previous_tx_hash,
   inputs.spent_output_index AS input_spent_output_index,
   inputs.value / 100000000 AS input_value,
   tx.input_value / 100000000 AS tx_total_input_value,

   tx.hash AS current_tx_hash,
   outputs.index AS output_index,
   outputs.value / 100000000 AS output_value,
   tx.output_value / 100000000 AS tx_total_output_value
 FROM
   `bigquery-public-data.crypto_bitcoin.transactions` AS tx,
   tx.inputs AS inputs,
   tx.outputs AS outputs
 WHERE
   tx.hash IS NOT NULL
   AND outputs.index IS NOT NULL
   ),

coinbase_txo_flow AS (
 SELECT
   coinbase_output.days_since_coinbase AS days_since_coinbase,
   coinbase_output.coinbase_tx_hash AS coinbase_tx_hash,
   coinbase_output.coinbase_block_number AS coinbase_block_number,
   DATETIME(coinbase_output.coinbase_block_ts) AS coinbase_block_ts,
   coinbase_output.coinbase_output_index AS coinbase_output_index,
   coinbase_output.coinbase_output_value AS coinbase_output_value,

   tx1.block_number AS tx1_block_number,
   tx1.block_timestamp AS tx1_block_ts,
   tx1.current_tx_hash AS tx1_tx_hash,
   tx1.output_index AS tx1_output_index,
   tx1.output_value AS tx1_output_value,
   IEEE_DIVIDE(tx1.input_value, tx1.tx_total_input_value) AS tx1_scale_factor,
   tx1.output_value
    * IEEE_DIVIDE(tx1.input_value, tx1.tx_total_input_value) AS tx1_output_value_adj,

   tx2.block_number AS tx2_block_number,
   tx2.block_timestamp AS tx2_block_ts,
   tx2.current_tx_hash AS tx2_tx_hash,
   tx2.output_index AS tx2_output_index,
   tx2.output_value AS tx2_output_value,
   IEEE_DIVIDE(tx2.input_value, tx2.tx_total_input_value) AS tx2_scale_factor,
   tx2.output_value
     * IEEE_DIVIDE(tx2.input_value, tx2.tx_total_input_value)
     * IEEE_DIVIDE(tx1.input_value, tx1.tx_total_input_value) AS tx2_output_value_adj,

   tx3.block_number AS tx3_block_number,
   tx3.block_timestamp AS tx3_block_ts,
   tx3.current_tx_hash AS tx3_tx_hash,
   tx3.output_index AS tx3_output_index,
   tx3.output_value AS tx3_output_value,
   tx3.input_value / tx3.tx_total_input_value AS tx3_scale_factor,
   tx3.output_value
     * IEEE_DIVIDE(tx3.input_value, tx3.tx_total_input_value)
     * IEEE_DIVIDE(tx2.input_value, tx2.tx_total_input_value)
     * IEEE_DIVIDE(tx1.input_value, tx1.tx_total_input_value) AS tx3_output_value_adj,

   tx4.block_number AS tx4_block_number,
   tx4.block_timestamp AS tx4_block_ts,
   tx4.current_tx_hash AS tx4_tx_hash,
   tx4.output_index AS tx4_output_index,
   tx4.output_value AS tx4_output_value,
   tx4.input_value / tx4.tx_total_input_value AS tx4_scale_factor,
   tx4.output_value
     * IEEE_DIVIDE(tx4.input_value, tx4.tx_total_input_value)
     * IEEE_DIVIDE(tx3.input_value, tx3.tx_total_input_value)
     * IEEE_DIVIDE(tx2.input_value, tx2.tx_total_input_value)
     * IEEE_DIVIDE(tx1.input_value, tx1.tx_total_input_value) AS tx4_output_value_adj

 FROM
   coinbase_output

 LEFT JOIN
   tx AS tx1
 ON
   coinbase_output.coinbase_tx_hash = tx1.previous_tx_hash
   AND coinbase_output.coinbase_output_index = tx1.input_spent_output_index
   AND coinbase_output.metric_date >= DATE(tx1.block_timestamp)

 LEFT JOIN
   tx AS tx2
 ON
   tx1.current_tx_hash = tx2.previous_tx_hash
   AND tx1.output_index = tx2.input_spent_output_index
   AND coinbase_output.metric_date >= DATE(tx2.block_timestamp)

 LEFT JOIN
   tx AS tx3
 ON
   tx2.current_tx_hash = tx3.previous_tx_hash
   AND tx2.output_index = tx3.input_spent_output_index
   AND coinbase_output.metric_date >= DATE(tx3.block_timestamp)

 LEFT JOIN
   tx AS tx4
 ON
   tx3.current_tx_hash = tx4.previous_tx_hash
   AND tx3.output_index = tx4.input_spent_output_index
   AND coinbase_output.metric_date >= DATE(tx4.block_timestamp)

 WHERE
   IF(tx1.block_number IS NOT NULL, tx1.block_number >= coinbase_output.coinbase_block_number, True)
   AND IF(tx2.block_number IS NOT NULL, tx2.block_number >= tx1.block_number, True)
   AND IF(tx3.block_number IS NOT NULL, tx3.block_number >= tx2.block_number, True)
   AND IF(tx4.block_number IS NOT NULL, tx4.block_number >= tx3.block_number, True)
 ),

txos AS (
SELECT
  days_since_coinbase,
  coinbase_tx_hash,
  coinbase_block_number,
  coinbase_block_ts,
  coinbase_output_value,
  CASE
    WHEN tx4_output_value IS NOT NULL THEN CONCAT(tx4_tx_hash, " ", tx4_output_index)
    WHEN tx3_output_value IS NOT NULL THEN CONCAT(tx3_tx_hash, " ", tx3_output_index)
    WHEN tx2_output_value IS NOT NULL THEN CONCAT(tx2_tx_hash, " ", tx2_output_index)
    WHEN tx1_output_value IS NOT NULL THEN CONCAT(tx1_tx_hash, " ", tx1_output_index)
  ELSE CONCAT(coinbase_tx_hash, " ", coinbase_output_index) END AS row_source,
  CASE
    WHEN tx4_output_value IS NOT NULL THEN tx4_output_value_adj
    WHEN tx3_output_value IS NOT NULL THEN tx3_output_value_adj
    WHEN tx2_output_value IS NOT NULL THEN tx2_output_value_adj
    WHEN tx1_output_value IS NOT NULL THEN tx1_output_value_adj
  ELSE coinbase_output_value END
      AS row_contribution
FROM
  coinbase_txo_flow
  ),

herf AS (
SELECT
  txos.days_since_coinbase AS days_since_coinbase,
  txos.coinbase_tx_hash AS coinbase_tx_hash,
  txos.coinbase_block_number AS coinbase_block_number,
  txos.coinbase_block_ts AS coinbase_block_ts,
  cb_sum.coinbase_total_value AS coinbase_total_value,
  txos.row_contribution AS row_contribution,
  IEEE_DIVIDE(txos.row_contribution, cb_sum.coinbase_total_value) AS row_pct,
  IEEE_DIVIDE(txos.row_contribution, cb_sum.coinbase_total_value)
    * IEEE_DIVIDE(txos.row_contribution, cb_sum.coinbase_total_value) AS row_herf

FROM
  txos
JOIN
(SELECT
  days_since_coinbase,
  coinbase_tx_hash,
  SUM(row_contribution) AS coinbase_total_value
FROM
  txos
GROUP BY
  days_since_coinbase, coinbase_tx_hash) AS cb_sum
ON
  txos.coinbase_tx_hash = cb_sum.coinbase_tx_hash
  AND txos.days_since_coinbase = cb_sum.days_since_coinbase
),

herf_block AS (
SELECT
  coinbase_tx_hash,
  coinbase_block_number,
  coinbase_block_ts,
  days_since_coinbase,
  SUM(row_contribution) AS coinbase_total_value,
  SUM(row_herf) herfindal_index
FROM
  herf
GROUP BY
  coinbase_tx_hash,
  coinbase_block_number,
  coinbase_block_ts,
  days_since_coinbase)

SELECT
  *
FROM
  herf_block