
class Format
  # TODO: Takes the json response body from an HTTP GET
  # request and "pretty prints" it
  def self.get_hosts(hostname_hash)
    host_hash = {}

    hostname_hash.delete("ok")
    hostname_hash.each do |type, hosts|
      if type == "domain"
        host_hash[type] = hosts
      else
        host_hash[type] = hosts["hostname"]
      end
    end

    host_hash.to_json
  end
end
