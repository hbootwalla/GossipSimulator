# FULL TOPOLOGY

defmodule FullPSAgent do
    use Agent
  
    def start_link(args \\ []) do
      Agent.start_link(fn -> args end)
    end
  
    def add_neighbor(agent_link, neighbor_pid) do
      Agent.update(agent_link, fn list -> [neighbor_pid | list] end)
    end
  
    def get_random_neighbor(agent_link) do
      list_R = Agent.get(agent_link, fn list -> list end)
      case list_R do
        [] -> n_pid = nil;
  
        list_R -> n_pid = Enum.random(list_R);
            unless Process.alive?(n_pid) do
              Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
              list_RU = Agent.get(agent_link, fn(list) -> list end)
              n_pid = get_random_neighbor(agent_link);
          end
        end
        n_pid
    end
  
  
     def get_all_neighbors(agent_link) do
        Agent.get(agent_link, fn(list) -> list end)
     end
end

defmodule TwoDPSAgent do
  
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

  
defmodule FullPSGossip do
    
    def spawnFullActors(numOfNodes, nodeCount, pIndex, list)  do
      if nodeCount != numOfNodes do
        pid = spawn(__MODULE__, :startFullPushSum, [pIndex, 1, 0, nil]);
        list = list ++ [pid];
        spawnFullActors(numOfNodes, nodeCount + 1,pIndex+1, list)
      else
        list
      end    
    end
  
    def messageAllNodesToAddNeighbors(pid, list) do
      newList = List.delete(list, pid)
      send(pid, {:add_neighbors, list});
    end
  
    def startFullPushSum(sVal, wVal, count, agent_link) do
      receive do
        {:add_neighbors, n_pid} ->  {:ok, agent_link} = FullPSAgent.start_link(n_pid);
                                    FullPSGossip.startFullPushSum(sVal, wVal, count, agent_link);
  
        {:push_sum, ppid, {new_s, new_w}} ->  if(count == 3) do
                                                IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
                                                Process.exit(self(), :kill);
                                              else  
                                                IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " S: #{sVal + new_s}" <> " W: #{wVal}");
                                                neighborPid = FullPSAgent.get_random_neighbor(agent_link);
                                                case neighborPid do
                                                    nil -> Process.exit(self(), :kill);
                                                    _ -> send(neighborPid, {:push_sum, self(), {(sVal + new_s)/2, (wVal + new_w)/2}});
                                                          # if count == 1 do
                                                          #   spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message]);
                                                          # end
                                                          end
                                                if(((new_s/new_w) - (sVal/wVal)) <= :math.pow(10,-10)) do
                                                  FullPSGossip.startFullPushSum((sVal + new_s)/2,(wVal + new_w)/2,count+1, agent_link);
                                                else
                                                  FullPSGossip.startFullPushSum((sVal + new_s)/2, (wVal + new_w)/2, count, agent_link);
                                                end
                                              end 
      end
    end
  end
