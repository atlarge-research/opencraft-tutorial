# Opencraft Tutorial

Minecraft is one of the most best-selling games of all time.
It has sold more than 200 million copies,[^1] and has more than 126 million active monthly players.[^2]
In contrast to traditional games, Minecraft gives players fine-grained control over the environment.
Players can be creative and alter the environment to their liking.
Players can decide to create buildings, mines, farms, logical circuits, and other constructions.
Minecraft's success has led to the creation of hundreds of similar games, which we collectively refer to as _Minecraft-like games_.

Despite the popularity of these games, their scalability is limited.
The original Minecraft and popular spin-offs can only support between 200-300 players under favorable conditions.[^3]
To support its more than 126 million active monthly players, these games rely on the replication of small, isolated instances, preventing large groups of players from playing together.

The Opencraft research project addresses these challenges through research aimed at improving our understanding of the performance of Minecraft-like games, and the design and evaluation of novel scalability techniques.
As part of this this effort, we develop Opencraft.
Opencraft is a Minecraft-like game and research platform that is used to evaluate novel scalability techniques.

In this tutorial, you will set up, run, and conduct a basic experiment with Opencraft. After completing this tutorial, you have experience with:

1. Setting up and running a distributed system.
2. Running a distributed system.
2. Configuring a distributed system.
3. Writing code for a distributed system.
4. Analyzing the behavior of a distributed system.

# Setup — Hello, World!

## Connecting to the DAS-5

Append the following configuration to your SSH configuration file, located at `~/.ssh/config`:

```
Host vu-data
	HostName ssh.data.vu.nl
	User VUNET_USERNAME

Host das5
	HostName fs0.das5.cs.vu.nl
	User DAS5_USERNAME
	ProxyJump vu-data
```

You should now be able to connect to the DAS-5 using the command `ssh das5`.
SSH will first request your VUnet password, and then your DAS-5 password.

> PROTIP: If you connect to the DAS-5 regularly, it is worth switching to public-key authentication using `ssh-keygen` and `ssh-copy-id`. This is left as an exercise for the reader.

## Collecting Your Tools

Opencraft consists of a collection of tools. We will set perform the necessary setup in two steps. First we create a Python environment with the necessary packages, and then we download the Opencraft-specific tools. From this point onwards, all commands should be executed on the DAS-5, unless otherwise specified.

### Python

We will use Miniconda to create a Python environment with the necessary packages.
Miniconda simplifies the process of creating portable Python environments with specfic Python runtime and package versions.

Download the Miniconda installer for Linux:

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```
Run the installer, and **make sure to install Miniconda in `/var/scratch/<USERNAME>/`**.

Now we create a new Python environment that contains the exact Python runtime and package versions we need to run the Opencraft tools.

```
wget https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/conda/spec-file.txt
conda create --name opencraft --file spec-file.txt
echo "conda activate opencraft" >> ~/.bashrc
rm spec-file.txt
```
Restart your SSH connection. You should now see `(opencraft)` prepended to your terminal prompt. You can also verify the correct Python runtime is used by running `which python`.

### Opencraft Tools

To dowload and configure the Opencraft tools, run the following command:

```
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/scripts/setup-opencraft.sh | sh
```

> PRO TIP: Never execute code straight from the Internet. :)

Follow the installation instructions printed on your terminal to complete the setup.

## BONUS: Join Your Own Opencraft Game

This is a good moment to take a breath and check that everything we have done so far. TODO write.

```
preserve -np 1 -t 300
```

`TODO SSH SSH`

# Exercises

## Run Opencraft Experiment

Run the following command to reserve 3 machines on the DAS-5 for 900 seconds (15 minutes):

```
preserve -np 3 -t 900
```

Now use `preserve -llist` to list all reservations. Yours will be near the bottom. Note the reservation number you have been assigned, shown in the first column.

```
ocd run /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment <reservation-number>
```

The OpenCraft Deployer prints all commands executed to set up and perform the experiment to standard output. As you can see, most of it is moving configuration and log files around. No magic, but if these files are not in the right place, the system does not do what you want it to do.

> PRO TIP: Running your experiments in `screen` allows you to stop your SSH connection without interrupting your experiments. This is especially useful if your experiments take a long time to run, or your network connection is unreliable.

Now run the following commands to collect and plot the results from your experiment:

```
ocd collect /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment
TODO ocd plot
```

Because your connection to the DAS-5 is text only, we need to move the resulting figures from the DAS-5 to your local machine before we can view them. Run the following command from your local computer:

```
scp -r das5:/var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment/figures .
```

There should now be a `figures` directory on your local machine which contains several figures. Open them to view your experiment results.

#### Questions

- The experiment is configured to run the experiment once. (See `experiment-config.toml`.) What can go wrong when running an experiment only once? How can you address this risk?

## Modify Opencraft Configuration

Now we will change the configuration of Opencraft to see how that affects the system behavior

Run the following commands to create a new configuration for your current experiment:

```
cd /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment
mkdir -p policy-chunk/resources/config
cp policy-zero/resources/config/opencraft.yml policy-chunk/resources/config
```

Now use a text editor (e.g., `vim` or `nano`) to modify Opencraft's configuration. Open `policy-chunk/resources/config/opencraft.yml`, and set `opencraft.messaging.policy` from `zero` to `chunk`.

Redo the operations discussed in the [previous section](#run-opencraft-experiment) to run the experiment with the new configuration.

#### Questions
- Does changing the Opencraft policy significantly affect the behavior of the system? Why (not)?

## Modify Opencraft Policy

The final exercise in this tutorial involves modifying Opencraft's behavior by modifying its source code.

You first need to download Maven, the toolchain used to compile Opencraft's source code. You can do so be executing the following commands:

```
cd
wget https://mirror.lyrahosting.com/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip
unzip apache-maven-3.6.3-bin.zip
echo PATH="/home/$(whoami)/apache-maven-3.5.0/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
```

Now you can get the Opencraft source code by running `git clone git@github.com:atlarge-research/opencraft-opencraft.git opencraft`. This will create a directory called `opencraft` containing the Opencraft source code.

> PRO TIP: Editing code directly on the DAS-5 is slow and error prone. Modern IDEs, such as Intellij, can deploy code directly to a remote machine. This allows you to edit code in your favorite editor, and use it on the DAS-5. Setting up such automatic deployment is left as an exercise for the reader.

Now that you have a copy of the source code, you can add your own policy.
Copy the existing `ChunkPolicy` as a template:

```
cd opencraft/src/main/java/science/atlarge/opencraft/opencraft/messaging/dyconits/policies
cp ChunkPolicy.java NewChunkPolicy.java
```

Swap the parameters passed to the `Bounds` constructor in `NewChunkPolicy.java`:

```
         for (int x = centerX - radius; x <= centerX + radius; x++) {
             for (int z = centerZ - radius; z <= centerZ + radius; z++) {
                 Chunk chunk = world.getChunkAt(x, z);
-                chunks.add(new DyconitSubscribeCommand<>(sub.getKey(), sub.getCallback(), new Bounds(Integer.MAX_VALUE / 2, 2), chunkToName(chunk)));
+                chunks.add(new DyconitSubscribeCommand<>(sub.getKey(), sub.getCallback(), new Bounds(2, Integer.MAX_VALUE / 2), chunkToName(chunk)));
             }
         }
         return chunks;
