import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const s3 = new S3Client({});
const dynamo = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const BUCKET = process.env.AVATAR_BUCKET;
const TABLE = process.env.USERS_TABLE;

export const handler = async (event) => {

  const body = event.body ? JSON.parse(event.body) : {}

  const userId = event.pathParameters?.user_id;

  if (!userId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "user_id is required"})
    }
  }

  if (!body.image) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "image is required" })
    }
  }

  const imageBase64 = body.image;

  const buffer = Buffer.from(imageBase64, "base64");

  const key = `avatars/${userId}.jpg`;

  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    Body: buffer,
    ContentType: "image/jpeg"
  }));

  const avatarUrl = `https://${BUCKET}.s3.amazonaws.com/${key}`;

  await dynamo.send(new UpdateCommand({
    TableName: TABLE,
    Key: { uuid: userId },
    UpdateExpression: "SET avatar = :avatar",
    ExpressionAttributeValues: {
      ":avatar": avatarUrl
    }
  }));

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Avatar uploaded",
      avatarUrl
    })
  };
};