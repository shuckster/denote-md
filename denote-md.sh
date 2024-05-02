#!/bin/bash

if test "$1" = "env"
then
  echo "DENOTE_MD_SCRIPT_PATH=$0"
  echo "DENOTE_MD_NOTES_PATH=$DENOTE_MD_NOTES_PATH"
  exit
fi

enable_colors="false"
if test "$1" = "-g"
then
  enable_colors="true"
  shift
fi

handle_help ()
{
  if test "$1" = ""
  then
echo "
-=[ denote-md 1.1.0 ]=--------------------------------------------------------

Denote was written by Protesilaos Stavrou and is documented here:
- https://protesilaos.com/emacs/denote

This script, denote-md, implements Denote in its Markdown-with-YAML
front-matter variant only, with a couple of extra features that the author
finds personally useful. It was written by Conan Theobald.

There is a companion Vim plugin available.
- https://github.com/shuckster/denote-md
- https://github.com/shuckster/vim-denote-md

------------------------------------------------------------------------------
The following commands are available:
"
  fi
  echo -n "Usage: ${0} "

  case $1 in
# ==============================================================================
# GET FILENAME/TITLE
# ==============================================================================
    "get filename")
      echo "$1 [identifier]

Return the filename of the note for the given identifier, eg;

  $ $0 get filename 20231206T114112
  20231206T114112--my-note__tag1_tag2.md
"
      ;;
    "get title")
      echo "$1 note.md

Return the title in the frontmatter of the note, eg;

  $ $0 get title 20231206T114112--my-note__tag1_tag2.md
  My Note
"
      ;;

# ==============================================================================
# REPLACE TITLE/TAGS
# ==============================================================================
    "replace tags")
      echo "$1 [new_tags] *.md

Replace the tags in the frontmatter of the given files, eg;

  $ $0 replace tags tag1,tag2 *.md
  20231206T114112--my-note__tag1_tag2.md

This command accepts globs, so be careful. It returns a list of notes with
their newly updated filenames.
"
      ;;
    "replace title")
      echo "$1 [new_title] *.md

Replace the title in the frontmatter of the given files, eg;

  $ $0 replace title \"My New Title\" *.md

This command accepts globs, so be careful. It returns a list of notes with
their newly updated filenames.
"
      ;;

# ==============================================================================
# LIST THINGS UNDER A HEADING
# ==============================================================================
    "list heading")
      echo "$1 [tags]

List everything under the specified heading, eg;

  $ $0 list heading Summary tag1,-tag2
  20231206T114112--my-note-1__tag1.md
  A summary you wrote under the heading you specified.

All lines under an '# Summary' heading, up until the next line starting with
'#' or End-of-File.
"
      ;;

# ==============================================================================
# LIST ACTIONS/BACKLINKS
# ==============================================================================
    "list actions")
      echo "$1 [tags]

List all actions in the given notes, eg;

  $ $0 list actions tag1,-tag2
  20231206T114112--my-note-1__tag1.md
  - [ ] Action 1
  - [ ] Action 2

Actions are all lines under an '# Actions' heading, up until the next line
starting with '#' or End-of-File.

Essentially an alias for 'list heading Actions'
"
      ;;
    "list backlinks")
      echo "$1 note.md

List all notes that link back to the given note, eg;

  $ $0 list backlinks 20231206T114112--my-note__metanote.md
  20231206T114112--my-note-1__tag1.md
  20231206T114112--my-note-2__tag2.md

Links look like this: [[denote:20231206T114112]]
"
      ;;

# ==============================================================================
# ADD/REMOVE/RENAME TAG
# ==============================================================================
    "add tag")
      echo "$1 [tag] *.md

Add the given tag to the frontmatter of the given files, returning the name
of the new file, eg;

  $ $0 add tag tag3 *.md
  20231206T114112--my-note__tag1_tag2_tag3.md

This command accepts globs, so be careful. It returns a list of notes with
their newly updated filenames.
"
      ;;
    "remove tag")
      echo "$1 [tag] *.md

Remove the given tag from the frontmatter of the given files, eg;

  $ $0 remove tag tag1 *.md

