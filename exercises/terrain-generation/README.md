# Terrain Generation Exercise

Welcome to the terrain generation exercise!
In this exercise, you will evaluate the effect of generating terrain on AWS Lambda, a commercially available serverless platform.
<!-- TODO What is the workload? During this experiment, we will connect 50 players, and let these players move around on a flat plane. -->

## Experiment Setup

Before we can run our experiment, we need to do the necessary setup.
During setup, we make sure that all necessary resources are in the correct location,
and that all systems are correctly configured.
In this exercise, you can complete the experiment setup by running a single script:

```
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/exercises/terrain-generation/scripts/setup-experiment.sh | bash
source ~/.bashrc # load the prun module
```

## Running the Baseline Experiment

We start our evaluation by running a _baseline_ experiment.
The goal of this experiment is to evaluate the latency of generating terrain locally (i.e., at the server).

Run the following command to reserve 3 machines on the DAS-5 for 900 seconds (15 minutes):

```
preserve -np 2 -t 900
```

Now use `preserve -llist` to list all reservations. Yours will be near the bottom. Note the reservation number you have been assigned, shown in the first column.

The following command uses the OpenCraft Deployer to run your first experiment.
It deploys Opencraft together with Yardstick, a benchmark that emulates players and monitors Opencraft's system behavior.

```
ocd run /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/terrain-generation-experiment <reservation-number>
```

The OpenCraft Deployer prints all commands executed to set up and perform the experiment to standard output. As you can see, most of it is moving configuration and log files around. No magic, but if these files are not in the right place, the system does not do what you want it to do.

> PRO TIP: Running your experiments in `screen` allows you to stop your SSH connection without interrupting your experiments. This is especially useful if your experiments take a long time to run, or your network connection is unreliable.

Now run the following commands to collect and plot the results from your experiment:

```
ocd collect /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/terrain-generation-experiment
python /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/terrain-generation-experiment/figures/plot-network.py
```

Because your connection to the DAS-5 is text only, you will need to move the resulting figures from the DAS-5 to your local machine before you can view them. Run the following command from your local computer:

```
scp -r das5:/var/scratch/<DAS5_USERNAME>/opencraft-tutorial/opencraft-experiments/terrain-generation-experiment/figures .
```

There should now be a `figures` directory on your local machine which contains several figures. Open them to view your experiment results.

### Questions

- The experiment is configured to run the experiment once. (See `experiment-config.toml`.) What can go wrong when running an experiment only once? How can you address this risk?

## Modify Opencraft Configuration

In this section, we run a second experiment while enabling the _serverless terrain generation_ in Opencraft.
By generating chunk data on AWS Lambda, we free resources on the server, which we expect will improve performance.

Run the following commands to create a new configuration for your current experiment:

```
cd /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/terrain-generation-experiment
mkdir -p serverless-generation/resources/config # Create a dir for the new Opencraft config. Change 'serverless-generation' if needed.
cp local-generation/resources/config/opencraft.yml serverless-generation/resources/config
```

Now use a text editor (e.g., `vim` or `nano`) to modify Opencraft's configuration. Open `serverless-generation/resources/config/opencraft.yml`, and set `opencraft.chunk-population.policy` from `default` to `naive`.

Redo the operations discussed in the [previous section](#run-opencraft-experiment) to run the experiment with the new configuration.

### Questions
- Does changing the Opencraft policy significantly affect the behavior of the system? Why (not)?
