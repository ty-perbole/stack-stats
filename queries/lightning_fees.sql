SELECT
    DATE(tx.block_timestamp) AS date
  , SUM(fee) * (1e-8) AS total_fees
  , SUM(IF(type = 'channel_open', fee, 0)) * (1e-8) AS channel_open_fees
  , SUM(IF(type = 'channel_close', fee, 0)) * (1e-8) AS channel_close_fees
  , SUM(IF(type IN ('channel_close', 'channel_open'), fee, 0)) * (1e-8) AS lightning_fees
  , SUM(IF(type IN ('channel_close', 'channel_open'), fee, 0)) / SUM(fee) AS lightning_pct
FROM `bigquery-public-data.crypto_bitcoin.transactions` tx
LEFT JOIN `bitcoinkpis.misc.lightning_txids` l
ON tx.hash = l.txid
WHERE tx.block_timestamp_month >= "2017-01-01"
GROUP BY 1
ORDER BY 1 ASC