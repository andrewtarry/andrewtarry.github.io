#!/usr/bin/env bash
#
# Create HTML pages for Categories and Tags in posts.
#
# Usage:
#     Call from the '_posts' sibling directory.
#
# v2.2
# https://github.com/cotes2020/jekyll-theme-chirpy
# © 2020 Cotes Chung
# Published under MIT License

set -eu

TYPE_CATEGORY=0
TYPE_TAG=1

category_count=0
tag_count=0


_read_yaml() {
  local _endline=$(grep -n "\-\-\-" $1 | cut -d: -f 1 | sed -n '2p')
  head -$_endline $1
}


read_categories() {
  local _yaml=$(_read_yaml $1)
  local _categories=$(echo "$_yaml" | grep "^categories:")
  local _category=$(echo "$_yaml" | grep "^category:")

  if [[ ! -z "$_categories" ]]; then
    echo "$_categories" | sed "s/categories: *//;s/\[//;s/\]//;s/, */,/g;s/\"//g;s/'//g"
  elif [[ ! -z "_category" ]]; then
    echo "$_category" | sed "s/category: *//;s/\[//;s/\]//;s/, */,/g;s/\"//g;s/'//g"
  fi
}


read_tags() {
  local _yaml=$(_read_yaml $1)
  echo "$_yaml" | grep "^tags:" | sed "s/tags: *//;s/\[//;s/\]//;s/, */,/g;s/\"//g;s/'//g"
}


init() {
  if [[ -d categories ]]; then
    rm -rf categories
  fi

  if [[ -d tags ]]; then
    rm -rf tags
  fi

  mkdir categories tags
}


create_category() {
  local _name=$1
  local _filepath="categories/$(echo $_name | sed 's/ /-/g' | awk '{print tolower($0)}').html"

  if [[ ! -f $_filepath ]]; then
    echo "---" > $_filepath
    echo "layout: category" >> $_filepath
    echo "title: $_name" >> $_filepath
    echo "category: $_name" >> $_filepath
    echo "---" >> $_filepath

    ((category_count=category_count+1))
  fi
}


create_tag() {
  local _name=$1
  local _filepath="tags/$( echo $_name | sed "s/ /-/g;s/'//g" | awk '{print tolower($0)}' ).html"

  if [[ ! -f $_filepath ]]; then

    echo "---" > $_filepath
    echo "layout: tag" >> $_filepath
    echo "title: $_name" >> $_filepath
    echo "tag: $_name" >> $_filepath
    echo "---" >> $_filepath

    ((tag_count=tag_count+1))
  fi
}


#########################################
# Create HTML pages for Categories/Tags.
# Arguments:
#   $1 - an array string
#   $2 - type specified option
#########################################
create_pages() {
  if [[ $1 == '' ]]; then
    exit 0
  fi

  # split string to array
  IFS_BAK=$IFS
  IFS=','
  local _string=$1

  case $2 in

    $TYPE_CATEGORY)
      for i in ${_string#,}; do
        create_category $i
      done
      ;;

    $TYPE_TAG)
      for i in ${_string#,}; do
        create_tag $i
      done
      ;;

    *)
      ;;

    esac

    IFS=$IFS_BAK
  }


main() {
  init

  for _file in $(ls "_posts")
  do
    local _path="_posts/$_file"
    local _categories=$(read_categories "$_path")
    local _tags=$(read_tags "$_path")

    create_pages "$_categories" $TYPE_CATEGORY
    create_pages "$_tags" $TYPE_TAG
  done

  if [[ $category_count -gt 0 ]]; then
    echo "[INFO] Succeed! $category_count category-pages created."
  fi

  if [[ $tag_count -gt 0 ]]; then
    echo "[INFO] Succeed! $tag_count tag-pages created."
  fi
}

main
