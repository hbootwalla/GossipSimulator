# FULL TOPOLOGY

defmodule FullAgent do
    use Agent
  
    def start_link(args \\ %{}) do
      Agent.start_link(fn -> Map.put(Map.new, :count, 0); end)
    end
  
    # def add_neighbor(agent_link, neighbor_pid) do
    #   Agent.update(agent_link, fn map -> Map.put(map, :list, [neighbor_pid | Map.get(map, :list)]) end)
    # end
  
    def get_random_neighbor(agent_link) do
      list_R = Agent.get(agent_link, fn map -> Map.get(map, :list) end)
      # case list_R do
      #   [] -> n_pid = nil;
  
      #   list_R -> n_pid = Enum.random(list_R);
      #       unless Process.alive?(n_pid) do
      #         Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
      #         list_RU = Agent.get(agent_link, fn(list) -> list end)
      #         n_pid = get_random_neighbor(agent_link);
      #     end
      #   end
        n_pid = Enum.random(list_R)
    end
  
  
     def add_neighbors(agent_link, listOfPids) do
        Agent.update(agent_link, fn(map) -> Map.put(map, :list, listOfPids) end)
     end

     def get_count(agent_link) do
       Agent.get(agent_link, fn map -> Map.get(map, :count) end)
     end
     
     def add_count(agent_link) do
      Agent.update(agent_link, fn map -> Map.put(map, :count, Map.get(map, :count)+1) end)
     end

    end


  
defmodule FullGossip do
    
    def spawnFullActors(numOfNodes, nodeCount, totRepeat, list, main_pid)  do
      if nodeCount != numOfNodes do
        pid = spawn(__MODULE__, :startFullGossip, [totRepeat, nil, main_pid]);
        list = list ++ [pid];
        spawnFullActors(numOfNodes, nodeCount + 1,totRepeat, list, main_pid)
      else
        list
      end    
    end
  
    # def messageAllNodesToAddNeighbors(pid, list) do
    #   newList = List.delete(list, pid)
    #   send(pid, {:add_neighbors, list});
    # end
  
    def startFullGossip(totRepeat, agent_link, main_pid) do
      if agent_link == nil do
        {:ok, agent_link} = FullAgent.start_link;
      end
      count = FullAgent.get_count(agent_link)
      if(count < totRepeat) do
        receive do
          {:add_neighbors, n_pid} ->  FullAgent.add_neighbors(agent_link, n_pid)
                                      startFullGossip(totRepeat, agent_link, main_pid);
    
          {:gossip, ppid, message} -> #IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
                                      neighborPid = FullAgent.get_random_neighbor(agent_link);
                                      case neighborPid do
                                          #nil -> send(main_pid, {:dead_process}); # Process.exit(self(), :kill);
                                          _ ->   send(neighborPid, {:gossip, self(), message});
                                                if count == 0 do
                                                  spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, totRepeat, self(), message, main_pid]);
                                                end
                                                FullAgent.add_count(agent_link)
                                                startFullGossip(totRepeat,agent_link, main_pid); 
                                      end
                                    end
      else
        #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
        send(main_pid, {:dead_process});
        doNothing
      end
    end
  
    # def startFullGossip(count, totRepeat, agent_link, main_pid) when count > totRepeat do
    #   IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
    #   Process.exit(self(), :kill);
    #   send(main_pid, {:dead_process});
    #   doNothing
    # end

    def doNothing do
      receive do
      _ -> doNothing
      end
    end
    
    def spreadGossipPeriodically(agent_link,totRepeat, ppid, message, main_pid) do
      count = FullAgent.get_count(agent_link);
      if count < totRepeat do
        neighborPid = FullAgent.get_random_neighbor(agent_link);
            case neighborPid do
                #nil -> send(main_pid, {:dead_process}); #Process.exit(self(), :kill);
                _ ->   send(neighborPid, {:gossip, self(), message});
                        spreadGossipPeriodically(agent_link, totRepeat, ppid, message, main_pid);
            end 
      else
        Process.exit(self(), :kill);
      end
    end
end

