import datetime

import plotly.graph_objects as go
from plotly.subplots import make_subplots

def two_axis_chart(df, x_series, y1_series, y2_series, **kwargs):
    """
        Plot a two axis chart using Plotly library

        Arguments:
        df (dataframe): Pandas dataframe containing CoinMetrics community data
        x_series (string): Column name for x series, typically 'Date'
        y1_series (string, list): C dolumn name, or list of column names, to plot on the left Y axis
        y2_series (string): Column name to plot on the right Y axis, typically 'PriceUSD'

        Keyword arguments:
        title (string): Title for the plot
        x_axis_title (string): Title for X axis, defaults to string from x_series
        y1_series_axis_type (string): Left Y axis type. Default is 'log'. Other sane option: 'linear'
        y1_series_axis_range (list): Range for left Y axis. When axis type is log, range values represent powers of 10
        y2_series_axis_type (string): Right Y axis type. Default is 'log'. Other sane option: 'linear'
        y2_series_axis_range (list): Range for right Y axis. When axis type is log, range values represent powers of 10
        y1_upper_thresh (float): Upper threshold for highlighting regions with extreme values for Y1 series
        y1_lower_thresh (float): Lower threshold for highlighting regions with extreme values for Y1 series
        thresh_inverse (bool): When true, high values of a ratio metric are highlighted green. When false, high values
            indicate poor fundamentals and are highlighted red. Inverse logic for lower threshold.

        Returns:
            Plotly figure

        """
    # Create figure with secondary y-axis
    fig = make_subplots(
        specs=[[{"secondary_y": True}]]
    )

    if isinstance(y1_series, str):
        y1_series_title = y1_series
        y1_series = [y1_series]
    elif isinstance(y1_series, list):
        if "Roll" in y1_series[0]:
            y1_series_title = y1_series[0][: y1_series[0].find("Roll")]
        else:
            y1_series_title = y1_series[0]

    if kwargs.get('y1_series_title'):
        y1_series_title = kwargs.get('y1_series_title')

    for y1 in y1_series:
        # First trace
        fig.add_trace(
            go.Scatter(x=df[x_series], y=df[y1], name=y1),
            secondary_y=False
        )

    # Second trace
    fig.add_trace(
        go.Scatter(x=df[x_series], y=df[y2_series], name=y2_series,
                   line=dict(color='darkorange')
                   ),
        secondary_y=True
    )

    # Add figure title
    fig.update_layout(
        title_text=kwargs.get('title', y1_series_title),
    )

    # Set x-axis title
    if kwargs.get('x_axis_title'):
        fig.update_xaxes(title_text=kwargs.get('x_axis_title'))

    if kwargs.get('y1_upper_thresh') or kwargs.get('y1_lower_thresh'):
        highlight_shapes = []

        if kwargs.get('y1_upper_thresh'):
            highlight_shapes.extend(create_highlighted_region_shapes(
                get_threshold_dates(df, x_series, y1_series[0], kwargs.get('y1_upper_thresh'), upper_bound=True),
                fillcolor=('LightGreen' if kwargs.get('thresh_inverse', False) else 'LightSalmon')
                )
            )

        if kwargs.get('y1_lower_thresh'):
            highlight_shapes.extend(create_highlighted_region_shapes(
                get_threshold_dates(df, x_series, y1_series[0], kwargs.get('y1_lower_thresh'), upper_bound=False),
                fillcolor=('LightSalmon' if kwargs.get('thresh_inverse', False) else 'LightGreen')
                )
            )

        fig.update_layout(
            shapes=highlight_shapes
        )

    fig.update_layout(
        annotations=[
            dict(x=1, y=-0.1,
                 text="Chart by: @typerbole; Data: {}".format(kwargs.get('data_source')) if kwargs.get('data_source') else "Chart by: @typerbole",
                 showarrow=False, xref='paper', yref='paper',
                 xanchor='right', yanchor='auto', xshift=0, yshift=0)
        ],
        showlegend=True,
        legend_orientation="h",
        template="plotly_dark"

    )

    # Set y-axes titles
    fig.update_yaxes(
        title_text=y1_series_title, secondary_y=False, tickformat=kwargs.get('y1_series_axis_format', None),
        type=kwargs.get('y1_series_axis_type', 'linear'), range=kwargs.get('y1_series_axis_range'),
        showgrid=False
    )
    fig.update_yaxes(
        title_text=y2_series, secondary_y=True, tickformat=kwargs.get('y2_series_axis_format', "${n},"),
        type=kwargs.get('y2_series_axis_type', 'linear'), range=kwargs.get('y2_series_axis_range'),
        showgrid=False
    )

    return fig.show()


