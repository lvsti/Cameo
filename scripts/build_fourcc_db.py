#!/usr/bin/env python

import os
import re
import json

fourcc_regex = re.compile("((?:kCMIO|kCMPixelFormat|kCMVideoCodecType|kIOAudioDeviceTransportType)[^\s]+?)\s*=\s*'(....)',?", re.S)

def generate_source(source_path):
	outfile = open(source_path, "w")
	outfile.write("""
		#include <CoreMedia/CMFormatDescription.h>
		#include <CoreMediaIO/CMIOHardware.h>
		#include <IOKit/audio/IOAudioTypes.h>
	""")
	outfile.close()

def clean_up_source(source_path):
	os.remove(source_path)

def clean_up_preprocessed(preprocessed_path):
	os.remove(preprocessed_path)

def preprocess_source(source_path, preprocessed_path):
	return os.popen("/usr/bin/clang -E %s -o %s" % (source_path, preprocessed_path)).read()

def parse_fourccs(preprocessed_path):
	infile = open(preprocessed_path, "r")
	infile_contents = infile.read()
	infile.close()

	matches = fourcc_regex.finditer(infile_contents)

	entries = []

	for match in matches:
		fcc = match.group(2)
		raw_value = (ord(fcc[0]) << 24) | (ord(fcc[1]) << 16) | (ord(fcc[2]) << 8) | ord(fcc[3])
		entries.append({"fourCC": fcc, "rawValue": raw_value, "constantName": match.group(1)})

	return entries

def dump_fourcc_db(entries):
	print json.dumps(entries)


src_path = "fourcc.c"
preprocessed_path = "fourcc.i"

generate_source(src_path)
preprocess_source(src_path, preprocessed_path)
clean_up_source(src_path)
entries = parse_fourccs(preprocessed_path)
clean_up_preprocessed(preprocessed_path)
dump_fourcc_db(entries)
