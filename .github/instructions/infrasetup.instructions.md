---
applyTo: '**'
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.
# Infrastructure Setup Instructions
This document outlines the steps required to set up the infrastructure for the project. It is essential to follow these instructions carefully to ensure a smooth deployment and operation of the application.



1. This application will primarily be used to setup the azure infrastructure for a typical web application (Angular) with REST APIs connecting to a Postgresql database. All the binaries are supposed to be deployed to appropriate azure infrastructure components.
2. The main objective is to setup infrastructure in the three environments IT, QA and Prod.
3. For the IT environment, we will use free tier as much as possible. If free tier is not available for a certanin resource, we will use the lowest available paid resource from Azure for that IT environment.
4. we should be able to clearly identify which environment we are building.
5. Setup a budget alarm setup as soon as the environment is built to identify whenever the overall 'estimated cost of the resources for that environment exceed more than $10'.  That alert should go to prashantmdesai@yahoo.com, prashantmdesai@hotmail.com as an email and +1 224 656 4855 as a text message.
6. Setup a actual alarm setup as soon as the environment is built to identify whenever the overall 'actual cost of the resources for that environment exceed more than $10'.  That alert should go to prashantmdesai@yahoo.com, prashantmdesai@hotmail.com as an email and +1 224 656 4855 as a text message.
7. We should be able to clearly identify which environment we are building even while giving any commands on the terminal or on azure CLI.
8. For QA environment, there should be a budget alarm setup as soon as the environment is built to identify whenever the overall 'estimated cost of the resources for that environment exceed more than $20'.  That alert should go to prashantmdesai@yahoo.com, prashantmdesai@hotmail.com as an email and +1 224 656 4855 as a text message.
9. For QA environment, there shuld  a actual alarm setup as soon as the environment is built to identify whenever the overall 'actual cost of the resources for that environment exceed more than $20'.  That alert should go to prashantmdesai@yahoo.com, prashantmdesai@hotmail.com as an email and +1 224 656 4855 as a text message.
10. For Prod environment, there shuld be a budget alarm setup as soon as the environment is built to identify whenever the overall 'estimated cost of the resources for that environment exceed more than $30'.  That alert should go to prashantmdesai@yahoo.com, prashantmdesai@hotmail.com as an email and +1 224 656 4855 as a text message.
11. For Prod environment, there should a actual alarm setup as soon as the environment is built to identify whenever the overall 'actual cost of the resources for that environment exceed more than $30'.  That alert should go to prashantmdesai@yahoo.com, prashantmdesai@hotmail.com as an email and +1 224 656 4855 as a text message.
12. For all environments, if none of the environment resources are used for more than an hour, entire environment including all the resources should be shut down, and the resources released such that they do not cost us. Next time we need the environment, we should be able to rerun the 'environment build out' again to rebuild those resources.
13. In the IT environment, we will not be using any 'Managed' offerings from Azure for the IT environment. FOr respective resources, if free tier is available, we will use that OR we will use the least paid class of that resource.
14. In the QA and Prod environments, Security is of paramount importance, so, we should use apppropriate security offerings from Azure for QA and Prod environments.
15. In the QA and Prod environments, Performance and scalability is very important, so, we should use appropriate offerings from Azure for the Prod environment. The user facing (front-end, and API) components should have auto-scaling (up and down) configured.
16. Every environment should have a ready 'shutdown' script which will shut down all resources in that environment, release those resources completely, such that the cost of that environment goes down to zero. That script should be possible to be executed using terminal in vscode or azure cli. That script should encompass all the azure resources created for that environment.
17. Every environment should have a ready 'startup' script which will start all our required resources in that environment. That script should be possible to be executed using terminal in vscode or azure cli. That script should encompass all the azure resources required for that particular environment.
18. Every time the overall configuration of the environment changes due to addition or removal of a resource related scripts, the startup and shutdown scripts of that environment must be modified to cover for that change.
19. In all environments, we will be using azure key vault to store all the secrets
20. QA environment database size, file storage size does not need to be as big as production. It should be slightly larger than the IT environment and not more than 20% of the production environment.
21. Prod environment shutdown scripts should have special prompting and "triple confirmation mechanism" to let the person executing the script to choose whether they really want to shutdown "production".
22. In all environments, the REST APIs should be exposed via the Azure API Gateway.
23. Every time any environment is started or shutdown, the user should be prompted with anticipated cost that this environment will cost per hour of usage and the user should be explicitly made to say 'Yes' to that cost and only then the script should proceed.
24. In each environment, deploy a 'linux virtual machine' for the use of a developer who can login to that machine and be able to access any azure resources that belong to that environment.
24a. Using that virtual machine, the developer should be able to access any of the Azure resources present in that environment. It should have all the requisite software (Azure CLI, Github CLI, Git etc.) installed on it ready for use by the developer.
24b. Once the environment setup is complete, the respective setup or startup script shoudl display (on the terminal or console) the IP address and machine name of this 'linux virtual machine' so that the developer does not have to search for that elsewhere.
25. all web traffic should always be over HTTPS
26. Modify relevant infrastructure setup code and scripts such that all web traffic should always be over HTTPS
27. Make sure there is elaborate documentation throughout the code explaining what the code is doing and why
28. Use Azure Bicep for all infrastructure as code related activities