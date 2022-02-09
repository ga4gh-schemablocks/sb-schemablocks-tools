## sbSchemaParser

The `sbSchemaParser.pl` Perl script parses YAML schema definitions 
written in [_JSON Schema_](https://json-schema.org) which use the standard GA4GH 
[SchemaBlocks {S}[B]](http://schemablocks.org) structure, into 

* JSON versions of the schemas (unprocessed), to serve as the reference
schema versions
* Markdown documentation, both in plain Markdown and as sources for "Jekyll" 
based Markdown => HTML generation by Github Pages (or a local installation)
* example `.json` data files, from the inline `examples`

#### Usage

The `sbSchemaParser.pl` script has to be run in a _local_ version of the 
repository structure. In principle, any relative directory locations should be 
possible if specified in the `config.yaml` defaults file, though a reasonable 
approach is to use a "organization -> projects" structure as above.

Paths for input and output directories are specified in the configuration YAML
file as *relative to the configuration file*. The only assumption there is the
existence of a shared root directory for schema repositories and website repo.

The script is executed - from any location - with

```
perl sbSchemaParser.pl -c __path_to_configuration_file__
```

The only additional option is to provide a "-filter" argument against the schema 
file names; e.g. `perl sbSchemaParser.pl -filter Age -c ...` will only process
schemas with "Age" in their file name. Additionally, the configuration file allows
to exclude files from processing.

#### Example configuration

```
---
github_organisation: ga4gh-schemablocks
site_domain_name: beacon-project.io
url: 'https://beacon-project.io'
organization_root_path_comps:
  - ..
  - ..
status_levels:
  - playground
  - community
  - proposed
  - implemented
  - core

defaults:
  version: 2.0.0-draft.4
  project: sb-beacon-api
  meta_header:
    contributors:
      - label: ELIXIR Beacon project team
        id: https://beacon-project.io/categories/people.html
    provenance:
      - label: Beacon v2 provisional version
        id: https://github.com/ga4gh-beacon/
    used_by:
      - label: Beacon v2 frontline implementers
        id: https://ga4gh-approval-service-registry.ega-archive.org
      - label: Progenetix database schema (Beacon+ backend)
        id: https://docs.progenetix.org/beaconplus/
    sb_status: proposed

schema_repos:
  - schema_repo: sb-beacon-api
    branch: main
    tags:
      - Beacon-v2
      - beacon
      - schemas
    categories:
      - specification
    schema_dirs:
      - [ "schemas", "framework", "common" ]
      - [ "schemas", "framework", "configuration" ]
      - [ "schemas", "framework", "requests" ]
      - [ "schemas", "framework", "responses" ]
      - [ "schemas", "models", "analyses" ]
      - [ "schemas", "models", "biosamples" ]
      - [ "schemas", "models", "cohorts" ]
      - [ "schemas", "models", "common" ]
      - [ "schemas", "models", "datasets" ]
      - [ "schemas", "models", "genomicVariations" ]
      - [ "schemas", "models", "individuals" ]
      - [ "schemas", "models", "runs" ]
    out_dir_name: generated
    target_doc_dirname: sb-beacon-api
    include_matches: [ ]
    exclude_matches: [ "endpoints" ]
    meta_header_filename: ""

out_dirnames:
  json: json
  markdown: doc
  examples: examples

webdocs:
  repo: 'ga4gh-schemablocks.github.io'
  jekyll_path_comps:
    - pages
    - _schemas
  schemadir: 'schemas'
  web_schemas_rel: "/schemas"
  web_html_rel: "/schemas"

generator_prefix: '+generated__'

schema_disclaimer: >
  <div id="schema-footer">
  This schema representation is for information purposes. The authorative 
  version remains with the developing project (see "provenance").
  </div>

jekyll_excerpt_separator: "<!--more-->"

prefix_expansions:
  orcid: 'https://orcid.org/'
  PMID: 'https://www.ncbi.nlm.nih.gov/pubmed/'
  github: 'https://github.com/'

links:
  sb_status_levels: "https://schemablocks.org/about/sb-status-levels.html"
```

#### Processing Schema Source Directories

The script parses through the associated source repositories which are required
to reside inside a unified root (`git_root_dir`). The names of the (one or
several) repositories and their schema file source directories (one or several
per repository) are specified in the `config.yaml` (can be named differently)
file.

The output files are generated relative to the configuration path. This assumes
a directory structure, in which the different repositories are contained in the
same root (i.e. organization) directory.

```
this-organization
  |
  |-- sb-external-schemas-name      # example for 1 or more schema repositories
  |     |
  |     |-- config
  |     |     |
  |     |     |-- config.yaml       # ==> required <==
  |     |     |                     # configuration for directories etc.
  |     |     |                     # called with `-c __path__to__this__` 
  |     |
  |     |-- source                  # (optional)
  |     |     |
  |     |     |-- v1.0.1            # versioned representation of the donor code
  |     |
  |     |-- schemas                 # ==> required <==
  |     |     |                     # name can be specified in configuration
  |     |     |-- Schema.yaml
  |     |     |-- OtherSchema.yaml
  |     |     |-- ...
  |     |
  |     |-- working                 # (optional)
  |     |     |-- SomethingNew.yaml     
  |     |     |-- ...s
  |     |     
  |     |-- generated               # ==> required <==
  |           |                     # name can be specified in configuration
  |           |-- doc
  |           |     |-- Schema.md
  |           |     |-- OtherSchema.md
  |           |     |-- ...
  |           |
  |           |-- json
  |           |     |    
  |           |     |-- current
  |           |     |     |-- Schema.json
  |           |     |     |-- ...
  |           |     |    
  |           |     |-- v0.0.1
  |           |     |     |-- Schema.json
  |           |     |     |-- ...
  |           |     |    
  |           |     |-- v... 
  |           |
  |           |-- examples
  |   
  |-- (organization.github.io)       # web repository (Jekyll based)
        |                            # names as examples
        |-- (pages/_schemas)         # specified in configuration
        |     |
        |     |-- Schema.md
        |     |-- ...
        |
        |-- (schemas)
              |
              |     |-- Schema.json
              |     |-- ...
              |    
              |-- v0.0.1
              |     |-- Schema.json
              |     |-- ...
              |    
              |-- v...
```


