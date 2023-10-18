# [Dive into Valkyrie](https://samveraconnect2023.sched.com/event/1OmBk)

This repository supports a workshop given at
[Samvera Connect 2023](https://samvera.atlassian.net/wiki/spaces/samvera/pages/2174877699/Samvera+Connect+2023).

Valkyrie is a data persistence library which provides a common interface to multiple backends. There are a growing number of Samvera applications that use Valkyrie including Hyrax. This workshop will introduce core concepts and how they differ from ActiveFedora, ActiveRecord, and ActiveStorage. We’ll build a simple rails application that uses Valkyrie to write metadata to a postgres database and store files on disk.

## Learning Outcomes

We will learn:
1. Familiarity of Data Mapper pattern
   1. Why DataMapper?
   1. Differences with ActiveRecord
1. Familiarity with Valkyrie concepts
   1. Resource
   2. Change Set
   3. Metadata Adapter
   4. Persister
   5. Query Service
      1. Built-in queries
      2. Custom queries
   7. Storage Adapter
1. Understanding how to use Valkyrie in a simple rails application for metadata and file storage
   1. Hands on experience defining resource models and persisting metadata and files
1. Familiarity with available Valkyrie adapters
   1. Bundled in Valkyrie gem
   2. Adapter ecosystem

## Prerequisites

**Please ensure you can do the following prior to the workshop:**

```sh
git clone https://github.com/samvera-labs/dive-into-valkyrie-workshop.git
cd dive-into-valkyrie-workshop
docker-compose pull
docker-compose up 
```

## Agenda

???


## Resources

  * [Dive into Valkyrie](https://github.com/samvera/valkyrie/wiki/Dive-into-Valkyrie)
  * [Valkyrie wiki](https://github.com/samvera/valkyrie/wiki)
