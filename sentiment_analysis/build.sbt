name := "bigdata"

version := "0.1"

scalaVersion := "2.13.15"

// elasticsearch-spark-30_8.15.3 works with Spark version 3.4.3

libraryDependencies ++= Seq(
    "org.apache.spark" %% "spark-core" % "3.4.3" % "provided",
    "org.apache.spark" %% "spark-sql" % "3.4.3" % "provided",
    "org.apache.spark" %% "spark-mllib" % "3.4.3" % "provided",
    "org.apache.spark" %% "spark-streaming" % "3.4.3" % "provided",
    "com.roncemer.spark" %% "spark-sql-kinesis" % "1.2.3_spark-3.2" % "provided",
    "edu.stanford.nlp" % "stanford-corenlp" % "4.5.7",
    "edu.stanford.nlp" % "stanford-corenlp" % "4.5.7" classifier "models",
//    "org.apache.hadoop" % "hadoop-common" % "3.3.4" % "provided",
    "org.apache.hadoop" % "hadoop-aws" % "3.3.4",
    "org.apache.commons" % "commons-lang3" % "3.12.0",
    "org.elasticsearch" %% "elasticsearch-spark-30" % "8.15.3",
)

/*
   The following (general) merger doesn't work. For instance, spark-sql-kinesis will not be placed in the final
   JAR file since it includes duplicate protobuf classes, and looks like spark-sql-kinesis is the JAR file that
   will be affected:

   -----------------------------------------------------------------------------------------------------------
   Deduplicate found different file contents in the following:
    Jar name = protobuf-java-3.19.6.jar, jar org = com.google.protobuf, entry target = google/protobuf/api.proto
    Jar name = spark-sql-kinesis_2.13-1.2.3_spark-3.2.jar, jar org = com.roncemer.spark, entry target = google/protobuf/api.proto
    Jar name = spark-core_2.13-3.5.3.jar, jar org = org.apache.spark, entry target = google/protobuf/api.proto
   -----------------------------------------------------------------------------------------------------------

   so, the following command returns nothing:

   jar tf target/scala-2.13/bigdata-assembly-0.1.jar | grep spark-sql-kinesis

   and spark-submit complaints that it can't find kinesis source:

   [DATA_SOURCE_NOT_FOUND] Failed to find the data source: kinesis

   until fixed, the JAR file out/artifacts/ is used and JAR dependencies are copied into jars/ in spark folder.
 */

assembly / assemblyMergeStrategy := {
  case PathList("google", "protobuf", xs @ _*) => MergeStrategy.last
  case PathList("module-info.class") => MergeStrategy.last
  case PathList(".gitkeep") => MergeStrategy.last
  case x =>
    val oldStrategy = (assembly / assemblyMergeStrategy).value
    oldStrategy(x)
}