# Sigmoid
Sigmoid files


Pipeline Job will contain:
	a. Parameterized build:
		i. ENVIRON which will contain option to selct from "Dev", "QA" and "Prod"
		ii. RESULTS_LOCATION to store the results on server
	b. Will execute below command:
		node('master') {
			load 'Execute.sh'
		}

Execute script is the main script which will be called by pipeline job and performs the following:
	1. Clone wordpress repository
	2. Create spot isntance for Dev, QA and Prod front end.
	3. Spot instance is used for spot instance fleet
	4. ELB used for load distribution
	5. Auto-scaling setup for Production env
	6. Monitor is done and placed on RESULTS_LOCATION folder.
	