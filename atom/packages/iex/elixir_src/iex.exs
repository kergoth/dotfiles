defmodule AtomIEx do
  @moduledoc "Helper functions to support interaction with IEx using the iex
  package for the Atom editor"

  @doc "Reset the application"
  def reset do
    Mix.Task.reenable "compile.elixir"
    try do
      Application.stop(Mix.Project.config[:app]);
      Mix.Task.run "compile.elixir";
      Application.start(Mix.Project.config[:app], :permanent)
    catch;
      :exit, _ -> "Application failed to start"
    end
    :ok
  end

  @doc "Run all the tests defined in the application"
  def run_all_tests do
    {rval, _} = System.cmd("mix", ["test", "--color"], [])
    IO.puts rval
  end

  @doc "Run the currently open test file"
  def run_test(file) do
    {rval, _} = System.cmd("mix", ["test", "--color", file])
    IO.puts rval
  end

  @doc "Run the currently selected test"
  def run_test(file, line_num) do
    {rval, _} = System.cmd("mix", ["test", "--color", "#{file}:#{line_num}"])
    IO.puts rval
  end

  @doc "Get file and line of a module definition"
  def get_file_and_line(module) do
    file = to_string(module.__info__(:compile)[:source])
    code_docs = Code.get_docs(module, :moduledoc)
    line_num = elem(code_docs, 0)
    "#{module} - #{file}:#{line_num}"
  end

  @doc "Get file and line of function definition"
  def get_file_and_line(module, func) do
    file = to_string(module.__info__(:compile)[:source])
    code_docs = Code.get_docs(module, :all)[:docs]
    #line_num = List.key_find(code_docs, )
    entry = Enum.find(code_docs, fn(x) -> elem(x, 0) |> elem(0) == func end)
    line_num = elem(entry, 1)
    "#{module}.#{func} - #{file}:#{line_num}"
  end

  defmodule Comment do
    @moduledoc "Provides a 'comment' macro to allow blocks of code to be ignored
    to facilitate running them as small tests in IEx during interactive
    development.

    Usage:
    ```
    comment do
      some code
    end
    ```"
    defmacro comment(_expr) do
    end
  end
end
