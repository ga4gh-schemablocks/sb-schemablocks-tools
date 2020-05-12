#!/usr/local/bin/python3

import sys, yaml, re, json
from os import path as path
import argparse

# local
dir_path = path.dirname(path.abspath(__file__))

"""podmd

The `sbOpenAPIparser` tool reads schema files defined using OpenAPI and extracts
the embedded schemas as single YAML documents, with an added metadata header
compatible to use in [SchemaBlocks](https://schemablocks.org/categories/schemas.html)
schema documents.

##### Examples

* `python3 sbOpenAPIparser.py -o ~/GitHub/ga4gh-schemablocks/sb-discovery-search/schemas/ -f ~/GitHub/ga4gh-schemablocks/sb-discovery-search/source/search-api.yaml -p "sb-discovery-search" -m ~/GitHub/ga4gh-schemablocks/sb-discovery-search/source/header.yaml`

podmd"""

################################################################################
################################################################################
################################################################################

def _get_args():

    parser = argparse.ArgumentParser()
    parser.add_argument("-o", "--outdir", help="path to the output directory")
    parser.add_argument("-f", "--file", help="OpenAPI schema file to be ripped apart")
    parser.add_argument("-m", "--header", help="SchemaBlocks format metadata header")
    parser.add_argument("-p", "--project", help="Project id")

    args = parser.parse_args()

    return(args)

################################################################################

def main():

    """podmd

    A single-file OpenAPI schema is read in from a YAML file, and the
    `components.schemas` object is iterated over, extracting each individual
    schema.

    This schema is updated with metadata, either from a provided SchemaBlocks
    header file or with a default from `config.yaml`.

    Some of the parameter values are adjusted (which probably will have to be
    expanded for different use cases); e.g. the internal reference paths
    are interpreted as pointing to individual schema files in the current
    directory.

    end_podmd"""

    with open( path.join( path.abspath( dir_path ), "config.yaml" ) ) as cf:
        config = yaml.load( cf , Loader=yaml.FullLoader)

    args = _get_args()
    config = _check_args(config, args)

    with open( config[ "paths" ][ "schemafile" ] ) as f:
        oas = yaml.load( f , Loader=yaml.FullLoader)

    if path.isfile( config[ "paths" ][ "headerfile" ] ):
        with open( config[ "paths" ][ "headerfile" ] ) as f:
            config.update( { "header": yaml.load( f , Loader=yaml.FullLoader) } )

    for s_name in oas["components"]["schemas"].keys():

        f_name = s_name+".yaml"
        print(f_name)

        s = oas["components"]["schemas"][ s_name ]

        s = _add_header(config, s)
        s = _add_project_specs(oas, s)
        s = _fix_relative_ref_paths(s)

        s[ "title" ] = s_name

        if "$id" in s:
            s[ "$id" ] = re.sub( r"__schema__", s_name, s[ "$id" ] )
            s[ "$id" ] = re.sub( r"__project__", args.project, s[ "$id" ] )

        ofp = path.join( config[ "paths" ][ "out" ], f_name )
        with open(ofp, 'w') as of:
            docs = yaml.dump(s, of)

################################################################################

def _check_args(config, args):

    if not args.project:
        print("No project name has been provided; please use `-p` to specify")
        sys.exit( )

    if args.outdir:
        config[ "paths" ][ "out" ] = args.outdir

    if not path.isdir( config[ "paths" ][ "out" ] ):
        print("""
The output directory:
    {}
...does not exist; please use `-o` to specify
""".format(config[ "paths" ][ "out" ]))
        sys.exit( )

    if args.file:
        config[ "paths" ][ "schemafile" ] = args.file

    if not path.isfile( config[ "paths" ][ "schemafile" ] ):
        print("No inputfile has ben given; please use `-f` to specify")
        sys.exit( )

    if args.header:
        config[ "paths" ][ "headerfile" ] = args.header

    return(config)

################################################################################

def _add_header(config, s):

    for p in config[ "header" ]:
        s[ p ] = config[ "header" ][ p ]

    return(s)

################################################################################

def _add_project_specs(oas, s):

    if "info" in oas:
        if "version" in oas[ "info" ]:
            s[ "version" ] = oas[ "info" ][ "version" ]
            s[ "$id" ] = re.sub( r"__version__", s[ "version" ], s[ "$id" ] )

    return(s)

################################################################################

def _fix_relative_ref_paths(s):

    properties = s
    if "properties" in s:
        properties = s[ "properties" ]

    for p in properties.keys():

        print(p)
        if '$ref' in properties[ p ]:
            properties[ p ][ '$ref' ] = re.sub( '#/components/schemas/', './', properties[ p ][ '$ref' ] )
        if 'items' in properties[ p ]:
            if '$ref' in properties[ p ][ "items" ]:
                properties[ p ][ "items" ][ '$ref' ] = re.sub( '#/components/schemas/', './', properties[ p ][ "items" ][ '$ref' ] )

        if "properties" in s:
            s[ "properties" ].update( { p: properties[ p ] } )
        else:
            s.update( { p: properties[ p ] } )

    return(s)

################################################################################
################################################################################
################################################################################

if __name__ == '__main__':
    main(  )
