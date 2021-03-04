## sbSchemaParser

The `sbSchemaParser.pl` Perl script parses YAML schema definitions 
written in [_JSON Schema_](https://json-schema.org) which use the standard GA4GH 
[SchemaBlocks {S}[B]](http://schemablocks.org) structure, into 

* JSON versions of the schemas (unprocessed), to serve as the reference
schema versions
* Markdown documentation, both in plain Markdown and as sources for "Jekyll" 
based Markdown => HTML generation by Github Pages (or a local installation)
* example `.json` data files, from the inline `examples`

#### Processing Schema Source Directories

The script parses through the associated source repositories which are required
to reside inside a unified root (`git_root_dir`). The names of the (one or
several) repositories and their schema file source directories (one or several
per repository) are specified in the `config.yaml` file.


The output files are generated relative to the script path. This assumes a
directory structure, in which the different repositories are contained in the
same root (i.e. organization) directory, and the script itself is inside a
first order directory in one of the repositories. However, specific names of all of 
the directories can be modified in [`config.yaml`](./config.yaml):


```
this-organization
  |
  |-- tools
  |     |
  |     |-- sbSchemaParser
  |     |     |
  |           |-- sbSchemaParser.pl # this file
  |           |-- config.yaml       # in- and output path definitions
  |
  |-- sb-external-schemas-name      # example for (1 or 1+) schema repositories
  |     |
  |     |-- source
  |     |     |
  |     |     |-- v1.0.1			# versioned representation of the donor code
  |     |
  |     |-- schemas
  |     |     |
  |     |     |-- Schema.yaml
  |     |     |-- OtherSchema.yaml
  |     |     |-- ...
  |     |
  |     |-- working
  |     |     |-- SomethingNew.yaml     
  |     |     |-- ...
  |     |     
  |     |-- generated               # config.yaml -> "out_dirnames"
  |           |
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
  |-- (webdocs.repo)                # web repository (Jekyll based)
        |
        |-- (webdocs.jekylldir)
        |     |
        |     |-- Schema.md
        |     |-- ...
        |
        |-- (webdocs.schemadir)
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

#### Usage

The `sbSchemaParser.pl` script has to be run in a _local_ version of the 
repository structure. In principle, any relative directory locations should be 
possible if specified in the `config.yaml` defaults file, though a reasonable 
approach is to use a "organization -> projects" structure as above.

The script is executed with

```
perl sbSchemaParser.pl
```

The only current option is to provide a "-filter" argument against the schema 
file names; e.g. `perl sbSchemaParser.pl -filter Age` will only process schemas 
with "Age" in their file name.

