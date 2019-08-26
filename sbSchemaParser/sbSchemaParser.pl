#!/usr/bin/perl

#use diagnostics;

use Cwd qw(abs_path);
use File::Basename;
use File::Copy;
use JSON::XS;
use YAML::XS qw(LoadFile DumpFile);
use Data::Dumper;
$Data::Dumper::Sortkeys = 	1;
use Text::Markdown qw(markdown);

binmode STDOUT, ":utf8";
my @here_path  	=   split('/', abs_path($0));
pop @here_path;
my $here_path		=		join('/', @here_path);
my $config     	=   LoadFile($here_path.'/config.yaml') or die "¡No config.yaml file in this path!";
bless $config;

$config->{repository}	=		(split('/', $here_path))[-2];	# script resides in a dir in repo root
$config->{here_path}	=		$here_path;

# command line input
my %args        =   @ARGV;
$args{-filter}	||= q{};
$args{-cleanup}	||= "n";
foreach (keys %args) { $config->{args}->{$_} = $args{$_} }

$config					=		_check_paths($config);
_delete_generated_files($config);
_process_input_dirs($config);

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

  my $config 		=   shift;
  my $file_path =   shift;

  my $files			=		_create_file_paths($config, $file_path);
	my $yaml_github_web_link 	=   $config->{paths}->{github_org_path}.'/'.$config->{repository}.'/blob/master/'.$files->{input_dir}.'/'.$files->{input_name};
  
  print "Reading YAML file \"$files->{input_yaml}\"\n";

  my $data      =   LoadFile($files->{input_yaml});

=podmd
The class name is extracted from the file's "title" value.
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

  my $jekyll_header =   _create_jekyll_header($config, $data->{title});

  my $md  			=   <<END;

## $data->{title}

* {S}[B] Status  [[i]]($config->{links}->{sb_status_levels})
    - __$data->{meta}->{sb_status}__
END

	foreach my $attr (qw(provenance used_by contributors)) {
		if ($data->{meta}->{$attr}) {
			my $label =   $attr;
			$label  	=~  s/\_/ /g;
			$md 			.=  "\n\n* ".ucfirst($label)."  \n";
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
				$md 		.=  "\n    - ".$text."  ";
	}}}
  $md  					.=  <<END;

$config->{jekyll_excerpt_separator}

### Source

* raw source [[JSON](./$files->{input_class}.json)] 
* [Github]($yaml_github_web_link)

### Attributes
END

	foreach my $attr (grep{ $data->{$_} =~ /\w/ }  qw(type format pattern description)) {
		$md 				.=  "  \n__".ucfirst($attr).":__ $data->{$attr}" }

	if ($data->{type} =~ /object/i) {
		$md						=		_parse_properties($data, $md) }
   
	if ($data->{'examples'}) {
		$md 				.=  "\n\n### `$data->{title}` Value "._pluralize("Example", $data->{'examples'})."  \n\n";
		foreach (@{ $data->{'examples'} }) {
		  $md   		.=  "```\n".JSON::XS->new->pretty( 1 )->canonical()->allow_nonref->encode($_)."```\n";		
		}
	}

	##############################################################################

=podmd


=cut

  my $printout    =   JSON::XS->new->pretty( 1 )->canonical()->encode( $data->{examples} )."\n";
	print "writing $files->{exmpls_json}\n";
	open  (FILE, ">", $files->{exmpls_json}) || warn 'output file '.$files->{exmpls_json}.' could not be created.';
	print FILE  $printout;
	close FILE;

	print "writing $files->{plain_md}\n";
	open  (FILE, ">", $files->{plain_md}) || warn 'output file '. $files->{plain_md}.' could not be created.';
	print FILE  $md."\n";
	close FILE;

	foreach (qw(src_json web_src_json)) {
		print "writing $files->{$_}\n";
		open  (FILE, ">", $files->{$_}) || warn 'output file '. $files->{$_}.' could not be created.';
		print FILE  JSON::XS->new->pretty( 1 )->canonical()->allow_nonref->encode($data)."\n";
		close FILE;
	}

	print "writing $files->{jekyll_md}\n";
	open  (FILE, ">", $files->{jekyll_md}) || warn 'output file '. $files->{jekyll_md}.' could not be created.';
  print FILE  $jekyll_header.$md."\n";
  close FILE;

}

