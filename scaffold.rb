begin
  require 'nokogiri'
rescue LoadError
  puts "============ note ============="
  puts "Looks like you don't have nokogiri installed. Nokogiri is used to help you quickly scaffold models, view and controllers:" 
  puts "You *DO NOT* need scaffolding for the Oak interactive tutorial, or any development (just a nice to have)"
  puts "So don't worry about this note if you don't want scaffolding"
  puts "Instructions for setting up nokogiri (one time):"
  puts "  - Install chocolatey by running the powershell script located at chocolatey.org" 
  puts "  - After chocolatey is installed, run the command: cinst ruby.devkit (if you haven't installed ruby's DevKit)" 
  puts "  - Then run the command 'gem install nokogiri'"
  puts "  - Type 'rake -D gen' for more information on scaffolding (the source located in scaffold.rb)."
  puts "================================"
  puts ""
end

namespace :gen do
  desc "adds a dynamic model class to your mvc project, example: rake gen:model[Blog]"
  task :model, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, example: rake gen:model[Blog]" if args[:name].nil?

    verify_file_name args[:name]

    folder "Models"
    
    save model_template(args[:name]), "#{@mvc_project_directory}/Models/#{args[:name]}.cs"

    add_compile_node :Models, args[:name]
  end

  desc "adds a dynamic repository class to your mvc project, example: rake gen:repo[Blogs]"
  task :repo, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, example: rake gen:repository[Blogs]" if args[:name].nil?

    verify_file_name args[:name]

    folder "Repositories"

    save repo_template(args[:name]), "#{@mvc_project_directory}/Repositories/#{args[:name]}.cs"

    add_compile_node :Repositories, args[:name]
  end

  desc "adds a dynamic repository with a projection to a dynamic model, example: rake gen:repo_model[Blogs:Blog]"
  task :repo_model, [:repo_and_model_name] => :rake_dot_net_initialize do |t, args|
    repo = args[:repo_and_model_name].split(':').first
    model = args[:repo_and_model_name].split(':').last

    raise "repostiory and model name required, example: rake gen:repo_model[Blogs:Blog]" if args[:repo_and_model_name].split(':').count == 1

    verify_file_name repo
    verify_file_name model

    folder "Models"
    
    save model_template(model), "#{@mvc_project_directory}/Models/#{model}.cs"

    add_compile_node :Models, model

    folder "Repositories"

    save projection_repo_template(repo, model), "#{@mvc_project_directory}/Repositories/#{repo}.cs"

    add_compile_node :Repositories, repo
  end

  desc "adds a controller class to your mvc project, example: rake gen:controller[Blogs]"
  task :controller, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, example: rake gen:controller[Blogs]" if args[:name].nil?

    verify_file_name args[:name]

    folder "Controllers"

    controller_name = args[:name] + "Controller"

    save controller_template(controller_name), "#{@mvc_project_directory}/Controllers/#{controller_name}.cs"

    add_compile_node :Controllers, controller_name
  end

  desc "adds a cshtml to your mvc project, example: rake gen:view[Home:Index]"
  task :view, [:controller_and_view_name] => :rake_dot_net_initialize do |t, args|
    controller = args[:controller_and_view_name].split(':').first
    name = args[:controller_and_view_name].split(':').last

    raise "controller and view name required, example: rake gen:view[Home:Index]" if args[:controller_and_view_name].split(':').count == 1

    verify_file_name controller
    verify_file_name name

    folder "Views/#{controller}"

    save view_template(name), "#{@mvc_project_directory}/Views/#{controller}/#{name}.cshtml"

    add_cshtml_node controller, name
  end

  desc "adds javascript file to your mvc project, example: rake gen:script[index]"
  task :script, [:name] => :rake_dot_net_initialize do |t, args|
    raise "js name required, example: rake gen:script[index]" if args[:name].nil?

    verify_file_name args[:name]

    folder "Scripts/app"

    save js_template(args[:name]), "#{@mvc_project_directory}/Scripts/app/#{args[:name]}.js"

    add_js_node args[:name]
  end

  desc "adds a test file to your test project, example: rake gen:test[describe_BlogsController]"
  task :test, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, example: rake gen:test[decribe_HomeController]" if args[:name].nil?

    verify_file_name args[:name]

    save test_template(args[:name]), "#{@test_project}/#{args[:name]}.cs"

    add_compile_node :root, args[:name], "#{@test_project}/#{@test_project}.csproj"
  end

  def save content, file_path
    raise "#{file_path} already exists, cancelling" if File.exists? file_path

    File.open(file_path, "w") { |f| f.write(content) }
  end

  def folder dir
    FileUtils.mkdir_p "./#{@mvc_project_directory}/#{dir}/"
  end

  def add_compile_node folder, name, project = nil
    to_open = project || proj_file
    doc = Nokogiri::XML(open(to_open))
    if folder == :root
      add_include doc, :Compile, "#{name}.cs"
    else
      add_include doc, :Compile, "#{folder.to_s}\\#{name}.cs"
    end
    File.open(to_open, "w") { |f| f.write(doc) }
  end

  def add_cshtml_node folder, name
    doc = Nokogiri::XML(open(proj_file))
    add_include doc, :Content, "Views\\#{folder}\\#{name}.cshtml"
    File.open(proj_file, "w") { |f| f.write(doc) }
  end
  
  def add_js_node name
    doc = Nokogiri::XML(open(proj_file))
    add_include doc, :Content, "Scripts\\app\\#{name}.js"
    File.open(proj_file, "w") { |f| f.write(doc) }
  end

  def add_include doc, type, value
    doc.xpath("//xmlns:ItemGroup[xmlns:#{type.to_s}]").first << "<#{type.to_s} Include=\"#{value}\" />"
  end

  def proj_file
    "#{@mvc_project_directory}/#{@mvc_project_directory}.csproj"
  end

  def verify_file_name name
    raise "You cant use #{name} as the name. No spaces or fancy characters please." if name =~ /[\x00\/\\:\*\?\"<>\|]/ || name =~ / /
  end

def model_template name
return <<template
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Oak;

namespace #{@mvc_project_directory}.Models
{
    public class #{name} : DynamicModel
    {
        public #{name}(object dto) : base(dto) { }
        public #{name}() { }
        //IEnumerable<dynamic> Validates() { }
        //IEnumerable<dynamic> Associates() { }
    }
}
template
end

def controller_template name
return <<template
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Oak;

namespace #{@mvc_project_directory}.Controllers
{
    public class #{name} : BaseController { }
}
template
end

def repo_template name
return <<template
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Oak;
using Massive;

namespace #{@mvc_project_directory}.Repositories
{
    public class #{name} : DynamicRepository { }
}
template
end

def projection_repo_template name, model_name
return <<template
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Oak;
using Massive;
using #{@mvc_project_directory}.Models;

namespace #{@mvc_project_directory}.Repositories
{
    public class #{name} : DynamicRepository
    {
        public #{name}()
        {
            Projection = d => new #{model_name}(d);
        }
    }
}
template
end

def view_template name
return <<template
@{
    ViewBag.Title = "#{name}";
}
template
end

def js_template name
return <<template
$(function () {

});
template
end

def test_template name
return <<template
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NSpec;
using Oak.Controllers;

namespace #{@test_project}
{
    class #{name} : nspec
    {
        SeedController seed;

        void before_each()
        {
            seed = new SeedController();
            seed.PurgeDb();
            seed.All();
        }
    }
}
template
end
end
