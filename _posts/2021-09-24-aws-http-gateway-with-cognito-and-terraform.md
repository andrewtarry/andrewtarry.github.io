---
layout: post
title: AWS HTTP Api Gateway with Cognito and Terraform
description: Learn how to deploy an API Gateway with Terraform and Cognito
date: 2021-09-24 16:10:00 +0000
categories: [DevOps, AWS, Terraform, Cognito]
tags: [aws, terraform, cognito]
---

AWS now offer two different types of API Gateway, helpfully called Rest and HTTP. The names are a little confusing since nothing in the Rest gateway forces you to use Rest, and nothing in the HTTP gateway prevents you from using Rest. The HTTP gateway is the newer format, and it is starting to get closer to feature parity with Rest. It is still a little way off, but you can think of the HTTP gateway as Api Gateway v2. 

With that in mind, I wanted to explore using it with Cognito and Terraform.

## Setting up Cognito

First, we will need a Cognito user pool for our users. I am not going to be using Identity Pools in this case, there is no need for them to make the API gateway work, and they are only needed if you want to manage other AWS access using IAM roles.

Here is the Terraform for the user pool:

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = "example_user_pool"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "example_external_api"
  user_pool_id = aws_cognito_user_pool.pool.id
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}
```

In this example, we are creating a basic user pool and a client to interact with it. We are allowing three types of authentication flows, Password, SRP and Refresh. The most basic is password authentication, when we can call the Cognito API with a username, password and client id to get a token. We can also use the SRP flow, so we do not need to send the actual password.

## Setting up the API Gateway

Now that we have Cognito, we can set up the API gateway.


```
resource "aws_apigatewayv2_api" "gateway" {
  name = "example_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "auth" {
  api_id           = aws_apigatewayv2_api.gateway.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://${aws_cognito_user_pool.pool.endpoint}"
  }
}

resource "aws_apigatewayv2_integration" "int" {
  api_id           = aws_apigatewayv2_api.gateway.id
  integration_type = "AWS_PROXY"
  connection_type = "INTERNET"
  integration_method = "POST"
  integration_uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:function:${var.lambda_name}/invocations"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.gateway.id
  route_key = "GET example"
  target = "integrations/${aws_apigatewayv2_integration.int.id}"
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.auth.id
}
```

Here we have created an API gateway and added a method to the API with a signature. As you can see by the resource names, the HTTP gateway is referred to as `apigatewayv2`, which shows how the difference between Rest and HTTP gateways is considered at an API level. 

We have an API with the `HTTP` protocol, the alternative is a WebSocket. The authorizer uses JWT with the Cognito endpoint set as the issuer. The nice thing about this authorizer is that it is not limited to Cognito. It can be used for any authentication service that exposes JWKS, [for more information, see this article](https://auth0.com/docs/security/tokens/json-web-tokens/json-web-key-sets). The audience is essential since it has to include the client id.

There is a lambda that we are using as the backend that looks like this:

```js
exports.handler = async (event) => {
    return {
        statusCode: 200,
        isBase64Encoded: false,
        body: JSON.stringify({ a: 'b' })
    };
};
```

The content of the lambda is not essential, but when we call the API, we expect to get a response of `{"a": "b"}`.

## Calling the API

When we call the API, we will first get an authentication error:


```
curl --request GET 'https://api_gateway_url/example'
```

```js
{
    "message": "Unauthorized"
}
```

As expected, the authentication will fail in this first request. The problem is that we do not include a token, so the request is not valid.

To get a token, we need to create a user. The easiest way to do that is to log into the AWS console, open Cognito and add a user. You might need to set the user password for this test if you have only just created the user pool:

```sh
aws cognito-idp admin-set-user-password \
     --user-pool-id ${userPoolId} \
     --username "${username}" \
     --password "${password}" \
     --permanent
```

With a user created, you can log in:

```sh
curl --location --request POST 'https://cognito-idp.${region}.amazonaws.com' \
--header 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
--header 'Content-Type: application/x-amz-json-1.1' \
--data-raw '{
   "AuthParameters" : {
      "USERNAME" : "xxx",
      "PASSWORD" : "yyy"
   },
   "AuthFlow" : "USER_PASSWORD_AUTH",
   "ClientId" : "zzz"
}'
```


Enter the actual username, password and client id into this request and you should get back an access token. Now we can try our request again:

```
curl --request GET 'https://api_gateway_url/example' --header 'Authorizion: Bearer ${token}'
```

```js
{
    "a": "b"
}
```

The API gateway will have validated the token and granted access.

## Conclusion

The HTTP API Gateway feels like a nice improvement on the Rest gateway. The integration with Cognito is logical and straightforward, resulting in a production-ready, secure API Gateway in only a few lines of Terraform. The added flexibility to use other authentication services means we should need fewer lambda authenticators and rely on a tried and tested approach from AWS.
