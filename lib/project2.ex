
defmodule Project2.CLI do
  # Command Line arguments are passed in args list
  def main(args \\ []) do
    args_tuple = List.to_tuple args
    {numOfNodes, topology, algorithm} = args_tuple
    totRepeat = 10;
    case algorithm do
      "gossip" ->
          case topology do
            "full" -> list = FullGossip.spawnFullActors(String.to_integer(numOfNodes), 0, totRepeat,[], self());
                  for x <- 0..String.to_integer(numOfNodes)-1 do
                    newList = List.delete_at(list, x);
                    {pid, _} = List.pop_at(list, x);
                    send(pid, {:add_neighbors, newList});
                  end
                  pid = List.first(list);

            "line" -> pid = LineGossip.spawnLineActors(String.to_integer(numOfNodes), 0, totRepeat, nil, self);

            "2D" -> 
                    sqRt = trunc(Float.ceil(:math.sqrt(String.to_integer(numOfNodes))));
                    map = TwoDGossip.spawn2DActors(String.to_integer(numOfNodes), totRepeat,0,0,sqRt, %{}, self);
                    TwoDGossip.setupNeighbors(map,0,0,sqRt);
                    pid = map[0][0]
            "2DImp" -> 
                    sqRt = trunc(Float.ceil(:math.sqrt(String.to_integer(numOfNodes))));
                    {map,listOfPids} = TwoDImpGossip.spawn2DActors(String.to_integer(numOfNodes),totRepeat, 0,0,sqRt, %{}, [], self);
                    TwoDImpGossip.setupNeighbors(map,0,0,sqRt, listOfPids);
                    pid = map[0][0]
          end
          IO.puts(List.to_string(:erlang.pid_to_list(self())) <> " --> " <> List.to_string(:erlang.pid_to_list(pid)));
          send(pid, {:gossip, self(), "something"});
          keepAwake(1, String.to_integer(numOfNodes), :os.system_time(:microsecond))
      "push-sum" -> 
        case topology do
          "full" -> list = FullPSGossip.spawnFullActors(String.to_integer(numOfNodes), 0, 1, [], self());
                    for x <- 0..String.to_integer(numOfNodes)-1 do
                      newList = List.delete_at(list, x);
                      {pid, _} = List.pop_at(list, x);
                      send(pid, {:add_neighbors, newList});
                    end
                    pid = List.first(list);
                   end
        send(pid, {:start_push_sum, self()});
        keepAwakeForPushSum(1, String.to_integer(numOfNodes), :os.system_time(:microsecond), list)
        end
  end  

  def keepAwake(count, numOfNodes, startTime) do
    if(count > numOfNodes) do
      IO.puts (:os.system_time(:microsecond) - startTime);
    else
      receive do
        {:dead_process} -> keepAwake(count+1, numOfNodes, startTime); 
      end
    end
  end

  def keepAwakeForPushSum(count, numOfNodes, startTime, list) do
    if(count > numOfNodes) do
      IO.puts (:os.system_time(:microsecond) - startTime);
    else
      receive do
        {:dead_process, pid} -> list = List.delete(list, pid);
                                new_pid = Enum.random(list);
                                send(new_pid, {:update_neighbors, List.delete(list, pid)})
                                send(new_pid, {:start_push_sum, self()});
                                keepAwake(count+1, numOfNodes, startTime); 
      end
    end
  end

end

# IGNORE THE REST, I HAVE MODULARIZED IT

# defmodule GossipServer do
#   use GenServer

#   def start_link do
#     GenServer.start_link(__MODULE__, %{}, name: Gossip)
#   end

#   def init(%{}) do
#     {:ok, %{}}
#   end

#   def handle_call({:initialize_topology, top_type}, _from, state) do
#     Map.put(state, :top_type, top_type)
#     case top_type do
#       "full" -> {:reply, :ok, Map.put(state, :full, [])};
#       "2D" -> {:reply, :ok, Map.put(state, :twoD, %{})};
#       "line" -> {:reply, :ok, Map.put(state, :line, [])};
#       "2DImp" -> {:reply, :ok, Map.put(state, :twoDImp, %{})};
#     end
#   end

#   def handle_call({:get_neighbor, topology, pid}, _from, state) do
#     case topology do
#       "full" -> list = Map.get(state, :full);
#                 new_list = List.delete(list, pid);
#                 case new_list do
#                   [] -> {:reply, nil, state}
#                   _ -> {:reply, Enum.random(new_list), state}
#                 end
      
#     end
#   end

#   def handle_call({:add_actor, topology, pid}, _from, state) do
#     case topology do
#       "full"-> list = Map.get(state, :full)
#                list = [pid] ++ list
#                {:reply, :ok, Map.put(state, :full, list)}
#     end  
#   end

