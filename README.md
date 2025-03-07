# Fuse take home

The goal of this take home is to create a `production ready product` to improve the Fuse team performance on a certain group of task using cool stuck like LLMs / Agents / integrations.

This is the repository of the React application: [React App] (https://github.com/FuseFinance/react-ai-agent) where it has the code to render the table from the json file. You need to create an AI Agent which will be able to add/update ( never delete ) information to that json file from a [Linear task] (https://linear.app).

The steps to follow are:

1. Listen task with an specific labels / projects ( up to you ) in [Linear](https://linear.app)
2. Triggers an agent that should be able to :

- Check if it's able to do the task ( avoid task that are not in the scope)
- If it's able to do and need more information, ask about this
- If it's able to do and have the right context do the task and create a PR review in a github repository
- if it's not able to do the task, reply in the a comment that it is not able to help and the reason

3. In the success path, it should be able to add a comment with the PR review / change the status of the task

### Important notes

- Fork the React App in your github account to be able to use it programmatically

## Deliverables

- `Production application working`, so, we want to have a real demo, like having an user in Linear / Github to see how it works. You can add a loom too.
- The backend and the infrastructure code, ideally `Terraform` or `CDK` with `AWS`
- In the project, a `Readme.md` explaining the decistion that you take
- The source code of the service in private repository, add the user @skaznowiecki / @sebastian-alvarez-fuse-finance / @danielruizr / @felipe-machado as a collaborator

## Evaluation

- The application working as expect ( live ).
- The infrastructure as code
- The architecture decistions

- - We're not going to pay too much attention to the architecture of the backend service ( like DDD or Hexagonal architecture ) , the most important things are the 3 items mentioned before.