This command accepts globs, so be careful. It returns a list of notes with
their newly updated filenames.
"
      ;;
    "rename tag")
      echo "$1 [tag] [new_name] *.md

Rename the given tag in the frontmatter of the given files, eg;

  $ $0 rename tag oldtag newtag *.md

This command accepts globs, so be careful. It returns a list of notes with
their newly updated filenames.
"
      ;;
# ==============================================================================
# REFRESH FILENAME
# ==============================================================================
    "refresh")
      echo "$1 *.md

Refresh the filenames of the given files to match the title and tags in the
frontmatter, eg;

  $ $0 refresh *.md

This command accepts globs, so be careful. It returns a list of notes with
their newly updated filenames.
"
      ;;

# ==============================================================================
# SHOW ALL HELP
# ==============================================================================
    *)
      echo "[-g] <command> [<args>]
  new                 [tags] [title]
  get      filename   [identifier]
  get      title      note.md
  replace  title      [new_title] *.md

  list     tags       [*.md]
  list     notes      [tags]
  list     recent     [num_notes]
  list     backlinks  note.md
  list     heading    [heading] [tags]
  list     actions    [tags]

  add      tag        [tag] *.md
  remove   tag        [tag] *.md
  rename   tag        [tag] [new_name] *.md
  replace  tags       [new_tags] *.md

  refresh             *.md

  env                 Print environment variables

Prefixing a command with -g will enable colour for any printed filename.

Except for 'new', commands with missing arguments will print help and an
example for that command. The 'new' command will prompt for missing arguments.

No command is confirmed before being executed, so please use in combination
with version control. You have been warned.
"
      ;;
  esac
}

main ()
{
  local cmd=$1
  shift
  case $cmd in
    new) handle_new_note $@;;
    add) handle_add_tag $@;;
    remove) handle_remove_tag $@;;
    rename) handle_rename_tag $@;;
    replace) handle_replace "$@";;
    refresh) handle_refresh_filename $@;;
    list) handle_list $@;;
    get) handle_get $@;;
    *) handle_help $@;;
  esac
}

handle_new_note ()
{
  local tags="$(prompt_when_no_value "Enter tags (comma-separated): " "$1")"
  shift
  local title="$(prompt_when_no_value "Enter title: " "$@")"
  local new_fm="$(new_frontmatter)"
  new_fm="$(update_title_in_frontmatter "$new_fm" "$title")"
  new_fm="$(update_tags_in_frontmatter "$new_fm" "$tags")"
  local filename="$(filename_from_frontmatter "$new_fm")"
  echo "$new_fm

" > "${DENOTE_MD_NOTES_PATH}${filename}"
  print_note_name "$filename"
}

#
# ADD/REMOVE/RENAME TAGS
#

handle_add_tag ()
{
  if test "$1" != "tag"
  then
    handle_help "add tag"
    return
  fi
  if test "$2" = ""
  then
    handle_help "add tag"
    return
  fi
  local tag_to_add="$2"
  shift 2
  process_files_from_stdin_or_args "$@" | while read file
  do
    local fm="$(frontmatter_from_file "$file")"
    local tags="$(tags_from_frontmatter "$fm")"
    local new_tags="$(tags_with_tag "$tags" "$tag_to_add")"
    local new_fm="$(update_tags_in_frontmatter "$fm" "$new_tags")"
    local note_content="$(file_without_frontmatter "$file")"
    local filename="$(filename_from_frontmatter "$new_fm")"
    echo "$new_fm" > "$file"
    echo "$note_content" >> "$file"
    mv "$file" "$filename"
    print_note_name "$filename"
  done
}

