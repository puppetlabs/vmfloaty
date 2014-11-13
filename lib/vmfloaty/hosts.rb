# manage hosts used from vm pooler
class Hosts
  def initialize
    @host_list = {}
  end

  def add_host(host_hash)
    host_hash.each do |k,v|
      if @host_list[k]
        @host_list[k].push(v)
      else
        if v.is_a?(Array)
          @host_list[k] = v
        else
          @host_list[k] = [v]
        end
      end
    end

    puts @host_list
  end

  def remove_host(host_id)
  end

  def print_host_list
    puts @host_list
  end
end
