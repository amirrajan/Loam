begin
  require 'nokogiri'
rescue LoadError
  puts "============ note ============="
  puts "looks like you don't have nokogiri installed, to use the scaffolding capabilities of Oak, you'll need to run the command 'gem install nokogiri', type 'rake -D gen' for more information on scaffolding (source located in scaffold.rb)."
  puts "================================"
  puts ""
end

namespace :gen do
  desc "adds a dynamic model class to your mvc project"
  task :model, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:model[Person]" if args[:name].nil?

    folder "Models"
    
    save model_template(args[:name]), "#{@mvc_project_directory}/Models/#{args[:name]}.cs"

    add_compile_node :Models, args[:name]
  end

  desc "adds a dynamic repository class to your mvc project"
  task :repo, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:repository[People]" if args[:name].nil?

    folder "Repositories"

    save repo_template(args[:name]), "#{@mvc_project_directory}/Repositories/#{args[:name]}.cs"

    add_compile_node :Repositories, args[:name]
  end

  desc "adds a dynamic repository with a projection to a dynamic model"
  task :repo_model, [:repo_and_model_name] => :rake_dot_net_initialize do |t, args|
    repo = args[:repo_and_model_name].split(':').first
    model = args[:repo_and_model_name].split(':').last

    raise "repostiory and model name required, usage: rake gen:repo_model[Blogs:Blog]" if args[:repo_and_model_name].split(':').count == 1

    folder "Models"
    
    save model_template(model), "#{@mvc_project_directory}/Models/#{model}.cs"

    add_compile_node :Models, model

    folder "Repositories"

    save projection_repo_template(repo, model), "#{@mvc_project_directory}/Repositories/#{repo}.cs"

    add_compile_node :Repositories, repo
  end

  desc "adds a controller class to your mvc project"
  task :controller, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:controller[PeopleController]" if args[:name].nil?

    folder "Controllers"

    save controller_template(args[:name]), "#{@mvc_project_directory}/Controllers/#{args[:name]}.cs"

    add_compile_node :Controllers, args[:name]
  end

  desc "adds cshtml to your mvc project"
  task :view, [:controller_and_name] => :rake_dot_net_initialize do |t, args|
    controller = args[:controller_and_name].split(':').first
    name = args[:controller_and_name].split(':').last

    raise "controller and view name required, usage: rake gen:view[Home:Index]" if args[:controller_and_name].split(':').count == 1

    folder "Views/#{controller}"

    save view_template(name), "#{@mvc_project_directory}/Views/#{controller}/#{name}.cshtml"

    add_cshtml_node controller, name
  end

  desc "adds javascript file to your mvc project"
  task :script, [:name] => :rake_dot_net_initialize do |t, args|
    raise "js name required, usage: rake gen:script[index]" if args[:name].nil?

    folder "Scripts/app"

    save js_template(args[:name]), "#{@mvc_project_directory}/Scripts/app/#{args[:name]}.js"

    add_js_node args[:name]
  end

  desc "adds a test file to your test project"
  task :test, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:test[decribe_HomeController]" if args[:name].nil?

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