handle_remove_tag ()
{
  if test "$1" != "tag"
  then
    handle_help "remove tag"
    return
  fi
  if test "$2" = ""
  then
    handle_help "remove tag"
    return
  fi
  local tag_to_remove="$2"
  shift 2
  process_files_from_stdin_or_args "$@" | while read file
  do
    local fm="$(frontmatter_from_file "$file")"
    local tags="$(tags_from_frontmatter "$fm")"
    local new_tags="$(tags_without_tag "$tags" "$tag_to_remove")"
    local new_fm="$(update_tags_in_frontmatter "$fm" "$new_tags")"
    local note_content="$(file_without_frontmatter "$file")"
    local filename="$(filename_from_frontmatter "$new_fm")"
    echo "$new_fm" > "$file"
    echo "$note_content" >> "$file"
    mv "$file" "$filename"
    print_note_name "$filename"
  done
}

handle_rename_tag ()
{
  if test "$1" != "tag"
  then
    handle_help "rename tag"
    return
  fi
  if test "$2" = ""
  then
    handle_help "rename tag"
    return
  fi
  local tag_to_rename="$2"
  local new_tag_name="$3"
  shift 3
  process_files_from_stdin_or_args "$@" | while read file
  do
    local fm="$(frontmatter_from_file "$file")"
    local tags="$(tags_from_frontmatter "$fm")"
    local new_tags="$(tags_without_tag "$tags" "$tag_to_rename")"
    if test "$tags" = "$new_tags"
    then
      continue
    fi
    new_tags="$(tags_with_tag "$new_tags" "$new_tag_name")"
    local new_fm="$(update_tags_in_frontmatter "$fm" "$new_tags")"
    local note_content="$(file_without_frontmatter "$file")"
    local filename="$(filename_from_frontmatter "$new_fm")"
    echo "$new_fm" > "$file"
    echo "$note_content" >> "$file"
    mv "$file" "$filename"
    print_note_name "$filename"
  done
}

#
# REPLACE TITLE/TAGS
#

handle_replace ()
{
  local cmd="$1"
  local arg="$2"
  local maybe_file="$3"
  case $cmd in
    title) handle_replace_title "$arg" "$maybe_file";;
    tags) handle_replace_tags "$arg" "$maybe_file";;
    *) handle_help "replace";;
  esac
}

handle_replace_title ()
{
  if test "$2" = ""
  then
    handle_help "replace title"
    return
  fi
  local new_title="$1"
  local file="$2"
  local fm="$(frontmatter_from_file "$file")"
  local title="$(title_from_frontmatter "$fm")"
  local new_fm="$(update_title_in_frontmatter "$fm" "$new_title")"
  local note_content="$(file_without_frontmatter "$file")"
  local filename="$(filename_from_frontmatter "$new_fm")"
  echo "$new_fm" > "$file"
  echo "$note_content" >> "$file"
  mv "$file" "$filename"
  print_note_name "$filename"
}

handle_replace_tags ()
{
  if test "$2" = ""
  then
    handle_help "replace tags"
    return
  fi
  local new_tags="$1"
  local file="$2"
  local fm="$(frontmatter_from_file "$file")"
  local tags="$(tags_from_frontmatter "$fm")"
  local new_fm="$(update_tags_in_frontmatter "$fm" "$new_tags")"
  local note_content="$(file_without_frontmatter "$file")"
  local filename="$(filename_from_frontmatter "$new_fm")"
  echo "$new_fm" > "$file"
  echo "$note_content" >> "$file"
  mv "$file" "$filename"
  print_note_name "$filename"
}

#
# REFRESH FILENAME
#

handle_refresh_filename ()
{
  if test "$1" = ""
  then
    handle_help "refresh"
    return
  fi
  process_files_from_stdin_or_args "$@" | while read file
  do
    local fm="$(frontmatter_from_file "$file")"
    local title="$(title_from_frontmatter "$fm")"
    local tags="$(tags_from_frontmatter "$fm")"
    local new_fm="$(update_title_in_frontmatter "$fm" "$title")"
    new_fm="$(update_tags_in_frontmatter "$new_fm" "$tags")"
    local filename="$(filename_from_frontmatter "$new_fm")"
    if test "$filename" != "$file"
    then
      local note_content="$(file_without_frontmatter "$file")"
      echo "$new_fm" > "$file"
      echo "$note_content" >> "$file"
      mv "$file" "$filename"
      file="$filename"
      print_note_name "$file"
    fi
  done
}

