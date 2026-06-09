defmodule Chat.Clients.S3 do
  alias ExAws.S3

  def upload_file(file, path, content_type, bucket) do

    S3.put_object(bucket, path, file, [content_type: content_type, acl: :public_read])
    |> ExAws.request!()

  end

  def build_key_url(key, bucket) do

    s3_config = Application.get_env(:ex_aws, :s3)
    scheme = s3_config[:scheme] || "http"
    host = s3_config[:host] || "localhost"
    port = s3_config[:port]

    port_part = if port, do: ":#{port}", else: ""

    "#{scheme}://#{host}#{port_part}/#{bucket}/#{key}"

  end

end