# LINE TOPOLOGY

  defmodule LineAgent do
    use Agent
  
    def start_link do
      Agent.start_link(fn -> map = Map.put(Map.new, :count, 0); Map.put(map, :list, []) end)
    end
  
    def add_neighbor(agent_link, pid, neighbor_pid) do
      Agent.update(agent_link, fn map -> Map.put(map, :list, [neighbor_pid | Map.get(map, :list)]) end)
      
    end
  
    def get_random_neighbor(agent_link) do
      list_R = Agent.get(agent_link, fn map -> Map.get(map, :list) end)
      # case list_R do
      #   [] -> n_pid = nil;
  
      #   list_R -> n_pid = Enum.random(list_R);
      #       unless Process.alive?(n_pid) do
      #         Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
      #         list_RU = Agent.get(agent_link, fn(list) -> list end)
      #         n_pid = List.first(list_RU)
      #     end
      #   end
      #   n_pid
      Enum.random(list_R);
    end

    def get_count(agent_link) do
      Agent.get(agent_link, fn map -> Map.get(map, :count) end)
    end
    
    def add_count(agent_link) do
     Agent.update(agent_link, fn map -> Map.put(map, :count, Map.get(map, :count)+1) end)
    end

  end
  
defmodule LineGossip do
    def spawnLineActors(numOfNodes, nodeCount, totRepeat, prevPid, main_pid) when nodeCount == 0 do
      pid = spawn(__MODULE__, :startGossiping, [totRepeat, nil, main_pid]);
      spawnLineActors(numOfNodes, nodeCount+1, totRepeat, pid, main_pid);
      pid
    end
  
    def spawnLineActors(numOfNodes, nodeCount, totRepeat, prevPid, main_pid) when (nodeCount < numOfNodes and nodeCount > 0) do
             pid = spawn(__MODULE__, :startGossiping, [totRepeat,nil,main_pid]);
             send(pid, {:add_neighbor, prevPid})
             send(prevPid, {:add_neighbor, pid})
             spawnLineActors(numOfNodes, nodeCount+1, totRepeat, pid, main_pid);
    end
  
    def spawnLineActors(numOfNodes, nodeCount, _,  _, _) when nodeCount == numOfNodes do
    end
  
    def startGossiping(totRepeat, agent_link, main_pid)  do
    
     if agent_link == nil do
        {:ok, agent_link} = LineAgent.start_link
     end
    count = LineAgent.get_count(agent_link)
    if count < totRepeat do
     receive do
          {:add_neighbor, n_pid} -> LineAgent.add_neighbor(agent_link, self(), n_pid);
                                    startGossiping(totRepeat, agent_link, main_pid);
  
          {:gossip, ppid, message} -> #IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
                                      neighborPid = LineAgent.get_random_neighbor(agent_link);
                                      case neighborPid do
                                        #nil -> send(main_pid, {:dead_process}); #IO.puts "I have no more neighbors PID: -- "<> List.to_string :erlang.pid_to_list self(); Process.exit(self(), :kill);
                                        _ -> send(neighborPid, {:gossip, self(), message});
                                            if count == 1 do
                                              spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message,main_pid, totRepeat]);
                                            end
                                            LineAgent.add_count(agent_link)
                                            startGossiping(totRepeat, agent_link, main_pid);
                                      end
      end
    else
      send(main_pid, {:dead_process});
      #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
      doNothing
    end
    end
    
  
    def spreadGossipPeriodically(agent_link, ppid, message,main_pid, totRepeat) do
      #Process.sleep(100);
      count = LineAgent.get_count(agent_link)
      if count < totRepeat do 
        neighborPid = LineAgent.get_random_neighbor(agent_link)
          case neighborPid do
            #nil -> send(main_pid, {:dead_process}); #IO.puts "I have no more neighbors PID: -- "<> List.to_string :erlang.pid_to_list ppid; Process.exit(ppid, :kill);
            _ -> send(neighborPid, {:gossip, ppid, message});
                      spreadGossipPeriodically(agent_link, ppid, message, main_pid, totRepeat);
            end
          else
            Process.exit(self(), :kill);
          end
        end
    
    # def startGossiping(totRepeat, _ , main_pid) when count > totRepeat do
    #   send(main_pid, {:dead_process});
    #   #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
    #   #Process.exit(self(), :kill);
    #   #GenServer.cast(server, {:termination_message, self()});
    #   doNothing
    # end
  
    def doNothing do
      receive do
      _ -> doNothing
      end
    end

  end
  
  # TwoD GOSSIP

  defmodule TwoDAgent do
    
    def start_link(args \\ %{}) do
      Agent.start_link(fn -> Map.put(Map.put(Map.new, :count, 0), :list, []) end)
    end
  
    def add_neighbors(agent_link, listOfPid) do
      Agent.update(agent_link, fn map -> Map.put(map, :list, listOfPid) end);
    end
  
    def get_random_neighbor(agent_link) do
      list_R = Agent.get(agent_link, fn map -> Map.get(map, :list) end)
      # case list_R do
      #   [] -> n_pid = nil;
  
      #   list_R -> n_pid = Enum.random(list_R); 
      #       unless Process.alive?(n_pid) do
      #         Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
      #         list_RU = Agent.get(agent_link, fn(list) -> list end)
      #         n_pid = get_random_neighbor(agent_link);
      #     end
      #   end
        n_pid = Enum.random(list_R);
    end
    
    def get_count(agent_link) do
      Agent.get(agent_link, fn map -> Map.get(map, :count) end)
    end
    
    def add_count(agent_link) do
     Agent.update(agent_link, fn map -> Map.put(map, :count, Map.get(map, :count)+1) end)
    end


  end
  
  defmodule TwoDGossip do
    
    def spawn2DActors(numOfNodes, totRepeat, rC, cC, power, map, main_pid) do
      if(rC == power) do
        map
      else
        pid = spawn(__MODULE__, :startTwoDGossip, [totRepeat,nil, main_pid])
        if(cC == 0) do
          map = Map.put(map, rC, %{});
        end
        mapInMap = Map.get(map, rC);
        newMap = Map.put(mapInMap, cC, pid);
        map = Map.put(map, rC, newMap);      
        if(cC + 1 == power) do
          spawn2DActors(numOfNodes, totRepeat, rC+1, 0, power, map, main_pid)
        else
          spawn2DActors(numOfNodes, totRepeat, rC, cC+1, power, map,main_pid)
        end
      end
    end
  
    def setupNeighbors(map, rC, cC, power) do
      if(rC < power) do
        list = []
        if rC-1 >= 0 do
          list = [map[rC-1][cC]] ++ list; 
        end
        if rC+1 < power do
          list = [map[rC+1][cC]] ++ list; 
        end
        if cC-1 >= 0 do
          list = [map[rC][cC-1]] ++ list; 
        end
        if cC+1 < power do
          list = [map[rC][cC+1]] ++ list; 
        end
        send(map[rC][cC], {:add_neighbors, list});
        if(cC+1 == power) do
          setupNeighbors(map, rC + 1, 0, power);
        else
          setupNeighbors(map,rC,cC+1, power)
        end
      end
    end
  
  
    def startTwoDGossip(totRepeat, agent_link, main_pid) do
      if agent_link == nil do
        {:ok, agent_link} = TwoDAgent.start_link
      end
      count = TwoDAgent.get_count(agent_link)
      if count < totRepeat do
        receive do
          {:add_neighbors, listOfPid} ->  TwoDAgent.add_neighbors(agent_link, listOfPid)
                                          startTwoDGossip(totRepeat, agent_link, main_pid);
    
          {:gossip, ppid, message} ->  #IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
                                      neighborPid = TwoDAgent.get_random_neighbor(agent_link);
                                      case neighborPid do
                                         # nil -> send(main_pid, {:dead_process}); #Process.exit(self(), :normal);
                                          _ ->   send(neighborPid, {:gossip, self(), message});
                                                if count == 0 do
                                                  spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message, main_pid, totRepeat]);
                                                end
                                                TwoDAgent.add_count(agent_link)
                                                startTwoDGossip(totRepeat, agent_link,  main_pid);
                                      end
        end
        else
          send(main_pid, {:dead_process});
          #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
          doNothing
        end 
      
    end
  
    # def startTwoDGossip(count, totRepeat, agent_link, main_pid) when count > totRepeat do
    #   send(main_pid, {:dead_process});
    #   #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
    #   #Process.exit(self(), :normal);
    #   doNothing
    # end

    def doNothing do
      receive do
      _ -> doNothing
      end
    end
  
    def spreadGossipPeriodically(agent_link, ppid, message, main_pid, totRepeat) do
      #Process.sleep(1);
      count = TwoDAgent.get_count(agent_link)
      if count < totRepeat do
        neighborPid = TwoDAgent.get_random_neighbor(agent_link);
            case neighborPid do
                #nil -> send(main_pid, {:dead_process}); #Process.exit(self(), :normal);
                _ ->   send(neighborPid, {:gossip, self(), message});
                       spreadGossipPeriodically(agent_link, ppid, message, main_pid, totRepeat);
            end 
        
      else
        Process.exit(self(), :kill);
      end
    end
  end