#
# LIST
#

handle_list ()
{
  local subcommand="$1"
  shift
  case $subcommand in
    tags) handle_list_all_tags $@;;
    notes) handle_list_notes_for_tags $@;;
    recent) handle_list_recent_notes $@;;
    backlinks) handle_list_backlinks $@;;
    heading) handle_list_heading $@;;
    actions) handle_list_actions $@;;
    *) handle_help "list";;
  esac
}

handle_list_all_tags ()
{
  local files=$(process_files_from_stdin_or_args "$@")
  if test "$files" = ""
  then
    files=$(ls ${DENOTE_MD_NOTES_PATH}*.md)
  fi
  local tags=""
  local next_tags
  for file in "${files[@]}"
  do
    if test "$tags" != ""
    then
     tags="$tags,"
    fi
    next_tags="$(tags_from_filename "$file")"
    tags="$tags${next_tags/[$'\t\r\n']/,}"
  done
  local tag_list="$(echo "${tags/[$'\t\r\n,']/,}" | tr ',' '\n' | sort -u)"
  let count=0
  for tag in $tag_list;
  do
    if test $count -gt 0
    then
      echo -n ", "
    fi
    : $((count+=1))
    echo -n "$tag"
  done
  echo -e "${NO_COLOR}"
}

handle_list_notes_for_tags ()
{
  local tags="$1"
  shift
  for file in $(ls ${DENOTE_MD_NOTES_PATH}*.md)
  do
    if test "$tags" = ""
    then
      print_note_name "$file"
      continue
    fi
    if filename_matches_tags "$file" "$tags"
    then
      print_note_name "$file"
    fi
  done
}

handle_list_recent_notes ()
{
  local num_notes=5
  if [[ "$1" =~ ^[0-9]+$ ]]
  then
    num_notes="$1"
    shift
  fi
  local files=$(ls -t ${DENOTE_MD_NOTES_PATH}*.md | head -n "$num_notes")
  for file in "${files[@]}"
  do
    print_note_name "$file"
  done
}

handle_list_backlinks ()
{
  if test "$1" = ""
  then
    handle_help "list backlinks"
    return
  fi
  local input_file="$1"
  local identifier=$(identifier_from_filename "$input_file")
  local search_pattern="[[denote:$identifier]]"
  # Use grep to search all markdown files for the pattern, excluding the input file
  grep -lF "$search_pattern" ${DENOTE_MD_NOTES_PATH}*.md | \
  grep -v "$identifier" | \
  while read -r file
  do
    print_note_name "$file"
  done
}

handle_list_heading ()
{
  if test "$1" = "" || test "$2" = ""
  then
    handle_help "list heading"
    return
  fi
  local heading="${1:-Actions}"
  local tags="$2"
  local _enable_colors="$enable_colors"
  enable_colors="false"
  local notes_for_tags
  notes_for_tags=$(handle_list_notes_for_tags "$tags")
  enable_colors="$_enable_colors"
  for file in $notes_for_tags
  do
    print_note_name "$file"
    awk '
      /^# '"${heading}"'/ { flag=1; next; }
      /^#/ { if (flag) print ""; exit; }
      flag && NF { print; }
      END { print ""; }
    ' "$file"
  done
}

handle_list_actions ()
{
  if test "$1" = ""
  then
    handle_help "list actions"
    return
  fi
  handle_list_heading "Actions" "$1" 
}

#
# GET
#

handle_get ()
{
  local subcommand="$1"
  shift
  case $subcommand in
    filename) handle_get_filename $@;;
    title) handle_get_title $@;;
    *) handle_help "get";;
  esac
}

handle_get_filename ()
{
  if test "$1" = ""
  then
    handle_help "get filename"
    return
  fi
  local identifier="$1"
  local file=$(ls ${DENOTE_MD_NOTES_PATH}*.md | grep "$identifier")
  print_note_name "$file"
}

handle_get_title ()
{
  if test "$1" = ""
  then
    handle_help "get title"
    return
  fi
  local file="$1"
  local fm="$(frontmatter_from_file "$file")"
  local title="$(title_from_frontmatter "$fm")"
  echo "$title"
}

