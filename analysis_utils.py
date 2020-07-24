import datetime

def get_extra_datetime_cols(df, datecol, date_format="%Y-%m-%d"):
    df['datetime'] = [datetime.datetime.strptime(x, date_format) for x in df[datecol]]
    if date_format != "%Y-%m-%d":
        df['date'] = [x.strftime("%Y-%m-%d") for x in df['datetime']]
    df['year_string'] = [x.strftime('%Y') for x in df['datetime']]
    df['month_string'] = [x.strftime('%B %Y') for x in df['datetime']]
    df['week_string'] = [(x - datetime.timedelta(days=x.weekday())).strftime('%Y-%m-%d') for x in
                          df['datetime']]
    return df

def sats_fee_bucket(fee):
    bucket = ''
    if fee == 0:
        bucket = '0'
    elif fee < 2:
        bucket = '0-2'
    elif fee < 4:
        bucket = '2-4'
    elif fee < 6:
        bucket = '4-6'
    elif fee < 9:
        bucket = '6-9'
    elif fee < 12:
        bucket = '9-12'
    elif fee < 18:
        bucket = '12-18'
    elif fee < 24:
        bucket = '18-24'
    elif fee < 30:
        bucket = '24-30'
    elif fee < 40:
        bucket = '30-40'
    elif fee < 50:
        bucket = '40-50'
    elif fee < 60:
        bucket = '50-60'
    elif fee < 80:
        bucket = '60-80'
    elif fee < 100:
        bucket = '80-100'
    elif fee < 130:
        bucket = '100-130'
    elif fee < 170:
        bucket = '130-170'
    elif fee < 220:
        bucket = '170-220'
    elif fee < 350:
        bucket = '220-350'
    elif fee < 600:
        bucket = '350-600'
    elif fee >= 600:
        bucket = '600+'
    return bucket

def usd_fee_bucket(fee):
    bucket = ''
    if fee == 0:
        bucket = '$0'
    elif fee < 0.00005:
        bucket = '$0-$0.00005'
    elif fee < 0.00008:
        bucket = '$0.00005-$0.00008'
    elif fee < 0.0001:
        bucket = '$0.00008-$0.0001'
    elif fee < 0.00015:
        bucket = '$0.0001-$0.00015'
    elif fee < 0.0002:
        bucket = '$0.00015-$0.0002'
    elif fee < 0.00025:
        bucket = '$0.0002-$0.00025'
    elif fee < 0.0003:
        bucket = '$0.00025-$0.0003'
    elif fee < 0.0004:
        bucket = '$0.0003-$0.0004'
    elif fee < 0.0005:
        bucket = '$0.0004-$0.0005'
    elif fee < 0.00065:
        bucket = '$0.0005-$0.00065'
    elif fee < 0.0009:
        bucket = '$0.00065-$0.0009'
    elif fee < 0.001:
        bucket = '$0.0009-$0.001'
    elif fee < 0.0015:
        bucket = '$0.001-$0.0015'
    elif fee < 0.002:
        bucket = '$0.0015-$0.002'
    elif fee < 0.003:
        bucket = '$0.002-$0.003'
    elif fee < 0.0045:
        bucket = '$0.003-$0.0045'
    elif fee < 0.007:
        bucket = '$0.0045-$0.007'
    elif fee < 0.01:
        bucket = '$0.007-$0.01'
    elif fee < 0.15:
        bucket = '$0.01-$0.15'
    elif fee >= 0.15:
        bucket = '$0.15+'
    return bucket

SATS_FEE_BINS = [
    '0', '0-2', '2-4', '4-6', '6-9',
    '9-12', '12-18', '18-24', '24-30', '30-40',
    '40-50', '50-60', '60-80', '80-100',
    '100-130', '130-170', '170-220', '220-350', '350-600',
    '600+']

USD_FEE_BINS = [
    '$0', '$0-$0.00005', '$0.00005-$0.00008', '$0.00008-$0.0001',
    '$0.0001-$0.00015', '$0.00015-$0.0002', '$0.0002-$0.00025',
    '$0.00025-$0.0003', '$0.0003-$0.0004', '$0.0004-$0.0005',
    '$0.0005-$0.00065', '$0.00065-$0.0009', '$0.0009-$0.001',
    '$0.001-$0.0015', '$0.0015-$0.002', '$0.002-$0.003', '$0.003-$0.0045',
    '$0.0045-$0.007', '$0.007-$0.01', '$0.01-$0.15', '$0.15+'
]