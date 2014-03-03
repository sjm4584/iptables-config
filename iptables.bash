#!/bin/bash

#make it easy to configure iptables, allow/deny services/ports/ranges etc
##############################################################################
#1. display firewall status		# -status
#2. start/stop/restart firewall		# -start/-stop/-restart
#3. delete input rules			# -del input \n <rule number>
#4. delete output rules			# -del output \n <rule number>
#5. flush rules				# -flush
#6. insert block input rule		# -insert $num block input(do)
#7. insert block output rule		# -insert $num block output(do) 
#7. save rules				# -save
#8. drop all traffic			# -drop all
#9. block specific IP input		# -block input from <ip addr>
#10 view INPUT rules			# -view input
#11 view OUTPUT rules			# -view output
#12 block all input IPs to a port	# -block P input from all
#13 block input from IP to a port	# -block P input from <ip addr>
#14 block output IPs to a port		# -block P output from all
#15 block input port ranges from all	# -block P range(#-#) input all(do)
###############################################################################


user_input=""
substr=""

insertBlockInput() {
  echo "Inserting block at position $1 from IP $2"
  iptables -I INPUT $1 -s $2 -j DROP
}

blockOutputAllPort() {
  echo "Blocking $1 from coming in"
  iptables -A OUTPUT -p tcp --dport $1 -j DROP
}

blockInputPort() {
  echo "Blocking port $1 from $2"
  #blocks a specific IP addr ($2) from accessing port $1
  #iptables -I INPUT -s $2 -j DROP
  iptables -A INPUT -p tcp -s $2 --dport $1 -j DROP
}

blockInputAllPort() {
  echo "None one will be able to access port $1 anymore"
  iptables -A INPUT -p tcp --destination-port $1 -j DROP
}

#--------------block specific IP addr coming into the machine----
blockInputIP() {
  echo "Blocking $1 from coming in"
  iptables -A INPUT -s "$1" -j DROP
}

delInputRule() {
  echo "Deleteing input rule: $1"
  iptables -D INPUT $1
}

delOutputRule() {
  echo "Deleteing output rule :$1"
  iptables -D OUTPUT $1
}

viewInputRules() {
  iptables -L INPUT -n --line-numbers
}

viewOutputRules() {
  iptables -L OUTPUT -n --line-numbers
}


#Makes users confirm that they really want to flush
flushRecords() {
  echo "Are you sure you want to flush? It will delete
all rules from your firewall! (Y\N)"
  read -a user_input
  
  #toUpper() basically
  user_input=$(echo $user_input | tr '[a-z]' '[A-Z]')
  if [[ $user_input = "Y" ]]; then
    echo "Flushing..."
    iptables -F
  fi

  if [[ $user_input = "N" ]]; then echo "Cancelling Flush!"; fi
}


checkStatus() {
  echo "Checking status..."
  iptables -L -n -v --line-numbers
}


dropAll() {
  echo "Dropping all connections, goodbye world!"
  iptables -P INPUT DROP
  iptables -P OUTPUT DROP
  iptables -P FORWARD DROP
}

#=================================================================================

while true; do
echo "Enter command: "
#takes user input and stores it in a var
read user_input

if [[ ${user_input:0:7} = "-insert" ]]; then
  echo "hello"
  checkStatus #display all the current rules
  
fi

#flush all rules to start from fresh
if [[ $user_input = "-flush" ]]; then flushRecords; fi

#dispaly the status of the firewall
if [[ $user_input = "-status" ]]; then checkStatus; fi

#saves the records (this doesn't have a function)
if [[ $user_input = "-save" ]]; then 
  service iptables save
fi

#block specific input IP addr
if [[ ${user_input:0:17} = "-block input from" ]]; then 
  #Gets the ip addr from the user input and passes it to $substr
  substr=${user_input:18}
 
  #passes the IP addr to our blockIP() function
  blockInputIP $substr 
fi

#read port number after the statement, fix this later I guess
if [[ $user_input = "-block P from input all" ]]; then
  echo "Port Number: "; read user_input
  blockInputAllPort $user_input
fi

#block port from everyone output
if [[ $user_input = "-block P from output all" ]]; then
  echo "Port Number: "; read user_input
  blockOutputAllPort $user_input
fi

if [[ ${user_input:0:13} = "-block P from" ]]; then
  substr=${user_input:14}
  echo "Port Number: "; read user_input
  #passes port then IP addr
  blockInputPort $user_input $substr
fi

#block input to a port from a specific IP
if [[ ${user_input:0:9} = "-block P " && ${user_input:14:25} = "input from " ]]; then
  substrp=${user_input:10:13}
  substr=${user_input:15}
  #sends port and the IP addr to the blockInputPort function
  blockInputPort $substrp $substr
fi

#drop all traffic
if [[ $user_input = "-drop all" ]]; then dropAll; fi

#view all input rules
if [[ $user_input = "-view input" ]]; then viewInputRules; fi

#view all output rules
if [[ $user_input = "-view output" ]]; then viewOutputRules; fi

#delete input rules
if [[ $user_input = "-del input" ]]; then
  echo "Here are the input rules:"
  viewInputRules
  echo "What rule would you like to delete? "
  read user_input
  delInputRule $user_input 
fi


#delete output rules
if [[ $user_input = "-del output" ]]; then
  echo "Here are the output rules:"
  viewOutputRules
  echo "What rule would you like to delete? "
  read user_input; delOutputRule $user_input
fi



done #end of while loop
