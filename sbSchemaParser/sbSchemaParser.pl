#!/usr/bin/perl

use Cwd qw(abs_path);
use JSON::XS;
use YAML::XS qw(LoadFile DumpFile);
use Data::Dumper;
$Data::Dumper::Sortkeys = 	1;

binmode STDOUT, ":utf8";
my @here_path  	=   split('/', abs_path($0));
pop @here_path;
my $here_path		=		join('/', @here_path);
my $config     	=   LoadFile($here_path.'/config.yaml') or die "¡No config.yaml file in this path!";
bless $config;

=podmd
The output files are generated relative to the script path. This assumes a
directory structure, in which the different repositories are contained in the
same root (i.e. organization) directory, and the script itself is inside a
first order directory in one of the repositories (e.g. `/my-repo/tools/`).

=cut

$config->{here_path}		=		$here_path;
$config->{git_root_rel}	=		$here_path.'/../..';

# command line input
my %args        =   @ARGV;
$args{-filter}	||= q{};
foreach (keys %args) { $config->{args}->{$_} = $args{$_} }

_process_src($config);

exit;

################################################################################
################################################################################
# subs
################################################################################
################################################################################

################################################################################
# main file specific process
################################################################################

sub _process_yaml {

	my $config		=		shift;
	my $files			=		shift;

  print "Reading YAML file \"$files->{input_yaml}\"\n";

  my $data      =   LoadFile($files->{input_yaml});

=podmd
The class name should correspond to the file's "title" value.
Processing is skipped if the class name does not consist of word character, or
if a filter had been provided and the class name doesn't match.

=cut

  _check_class_name($files->{input_class}, $data->{title});

  if ($data->{title} !~ /^\w+?$/) { return }
	if ($args{-filter} =~ /.../) {
		if ($data->{title} !~ /$args{-filter}/) {
			return } }

=podmd
The documentation is extracted from the $data object and formatted into a
markdown document.

=cut

	my $output		=		{
		md					=>	q{},
		jekyll_head	=>	_create_jekyll_header($config, $files),
	};

  $output->{md} .=  <<END;

## $data->{title}

* {S}[B] Status  [[i]]($config->{links}->{sb_status_levels})
    - __$data->{meta}->{sb_status}__
END

	foreach my $attr (qw(provenance used_by contributors)) {
		if ($data->{meta}->{$attr}) {
			my $label =   $attr;
			$label  	=~  s/\_/ /g;
			$output->{md} .=  "\n* ".ucfirst($label)."  \n";
			foreach (@{$data->{meta}->{$attr}}) {
				my $text		=   $_->{description};
=podmd
The script performs a CURIE to URL expansion for prefixes defined in the
configuration file and links e.g. the ORCID id to its web address.

=cut
				my $id	=		_expand_CURIEs($config, $_->{id});
				if ($id =~ /\:\/\/\w/) {
					$text =   '['.$text.']('.$id.')' }
				elsif ($id =~ /\w/) {
					$text .=  ' ('.$id.')' }
				$output->{md} 	.=  "\n    - ".$text."  ";
	}}}
  $output->{md} .=  <<END;

$config->{jekyll_excerpt_separator}

### Source

* raw source [[JSON](./$files->{input_class}.json)]
* [Github]($files->{github_link})

### Attributes
END

	foreach my $attr (grep{ $data->{$_} =~ /\w/ }  qw(type format pattern description)) {
		$output->{md} 	.=  "  \n__".ucfirst($attr).":__ $data->{$attr}" }

	if ($data->{type} =~ /object/i) {
		$output->{md}		=		_parse_properties($data, $output->{md}) }

	if ($data->{'examples'}) {
		$output->{md} 	.=  "\n\n### `$data->{title}` Value "._pluralize("Example", $data->{'examples'})."  \n\n";
		foreach (@{ $data->{'examples'} }) {
		  $output->{md} .=  "```\n".JSON::XS->new->pretty( 1 )->canonical()->allow_nonref->encode($_)."```\n";
		}
	}

	##############################################################################

=podmd


=cut

	$files->{outfile_exmpls_json}->{content}  =   JSON::XS->new->pretty( 1 )->canonical()->encode( $data->{examples} )."\n";
	$files->{outfile_plain_md}->{content}     =   $output->{md};
	$files->{outfile_src_json}->{content}     =   JSON::XS->new->pretty( 1 )->canonical()->allow_nonref->encode($data)."\n";
	$files->{outfile_web_src_json}->{content} =   JSON::XS->new->pretty( 1 )->canonical()->allow_nonref->encode($data)."\n";
	$files->{outfile_jekyll_md}->{content}    =   $output->{jekyll_head}.$output->{md}."\n";

  foreach my $outFile (grep{ /outfile/} keys %{ $files }) {
    print "writing $files->{$outFile}->{path}\n";
    open  (FILE, ">", $files->{$outFile}->{path}) || warn '!!! output file '. $files->{$outFile}->{path}.' could not be created !!!';
    print FILE  $files->{$outFile}->{content}."\n";
    close FILE;
  }

}

