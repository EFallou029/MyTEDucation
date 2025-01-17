###### TEDx-Load-Aggregate-Model
######

import sys
import json
import pyspark
from pyspark.sql.functions import col, collect_list, array_join, struct

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job




##### FROM FILES
tedx_dataset_path = "s3://myteducation-data/final_list.csv"

###### READ PARAMETERS
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

##### START JOB CONTEXT AND JOB
sc = SparkContext()


glueContext = GlueContext(sc)
spark = glueContext.spark_session


    
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


#### READ INPUT FILES TO CREATE AN INPUT DATASET
tedx_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(tedx_dataset_path)
    
tedx_dataset.printSchema()


#### FILTER ITEMS WITH NULL POSTING KEY
count_items = tedx_dataset.count()
count_items_null = tedx_dataset.filter("id is not null").count()

print(f"Number of items from RAW DATA {count_items}")
print(f"Number of items from RAW DATA with NOT NULL KEY {count_items_null}")

## READ THE DETAILS
details_dataset_path = "s3://myteducation-data/details.csv"
details_dataset = spark.read \
    .option("header","true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(details_dataset_path)

details_dataset = details_dataset.select(col("id").alias("id_ref"),
                                         col("interalId").alias("internalId"),
                                         col("description"),
                                         col("duration"),
                                         col("publishedAt"))

# AND JOIN WITH THE MAIN TABLE
tedx_dataset_main = tedx_dataset.join(details_dataset, tedx_dataset.id == details_dataset.id_ref, "left") \
    .drop("id_ref")

tedx_dataset_main.printSchema()

## READ IMAGES DATASET
images_dataset_path = "s3://myteducation-data/images.csv"
images_dataset = spark.read.option("header","true").csv(images_dataset_path)
images_dataset = images_dataset.select(col("id").alias("id_ref"),
                                       col("url").alias("image_url"))

# JOIN WITH THE MAIN TABLE

tedx_dataset_main = tedx_dataset_main.join(images_dataset, tedx_dataset_main.id == images_dataset.id_ref, "left") \
    .drop("id_ref")


## READ RELATED VIDEOS
related_videos_dataset_path = "s3://myteducation-data/related_videos.csv"
related_videos_dataset = spark.read.option("header","true").csv(related_videos_dataset_path)

# CREATE THE AGGREGATE MODEL AND ADD WATCH_NEXT TO TEDX_DATASET
current_video_views = related_videos_dataset.select(col("relatedId").alias("id_ref"),
                                                    col("viewedCount").alias("views"))

related_videos_dataset = related_videos_dataset.select(col("internalId").alias("id_ref"),
                                                       col("related_id").alias("watch_next_id"),
                                                       col("slug").alias("watch_next_slug"),
                                                       col("title").alias("watch_next_title"),
                                                       col("viewedCount").alias("watch_next_views"))

related_videos_dataset = related_videos_dataset.groupBy(col("id_ref").alias("internalId")).agg(collect_list(struct(
        col("watch_next_id"),
        col("watch_next_slug"),
        col("watch_next_title"),
        col("watch_next_views"))).alias("watch_next"))



# JOIN WITH THE MAIN TABLE

tedx_dataset_main = tedx_dataset_main.join(current_video_views, tedx_dataset_main.internalId == current_video_views.id_ref, "left") \
    .drop("id_ref")
tedx_dataset_main = tedx_dataset_main.join(related_videos_dataset, tedx_dataset_main.internalId == related_videos_dataset.internalId, "left") \
    .drop("id_ref")


## READ TAGS DATASET
tags_dataset_path = "s3://myteducation-data/tags.csv"
tags_dataset = spark.read.option("header","true").csv(tags_dataset_path)


# CREATE THE AGGREGATE MODEL, ADD TAGS TO TEDX_DATASET
tags_dataset_agg = tags_dataset.groupBy(col("id").alias("id_ref")).agg(collect_list("tag").alias("tags"))
tags_dataset_agg.printSchema()
tedx_dataset_agg = tedx_dataset_main.join(tags_dataset_agg, tedx_dataset.id == tags_dataset_agg.id_ref, "left") \
    .drop("id_ref") \
    .select(col("id").alias("_id"), col("*")) \
    .drop("id") \




tedx_dataset_agg.printSchema()


write_mongo_options = {
    "connectionName": "TEDX",
    "database": "unibg_tedx_2024",
    "collection": "tedx_data",
    "ssl": "true",
    "ssl.domain_match": "false"}
from awsglue.dynamicframe import DynamicFrame
tedx_dataset_dynamic_frame = DynamicFrame.fromDF(tedx_dataset_agg, glueContext, "nested")

glueContext.write_dynamic_frame.from_options(tedx_dataset_dynamic_frame, connection_type="mongodb", connection_options=write_mongo_options)
