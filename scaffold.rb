namespace :gen do
  desc "adds a dynamic model class to your mvc project"
  task :model, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:model[Person]" if args[:name].nil?

    mkdir "Models"
    
    save model_template(args[:name]), "#{@mvc_project_directory}/Models/#{args[:name]}.cs"

    add_compile_node :Models, args[:name]
  end

  desc "adds a dynamic repository class to your mvc project"
  task :repo, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:repository[People]" if args[:name].nil?

    mkdir "Repositories"

    save repo_template(args[:name]), "#{@mvc_project_directory}/Repositories/#{args[:name]}.cs"

    add_compile_node :Repositories, args[:name]
  end

  desc "adds a controller class to your mvc project"
  task :controller, [:name] => :rake_dot_net_initialize do |t, args|
    raise "name parameter required, usage: rake gen:controller[PeopleController]" if args[:name].nil?

    mkdir "Controllers"

    save controller_template(args[:name]), "#{@mvc_project_directory}/Controllers/#{args[:name]}.cs"

    add_compile_node :Controllers, args[:name]
  end

  def save content, file_path
    raise "#{file_path} already exists, cancelling" if File.exists? file_path

    File.open(file_path, "w") { |f| f.write(content) }
  end

  def mkdir dir
    FileUtils.mkdir_p "#{@mvc_project_directory}/#{dir}"
  end

  def add_compile_node folder, name
    proj_file = "#{@mvc_project_directory}/#{@mvc_project_directory}.csproj"
    doc = Nokogiri::XML(open(proj_file))
    doc.xpath("//xmlns:ItemGroup[xmlns:Compile]").first << "<Compile Include=\"#{folder.to_s}\\#{name}.cs\" />"
    File.open(proj_file, "w") { |f| f.write(doc) }
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
        public Peep(object dto) : base(dto) { }
        public Peep() { }
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

end
