## Run Opencraft Experiment

In this section, you will run your first experiment with Opencraft.
The goal of the experiment is to find out the network usage of the game when connecting 50 players.

Run the following command to reserve 3 machines on the DAS-5 for 900 seconds (15 minutes):

```
preserve -np 3 -t 900
```

Now use `preserve -llist` to list all reservations. Yours will be near the bottom. Note the reservation number you have been assigned, shown in the first column.

The following command uses the OpenCraft Deployer to run your first experiment.
It deploys Opencraft together with Yardstick, a benchmark that emulates players and monitors Opencraft's system behavior.

```
ocd run /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment <reservation-number>
```

The OpenCraft Deployer prints all commands executed to set up and perform the experiment to standard output. As you can see, most of it is moving configuration and log files around. No magic, but if these files are not in the right place, the system does not do what you want it to do.

> PRO TIP: Running your experiments in `screen` allows you to stop your SSH connection without interrupting your experiments. This is especially useful if your experiments take a long time to run, or your network connection is unreliable.

Now run the following commands to collect and plot the results from your experiment:

```
ocd collect /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment
python /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment/figures/plot-network.py
```

Because your connection to the DAS-5 is text only, you will need to move the resulting figures from the DAS-5 to your local machine before you can view them. Run the following command from your local computer:

```
scp -r das5:/var/scratch/<DAS5_USERNAME>/opencraft-tutorial/opencraft-experiments/2020/first-experiment/figures .
```

There should now be a `figures` directory on your local machine which contains several figures. Open them to view your experiment results.

#### Questions

- The experiment is configured to run the experiment once. (See `experiment-config.toml`.) What can go wrong when running an experiment only once? How can you address this risk?

## Modify Opencraft Configuration

In this section, we run a second experiment while enabling the _Dyconit chunk policy_ in Opencraft.
Dyconits are a technique to reduce network usage by allowing optimistically bounded inconsistency.
The chunk policy makes players receive fewer updates for objects that are further away.
Because these objects are further away, they player is less likely to focus on them, and less able to see small differences in their appearance or location.
Hopefully, this will significantly reduce the network usage of the game.

Run the following commands to create a new configuration for your current experiment:

```
cd /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment
mkdir -p policy-chunk/resources/config # Create a dir for the new Opencraft config. Change 'policy-chunk' if needed.
cp policy-zero/resources/config/opencraft.yml policy-chunk/resources/config
```

Now use a text editor (e.g., `vim` or `nano`) to modify Opencraft's configuration. Open `policy-chunk/resources/config/opencraft.yml`, and set `opencraft.messaging.policy` from `zero` to `chunk`.

Redo the operations discussed in the [previous section](#run-opencraft-experiment) to run the experiment with the new configuration.

#### Questions
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
cp ~/opencraft/target/opencraft*.jar /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment/policy-new/resources
```

Repeat the steps from the [first section](#run-opencraft-experiment) to repeat the experiment for the new configuration.


