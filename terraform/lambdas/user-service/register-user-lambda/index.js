import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { v4 as uuidv4 } from "uuid";
import bcrypt from "bcryptjs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const sqs = new SQSClient({});

const USERS_TABLE = process.env.USERS_TABLE;
const QUEUE_URL = process.env.CARD_REQUEST_QUEUE;
const NOTIFICATION_QUEUE = process.env.NOTIFICATION_QUEUE;

export const handler = async (event) => {

    const body = event.body ? JSON.parse(event.body) : event;

    const existingUser = await dynamo.send(
        new ScanCommand({
            TableName: USERS_TABLE,
            FilterExpression: "email = :email",
            ExpressionAttributeValues: {
                ":email": body.email
            }
        })
    );

    if (existingUser.Items && existingUser.Items.length > 0) {
        return {
            statusCode: 400,
            body: JSON.stringify({
                message: "User already exists"
            })
        };
    }

    const id = uuidv4();

    const hashedPassword = await bcrypt.hash(body.password, 10);

    const user = {
        uuid: id,
        name: body.name,
        lastName: body.lastName,
        email: body.email,
        password: hashedPassword,
        document: body.document
    };

    await dynamo.send(new PutCommand({
        TableName: USERS_TABLE,
        Item: user
    }));

    //SQS
    const debitCardRequest = {
        userId: id,
        request: "DEBIT"
    };

    const creditCardRequest = {
        userId: id,
        request: "CREDIT"
    }

    await sqs.send(
        new SendMessageCommand({
            QueueUrl: QUEUE_URL,
            MessageBody: JSON.stringify(debitCardRequest)
        })
    );

    await sqs.send(
        new SendMessageCommand({
            QueueUrl: QUEUE_URL,
            MessageBody: JSON.stringify(creditCardRequest)
        })
    );

    // Notificacion
    const notificationEvent = {
        type: "WELCOME",
        data: {
            fullName: `${body.name} ${body.lastName}`,
            email: body.email
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
            message: "User created",
            userId: id
        })
    };
};