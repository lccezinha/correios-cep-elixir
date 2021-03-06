defmodule Correios.CEP do
  @moduledoc """
  Find Brazilian addresses by zip code, directly from Correios API. No HTML parsers.
  """

  alias Correios.CEP.{Address, Client, Error, Parser}

  @type t :: {:ok, Address.t()} | {:error, Error.t()}

  @zipcode_regex ~r/^\d{5}-?\d{3}$/

  @doc """
  Finds address by the given `zipcode`.

  Zip codes with and without "-" separator are accepted.

  ## Options

    * `connection_timeout`: timeout for establishing a connection, in milliseconds. Default is 5000.
    * `request_timeout`: timeout for receiving the HTTP response, in milliseconds. Default is 5000.
    * `proxy`: proxy to be used for the request: `{host, port}` tuple, where `port` is an integer.
    * `proxy_auth`: proxy authentication: `{user, password}` tuple.
    * `url`: Correios API full URL. Default is `https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente`.

  ## Examples

      iex> #{inspect(__MODULE__)}.find_address("54250610")
      {:ok,
       %#{inspect(Address)}{
         city: "Jaboatão dos Guararapes",
         complement: "",
         neighborhood: "Cavaleiro",
         state: "PE",
         street: "Rua Fernando Amorim",
         zipcode: "54250610"
       }}

      iex> #{inspect(__MODULE__)}.find_address("54250-610")
      {:ok,
       %#{inspect(Address)}{
         city: "Jaboatão dos Guararapes",
         complement: "",
         neighborhood: "Cavaleiro",
         state: "PE",
         street: "Rua Fernando Amorim",
         zipcode: "54250610"
       }}

      iex> #{inspect(__MODULE__)}.find_address("54250-610", connection_timeout: 1000, request_timeout: 1000)
      {:ok,
       %#{inspect(Address)}{
         city: "Jaboatão dos Guararapes",
         complement: "",
         neighborhood: "Cavaleiro",
         state: "PE",
         street: "Rua Fernando Amorim",
         zipcode: "54250610"
       }}

      iex> #{inspect(__MODULE__)}.find_address("54250-610", proxy: {"localhost", 8888})
      {:ok,
       %#{inspect(Address)}{
         city: "Jaboatão dos Guararapes",
         complement: "",
         neighborhood: "Cavaleiro",
         state: "PE",
         street: "Rua Fernando Amorim",
         zipcode: "54250610"
       }}

      iex> #{inspect(__MODULE__)}.find_address(
      ...>   "54250-610",
      ...>   proxy: {"localhost", 8888},
      ...>   proxy_auth: {"myuser", "mypass"}
      ...> )
      {:ok,
       %#{inspect(Address)}{
         city: "Jaboatão dos Guararapes",
         complement: "",
         neighborhood: "Cavaleiro",
         state: "PE",
         street: "Rua Fernando Amorim",
         zipcode: "54250610"
       }}

      iex> #{inspect(__MODULE__)}.find_address("00000-000")
      {:error, %#{inspect(Error)}{reason: "CEP NAO ENCONTRADO"}}

      iex> #{inspect(__MODULE__)}.find_address("1234567")
      {:error, %#{inspect(Error)}{reason: "zipcode in invalid format"}}

      iex> #{inspect(__MODULE__)}.find_address("")
      {:error, %#{inspect(Error)}{reason: "zipcode is required"}}

  """
  @spec find_address(String.t(), keyword()) :: t()
  def find_address(zipcode, options \\ [])

  def find_address("", _options), do: {:error, Error.new("zipcode is required")}

  def find_address(zipcode, options) when is_binary(zipcode) and is_list(options) do
    if valid_zipcode?(zipcode) do
      zipcode
      |> client().request(options)
      |> parse()
    else
      {:error, Error.new("zipcode in invalid format")}
    end
  end

  @spec valid_zipcode?(String.t()) :: boolean()
  defp valid_zipcode?(zipcode), do: zipcode =~ @zipcode_regex

  @spec client :: module()
  defp client, do: Application.get_env(:correios_cep, :client) || Client

  @spec parse(Client.t()) :: t()
  defp parse({:ok, response}) do
    response
    |> Parser.parse_ok()
    |> case do
      %Address{} = address -> {:ok, address}
      %Error{} = error -> {:error, error}
    end
  end

  defp parse({:error, error}), do: {:error, Parser.parse_error(error)}

  @doc """
  Finds address by a given zip code.

  Similar to `find_address/2` except it will unwrap the error tuple and raise in case of errors.

  ## Examples

      iex> #{inspect(__MODULE__)}.find_address!("54250610")
      %#{inspect(Address)}{
        city: "Jaboatão dos Guararapes",
        complement: "",
        neighborhood: "Cavaleiro",
        state: "PE",
        street: "Rua Fernando Amorim",
        zipcode: "54250610"
      }

      iex> #{inspect(__MODULE__)}.find_address!("00000-000")
      ** (#{inspect(Error)}) CEP NAO ENCONTRADO

  """
  @spec find_address!(String.t(), keyword()) :: Address.t()
  def find_address!(zipcode, options \\ []) when is_binary(zipcode) and is_list(options) do
    zipcode
    |> find_address(options)
    |> case do
      {:ok, response} -> response
      {:error, error} -> raise(error)
    end
  end
end