def get_threshold_dates(df, x_series, y_series, thresh, upper_bound=True):
    ''' Get a list of date regions that are above or below a certain threshold '''
    date_regions = []

    if upper_bound:
        date_subset = df.loc[df[y_series] >= thresh][x_series]
    else:
        date_subset = df.loc[df[y_series] <= thresh][x_series]
    if len(date_subset) > 0:
        for index, date in enumerate(date_subset):
            date_datetime = datetime.datetime.strptime(date, '%Y-%m-%d')
            if index == 0:
                date_region = (date, date)
            elif (prev_date + datetime.timedelta(days=1)) == date_datetime:
                date_region = (date_region[0], date)
            else:
                date_regions.append(date_region)
                date_region = (date, date)
            prev_date = date_datetime
        date_regions.append(date_region)
    return date_regions

def create_highlighted_region_shapes(date_regions, fillcolor='LightSalmon'):
    ''' Build a list of highlighted regions to feed to plotly '''
    shapes = []
    for region in date_regions:
        shapes.append(
            dict(
                type="rect",
                # x-reference is assigned to the x-values
                xref="x",
                # y-reference is assigned to the plot paper [0,1]
                yref="paper",
                x0=region[0],
                y0=0,
                x1=region[1],
                y1=1,
                fillcolor=fillcolor,
                opacity=0.5,
                layer="below",
                line_width=0,
            )
        )
    return shapes

def hodl_waves_chart(df, version='value'):
    """
            Plot a two axis chart using Plotly library

            Arguments:
            df (dataframe): Pandas dataframe containing HODL waves dataframe from 02_HODLWaves.ipynb notebook
            version: Can plot HODL waves by TXO value ('value), by total count of TXO ('count'),
                     and by TXO with balance > 0.01 BTC ('count_filter')

            Returns:
                Plotly figure

            """
    x = df['date']
    fig = make_subplots(
        specs=[[{"secondary_y": True}]],
    )

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_under_1d'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(229.0, 89.0, 52.0)',
        fill='tonexty',
        name='<1d',
        stackgroup='one',
        groupnorm='percent'  # sets the normalization for the sum of the stackgroup
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_1d_1w'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(228.8, 112.0, 52.6)',
        fill='tonexty',
        name='1d-1w',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_1w_1m'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(228.6, 135.0, 53.2)',
        fill='tonexty',
        name='1w-1m',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_1m_3m'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(228.4, 158.0, 53.8)',
        fill='tonexty',
        name='1m-3m',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_3m_6m'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(228.2, 181.0, 54.4)',
        fill='tonexty',
        name='3m-6m',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_6m_12m'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(228.0, 204.0, 55.0)',
        fill='tonexty',
        name='6m-12m',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_12m_18m'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(182.4, 192.0, 82.2)',
        fill='tonexty',
        name='12m-18m',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_18m_24m'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(136.8, 180.0, 109.4)',
        fill='tonexty',
        name='18m-2y',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_2y_3y'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(91.2, 168.0, 136.6)',
        fill='tonexty',
        name='2y-3y',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_3y_5y'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(45.6, 156.0, 163.8)',
        fill='tonexty',
        name='3y-5y',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_5y_8y'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(0.0, 144.0, 191.0)',
        fill='tonexty',
        name='5y-8y',
        stackgroup='one',
    ))

    fig.add_trace(go.Scatter(
        x=x, y=df['utxo_{}_greater_8y'.format(version)],
        mode='lines',
        line=dict(width=0.5, color='rgb(0, 0, 0)'),
        fillcolor='rgb(0.0, 100.0, 130.0)',
        fill='tonexty',
        name='>8y',
        stackgroup='one',
    ))

    fig.update_layout(
        showlegend=True,
        legend_orientation="h",
        yaxis=dict(
            type='linear',
            range=[1, 100],
            ticksuffix='%'))

    # Second trace
    fig.add_trace(go.Scatter(
        x=x, y=df['PriceUSD'],
        name='PriceUSD',
        mode='lines',
        line=dict(width=2, color='rgb(0, 0, 0)'),
    ),
        secondary_y=True,
    )

    fig.add_trace(go.Scatter(
        x=['2012-11-29', '2012-11-29'],
        y=[0, 1000000],
        mode="lines",
        showlegend=False,
        line=dict(width=2, color='black', dash="dot"),
        ),
        secondary_y=True
    )

    fig.add_trace(go.Scatter(
        x=['2016-07-10', '2016-07-10'],
        y=[0, 1000000],
        mode="lines",
        showlegend=False,
        line=dict(width=2, color='black', dash="dot"),
    ),
        secondary_y=True
    )

    fig.update_yaxes(
        title_text='PriceUSD', secondary_y=True, tickformat="${n},",
        type='log', range=[-2, 5],
        showgrid=False
    )

    # Add figure title
    fig.update_layout(
        title_text='Bitcoin HODL Waves: {} weighted'.format(version),
        annotations=[
            dict(x=1, y=-0.1,
                 text="Chart by: @typerbole",
                 showarrow=False, xref='paper', yref='paper',
                 xanchor='right', yanchor='auto', xshift=0, yshift=0)
        ],
    )

    # Set x-axis title
    fig.update_xaxes(title_text='Date')

    return fig.show()