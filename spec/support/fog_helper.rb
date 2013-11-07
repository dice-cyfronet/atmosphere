module FogHelpers
  # returns hash specofic for Fog library asking about VM
  def vm(id, name, status, addr='10.100.8.18')
    {
      "id" => id,
      "addresses" => {"private"=>[{"version"=>4, "addr"=>addr}]},
      "image" => {
        "id" => "ubuntu",
        "links" => [
            {"href" => "http://10.100.0.24:8774/a0297dad2a9f40dc9bda6eacd43d488a/images/addc2222-9632-468e-8b78-18c74d9df6ef", "rel" => "bookmark"}
        ]
      },
      "name" => name,
      "state" => status.to_s.upcase,
      "key_name" => "jm",
      "fault" => nil
    }
  end
end