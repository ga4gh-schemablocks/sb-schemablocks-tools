## tools

Tools for managing the {S}[B] repositories and website

### sbSchemaParser

The `sbSchemaParser.pl` script is used to process schema files written in
*JSON Schema* (YAML version) into human-readable documentation (e.g. Markdown files for Jekyll
based HTML generation) and JSON data files from the embedded examples.

Directives for source and target directories can be modified in the `config.yaml` file in the script's directory.

```
sb-code       # each of the code repositories
  |
  |- source   # original code
  |- working  # for editing, temporary...
  |- schemas  # JSON Schema files as YAM; read to produce the output files
  |- json     # .json version of the schema, generated from YAML file
  |- examples # .json example data, generated from inline examples in schema
  |- doc      # .md documentation, generated from inline documentation in schema
```

The script alse generates copies of the `myschema.json` files into the canonical
website directory, and a GH-pages version of the Markdown documentation file
into the `pages` tree processed by the GH-pages "Jekyll" processing engine.

```
ga4gh-schemablocks.github.io
  |
  |- schemas
  |        |- ga4gh # json version of the schema, generated from YAML
  |                 # => https://schemablocks.org/schemas/ga4gh/__schema__.json
  |- pages
        |- _schemas
                |- ga4gh  # the Jekyll Markdown files for the website
```
