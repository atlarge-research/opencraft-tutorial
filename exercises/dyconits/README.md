# Dyconit Exercise

Welcome to the Dyconit exercise!
In this exercise, you will evaluate the effect of bounded inconsistency on Opencraft's bandwidth usage.
During this experiment, we will connect 50 players, and let these players move around on a flat plane.

## Experiment Setup

Before we can run our experiment, we need to do the necessary setup.
During setup, we make sure that all necessary resources are in the correct location,
and that all systems are correctly configured.
In this exercise, you can complete the experiment setup by running a single script:

```
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/exercises/dyconits/scripts/setup-experiment.sh | bash
```

That's it!
You just downloaded Opencraft (the _System Under Test_), Yardstick (the benchmark generating the _workload_), a monitoring script (to collect the right _metrics_ during the experiment), and several configuration files. We can now proceed with running the experiment.

## Running the Baseline Experiment

Run the following command to reserve 3 machines on the DAS-5 for 900 seconds (15 minutes):

```
preserve -np 3 -t 900
```

Now use `preserve -llist` to list all reservations. Yours will be near the bottom. Note the reservation number you have been assigned, shown in the first column.

The following command uses the OpenCraft Deployer to run your first experiment.
This experiment will form the _baseline_: the default behavior of the system (i.e., without using Dyconits), to which we can compare later results.

```
ocd run /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/dyconit-experiment <reservation-number>
```

The OpenCraft Deployer moves the executables and configuration files downloaded during the setup to temporary locations on the nodes you just reserved, starts the experiment, and collects the results when the experiment completes.
The OpenCraft Deployer prints all commands it executes to standard output.
Now we simply wait for the experiment to complete.

> PRO TIP: Running your experiments in `screen` allows you to stop your SSH connection without interrupting your experiments. This is especially useful if your experiments take a long time to run, or your network connection is unreliable.

After the experiment completes, we will manually run a script to plot the results:

```
ocd collect /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/dyconit-experiment
python /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/dyconit-experiment/figures/plot-network.py
```

Because your connection to the DAS-5 is text only, you will need to move the resulting figures from the DAS-5 to your local machine before you can view them. Run the following command from your local computer:

```
scp -r das5:/var/scratch/<DAS5_USERNAME>/opencraft-tutorial/opencraft-experiments/dyconit-experiment/figures .
```

There should now be a `figures` directory on your local machine which contains several figures. Open them to view your experiment results.

### Questions

- What does the result plot show? Is the result what you expect? Why (not)?
- The experiment is configured to run the experiment once. (See `experiment-config.toml`.) What can go wrong when running an experiment only once? How can you address this risk?

## Modify Opencraft Configuration

In this section, we run a second experiment while enabling the _Dyconit chunk policy_ in Opencraft.
Dyconits are a technique to reduce network usage by allowing optimistically bounded inconsistency.
The chunk policy effectively implements Area of Interest (AoI), letting players receive fewer updates for objects that are further away.
The intuition behind AoI is that objects that are further away are less likely to draw a player's attention, and cannot be observed in as much details as objects that are located nearby.
Therefore, players are less able to see small differences in the appearance or location of these objects.
Reducing the update frequency for these objects will, hopefully, significantly reduce the network usage of the game.

Run the following commands to create a new configuration for your current experiment:

```
cd /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/dyconit-experiment
mkdir -p policy-chunk/resources/config # Create a dir for the new Opencraft config. Change 'policy-chunk' if needed.
cp policy-zero/resources/config/opencraft.yml policy-chunk/resources/config
```

Now use a text editor (e.g., `vim` or `nano`) to modify Opencraft's configuration. Open `policy-chunk/resources/config/opencraft.yml`, and set `opencraft.messaging.policy` from `zero` to `chunk`.

