# Stack Stats Tutorials: Bitcoin data science

## About
Author: [@typerbole](https://twitter.com/typerbole), [GitHub](https://github.com/ty-perbole), [stack-stats.com](http://www.stack-stats.com)

This repo contains jupyter notebook tutorials on various Bitcoin data science topics. I plan to publish new notebooks 
every few weeks.

My goal is to develop a better understanding of these topics by exploring them myself, as I learn best this way, and to
provide the end product as a learning resource for others who want the same experience

## Instructions

- Install Jupyter. I recommend installing [Anaconda](https://www.anaconda.com/distribution/) (Python 3) to get Jupyter 
and other common Python data science packages.
- Familiarize yourself with Jupyter notebooks, if not already familiar: [tutorial 1](https://www.dataquest.io/blog/jupyter-notebook-tutorial/), [tutorial 2](https://plotly.com/python/ipython-notebook-tutorial/).
- Clone the repository to your local machine: `git clone git@github.com:ty-perbole/stack-stats.git`
- Spin up Jupyter: run `jupyter notebook` in your terminal
- Navigate to the stack-stats repo in jupyter and open the .ipynb file for the tutorial you want to try
- You may have to install additional libraries (right now, Plotly) to run the notebooks

## Rendered HTML notebooks
Available at
- https://ty-perbole.github.io/stack-stats/index.html.
- [01_BitcoinNetworkRatios](https://ty-perbole.github.io/stack-stats/01_BitcoinNetworkRatios.html)
- [02_HODLWavesPart1](https://ty-perbole.github.io/stack-stats/02_HODLWavesPart1.html)
- [03_HODLWavesPart2RealizedCap](https://ty-perbole.github.io/stack-stats/03_HODLWavesPart2RealizedCap.html)
- [04_BlockSpaceMarket](https://ty-perbole.github.io/stack-stats/04_BlockSpaceMarket.html)

If you don't want to install Jupyter and run the tutorials yourself you can view the tutorials as rendered HTML in your browser.
You will not be able to run code in the HTML version but you will be able to see the visualizations and follow along.

It's also worth noting that GitHub will not render the Plotly charts if you click into the .ipynb files. Instead it will just say something like:

`FigureWidget({
    'data': [{'name': 'NVTRatioAdj',
              'type': 'scatter',
              'uid': 'f6a…`
              
So if you want to see the visualizations without running the notebook locally, use the HTML version.

## Misc Work
- [RealCap Weighted HODL Waves Chart](https://ty-perbole.github.io/stack-stats/RealCapHODLWaves.html)
- [Bitcoin Security Margin Analysis](https://ty-perbole.github.io/stack-stats/SecurityMargin.html)
- [Coinbase Output Herfindahl Index](https://ty-perbole.github.io/stack-stats/MinerHerfMultiple.html)