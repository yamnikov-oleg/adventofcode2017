Graph = {}
Graph.__index = Graph

function Graph:create()
    local graph = {}
    setmetatable(graph, Graph)
    graph.edges = {}
    return graph
end

function Graph:connect(node1, node2)
    if not self.edges[node1]
    then
        self.edges[node1] = {}
    end

    self.edges[node1][node2] = true
end

function Graph:biconnect(node1, node2)
    self:connect(node1, node2)
    self:connect(node2, node1)
end

function keys(t)
    local function iter(t, k)
        k2 = next(t, k)
        return k2
    end

    return iter, t, nil
end

function Graph:connectedto(node)
    return keys(self.edges[node])
end

function Graph:deepsearch(origin, cb)
    local function ds(origin, cb, exclude)
        for node in self:connectedto(origin)
        do
            if not exclude[node]
            then
                cb(node)
                exclude[node] = true
                ds(node, cb, exclude)
            end
        end
    end

    cb(origin)
    ds(origin, cb, {[origin] = true})
end

function Graph:groupsearch(cb)
    local passed = {}
    local group

    for node in keys(self.edges)
    do
        if not passed[node]
        then
            group = {}
            self:deepsearch(node, function(othernode)
                passed[othernode] = true
                group[othernode] = true
            end)

            cb(function() return keys(group) end)
        end
    end
end

function minin(iter, state, k)
    local m = k

    for v in iter,state,k
    do
        if not m or m > v
        then
            m = v
        end
    end

    return m
end

function count(iter, state, k)
    local cnt = 0

    for _ in iter,state,k
    do
        cnt = cnt + 1
    end

    return cnt
end

function main()
    -- Read input path
    local inputpath = arg[1]
    if not inputpath
    then
        print("Input file path is required")
        os.exit(1)
    end

    -- Open the file
    local inputfile, err = io.open(inputpath, "r")
    if err then
        print(err)
        os.exit(1)
    end

    -- Fill in the graph
    local graph = Graph:create()
    while true
    do
        local line = inputfile:read("*line")
        if line == nil
        then
            break
        end

        local node, nodes = string.match(line, '(%d+) <%-> ([%d, ]+)')
        node = tonumber(node)
        for subnode in string.gmatch(nodes, "%d+")
        do
            subnode = tonumber(subnode)
            graph:biconnect(node, subnode)
        end
    end
    io.close(inputfile)

    -- Analyse it
    local groupcnt = 0
    graph:groupsearch(function(nodes)
        local min = minin(nodes())
        if min == 0
        then
            local cnt = count(nodes())
            print("Group "..min..": "..cnt.." nodes")
        end

        groupcnt = groupcnt + 1
    end)
    print("Overall "..groupcnt.." groups")
end

main()
