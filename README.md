# Opencraft Tutorial

Minecraft is one of the best-selling games of all time.
It has sold more than 200 million copies,<sup id="a1">[1](#fn1)</sup> and has more than 126 million active monthly players.<sup id="a2">[2](#fn2)</sup>
In contrast to traditional games, Minecraft gives players fine-grained control over the environment.
Players can be creative and alter the environment to their liking.
Players can decide to create buildings, mines, farms, logical circuits, and other constructions.
Minecraft's success has led to the creation of hundreds of similar games, which we collectively refer to as _Minecraft-like games_.

Despite the popularity of these games, their scalability is limited.
The original Minecraft and popular spin-offs can only support between 200-300 players under favorable conditions.<sup id="a3">[3](#fn3)</sup>
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

> PRO TIP: If you connect to the DAS-5 regularly, it is worth switching to public-key authentication using `ssh-keygen` and `ssh-copy-id`. This is left as an exercise for the reader. Unfortunately, ssh.data.vu.nl does not accept public-key authentication, but DAS-5 does.

> PRO TIP: You do not need the `ProxyJump` command while working from the VU campus network.

## Collecting Your Tools

Opencraft consists of a collection of tools. The setup consists of two steps: creating a Python environment with the necessary packages, and downloading the Opencraft-specific tools. From this point onwards, all commands should be executed on the DAS-5, unless otherwise specified.

### Python

Use Miniconda to create a Python environment with the necessary packages.
Miniconda simplifies the process of creating portable Python environments with specfic Python runtime and package versions.

Download the Miniconda installer for Linux:

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```
Run the installer. It will ask where Miniconda should be installed. **Make sure to install Miniconda in `/var/scratch/<USERNAME>/miniconda3`**;
the home folder does not have sufficient space for large python environments. Answer "yes" when asked if the installer should run `conda init`.

Now create a new Python environment that contains the exact Python runtime and package versions needed to run the Opencraft tools.

```
source ~/.bashrc
wget https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/conda/spec-file.txt
conda create --name opencraft --file spec-file.txt
echo "conda activate opencraft" >> ~/.bashrc
source ~/.bashrc
rm spec-file.txt
rm Miniconda3-latest-Linux-x86_64.sh
```
You should now see `(opencraft)` prepended to your terminal prompt. You can also verify the correct Python runtime is used by running `which python`.

### Opencraft Tools

To dowload and configure the Opencraft tools, run the following command:

```
curl -sSL https://raw.githubusercontent.com/atlarge-research/opencraft-tutorial/main/scripts/setup-opencraft.sh | bash
source ~/.bashrc # load the prun module
```

> PRO TIP: Never execute code straight from the Internet. :)

# Exercises

This tutorial consists of two exercises. In both exercises, you evaluate novel game-scalability methods by running experiments with Opencraft on the DAS5. In the first exercise, you evaluate how Dyconits improve the network bandwidth usage of the game. In the second experiment, you evaluate the performance of using serverless technology for on-demand terrain (i.e., content) generation.

You can access the exercises here:

- [Dyconit Exercise](./exercises/dyconits/README.md)
- [Terrain Generation Exercise](./exercises/terrain-generation/README.md)


## BONUS: Connect to Your Own Opencraft Game

While debugging your Opencraft experiments, it can be useful to see what the game and its emulated players are doing. Because the DAS-5 worker nodes are not accessible from the Internet, you cannot *directly* connect to the Opencraft server with our local Minecraft client.
However, you can work around this by chaining two SSH tunnels.

Start by running Opencraft on a DAS-5 worker node by starting an experiment or by launching the game manually. Next, use `preserve -llist` to identify which machine (e.g., node0XY) is running the Opencraft server.<sup id="a4">[4](#fn4)</sup> Now create two SSH tunnels from your local machine to the worker node that is running the Opencraft server, replacing `node0XY` with the correct hostname:

```
ssh -L 25565:node0XY:25565 das5
```
*Working out how this command works exactly is left as an exercise for the reader.*

Finally, start your Minecraft 1.12.2 client on your local machine and connect to the server at `localhost:25565`. You should now be connected to the Opencraft server running on the DAS-5.

## Wrapping Up

You have reached the end of the Opencraft tutorial. At this point, it is worth reminding yourself of what you have learned:

1. You learned to set up a distributed system on a distributed super computer.
2. You learned to run an experiment on a distributed system and observe the results.
3. You learned to use an experiment to observe how configuration changes the behavior of a distributed system.
4. You learned to write code for a distributed system by adding a new policy, and how to compare it against existing policies.

You are now ready to apply these lessons to the systems and experiments that you want to explore.

---

Thank you for completing this tutorial. We would appreciate it if you could share with us any feedback you might have.

- Please share your comments through this anonymous one-page survey: <https://forms.gle/9RpbxTVoJ9EdyrPN6>.
- If you noticed any mistakes in the tutorial, please let us know by creating a new issue here: <https://github.com/atlarge-research/opencraft-tutorial/issues>.

---

<a name="fn1">1.</a> <https://news.xbox.com/en-us/2020/05/18/minecraft-connecting-more-players-than-ever-before/> [↩](#a1)

<a name="fn2">2.</a> Ibid. [↩](#a2)

<a name="fn3">3.</a> van der Sar, et al. Yardstick: A Benchmark for Minecraft-like Services. ICPE 2019 [↩](#a3)

<a name="fn4">4.</a> When running an Opencraft experiment with `ocd`, the Opencraft server runs on the first node in your list of reserved nodes. [↩](#a4)
