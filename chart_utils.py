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
        specs=[[{"secondary_y": True}]],
    )

    if isinstance(y1_series, str):
        y1_series_title = y1_series
        y1_series = [y1_series]
    elif isinstance(y1_series, list):
        if "Roll" in y1_series[0]:
            y1_series_title = y1_series[0][: y1_series[0].find("Roll")]
        else:
            y1_series_title = y1_series[0]

    for y1 in y1_series:
        # First trace
        fig.add_trace(
            go.Scatter(x=df[x_series], y=df[y1], name=y1),
            secondary_y=False
        )

    # Second trace
    fig.add_trace(
        go.Scatter(x=df[x_series], y=df[y2_series], name=y2_series),
        secondary_y=True,
    )

    # Add figure title
    fig.update_layout(
        title_text=kwargs.get('title', y1_series_title),
        # paper_bgcolor='rgba(0,0,0,0)',
        # plot_bgcolor='rgba(169,169,169,0.5)'
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

    # Set y-axes titles
    fig.update_yaxes(
        title_text=y1_series_title, secondary_y=False,
        type=kwargs.get('y1_series_axis_type', 'linear'), range=kwargs.get('y1_series_axis_range'),
        showgrid=False
    )
    fig.update_yaxes(
        title_text=y2_series, secondary_y=True, tickformat="${n},",
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