Redo the operations discussed in the [previous section](#run-opencraft-experiment) to run the experiment with the new configuration.
The Opencraft Deployer will automatically detect that you already ran the baseline experiment, and skip it.

### Questions

- What system behavior is controlled by the configuration option you modified?
- Does changing the Opencraft policy significantly affect the behavior of the system? Why (not)?

## Modify Opencraft Policy

In this section, we run a final experiment in which you create your own policy. Can we further reduce the network usage?
Can we do so without creating inconsistencies large enough to be noticed by players?
The instructions below make a small but significant change to the Chunk policy, but you can make other changes if you are feeling adventurous!

You first need to download Maven, the toolchain used to compile Opencraft's source code. You can do so by executing the following commands:

```
cd
wget https://mirror.lyrahosting.com/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip
unzip apache-maven-3.6.3-bin.zip
echo PATH="/home/$(whoami)/apache-maven-3.6.3/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
mvn --version # Check that mvn command was added to PATH
rm apache-maven-3.6.3-bin.zip
```

Now you can get the Opencraft source code by running `git clone https://github.com/atlarge-research/opencraft-opencraft.git opencraft`. This will create a directory called `opencraft` containing the Opencraft source code.

> PRO TIP: Editing code directly on the DAS-5 is slow and error prone. Modern IDEs, such as Intellij, can deploy code directly to a remote machine. This allows you to edit code in your favorite editor, and use it on the DAS-5. Setting up such automatic deployment is left as an exercise for the reader.

Now that you have a copy of the source code, you can add your own policy.
Copy the existing `ChunkPolicy` as a template:

```
cd opencraft/src/main/java/science/atlarge/opencraft/opencraft/messaging/dyconits/policies
cp ChunkPolicy.java NewChunkPolicy.java
```

 In `NewChunkPolicy.java`, change the class name and swap the parameters passed to the `Bounds` constructor:

```
 import science.atlarge.opencraft.dyconits.policies.DyconitPolicy;
 import science.atlarge.opencraft.dyconits.policies.DyconitSubscribeCommand;
 
-public class ChunkPolicy implements DyconitPolicy<Player, Message> {
+public class NewChunkPolicy implements DyconitPolicy<Player, Message> {
 
     private final int viewDistance;
     private static final String CATCH_ALL_DYCONIT_NAME = "catch-all";
 
-    public ChunkPolicy(int viewDistance) {
+    public NewChunkPolicy(int viewDistance) {
         this.viewDistance = viewDistance;
     }
 

...

         for (int x = centerX - radius; x <= centerX + radius; x++) {
             for (int z = centerZ - radius; z <= centerZ + radius; z++) {
                 Chunk chunk = world.getChunkAt(x, z);
                 String dyconitName = chunkToName(chunk);
-                chunks.add(new DyconitSubscribeCommand<>(sub.getKey(), sub.getCallback(), new Bounds(Integer.MAX_VALUE / 2, 2), dyconitName));
+                chunks.add(new DyconitSubscribeCommand<>(sub.getKey(), sub.getCallback(), new Bounds(2, Integer.MAX_VALUE / 2), dyconitName));
                 playerSubscriptions.add(dyconitName);
             }
         }
         return chunks;
```

In `PolicyFactory.java`, add an `else if` statement to enable the new policy:

```
             return new ZeroBoundsPolicy();
         } else if (nameMatches(InfiniteBoundsPolicy.class, policyName)) {
             return new InfiniteBoundsPolicy();
+        } else if (nameMatches(NewChunkPolicy.class, policyName)) {
+            return new NewChunkPolicy(server.getViewDistance());
         }
         return null;
     }
```

Now that you have added a new policy to Opencraft, you can compile the code. To do so, go back to `~/opencraft` and run `mvn package -DskipTests`. This will take a while... (You can enable the tests, but that will increase the compilation time even further.) Upon successful compilation, a freshly compiled version of Opencraft should be waiting in the `target` directory.

Repeat the steps in the [previous section](#modify-opencraft-configuration) to add a new configuration to your experiment. This time, call the new configuration `policy-new`. In the corresponding `opencraft.yml` configuration file, change the policy to `NewChunkPolicy`.

The new policy is not supported by the Opencraft version you used in our previous experiments. To use the new version of Opencraft, copy the new Opencraft jar to the new configuration's resources folder:

```
cp ~/opencraft/target/opencraft*.jar /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/dyconit-experiment/policy-new/resources
```

Repeat the steps from the [first section](#run-opencraft-experiment) to repeat the experiment for the new configuration.

### Questions

- How did your custom policy perform compared to the others? Did you expect this behavior?

## Done!

You successfully completed the dyconit assignment!
To continue with the Opencraft tutorial, go back to the [main page](../../README.md#exercises).
