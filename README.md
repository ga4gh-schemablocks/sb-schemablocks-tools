## tools

Tools for managing the {S}[B] repositories and website

### sbSchemaParser

The `sbSchemaParser.pl` script is used to process schema files written in
*JSON Schema* (YAML version) into human-readable documentation (e.g. Markdown files for Jekyll
based HTML generation) and JSON data files from the embedded examples.

Directives for source and target directories can be modified in the `config.yaml` file in the script's directory. The general repository structures for the 
repositories which are being parsed by _sbSchemaParser_ is shown below.

#### {S}[B] Repositories

{S}[B] code repositories adhere a consistent structure & naming:

```
sb-code       # each of the code repositories
  |
  |- source   # original code
  |- working  # for editing, temporary...
  |- schemas  # JSON Schema files as YAML; read to produce the output files
  |- json     # .json version of the schema, generated from YAML file
  |- examples # .json example data, generated from inline examples in schema
  |- doc      # .md documentation, generated from inline documentation in schema
```

Here  

* The `source` and `working` directories are optional.
* The `json`, `examples` and `doc` directories are populated by the _sbSchemaParser_

##### Website Files

The _sbSchemaParser_ also generates copies of the `myschema.json` files into 
the canonical website directory, and a GH-pages version of the Markdown documentation file into the `pages` tree processed by the GH-pages "Jekyll" processing engine. The .md file contains a `permalink` directive in its YAML 
header, which will lead to GH-pages placing the HTML page at  "https://schemablocks.org/schemas/ga4gh/myschema.html".

```
ga4gh-schemablocks.github.io
  |
  |- schemas
  |        |- ga4gh # json version of the schema, generated from YAML
  |                 # => https://schemablocks.org/schemas/ga4gh/myschema.json
  |- pages
        |- _schemas
                |- ga4gh  # the Jekyll Markdown files for the website
```
