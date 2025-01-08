import requests
import os
import boto3
import json
from datetime import datetime
import calendar
import random
import string
import logging
import time
import sys
import time
import csv
import os
from botocore.exceptions import ClientError
from random import randrange

logger = logging.getLogger(__name__)

aws_profile = "default"
stream_name = 'sentiment-source-stream'

logging.basicConfig(stream=sys.stdout, level=logging.INFO)


def randomPartitionKey():
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


def main():
    session = boto3.Session(profile_name=aws_profile)

    kinesis_client = session.client('kinesis', region_name='us-east-1')
    kinesis_stream = KinesisStream(kinesis_client, stream_name)

    tweets = []
    tweets_to_send = 100

    with open("tweets.csv", 'r') as f:
        lines = f.readlines()
        for l in lines:
            tweets.append(l)

    while True:
        for _ in range(tweets_to_send):
           twt = tweets[randrange(len(tweets))]
           twt = twt.encode("ascii", "ignore").decode()
           kinesis_stream.put_record(twt, randomPartitionKey())
           time.sleep(0.2)


if __name__ == "__main__":
    main()