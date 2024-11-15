package bigdata

// AWS imports
import org.apache.spark.sql.expressions.UserDefinedFunction
import org.apache.spark.sql.functions._

// Log imports
import org.apache.log4j._
import org.apache.spark.sql.SparkSession

object SentimentAnalysis {

  // Kinesis streams parameters
  private val inputKinesisStream = "sentiment-source-stream"
  private val kinesisRegion = "us-east-1"

  def main(array: Array[String]) {

    // Set the log level to only print errors
    Logger.getLogger("org").setLevel(Level.ERROR)

    val esNodes = System.getProperty("ES_NODES")
    val checkpointLocation = System.getProperty("CHECKPOINT_LOCATION")

    val spark = SparkSession
       .builder
       .appName("SentimentAnalysis")
       .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")

    val inputStream = spark
      .readStream
      .format("kinesis")
      .option("region", kinesisRegion)
      .option("streamName", inputKinesisStream)
      .option("endpointUrl", "https://kinesis.us-east-1.amazonaws.com")
      .option("startingposition", "LATEST")
      .option("kinesis.executor.maxRecordPerRead", 10)
      .option("awsUseInstanceProfile", "true")
      .option("awsUseInstanceProfile", "false")
      .load()

    // transform sentiments into string
    import bigdata.CoreNLPUtils._

    val tweetSentiment: UserDefinedFunction = udf((tweet: String) => detectSentiment(tweet))
    // tweets are in binary format. Convert them into string before sending to the output connector
    val toString = udf((payload: Array[Byte]) => new String(payload))
    val sentiments = inputStream
      .withColumn("sentiment", tweetSentiment(col("data")))
      .withColumn("data", toString(col("data")))
      // sentiment column is (sentiment, inference time)
      .select("data", "sentiment", "approximateArrivalTimestamp")

    val out = sentiments
      .writeStream
      .format("es")
      .option("es.nodes", esNodes)
      .option("es.port", "9200")
      .option("es.nodes.discovery", false)
      .option("es.nodes.wan.only", "true")    // true when the elastic server is running outside cluster
      .option("checkpointLocation", checkpointLocation)
      .option("es.index.auto.create", "true") // create the index on your own
      .start("sentiments")              /* index name - raised error when using spark/people
                                                 (Detected type name in resource [spark/people]. Remove type name to continue)
                                               */
      .awaitTermination()
  }
}
