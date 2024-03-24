# OAI-PMH Endpoint

The DTA supports an OAI-PMH for sharing of data. The relevant URLS for this are:
* **List Records:** https://www.digitaltransgenderarchive.net/oai.xml/?verb=ListRecords
  * Use the resumption token at the end to resume records like: https://www.digitaltransgenderarchive.net/oai.xml/?verb=ListRecords&resumptionToken=100
* **Get Collections:** https://www.digitaltransgenderarchive.net/oai.xml/?verb=ListSets
* **Get Individual Record:** https://www.digitaltransgenderarchive.net/oai.xml/?verb=GetRecord&identifier=765371442

# Fields

## Metadata fields 

To be further added.

## File

For the source file, there are the following fields:
* **dc:preview**: This is a JPG thumbnail version of the object.
* **dc:file**: This is highest quality version of the original file and could be an image, a pdf, etc.
  * Of note, if **dc:hosted_elsewhere** is set, then this is an image of 600px of width for future thumbnail generation.
    The original is stored at the partner institution,
* **dc:file_original_name**: The original name of the uploaded file (if available).
* **dc:file_original_extension**: The original extension of the file (if available).
* **dc:file_mime_type**: The mime type of the file.

Of note is that these fields can be repeated. A repeated example would be:
* https://www.digitaltransgenderarchive.net/oai.xml/?verb=GetRecord&identifier=bz60cw59v

## Other

* **dc:aggregatorHarvestingIndicator** is used by the [Digital Commonwealth](https://www.digitalcommonwealth.org) as flag
  on whether to ingest records for their system. This is to avoid duplicates that they might have ingested from other aggregate
  source. This can be ignored by other systems.