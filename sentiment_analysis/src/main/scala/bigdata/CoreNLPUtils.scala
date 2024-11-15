package bigdata

import java.util.Properties

import edu.stanford.nlp.ling.CoreAnnotations
import edu.stanford.nlp.neural.rnn.RNNCoreAnnotations
import edu.stanford.nlp.pipeline.StanfordCoreNLP
import edu.stanford.nlp.sentiment.SentimentCoreAnnotations

import scala.collection.JavaConverters._
import scala.collection.mutable.ListBuffer

object CoreNLPUtils {

    private val nlpProps = {
        val props = new Properties()
        props.setProperty("annotators", "tokenize, ssplit, parse, sentiment")
        props
    }

    private val pipeline = new StanfordCoreNLP(nlpProps)

    def detectSentiment(message: String): (String, Long) = {
//    def detectSentiment(message: String): String = {

        val t0 = System.nanoTime() / (1000 * 1000)
        val annotation = pipeline.process(message.stripPrefix("\"").stripSuffix("\""))

        var sentiments: ListBuffer[Double] = ListBuffer()
        var sizes: ListBuffer[Int] = ListBuffer()

        var longest = 0

        for (sentence <- annotation.get(classOf[CoreAnnotations.SentencesAnnotation]).asScala) {

            val tree = sentence.get(classOf[SentimentCoreAnnotations.SentimentAnnotatedTree])
            val sentiment = RNNCoreAnnotations.getPredictedClass(tree)
            val partText = sentence.toString

            if (partText.length() > longest) {
                longest = partText.length()
            }

            sentiments += sentiment.toDouble
            sizes += partText.length
        }
        val infTime = (System.nanoTime() / (1000 * 1000)) - t0

        val weightedSentiments = (sentiments, sizes).zipped.map((sentiment, size) => sentiment * size)
        var weightedSentiment = weightedSentiments.sum / (sizes.fold(0)(_ + _))

        if(sentiments.size == 0) {
            weightedSentiment = -1
        }

        /*
         0 -> very negative
         1 -> negative
         2 -> neutral
         3 -> positive
         4 -> very positive
         */
        val sentimentType = weightedSentiment match {
            case s if s <= 0.0 => NOT_UNDERSTOOD
            case s if s < 1.0 => VERY_NEGATIVE
            case s if s < 2.0 => NEGATIVE
            case s if s < 3.0 => NEUTRAL
            case s if s < 4.0 => POSITIVE
            case s if s < 5.0 => VERY_POSITIVE
            case s if s > 5.0 => NOT_UNDERSTOOD
        }

        (sentimentToString(sentimentType), infTime)
    }

    private def sentimentToString(sentiment: SENTIMENT_TYPE): String = {
        sentiment match {
            case NOT_UNDERSTOOD => "NOT_UNDERSTOOD"
            case VERY_NEGATIVE => "VERY_NEGATIVE"
            case NEGATIVE => "NEGATIVE"
            case NEUTRAL => "NEUTRAL"
            case POSITIVE => "POSITIVE"
            case VERY_POSITIVE => "VERY_POSITIVE"
        }
    }

    trait SENTIMENT_TYPE
    case object VERY_NEGATIVE extends SENTIMENT_TYPE
    case object NEGATIVE extends SENTIMENT_TYPE
    case object NEUTRAL extends SENTIMENT_TYPE
    case object POSITIVE extends SENTIMENT_TYPE
    case object VERY_POSITIVE extends SENTIMENT_TYPE
    case object NOT_UNDERSTOOD extends SENTIMENT_TYPE
}