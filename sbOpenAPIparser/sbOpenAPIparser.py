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


    end_podmd"""

    with open( path.join( path.abspath( dir_path ), "config.yaml" ) ) as cf:
        config = yaml.load( cf , Loader=yaml.FullLoader)

    config[ "paths" ][ "headerfile" ] = path.join( path.abspath( dir_path ), "header.yaml" )

    args = _get_args()
    config = _check_args(config, args)

    with open( config[ "paths" ][ "schemafile" ] ) as f:
        oas = yaml.load( f , Loader=yaml.FullLoader)

    with open( config[ "paths" ][ "headerfile" ] ) as f:
        hd = yaml.load( f , Loader=yaml.FullLoader)

    for schema in oas["components"]["schemas"]:

        fn = schema+".yaml"
        print(fn)

        s = oas["components"]["schemas"][ schema ]
        s[ "title" ] = schema

        for p in hd:
            s[ p ] = hd[ p ]

        for p in s[ "properties" ]:

            if '$ref' in s[ "properties" ][ p ]:
                s[ "properties" ][ p ][ '$ref' ] = re.sub( '#/components/schemas/', './', s[ "properties" ][ p ][ '$ref' ] )
            if 'items' in s[ "properties" ][ p ]:
                if '$ref' in s[ "properties" ][ p ][ "items" ]:
                    s[ "properties" ][ p ][ "items" ][ '$ref' ] = re.sub( '#/components/schemas/', './', s[ "properties" ][ p ][ "items" ][ '$ref' ] )

        s[ "$id" ] = re.sub( r"__schema__", schema, s[ "$id" ] )

        if "info" in oas:
            if "version" in oas[ "info" ]:
                s[ "version" ] = oas[ "info" ][ "version" ]
                s[ "$id" ] = re.sub( r"__version__", s[ "version" ], s[ "$id" ] )

        s[ "$id" ] = re.sub( r"__project__", args.project, s[ "$id" ] )

        ofp = path.join( config[ "paths" ][ "out" ], fn )
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

    if not path.isfile( config[ "paths" ][ "headerfile" ] ):
        print("No header file has ben given; please use `-h` to specify")
        sys.exit( )

    return(config)

################################################################################
################################################################################
################################################################################

if __name__ == '__main__':
    main(  )
