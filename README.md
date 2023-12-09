# Welcome!

Xema is a product developed by a startup @TechSudoku based in India. We serve the Call Center operators with customized call flows. We are happy to see you here and ready to support your evaluation. You can write to us at support@xema.in


### Prerequisites

Xema lives in Ubuntu, the defacto operating system for many. At this point we support Ubuntu 18.


### Installation

> **Warning:** When executed, this script will install various packages in your system and reconfigures the OS for Xema. Please run it in a disposable copy of your OS. You have been warned!


> **Note:** You need to run this install script as **root**

<pre>
wget -q https://raw.githubusercontent.com/xema-in/install/master/xema-manager.sh -O /tmp/xema-manager.sh;chmod 744 /tmp/xema-manager.sh;/tmp/xema-manager.sh;
</pre>



### v2 install scripts


Release channel
<pre>
wget -q https://raw.githubusercontent.com/xema-in/install/master/install-xema.sh -O /tmp/install-xema.sh;chmod 744 /tmp/install-xema.sh;/tmp/install-xema.sh;
</pre>


Dev channel
<pre>
wget -q https://raw.githubusercontent.com/xema-in/install/master/install-xema.sh -O /tmp/install-xema.sh;chmod 744 /tmp/install-xema.sh;/tmp/install-xema.sh -d;
</pre>
