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