end

  defmodule TwoDPSGossip do
    def spawnFullActors(numOfNodes, nodeCount, pIndex, list)  do
      if nodeCount != numOfNodes do
        pid = spawn(__MODULE__, :startFullPushSum, [pIndex, 1, 0, nil]);
        list = list ++ [pid];
        spawnFullActors(numOfNodes, nodeCount + 1,pIndex+1, list)
      else
        list
      end    
    end
  
    def messageAllNodesToAddNeighbors(pid, list) do
      newList = List.delete(list, pid)
      send(pid, {:add_neighbors, list});
    end
  
    def startFullPushSum(sVal, wVal, count, agent_link) do
      receive do
        {:add_neighbors, n_pid} ->  {:ok, agent_link} = TwoDPSAgent.start_link(n_pid);
                                    TwoDPSGossip.startFullPushSum(sVal, wVal, count, agent_link);
  
        {:push_sum, ppid, {new_s, new_w}} ->  if(count == 3) do
                                                IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
                                                Process.exit(self(), :kill);
                                              else  
                                                IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " S: #{sVal + new_s}" <> " W: #{wVal}");
                                                neighborPid = TwoDPSAgent.get_random_neighbor(agent_link);
                                                case neighborPid do
                                                    nil -> Process.exit(self(), :kill);
                                                    _ -> send(neighborPid, {:push_sum, self(), {(sVal + new_s)/2, (wVal + new_w)/2}});
                                                          # if count == 1 do
                                                          #   spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message]);
                                                          # end
                                                          end
                                                if(((new_s/new_w) - (sVal/wVal)) <= :math.pow(10,-10)) do
                                                  TwoDPSGossip.startFullPushSum((sVal + new_s)/2,(wVal + new_w)/2,count+1, agent_link);
                                                else
                                                  TwoDPSGossip.startFullPushSum((sVal + new_s)/2, (wVal + new_w)/2, count, agent_link);
                                                end
                                              end 
      end
    end
    
  end

  defmodule TwoDImpPSGossip do
    def spawnFullActors(numOfNodes, nodeCount, pIndex, list)  do
      if nodeCount != numOfNodes do
        pid = spawn(__MODULE__, :startFullPushSum, [pIndex, 1, 0, nil]);
        list = list ++ [pid];
        spawnFullActors(numOfNodes, nodeCount + 1,pIndex+1, list)
      else
        list
      end    
    end
  
    def messageAllNodesToAddNeighbors(pid, list) do
      newList = List.delete(list, pid)
      send(pid, {:add_neighbors, list});
    end
  
    def startFullPushSum(sVal, wVal, count, agent_link) do
      receive do
        {:add_neighbors, n_pid} ->  {:ok, agent_link} = TwoDPSAgent.start_link(n_pid);
              TwoDImpPSGossip.startFullPushSum(sVal, wVal, count, agent_link);
  
        {:push_sum, ppid, {new_s, new_w}} ->  if(count == 3) do
                                                IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
                                                Process.exit(self(), :kill);
                                              else  
                                                IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " S: #{sVal + new_s}" <> " W: #{wVal}");
                                                neighborPid = TwoDPSAgent.get_random_neighbor(agent_link);
                                                case neighborPid do
                                                    nil -> Process.exit(self(), :kill);
                                                    _ -> send(neighborPid, {:push_sum, self(), {(sVal + new_s)/2, (wVal + new_w)/2}});
                                                          # if count == 1 do
                                                          #   spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message]);
                                                          # end
                                                          end
                                                if(((new_s/new_w) - (sVal/wVal)) <= :math.pow(10,-10)) do
                                                  TwoDImpPSGossip.startFullPushSum((sVal + new_s)/2,(wVal + new_w)/2,count+1, agent_link);
                                                else
                                                  TwoDImpPSGossip.startFullPushSum((sVal + new_s)/2, (wVal + new_w)/2, count, agent_link);
                                                end
                                              end 
      end
    end
  end
  
   
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  # def startFullPushSum(s,w, agent_link) when count > totRepeat do
    #   IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
    #   Process.exit(self(), :kill);
    # end
    
    # def spreadGossipPeriodically(agent_link, ppid, message) do
    #   neighborPid = FullPSAgent.get_random_neighbor(agent_link);
    #       case neighborPid do
    #            nil -> Process.exit(self(), :kill);
    #            _ ->   send(neighborPid, {:gossip, self(), message});
    #                   spreadGossipPeriodically(agent_link, ppid, message);
    #       end 
    #   end

# LINE TOPOLOGY

#   defmodule LineAgent do
#     use Agent
  
#     def start_link do
#       Agent.start_link(fn -> [] end)
#     end
  
#     def add_neighbor(agent_link, pid, neighbor_pid) do
#       Agent.update(agent_link, fn list -> [neighbor_pid | list] end)
      
#     end
  
#     def get_random_neighbor(agent_link) do
#       list_R = Agent.get(agent_link, fn list -> list end)
#       case list_R do
#         [] -> n_pid = nil;
  
#         list_R -> n_pid = Enum.random(list_R);
#             unless Process.alive?(n_pid) do
#               Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
#               list_RU = Agent.get(agent_link, fn(list) -> list end)
#               n_pid = List.first(list_RU)
#           end
#         end
#         n_pid
#     end
# end
  
# defmodule LineGossip do
#     def spawnLineActors(numOfNodes, nodeCount, totRepeat, prevPid) when nodeCount == 0 do
#       pid = spawn(__MODULE__, :startGossiping, [1, totRepeat, nil]);
#       spawnLineActors(numOfNodes, nodeCount+1, totRepeat, pid);
#       pid
#     end
  
#     def spawnLineActors(numOfNodes, nodeCount, totRepeat, prevPid) when (nodeCount < numOfNodes and nodeCount > 0) do
#              pid = spawn(__MODULE__, :startGossiping, [1, totRepeat,nil]);
#              send(pid, {:add_neighbor, prevPid})
#              send(prevPid, {:add_neighbor, pid})
#              spawnLineActors(numOfNodes, nodeCount+1, totRepeat, pid);
#     end
  
