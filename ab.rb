#! /usr/local/rvm/bin/ruby

require 'xcodeproj'

def checkout_classes(files, branch_name)
  files.each do |file_original|
    `git checkout #{branch_name} -- #{file_original}.h #{file_original}.m`
    `git reset HEAD #{file_original}.h #{file_original}.m` # we don't want this files to be staged
  end
end

def branchize_classes(files, branch_name, proj)
  files.each do |file_original|
    parts = file_original.split('/')
    class_original = parts.pop()
    class_name = "#{branch_name}_#{class_original}"
    parts.push(class_name)
    filename = parts.join('/')
    `mv #{file_original}.m #{filename}.m`
    `mv #{file_original}.h #{filename}.h`
    # inside the renamed files we find and replace to update name # sed -i 's/old-name/new-name/g' $filename
    `sed -i "" 's/#{class_original}/#{class_name}/g' #{filename}.m`
    `sed -i "" 's/#{class_original}/#{class_name}/g' #{filename}.h`
    add_new_source("#{filename}.m", proj)
    add_new_header("#{filename}.h", proj)
  end
end

def substitute_classes(files, branches)
  files.each do |file|
    class_name = file.split('/').last
    # create file.h + file.m from selector template
    header = File.new("#{file}.h", "w")
header.puts(%Q{
#import "ABClassSelector.h"
@interface ABViewController : ABClassSelector
@end
})
    header.close()
    imp = File.new("#{file}.m", "w")
    classes = branches.map { |b| "[#{b}_#{class_name} class]" }
    imports = branches.map { |c| "\#import \"#{c}_#{class_name}.h\""  }
    imp.puts(%Q{
#import "#{class_name}.h"
#{imports.join("\n")}

@implementation #{class_name}
+ (NSArray *)classes
{
    return [NSArray arrayWithObjects:#{classes.join(", ")}, nil];
}
@end
})
    imp.close()
  end
end

def get_conflicting_classes(branches)
  files = `git diff --name-status #{branches[0]}..#{branches[1]}`.split('\n').map { |f| f[2..-2] }
  # remove any files that are not .m. The main case is to exclude .h files

  class_files = []
  files.each do |file|
    class_files.push(file[0..-3]) if file[-2..-1] == ".m"
  end

  return class_files
end

def add_new_source(filename, proj)
  target = proj.targets.first
  build_phase = target.source_build_phase
  build_phase.add_file_reference(proj.new_file(filename, "ABExample"))
end

def add_new_header(filename, proj)
  target = proj.targets.first
  build_phase = target.headers_build_phase
  build_phase.add_file_reference(proj.new_file(filename, "ABExample"))
end

branches = ARGV[0..2]
`git checkout #{branches[0]}`
new_branch = "AB-#{branches[0]}+#{branches[1]}"
# `git checkout -b #{newbranch}`

proj = Xcodeproj::Project.new('ABExample.xcodeproj')
class_files = get_conflicting_classes(branches)

branchize_classes(class_files, branches[0], proj)
checkout_classes(class_files, branches[1])
branchize_classes(class_files, branches[1], proj)
substitute_classes(class_files, branches)
# TODO: add new files to compile list

proj.save_as('ABExample.xcodeproj')
