using Documenter
using ToMATo

DocMeta.setdocmeta!(ToMATo, :DocTestSetup, :(using ToMATo); recursive = true)

makedocs(;
    modules = [ToMATo],
    sitename = "ToMATo.jl",
    authors = "G. Vituri and contributors",
    doctest = false,
    checkdocs = :none,
    warnonly = [:cross_references, :docs_block],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://JuliaTDA.github.io/ToMATo.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Worked tutorial" => "tutorial.md",
        "Parameters and interpretation" => "parameters.md",
        "API reference" => "api.md",
    ],
)

if get(ENV, "JULIATDA_DOCS_DEPLOY", "false") == "true"
    deploydocs(;
        repo = "github.com/JuliaTDA/ToMATo.jl",
        devbranch = "main",
    )
end
