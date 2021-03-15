## sbOpenAPIparser

A configuration file is required for the script and may be provided as `sbOpenAPIparser.yaml`
file in the script's directory (auto-detected) or in another location and then be called
with a `-c ___path-to-the-file___` command line argument.

#### Example configuration file

The script avoids the bundling of an example configuration file, to leave the blame of any
file system chaos with the implementer. Below is an example that can be used as template.

* paths are _relative to the configuration file_
* the 3 last parts of the `$id` parameter are canonical & required for parsing with the
[sbSchemaParser](./sbSchemaParser.md) tool
  - `__schema__` and `__schemaversion__` are derived from the original file
  - `__project__` may reflect the original project name or an alternative

```
version: 2021-03-12
project: 'beacon-v2'
outdir: '../schemas'
schemafile: '../../specification-v2/beacon.yaml'
headerfile: false
header:
  "$schema": http://json-schema.org/draft-07/schema#
  "$id": https://schemablocks.org/schemas/__project__/__schema__/__schemaversion__
  meta:
    contributors:
      - label: "ELIXIR Beacon project team"
        id: "https://beacon-project.io/categories/people.html"
      - label: "Jordi Rambla"
        id: 'github:@jrambla'
      - label: "Sabele de la Torre"
        id: 'github:@sdelatorrep'
      - label: "Mamana Mbiyavanga"
        id: 'github:@mamanambiya'
      - label: "Michael Baudis"
        id: "orcid:0000-0002-9903-4248"
    provenance:
      - label: "Beacon v2"
        id: "https://github.com/ga4gh-beacon/specification-v2"
    used_by:
      - label: "Progenetix database schema (Beacon+ backend)"
        id: 'https://github.com/progenetix/schemas/'
    sb_status: community
```
