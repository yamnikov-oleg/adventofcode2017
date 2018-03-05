def strongest_bridge(node_num, pipes_bag) : Int32
  strongest_strength = 0

  pipes_bag.each do |pipe|
    if pipe[0] == node_num
      other_node_num = pipe[1]
    elsif pipe[1] == node_num
      other_node_num = pipe[0]
    else
      next
    end

    strength = node_num + other_node_num
    strongest_subbridge = strongest_bridge(other_node_num, pipes_bag - Set{pipe})

    if strength + strongest_subbridge > strongest_strength
      strongest_strength = strength + strongest_subbridge
    end
  end

  strongest_strength
end

def longest_bridge(node_num, pipes_bag) : {strength: Int32, length: Int32}
  longest_strength = 0
  longest_length = 0

  pipes_bag.each do |pipe|
    if pipe[0] == node_num
      other_node_num = pipe[1]
    elsif pipe[1] == node_num
      other_node_num = pipe[0]
    else
      next
    end

    strength = node_num + other_node_num
    subbridge = longest_bridge(other_node_num, pipes_bag - Set{pipe})

    subbridge_longer = subbridge[:length] + 1 > longest_length
    subbridge_same_length = subbridge[:length] + 1 == longest_length
    subbridge_stronger = subbridge[:strength] + strength > longest_strength
    if subbridge_longer || (subbridge_same_length && subbridge_stronger)
      longest_strength = subbridge[:strength] + strength
      longest_length = subbridge[:length] + 1
    end
  end

  {strength: longest_strength, length: longest_length}
end

def main
  if ARGV.size != 1
    puts "Input file path is required in command line"
    return
  end

  # Luckily the input has no duplicates
  pipes = Set({Int32, Int32}).new

  begin
    input_file = File.each_line ARGV[0] do |line|
      parts = line.strip.split("/").map(&.to_i)
      pipes << {parts[0], parts[1]}
    end
  rescue ex
    puts ex.message
    return
  end

  strongest_strength = strongest_bridge(0, pipes)
  puts "Strongest bridge has strength of #{strongest_strength}"

  longest = longest_bridge(0, pipes)
  puts "Longest bridge has length of #{longest[:length]} and strength of #{longest[:strength]}"
end

main
