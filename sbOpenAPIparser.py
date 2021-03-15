#!/usr/local/bin/python3

import sys, re
from ruamel.yaml import YAML
from os import path as path
import argparse

# local
dir_path = path.dirname(path.abspath(__file__))

"""podmd

The `sbOpenAPIparser` tool reads schema files defined using OpenAPI and extracts
the embedded schemas as individual YAML documents, with an added metadata header
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
    parser.add_argument("-c", "--config", help="path to the sbOpenAPIparser.yaml configuration file")
    args = parser.parse_args()

    return args

################################################################################

def main():

    """podmd

    A single-file OpenAPI schema is read in from a YAML file, and the
    `components.schemas` object is iterated over, extracting each individual
    schema.

    This schema is updated with metadata, either from a provided SchemaBlocks
    header file or with a default from a configuration file (e.g.
    `sbOpenAPIparser.yaml`).

    Some of the parameter values are adjusted (which probably will have to be
    expanded for different use cases); e.g. the internal reference paths
    are interpreted as pointing to individual schema files in the current
    directory.

    end_podmd"""

    cff = _get_config_path(dir_path, _get_args())

    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)

    try:
        with open( cff ) as cf:
            config = yaml.load( cf )
    except Exception as e:
        print("Error loading the config file ({}): {}".format(cff, e) )
        exit()

    config.update( { "config_base_path": path.dirname(cff) } )
    _check_config(config)

    with open( config[ "schemafile" ] ) as f:
        oas = yaml.load( f )

    _config_add_project_specs(config, oas)

    for s_name in oas["components"]["schemas"].keys():

        f_name = s_name+".yaml"
        print(f_name)

        s = oas["components"]["schemas"][ s_name ]
        _add_header(config, s, s_name)
        _fix_relative_ref_paths(s)

        if "$id" in s:
            s[ "$id" ] = re.sub( r"__schema__", s_name, s[ "$id" ] )
            s[ "$id" ] = re.sub( r"__project__", config[ "project" ], s[ "$id" ] )

        ofp = path.join( config[ "outdir" ], f_name )
        with open(ofp, 'w') as of:
            docs = yaml.dump(s, of)

################################################################################

def _get_config_path(dir_path, args):

    cfp = path.join( path.abspath( dir_path ), "sbOpenAPIparser.yaml")
    if vars(args)["config"]:
        cfp = path.abspath( vars(args)["config"] )

    if not path.isfile( cfp ):
        print("""
The configuration file:
    {}
...does not exist; please use a correct "-c" parameter".
""".format(cfp))
        sys.exit( )
       
    return cfp

################################################################################

def _check_config(config):

    for p in ["schemafile", "outdir", "project"]:
        if not p in config:
            print('No {} parameter has been provided the configuration file => exiting.'.format(p))
            sys.exit( )

    config.update({ "outdir": path.join( config[ "config_base_path" ], config[ "outdir" ]) } )
    config.update({ "schemafile": path.join( config[ "config_base_path" ], config[ "schemafile" ]) } )

    if not path.isdir( config[ "outdir" ] ):
        print("""
The output directory:
    {}
...does not exist; please use a correct relative path in the configuration file.
""".format(config[ "outdir" ]))
        sys.exit( )

    if not path.isfile( config[ "schemafile" ] ):
        print("""
The input file:
    {}
...does not exist; please use a correct relative path in the configuration file.
""".format(config[ "outdir" ]))
        sys.exit( )

    return config

################################################################################

def _config_add_project_specs(config, oas):

    h_k_n = len( config["header"].keys() )

    if "info" in oas:
        if "version" in oas[ "info" ]:
            config["header"].update( { "$id" : re.sub( r"__schemaversion__", oas["info"][ "version" ], config["header"]["$id" ]) } )
            config["header"].insert(h_k_n, "version", oas["info"][ "version" ])

    return config

################################################################################

def _add_header(config, s, s_name):

    pos = 0

    for k, v in config[ "header" ].items():
        s.insert(pos, k, v)
        pos += 1

    s.insert(pos, "title", s_name)

    return s

################################################################################

def _fix_relative_ref_paths(s):

    """podmd
    The path fixes here are very much "experience driven" and should be replaced
    with a more systematic version, including existence & type checking ...
    podmd"""

    properties = s
    if "properties" in s:
        properties = s[ "properties" ]

    for p in properties.keys():

        if '$ref' in properties[ p ]:
            properties[ p ][ '$ref' ] = re.sub( '#/components/schemas/', '', properties[ p ][ '$ref' ] ) + '.yaml#/'
        if 'items' in properties[ p ]:
            if '$ref' in properties[ p ][ "items" ]:
                properties[ p ][ "items" ][ '$ref' ] = re.sub( '#/components/schemas/', '', properties[ p ][ "items" ][ '$ref' ] ) + '.yaml#/'

        if "properties" in s:
            s[ "properties" ].update( { p: properties[ p ] } )
        else:
            s.update( { p: properties[ p ] } )

    if "oneOf" in s:
        o_o = [ ]
        for o in s[ "oneOf" ]:
            if "$ref" in o.keys():
                v = re.sub( '#/components/schemas/', '', o["$ref"] ) + '.yaml#/'
                o_o.append( { "$ref": v} )
            else:
                o_o.append( o )
        s.update( { "oneOf": o_o } )

    return s

################################################################################
################################################################################
################################################################################

if __name__ == '__main__':
    main(  )
