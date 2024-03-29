using Documenter, XLSXasJSON

# copy coverage report to build folder for Documentor.jl to take along to `gh-pages` branch 
function copy_coverage()
  source = joinpath(@__DIR__, "src/coverage")
  target = joinpath(@__DIR__, "build/coverage")
  @info "Copy $source to $target" 

  cp(source, target; force = true)
  nothing
end

makedocs(
   modules = [XLSXasJSON],
 checkdocs = :all,
   authors = "YongHee Kim",
  sitename = "XLSXasJSON.jl",
  pages = [ "Home" => "index.md",
            "Tutorial" => "tutorial.md",
            "API Reference" => "api.md" ]
)

deploydocs(
    repo   = "github.com/YongHee-Kim/XLSXasJSON.jl.git",
    target = "build",
    deps   = copy_coverage(),
    make   = nothing
)