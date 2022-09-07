local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local resources = replicatedStorage:WaitForChild("Resources")

local remotesFolder = resources:FindFirstChild("RemotesFolder")
if remotesFolder == nil then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "RemotesFolder"
	remotesFolder.Parent = resources
end

local isClient = not runService:IsServer()

type Callback = (...any) -> nil
type ConnectionArray = {[number]: RBXScriptSignal}
type Remote = {
	Connection: RBXScriptSignal | nil,
	Destroy: () -> nil
}

local remotes = {
	connections = {} -- ConnectionArray (no clue how to make this typed, revise later)
}

local function getRemote(remote: string, folder: Instance?): Instance
	local f = folder or remotesFolder
	return f:WaitForChild(remote)
end

local function listenEvent(eventName: string, callback: Callback): Remote
	local event = getRemote(eventName)
	local connection: RBXScriptSignal
	if isClient then
		connection = event.OnClientEvent:Connect(callback)
	else
		connection = event.OnServerEvent:Connect(callback)
	end
	table.insert(remotes.connections, connection)

	return {
		Connection = connection,
		Destroy = function(self)
			connection:Disconnect()
			connection = nil
			self.Connection = nil
		end
	}
end

local function listenFunction(funcName: string, callback: Callback): Remote
	local func = getRemote(funcName)
	if isClient then
		func.OnClientInvoke = callback
	else
		func.OnServerInvoke = callback
	end

	return {
		Connection = nil,
		Destroy = function()
			func.OnFunctionInvoke = nil
		end
	}
end

remotes.listenEvent = listenEvent
remotes.listenFunction = listenFunction

local function fireEvent(eventName, ...: any)
	local event: RemoteEvent = getRemote(eventName)
	if isClient then
		event:FireServer(...)
	else
		event:FireClient(...)
	end
end

local function fireAllEvent(eventName, ...: any)
	local event: RemoteEvent = getRemote(eventName)
	if not isClient then
		event:FireAllClients(...)
	end
end

local function fireFunction(functionName, ...: any)
	local func = getRemote(functionName)

	if isClient then
		return func:InvokeServer(...)
	else
		return func:InvokeClient(...)
	end
end

remotes.fireEvent = fireEvent
remotes.fireAllEvent = fireAllEvent
remotes.fireFunction = fireFunction

local function createEvent(name: string): string
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotesFolder
	return name
end

local function createFunction(name: string): string
	local event = Instance.new("RemoteFunction")
	event.Name = name
	event.Parent = remotesFolder
	return name
end
remotes.createEvent = createEvent
remotes.createFunction = createFunction

return remotes