################################################################################
################################################################################
# helpers
################################################################################
################################################################################

################################################################################
################################################################################

sub _create_file_paths {

=podmd
Paths for the output files are created from the pre-generated directory paths
and variables (class, parent directory name) which are extracted from the full
path of the input file.

The web files for the Jekyll / GH-pages processing gets a prefix, to ensure that
auto-generated and normal pages can be separated.

=cut

	my (
		$config,
		$file,
		$repoName,
		$dirName,
		$fileName,
		$out_web
	)							=		@_;
	my $class			=		$fileName;
	$class				=~	s/\.\w+?$//;

	return		{
		input_yaml	=>	$file,
		input_name	=>	$fileName,
		input_class	=>	$class,
		input_dir		=>	$dirName,
		input_repo	=>	$repository,
		outfile_exmpls_json => 	{
			path			=>	join('/',
											$config->{git_root_rel},
											$repoName,
											$config->{paths}->{out_dirnames}->{examples},
											$class.'-examples.json'
										),
			content		=>	q{}
		},
		outfile_plain_md		=> 	{
			path			=>	join('/',
											$config->{git_root_rel},
											$repoName,
											$config->{paths}->{out_dirnames}->{markdown},
											$class.'.md'
										),
			content		=>	q{}
		},
		outfile_src_json 		=> 	{
			path			=>	join('/',
											$config->{git_root_rel},
											$repoName,
											$config->{paths}->{out_dirnames}->{json},
											$class.'.json'
										),
			content		=>	q{}
		},
		outfile_web_src_json => 	{
			path			=>	join('/',
											$config->{git_root_rel},
											$out_web->{repository},
											$out_web->{dirs}->{schemas},
											$class.'.json'
										),
			content		=>	q{}
		},
		outfile_jekyll_md 	=> 	{
			path			=>	join('/',
											$config->{git_root_rel},
											$out_web->{repository},
											$out_web->{dirs}->{jekyll},
											$config->{generator_prefix}.$class.'.md'
										),
			content		=>	q{}
		},
		github_link => 	join('/',
											$config->{paths}->{github_web},
											$repoName,
											'blob/master',
											$dirName,
											$fileName
										),
		web_link_json => 	join('/',
											$out_web->{web}->{schemas_rel},
											$class.'.json'
										),
		doc_link_html => 	join('/',
											$out_web->{web}->{html_rel},
											$class.'.html'
										),
	};

}

################################################################################
################################################################################

sub _check_class_name {

	my ($file_name, $class)		=		@_;

  if ($file_name ne $class) {
		print <<END;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Mismatch between file name
	$file_name
and class name from "title" parameter
	$class

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END

  }
}

################################################################################
################################################################################

