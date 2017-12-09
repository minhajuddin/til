defmodule Til.Github do
  alias Til.Accounts.User

  @hello_world_template Path.expand("../../templates/hello_world.md", __DIR__)
                        |> File.read!()
  def setup_til_repo(%User{} = user) do
    {:ok, _} = create_repo(user)
    {:ok, _} = create_file(user, "hello-world.md", @hello_world_template)
    {:ok, _} = create_push_webhook(user)
  end

  def create_repo(%User{} = user) do
    request(
      :post,
      "/user/repos",
      %{
        name: "tilhub",
        description: ":rainbow: Awesome things I have learnt!"
      }
      |> Poison.encode!(),
      user.github_access_token
    )
  end

  def create_file(%User{} = user, filename, contents) do
    request(
      :put,
      "/repos/#{user.github_username}/#{user.github_repo}/contents/#{filename}",
      %{path: filename, message: "Created #{filename}", content: contents |> Base.encode64()}
      |> Poison.encode!(),
      user.github_access_token
    )
  end

  @tilhub_url "https://tilhub.in"
  def create_push_webhook(%User{} = user) do
    request(
      :post,
      "/repos/#{user.github_username}/#{user.github_repo}/hooks",
      %{
        name: "web",
        active: true,
        events: ["push"],
        config: %{
          url: "#{@tilhub_url}/#{user.github_uid}",
          content_type: "json"
        }
      }
      |> Poison.encode!(),
      user.github_access_token
    )
  end

  @api_url "https://api.github.com"
  @headers [{"accept", "application/vnd.github.v3+json"}]
  def request(method, "/" <> _ = path, body, access_token) do
    HTTPoison.request(method, @api_url <> path, body, [
      {"authorization", "token #{access_token}"} | @headers
    ])
  end
end