#     def spawnLineActors(numOfNodes, nodeCount, _,  _) when nodeCount == numOfNodes do
#     end
  
#     def startGossiping(count, totRepeat, agent_link) when count <= totRepeat   do
#       if agent_link == nil do
#         {:ok, agent_link} = LineAgent.start_link
#      end
#      receive do
#           {:add_neighbor, n_pid} -> LineAgent.add_neighbor(agent_link, self(), n_pid);
#                                     startGossiping(count,totRepeat, agent_link);
  
#           {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                       neighborPid = LineAgent.get_random_neighbor(agent_link);
#                                       case neighborPid do
#                                         nil -> IO.puts "I have no more neighbors PID: -- "<> List.to_string :erlang.pid_to_list self(); Process.exit(self(), :kill);
#                                         _ -> send(neighborPid, {:gossip, self(), message});
#                                             if count == 1 do
#                                               spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message]);
#                                             end
#                                             startGossiping(count+1,totRepeat, agent_link);
#                                       end
#       end
#     end
    
  
#     def spreadGossipPeriodically(agent_link, ppid, message) do
#       Process.sleep(100);
#         neighborPid = LineAgent.get_random_neighbor(agent_link)
#           case neighborPid do
#             nil -> IO.puts "I have no more neighbors PID: -- "<> List.to_string :erlang.pid_to_list ppid; Process.exit(ppid, :kill);
#             _ -> send(neighborPid, {:gossip, ppid, message});
#                       spreadGossipPeriodically(agent_link, ppid, message);
#             end
#       end
    
#     def startGossiping(count, totRepeat, _ ) when count > totRepeat do
#       IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
#       Process.exit(self(), :kill);
#       #GenServer.cast(server, {:termination_message, self()});
#     end
  
#   end
  
#   # TwoD GOSSIP

#   defmodule TwoDAgent do
    
#     def start_link(args \\ []) do
#       Agent.start_link(fn -> args end)
#     end
  
#     def add_neighbors(agent_link, listOfPid) do
#       Agent.update(agent_link, fn list -> listOfPid end);
#     end
  
#     def get_random_neighbor(agent_link) do
#       list_R = Agent.get(agent_link, fn list -> list end)
#       case list_R do
#         [] -> n_pid = nil;
  
#         list_R -> n_pid = Enum.random(list_R); 
#             unless Process.alive?(n_pid) do
#               Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
#               list_RU = Agent.get(agent_link, fn(list) -> list end)
#               n_pid = get_random_neighbor(agent_link);
#           end
#         end
#         n_pid
#     end
  
#   end
  
#   defmodule TwoDGossip do
    
#     def spawn2DActors(numOfNodes, totRepeat, rC, cC, power, map) do
#       if(rC == power) do
#         map
#       else
#         pid = spawn(__MODULE__, :startTwoDGossip, [1,totRepeat,nil])
#         if(cC == 0) do
#           map = Map.put(map, rC, %{});
#         end
#         mapInMap = Map.get(map, rC);
#         newMap = Map.put(mapInMap, cC, pid);
#         map = Map.put(map, rC, newMap);      
#         if(cC + 1 == power) do
#           spawn2DActors(numOfNodes, totRepeat, rC+1, 0, power, map)
#         else
#           spawn2DActors(numOfNodes, totRepeat, rC, cC+1, power, map)
#         end
#       end
#     end
  
#     def setupNeighbors(map, rC, cC, power) do
#       if(rC < power) do
#         list = []
#         if rC-1 >= 0 do
#           list = [map[rC-1][cC]] ++ list; 
#         end
#         if rC+1 < power do
#           list = [map[rC+1][cC]] ++ list; 
#         end
#         if cC-1 >= 0 do
#           list = [map[rC][cC-1]] ++ list; 
#         end
#         if cC+1 < power do
#           list = [map[rC][cC+1]] ++ list; 
#         end
#         send(map[rC][cC], {:add_neighbors, list});
#         if(cC+1 == power) do
#           setupNeighbors(map, rC + 1, 0, power);
#         else
#           setupNeighbors(map,rC,cC+1, power)
#         end
#       end
#     end
  
  
#     def startTwoDGossip(count, totRepeat, agent_link) when count <= totRepeat do
#       receive do
#         {:add_neighbors, listOfPid} -> #TwoDAgent.add_neighbors(agent_link, listOfPid);
#                                         {:ok, agent_link} = TwoDAgent.start_link(listOfPid); startTwoDGossip(count, totRepeat, agent_link);
  