sub _process_src {

	my $config		=		shift;

	foreach my $src (@{ $config->{paths}->{'src'} }) {
		my $src_dir = 	join('/',
											$config->{here_path},
											'../..',
											$src->{repository},
											$src->{dir}
										);
		opendir DIR, $src_dir;
		foreach my $schema (grep{ /ya?ml$/ } readdir(DIR)) {
			foreach my $out_web (@{ $config->{paths}->{'out_web'} }) {
				my $files		=	_create_file_paths(
					$config,
					join('/',
						$src_dir,
						$schema
					),
					$src->{repository},
					$src->{dir},
					$schema,
					$out_web
				);
				_process_yaml($config, $files);
			}
		}
		close DIR;
	}

}

################################################################################
################################################################################

sub _parse_properties {

	my $data			=		shift;
	my $md				=		shift;

  $md  					.=  <<END;


### Properties

<table>
  <tr>
    <th>Property</th>
    <th>Type</th>
  </tr>
END

  foreach my $property ( sort keys %{ $data->{properties} } ) {
		my $label		=		_format_property_type_html($data->{properties}->{$property});
    $md 				.=  <<END;
  <tr>
    <td>$property</td>
    <td>$label</td>
  </tr>
END
  }

  $md   				.=  "\n".'</table>'."\n\n";

=podmd
The property overview is followed by the listing of the properties, including
descriptions and examples.

=cut

  foreach my $property ( sort keys %{ $data->{properties} } ) {
		my $label		=		_format_property_type_html($data->{properties}->{$property});
    $md   			.=  <<END;

#### $property

* type: $label

$data->{properties}->{$property}->{'description'}

END

		$md 				.=  "##### `$property` Value "._pluralize("Example", $data->{properties}->{$property}->{'examples'})."  \n\n";
		foreach (@{ $data->{properties}->{$property}->{'examples'} }) {
		  $md 			.=  "```\n".JSON::XS->new->pretty( 1 )->allow_nonref->canonical()->encode($_)."```\n";
		}

	}

	return $md;

}

################################################################################
################################################################################

sub _expand_CURIEs {

	my $config		=		shift;
	my $curie			=		shift;

	if (grep{ $curie =~ /^$_\:/ } keys %{ $config->{prefix_expansions} }) {
		my $pre			=		(grep{ $curie =~ /^$_\:/ } keys %{ $config->{prefix_expansions} })[0];
		$curie			=~	s/$pre\:/$config->{prefix_expansions}->{$pre}/;
	}

	return $curie;

}

################################################################################
################################################################################

sub _format_property_type_html {

	my $prop_data	=		shift;
  my $typeLab;
	my $type  		=   $prop_data->{type};
	if ($type !~ /.../ && $prop_data->{'$ref'} =~ /.../) {
		$typeLab		=		$prop_data->{'$ref'} }
	elsif ($type =~ /array/ && $prop_data->{items}->{'$ref'} =~ /.../) {
		$typeLab		=		$prop_data->{items}->{'$ref'} }
	else {
		$typeLab		=		$type }

	if ($typeLab =~ /\/[\w\-]+?\.\w+?$/) {
		my $yaml		=		$typeLab;
		my $html		=		$typeLab;
		$html				=~	s/\.\w+?$/.html/;
		$typeLab		.=	' [<a href="'.$yaml.'" target="_BLANK">SRC</a>] [<a href="'.$html.'" target="_BLANK">HTML</a>]' }

	if ($type =~ /array/) {
		$typeLab		=		"array of ".$typeLab }

		return $typeLab;

}

################################################################################
################################################################################

sub _create_jekyll_header {

	my $config		=		shift;
	my $files			=		shift;
	return 	<<END;
---
title: $files->{input_class}
layout: default
permalink: "$files->{doc_link_html}"
excerpt_separator: $config->{jekyll_excerpt_separator}
category:
  - schemas
tags:
  - code
---

END

}

################################################################################
################################################################################

sub _pluralize {
	my $word			=		shift;
	my $list			=		shift;
	if (@$list > 1) { $word .= 's' }
	return $word;
}
