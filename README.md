# Venteur Coding Assignment

Here's the code for finding the shortest path a knight can take to get from one square on a chess board to another.

To test it out, send a `POST` request to `https://geiepswe56.execute-api.us-east-2.amazonaws.com/knightpath`. The request should include `source` and `target` query params, which should be valid squares on a chess board in the format "F7", "A2", etc. (Note for fellow chess nerds - it uses algebraic notation rather than descriptive notation, as all god-fearing chess players should.)
The endpoint will return a string with an `operationId`. To see the results, send another `POST` request to `https://lpqc5x7jb0.execute-api.us-east-2.amazonaws.com/knightspath_result` with an `operationId` query param. That will return a message with the request status (either "RECEIVED", "IN PROGRESS", or "COMPLETE") and, if the request's processing is finished, a description of the shortest path; that return object will look like
```
{
    "status": "COMPLETE", 
    "starting": "F3", 
    "ending": "C7", 
    "shortestPath": "F3:G5:E6:C7", 
    "numberOfMoves": 3, 
    "operationId": 
    "c5acee0f-e876-4904-9f18-5b3331e6b651"
}
```

## Architecture

The functionality is provided primarily by three Dockerized lambda functions, a postgres database, and an SQS queue. (There are additional support resources you can see in the `infra` folder, they're all defined with Terraform.)

The database has two tables, `request` and `path`. The `request` table maintains the status of requests, as well as a `path_id` that links to a row in the `path` table. The `path` table describes paths that have already been solved.

The `receive_request_lambda` function receives a request at the `/knightspath` endpoint. It then enters the request into the `request` table and emits an SQS queue event, which triggers the `process_request_lambda` function. 

That lambda is doing the lion's share of the work. It first checks the `path` table to see if that path has already been solved, and updates the `request` table if it has. If not, it solves the knight's path problem for that combination of starting and ending squares using a modification of Dijkstra's algorithm, treating the knight's move options as vertices in a graph. When it's solved the path, it inserts a line into the `path` table with the solution, and updates the `request` table to point to that path.

The `retrieve_result_lambda` receives requests at the `knightspath_result` endpoint. It looks up the request ID in the `request` table and returns the request's status, along with the path and number of moves if the request has been completed.

There's a fourth lambda function called `provision_db_lambda`, but that's just to do initial DB setup when the Terraform code is first run. It runs automatically.

## Installation

You'll need Terraform and Docker installed to build and deploy the repo. I won't walk you through those steps, there's good documentation for both; I will just suggest that you install Terraform with a version manager like asdf.

You'll also need an AWS account, and an IAM user with CLI permissions that can deploy resources. Change the occurrences of <AWS ACCOUNT NUMBER> to your account number in the deploy scripts, and then set up `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` to the values for your IAM user.

To deploy the infra resources, navigate into the `infra` directory and run 
```
terraform init
terraform plan
```
If everything looks kosher, run 
```
terraform apply
```
It will prompt for a password for the postgres DB. In a live DB, there would obviously be a little more security to this step; for now, you're coming up with a password that will be stored in AWS Secrets Manager. Terraform will output your endpoints.

Once everything is deployed, you can update the function code as you like and run the deploy scripts in each function's folder to deploy updated code to that function.

There's a quirk to Terraform that takes slightly more orchestration to work around, and it would've gone out of scope for this project: Terraform Lambda resources assume the source code already exists wherever you've pointed the `image_uri` field to, but you can't deploy images until you deploy the ECR repositories to put them in. (There are other ways around this, but I wanted to Dockerize these functions and have them live in ECR.) To get around this, comment out all of the Terraform resources that refer to the Lambda functions (including the API Gateway code), then run `terraform apply`. This will deploy the ECR repos and the other resources you'll need. Then run the function deploy scripts. Then come back to the infra folder, uncomment everything, and run `terraform apply` again. No, I don't love this either.

## TO-DOs

There are a few things I'd like to improve on given more time.

* I wrote the deploy scripts to make it easier to iterate through the functions, so I could make a change and just run `./deploy.sh` to immediately get the new code running in the serverless function. As I was writing those (and the Dockerfiles), I realized each was basically the same other than the function name, and when I caught a bug I was fixing it in four places. With more time I'd like to take those and the Dockerfiles and parameterize them so I could reuse single files and wasn't repeating code all over the place.
* Speaking of that Terraform quirk - as I was building this out, I kept fighting the temptation to just build a more robust CI/CD pipeline. It would've taken more time to get right, but it would've been nice to automate some of the development process so I could deploy resources and function code more easily, including deploying the Terraform in different stages.
* (And it'd also be easier if I organized the TF into modules.)
* I was also tempted to try to optimize the algorithm a little further by looking to see when one of the next squares was the start of a path that had already been solved. For example, if you're going from F3 to C7, and you get to G5 and realize there's already an entry in the DB for G5-C7, it'd be nice to include that result in the algorithm, and stop looking for any new paths that starts at G5.
For this to be practical, though, you'd want a much faster DB focused on just this functionality - maybe a Redis cache or something. This is for two reasons: First, you can't just concatenate your path so far with the path you've already mapped out - it's possible that one of the other squares bordering F3 is only one jump away from C7, so exiting early and returning F3::<existing path from G5 to C7> might not be correct. Second, if you wanted to get around that, you'd have to store the length of the G5-C7 path and all the squares it traversed so that you would know if some other path was leading you the same way and could be aborted. If you don't do both, you're either going to return the wrong result or lose any optimization value. And that seemed like a much larger problem - especially when the existing algorithm is returning results pretty quickly as is!