#   def handle_call({:get_first_actor, topology}, _from, state) do
#     case topology do
#       "full" -> [first | tail] = Map.get(state, :full)
#     end
#     {:reply, first, state} 
#   end

#   def handle_cast({:termination_message, pid}, state) do
#     {:noreply, Map.put(state, :full, List.delete(Map.get(state, :full), pid))};
#   end
# end

# defmodule LineAgent do
#   use Agent

#   def start_link do
#     Agent.start_link(fn -> [] end)
#   end

#   def add_neighbor(agent_link, pid, neighbor_pid) do
#     Agent.update(agent_link, fn list -> [neighbor_pid | list] end)
    
#   end

#   def get_random_neighbor(agent_link) do
#     list_R = Agent.get(agent_link, fn list -> list end)
#     case list_R do
#       [] -> n_pid = nil;

#       list_R -> n_pid = Enum.random(list_R);
#           unless Process.alive?(n_pid) do
#             Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
#             list_RU = Agent.get(agent_link, fn(list) -> list end)
#             n_pid = List.first(list_RU)
#         end
#       end
#       n_pid
#   end
# end

# defmodule FullAgent do
#   use Agent

#   def start_link(args \\ []) do
#     Agent.start_link(fn -> args end)
#   end

#   def add_neighbor(agent_link, neighbor_pid) do
#     Agent.update(agent_link, fn list -> [neighbor_pid | list] end)
    
#   end

#   def get_random_neighbor(agent_link) do
#     list_R = Agent.get(agent_link, fn list -> list end)
#     case list_R do
#       [] -> n_pid = nil;

#       list_R -> n_pid = Enum.random(list_R);
#           unless Process.alive?(n_pid) do
#             Agent.update(agent_link, fn(list) -> List.delete(list_R, n_pid) end);
#             list_RU = Agent.get(agent_link, fn(list) -> list end)
#             n_pid = get_random_neighbor(agent_link);
#         end
#       end
#       n_pid
#   end


#    def get_all_neighbors(agent_link) do
#       Agent.get(agent_link, fn(list) -> list end)
#    end
# end

# defmodule FullGossip do
  
#   def spawnFullActors(topology, numOfNodes, nodeCount, list)  do
#     if nodeCount != numOfNodes do
#       pid = spawn(__MODULE__, :startFullGossip, [1, topology, nil]);
#       list = list ++ [pid];
#       spawnFullActors(topology, numOfNodes, nodeCount + 1, list)
#     else
#       list
#     end    
#   end

#   def messageAllNodesToAddNeighbors(pid, list) do
#     newList = List.delete(list, pid)
#     send(pid, {:add_neighbors, list});
#   end

#   def startFullGossip(count, topology, agent_link) when count < 5 do
#     receive do
#       {:add_neighbors, n_pid} ->  {:ok, agent_link} = FullAgent.start_link(n_pid);
#                                   startFullGossip(count, topology, agent_link);

#       {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                   neighborPid = FullAgent.get_random_neighbor(agent_link);
#                                   case neighborPid do
#                                       nil -> Process.exit(self(), :kill);
#                                       _ -> send(neighborPid, {:gossip, self(), message});
#                                             if count == 1 do
#                                               spawn(__MODULE__, :spreadGossipPeriodically, [topology, agent_link, self(), message]);
#                                             end
#                                             startFullGossip(count+1,topology,agent_link);
#                                   end 
#     end
#   end

#   def startFullGossip(count, topology, agent_link) when count == 5 do
#     IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
#     Process.exit(self(), :kill);
#   end
  
#   def startGossiping(count, topology,agent_link) when count < 15   do
#     if agent_link == nil do
#       {:ok, agent_link} = LineAgent.start_link
#    end
#     receive do
#         {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                     neighborPid = GenServer.call(Gossip, {:get_neighbor, topology, self()});
#                                     case neighborPid do
#                                        nil -> Process.exit(self(), :kill);
#                                         _ -> send(neighborPid, {:gossip, self(), message});
#                                               if count == 1 do
#                                                 spawn(__MODULE__, :spreadGossipPeriodically, [topology, agent_link, self(), message]);
#                                               end
#                                             startGossiping(count+1,topology,agent_link);
#                                       end 
#             end

#       end
  
#   def spreadGossipPeriodically(topology, agent_link, ppid, message) do
#     Process.sleep(100);
#     neighborPid = FullAgent.get_random_neighbor(agent_link);
#         case neighborPid do
#              nil -> Process.exit(self(), :kill);
#              _ ->   send(neighborPid, {:gossip, self(), message});
#                     spreadGossipPeriodically(topology, agent_link, ppid, message);
#         end 
#     end

