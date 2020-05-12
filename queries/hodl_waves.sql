WITH

-- Outputs subquery: contains relevant information about a given output.
-- A TXO is created when it is an output of a transaction, so this contains
-- metadata about the TXO creation
output AS (
  SELECT
    transactions.HASH AS transaction_hash,
    transactions.block_number AS created_block_number,
    transactions.block_timestamp AS created_block_ts,
    outputs.index AS output_index,
    outputs.value AS output_value
  FROM
    `bigquery-public-data.crypto_bitcoin.transactions` AS transactions,
    transactions.outputs AS outputs
    ),

-- Inputs subquery: contains relevant information about a given input.
-- A TXO is consumed when it is the input to a transaction, so this metadata
-- tells us about when a TXO is spent or destroyed
input AS (
  SELECT
    transactions.hash AS spending_transaction_hash,
    inputs.spent_transaction_hash AS spent_transaction_hash,
    transactions.block_number AS destroyed_block_number,
    transactions.block_timestamp AS destroyed_block_ts,
    inputs.spent_output_index,
    inputs.value AS input_value
  FROM
    `bigquery-public-data.crypto_bitcoin.transactions` AS transactions,
    transactions.inputs AS inputs
    ),

-- txo subquery: joins outputs to inputs so that we know when/if a TXO is spent.
txo AS (
  SELECT
    output.transaction_hash,
    output.created_block_number,
    DATETIME(output.created_block_ts) AS created_block_ts,
    -- Any field from the input table will be NULL if the TXO remains unspent.
    input.spending_transaction_hash,
    input.spent_transaction_hash,
    input.destroyed_block_number,
    DATETIME(input.destroyed_block_ts) AS destroyed_block_ts,
    output.output_value
  FROM
    output
  -- Use Left Join, as not all outputs will be linked as inputs in future transactions if they remain unspent.
  LEFT JOIN
    input
  ON
    -- Join an output to a future input based on the output transaction hash
    -- matching the spent transaction hash of the input
    output.transaction_hash = input.spent_transaction_hash
    -- Also make sure the output index matches within the transaction hash
    AND output.output_index = input.spent_output_index
  ),

-- blocks subquery: for each date get the final block for that date
blocks AS (
  SELECT
    DATE(timestamp) AS date,
    -- Get last block per day
    MAX(number) AS block_number,
    MAX(DATETIME(timestamp)) AS block_ts
  FROM
    `bigquery-public-data.crypto_bitcoin.blocks`
  GROUP BY
    date)

-- final data aggregation query: join txo with blocks, keeping only txo
-- that were created and unspent as of that block, then bucket the txo
-- by age and sum the txo value per bucket per that day
SELECT
  -- Time series metadata
  blocks.date AS date,
  blocks.block_number AS block_number,
  blocks.block_ts AS block_ts,

-- BTC Value Weighting
  -- Total UTXO value on that date
  SUM(txo.output_value) AS total_utxo_value,
  -- Our HODL Waves buckets, counting value of UTXO
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 1, txo.output_value, 0)) AS utxo_value_under_1d,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 1
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 7,
         txo.output_value, 0)) AS utxo_value_1d_1w,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 7
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28,
         txo.output_value, 0)) AS utxo_value_1w_1m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 3,
         txo.output_value, 0)) AS utxo_value_1m_3m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 3
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 6,
         txo.output_value, 0)) AS utxo_value_3m_6m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 6
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12,
         txo.output_value, 0)) AS utxo_value_6m_12m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 18,
         txo.output_value, 0)) AS utxo_value_12m_18m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 18
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 24,
         txo.output_value, 0)) AS utxo_value_18m_24m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 2
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 3,
         txo.output_value, 0)) AS utxo_value_2y_3y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 3
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 5,
         txo.output_value, 0)) AS utxo_value_3y_5y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 5
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 8,
         txo.output_value, 0)) AS utxo_value_5y_8y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 8,
         txo.output_value, 0)) AS utxo_value_greater_8y,

-- Flat Weighting
  -- Total UTXO count on that date
  SUM(1) AS total_utxo_count,
  -- Our HODL Waves buckets, counting number of UTXO
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 1, 1, 0)) AS utxo_count_under_1d,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 1
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 7,
         1, 0)) AS utxo_count_1d_1w,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 7
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28,
         1, 0)) AS utxo_count_1w_1m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 3,
         1, 0)) AS utxo_count_1m_3m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 3
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 6,
         1, 0)) AS utxo_count_3m_6m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 6
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12,
         1, 0)) AS utxo_count_6m_12m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 18,
         1, 0)) AS utxo_count_12m_18m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 18
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 24,
         1, 0)) AS utxo_count_18m_24m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 2
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 3,
         1, 0)) AS utxo_count_2y_3y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 3
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 5,
         1, 0)) AS utxo_count_3y_5y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 5
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 8,
         1, 0)) AS utxo_count_5y_8y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 8,
         1, 0)) AS utxo_count_greater_8y,

-- Flat weighting, filtered
  -- Total UTXO count on that date (> 0.01 BTC)
  SUM(IF(txo.output_value / 100000000 > 0.01, 1, 0)) AS total_utxo_count_filter,
  -- Our HODL Waves buckets, counting number of UTXO (> 0.01 BTC)
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 1
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_under_1d,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 1
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 7
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_1d_1w,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 7
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_1w_1m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 3
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_1m_3m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 3
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 6
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_3m_6m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 6
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_6m_12m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 18
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_12m_18m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 18
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 24
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_18m_24m,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 2
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 3
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_2y_3y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 3
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 5
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_3y_5y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 5
         AND DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) < 28 * 12 * 8
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_5y_8y,
  SUM(IF(DATETIME_DIFF(blocks.block_ts, txo.created_block_ts, DAY) >= 28 * 12 * 8
         AND txo.output_value / 100000000 >= 0.01,
         1, 0)) AS utxo_count_filter_greater_8y
FROM
  blocks
CROSS JOIN
  txo
WHERE
  -- Only include transactions that were created on or after the given block
  blocks.block_number >= txo.created_block_number
  -- Only include transactions there were unspent as of the given block
  AND (
    -- Transactions that are spent after the given block, so they are included
    blocks.block_number < txo.destroyed_block_number
    -- Transactions that are never spent, so they are included
    OR txo.destroyed_block_number IS NULL)
GROUP BY
  date, block_number, block_ts
ORDER BY
  date ASC;