#         {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                     neighborPid = TwoDAgent.get_random_neighbor(agent_link);
#                                     case neighborPid do
#                                         nil -> Process.exit(self(), :normal);
#                                         _ -> send(neighborPid, {:gossip, self(), message});
#                                               if count == 1 do
#                                                 spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message]);
#                                               end
#                                               startTwoDGossip(count+1, totRepeat, agent_link);
#         end
#       end 
#     end
  
#     def startTwoDGossip(count, totRepeat, agent_link) when count > totRepeat do
#       IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
#       Process.exit(self(), :normal);
#     end
  
#     def spreadGossipPeriodically(agent_link, ppid, message) do
#       Process.sleep(1);
#       neighborPid = TwoDAgent.get_random_neighbor(agent_link);
#           case neighborPid do
#                nil -> Process.exit(self(), :normal);
#                _ ->   send(neighborPid, {:gossip, self(), message});
#                       spreadGossipPeriodically(agent_link, ppid, message);
#           end 
#       end
#   end

# # TwoD Imperfect Gossip

# defmodule TwoDImpGossip do
    
#     def spawn2DActors(numOfNodes, totRepeat, rC, cC, power, map, list) do
#       if(rC == power) do
#         {map, list}
#       else
#         pid = spawn(__MODULE__, :startTwoDGossip, [1,totRepeat, nil])
#         list = list ++ [pid]
#         if(cC == 0) do
#           map = Map.put(map, rC, %{});
#         end
#         mapInMap = Map.get(map, rC);
#         newMap = Map.put(mapInMap, cC, pid);
#         map = Map.put(map, rC, newMap);      
#         if(cC + 1 == power) do
#           spawn2DActors(numOfNodes, totRepeat, rC+1, 0, power , map, list)
#         else
#           spawn2DActors(numOfNodes, totRepeat, rC, cC+1, power, map, list)
#         end
#       end
#     end
  
#     def returnRandomNeighbor(listOfPids, list) do
#       case list do
#         [] -> Enum.random(listOfPids);
#         [head | tail] -> returnRandomNeighbor(List.delete(listOfPids, head),tail);
#       end    
#     end
  
#     def setupNeighbors(map, rC, cC, power, listOfPids) do
#       if(rC < power) do
#         list = []
#         if rC-1 >= 0 do
#           list = [map[rC-1][cC]] ++ list; 
#         end
#         if rC+1 < power do
#           list = [map[rC+1][cC]] ++ list; 
#         end
#         if cC-1 >= 0 do
#           list = [map[rC][cC-1]] ++ list; 
#         end
#         if cC+1 < power do
#           list = [map[rC][cC+1]] ++ list; 
#         end
#         randomNeighbor = returnRandomNeighbor(listOfPids, [map[rC][cC]] ++ list);
#         list = [randomNeighbor] ++ list
#         send(map[rC][cC], {:add_neighbors, list});
#         if(cC+1 == power) do
#           setupNeighbors(map, rC + 1, 0, power, listOfPids);
#         else
#           setupNeighbors(map,rC,cC+1, power, listOfPids)
#         end
#       end
#     end
  
  
#     def startTwoDGossip(count, totRepeat, agent_link)when count <= totRepeat do
#       receive do
#         {:add_neighbors, listOfPid} -> #TwoDAgent.add_neighbors(agent_link, listOfPid);
#                                         {:ok, agent_link} = TwoDAgent.start_link(listOfPid); startTwoDGossip(count, totRepeat, agent_link);
  
#         {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                     neighborPid = TwoDAgent.get_random_neighbor(agent_link);
#                                     case neighborPid do
#                                         nil -> Process.exit(self(), :normal);
#                                         _ -> send(neighborPid, {:gossip, self(), message});
#                                               if count == 1 do
#                                                 spawn(__MODULE__, :spreadGossipPeriodically, [agent_link, self(), message]);
#                                               end
#                                               startTwoDGossip(count+1,totRepeat,agent_link);
#         end
#       end 
#     end
  
#     def startTwoDGossip(count, totRepeat, agent_link) when count > totRepeat do
#       IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
#       Process.exit(self(), :normal);
#     end
  
#     def spreadGossipPeriodically(agent_link, ppid, message) do
#       Process.sleep(1);
#       neighborPid = TwoDAgent.get_random_neighbor(agent_link);
#           case neighborPid do
#                nil -> Process.exit(self(), :normal);
#                _ ->   send(neighborPid, {:gossip, self(), message});
#                       spreadGossipPeriodically(agent_link, ppid, message);
#           end 
#       end
#   end
  