#   def startGossiping(count, _ , _) when count >= 15 do
#     IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
#     Process.exit(self(), :kill);
#     #GenServer.cast(server, {:termination_message, self()});
#   end


# end

# defmodule LineGossip do
#   def spawnLineActors(topology, numOfNodes, nodeCount, prevPid) when nodeCount == 0 do
#     pid = spawn(__MODULE__, :startGossiping, [1, "line", nil]);
#     spawnLineActors(topology, numOfNodes, nodeCount+1, pid);
#     pid
#   end

#   def spawnLineActors(topology, numOfNodes, nodeCount, prevPid) when (nodeCount < numOfNodes and nodeCount > 0) do
#            pid = spawn(__MODULE__, :startGossiping, [1, "line",nil]);
#            send(pid, {:add_neighbor, prevPid})
#            send(prevPid, {:add_neighbor, pid})
#            spawnLineActors(topology, numOfNodes, nodeCount+1,  pid);
#   end

#   def spawnLineActors(topology, numOfNodes, nodeCount, prevPid) when nodeCount == numOfNodes do
#   end

#   def startGossiping(count, topology,agent_link) when count < 15   do
#     if agent_link == nil do
#       {:ok, agent_link} = LineAgent.start_link
#    end
#     case topology do
#       "full"->receive do
#                 {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                       neighborPid = GenServer.call(Gossip, {:get_neighbor, topology, self()});
#                                       case neighborPid do
#                                         nil -> Process.exit(self(), :kill);
#                                         _ -> send(neighborPid, {:gossip, self(), message});
#                                               if count == 1 do
#                                                 spawn(__MODULE__, :spreadGossipPeriodically, [topology, agent_link, self(), message]);
#                                               end
#                                             startGossiping(count+1,topology,agent_link);
#                                       end 
#             end
#       "line" -> receive do
#         {:add_neighbor, n_pid} -> LineAgent.add_neighbor(agent_link, self(), n_pid);
#                                   startGossiping(count,topology, agent_link);

#         {:gossip, ppid, message} -> IO.puts(List.to_string(:erlang.pid_to_list(ppid)) <> " --> " <> List.to_string(:erlang.pid_to_list(self())) <> " Count: #{count}");
#                                     neighborPid = LineAgent.get_random_neighbor(agent_link);
#                                     case neighborPid do
#                                       nil -> IO.puts "I have no more neighbors PID: -- "<> List.to_string :erlang.pid_to_list self(); Process.exit(self(), :kill);
#                                       _ -> send(neighborPid, {:gossip, self(), message});
#                                           if count == 1 do
#                                             spawn(__MODULE__, :spreadGossipPeriodically, [topology, agent_link, self(), message]);
#                                           end
#                                           startGossiping(count+1,topology, agent_link);
#                                     end
#         end
#       end
#   end

#   def spreadGossipPeriodically(topology, agent_link, ppid, message) do
#     Process.sleep(100);
#     case topology do
#       "full" -> neighborPid = FullAgent.get_random_neighbor(agent_link);
#                 case neighborPid do
#                  nil -> Process.exit(self(), :kill);
#                  _ -> send(neighborPid, {:gossip, self(), message});
#                       spreadGossipPeriodically(topology, agent_link, ppid, message);
#       end 

#       "line" -> neighborPid = LineAgent.get_random_neighbor(agent_link)
#               case neighborPid do
#                 nil -> IO.puts "I have no more neighbors PID: -- "<> List.to_string :erlang.pid_to_list ppid; Process.exit(ppid, :kill);
#                 _ -> send(neighborPid, {:gossip, ppid, message});
#                     spreadGossipPeriodically(topology, agent_link, ppid, message);
#       end
#     end
    
#   end

#   def startGossiping(count, _ , _) when count >= 15 do
#     IO.puts ("I am done gossiping PID: -- "<> List.to_string :erlang.pid_to_list(self()));
#     Process.exit(self(), :kill);
#     #GenServer.cast(server, {:termination_message, self()});
#   end

# end


  # def spawnActors(topology, numOfNodes)  when numOfNodes > 0 do
  #   case topology do
  #     "full" -> pid = spawn(__MODULE__, :startGossiping, [Gossip, 1, topology])
  #               GenServer.call(Gossip, {:add_actor, topology, pid})
  #               spawnActors(topology, numOfNodes-1);
  #   end
  # end



  # def spawnFullActors(topology, numOfNodes, nodeCount, listOfPid) when (nodeCount < numOfNodes and nodeCount > 0) do
  #   pid = spawn(__MODULE__, :startFullGossip, [1, topology, nil, listOfPid]);
  #   spawnFullActors(topology, numOfNodes, nodeCount + 1, [pid | listOfPid])
  # end


  # def spawnActors(_, numOfNodes)  when numOfNodes == 0 do
  # end