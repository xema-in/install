# Welcome!

Xema is a product developed by a startup @TechSudoku based in India. We serve the Call Center operators with customized call flows. We are happy to see you here and ready to support your evaluation. You can write to us at support@xema.in


### Prerequisites

Xema runs on Ubuntu, the operating system choice of cloud.


### Installation

> **Warning:** When executed, this script will install various packages in your system and reconfigures the OS for Xema. Please run it in a disposable copy of your OS. You have been warned!


> **Note:** You need to run this install script as **root**

#### Version 1

Supports Ubuntu 18

<pre>
wget -q https://raw.githubusercontent.com/xema-in/install/master/xema-manager.sh -O /tmp/xema-manager.sh;chmod 744 /tmp/xema-manager.sh;/tmp/xema-manager.sh;
</pre>



#### Version 2

Supports Ubuntu 24, 22

<pre>
wget -q https://raw.githubusercontent.com/xema-in/install/master/install-xema.sh -O /tmp/install-xema.sh;chmod 744 /tmp/install-xema.sh;/tmp/install-xema.sh;
</pre>


#### Dev Branch

<pre>
wget -N https://raw.githubusercontent.com/xema-in/install/master/install-xema.sh -O /tmp/install-xema.sh;chmod 744 /tmp/install-xema.sh;/tmp/install-xema.sh -d;
</pre>
