import requests
import os
import boto3
import json
import random
import string
import logging
import time
import sys
from botocore.exceptions import ClientError

# See the following for the Kinesis-related functions
#  https://docs.aws.amazon.com/code-library/latest/ug/python_3_kinesis_code_examples.html

# X API documentations
#  https://developer.x.com/en/docs/x-api

logger = logging.getLogger(__name__)

# To set your environment variables in your terminal run the following line:
# export 'BEARER_TOKEN'='<your_bearer_token>'
bearer_token = os.environ.get("BEARER_TOKEN")

search_url = "https://api.twitter.com/2/tweets/search/recent"
usage_url = "https://api.twitter.com/2/usage/tweets"

# Optional params: start_time,end_time,since_id,until_id,max_results,next_token,
# expansions,tweet.fields,media.fields,poll.fields,place.fields,user.fields
query_params = {'query': "(#onArm OR @Arm OR #Arm OR #GenAI) -is:retweet lang:en",
                'tweet.fields': 'lang'}

aws_profile = "default"
stream_name = 'sentiment-source-stream'

logging.basicConfig(stream=sys.stdout, level=logging.INFO)


def random_partition_key():
    length = 5
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))


class KinesisStream:
    """Encapsulates a Kinesis stream."""

    def __init__(self, kinesis_client, stream_name = None):
        """
        :param kinesis_client: A Boto3 Kinesis client.
        """
        self.kinesis_client = kinesis_client
        self.name = stream_name

    def put_record(self, data, partition_key):
        """
        Puts data into the stream. The data is formatted as JSON before it is passed
        to the stream.

        :param data: The data to put in the stream.
        :param partition_key: The partition key to use for the data.
        :return: Metadata about the record, including its shard ID and sequence number.
        """
        try:
            response = self.kinesis_client.put_record(
                StreamName=self.name, Data=json.dumps(data), PartitionKey=partition_key
            )
            logger.info("Put record in stream %s.", self.name)
        except ClientError:
            logger.exception("Couldn't put record in stream %s.", self.name)
            raise
        else:
            return response


def bearer_oauth(r):
    """
    Method required by bearer token authentication.
    """
    r.headers["Authorization"] = f"Bearer {bearer_token}"
    return r


def connect_to_endpoint(url, params=None):
    response = requests.get(url, auth=bearer_oauth, params=params)
    if response.status_code != 200:
        return None
    return response.json()


def main():
    session = boto3.Session(profile_name=aws_profile)

    # kinesis client initialization
    kinesis_client = session.client('kinesis', region_name='us-east-1')
    kinesis_stream = KinesisStream(kinesis_client, stream_name)

    number_of_tweets = 0
    rounds = 50
    next_token = ""
    while rounds > 0:
        if not next_token == "":
            query_params["next_token"] = next_token
        else:
            query_params.pop("next_token", None)

        json_response = connect_to_endpoint(search_url, query_params)

        if json_response is None:
            break

        if "next_token" in json_response['meta'].keys():
            next_token = json_response['meta']['next_token']
        else:
            next_token = ""
        tweets = json_response["data"]

        for tweet in tweets:
            if tweet["lang"] == "en":
                kinesis_stream.put_record(str(tweet["text"]).strip(), random_partition_key())
                number_of_tweets += 1
            time.sleep(0.2)

        rounds -= 1

    json_response = connect_to_endpoint(usage_url)
    print(json.dumps(json_response, indent=4, sort_keys=True))

    print(number_of_tweets)


if __name__ == "__main__":
    main()
