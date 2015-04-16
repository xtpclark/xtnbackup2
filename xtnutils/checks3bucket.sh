#!/bin/bash

checks3bucket()
{
s3cmd mb ${S3BUCKET}
sleep 10
}

