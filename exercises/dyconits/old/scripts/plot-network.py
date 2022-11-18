import pathlib

import pandas as pandas
import plotly.express as px
from kaleido.scopes.plotly import PlotlyScope
scope = PlotlyScope()
import os

template = "plotly_white"

data = pathlib.Path(os.path.abspath(__file__)).parent.parent.joinpath("results").absolute()
assert data.is_dir()
data_file = data.joinpath("pecosa.log")
assert data_file.is_file()
output_dir = pathlib.Path(__file__).parent.absolute()
assert output_dir.is_dir()

df = pandas.read_csv(data_file, sep="\t")
df["timestamp"] = df.groupby(["iteration", "config"])["timestamp"].transform(lambda x: x - x.min())
df["net.packets_sent.ib0"] = df.groupby(["iteration", "config"])["net.packets_sent.ib0"].transform(
    lambda x: x - x.min())

# It takes 25 seconds to connect all players; cut.
df["timestamp"] = df["timestamp"].transform(lambda x: x - 25000)
df = df[df["timestamp"] >= 0]

fig = px.line(df, x="timestamp", y="net.packets_sent.ib0", color="config", line_group="iteration", template=template,
              labels={
                  "timestamp": "time (ms)", "net.packets_sent.ib0": "packets sent", "config": "Dyconit configuration"})
with open(str(output_dir.joinpath("packets_over_time.pdf")), "wb") as f:
    f.write(scope.transform(fig, format="pdf"))


df = df.groupby(["iteration", "config"], as_index=False).max()
df["packets_per_second"] = df["net.packets_sent.ib0"] / (df["timestamp"] / 1000)
fig = px.box(df, x="config", y="packets_per_second", template=template,
             labels={"config": "Dyconit policy", "packets_per_second": "packets per second"})
with open(str(output_dir.joinpath("packets_per_second_over_policy.pdf")), "wb") as f:
    f.write(scope.transform(fig, format="pdf"))