```

Add an `else if` statement in `PolicyFactory.java` to enable the new policy:

```
             return new ZeroBoundsPolicy();
         } else if (nameMatches(InfiniteBoundsPolicy.class, policyName)) {
             return new InfiniteBoundsPolicy();
+        } else if (nameMatches(NewChunkPolicy.class, policyName)) {
+            return new NewChunkPolicy();
         }
         return null;
     }
```

Now that we have added a new policy to Opencraft, we can compile the code. To do so, run `mvn package -DskipTests`. (You can also enable the tests, but that will significantly increase the compilation time.) Upon successful compilation, a freshly compiled version of Opencraft should be waiting in the `target` directory.

Repeat the steps in the [previous section](#modify-opencraft-policy) to add a new configuration to your experiment. This time, call the new configuration `policy-new`. In the corresponding `opencraft.yml` configuration file, change the policy to `NewChunkPolicy`.

The new policy is not supported by the Opencraft version we have used in our previous experiments. To use the new version of Opencraft, copy the new Opencraft jar to the new configuration's resources folder:

```
cp ~/opencraft/target/opencraft*.jar /var/scratch/$(whoami)/opencraft-tutorial/opencraft-experiments/2020/first-experiment/policy-new/resources
```

Repeat the steps from the [first section](#run-opencraft-experiment) to repeat the experiment for the new configuration.

## Wrapping Up

You have reached the end of the Opencraft tutorial. At this point, it is worth reminding yourself of what you have learned:

1. You learned to set up a distributed system on a distributed super computer.
2. You learned to run an experiment on a distributed system and observe the results.
3. You learned to use an experiment to observe how configuration changes the behavior of a distributed system.
4. You learned to write code for a distributed system by adding a new policy, and how to compare it against existing policies.

You are now ready to apply these lessons to the systems and experiments that you want to explore.

-

Thank you for completing this tutorial. We would appreciate it if you could share with us any feedback you might have.

- Please share your comments through this anonymous one-page survey: <https://forms.gle/9RpbxTVoJ9EdyrPN6>.
- If you noticed any mistakes in the tutorial, please let us know by creating a new issue here: <https://github.com/atlarge-research/opencraft-tutorial/issues>.

-

## BONUS: Connect to Your Own Opencraft Game

While debugging your Opencraft experiments, it can be useful to see what the game and its emulated players are doing. Because the DAS-5 worker nodes are not accessible from the Internet, we cannot *directly* connect to the Opencraft server with our local Minecraft client.
However, we can work around this by chaining two SSH tunnels.

Start by running Opencraft on a DAS-5 worker node by starting an experiment or by launching the game manually. Next, use `preserve -llist` to identify which machine (e.g., node0XY) is running the Opencraft server.[^4] Now create two SSH tunnels from your local machine to the worker node that is running the Opencraft server, replacing `node0XY` with the correct hostname:

```
ssh -L 25565:localhost:10100 das5 ssh -L 10100:localhost:25565 node0XY
```
*Working out how this command work exactly is left as an exercise for the reader.*

Finally, start your Minecraft 1.12.2 client on your local machine and connect to the server at `localhost:25565`. You should now be connected to the Opencraft server running on the DAS-5.

[^1]: See: <https://news.xbox.com/en-us/2020/05/18/minecraft-connecting-more-players-than-ever-before/>
[^2]: Ibid.
[^3]: van der Sar, et al. Yardstick: A Benchmark for Minecraft-like Services. ICPE 2019
[^4]: When running an Opencraft experiment with `ocd`, the Opencraft server runs on the first node in your list of reserved nodes.
