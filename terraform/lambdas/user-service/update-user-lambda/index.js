import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand, GetCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const sqs = new SQSClient({});

const TABLE_NAME = process.env.USERS_TABLE;
const NOTIFICATION_QUEUE = process.env.NOTIFICATION_QUEUE;

export const handler = async (event) => {
  try {

    const userId = event.pathParameters?.user_id;

    if (!userId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "User_id is required in path"
        })
      };
    }

    const body = JSON.parse(event.body);
    const { address, phone } = body;


    if (!address || !phone) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "address and phone are required"
        })
      };
    }

    const user = await dynamo.send(
      new GetCommand({
        TableName: TABLE_NAME,
        Key: {
          uuid: userId
        }
      })
    )

    if (!user.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: "User not found"
        })
      }
    }

    await dynamo.send(
      new UpdateCommand({
        TableName: TABLE_NAME,
        Key: {
          uuid: userId
        },
        UpdateExpression: "SET address = :address, phone = :phone",
        ExpressionAttributeValues: {
          ":address": address,
          ":phone": phone
        }
      })
    );

    //SQS
    const notificationEvent = {
      type: "USER.UPDATE",
      data: {
        fullName: `${user.Item.name} ${user.Item.lastName}`,
        email: user.Item.email,
        date: new Date().toISOString()
      }
    };

    await sqs.send(
      new SendMessageCommand({
        QueueUrl: NOTIFICATION_QUEUE,
        MessageBody: JSON.stringify(notificationEvent)
      })
    );

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "User updated successfully"
      })
    };

  } catch (error) {

    console.error(error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Internal server error"
      })
    };
  }
};