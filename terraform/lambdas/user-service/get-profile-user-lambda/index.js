import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const TABLE_NAME = "user-table";

export const handler = async (event) => {
    try {
        const userId = event.pathParameters?.user_id;

        if (!userId) {
            return {
                statusCode: 400,
                body: JSON.stringify({
                    message: "User id is required"
                })
            };
        }

        const result = await dynamo.send(
            new GetCommand({
                TableName: TABLE_NAME,
                Key: {
                    uuid: userId
                }
            })
        );

        if (!result.Item) {
            return {
                statusCode: 404,
                body: JSON.stringify({
                    message: "User not found"
                })
            };
        }

        return {
            statusCode: 200,
            body: JSON.stringify(result.Item)
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
}