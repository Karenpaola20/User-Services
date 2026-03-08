import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const sqs = new SQSClient({});

const USERS_TABLE = process.env.USERS_TABLE;
const JWT_SECRET = process.env.JWT_SECRET;
const NOTIFICATION_QUEUE = process.env.NOTIFICATION_QUEUE;

export const handler = async (event) => {

  try {

    const body = event.body ? JSON.parse(event.body) : event;

    const { email, password } = body;

    if (!email || !password) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Email and password required"
        })
      };
    }

    // Buscar usuario por email
    const result = await dynamo.send(
      new ScanCommand({
        TableName: USERS_TABLE,
        FilterExpression: "email = :email",
        ExpressionAttributeValues: {
          ":email": email
        }
      })
    );

    if (!result.Items || result.Items.length === 0) {
      return {
        statusCode: 401,
        body: JSON.stringify({
          message: "Invalid credentials"
        })
      };
    }

    const user = result.Items[0];

    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return {
        statusCode: 401,
        body: JSON.stringify({
          message: "Invalid credentials"
        })
      };
    }

    // Crear JWT
    const token = jwt.sign(
      {
        userId: user.uuid,
        email: user.email
      },
      JWT_SECRET,
      { expiresIn: "1h" }
    );

    const notificationEvent = {
      type: "USER.LOGIN",
      fullName: `${user.name} ${user.lastName}`,
      data: {
        date: new Date().toISOString(),
        email: user.email
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
        token,
        userId: user.uuid
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