# TwoD Imperfect Gossip

defmodule TwoDImpGossip do
    
    def spawn2DActors(numOfNodes, totRepeat, rC, cC, power, map, list, main_pid) do
      if(rC == power) do
        {map, list}
      else
        pid = spawn(__MODULE__, :startTwoDGossip, [totRepeat, nil,main_pid])
        list = list ++ [pid]
        if(cC == 0) do
          map = Map.put(map, rC, %{});
        end
        mapInMap = Map.get(map, rC);
        newMap = Map.put(mapInMap, cC, pid);
        map = Map.put(map, rC, newMap);      
        if(cC + 1 == power) do
          spawn2DActors(numOfNodes, totRepeat, rC+1, 0, power , map, list, main_pid)
        else
          spawn2DActors(numOfNodes, totRepeat, rC, cC+1, power, map, list, main_pid)
        end
      end
    end
  
    def returnRandomNeighbor(listOfPids, list) do
      case list do
        [] -> Enum.random(listOfPids);
        [head | tail] -> returnRandomNeighbor(List.delete(listOfPids, head),tail);
      end    
    end
  
    def setupNeighbors(map, rC, cC, power, listOfPids) do
      if(rC < power) do
        list = []
        if rC-1 >= 0 do
          list = [map[rC-1][cC]] ++ list; 
        end
        if rC+1 < power do
          list = [map[rC+1][cC]] ++ list; 
        end
        if cC-1 >= 0 do
          list = [map[rC][cC-1]] ++ list; 
        end
        if cC+1 < power do
          list = [map[rC][cC+1]] ++ list; 
        end
        randomNeighbor = returnRandomNeighbor(listOfPids, [map[rC][cC]] ++ list);
        list = [randomNeighbor] ++ list
        send(map[rC][cC], {:add_neighbors, list});
        if(cC+1 == power) do
          setupNeighbors(map, rC + 1, 0, power, listOfPids);
        else
          setupNeighbors(map,rC,cC+1, power, listOfPids)
        end
      end
    end
  
  
    def startTwoDGossip(totRepeat, agent_link, main_pid) do
      if agent_link == nil do
        {:ok, agent_link} = TwoDAgent.start_link 
      end
      count = TwoDAgent.get_count(agent_link)
      if count < totRepeat do
        receive do
          {:add_neighbors, listOfPid} -> #TwoDAgent.add_neighbors(agent_link, listOfPid);
                                        TwoDAgent.add_neighbors(agent_link, listOfPid); startTwoDGossip(totRepeat, agent_link,main_pid);
    
          {:gossip, ppid, message} ->  #IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
                                      neighborPid = TwoDAgent.get_random_neighbor(agent_link);
                                      case neighborPid do
                                          #nil -> send(main_pid, {:dead_process}); #Process.exit(self(), :normal);
                                          _ -> send(neighborPid, {:gossip, self(), message});
                                                if count == 1 do
                                                  spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, totRepeat, self(), message,main_pid]);
                                                end
                                                TwoDAgent.add_count(agent_link)
                                                startTwoDGossip(totRepeat,agent_link,main_pid);
                                      end
        end
        else
          send(main_pid, {:dead_process});
          #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
          doNothing
        end
      end 
    
  
    # def startTwoDGossip(count, totRepeat, agent_link,main_pid) when count > totRepeat do
    #   send(main_pid, {:dead_process});
    #   #IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
    #   #Process.exit(self(), :normal);
    #   doNothing
    # end
  
    def doNothing do
      receive do
      _ -> doNothing
      end
    end

    def spreadGossipPeriodically(agent_link, totRepeat, ppid, message,main_pid) do
      #Process.sleep(1);
      count = TwoDAgent.get_count(agent_link)
      if count < totRepeat do
        neighborPid = TwoDAgent.get_random_neighbor(agent_link);
            case neighborPid do
                #nil -> send(main_pid, {:dead_process}); #Process.exit(self(), :normal);
                _ ->   send(neighborPid, {:gossip, self(), message});
                        spreadGossipPeriodically(agent_link, totRepeat, ppid, message, main_pid);
            end 
      else
        Process.exit(self(), :kill)
      end
    end
  end
  