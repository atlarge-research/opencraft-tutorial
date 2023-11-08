# Dyconit Exercise

Welcome to the Dyconit exercise!
In this exercise, you will evaluate the effect of bounded inconsistency on Opencraft's bandwidth usage.
During this experiment, we will connect 50 players, and let these players move around on a flat plane.

## Experiment Setup

Clone this repository and navigate to the directory containing the Dyconit exercise.

```bash
git clone https://github.com/atlarge-research/opencraft-tutorial.git
cd opencraft-tutorial/exercises/dyconits
```

### Questions

- Inspect the `run.sh` file. What is its purpose? What does it do?
- What is the tasks of the Ansible playbooks executed towards the end of the script?
- Answer the same questions for the files `experiment.yml`, `confex.py`, and `environment.yml`.

## Running the Baseline Experiment

Run the baseline experiment by calling `./run.sh`. The script should take care of all necessary setup.

_Expected runtime: 5 minutes_

> PRO TIP: Running your experiments in `screen` allows you to stop your SSH connection without interrupting your experiments. This is especially useful if your experiments take a long time to run, or your network connection is unreliable.

After the experiment, several plots should be available in the output directory `exercises/dyconits/output/[hash]/plots`. Inspect the plots by opening them in your IDE (e.g., VSCode) or by copying them to your local machine (e.g., using `scp`).

### Questions

- What does the result plot show? Is the result what you expect? Why (not)?
- The experiment is configured to run the experiment once. What can go wrong when running an experiment only once? How can you address this risk?

## Modify Opencraft Configuration

In this section, we run a second experiment while enabling the _Dyconit chunk policy_ in Opencraft.
Dyconits are a technique to reduce network usage by allowing optimistically bounded inconsistency.
The chunk policy effectively implements Area of Interest (AoI), letting players receive fewer updates for objects that are further away.
The intuition behind AoI is that objects that are further away are less likely to draw a player's attention, and cannot be observed in as much details as objects that are located nearby.
Therefore, players are less able to see small differences in the appearance or location of these objects.
Reducing the update frequency for these objects will, hopefully, significantly reduce the network usage of the game.

To create a new configuration for your current experiment, edit `experiment.yml` so that the `config` part of it matches the snippet below.

```yml
config:
  type: one_by_one
  params:
    - name: policy
      values: ["zero", "chunk"]
```

Redo the operations discussed in the [previous section](#running-the-baseline-experiment) to run the experiment with the new configuration.
The script may complain about uncommitted changes. Go ahead and commit your changes and try again.

### Questions

- Does changing the Opencraft policy significantly affect the behavior of the system? Why (not)? [Hint: check the plots!]
- How is the configuration option you modified propagated to the *system under test*?

## Modify Opencraft Policy

In this section, we run a final experiment in which you create your own policy. Can we further reduce the network usage?
Can we do so without creating inconsistencies large enough to be noticed by players?
The instructions below make a small but significant change to the Chunk policy, but you can make other changes if you are feeling adventurous!

The Opencraft source code is available in `./cache/opencraft`. 

> PRO TIP: Use an IDE, such as VSCode or Intellij, to directly edit code on a remote machine.

Now that you have a copy of the source code, you can add your own policy.
Copy the existing `ChunkPolicy` as a template:

```
cd opencraft/src/main/java/science/atlarge/opencraft/opencraft/messaging/dyconits/policies
cp ChunkPolicy.java NewChunkPolicy.java
```

 In `NewChunkPolicy.java`, change the class name and update the consistency bounds from a *numerical error* of 2 to a *staleness error* of 1000ms:

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
+                chunks.add(new DyconitSubscribeCommand<>(sub.getKey(), sub.getCallback(), new Bounds(1000, Integer.MAX_VALUE / 2), dyconitName));
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

To compile your code, go back to root of the Opencraft source code (e.g., `opencraft`) and run `mvn package -DskipTests`.
If `mvn` is not available on your path, you can use the copy of Maven available in the cache: `../apache-maven-3.9.5/bin/mvn package -DskipTests`.
Compilation might take a while...
Upon successful compilation, a freshly compiled version of Opencraft should be waiting in the `target` directory.

**Warning!** The experiment runner tries to reset the Opencraft code to the version specified in the `before.yml` playbook.
Edit this file to make sure it uses the version of Opencraft you compiled!

Finally, add `NewChunkPolicy` to the policy values in `experiment.yml`.

Repeat the steps from the [first section](#running-the-baseline-experiment) to repeat the experiment for the new configuration.

### Questions

- How did your custom policy perform compared to the others? Did you expect this behavior? Why (not)?

## Done!

You successfully completed the Dyconit assignment!
To continue with the Opencraft tutorial, go back to the [main page](../../README.md#exercises).