#
# UTILS
#

# FILES

process_files_from_stdin_or_args ()
{
  if test -t 0
  then
    # No stdin, so process args
    for file in "$@"
    do
      echo "$file"
    done
  else
    # Read from stdin
    while read file
    do
      echo "$file"
    done
  fi
}

# FRONTMATTER

frontmatter_from_file ()
{
  local file=$1
  awk '
    /^---$/ { flag=!flag; print; next; }
    flag { print; }
    !flag { exit; }
  ' "$file"
}

file_without_frontmatter ()
{
  local file=$1
  awk '
    /^---$/ {
      if (outside_frontmatter) { print; next; }
      if (flag) { outside_frontmatter=1; }
      flag=!flag;
      next;
    }
    outside_frontmatter {
      print;
    }
  ' "$file"
}

new_frontmatter ()
{
  identifier=$(date -u +"%Y%m%dT%H%M%S")
  current_datetime=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  echo "---
identifier: \"$identifier\"
date: $current_datetime
tags: [ ]
title: \"\"
---
"
}

# EXTRACT FROM FRONTMATTER

identifier_from_frontmatter ()
{
  local frontmatter="$1"
  echo "$frontmatter" | awk '
    /^---$/ {
      flag=!flag; next;
    }
    /^identifier:/ && flag {
      gsub(/^identifier: *|"/, "");
      print;
      exit;
    }
  '
}

tags_from_frontmatter ()
{
  local frontmatter="$1"
  echo "$frontmatter" | awk '
    /^---$/ {
      flag=!flag; next;
    }
    /^tags:/ && flag {
      gsub(/^tags: *\[|\]$/, "");
      gsub(/[" ]/, "");
      gsub(/,/, ", ");
      print;
      exit;
    }
  '
}

title_from_frontmatter ()
{
  local frontmatter="$1"
  echo "$frontmatter" | awk '
    /^---$/ {
      flag=!flag; next;
    }
    /^title:/ && flag {
      gsub(/^title: *"|"$/, "");
      print;
      exit;
    }
  '
}

# UPDATE FRONTMATTER

update_title_in_frontmatter ()
{
  local frontmatter="$1"
  local new_title="$2"
  echo "$frontmatter" | awk -v new_title="$new_title" '
    /^---$/ {
      flag=!flag;
      print;
      next;
    }
    /^title:/ && flag {
      print "title: \"" new_title "\"";
      next;
    }
    flag { print; }
  '
}

update_tags_in_frontmatter ()
{
  local frontmatter="$1"
  local new_tags="$2"
  echo "$frontmatter" | awk -v new_tags="$new_tags" '
    BEGIN {
      gsub(/[[:alnum:]-]+/, "\"&\"", new_tags);
      gsub(/[ ,]+/, ", ", new_tags);
    }
    /^---$/ {
      flag=!flag; print; next;
    }
    /^tags:/ && flag {
      print "tags: [ " new_tags " ]";
      next;
    }
    flag { print; }
  '
}

# FILENAME

to_lower_kebab_case()
{
  local frontmatter="$1"
  echo "$frontmatter" | awk '
    {
      $0 = tolower($0);
      gsub(/[^a-z0-9]+/, "-");
      print;
    }
  '
}

tags_with_underscores ()
{
  local tags="$1"
  echo "$tags" | awk -v tags="$tags" '
    BEGIN {
      gsub(/[ ,]+/, "_", tags);
    }
    { print tags; }
  '
}

filename_from_frontmatter ()
{
  local frontmatter="$1"
  local identifier="$(identifier_from_frontmatter "$frontmatter")"
  local tags="$(tags_from_frontmatter "$frontmatter")"
  local title="$(title_from_frontmatter "$frontmatter")"
  local file_part="$(to_lower_kebab_case "$title")"
  local tags_part="$(tags_with_underscores "$tags")"
  echo "${identifier}--${file_part}__${tags_part}.md"
}

tags_from_filename ()
{
  local filename="$1"
  echo "$filename" | awk '
    {
      gsub(/^[^_]*__/, "");
      gsub(/\.md$/, "");
      gsub(/_/, ",");
      print;
    }
  '
}

identifier_from_filename ()
{
  local filepath="$1"
  local filename=$(basename "$filepath")
  echo "${filename%%--*}"
}

# TAGS

tags_without_tag ()
{
  local tag_list="$1"
  local tag_to_remove="$2"
  echo "$tag_list" | awk -v tag="$tag_to_remove" -v OFS=", " '
    BEGIN {
      FS = "[ ,]+";
      first = 1;
    }
    {
      for (i = 1; i <= NF; i++) {
        if ($i != tag) {
          if (first) {
            first = 0;
          } else {
            printf("%s", OFS);
          }
          printf("%s", $i);
        }
      }
      atLeastOneTagPrinted = first == 0;
      if (atLeastOneTagPrinted) {
        print "";
      }
    }'
}

tags_with_tag ()
{
  local tag_list="$1"
  local new_tag="$2"
  echo "$tag_list" | awk -v tag="$new_tag" -v OFS=", " '
    BEGIN {
      FS = "[ ,]+";
      tagAdded = 0;
    }
    {
      for (i = 1; i <= NF; i++) {
        printf("%s%s", (i > 1 ? OFS : ""), $i);
        if ($i == tag) {
          tagAdded = 1;
        }
      }
      addTagToEndOfList = tagAdded == 0;
      if (addTagToEndOfList) {
        printf("%s%s", (NF > 0 ? OFS : ""), tag);
      }
      print "";
    }
  '
}

filename_has_tag()
{
  local file=$1
  local tag=$2
  grep -q "_${tag}[_.]" <<< "$file"
}

# Function to check if a file contains all of
# the given tags and none of the -excluded tags
filename_matches_tags()
{
  local file=$1
  shift
  local tags="${@}"
  local tag
  for tag in ${tags//,/ }
  do
    # check if tag begins with a hyphen
    if test "${tag:0:1}" = "-"
    then
      # This is an exclusion tag, remove the leading hyphen
      tag="${tag#-}"
      if filename_has_tag "$file" "$tag"
      then
        return 1
      fi
    else
      # This is a regular tag, check for its presence
      if ! filename_has_tag "$file" "$tag"
      then
        return 1
      fi
    fi
  done
  return 0
}

# PROMPT

prompt_when_no_value ()
{
  local prompt_message="$1"
  shift
  if test "$1" != ""
  then
    echo "$@"
    return
  fi
  local input
  read -e -p "$prompt_message" input
  echo "$input"
}

LIGHT_BLUE=""
WHITE=""
YELLOW=""
NO_COLOR=""

if test "$enable_colors" = "true"
then
  LIGHT_BLUE="\033[1;94m"
  WHITE="\033[1;97m"
  YELLOW="\033[1;93m"
  NO_COLOR="\033[0m"
  trap 'echo -e "${NO_COLOR}"; exit' SIGINT
fi

# PRINT

print_note_name ()
{
  IFS=$'\n' read -r -d '' -a lines <<< "$@"
  for input_string in "${lines[@]}"
  do
    if test "$enable_colors" = "false"
    then
      local prefix="${DENOTE_MD_NOTES_PATH}"
      [[ $input_string != $prefix* ]] && input_string="${prefix}${input_string}"
      echo "$input_string"
      continue
    fi
    local identifier_regex='([0-9]{8}T[0-9]{6})--'
    local identifier
    if [[ $input_string =~ $identifier_regex ]]
    then
        local identifier=${BASH_REMATCH[1]}
    else
        echo "$input_string"
        continue
    fi
    local rest=${input_string#*--}
    local title=${rest%%__*}
    local tags_with_ext=${rest#*__}
    local tags=${tags_with_ext%.md}
    echo -e "${DENOTE_MD_NOTES_PATH}${LIGHT_BLUE}${identifier}${NO_COLOR}--${WHITE}${title}${NO_COLOR}__${YELLOW}${tags}.md${NO_COLOR}"
  done
}

#
# MAIN
#

main "$@"
