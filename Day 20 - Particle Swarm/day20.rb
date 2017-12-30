require 'matrix'
require 'set'


class Vector
    # Manhattan magnitude
    def manh_magn
        self.collect(&:abs).reduce(:+)
    end
end


class Particle
    attr_reader :position
    attr_reader :velocity
    attr_reader :acceleration

    def initialize p=nil, v=nil, a=nil
        @position = p || Vector[0, 0, 0]
        @velocity = v || Vector[0, 0, 0]
        @acceleration = a || Vector[0, 0, 0]
    end

    def self.deserialize str
        match = /p=<([^>]+)>, v=<([^>]+)>, a=<([^>]+)>/.match str

        if match == nil
            raise "invalid format"
        end

        p = Vector[*match[1].split(",").map(&:to_i)]
        v = Vector[*match[2].split(",").map(&:to_i)]
        a = Vector[*match[3].split(",").map(&:to_i)]
        Particle.new p, v, a
    end

    def to_s
        "Particle(#{position}, #{velocity}, #{acceleration})"
    end

    def collision_time_with other
        # Solve the quadratic equation:
        # dP + dV*t + dA*t*(t+1)/2 = 0
        # dP + dV*t + dA*t^2/2 + dA*t/2 = 0
        # dP + (dV+dA/2)*t + (dA/2)*t^2 = 0
        # where dX = X1 - X2
        dp = self.position - other.position
        dv = self.velocity - other.velocity
        da = self.acceleration - other.acceleration

        c0 = dp
        c1 = dv + 0.5*da
        c2 = 0.5 * da

        # Solve for each vector component
        solutions = []
        3.times do |i|
            if c2[i] != 0
                # Quadratic equation
                discr = c1[i] * c1[i] - 4*c2[i]*c0[i]

                # If at least one component doesn't have a root -
                # no other components can have it.
                return nil if discr < 0

                root1 = (-c1[i] - Math.sqrt(discr)) / (2 * c2[i])
                root2 = (-c1[i] + Math.sqrt(discr)) / (2 * c2[i])
                valid_roots = [root1, root2].keep_if do |root|
                    root >= 0 && root.truncate == root
                end
                valid_roots.uniq!
            elsif c1[i] != 0
                # Linear equation
                root = -c0[i].to_f / c1[i]
                if root >= 0 && root.truncate == root
                    valid_roots = [root]
                else
                    valid_roots = []
                end
            else
                # Constant
                if c0[i] == 0
                    # Any solution is valid
                    next
                else
                    valid_roots = []
                end
            end

            return nil if valid_roots.empty?
            solutions << valid_roots
        end

        common_solutions = solutions.inject(:&)
        return nil if common_solutions.empty?
        common_solutions.min.truncate
    end
end


class PrtSystem
    attr_reader :particles

    def initialize
        @particles = []
    end

    def << p
        @particles.push p
    end

    def simulate_collisions
        time_to_collisions = Hash.new []
        iter = 1
        @particles.each do |p1|
            @particles.each do |p2|
                next if p1 == p2

                if iter % 1000 == 0
                    print "."
                    STDOUT.flush

                    puts if iter % 100000 == 0
                end
                iter += 1

                ct = p1.collision_time_with p2
                next if !ct
                time_to_collisions[ct] = time_to_collisions[ct] << [p1, p2]
            end
        end
        puts

        deleted = Set[]

        time_to_collisions.keys.sort.each do |time|
            pairs = time_to_collisions[time]
            pairs.delete_if do |ps|
                deleted.include?(ps[0]) || deleted.include?(ps[1])
            end
            parts = pairs.flatten.uniq
            parts.each do |p|
                @particles.delete(p)
                deleted.add(p)
            end
        end
    end
end


def main
    if ARGV.length < 1
        puts "Input file path is required"
        exit 1
    end

    system = PrtSystem.new
    begin
        File.foreach(ARGV[0]).with_index do |line, li|
            begin
                system << Particle.deserialize(line)
            rescue Exception => e
                raise "Could not parse line #{li}: #{e}"
            end
        end
    rescue Exception => e
        puts e
        exit 1
    end

    min_pi = 0
    system.particles.each.with_index do |p, pi|
        if p.acceleration.manh_magn < system.particles[min_pi].acceleration.manh_magn
            min_pi = pi
        end
    end
    puts "The particle closest to the (0, 0, 0) in the long term:"
    puts "#{min_pi}: #{system.particles[min_pi]}"

    system.simulate_collisions
    puts "After all the collisions particles were left:"
    puts system.particles.length
end

main