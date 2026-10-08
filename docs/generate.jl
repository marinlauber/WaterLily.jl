# Generate the examples with Literate.jl
import Literate

EXAMPLES_IN = joinpath(@__DIR__, "src", "literate-examples")
EXAMPLES_OUT = joinpath(@__DIR__, "src", "examples")
mkpath(EXAMPLES_OUT)

# Run Literate on all examples
@timeit dto "Literate." for program in readdir(EXAMPLES_IN; join = true)
    name = basename(program)
    if endswith(program, ".jl")
        if !liveserver
            script = @timeit dto "script()" @timeit dto name Literate.script(program, EXAMPLES_OUT)
            code = strip(read(script, String))
        else
            code = "<< no script output when building as draft >>"
        end

        # remove "hidden" lines which are not shown in the markdown
        line_ending_symbol = occursin(code, "\r\n") ? "\r\n" : "\n"
        code_clean = join(filter(x -> !endswith(x, "#hide"), split(code, r"\n|\r\n")), line_ending_symbol)
        code_clean = replace(code_clean, r"^# This file was generated .*$"m => "")
        code_clean = strip(code_clean)

        mdpost(str) = replace(str, "@__CODE__" => code_clean)

        @timeit dto "markdown()" @timeit dto name begin
            Literate.markdown(program, EXAMPLES_OUT, postprocess = mdpost)
        end
        if !liveserver
            # Notebooks are shipped unexecuted: the simulations are too expensive to
            # run a second time, and the markdown pages already carry the output.
            @timeit dto "notebook()" @timeit dto name begin
                Literate.notebook(program, EXAMPLES_OUT, execute = false)
            end
        end
    elseif any(endswith.(program, (".png", ".jpg", ".gif")))
        cp(program, joinpath(EXAMPLES_OUT, name); force = true)
    else
        @warn "ignoring $program"
    end
end