################################################################################
################################################################################
# helpers
################################################################################
################################################################################

sub _check_paths {

=podmd
The generation of file paths is based on the assumptions that:

* the processing script (i.e. this file) resides in a "_tools" directory in the 
root of a git repository (name of directory not relevant)
* that other directories are defined relative to it

=cut

  my $config 		=   shift;

	foreach my $path (grep { /_rel/ } keys %{$config->{paths}}) {
		$config->{paths}->{$path}	=		$config->{here_path}.'/'.$config->{paths}->{$path};
		if (! -d $config->{paths}->{$path}) {
			print <<END;
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Path "$path" does not exist at 
    $config->{paths}->{$path}
Dying on the spot ...

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END
	
		}
	}
	
	return $config;
	
}

################################################################################
################################################################################

sub _create_file_paths {

=podmd
Paths for the output files are created from the pre-generated directory paths 
and variables (class, parent directory name) which are extracted from the full 
path of the input file.

The web file for the Jekyll / GH-pages processing gets a prefix, to ensure that
auto-generated and normal pages can be separated.

=cut

	my ($config, $file_path)	=		@_;
	my @pathEls		=		split('/', $file_path);
	my $fileName	=		pop @pathEls;
	my $dirName		=		pop @pathEls;
	
	my $class			=		$fileName;
	$class				=~	s/\.\w+?$//;
	return		{
		input_yaml	=>	$file_path,
		input_name	=>	$fileName,
		input_class	=>	$class,
		input_dir		=>	$dirName,
		exmpls_json => 	join('/', 
											@pathEls,
											$config->{paths}->{examples_dir},
											$class.'-examples.json'
										),
		plain_md		=>	join('/', 
											@pathEls,
											$config->{paths}->{md_dir},
											$class.'.md'
										),
		src_json 		=>	join('/', 
											@pathEls,
											$config->{paths}->{json_dir},
											$class.'.json'
										),
		web_src_json =>	join('/', 
											$config->{paths}->{md_web_schemas_rel},
											$class.'.json'
										),
		jekyll_md 	=> 	join('/', 
											$config->{paths}->{md_web_doc_rel},
											$config->{generator_prefix}.$class.'.md'
										)
	};

}

################################################################################
################################################################################

sub _check_class_name {

	my ($file_name, $class)	=	@_;
	
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

sub _delete_generated_files { 

	my $config		=		shift;

	if ($config->{args}->{-cleanup} !~ /^1|^y/i) { return }

	foreach my $dir (grep{ /_rel/} keys %{$config->{paths}}) {
		if ($config->{generator_prefix} =~ /.../) {
			my $delCMD  =   'rm '.$config->{paths}->{$dir}.'/'.$config->{generator_prefix}.$config->{args}->{-filter}.'*';
			print $delCMD."\n";
			`$delCMD`;
		}
	}

}

################################################################################
################################################################################

sub _process_input_dirs {

	my $config		=		shift;

	foreach my $src_dir (@{ $config->{paths}->{'src_dirs'} }) {
		opendir DIR, $config->{here_path}.'/'.$src_dir;
		foreach (grep{ /ya?ml$/ } readdir(DIR)) {
			_process_yaml(
				$config,
				join('/', 
					$config->{here_path},
					$src_dir,
					$_
				),
				$_
			);
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
	my $class			=		shift;
	return 	<<END;
---
title: '$class'
layout: default
permalink: "$config->{paths}->{md_web_doc_link}/$class.html"
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

