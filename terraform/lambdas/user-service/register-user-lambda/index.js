import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from "uuid";
import bcrypt from "bcryptjs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {

    const body = JSON.parse(event.body);

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
        TableName: "user-table",
        Item: user
    }));

    return {
        statusCode: 200,
        body: JSON.stringify({
            message: "User created",
            userId: id
        })
    };
};