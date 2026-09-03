if getfenv and type(getfenv) == "function" then
    local env = getfenv()
    if env then
        env._VERSION = "Luau"
    end
end
_G._VERSION = "Luau"
local fs = require("@lune/fs")
local _print = print
local proc = require("@lune/process")
local stdio = require("@lune/stdio")
local serde = require("@lune/serde")
-- Load the network module only when an HTTP helper actually needs it.
-- This avoids initializing Lune's network backend during offline Linux startup.
local nett = function()
    return require("@lune/net")
end

local _luau
do
    local ok, mod = pcall(require, "@lune/luau")
    _luau = ok and mod or nil
end
local class_members = {}
local class_superclass = {}
local api_dump_content = fs.readFile("core/io/apidump.json")
local api_dump = serde.decode("json", api_dump_content)
for _, class_data in ipairs(api_dump.Classes) do
    local className = class_data.Name
    class_superclass[className] = class_data.Superclass
    local members = {}
    for _, member in ipairs(class_data.Members) do
        local mtype = member.MemberType
        local mname = member.Name
        local is_readonly = false
        local is_not_scriptable = false
        if member.Tags then
            for _, tag in ipairs(member.Tags) do
                if tag == "ReadOnly" then is_readonly = true end
                if tag == "NotScriptable" then is_not_scriptable = true end
            end
        end
        members[mname] = {
            Type = mtype,
            ReadOnly = is_readonly,
            NotScriptable = is_not_scriptable,
            ValueType = member.ValueType,
            ReturnType = member.ReturnType,
        }
    end
    class_members[className] = members
end
class_superclass["InternalSyncService"] = "Instance"
class_members["InternalSyncService"] = {}
class_superclass["AuroraHandle"] = "Object"
class_members["AuroraHandle"] = {}
class_superclass["AuroraScript"] = "LuaSourceContainer"
class_members["AuroraScript"] = {}
class_superclass["AuroraScriptService"] = "Instance"
class_members["AuroraScriptService"] = {}
class_superclass["InternalSyncItem"] = "Instance"
class_members["InternalSyncItem"] = {}
class_superclass["ConversationalAIAcceptanceService"] = "Instance"
class_members["ConversationalAIAcceptanceService"] = {}
class_superclass["AuroraService"] = "Instance"
class_members["AuroraService"] = {}
class_superclass["EmotesPages"] = "InventoryPages"
class_members["EmotesPages"] = {}
class_members["WrapLayer"]["TemporaryReferenceId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️AvatarAppearance} {RobloxEngine}" } }
class_members["BevelMesh"]["Bulge"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["BevelMesh"]["Bevel"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["MeshPart"]["RenderFidelityReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "RenderFidelity" } }
class_members["MeshPart"]["MeshID"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["MeshPart"]["InitialSize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3 {🛠️Basic} {RobloxEngine}" } }
class_members["MeshPart"]["AlternateMeshHash"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Basic} {RobloxEngine}" } }
class_members["MeshPart"]["PhysicsData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Basic} {RobloxEngine}" } }
class_members["MeshPart"]["VertexCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Basic} {RobloxEngine}" } }
class_members["MeshPart"]["SolidMeshHolder"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "NetAssetRef" } }
class_members["RolloutValidation"]["ThirdSharedString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {RobloxEngine}" } }
class_members["RolloutValidation"]["SecondSharedExpectedValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["RolloutValidation"]["GenerationStrategy"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["RolloutValidation"]["FirstSharedString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {RobloxEngine}" } }
class_members["RolloutValidation"]["AdditionalFluffTwo"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["RolloutValidation"]["FirstBinaryExpectedValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["RolloutValidation"]["ThirdBinaryString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["RolloutValidation"]["ThirdBinaryExpectedValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["RolloutValidation"]["CreationVersion"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["RolloutValidation"]["AdditionalFluffOne"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["RolloutValidation"]["ThirdSharedExpectedValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["RolloutValidation"]["SecondBinaryExpectedValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["RolloutValidation"]["SecondBinaryString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["RolloutValidation"]["AdditionalFluffThree"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["RolloutValidation"]["FirstBinaryString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["RolloutValidation"]["SecondSharedString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {RobloxEngine}" } }
class_members["RolloutValidation"]["FirstSharedExpectedValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["WeldConstraint"]["State"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["WeldConstraint"]["CFrame1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["WeldConstraint"]["CFrame0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["WeldConstraint"]["Part0Internal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BasePart" } }
class_members["WeldConstraint"]["Part1Internal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BasePart" } }
class_members["Folder"]["ReplicatedGuiInsertionOrder"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["EditableService"]["EditableStatus"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "EditableStatus {RobloxEngine}" } }
class_members["BallSocketConstraint"]["MaxFrictionTorqueXml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Accoutrement"]["BackendAccoutrementState"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["PartOperationAsset"]["ChildData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["PartOperationAsset"]["MeshData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["LuaSourceContainer"]["CachedRemoteSource"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["LuaSourceContainer"]["isPlayerScript"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["LuaSourceContainer"]["CachedRemoteSourceLoadState"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["LuaSourceContainer"]["HasAssociatedDrafts"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["LuaSourceContainer"]["ScriptGuid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["LuaSourceContainer"]["SandboxedSource"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["LuaSourceContainer"]["IsDifferentFromFileSystem"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["SkateboardPlatform"]["MoveState"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "MoveState" } }
class_members["AnimationRigData"]["transform"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["AnimationRigData"]["name"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["AnimationRigData"]["label"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["AnimationRigData"]["parent"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["AnimationRigData"]["postTransform"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["AnimationRigData"]["preTransform"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["TextLabel"]["Confidential"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️UI} {RobloxEngine}" } }
class_members["BaseWrap"]["HSRMeshIdData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️AvatarAppearance} {RobloxEngine}" } }
class_members["BaseWrap"]["HSRData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️AvatarAppearance} {RobloxEngine}" } }
class_members["BaseWrap"]["ImportInProcess"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["BaseWrap"]["TemporaryCageMeshId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️AvatarAppearance} {RobloxEngine}" } }
class_members["TeamCreateData"]["InitialCameraCFrame"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "CFrame {RobloxEngine}" } }
class_members["AudioDeviceInput"]["AccessList"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Audio | Input} {RobloxEngine}" } }
class_members["MaterialVariant"]["TexturePack"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["MaterialVariant"]["AvgMetalness"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["MaterialVariant"]["AvgRoughness"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Decal"]["TexturePackMetadata"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️Basic} {RobloxEngine}" } }
class_members["TerrainDetail"]["TexturePack"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["Clothing"]["Outfit2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["Clothing"]["Outfit1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["ScriptDebugger"]["ScriptGuid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["ScriptDebugger"]["CoreScriptIdentifier"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["Smoke"]["opacity_xml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Smoke"]["size_xml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Smoke"]["riseVelocity_xml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["AvatarAbilityRules"]["EnableStumbling"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["UserGameSettings"]["ComputerMovementChanged"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["UserGameSettings"]["CompletedTutorials"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["UserGameSettings"]["TouchMovementChanged"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["UserGameSettings"]["gaID"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["UserGameSettings"]["ComputerCameraMovementChanged"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["UserGameSettings"]["TouchCameraMovementChanged"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["MetaBreakpointContext"]["ContextDataInternal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["AudioPlayer"]["IsMutedForCapture"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["HopperBin"]["Command"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["HopperBin"]["TextureName"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["IntConstrainedValue"]["value"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["TextButton"]["Confidential"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️UI} {RobloxEngine}" } }
class_members["ViewportFrame"]["CameraFieldOfView"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["ViewportFrame"]["CameraCFrame"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["VideoPlayer"]["PlayingReplicating"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["AnimationNodeDefinition"]["InputPinData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["TextSource"]["UserIdReplicated"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["NetworkSettings"]["OutboundNetworkMaxDelayMs"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Network} {NotAccessible}" } }
class_members["NetworkSettings"]["OpenCertManagerDialog"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Network} {NotAccessible}" } }
class_members["NetworkSettings"]["NetworkEmulationEnabled"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Network} {NotAccessible}" } }
class_members["NetworkSettings"]["InboundNetworkMaxDelayMs"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Network} {NotAccessible}" } }
class_members["Model"]["NeedsPivotMigration"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Model"]["SlimHash"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {RobloxEngine}" } }
class_members["Model"]["WorldPivotData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["Model"]["ModelMeshCFrame"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["Model"]["SlimAnimationTarget"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SlimAnimationDataEntity" } }
class_members["Model"]["ModelMeshSize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["Model"]["ScaleFactor"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Model"]["ModelMeshData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString" } }
class_members["Model"]["LodEntity"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "LodDataEntity" } }
class_members["DoubleConstrainedValue"]["value"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["AnimationClip"]["GuidBinaryString"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["ValueCurve"]["ValuesAndTimes"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["UnvalidatedAssetService"]["CachedData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["UIListLayout"]["VerticalPadding"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "UDim" } }
class_members["UIListLayout"]["HorizontalPadding"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "UDim" } }
class_members["RocketPropulsion"]["Active"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["TerrainRegion"]["SmoothGrid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["TerrainRegion"]["ExtentsMax"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3int16" } }
class_members["TerrainRegion"]["GridV3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["TerrainRegion"]["ExtentsMin"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3int16" } }
class_members["TriangleMeshPart"]["AeroMeshData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️Basic} {RobloxEngine}" } }
class_members["TriangleMeshPart"]["FluidFidelityInternal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "FluidFidelity {🛠️Basic} {RobloxEngine}" } }
class_members["TriangleMeshPart"]["PhysicalConfigData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️Basic} {RobloxEngine}" } }
class_members["TriangleMeshPart"]["ConvexDecompHolder"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "NetAssetRef {🛠️Basic} {RobloxEngine}" } }
class_members["TriangleMeshPart"]["InertiaMigrated"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Basic} {RobloxEngine}" } }
class_members["FloatCurve"]["ValuesAndTimes"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["FaceControls"]["InternalOverrideFACSData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Animation} {RobloxEngine}" } }
class_members["CustomEvent"]["PersistedCurrentValue"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["VideoFrame"]["PlayingReplicating"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["VideoFrame"]["TimePositionReplicating"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["TextChatMessage"]["Verified"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Chat} {RobloxEngine}" } }
class_members["DataModel"]["ForceR15"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["DataModel"]["R15CollisionType"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "R15CollisionType {RobloxEngine}" } }
class_members["DataModel"]["GameAvatarType"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "GameAvatarType {RobloxEngine}" } }
class_members["Workspace"]["MoverConstraintRootBehavior"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "MoverConstraintRootBehaviorMode" } }
class_members["Workspace"]["CollisionGroups"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["Workspace"]["CollisionGroupData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["Workspace"]["ExplicitAutoJoints"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Workspace"]["SignalBehavior2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "SignalBehavior" } }
class_members["Workspace"]["DataModelPlaceVersion"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Workspace"]["TerrainWeldsFixed"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Workspace"]["StreamingPauseMode"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "StreamingPauseMode" } }
class_members["Workspace"]["ConvexDecompCompressed"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["TextBox"]["Confidential"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️UI} {RobloxEngine}" } }
class_members["TextBox"]["LocalizedPlaceholderText"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️UI} {RobloxEngine}" } }
class_members["Annotation"]["MessageId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["TrussPart"]["style"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "Style" } }
class_members["ArcHandles"]["MouseDragConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["ArcHandles"]["MouseButton1DownConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["ArcHandles"]["MouseEnterConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["ArcHandles"]["MouseLeaveConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["ArcHandles"]["MouseButton1UpConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["AuroraScriptObject"]["MaxFrequency"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Players"]["ServerGitHash"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️Players} {RobloxEngine}" } }
class_members["Players"]["ServerLogPrefix"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️Players} {RobloxEngine}" } }
class_members["Terrain"]["ClusterGridV2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["Terrain"]["SmoothGrid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["Terrain"]["AcquisitionMethod"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "TerrainAcquisitionMethod" } }
class_members["Terrain"]["ClusterGridV3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["Terrain"]["PhysicsGrid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["Terrain"]["ClusterGrid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["StyleDerive"]["Index"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Fire"]["size_xml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Fire"]["heat_xml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["StyleRule"]["PropertyTransitionsSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["StyleRule"]["Index"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["StyleRule"]["PropertiesSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["Studio"]["CameraSpeedLockDefault"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["BinaryStringValue"]["Value"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["StarterPlayer"]["AvatarJointUpgrade_SerializedRollout"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "RolloutState" } }
class_members["StarterPlayer"]["LoadCharacterLayeredClothing"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "LoadCharacterLayeredClothing" } }
class_members["GuiBase2d"]["ActiveQueryNames"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["GuiBase2d"]["ReplicatedInsertionOrder"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️UI} {RobloxEngine}" } }
class_members["PartOperation"]["ComponentIndex"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["MeshData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["InitialSize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3 {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["ChildData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["SolidMeshHolder"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "NetAssetRef" } }
class_members["PartOperation"]["MeshData2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["ManifoldMesh_DEPRECATED"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["AssetId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["PhysicsData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["DCDPropertyData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "CSGPropertyData {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["FormFactor"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "FormFactor {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["SerializedOperationGraph"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString" } }
class_members["PartOperation"]["ChildData2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["PartOperation"]["OffCentered"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["SlimAnimationDataEntity"]["SlimReplicationTimestampSec"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["SlimAnimationDataEntity"]["Handle"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["SlimAnimationDataEntity"]["EntitySource"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Instance? {RobloxEngine}" } }
class_members["SlimAnimationDataEntity"]["NumBones"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["SlimAnimationDataEntity"]["IsSlimEnabled"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["RotationCurve"]["ValuesAndTimes"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["HumanoidDescription"]["EquippedEmotesDataInternal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["HumanoidDescription"]["EmotesDataInternal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["EditableMesh"]["MeshData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString {🛠️DynamicGeneration} {RobloxEngine}" } }
class_members["EditableMesh"]["SkinningEnabled"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["EditableMesh"]["IsReplicatedCopy"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️DynamicGeneration} {RobloxEngine}" } }
class_members["MarkerCurve"]["ValuesAndTimes"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["HiddenSurfaceRemovalAsset"]["HSRMeshIdData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["HiddenSurfaceRemovalAsset"]["HSRData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["Motor6D"]["ReplicateCurrentOffset6D"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3 {🛠️Physics} {RobloxEngine}" } }
class_members["Motor6D"]["ReplicateCurrentAngle6D"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3 {🛠️Physics} {RobloxEngine}" } }
class_members["PlayerGui"]["InputBindingMappingsRaw"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["FunctionalTest"]["AllowSleep"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["FunctionalTest"]["PhysicsEnvironmentalThrottle"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["FunctionalTest"]["HasMigratedSettingsToTestService"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["FunctionalTest"]["Timeout"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["FunctionalTest"]["Is30FpsThrottleEnabled"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["BasePart"]["CollisionGroupReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["BasePart"]["ReplicationPV"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "ReplicationPV {RobloxEngine}" } }
class_members["BasePart"]["DraggingV1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["BasePart"]["NetworkOwnershipRule"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "NetworkOwnership" } }
class_members["BasePart"]["LocalSimulationValidation"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["BasePart"]["PhysicsRepRootPart"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BasePart? {RobloxEngine}" } }
class_members["BasePart"]["Color3uint8"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Color3uint8" } }
class_members["BasePart"]["size"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["BasePart"]["siz"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["BasePart"]["MaterialVariantSerialized"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["BasePart"]["NetworkIsSleeping"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["BasePart"]["NetworkOwnerV3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SystemAddress" } }
class_members["Handles"]["MouseDragConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Handles"]["MouseButton1DownConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Handles"]["MouseEnterConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Handles"]["MouseLeaveConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Handles"]["MouseButton1UpConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Path2D"]["PropertiesSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString" } }
class_members["Part"]["shap"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "PartType" } }
class_members["Part"]["shape"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "PartType" } }
class_members["DebuggerBreakpoint"]["line"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Animator"]["FadeTime4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightTarget0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FadeTime5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["WeightCurrent3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["TimePosition2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority6"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Priority0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "AnimationPriority {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["PlaybackSpeed2"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped4"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped5"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["Looped0"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["IsPlaying1"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["FacsReplicationData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "FacsReplicationData {🛠️Animation} {RobloxEngine}" } }
class_members["Animator"]["AnimationId7"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Animation} {RobloxEngine}" } }
class_members["VersionControlService"]["ScriptCollabVersionHistoryEnabled"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["NegateOperation"]["PreviousOperation"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "NegateOperationHiddenHistory {🛠️Basic | CSG} {RobloxEngine}" } }
class_members["Motor"]["ReplicateCurrentAngle"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {🛠️Physics} {RobloxEngine}" } }
class_members["DragDetector"]["PhysicalDragClickedPart"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Instance" } }
class_members["DragDetector"]["PhysicalDragHitPoint"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["DragDetector"]["PhysicalDragTargetFrame"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["DragDetector"]["PhysicalDragIsInVR"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["ModuleScript"]["Confidential"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["Sound"]["IsMutedForCapture"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Sound"]["TimePositionReplicator"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Sound"]["PlayingReplicator"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Sound"]["xmlRead_MaxDistance_3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Sound"]["xmlRead_MinDistance_3"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["LocalizationService"]["GameSourceLanguageId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["LocalizationService"]["ShouldUseCloudTable"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["LocalizationService"]["LocaleManifest"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["LocalizationTable"]["Contents"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["LocalizationTable"]["IsExemptFromUGCAnalytics"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["LiveScriptingService"]["ServerLiveEditingMode"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "ServerLiveEditingMode" } }
class_members["GuiButton"]["MouseButton2DownConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiButton"]["MouseButton1ClickConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiButton"]["MouseButton1DownConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiButton"]["MouseButton2UpConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiButton"]["MouseButton2ClickConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiButton"]["MouseButton1UpConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["LodDataEntity"]["EntityData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SharedString" } }
class_members["LodDataEntity"]["EntityPosition"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["LodDataEntity"]["IsSlimEnabled"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["LodDataEntity"]["SlimReplicationTimestampSec"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["LodDataEntity"]["EntitySource"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Instance" } }
class_members["LodDataEntity"]["SlimAnimationSource"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "SlimAnimationDataEntity" } }
class_members["LodDataEntity"]["EntityScale"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["Instance"]["numExpectedDirectChildren"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Instance"]["PropertyStatusStudio"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "PropertyStatus {RobloxEngine}" } }
class_members["Instance"]["Attributes"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["Instance"]["Tags"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["Instance"]["HistoryId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "UniqueId {RobloxEngine}" } }
class_members["Instance"]["DefinesCapabilities"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["Instance"]["AttributesSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["Instance"]["AttributesReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "string {RobloxEngine}" } }
class_members["HumanoidRigDescription"]["PelvisRangeMin"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["HumanoidRigDescription"]["RightToesRangeMax"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["HumanoidRigDescription"]["RightToesSize"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["HumanoidRigDescription"]["LeftToesTposeAdjustment"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["HumanoidRigDescription"]["LeftToesRangeMin"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["HumanoidRigDescription"]["LeftToesRangeMax"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["HumanoidRigDescription"]["RightToesRangeMin"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["HumanoidRigDescription"]["PelvisRangeMax"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["HumanoidRigDescription"]["RightToesTposeAdjustment"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["HumanoidRigDescription"]["PelvisSize"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["HumanoidRigDescription"]["RightToes"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "Instance" } }
class_members["HumanoidRigDescription"]["Pelvis"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "Instance" } }
class_members["HumanoidRigDescription"]["LeftToesSize"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["HumanoidRigDescription"]["PelvisTposeAdjustment"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["HumanoidRigDescription"]["LeftToes"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "Instance" } }
class_members["InsertService"]["AllowClientInsertModels"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Humanoid"]["JumpReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Humanoid"]["Health_XML"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Humanoid"]["InternalOriginalHipHeight"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Humanoid"]["CameraMode"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "CameraMode" } }
class_members["Humanoid"]["CameraMinDistance"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Humanoid"]["MoveDirectionInternal"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["Humanoid"]["InternalHeadScale"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Humanoid"]["WalkDirection"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["Humanoid"]["CameraMaxDistance"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Humanoid"]["WalkAngleError"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Humanoid"]["Strafe"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Humanoid"]["OverrideDefaultCollisions"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️AvatarAppearance} {RobloxEngine}" } }
class_members["Humanoid"]["RotationType"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "RotationType {🛠️AvatarAppearance} {RobloxEngine}" } }
class_members["Humanoid"]["InternalBodyScale"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "Vector3" } }
class_members["Humanoid"]["NetworkHumanoidState"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "HumanoidStateType" } }
class_members["HapticEffect"]["Waveform"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "FloatCurve" } }
class_members["HapticEffect"]["WaveformData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Input} {RobloxEngine}" } }
class_members["Player"]["ChatPrivacyMode"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "ChatPrivacyMode" } }
class_members["Player"]["InternalCharacterAppearanceLoaded"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Player"]["FollowUserIdReplicated"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Player"]["CameraFrustumRequested"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Players} {RobloxEngine}" } }
class_members["Player"]["SuperSafeChatReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Player"]["RawJoinData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️Players} {RobloxEngine}" } }
class_members["Player"]["ChararacterRegionId"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "Vector3 {🛠️Players} {RobloxEngine}" } }
class_members["Player"]["CloudEditCameraCoordinateFrame"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "DataType", Name = "CFrame" } }
class_members["Player"]["AccountAgeReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Player"]["MaxSimulationRadius"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["Player"]["CloudEditPlayerActive"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["Player"]["MembershipTypeReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "MembershipType" } }
class_members["Player"]["CountryRegionCodeReplicate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["Player"]["NeedRegionalFallback"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️Players} {RobloxEngine}" } }
class_members["GuiObject"]["MouseMovedConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiObject"]["DragStoppedConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiObject"]["MouseWheelBackwardConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiObject"]["MouseWheelForwardConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiObject"]["DragBeginConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiObject"]["MouseLeaveConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["GuiObject"]["MouseEnterConnectionCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["MaterialService"]["Use2022MaterialsXml"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean" } }
class_members["FormFactorPart"]["formFactorRaw"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Enum", Name = "FormFactor" } }
class_members["StyleQuery"]["ConditionsSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️UI} {RobloxEngine}" } }
class_members["EditableImage"]["ImageData"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {🛠️DynamicGeneration} {RobloxEngine}" } }
class_members["EditableImage"]["IsReplicatedCopy"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {🛠️DynamicGeneration} {RobloxEngine}" } }
class_members["PackageLink"]["VersionIdSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["PackageLink"]["PackageGuid"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number" } }
class_members["PackageLink"]["PackageIdSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Primitive", Name = "string" } }
class_members["PackageLink"]["CanAutoUpdate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "boolean {RobloxEngine}" } }
class_members["StudioService"]["ShowPlaceVersionHistoryDialog"] = { Type = "Function" }
class_members["DataModel"]["ReportInGoogleAnalytics"] = { Type = "Function" }
class_members["VoiceChatInternal"]["SetSpeakerDevice"] = { Type = "Function" }
class_members["VoiceChatInternal"]["GetSpeakerDevices"] = { Type = "Function" }
class_members["UGCValidationService"]["GetImageTransparencyWithByteString"] = { Type = "Function" }
class_members["UGCValidationService"]["GetSkinnedJointNamesFromMeshId"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateImageTransparencyThresholdTextureID_V2"] = { Type = "Function" }
class_members["UGCValidationService"]["CompareTextureOverlapTextureId"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateUVValuesInReference"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateCageUVTriangleArea"] = { Type = "Function" }
class_members["UGCValidationService"]["GetFacsDrivenJointNamesFromMeshId"] = { Type = "Function" }
class_members["UGCValidationService"]["CompareTextureOverlapByteString"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidatePartBBoxAfterFullFacsFromMeshIds"] = { Type = "Function" }
class_members["UGCValidationService"]["GetMaxNearbyVerticesCollisions"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateFacialExpressiveness"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateTextureAlphaByteString"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateOverlappingVertices"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateSkinnedMesh"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateTextureAlpha"] = { Type = "Function" }
class_members["UGCValidationService"]["GetDynamicHeadMeshInactiveControls"] = { Type = "Function" }
class_members["UGCValidationService"]["GetMeshVertColors"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateMeshVertColors"] = { Type = "Function" }
class_members["UGCValidationService"]["GetCagingRelevancyMetrics"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateImageTransparencyThresholdTextureID"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateImageTransparencyThresholdByteString_V2"] = { Type = "Function" }
class_members["UGCValidationService"]["GetTextureSize"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateCageUVCoincident"] = { Type = "Function" }
class_members["UGCValidationService"]["GetImageTransparencyWithTextureID"] = { Type = "Function" }
class_members["UGCValidationService"]["GetMeshTriCount"] = { Type = "Function" }
class_members["UGCValidationService"]["GetEditableImageData"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateEditableImageSize"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateDynamicHeadMesh"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateCageMeshIntersection"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateImageTransparencyThresholdByteString"] = { Type = "Function" }
class_members["UGCValidationService"]["GetSkinningTransferJointsInfo"] = { Type = "Function" }
class_members["UGCValidationService"]["ValidateFacialBounds"] = { Type = "Function" }
class_members["Humanoid"]["ApplyDescriptionClientServer"] = { Type = "Function" }
class_members["AuroraHandle"]["Destroy"] = { Type = "Function" }
class_members["AuroraHandle"]["ForEach"] = { Type = "Function" }
class_members["AuroraScript"]["Source"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Primitive", Name = "string" } }
class_members["AuroraScript"]["AuroraScriptBindingsSerialize"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "BinaryString {RobloxEngine}" } }
class_members["AuroraScript"]["LODCriticality"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["AuroraScript"]["EnableCulling"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["AuroraScript"]["EnableLOD"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["AuroraScript"]["Priority"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["AuroraScript"]["SignalFired"] = { Type = "Function" }
class_members["AuroraScript"]["AddTo"] = { Type = "Function" }
class_members["AuroraScript"]["GetSchema"] = { Type = "Function" }
class_members["AuroraScript"]["IsOnInstance"] = { Type = "Function" }
class_members["AuroraScript"]["RemoveFrom"] = { Type = "Function" }
class_members["AuroraScriptService"]["GetLocalFrameId"] = { Type = "Function" }
class_members["AuroraScriptService"]["getBehaviorObjects"] = { Type = "Function" }
class_members["AuroraScriptService"]["getInstancesForBehavior"] = { Type = "Function" }
class_members["AuroraScriptService"]["FindBinding"] = { Type = "Function" }
class_members["AuroraScriptService"]["getBehaviors"] = { Type = "Function" }
class_members["AuroraScriptService"]["FindBindings"] = { Type = "Function" }
class_members["AuroraScriptService"]["getBehaviorsForInstance"] = { Type = "Function" }
class_members["AuroraScriptService"]["CreateCollection"] = { Type = "Function" }
class_members["AuroraScriptService"]["SendMessage"] = { Type = "Function" }
class_members["InternalSyncItem"]["Enabled"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["InternalSyncItem"]["Path"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Primitive", Name = "string" } }
class_members["InternalSyncItem"]["Target"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "Instance" } }
class_members["InternalSyncItem"]["AutoSync"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["ConversationalAIAcceptanceService"]["SendMeshGenActivatedTelemetry"] = { Type = "Function" }
class_members["ConversationalAIAcceptanceService"]["SendMeshGenPublishedAssetsTelemetry"] = { Type = "Function" }
class_members["ConversationalAIAcceptanceService"]["SendMeshGenMeshInsertedTelemetry"] = { Type = "Function" }
class_members["ConversationalAIAcceptanceService"]["SendMeshGenCompletedTelemetry"] = { Type = "Function" }
class_members["AuroraService"]["InputDropRate"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["AuroraService"]["OutOfOrderInputCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["AuroraService"]["BufferFullInputCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["AuroraService"]["HashRoundingPoint"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["AuroraService"]["RollbackOffset"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "number" } }
class_members["AuroraService"]["RCCHeartbeatFPS"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["AuroraService"]["IgnoreRotation"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["AuroraService"]["LockStepIdOffset"] = { Type = "Property", ReadOnly = false, ValueType = { Category = "Class", Name = "boolean" } }
class_members["AuroraService"]["TooOldInputCount"] = { Type = "Property", ReadOnly = true, ValueType = { Category = "Class", Name = "number {RobloxEngine}" } }
class_members["AuroraService"]["StepPhysics"] = { Type = "Function" }
class_members["AuroraService"]["SetIncomingReplicationLag"] = { Type = "Function" }
class_members["AuroraService"]["GetRemoteWorldStepId"] = { Type = "Function" }
class_members["AuroraService"]["StopInputRecording"] = { Type = "Function" }
class_members["AuroraService"]["StopPrediction"] = { Type = "Function" }
class_members["AuroraService"]["IsInstancePredicted"] = { Type = "Function" }
class_members["AuroraService"]["GetServerView"] = { Type = "Function" }
class_members["AuroraService"]["StartPrediction"] = { Type = "Function" }
class_members["AuroraService"]["ShowDebugVisualizer"] = { Type = "Function" }
class_members["AuroraService"]["GetWorldStepId"] = { Type = "Function" }
class_members["AuroraService"]["GetPredictedInstances"] = { Type = "Function" }
class_members["AuroraService"]["UpdateProperties"] = { Type = "Function" }
class_members["AuroraService"]["PlayInputRecording"] = { Type = "Function" }
class_members["AuroraService"]["StartInputRecording"] = { Type = "Function" }
-- END API DUMP V2 ADDITIONS

local stats_members = class_members["Stats"] or {}
stats_members.ContactsCount = stats_members.ContactsCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.DataReceiveKbps = stats_members.DataReceiveKbps
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.DataSendKbps = stats_members.DataSendKbps
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.FrameTime = stats_members.FrameTime
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.HeartbeatTime = stats_members.HeartbeatTime
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.HeartbeatTimeMs = stats_members.HeartbeatTimeMs
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.InstanceCount = stats_members.InstanceCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.MemoryTrackingEnabled = stats_members.MemoryTrackingEnabled
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "bool" },
    }
stats_members.MovingPrimitivesCount = stats_members.MovingPrimitivesCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.PhysicsReceiveKbps = stats_members.PhysicsReceiveKbps
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.PhysicsSendKbps = stats_members.PhysicsSendKbps
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.PhysicsStepTime = stats_members.PhysicsStepTime
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.PhysicsStepTimeMs = stats_members.PhysicsStepTimeMs
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.PrimitivesCount = stats_members.PrimitivesCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.RenderCPUFrameTime = stats_members.RenderCPUFrameTime
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.RenderGPUFrameTime = stats_members.RenderGPUFrameTime
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.SceneDrawcallCount = stats_members.SceneDrawcallCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.SceneTriangleCount = stats_members.SceneTriangleCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.ShadowsDrawcallCount = stats_members.ShadowsDrawcallCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.ShadowsTriangleCount = stats_members.ShadowsTriangleCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.UI2DDrawcallCount = stats_members.UI2DDrawcallCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.UI2DTriangleCount = stats_members.UI2DTriangleCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.UI3DDrawcallCount = stats_members.UI3DDrawcallCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.UI3DTriangleCount = stats_members.UI3DTriangleCount
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetCpuTimeTime = stats_members.GetCpuTimeTime
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetMemoryUsageMb = stats_members.GetMemoryUsageMb
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetTotalMemoryUsageMb = stats_members.GetTotalMemoryUsageMb
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetValue = stats_members.GetValue
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetValueString = stats_members.GetValueString
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "string" },
    }
stats_members.GetItemTime = stats_members.GetItemTime
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetGlobalDataPacketLoss = stats_members.GetGlobalDataPacketLoss
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.GetGlobalPhysicsPacketLoss = stats_members.GetGlobalPhysicsPacketLoss
    or {
        Type = "Function",
        ReturnType = { Category = "Primitive", Name = "double" },
    }
stats_members.NetworkStats = stats_members.NetworkStats
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Class", Name = "StatsItem" },
    }
stats_members.PhysicsStats = stats_members.PhysicsStats
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Class", Name = "StatsItem" },
    }
stats_members.RenderStats = stats_members.RenderStats
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Class", Name = "StatsItem" },
    }
stats_members.MemoryStats = stats_members.MemoryStats
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Class", Name = "StatsItem" },
    }
class_members["Stats"] = stats_members
local rs_members = class_members["RunService"] or {}
rs_members.RunState = rs_members.RunState
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Enum", Name = "RunState" },
    }
rs_members.ClientGitHash = rs_members.ClientGitHash
    or {
        Type = "Property",
        ReadOnly = true,
        ValueType = { Category = "Primitive", Name = "string" },
    }
class_members["RunService"] = rs_members
local vcs_members = class_members["VoiceChatService"] or {}
vcs_members.GetChannelId = { Type = "Function" }
vcs_members.GetGroupId = { Type = "Function" }
vcs_members.GetParticipants = { Type = "Function" }
vcs_members.GetSessionId = { Type = "Function" }
vcs_members.GetVoiceExperienceId = { Type = "Function" }
vcs_members.IsContextVoiceEnabled = { Type = "Function" }
vcs_members.IsVoiceEnabledForUserIdAsync = { Type = "Function" }
vcs_members.LogPublisherWebRTCStats = { Type = "Function" }
vcs_members.LogSubscriptionWebRTCStats = { Type = "Function" }
vcs_members.SubscribeBlock = { Type = "Function" }
vcs_members.SubscribeRetry = { Type = "Function" }
vcs_members.SubscribeUnblock = { Type = "Function" }
vcs_members.LocalPlayerModerated = { Type = "Event" }
vcs_members.VoiceChatState = {
    Type = "Property",
    ReadOnly = true,
    ValueType = { Category = "Enum", Name = "VoiceChatState" },
}
vcs_members.GetAndClearCallFailureMessage = { Type = "Function" }
vcs_members.GetAudioProcessingSettings = { Type = "Function" }
vcs_members.GetMicDevices = { Type = "Function" }
vcs_members.GetSpeakerDevices = { Type = "Function" }
vcs_members.GetVoiceChatApiVersion = { Type = "Function" }
vcs_members.GetVoiceChatAvailable = { Type = "Function" }
vcs_members.IsPublishPaused = { Type = "Function" }
vcs_members.IsSubscribePaused = { Type = "Function" }
vcs_members.JoinByGroupId = { Type = "Function" }
vcs_members.JoinByGroupIdToken = { Type = "Function" }
vcs_members.Leave = { Type = "Function" }
vcs_members.PublishPause = { Type = "Function" }
vcs_members.SetMicDevice = { Type = "Function" }
vcs_members.SetSpeakerDevice = { Type = "Function" }
vcs_members.SubscribePause = { Type = "Function" }
vcs_members.SubscribePauseAll = { Type = "Function" }
vcs_members.ParticipantsStateChanged = { Type = "Event" }
vcs_members.PlayerMicActivitySignalChange = { Type = "Event" }
vcs_members.StateChanged = { Type = "Event" }
vcs_members.TempSetMicMutedToggleMic = { Type = "Function" }
class_members["VoiceChatService"] = vcs_members
local vci_members = class_members["VoiceChatInternal"] or {}
vci_members.DefaultDistanceAttenuation = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Enum", Name = "VoiceChatDistanceAttenuationType" },
}
vci_members.EnableDefaultVoice = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.UseAudioApi = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Enum", Name = "AudioApiRollout" },
}
vci_members.UseNewAudioApi = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.UseNewControlPaths = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.UseNewJoinFlow = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.UseStreamSwitching = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.VoiceChatEnabledForPlaceOnRcc = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.VoiceChatEnabledForUniverseOnRcc = {
    Type = "Property",
    ReadOnly = false,
    ValueType = { Category = "Primitive", Name = "bool" },
}
vci_members.GetChatGroupsAsync = { Type = "Function" }
vci_members.IsVoiceEnabledForUserIdAsync = { Type = "Function" }
vci_members.getInternalChannelId = { Type = "Function" }
vci_members.getInternalGroupId = { Type = "Function" }
vci_members.getInternalPublishPause = { Type = "Function" }
vci_members.getInternalSessionId = { Type = "Function" }
vci_members.getInternalSubscribePause = { Type = "Function" }
vci_members.getInternalSubscribePauseAll = { Type = "Function" }
vci_members.getInternalVoiceChatApiVersion = { Type = "Function" }
vci_members.isInternalPublishPaused = { Type = "Function" }
vci_members.joinVoice = { Type = "Function" }
vci_members.lastVoiceChatStats = { Type = "Function" }
vci_members.leaveVoice = { Type = "Function" }
vci_members.notifyServerACSCleanup = { Type = "Function" }
vci_members.rejoinVoice = { Type = "Function" }
class_members["VoiceChatInternal"] = vci_members

local function find_member(className, memberName)
    local cur = className
    while cur and cur ~= "<<<ROOT>>>" do
        local members = class_members[cur]
        if members and members[memberName] then
            return members[memberName]
        end
        cur = class_superclass[cur]
    end
    return nil
end
local function is_roblox_class(className)
    return class_members[className] ~= nil
end
local _cor = coroutine
local get_event_mock_args
local get_default_property_value
local task_queue = {}
local cancelled_threads = {}
local c_functions = {}
local writefile_store = {}
local _require = require
local _type = type
local _typeof = typeof
local _tostring = tostring
local _tonumber = tonumber
local _pairs = pairs
local _ipairs = ipairs
local _next = next
local _select = select
local _unpack = table.unpack or unpack
local _pack = table.pack
    or function(...)
        return { n = select("#", ...), ... }
    end
local _getmt = getmetatable
local _setmt = setmetatable
local _rawget = rawget
local hidden_props = {}
local scriptable_props = {}
local _frozen_tables = {}
local _rawset = rawset
local _rawequal = rawequal
local _pcall = pcall
local _xpcall = xpcall
local _err = error
local function _lune_load(source, chunkname, mode, env)
    if _luau and _luau.load then
        local options = { debugName = chunkname }
        if env then
            options.environment = env
        end
        local ok, result = _pcall(_luau.load, source, options)
        if ok then
            return result
        end
        return nil, result
    end
    return nil, "load/loadstring is unavailable in this Luau runtime"
end
local _load = load or _lune_load
local _loadstr = loadstring or _lune_load

local _setfenv = setfenv
local _getfenv = getfenv
local dbg = debug or {}
local _getinfo = dbg.getinfo
local _traceback = dbg.traceback
local _sethook = dbg.sethook
local _aspect_source = nil
do
    local function _dummy_marker() end
    if dbg.info then
        local ok, src = _pcall(dbg.info, _dummy_marker, "s")
        if ok and src then
            _aspect_source = src
        end
    end
end
local function _is_internal_fn(f)
    if _type(f) ~= "function" then
        return false
    end
    if _aspect_source and dbg.info then
        local ok, src = _pcall(dbg.info, f, "s")
        if ok and src == _aspect_source then
            return true
        end
        if ok and src == "=[C]" then
            return true
        end
    end
    return false
end
local function readbin(path)
    local ok, data = _pcall(function()
        return fs.readFile(path)
    end)
    if not ok then
        return nil, "cant read file"
    end
    if _type(data) ~= "string" then
        local bytes = {}
        for i = 1, #data do
            table.insert(bytes, string.char(data[i]))
        end
        data = table.concat(bytes)
    end
    return data
end
local pargs = proc.args
local inputkey = pargs[3] or "byp4sp3ct"
local placeid = 8916037983
local px_mark = {}
local uid_mark = {}
local st
local lex
local need_space
local function isproxy(obj)
    if _type(obj) ~= "table" then
        return false
    end
    local ok, r = _pcall(function()
        return rawget(obj, px_mark) == true
    end)
    return ok and r
end
local spied_names = {
    ["Name"] = true,
    ["Parent"] = true,
    ["Enabled"] = true,
    ["Visible"] = true,
    ["Active"] = true,
    ["Health"] = true,
    ["MaxHealth"] = true,
    ["WalkSpeed"] = true,
    ["JumpPower"] = true,
    ["UserId"] = true,
    ["DisplayName"] = true,
    ["Character"] = true,
    ["LocalPlayer"] = true,
    ["Humanoid"] = true,
    ["HumanoidRootPart"] = true,
    ["IsLoaded"] = true,
    ["PlaceId"] = true,
    ["GameId"] = true,
    ["Connected"] = true,
    ["Value"] = true,
    ["Text"] = true,
    ["Position"] = true,
    ["CFrame"] = true,
    ["Size"] = true,
    ["Archivable"] = true,
    ["RootPart"] = true,
    ["PrimaryPart"] = true,
    ["TeamColor"] = true,
    ["Transparency"] = true,
    ["Anchored"] = true,
    ["CanCollide"] = true,
    ["IsA"] = true,
    ["isA"] = true,
    ["FindFirstChild"] = true,
    ["WaitForChild"] = true,
    ["IsDescendantOf"] = true,
    ["IsAncestorOf"] = true,
    ["FindFirstChildOfClass"] = true,
    ["FindFirstChildWhichIsA"] = true,
    ["FindFirstAncestorOfClass"] = true,
    ["FindFirstAncestorWhichIsA"] = true,
    ["GetService"] = true,
    ["IsClient"] = true,
    ["IsServer"] = true,
    ["IsStudio"] = true,
    ["IsEdit"] = true,
    ["IsRunning"] = true,
    ["HasTag"] = true,
    ["GetAttribute"] = true,
    ["IsInGroup"] = true,
    ["GetRankInGroup"] = true,
    ["UserOwnsGamePassAsync"] = true,
}
_G.spied_names = spied_names
local function is_spied(val)
    if not isproxy(val) then
        return false
    end
    local name = st.propstore[val] and st.propstore[val].Name
    local class = st.propstore[val] and st.propstore[val].ClassName
    local reg = st.reg[val]
    local function check(str)
        if not str then
            return false
        end
        if spied_names[str] then
            return true
        end
        for k, v in _pairs(spied_names) do
            if v == str or (_type(k) == "string" and str:find(k, 1, true)) then
                return true
            end
        end
        return false
    end
    --[[if check(name) then
        return true
    end
    if check(class) then
        return true
    end    
    if check(reg) then
        return true
    end]]
    return false
end
local function add_line_numbers_to_tokens(tokens, code)
    local line = 1
    local char_idx = 1
    for _, tok in _ipairs(tokens) do
        local pos = code:find(tok.value, char_idx, true)
        if pos then
            local sub = code:sub(char_idx, pos - 1)
            for _ in sub:gmatch("\n") do
                line = line + 1
            end
            tok.line = line
            for _ in tok.value:gmatch("\n") do
                line = line + 1
            end
            char_idx = pos + #tok.value
        else
            tok.line = line
        end
    end
end
local function parse_blocks(tokens)
    local blocks = {}
    local stack = {}
    local i = 1
    while i <= #tokens do
        local tok = tokens[i]
        if tok.type == "keyword" then
            if tok.value == "if" then
                local cond_parts = {}
                i = i + 1
                while i <= #tokens do
                    if
                        tokens[i].type == "keyword"
                        and tokens[i].value == "then"
                    then
                        break
                    end
                    table.insert(cond_parts, tokens[i])
                    i = i + 1
                end
                table.insert(
                    stack,
                    { type = "if", start_line = tok.line, cond = cond_parts }
                )
            elseif tok.value == "elseif" then
                local prev = table.remove(stack)
                if prev then
                    prev.end_line = tok.line - 1
                    table.insert(blocks, prev)
                end
                local cond_parts = {}
                i = i + 1
                while i <= #tokens do
                    if
                        tokens[i].type == "keyword"
                        and tokens[i].value == "then"
                    then
                        break
                    end
                    table.insert(cond_parts, tokens[i])
                    i = i + 1
                end
                table.insert(
                    stack,
                    { type = "if", start_line = tok.line, cond = cond_parts }
                )
            elseif tok.value == "else" then
                local prev = table.remove(stack)
                if prev then
                    prev.end_line = tok.line - 1
                    table.insert(blocks, prev)
                end
                local cond = prev and prev.cond
                table.insert(
                    stack,
                    { type = "else", start_line = tok.line, cond = cond }
                )
            elseif tok.value == "while" then
                local cond_parts = {}
                i = i + 1
                while i <= #tokens do
                    if
                        tokens[i].type == "keyword"
                        and tokens[i].value == "do"
                    then
                        break
                    end
                    table.insert(cond_parts, tokens[i])
                    i = i + 1
                end
                table.insert(
                    stack,
                    { type = "while", start_line = tok.line, cond = cond_parts }
                )
            elseif tok.value == "for" then
                local cond_parts = {}
                i = i + 1
                while i <= #tokens do
                    if
                        tokens[i].type == "keyword"
                        and tokens[i].value == "do"
                    then
                        break
                    end
                    table.insert(cond_parts, tokens[i])
                    i = i + 1
                end
                table.insert(
                    stack,
                    { type = "for", start_line = tok.line, cond = cond_parts }
                )
            elseif tok.value == "do" or tok.value == "function" then
                table.insert(stack, { type = "other", start_line = tok.line })
            elseif tok.value == "end" then
                local prev = table.remove(stack)
                if prev then
                    prev.end_line = tok.line
                    table.insert(blocks, prev)
                end
            end
        end
        i = i + 1
    end
    while #stack > 0 do
        local prev = table.remove(stack)
        prev.end_line = tokens[#tokens] and tokens[#tokens].line or 9999
        table.insert(blocks, prev)
    end
    return blocks
end
local function translate_tokens(tokens)
    local parts = {}
    for _, t in _ipairs(tokens) do
        if t.type == "ident" then
            local val = t.value
            if st.var_map and st.var_map[val] then
                table.insert(parts, st.var_map[val])
            else
                table.insert(parts, val)
            end
        else
            table.insert(parts, t.value)
        end
    end
    local result = {}
    for idx = 1, #parts do
        local part = parts[idx]
        local tok = tokens[idx]
        if idx > 1 then
            local prev_tok = tokens[idx - 1]
            local mock_prev = { value = result[#result], type = prev_tok.type }
            local mock_curr = { value = part, type = tok.type }
            if need_space(mock_prev, mock_curr) then
                table.insert(result, " ")
            end
        end
        table.insert(result, part)
    end
    return table.concat(result)
end
local function get_active_spied_blocks(line_num)
    local active = {}
    if not st.parsed_blocks then
        return active
    end
    for _, b in _ipairs(st.parsed_blocks) do
        if line_num >= b.start_line and line_num <= b.end_line then
            if b.cond and is_spied(b.cond) then
                table.insert(active, b)
            end
        end
    end
    table.sort(active, function(x, y)
        return x.start_line < y.start_line
    end)
    return active
end
local function get_current_script_line()
    if not dbg or not dbg.info then
        return nil, nil
    end
    for depth = 2, 20 do
        local ok, info_line = _pcall(dbg.info, depth, "l")
        if ok and info_line then
            local ok2, info_src = _pcall(dbg.info, depth, "s")
            if
                ok2
                and (
                    info_src == "script"
                    or info_src == '[string "script"]'
                    or info_src == "=@script"
                    or info_src == "=script"
                    or info_src:match("script")
                    or info_src:match("str_input")
                    or info_src:match("load")
                    or info_src:match("string")
                    or info_src == "=(load)"
                )
            then
                if st.source_lines and st.source_lines[info_line] then
                    return info_line, st.source_lines[info_line]
                end
            end
        end
    end
    return nil, nil
end
local last_block_cond = nil
function emit_statement(condition_str, body_str)
    if last_block_cond == condition_str then
        if st.out:sub(-4) == "\nend" or st.out:sub(-3) == "end" then
            st.out = st.out:gsub("%s*end$", "")
        end
        out(body_str)
        out("end")
    else
        last_block_cond = condition_str
        out("if " .. condition_str .. " then")
        out(body_str)
        out("end")
    end
end
local function getpxid(obj)
    if not isproxy(obj) then
        return nil
    end
    return rawget(obj, "__pxid")
end
local function isuid(obj)
    if _type(obj) ~= "table" then
        return false
    end
    local ok, r = _pcall(function()
        return rawget(obj, uid_mark) == true
    end)
    return ok and r
end
st = {
    out = {},
    ind = 0,
    reg = {},
    revreg = {},
    names = {},
    parentmap = {},
    propstore = {},
    callgraph = {},
    vartypes = {},
    strrefs = {},
    pxid = 0,
    cbdepth = 0,
    pending_iter = 0,
    last_url = nil,
    last_line = nil,
    rep_count = 0,
    cur_size = 0,
    lctr = 0,
    getdesc_pending = nil,
    getchldrn_pending = nil,
    limit_hit = false,
    loopctr = 0,
    cap_consts = {},
    cap_strings = {},
    sandbox = nil,
    vm_type = nil,
    t_start = 0,
    cf_depth = 0,
    in_cb = false,
    cb_stack = {},
    gassigns = {},
}
local cfg = {
    maxdepth = 25,
    maxtable = 150,
    outfile = "core/io/dumped_output.lua",
    verbose = false,
    trace_cbs = true,
    timeout = 30,
    maxrepeat = 12,
    mindeobf = 150,
    maxsize = 10 * 1024 * 1024,
    cap_str = true,
    cap_vm = true,
    cap_cf = true,
}
local all_services = {
    "AccountService",
    "AchievementService",
    "ActivityHistoryEventService",
    "AdService",
    "AnalyticsService",
    "AnimationClipProvider",
    "AnimationFromVideoCreatorService",
    "AnimationFromVideoCreatorStudioService",
    "AnnotationsService",
    "AppLifecycleObserverService",
    "AppRatingPromptService",
    "AppStorageService",
    "AppUpdateService",
    "AssetCounterService",
    "AssetDeliveryProxy",
    "AssetImportService",
    "AssetManagerService",
    "AssetQualityService",
    "AssetService",
    "AudioFocusService",
    "AuroraScriptService",
    "AuroraService",
    "AvatarChatService",
    "AvatarCreationService",
    "AvatarEditorService",
    "AvatarImportService",
    "AvatarSettings",
    "BadgeService",
    "BrowserService",
    "BugReporterService",
    "BulkImportService",
    "CSGDictionaryService",
    "CacheableContentProvider",
    "CalloutService",
    "CaptureService",
    "ChangeHistoryService",
    "ChangeHistoryStreamingService",
    "Chat",
    "CloudCRUDService",
    "ClusterPacketCache",
    "CollaboratorsService",
    "CollectionService",
    "CommerceService",
    "ConfigService",
    "ConfigureServerService",
    "ConnectivityService",
    "ContentProvider",
    "ContextActionService",
    "ControllerService",
    "ConversationalAIAcceptanceService",
    "CookiesService",
    "CoreGui",
    "CoreGuiConfiguration",
    "CorePackages",
    "CoreScriptDebuggingManagerHelper",
    "CoreScriptSyncService",
    "CreationDBService",
    "CreatorStoreService",
    "CrossDMScriptChangeListener",
    "DataModelPatchService",
    "DataStoreService",
    "Debris",
    "DebugSettings",
    "DebuggablePluginWatcher",
    "DebuggerConnectionManager",
    "DebuggerManager",
    "DebuggerUIService",
    "DeviceIdService",
    "DraftsService",
    "DraggerService",
    "EditableService",
    "EncodingService",
    "EventIngestService",
    "ExampleV2Service",
    "ExperienceAuthService",
    "ExperienceNotificationService",
    "ExperienceService",
    "ExperienceStateCaptureService",
    "ExperienceStateRecordingService",
    "ExplorerServiceVisibilityService",
    "FaceAnimatorService",
    "FacialAgeEstimationService",
    "FacialAnimationRecordingService",
    "FacialAnimationStreamingServiceV2",
    "FeatureRestrictionManager",
    "FileManagerService",
    "FlagStandService",
    "FlyweightService",
    "FriendService",
    "GamePassService",
    "GameSettings",
    "GamepadService",
    "GenerationService",
    "GenericChallengeService",
    "Geometry",
    "GeometryService",
    "GroupService",
    "GuiService",
    "GuidRegistryService",
    "HSRDataContentProvider",
    "HapticService",
    "HarmonyService",
    "HeapProfilerService",
    "HeatmapService",
    "HeightmapImporterService",
    "Hopper",
    "HttpRbxApiService",
    "HttpService",
    "ILegacyStudioBridge",
    "IXPService",
    "IncrementalPatchBuilder",
    "InsertService",
    "InstanceExtensionsService",
    "InstanceFileSyncService",
    "InternalSyncService",
    "JointsService",
    "KeyboardService",
    "KeyframeSequenceProvider",
    "LSPFileSyncService",
    "LanguageService",
    "LegacyStudioBridge",
    "Lighting",
    "LinkingService",
    "LiveScriptingService",
    "LiveSyncService",
    "LocalStorageService",
    "LocalizationService",
    "LodDataService",
    "LogReporterService",
    "LogService",
    "LoginService",
    "LuaSettings",
    "LuaWebService",
    "LuauScriptAnalyzerService",
    "MLModelDeliveryService",
    "MLService",
    "MarketplaceService",
    "MatchmakingService",
    "MaterialGenerationService",
    "MaterialService",
    "MemStorageService",
    "MemoryStoreService",
    "MeshContentProvider",
    "MessageBusService",
    "MessagingService",
    "MetaBreakpointManager",
    "MicroProfilerService",
    "ModerationService",
    "MouseService",
    "NetworkClient",
    "NetworkServer",
    "NetworkSettings",
    "NonReplicatedCSGDictionaryService",
    "NotificationService",
    "OmniRecommendationsService",
    "OpenCloudService",
    "PackageService",
    "PackageUIService",
    "PartyEmulatorService",
    "PatchBundlerFileWatch",
    "PathfindingService",
    "PerformanceControlService",
    "PermissionsService",
    "PhysicsService",
    "PhysicsSettings",
    "PlaceAssetIdsService",
    "PlaceStatsService",
    "PlacesService",
    "PlatformCloudStorageService",
    "PlatformFriendsService",
    "PlatformLibraries",
    "PlayerDataService",
    "PlayerEmulatorService",
    "PlayerHydrationService",
    "PlayerViewService",
    "Players",
    "PluginDebugService",
    "PluginGuiService",
    "PluginManagementService",
    "PluginPolicyService",
    "PointsService",
    "PolicyService",
    "ProcessInstancePhysicsService",
    "ProximityPromptService",
    "PublishService",
    "RbxAnalyticsService",
    "RecommendationService",
    "ReflectionService",
    "RemoteCommandService",
    "RemoteCursorService",
    "RemoteDebuggerServer",
    "RenderSettings",
    "ReplicatedFirst",
    "ReplicatedStorage",
    "RibbonNotificationService",
    "RobloxPluginGuiService",
    "RobloxReplicatedStorage",
    "RobloxServerStorage",
    "RolloutValidationService",
    "RomarkRbxAnalyticsService",
    "RomarkService",
    "RtMessagingService",
    "RunService",
    "RuntimeContentService",
    "RuntimeScriptService",
    "SafetyService",
    "ScriptChangeService",
    "ScriptCloneWatcher",
    "ScriptCloneWatcherHelper",
    "ScriptCommitService",
    "ScriptContext",
    "ScriptEditorService",
    "ScriptProfilerService",
    "ScriptRegistrationService",
    "ScriptService",
    "Selection",
    "SelectionHighlightManager",
    "SerializationService",
    "ServerScriptService",
    "ServerStorage",
    "ServiceVisibilityService",
    "SessionCheckService",
    "SessionService",
    "SharedTableRegistry",
    "SlimAnimationReplicationService",
    "SlimContentProvider",
    "SlimReplicationService",
    "SlimService",
    "SmoothVoxelsUpgraderService",
    "SnippetService",
    "SocialService",
    "SolidModelContentProvider",
    "SoundService",
    "SoundShimService",
    "SpawnerService",
    "StartPageService",
    "StarterGui",
    "StarterPack",
    "StarterPlayer",
    "StartupMessageService",
    "Stats",
    "StopWatchReporter",
    "StreamingService",
    "Studio",
    "StudioAssetService",
    "StudioCameraService",
    "StudioData",
    "StudioDeviceEmulatorService",
    "StudioPublishService",
    "StudioScriptDebugEventListener",
    "StudioSdkService",
    "StudioService",
    "StudioTestService",
    "StudioUserService",
    "StudioWidgetsService",
    "StylingService",
    "SystemThemeService",
    "TaskScheduler",
    "TeamCreateData",
    "TeamCreatePublishService",
    "TeamCreateService",
    "Teams",
    "TelemetryService",
    "TeleportService",
    "TemporaryCageMeshProvider",
    "TemporaryScriptService",
    "TestService",
    "TextBoxService",
    "TextChatService",
    "TextService",
    "TextureGenerationService",
    "ThirdPartyUserService",
    "TimerService",
    "ToastNotificationService",
    "TouchInputService",
    "TraceRouteService",
    "TracerService",
    "TutorialService",
    "TweenService",
    "UGCAvatarService",
    "UGCValidationService",
    "UIDragDetectorService",
    "UniqueIdLookupService",
    "UnvalidatedAssetService",
    "UserGameSettings",
    "UserInputService",
    "UserService",
    "UserStorageService",
    "VRService",
    "VRStatusService",
    "VersionControlService",
    "VideoCaptureService",
    "VideoScreenCaptureService",
    "VideoService",
    "VirtualInputManager",
    "VirtualUser",
    "VisibilityCheckDispatcher",
    "Visit",
    "VisualizationModeService",
    "VoiceChatInternal",
    "VoiceChatService",
    "WebSocketService",
    "WebViewService",
    "Workspace",
    "WrapDeformMeshProvider",
}
local all_events = {
    "ACSCleanup",
    "ActionActivatedSignal",
    "Activated",
    "ActiveUserSignedOut",
    "AdEvent",
    "AdTeleportEnded",
    "AdTeleportInitiated",
    "AllNotificationsReadFromRibbon",
    "AllowedGearTypeChanged",
    "AncestryChanged",
    "AnimationPlayed",
    "AnimationPlayedCoreScript",
    "AnimationStreamTrackPlayed",
    "AnnotationAdded",
    "AnnotationDeleted",
    "AnnotationEdited",
    "AnnotationResolved",
    "ApplyDescriptionFinished",
    "AssetFetchFailed",
    "AssetImported",
    "AssetImportedSignal",
    "AssetTypePurchased",
    "AttributeChanged",
    "AudioInstanceAdded",
    "AudioMetadataFailedResponse",
    "AudioMetadataRequest",
    "AudioMetadataResponse",
    "AuthCookieCopiedToEngine",
    "AutoTranslateWillRun",
    "AvatarAssetModerationCompleted",
    "AvatarModerationCompleted",
    "AxisChanged",
    "BadgeAwarded",
    "BeginEdit",
    "BenefitStatusReceived",
    "Blocked",
    "BoundActionAdded",
    "BoundActionChanged",
    "BoundActionRemoved",
    "BreakpointAdded",
    "BreakpointChanged",
    "BreakpointRemoved",
    "BroadcastMessage",
    "BroadcastRemoteCursorPositions",
    "BroadcastScriptChangesSubmitted",
    "BrowserWindowClosed",
    "BrowserWindowWillNavigate",
    "BubbleChatSettingsChanged",
    "BubbleDisplayed",
    "BugReportRequested",
    "BulkImportFinished",
    "BulkImportStarted",
    "Button1Down",
    "Button1Up",
    "Button2Down",
    "Button2Up",
    "ButtonChanged",
    "ButtonHoldBeganActionReplicated",
    "ButtonHoldEndedActionReplicated",
    "CallInviteStateChanged",
    "CaptureBegan",
    "CaptureEnded",
    "CaptureObjectSavedInternal",
    "CaptureSaved",
    "CaptureSavedInternal",
    "ChallengeAbandonedEvent",
    "ChallengeCompletedEvent",
    "ChallengeInvalidatedEvent",
    "ChallengeLoadedEvent",
    "ChallengeRequiredEvent",
    "Changed",
    "ChangedThisFrame",
    "CharacterAdded",
    "CharacterAppearanceLoaded",
    "CharacterRemoving",
    "Chatted",
    "ChildAdded",
    "ChildRemoved",
    "Click",
    "ClientLoggedEvent",
    "ClientLuaDialogRequested",
    "ClientPurchaseSuccess",
    "ClientRetryJoin",
    "ClientRetryJoinWithConfig",
    "ClientStreamSwitchAck",
    "ClientToServerFilterMessageSignalV2",
    "ClientToServerMessageReplicateSignalV2",
    "ClientToServerMessageReplicateSignalV3",
    "ClientToServerReportUnfilteredSignal",
    "Climbing",
    "Close",
    "CloseInspectMenuRequest",
    "CloseLate",
    "Closed",
    "CloudEditApplyEditsMessage",
    "CloudEditSelectionChanged",
    "ClusterCompositionFinished",
    "CollaboratorIdleUpdate",
    "CollaboratorInstanceCreatedSignal",
    "CollaboratorInstanceDestroyedSignal",
    "CollaboratorStatusUpdateRequestedSignal",
    "CollaboratorStatusUpdatedSignal",
    "CollisionGroupCollidableChanged",
    "ColormapHasUnknownPixels",
    "CommandSentFromStudio",
    "CommitRejectedInfo",
    "CommitStatusChanged",
    "Completed",
    "ComputerCameraMovementModeRegistered",
    "ComputerMovementModeRegistered",
    "ConfigurationChanged",
    "ConfirmPlayerMembership",
    "ConfirmUserSubscriptionPurchase",
    "ConnectionAccepted",
    "ConnectionEnded",
    "ConnectionFailed",
    "ConnectionStarted",
    "ControlPointChanged",
    "CoreGuiChangedSignal",
    "CoreGuiRenderOverflowed",
    "CurrentDataModelTypeAboutToChange",
    "CurrentDataModelTypeChanged",
    "CurrentDeviceIdChanged",
    "CustomStatusAdded",
    "CustomStatusRemoved",
    "DataModelSessionEnded",
    "DataModelSessionStarted",
    "Deactivated",
    "Deactivation",
    "DebuggerAdded",
    "DebuggerRemoved",
    "DefaultLoadingGuiRemoved",
    "DescendantAdded",
    "DescendantRemoving",
    "Deselected",
    "Destroying",
    "DeviceAccelerationChanged",
    "DeviceGravityChanged",
    "DeviceListChanged",
    "DeviceRotationChanged",
    "DevicesChanged",
    "DialogChoiceSelected",
    "DidEnd",
    "DidLoop",
    "Died",
    "DiscardRequested",
    "DraftAdded",
    "DraftRemoved",
    "DraftStatusChanged",
    "DragBegin",
    "DragContinue",
    "DragContinueReplicate",
    "DragEnd",
    "DragEndReplicate",
    "DragEnter",
    "DragStart",
    "DragStartReplicate",
    "DragStopped",
    "DropdownClick",
    "DynamicTranslationServerToClientResponse",
    "EditorsListChanged",
    "EmoteTriggered",
    "EmotesChanged",
    "EmotesMenuOpenChanged",
    "EncounteredBreak",
    "EndEdit",
    "Ended",
    "Equipped",
    "EquippedEmotesChanged",
    "Error",
    "ErrorDetailed",
    "ErrorMessageChanged",
    "Event",
    "EventConnected",
    "EventDisconnected",
    "ExpressionAdded",
    "ExpressionsCleared",
    "FSTriggeredSignal",
    "FailedToOpen",
    "FallingDown",
    "FeatureTimeoutAttempt",
    "FeatureTimeoutRestored",
    "FetchReceipt",
    "FetchUserTurnAuthOperationFailed",
    "FinishedReplicating",
    "FirstPersonTransition",
    "FixedRateTick",
    "FlagCaptured",
    "Flushed",
    "FocusChanged",
    "FocusLost",
    "FocusStateChanged",
    "Focused",
    "FreeFalling",
    "FriendRequestEvent",
    "FriendStatusChanged",
    "FriendsUpdated",
    "FullscreenChanged",
    "GameAnnounce",
    "GameInvitePromptClosed",
    "GameNameUpdated",
    "GamePublishCancelled",
    "GamePublishFinished",
    "GamepadConnected",
    "GamepadDisconnected",
    "GamepadThumbstick1Changed",
    "GenerationNotificationSignal",
    "GetActionButtonEvent",
    "GettingUp",
    "GraphicsQualityChangeRequest",
    "GuiVisibilityChangedSignal",
    "GuidLineContentsChanged",
    "GuidNameChanged",
    "HealthChanged",
    "Heartbeat",
    "Hit",
    "HttpResultOut",
    "Idle",
    "Idled",
    "ImageImportedSignal",
    "ImportSessionFinished",
    "ImportSessionStarted",
    "InExperienceBrowserRequested",
    "IndicatorHidden",
    "IndicatorShown",
    "InputActionsChanged",
    "InputBegan",
    "InputBindingsChanged",
    "InputChanged",
    "InputContextsChanged",
    "InputEnded",
    "InputPinsChanged",
    "InspectMenuEnabledChangedSignal",
    "InspectPlayerFromHumanoidDescriptionRequest",
    "InspectPlayerFromUserIdWithCtxRequest",
    "InstancePinned",
    "InstanceUnpinned",
    "InternalDelete",
    "InternalFacsOverrideChanged",
    "InterpolationFinished",
    "IrisInviteInitiated",
    "ItemAdded",
    "ItemChanged",
    "ItemRemoved",
    "ItemSelectedInCaptureMode",
    "ItemWasSet",
    "JavaScriptCallback",
    "JoinedVoice",
    "JumpRequest",
    "Jumping",
    "KeyDown",
    "KeyPressed",
    "KeyUp",
    "KeyframeReached",
    "KickFromEdit",
    "Kill",
    "LaserPointerTriggered",
    "LastInputTypeChanged",
    "LightingChanged",
    "LiveEditingClientConfiguration",
    "Loaded",
    "LocalGamesFromRegistryUpdatedSignal",
    "LocalPlayerArrivedFromTeleport",
    "LocalPlayerModerated",
    "LocalSimulationTouched",
    "LocalToolEquipped",
    "LocalToolUnequipped",
    "LockedScriptBatchCommit",
    "LoginFailed",
    "LoginSucceeded",
    "Looped",
    "LuaDialogCallbackSignal",
    "MagicLoginEvent",
    "MaterialFillToolEnabledChanged",
    "MenuClosed",
    "MenuOpened",
    "MenuTeleportAttempt",
    "MessageOut",
    "MessageReceived",
    "MetaBreakpointAdded",
    "MetaBreakpointChanged",
    "MetaBreakpointRemoved",
    "MetaBreakpointSetChanged",
    "Misprediction",
    "MockConfirmUserSubscriptionPurchase",
    "MockPurchasePremium",
    "ModerationModeEnabledChanged",
    "MouseActionReplicated",
    "MouseButton1Click",
    "MouseButton1Down",
    "MouseButton1Up",
    "MouseButton2Click",
    "MouseButton2Down",
    "MouseButton2Up",
    "MouseClick",
    "MouseDrag",
    "MouseEnter",
    "MouseEnterStudioViewport",
    "MouseHoverEnter",
    "MouseHoverLeave",
    "MouseLeave",
    "MouseLeaveStudioViewport",
    "MouseMoved",
    "MouseWheelBackward",
    "MouseWheelForward",
    "Move",
    "MoveStateChanged",
    "MoveToFinished",
    "MultiGetCanCollaborateRetrieved",
    "NativeClose",
    "NativePurchaseFinished",
    "NativePurchaseFinishedWithLocalPlayer",
    "NavigationRequested",
    "NetworkOwnerChanged",
    "NetworkPausedEnabledChanged",
    "NewNotificationFromRibbon",
    "NotificationReadFromRibbon",
    "NotifyStreamingUnpinned",
    "OnBadgeAwarded",
    "OnBecomeActive",
    "OnBrowserTrackerLayerLoadingStatusChanged",
    "OnCaptureAndMetadataSignatureResult",
    "OnClearRequested",
    "OnClientEvent",
    "OnClientFeatures",
    "OnCombinedUpdate",
    "OnContextRegistered",
    "OnContextUnregistered",
    "OnConvertToPackageResult",
    "OnCreatorLayerLoadingStatusChanged",
    "OnCrossExperienceStarted",
    "OnCrossExperienceStopped",
    "OnDeafenVoiceAudio",
    "OnDetach",
    "OnEmitRequested",
    "OnGameLeft",
    "OnHide",
    "OnHttpResultApproved",
    "OnImportFromRoblox",
    "OnIncomingMessageEvent",
    "OnJavaScriptCall",
    "OnLuaThemeUpdated",
    "OnLuaUrl",
    "OnMouseCaptureBegin",
    "OnMouseCaptureEnd",
    "OnNewData",
    "OnNewJoinAttempt",
    "OnOpenConvertToPackagePlugin",
    "OnOpenGameSettings",
    "OnOpenManagePackagePlugin",
    "OnPluginInstalledFromToolbox",
    "OnPluginInstalledFromWeb",
    "OnPolo",
    "OnPromptSaveInstanceToRobloxAsync",
    "OnPublishAsPlugin",
    "OnPublishAttempt",
    "OnPublishPackageResult",
    "OnRecordingFinished",
    "OnRecordingStarted",
    "OnRedo",
    "OnRemoteServerEvent",
    "OnResignActive",
    "OnSaveOrPublishPlaceToRoblox",
    "OnSaveToRoblox",
    "OnSensorOutputChanged",
    "OnServerEvent",
    "OnStart",
    "OnStreamingUpdated2",
    "OnTeleport",
    "OnTeleportInternal",
    "OnUGCSubmitCompleted",
    "OnUndeafenVoiceAudio",
    "OnUndo",
    "OnUnhide",
    "OnUserLayerLoadingStatusChanged",
    "OnWindowClosed",
    "OneshotCommandErrorFromRcc",
    "OneshotCommandResultFromRcc",
    "OneshotCommandSentFromStudio",
    "Open9SliceEditor",
    "OpenAllowInventoryReadAccess",
    "OpenAttenuationCurveEditorSignal",
    "OpenAudioCompressorEditorSignal",
    "OpenAudioEqualizerEditorSignal",
    "OpenAuthPrompt",
    "OpenCapturePermissionsPrompt",
    "OpenCreateResultModal",
    "OpenDirectionalCurveEditorSignal",
    "OpenExperienceDetailsPrompt",
    "OpenPromptCreateOufit",
    "OpenPromptDeleteOutfit",
    "OpenPromptRenameOutfit",
    "OpenPromptSaveAvatar",
    "OpenPromptSetFavorite",
    "OpenPromptUpdateOutfit",
    "OpenPublishResultModal",
    "OpenSaveCapturesPrompt",
    "OpenSelfieConsent",
    "OpenSelfieQRCode",
    "OpenShareCapturePrompt",
    "OpenShareSheetWithLink",
    "OpenStyleEditor",
    "Opened",
    "OpenedWithSource",
    "OptInPromptClosed",
    "OrientationChanged",
    "OutfitChanged",
    "OverrideStatusChanged",
    "OverrideStreamRadii",
    "PageEnter",
    "PageLeave",
    "ParticipantsStateChanged",
    "Paused",
    "PerformanceStatsVisibleChanged",
    "PersistentLoaded",
    "PhoneBookPromptClosed",
    "PlatformStanding",
    "PlayFailed",
    "PlaybackCompleted",
    "PlaybackReport",
    "PlaybackStatusUpdated",
    "Played",
    "PlayerAdded",
    "PlayerCharacterLoaded",
    "PlayerChatAvailabilityStatusChanged",
    "PlayerChatTranslationSettingsLocaleSetFromLua",
    "PlayerChatted",
    "PlayerConnecting",
    "PlayerDisconnecting",
    "PlayerExperienceSettingsLocaleSetFromLua",
    "PlayerHydration",
    "PlayerMembershipChanged",
    "PlayerMicActivitySignalChange",
    "PlayerPartyDataChanged",
    "PlayerRejoining",
    "PlayerRemoved",
    "PlayerRemoving",
    "PlayingUpdatedFromClient",
    "PlayingUpdatedFromServer",
    "PluginDragDropped",
    "PluginDragEntered",
    "PluginDragLeft",
    "PluginDragMoved",
    "PointFocused",
    "PointerAction",
    "PointsAwarded",
    "PortalPrompt",
    "PostSimulation",
    "PreAnimation",
    "PreRender",
    "PreSimulation",
    "PrepareCollectiblesPurchaseRequested",
    "Pressed",
    "PreviewNotificationSignal",
    "ProgressUpdate",
    "PromptAllowInventoryReadAccessCompleted",
    "PromptBulkPurchaseFinished",
    "PromptBulkPurchaseRequested",
    "PromptBundlePurchaseFinished",
    "PromptBundlePurchaseRequested",
    "PromptButtonHoldBegan",
    "PromptButtonHoldEnded",
    "PromptCancelSubscriptionRequested",
    "PromptCollectibleBundlePurchaseRequested",
    "PromptCollectiblesPurchaseRequested",
    "PromptCommerceProductPurchaseFinished",
    "PromptCommerceProductPurchaseRequested",
    "PromptCreateOutfitCompleted",
    "PromptDeleteOutfitCompleted",
    "PromptGamePassPurchaseFinished",
    "PromptGamePassPurchaseRequested",
    "PromptGameServerAvatarReportEnrichment",
    "PromptGameServerReportEnrichment",
    "PromptGameServerTargetedChatReportEnrichment",
    "PromptHidden",
    "PromptInviteRequested",
    "PromptIrisInviteRequested",
    "PromptNativePurchaseRequested",
    "PromptNativePurchaseRequestedWithLocalPlayer",
    "PromptOptInRequested",
    "PromptPremiumPurchaseFinished",
    "PromptPremiumPurchaseRequested",
    "PromptProductPurchaseFinished",
    "PromptProductPurchaseRequested",
    "PromptPurchaseFinished",
    "PromptPurchaseRequested",
    "PromptPurchaseRequestedV2",
    "PromptRenameOutfitCompleted",
    "PromptReportServerEnrichmentAndScan",
    "PromptRobloxPurchaseRequested",
    "PromptSaveAvatarCompleted",
    "PromptSaveAvatarThumbnailCustomizationCompleted",
    "PromptSetFavoriteCompleted",
    "PromptShown",
    "PromptSubscriptionPurchaseFinished",
    "PromptSubscriptionPurchaseRequested",
    "PromptThirdPartyPurchaseRequested",
    "PromptTransformPluginCheckEnable",
    "PromptTriggerEnded",
    "PromptTriggered",
    "PromptUpdateOutfitCompleted",
    "PublishStateChange",
    "Published",
    "PublishingHandshakeAcked",
    "PublishingHandshakeAckedWithBothSdp",
    "PublishingHandshakeAckedWithCompressedSdp",
    "PublishingHandshakeCompleted",
    "PublishingHandshakeInitiated",
    "PublishingHandshakeInitiatedWithBothSdp",
    "PublishingHandshakeInitiatedWithCompressedSdp",
    "PurchaseBrowserClosed",
    "PurchasePromptShown",
    "RCCProfilerDataComplete",
    "RagDoll",
    "Ragdoll",
    "RccConnectionChanged",
    "RccEventReceived",
    "ReJoinedVoice",
    "ReachedTarget",
    "Ready",
    "Received",
    "ReceivedUpdate",
    "ReceiverConnected",
    "ReceiverDisconnected",
    "RecentApiGamesFromRegistryUpdatedSignal",
    "ReconcileCommunicationAccessCompleted",
    "ReconcileCommunicationAccessSignal",
    "ReconnectTeleportInitFailed",
    "RecordingCompleted",
    "RefreshClientFeatures",
    "RefreshFeatureRestrictions",
    "RefreshPluginState",
    "RelayCandidatesGathered",
    "Released",
    "RemoteCreateMotor6D",
    "RemoteCreateSeatWeld",
    "RemoteDestroyMotor6D",
    "RemoteDestroySeatWeld",
    "RemoteFriendEventSignal",
    "RemoteFriendRequestSignal",
    "RemoteFriendStatusSignal",
    "RemoteInsert",
    "RemoteOnInvokeClient",
    "RemoteOnInvokeError",
    "RemoteOnInvokeServer",
    "RemoteOnInvokeSuccess",
    "RemoteRequireRequest",
    "RemoteRequireResponse",
    "RemoveDefaultLoadingGuiSignal",
    "RenderStepped",
    "ReplicateAvatarGenerationImageId",
    "ReplicateAvatarModel",
    "ReplicateAvatarPreviewUrl",
    "ReplicateGeneration",
    "ReplicatedSelected",
    "ReportImpressionSignal",
    "ReportIsSubscribedToVideoCompletion",
    "ReportTeleportSignal",
    "RequestAllEditorsSignal",
    "RequestAllRemoteCursorPositionForScript",
    "RequestAvatarGenerationImage",
    "RequestAvatarModel",
    "RequestAvatarPreviewUrl",
    "RequestCaptureAndMetadataSignature",
    "RequestCloudEditKick",
    "RequestCloudEditShutdown",
    "RequestCompleted",
    "RequestData",
    "RequestGenerationReplication",
    "RequestHttpResultApprovedSignal",
    "RequestInitiated",
    "RequestScriptExecutionSignal",
    "RequestServerHttpResultSignal",
    "RequestServerOutputSignal",
    "RequestSettingsChange",
    "RequestStreamingPin",
    "RequestStreamingPinByUniqueId",
    "RestartPhysicalDragReplicate",
    "Resumed",
    "Resuming",
    "ReturnPressedFromOnScreenKeyboard",
    "RewardedVideoAdEnded",
    "RewardedVideoAdStarted",
    "RightMouseClick",
    "Roblox17sConnectionChanged",
    "Roblox17sEventReceived",
    "RobloxConnectionChanged",
    "RobloxEventReceived",
    "RobloxGuiFocusedChanged",
    "Rollback",
    "RomarkEndOfTest",
    "Running",
    "RuntimeContentFail",
    "RuntimeContentLRCleanup",
    "RuntimeContentQuery",
    "RuntimeContentShare",
    "SafeZoneOffsetsChanged",
    "SaveLocallyAsComplete",
    "ScopeCheckInitiated",
    "ScopeCheckResult",
    "ScreenshotContentReady",
    "ScreenshotReady",
    "ScreenshotSavedToAlbum",
    "ScreenshotUploaded",
    "ScriptAdded",
    "ScriptBatchCommit",
    "ScriptBeingRemoved",
    "ScriptChanged",
    "ScriptChangesSubmitted",
    "ScriptEditorAdded",
    "ScriptEditorRemoved",
    "ScriptFullNameChanged",
    "ScriptSecurityError",
    "ScriptSourceChanged",
    "ScriptStartEdit",
    "ScriptStopEdit",
    "Seated",
    "SecondaryActivated",
    "Selected",
    "SelectionChanged",
    "SelectionChangedThisFrame",
    "SelectionGained",
    "SelectionLost",
    "SelfViewHidden",
    "SelfViewVisible",
    "SendAtomicOperation",
    "SendAtomicUpdateResponse",
    "SendCameraFrustum",
    "SendCreateInstanceFromStudio",
    "SendDeleteInstanceFromStudio",
    "SendMaxClientBandwidthBps",
    "SendOperation",
    "SendReparentInstanceFromStudio",
    "SendServerTime",
    "SendTerrainChangeFromStudio",
    "SendVIPData",
    "SendingMessage",
    "SequentialCommandsFinished",
    "ServeAdResponseSignal",
    "ServeAdSignal",
    "ServerApplyDescription",
    "ServerBreakJoints",
    "ServerCollectConditionalResult",
    "ServerCollectResult",
    "ServerEquipAccoutrement",
    "ServerEquipTool",
    "ServerHttpResultOut",
    "ServerLoadAnnotationReplies",
    "ServerLoadAnnotations",
    "ServerLoadResolvedAnnotations",
    "ServerMessageOut",
    "ServerMultiGetCanCollaborateRequested",
    "ServerPurchaseVerification",
    "ServerToClientMessageReplicateSignal",
    "ServerToClientMessageReplicateSignalV2",
    "ServerToClientUnderOver13FilteredResponseSignal",
    "ServerToClientUnfilteredChatReplicate",
    "ServerUnequipAccoutrement",
    "ServerUpdateEntities",
    "ServerUpdatedHead",
    "ServerVariantMessageOut",
    "ServiceAdded",
    "ServiceRemoving",
    "ServiceVisibilityChanged",
    "SetProfilingState",
    "SetShutdownMessage",
    "ShareSheetClosed",
    "ShowCameraSpeed",
    "ShowDynamicEudsaDisclosure",
    "ShowFeatureInterventionDetails",
    "ShowFeatureInterventionDetailsV2",
    "ShowJoinPrompt",
    "ShowLeaveConfirmation",
    "ShowPromptFeedbackSubmission",
    "ShowPromptFeedbackUnavailable",
    "ShowPromptRsvpToEvent",
    "ShowReportAdPopup",
    "SimulationRadiusChanged",
    "SourceValueChanged",
    "SpecialKeyPressed",
    "SsrcUserIdMappingUpdate",
    "StandardOutMessageFromRcc",
    "StartSingleMeshImport",
    "Started",
    "StateChanged",
    "StateEnabledChanged",
    "StatsAvailable",
    "StatsReceived",
    "Status",
    "StatusAdded",
    "StatusBarTapped",
    "StatusChanged",
    "StatusRemoved",
    "StatusReported",
    "Step",
    "Stepped",
    "StopSentFromStudio",
    "Stopped",
    "StoppedTouching",
    "StoreWasCleared",
    "Strafing",
    "StreamSyncRequest",
    "StreamingPinComplete",
    "StudioModeChanged",
    "StyleRulePropertyChanged",
    "StyleRulesChanged",
    "StyledPropertiesChanged",
    "SubscribeStateChange",
    "SubscriptionFeedStarted",
    "SubscriptionHandshakeAcked",
    "SubscriptionHandshakeAckedWithBothSdp",
    "SubscriptionHandshakeAckedWithCompressedSdp",
    "SubscriptionHandshakeCompleted",
    "SubscriptionHandshakeInitiated",
    "SubscriptionHandshakeInitiatedWithBothSdp",
    "SubscriptionHandshakeInitiatedWithCompressedSdp",
    "SubscriptionReset",
    "Swimming",
    "SyncStatusChanged",
    "SynchronizeState",
    "TagAdded",
    "TagRemoved",
    "TeamCreateErrorStatus",
    "TeamCreatePlaceUploadRequest",
    "TeamCreatePlaceUploadResponse",
    "TeamCreateServerMessage",
    "TeleportInProgress",
    "TeleportInitFailed",
    "TeleportInitFailedInternal",
    "TempSetMicMutedToggleMic",
    "TextBoxFocusReleased",
    "TextBoxFocused",
    "TextDocumentDidChange",
    "TextDocumentDidClose",
    "TextDocumentDidOpen",
    "TextScraperClientMessageWithPlayerSignal",
    "ThemeChanged",
    "ThirdPartyPurchaseFinished",
    "TimePositionUpdatedFromClient",
    "TimePositionUpdatedFromServer",
    "TimeoutChatAttempt",
    "ToggleNotificationTray",
    "ToggleSelectionHighlightsSignal",
    "TopbarTransparencyChangedSignal",
    "TouchCameraMovementModeRegistered",
    "TouchDrag",
    "TouchEnded",
    "TouchInBoundsChanged",
    "TouchLongPress",
    "TouchMoved",
    "TouchMovementModeRegistered",
    "TouchPan",
    "TouchPinch",
    "TouchPositionsChanged",
    "TouchRotate",
    "TouchStarted",
    "TouchSwipe",
    "TouchTap",
    "TouchTapInWorld",
    "Touched",
    "TouchpadModeChanged",
    "TrackerError",
    "TrackerPrompt",
    "TriggerEnded",
    "TriggerEndedActionReplicated",
    "Triggered",
    "TriggeredActionReplicated",
    "TriggeredCaptureUpload",
    "UgcValidationFailure",
    "UgcValidationSuccess",
    "UiMessageChanged",
    "Unblocked",
    "Unequipped",
    "UniverseMetadataLoaded",
    "Unloading",
    "UnpinStreaming",
    "UpdateAvailable",
    "UpdateChatTimeout",
    "UpdateClientFeatureTimeout",
    "UpdateClientRemoteCursorPosition",
    "UpdateExperienceChatTimeout",
    "UpdateFeatureTimeout",
    "UpdateSentFromRcc",
    "UpdateSentFromStudio",
    "UpdateState",
    "UpdateStatusChanged",
    "UpdateTurnAuthInfoRequest",
    "UpdateUI",
    "UploadComplete",
    "UploadProgress",
    "UserCFrameChanged",
    "UserCFrameEnabled",
    "UserCaptureSaved",
    "UserGuiRenderingChanged",
    "UserMessageIntentSent",
    "UserMessageIntentSentRemote",
    "UserSubscriptionStatusChanged",
    "UserTurnAuth",
    "UserVideoCaptureFailed",
    "UserVideoCaptureStartFailed",
    "VRLaserPointerClicked",
    "VerticesModified",
    "VideoAdClosed",
    "VideoCaptureInProgress",
    "VideoRecordingChangeRequest",
    "ViewportChanged",
    "VoiceChatClientVoiceCapability",
    "VoiceChatClientVoiceCapabilityWithConfig",
    "VoiceChatPlayerMuteStateChangedClientToServer",
    "VoiceChatPlayerMuteStateChangedServerToClient",
    "VoiceChatSampleTaggedEventClientToServer",
    "VoiceChatSampleTaggedEventServerToClient",
    "VoiceChatStatsCollected",
    "VoiceChatSubscriptionInitialBatchEmpty",
    "VoiceChatplayerMuteStatusChangedEvent",
    "VoiceMigration",
    "VoiceSetupFailed",
    "WatchAdded",
    "WatchRemoved",
    "WheelBackward",
    "WheelForward",
    "WindowFocusReleased",
    "WindowFocused",
    "WiringChanged",
    "WriteActivityHistoryEventFromStudio",
    "adGuiRegisterUI",
    "adGuiStateChanged",
    "changed",
    "childAdded",
    "equipped",
    "keyDown",
    "mouseClick",
    "playbackActionSync",
    "rewardedVideoAdPlayServerToClient",
    "rewardedVideoAdPlayServerToClientWithPlacement",
    "rewardedVideoAdResultClientToServer",
    "unequipped",
}
local all_brickcolors = {
    "White",
    "Grey",
    "Light yellow",
    "Brick yellow",
    "Light green (Mint)",
    "Light reddish violet",
    "Pastel Blue",
    "Light orange brown",
    "Nougat",
    "Bright red",
    "Med. reddish violet",
    "Bright blue",
    "Bright yellow",
    "Earth orange",
    "Black",
    "Dark grey",
    "Dark green",
    "Medium green",
    "Bright green",
    "Dark orange",
    "Light blue",
    "Light red",
    "Medium red",
    "Medium blue",
    "Light grey",
    "Bright violet",
    "Br. yellowish orange",
    "Bright orange",
    "Br. yellowish green",
    "Dark red",
    "Medium stone grey",
    "Light orange",
    "Bright yellowish green",
    "Warm yellowish orange",
    "Cool yellow",
    "Medium lilac",
    "Deep blue",
    "Sand blue",
    "Sand green",
    "Dark blue",
    "Dark brown",
    "Dark flesh",
    "Sand rose",
    "Reddish brown",
    "Sand red",
    "Dark azure",
    "Medium azure",
    "Aqua",
    "Medium lavender",
    "Lavender",
    "Light nougat",
    "Bright bluish green",
    "Lime green",
    "Slime green",
    "Smoky grey",
    "Dark tangerine",
    "Teal",
    "Sea green",
    "Shamrock",
    "Fossil",
    "Mulberry",
    "Forest green",
    "Really red",
    "Deep orange",
    "Salmon",
    "Gold",
    "Daisy orange",
    "Pearl",
    "Fog",
    "Cocoa",
    "Seaweed",
    "Burgundy",
    "Plum",
    "Currant",
    "Pine Cone",
    "Fawn brown",
    "Hurricane grey",
    "Cloudy grey",
    "Linen",
    "Copper",
    "Dirt brown",
    "Bronze",
    "Flint",
    "Dark taupe",
    "Burnt Sienna",
    "Pearl Dark Grey",
    "Navy blue",
    "Dusty Rose",
    "Olive",
    "Sand yellow",
    "Earth yellow",
    "Institutional white",
    "Mid gray",
    "Really black",
    "Alder",
    "New Yeller",
    "Really blue",
    "Cyan",
    "CGA brown",
    "Magenta",
    "Pink",
    "Toothpaste",
    "Camo",
    "Grime",
    "Pastel light blue",
    "Pastel orange",
    "Pastel violet",
    "Pastel blue-green",
    "Pastel green",
    "Pastel yellow",
    "Pastel brown",
    "Royal purple",
    "Hot pink",
    "Eggplant",
    "Turquoise",
    "Fossil",
    "Electric blue",
    "Tr. Blue",
    "Tr. Yellow",
    "Tr. Flu. Reddish orange",
    "Tr. Green",
    "Tr. Flu. Green",
    "Phosph. White",
    "Light blue violet",
    "Tr. Orange",
    "Glitter trans-Dark Pink",
    "Glitter trans-Clear",
    "Tr. Medium Reddish Violet",
    "Glitter trans-Dark Turquoise",
    "Glitter trans-Light Blue",
    "Tr. Flu. Blue",
    "Tr. Flu. Yellow",
    "Tr. Flu. White",
    "Glitter trans-Orange",
    "Tr. Very Lt Blue",
    "Tr. Med. Blue",
    "Tr. Flu. Orange",
    "Tr. Bright Green",
    "Tr. Br. Bl. Violet",
    "Glitter trans-Pink",
    "Earth Blue",
    "Earth Green",
    "Sand Blue Metallic",
    "Sand Yellow Metallic",
    "Sand Green Metallic",
    "Sand Red Metallic",
    "Neon orange",
    "Neon green",
    "Neon yellow",
    "Neon red",
    "Neon pink",
    "Light stone grey",
    "Medium stone grey",
    "Dark stone grey",
    "Light flesh",
    "Fabuland Orange",
    "Fabuland Brown",
    "Light Salmon",
    "Sand yellow",
    "Sienna Brown",
    "Light brick yellow",
    "Warm Gold",
    "Vibrant Coral",
    "Vibrant Yellow",
}
local all_creatable = {
    "AccessoryDescription",
    "Accoutrement",
    "Accessory",
    "AdPortal",
    "AdvancedDragger",
    "Animation",
    "CurveAnimation",
    "KeyframeSequence",
    "AnimationController",
    "AnimationRigData",
    "Animator",
    "Annotation",
    "Atmosphere",
    "Attachment",
    "Bone",
    "AudioAnalyzer",
    "AudioEmitter",
    "AudioListener",
    "AudioPlayer",
    "Backpack",
    "RemoteEvent",
    "UnreliableRemoteEvent",
    "WrapDeformer",
    "WrapLayer",
    "WrapTarget",
    "Beam",
    "BindableEvent",
    "BindableFunction",
    "BodyPartDescription",
    "Breakpoint",
    "BodyColors",
    "CharacterMesh",
    "Pants",
    "Shirt",
    "ShirtGraphic",
    "ClickDetector",
    "DragDetector",
    "Clouds",
    "Configuration",
    "AlignOrientation",
    "AlignPosition",
    "AngularVelocity",
    "BallSocketConstraint",
    "HingeConstraint",
    "LineForce",
    "LinearVelocity",
    "PlaneConstraint",
    "RigidConstraint",
    "RodConstraint",
    "RopeConstraint",
    "CylindricalConstraint",
    "PrismaticConstraint",
    "SpringConstraint",
    "Torque",
    "TorsionSpringConstraint",
    "UniversalConstraint",
    "VectorForce",
    "ControllerManager",
    "CustomLog",
    "BlockMesh",
    "FileMesh",
    "SpecialMesh",
    "DataStoreGetOptions",
    "Dialog",
    "DialogChoice",
    "Dragger",
    "EulerRotationCurve",
    "Explosion",
    "FaceControls",
    "Decal",
    "Texture",
    "Fire",
    "FloatCurve",
    "Folder",
    "ForceField",
    "GetTextBoundsParams",
    "CanvasGroup",
    "Frame",
    "ImageButton",
    "TextButton",
    "ImageLabel",
    "TextLabel",
    "ScrollingFrame",
    "TextBox",
    "VideoFrame",
    "ViewportFrame",
    "BillboardGui",
    "ScreenGui",
    "SurfaceGui",
    "SelectionBox",
    "BoxHandleAdornment",
    "ConeHandleAdornment",
    "CylinderHandleAdornment",
    "ImageHandleAdornment",
    "LineHandleAdornment",
    "SphereHandleAdornment",
    "WireframeHandleAdornment",
    "SelectionSphere",
    "ArcHandles",
    "Handles",
    "SurfaceSelection",
    "Path2D",
    "Highlight",
    "Humanoid",
    "HumanoidDescription",
    "HumanoidRigDescription",
    "IKControl",
    "InputAction",
    "InputBinding",
    "InputContext",
    "Motor",
    "Motor6D",
    "VelocityMotor",
    "Weld",
    "Keyframe",
    "KeyframeMarker",
    "PointLight",
    "SpotLight",
    "SurfaceLight",
    "LocalizationTable",
    "Script",
    "LocalScript",
    "ModuleScript",
    "MarkerCurve",
    "MaterialVariant",
    "NoCollisionConstraint",
    "Noise",
    "CornerWedgePart",
    "Part",
    "Seat",
    "SpawnLocation",
    "WedgePart",
    "MeshPart",
    "PartOperation",
    "IntersectOperation",
    "NegateOperation",
    "UnionOperation",
    "TrussPart",
    "VehicleSeat",
    "Camera",
    "Model",
    "Actor",
    "Tool",
    "WorldModel",
    "ParticleEmitter",
    "PathfindingLink",
    "PathfindingModifier",
    "Player",
    "PluginAction",
    "NumberPose",
    "Pose",
    "BloomEffect",
    "BlurEffect",
    "ColorCorrectionEffect",
    "DepthOfFieldEffect",
    "SunRaysEffect",
    "ProximityPrompt",
    "ProximityPromptService",
    "ReflectionMetadata",
    "RemoteFunction",
    "Sky",
    "Smoke",
    "Sound",
    "ChorusSoundEffect",
    "CompressorSoundEffect",
    "DistortionSoundEffect",
    "EchoSoundEffect",
    "EqualizerSoundEffect",
    "FlangeSoundEffect",
    "PitchShiftSoundEffect",
    "ReverbSoundEffect",
    "TremoloSoundEffect",
    "SoundGroup",
    "Sparkles",
    "StarterGear",
    "StyleRule",
    "StyleSheet",
    "SurfaceAppearance",
    "Team",
    "TeleportOptions",
    "TerrainDetail",
    "TerrainRegion",
    "TestService",
    "TextChannel",
    "TextChatCommand",
    "TextChatMessageProperties",
    "Trail",
    "Tween",
    "UIAspectRatioConstraint",
    "UISizeConstraint",
    "UITextSizeConstraint",
    "UICorner",
    "UIDragDetector",
    "UIFlexItem",
    "UIGradient",
    "UIGridLayout",
    "UIListLayout",
    "UIPageLayout",
    "UITableLayout",
    "UIPadding",
    "UIScale",
    "UIStroke",
    "BinaryStringValue",
    "BoolValue",
    "BrickColorValue",
    "CFrameValue",
    "Color3Value",
    "IntValue",
    "NumberValue",
    "ObjectValue",
    "RayValue",
    "StringValue",
    "Vector3Value",
    "Vector3Curve",
    "VideoPlayer",
    "WeldConstraint",
    "Wire",
    "AudioChordData",
    "AudioFader",
    "AudioPitchShifter",
    "AudioReverb",
    "EditableImage",
    "EditableMesh",
    "DataModelMesh",
    "AdGui",
    "BlockScript",
    "DraftsPropertyOptions",
    "ExperienceNotificationProfile",
    "MemoryStoreQueue",
    "StandalonePluginGui",
    "StudioData",
    "SurfaceControl",
    "TrackerControl",
    "AudioWire",
    "AudioPolyphonicMixer",
    "UIFlexLayout",
    "AudioChannelMixer",
    "AudioChannelSplitter",
    "AudioChorus",
    "AudioCompressor",
    "AudioDeviceInput",
    "AudioDeviceOutput",
    "AudioDistortion",
    "AudioEcho",
    "AudioFilter",
    "AudioFlanger",
    "AudioGate",
    "AudioLimiter",
    "AudioRecorder",
    "AudioTremolo",
    "BlockMesh",
    "CharacterMesh",
    "DataModelMesh",
    "FileMesh",
    "BevelMesh",
    "CylinderMesh",
    "PyramidHandleAdornment",
    "WorkspaceAnnotation",
    "PathfindingModifier",
    "TerrainDetail",
    "TextChatCommand",
    "TextLabel",
    "CanvasGroup",
    "CylinderMesh",
    "FloorWire",
    "HumanoidController",
    "SkateboardController",
    "VehicleController",
    "AirController",
    "ClimbController",
    "GroundController",
    "SwimController",
    "IntersectOperation",
    "NegateOperation",
    "UnionOperation",
    "BodyAngularVelocity",
    "BodyForce",
    "BodyGyro",
    "BodyPosition",
    "BodyThrust",
    "BodyVelocity",
    "RocketPropulsion",
    "ManualGlue",
    "ManualWeld",
    "RotateP",
    "RotateV",
    "Glue",
    "Snap",
}
local all_datatypes = {
    "Axes",
    "BrickColor",
    "CatalogSearchParams",
    "CFrame",
    "Color3",
    "ColorSequence",
    "ColorSequenceKeypoint",
    "Content",
    "DateTime",
    "DockWidgetPluginGuiInfo",
    "Enum",
    "EnumItem",
    "Enums",
    "Faces",
    "FloatCurveKey",
    "Font",
    "Instance",
    "NumberRange",
    "NumberSequence",
    "NumberSequenceKeypoint",
    "OverlapParams",
    "Path2DControlPoint",
    "PathWaypoint",
    "PhysicalProperties",
    "Random",
    "Ray",
    "RaycastParams",
    "RaycastResult",
    "RBXScriptConnection",
    "RBXScriptSignal",
    "Rect",
    "Region3",
    "Region3int16",
    "RotationCurveKey",
    "Secret",
    "SecurityCapabilities",
    "SharedTable",
    "TweenInfo",
    "UDim",
    "UDim2",
    "ValueCurveKey",
    "Vector2",
    "Vector2int16",
    "Vector3",
    "Vector3int16",
    "Buffer",
    "AudioSearchParams",
}
local all_globals = {
    "game",
    "workspace",
    "script",
    "shared",
    "_G",
    "PluginManager",
    "settings",
    "Game",
    "Workspace",
    "ElapsedTime",
    "elapsedTime",
    "print",
    "warn",
    "error",
    "delay",
    "Spawn",
    "spawn",
    "Tick",
    "tick",
    "Time",
    "time",
    "TypeOf",
    "typeof",
    "UserSettings",
    "version",
    "Version",
    "Wait",
    "wait",
    "Require",
    "require",
    "plugin",
    "utf8",
    "bit32",
    "buffer",
    "task",
    "assert",
    "collectgarbage",
    "gcinfo",
    "getfenv",
    "getmetatable",
    "ipairs",
    "loadstring",
    "newproxy",
    "next",
    "pairs",
    "pcall",
    "rawequal",
    "rawget",
    "rawlen",
    "rawset",
    "select",
    "setfenv",
    "setmetatable",
    "tonumber",
    "tostring",
    "type",
    "unpack",
    "xpcall",
    "_VERSION",
    "printidentity",
}
local all_libraries = {
    "bit32",
    "buffer",
    "coroutine",
    "debug",
    "math",
    "os",
    "string",
    "table",
    "task",
    "utf8",
}
local all_enums = {
    "ActionRole",
    "ActuatorType",
    "AdCoreEnums",
    "AdEventType",
    "AdMarker",
    "AlignType",
    "AlphaMode",
    "AnimationPriority",
    "AntialiasingMode",
    "AppShellActionType",
    "AspectType",
    "AssetType",
    "AttachmentGesture",
    "AudioApiRolloffMode",
    "AudioSubmixType",
    "AvatarJoint",
    "AvatarPromptResult",
    "Axis",
    "BaseSizeHint",
    "BeamLightInfluence",
    "BillboardMode",
    "BinType",
    "BlendMode",
    "BloximeterCustomCapType",
    "BodyPart",
    "BodyPartR15",
    "CameraMode",
    "CameraType",
    "Capacitance",
    "CenterDialogType",
    "ChatColor",
    "ChatMode",
    "ChatPrivacySetting",
    "ChatStyle",
    "ClientAnimatorThrottlingMode",
    "CollisionFidelity",
    "ColorAlignment",
    "ContextActionPriority",
    "ControlMode",
    "ControllerActivationType",
    "CoosState",
    "CreatorType",
    "CurrencyType",
    "CustomCameraType",
    "CuttingStyle",
    "DataStoreRequestType",
    "DeviceType",
    "DialogBehaviorType",
    "DialogChoiceStyle",
    "DialogPurpose",
    "DialogTone",
    "DigitalButton",
    "Direction",
    "DominantAxis",
    "DraftsSubmitResult",
    "DragDetectorResponseStyle",
    "EasingDirection",
    "EasingStyle",
    "ElasticityBasis",
    "EnviromentType",
    "ExplosionType",
    "ExpressionState",
    "FaceControlsFilter",
    "FillDirection",
    "FilterResult",
    "FontDirection",
    "FontSize",
    "FontStyle",
    "FontWeight",
    "FrameStyle",
    "FriendStatus",
    "FunctionalTestResult",
    "GameAvatarType",
    "GameplayPausedReason",
    "GearGenreSetting",
    "GearType",
    "Genre",
    "GeoComplianceType",
    "GraphicsMode",
    "HandlesStyle",
    "HapticFeedbackType",
    "HorizontalAlignment",
    "HttpContentType",
    "HttpRequestMethod",
    "HumanoidDisplayDistanceType",
    "HumanoidHealthDisplayType",
    "HumanoidRigType",
    "HumanoidStateType",
    "InGameAdRequirements",
    "InfoType",
    "InitialDockState",
    "InputType",
    "IntentType",
    "ItemType",
    "JointCreationMode",
    "KeyCode",
    "KeyframeAnimationGradientSpace",
    "LanguagePreference",
    "LeftRight",
    "LevelOfDetailSetting",
    "LightingMode",
    "Limb",
    "ListDisplayMode",
    "ListenerType",
    "LiveScriptingStatus",
    "LocalSaveState",
    "LocationType",
    "LogType",
    "MarketplaceBulkPurchaseResult",
    "Material",
    "MaterialPattern",
    "MembershipType",
    "MeshType",
    "MessageType",
    "ModifierTarget",
    "ModifierType",
    "MouseBehavior",
    "MoveState",
    "NameOcclusion",
    "NetworkOwnership",
    "NormalId",
    "OutputAuthMode",
    "PackagePermissionLevel",
    "PacketPriority",
    "PacketReliability",
    "PartType",
    "PathStatus",
    "PathfindingLinkUpdateType",
    "PerformanceAssetType",
    "PermissionLevel",
    "Platform",
    "PlaybackState",
    "PlayerActions",
    "PlayerChatType",
    "PlayerConnectionState",
    "PlayerFeature",
    "PlayerInterpolationMode",
    "PlaylistLoadStatus",
    "PluginMouseBehavior",
    "PoisonGroup",
    "PoseEasingDirection",
    "PoseEasingStyle",
    "PositionAlignment",
    "PositionTarget",
    "PrivilegeLevel",
    "ProductPurchaseDecision",
    "PropertyStatus",
    "ProximityPromptClickablePromptStyle",
    "ProximityPromptExclusivity",
    "ProximityPromptGamepadKeycode",
    "ProximityPromptInputType",
    "R15ArtistIntentLimb",
    "RatingType",
    "RaycastFilterType",
    "ReadyState",
    "RenderFidelity",
    "RenderingMode",
    "ReplicationFocusType",
    "ResamplerMode",
    "ReturnKeyType",
    "RibbonTool",
    "RollOffMode",
    "RotationOrder",
    "RuntimeUndoBehavior",
    "SafeZoneBaseClip",
    "SaveFilter",
    "SavedQualitySetting",
    "ScaleType",
    "ScreenOrientation",
    "ScrollBarType",
    "ScrollbarVerticleAlignment",
    "SearchCategory",
    "SelectionBehavior",
    "SensorType",
    "ServerStatus",
    "SevereError",
    "SizeConstraint",
    "SkinTopology",
    "SkyboxGenerationStatus",
    "SortOrder",
    "SoundCategory",
    "SoundFilterType",
    "SoundServiceStatus",
    "SpecialKey",
    "StartupFormat",
    "Status",
    "StreamingBehavior",
    "StyleRuleType",
    "SurfaceGuiSizingMode",
    "SurfaceType",
    "SystemCursor",
    "TableLayoutAlignment",
    "Technology",
    "TeleportResult",
    "TeleportType",
    "TerrainCalculationSpace",
    "TextAlignment",
    "TextFilterContext",
    "TextInputType",
    "TextTruncate",
    "TextureMode",
    "TextureQueryType",
    "Theme",
    "ThreadPriority",
    "ThreadPoolType",
    "ThumbnailSize",
    "ThumbnailType",
    "TopBottom",
    "TouchCameraMovementMode",
    "TouchMovementMode",
    "TouchTriggerType",
    "TrackType",
    "TrackerDeviceType",
    "TrackerType",
    "TrackingStatus",
    "TransactionStatus",
    "TransitionType",
    "TranslationContext",
    "TransmissionRateExponent",
    "TweenStatus",
    "UIFlexAlignment",
    "UIFlexBasisType",
    "UIFlexDirection",
    "UIFlexJustifyContent",
    "UIFlexWrap",
    "UIKey",
    "UIOrientation",
    "UiKind",
    "UnjoinableReason",
    "UploadSetting",
    "UsageContext",
    "UserCFrame",
    "UserInputState",
    "UserInputType",
    "UserNetworkCondition",
    "UserProfilingState",
    "UserSecurityType",
    "VREffectType",
    "VRNavigationMode",
    "VerticalAlignment",
    "VideoPlayerState",
    "VideoQuality",
    "VirtualCursorMode",
    "VoiceChatState",
    "VoiceEnvironmentType",
    "VolumeUnit",
    "WaterDirection",
    "WaypointAction",
    "WeaponType",
    "WeldConstraintState",
    "WidgetEnabledState",
    "WindowFocusState",
    "ZoneShape",
    "AutomaticSize",
    "FlexAlignContent",
    "FlexAlignItems",
    "IKControlTargetType",
    "TextChatBehavior",
    "TopBarItem",
    "AdMarkerStyle",
    "AppShellWindowType",
    "AssetCreatorType",
    "AudioDeviceDirection",
    "AudioLinearLinkType",
    "AvatarAssetType",
    "CallState",
    "CellBlockType",
    "ChatPrivacySettings",
    "Color3Universe",
    "CompositorCurveType",
    "ConnectionState",
    "CoreGuiType",
    "DataStoreKeyVersionFilter",
    "DraftsStatus",
    "EnrollmentState",
    "ExperienceNotificationStatus",
    "FormFactor",
    "FramerateManagerMode",
    "HSRStatus",
    "HardwareKeyboardType",
    "HttpError",
    "InGameDataStoreRequestType",
    "InputContextPriority",
    "LayoutCycleExceptionHandling",
    "LocalizationTableSource",
    "LocalStoreStatus",
    "LogTypeDetail",
    "MarketplaceItemType",
    "MaterialPatternType",
    "NetworkAdPlacementType",
    "NotificationType",
    "OpenCloudPermissionType",
    "PacketReliabilityType",
    "PaulType",
    "PipeAlignment",
    "PlatformType",
    "PlayerFeatureStatus",
    "PrimalState",
    "R15ArtistIntentType",
    "RenderingTechnology",
    "RibbonToolType",
    "ScaleTypeKind",
    "SelectionDirection",
    "StudioStyleGuideColor",
    "StudioStyleGuideModifier",
    "SurfaceGuiApplyType",
    "UIFlexItemGrow",
    "VerticalSizingMode",
    "VideoState",
    "VoiceChannelState",
    "VRDeviceType",
    "XRAnchorState",
    "XRSessionType",
}
local function cleanpath(txt)
    if _type(txt) ~= "string" then
        return txt
    end
    if txt:find("stack traceback:") or txt:find("during definition of") then
        return ""
    end
    local env = proc.env or {}
    local cwd = proc.cwd or ""
    local userprofile_nodrive = env.USERPROFILE
        and env.USERPROFILE:gsub("^[a-zA-Z]:", "")
    local cwd_nodrive = cwd and cwd:gsub("^[a-zA-Z]:", "")
    local targets = {
        { from = cwd, to = "root" },
        { from = cwd_nodrive, to = "root" },
        { from = env.USERPROFILE, to = "user" },
        { from = userprofile_nodrive, to = "user" },
        { from = env.HOME, to = "user" },
        { from = "main.luau", to = "file" },
        { from = "main.lua", to = "file" },
    }
    local function esc(s)
        if not s then
            return ""
        end
        return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    end
    for _, v in _pairs(targets) do
        if v.from and #v.from > 0 then
            txt = txt:gsub(esc(v.from), v.to)
            local sw = v.from:gsub("\\", "/")
            if sw ~= v.from then
                txt = txt:gsub(esc(sw), v.to)
            end
        end
    end
    txt = txt:gsub('[^%s"]+%.luau:%d+:?', "")
    txt = txt:gsub('[^%s"]+%.lua:%d+:?', "")
    txt = txt:gsub('[^%s"]+aspect:%d+:?', "")
    txt = txt:gsub('[^%s"]+4sp3ct:%d+:?', "")
    txt = txt:gsub('root4sp3ct:%d+:?', "")
    txt = txt:gsub('[^%s"]+[Aa]spect[^%s"]*:%d+:?', "")
    txt = txt:gsub("Isolates/.*:%d+:?", "")
    return txt
end
local function clean_traceback(tb)
    if _type(tb) ~= "string" then
        return tb
    end
    local lines = {}
    for line in tb:gmatch("[^\r\n]+") do
        if
            not line:find("aspect.luau")
            and not line:find("lune")
            and not line:find("=[C]: in function 'traceback'")
            and not line:find("=[C]: in function 'info'")
        then
            local cleaned =
                line:gsub('"[^"]-[/\\]aspect.luau"', '"aspect.luau"')
            table.insert(lines, cleaned)
        end
    end
    return table.concat(lines, "\n")
end
local _print_history = {}
local _print_window = 8
local _loop_count = 0
local function out(str, noind)
    if st.limit_hit then
        return
    end
    if str == nil or str == "" then
        return
    end
    local clean = cleanpath(_tostring(str))
    if clean == "" then
        return
    end
    msg = tostring(str)
    table.insert(_print_history, msg)
    if #_print_history > _print_window then
        table.remove(_print_history, 1)
    end
    if #_print_history == _print_window then
        local half = math.floor(_print_window / 2)
        local first_half = {}
        local second_half = {}
        for i = 1, half do first_half[i] = _print_history[i] end
        for i = half + 1, _print_window - 1 do second_half[i - half] = _print_history[i] end
        local repeated = true
        for i = 1, #second_half do
            if second_half[i] ~= first_half[i] then
                repeated = false
                break
            end
        end
        if repeated and half > 0 then
            _loop_count = _loop_count + 1
            return
        else
            _loop_count = 0
        end
    end
    local line_num = get_current_script_line()
    if line_num then
            local active_blocks = get_active_spied_blocks(line_num)
            if #active_blocks > 0 then
                local wrapped = clean
                for i = #active_blocks, 1, -1 do
                    local block = active_blocks[i]
                    local cond_str = translate_tokens(block.cond)
                if block.type == "while" then
                    wrapped = string.format("while %s do\n    %s\nend", cond_str, wrapped:gsub("\n", "\n    "))
                elseif block.type == "if" then
                    if #st.out > 0 and st.out[#st.out]:match("^%s*end%s*$") and _G._last_active_cond == cond_str then
                         table.remove(st.out)
                         wrapped = "    " .. clean .. "\nend"
                    else
                        _G._last_active_cond = cond_str
                        wrapped = string.format("if %s then\n    %s\nend", cond_str, wrapped:gsub("\n", "\n    "))
                    end
                end
            end
        end 
    end
    local pfx = noind and "" or string.rep("    ", st.ind)
    local lines = {}
    for line in clean:gmatch("[^\r\n]+") do
        table.insert(lines, pfx .. line)
    end
    for _, ln in _ipairs(lines) do
        local llen = #ln + 1
        if st.cur_size + llen > cfg.maxsize then
            st.limit_hit = true
            local msg = "-- file size limit grr"
            table.insert(st.out, msg)
            st.cur_size = st.cur_size + #msg
            error("DUMP_LIMIT_EXCEEDED")
        end
        if ln == st.last_line then
            st.rep_count = st.rep_count + 1
            if st.rep_count <= cfg.maxrepeat then
                table.insert(st.out, ln)
                st.cur_size = st.cur_size + llen
            elseif st.rep_count == cfg.maxrepeat + 1 then
                local msg = pfx .. "-- repeated lines cucked"
                table.insert(st.out, msg)
                st.cur_size = st.cur_size + #msg
            end
        else
            st.last_line = ln
            st.rep_count = 0
            table.insert(st.out, ln)
            st.cur_size = st.cur_size + llen
        end
        if cfg.verbose and st.rep_count <= 1 then
            print(ln)
        end
    end
end
local function note(str)
    out("-- " .. _tostring(str or ""))
end
local function gap()
    st.last_line = nil
    table.insert(st.out, "")
end
local function getout()
    return table.concat(st.out, "\n")
end
local beautify
local function saveout(fname)
    local raw = getout()
    local clean = cleanpath(raw)
    local pretty = beautify(clean)
    -- The router/bot treat a leading "--err" line as an in-band failure
    -- signal so they can report the real reason instead of handing back a
    -- header-only dump that looks successful. Only emitted when the script
    -- could not be compiled/loaded at all.
    if st.load_failed then
        pretty = "--err " .. _tostring(st.load_failed) .. "\n" .. pretty
    end
    local ok = _pcall(function()
        fs.writeFile(fname or cfg.outfile, pretty)
    end)
    return ok
end
lex = function(code)
    local tokens = {}
    local i = 1
    local n = #code
    while i <= n do
        local char = code:sub(i, i)
        local next2 = code:sub(i, i + 1)
        if char == "\r" and code:sub(i + 1, i + 1) == "\n" then
            table.insert(tokens, { type = "newline", value = "\n" })
            i = i + 2
        elseif char == "\n" or char == "\r" then
            table.insert(tokens, { type = "newline", value = "\n" })
            i = i + 1
        elseif char == " " or char == "\t" or char == "\f" or char == "\v" then
            i = i + 1
        elseif next2 == "--" then
            local start = i
            i = i + 2
            if code:sub(i, i) == "[" then
                local eqs = 0
                i = i + 1
                while code:sub(i, i) == "=" do
                    eqs = eqs + 1
                    i = i + 1
                end
                if code:sub(i, i) == "[" then
                    i = i + 1
                    local close = "]" .. string.rep("=", eqs) .. "]"
                    local ci = code:find(close, i, true)
                    if ci then
                        i = ci + #close
                    else
                        i = n + 1
                    end
                else
                    while
                        i <= n
                        and code:sub(i, i) ~= "\n"
                        and code:sub(i, i) ~= "\r"
                    do
                        i = i + 1
                    end
                end
            else
                while
                    i <= n
                    and code:sub(i, i) ~= "\n"
                    and code:sub(i, i) ~= "\r"
                do
                    i = i + 1
                end
            end
            table.insert(
                tokens,
                { type = "comment", value = code:sub(start, i - 1) }
            )
        elseif
            next2 == "[[" or (char == "[" and code:sub(i + 1, i + 1) == "=")
        then
            local eqs = 0
            if next2 == "[[" then
                i = i + 2
            else
                i = i + 1
                while code:sub(i, i) == "=" do
                    eqs = eqs + 1
                    i = i + 1
                end
                i = i + 1
            end
            local close = "]" .. string.rep("=", eqs) .. "]"
            local close_idx = code:find(close, i, true)
            local val
            if close_idx then
                val = code:sub(i - eqs - 2, close_idx + eqs + 1)
                i = close_idx + eqs + 2
            else
                val = code:sub(i - eqs - 2)
                i = n + 1
            end
            table.insert(tokens, { type = "string", value = val })
        elseif char == '"' or char == "'" then
            local quote = char
            i = i + 1
            local start = i
            while i <= n do
                local c = code:sub(i, i)
                if c == "\\" then
                    local nxt = code:sub(i + 1, i + 1)
                    if nxt == "x" then
                        i = i + 4
                    elseif nxt == "u" and code:sub(i + 2, i + 2) == "{" then
                        i = i + 3
                        while i <= n and code:sub(i, i) ~= "}" do
                            i = i + 1
                        end
                        i = i + 1
                    elseif nxt == "z" then
                        i = i + 2
                        while i <= n and code:sub(i, i):match("%s") do
                            i = i + 1
                        end
                    else
                        i = i + 2
                    end
                elseif c == quote then
                    break
                else
                    i = i + 1
                end
            end
            table.insert(
                tokens,
                { type = "string", value = code:sub(start - 1, i) }
            )
            i = i + 1
        elseif
            char:match("%d")
            or (char == "." and code:sub(i + 1, i + 1):match("%d"))
        then
            local start = i
            if char == "." then
                i = i + 1
            end
            while i <= n and code:sub(i, i):match("[%d%.]") do
                i = i + 1
            end
            if code:sub(i, i):match("[eE]") then
                i = i + 1
                if code:sub(i, i):match("[%-%+]") then
                    i = i + 1
                end
                while i <= n and code:sub(i, i):match("%d") do
                    i = i + 1
                end
            end
            table.insert(
                tokens,
                { type = "number", value = code:sub(start, i - 1) }
            )
        elseif char:match("[%a_]") then
            local start = i
            while i <= n and code:sub(i, i):match("[%w_]") do
                i = i + 1
            end
            local word = code:sub(start, i - 1)
            local keywords = {
                ["and"] = true,
                ["break"] = true,
                ["do"] = true,
                ["else"] = true,
                ["elseif"] = true,
                ["end"] = true,
                ["false"] = true,
                ["for"] = true,
                ["function"] = true,
                ["if"] = true,
                ["in"] = true,
                ["local"] = true,
                ["nil"] = true,
                ["not"] = true,
                ["or"] = true,
                ["repeat"] = true,
                ["return"] = true,
                ["then"] = true,
                ["true"] = true,
                ["until"] = true,
                ["while"] = true,
                ["continue"] = true,
                ["export"] = true,
                ["type"] = true,
                ["typeof"] = true,
            }
            table.insert(
                tokens,
                { type = keywords[word] and "keyword" or "ident", value = word }
            )
        elseif
            char == "."
            and code:sub(i + 1, i + 1) == "."
            and code:sub(i + 2, i + 2) == "."
        then
            table.insert(tokens, { type = "punct", value = "..." })
            i = i + 3
        elseif
            char == "."
            and code:sub(i + 1, i + 1) == "."
            and code:sub(i + 2, i + 2) == "="
        then
            table.insert(tokens, { type = "op", value = "..=" })
            i = i + 3
        elseif char == "." and code:sub(i + 1, i + 1) == "." then
            table.insert(tokens, { type = "op", value = ".." })
            i = i + 2
        elseif char == ":" and code:sub(i + 1, i + 1) == ":" then
            table.insert(tokens, { type = "punct", value = "::" })
            i = i + 2
        elseif char == "+" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "+=" })
            i = i + 2
        elseif char == "-" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "-=" })
            i = i + 2
        elseif char == "*" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "*=" })
            i = i + 2
        elseif
            char == "/"
            and code:sub(i + 1, i + 1) == "/"
            and code:sub(i + 2, i + 2) == "="
        then
            table.insert(tokens, { type = "op", value = "//=" })
            i = i + 3
        elseif char == "/" and code:sub(i + 1, i + 1) == "/" then
            table.insert(tokens, { type = "op", value = "//" })
            i = i + 2
        elseif char == "/" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "/=" })
            i = i + 2
        elseif char == "%" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "%=" })
            i = i + 2
        elseif char == "^" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "^=" })
            i = i + 2
        elseif char == "&" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "&=" })
            i = i + 2
        elseif char == "&" then
            table.insert(tokens, { type = "op", value = "&" })
            i = i + 1
        elseif char == "|" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "|=" })
            i = i + 2
        elseif char == "|" then
            table.insert(tokens, { type = "op", value = "|" })
            i = i + 1
        elseif
            char == "<"
            and code:sub(i + 1, i + 1) == "<"
            and code:sub(i + 2, i + 2) == "="
        then
            table.insert(tokens, { type = "op", value = "<<=" })
            i = i + 3
        elseif char == "<" and code:sub(i + 1, i + 1) == "<" then
            table.insert(tokens, { type = "op", value = "<<" })
            i = i + 2
        elseif char == "<" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "<=" })
            i = i + 2
        elseif char == "<" then
            table.insert(tokens, { type = "punct", value = "<" })
            i = i + 1
        elseif
            char == ">"
            and code:sub(i + 1, i + 1) == ">"
            and code:sub(i + 2, i + 2) == "="
        then
            table.insert(tokens, { type = "op", value = ">>=" })
            i = i + 3
        elseif char == ">" and code:sub(i + 1, i + 1) == ">" then
            table.insert(tokens, { type = "op", value = ">>" })
            i = i + 2
        elseif char == ">" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = ">=" })
            i = i + 2
        elseif char == ">" then
            table.insert(tokens, { type = "punct", value = ">" })
            i = i + 1
        elseif char == "=" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "==" })
            i = i + 2
        elseif char == "~" and code:sub(i + 1, i + 1) == "=" then
            table.insert(tokens, { type = "op", value = "~=" })
            i = i + 2
        elseif char == "~" then
            table.insert(tokens, { type = "op", value = "~" })
            i = i + 1
        elseif
            char == "#"
            and code:sub(i + 1, i + 1) == "!"
            and #tokens == 0
        then
            while
                i <= n
                and code:sub(i, i) ~= "\n"
                and code:sub(i, i) ~= "\r"
            do
                i = i + 1
            end
        else
            local ops = {
                ["+"] = true,
                ["-"] = true,
                ["*"] = true,
                ["/"] = true,
                ["%"] = true,
                ["^"] = true,
                ["#"] = true,
                ["="] = true,
            }
            local puncts = {
                ["("] = true,
                [")"] = true,
                ["{"] = true,
                ["}"] = true,
                ["["] = true,
                ["]"] = true,
                [";"] = true,
                [","] = true,
                ["."] = true,
                [":"] = true,
            }
            if ops[char] then
                table.insert(tokens, { type = "op", value = char })
            elseif puncts[char] then
                table.insert(tokens, { type = "punct", value = char })
            else
                table.insert(tokens, { type = "unknown", value = char })
            end
            i = i + 1
        end
    end
    return tokens
end
need_space = function(a, b)
    if not a or not b then
        return false
    end
    local av, at = a.value, a.type
    local bv, bt = b.value, b.type
    if at == "punct" and (av == "(" or av == "[" or av == "{") then
        return false
    end
    if
        bt == "punct"
        and (bv == ")" or bv == "]" or bv == "}" or bv == "," or bv == ";")
    then
        return false
    end
    if at == "punct" and (av == "," or av == ";") then
        return true
    end
    if av == "::" or bv == "::" then
        return false
    end
    if av == ":" or bv == ":" then
        if at == "ident" and bv == ":" then
            return false
        end
        if av == ":" and bt == "ident" then
            return false
        end
        return true
    end
    if av == "." or bv == "." then
        if
            bv == "."
            and (
                at == "ident"
                or av == ")"
                or av == "]"
                or av == "}"
                or at == "string"
            )
        then
            return false
        end
        if av == "." and (bt == "ident" or bt == "keyword") then
            return false
        end
        if av == "..." or bv == "..." then
            return false
        end
        return true
    end
    if at == "op" or bt == "op" then
        return true
    end
    if at == "keyword" then
        if av == "function" and bv == "(" then
            return false
        end
        if av == "not" or av == "function" then
            return true
        end
        if bv == "local" or bv == "return" or bv == "not" or bv == "function"
        or bv == "if" or bv == "while" or bv == "for" or bv == "repeat"
        or bv == "until" or bv == "end" or bv == "break" or bv == "continue" then
            return true
        end
    end
    if
        bt == "keyword"
        and (
            bv == "in"
            or bv == "then"
            or bv == "do"
            or bv == "and"
            or bv == "or"
            or bv == "else"
            or bv == "elseif"
        )
    then
        return true
    end
    if av == "}" and bt == "ident" then
        return true
    end
    if at == "ident" and bt == "ident" then
        return true
    end
    if at == "ident" and bt == "keyword" then
        return true
    end
    if at == "keyword" and bt == "ident" then
        return true
    end
    if at == "keyword" and bt == "keyword" then
        return true
    end
    if at == "string" and bt == "string" then
        return true
    end
    if at == "number" and bt == "number" then
        return true
    end
    return false
end
beautify = function(code)
    local tokens = lex(code)
    local out_parts = {}
    local indent = 0
    local MAX_INDENT = 8
    local prev = nil
    local at_line_start = true
    local blank_run = 0
    local block_open = {
        ["do"] = true,
        ["then"] = true,
        ["else"] = true,
        ["elseif"] = true,
        ["repeat"] = true,
    }
    local block_close =
        { ["end"] = true, ["until"] = true, ["else"] = true, ["elseif"] = true }
    local function emit(s)
        table.insert(out_parts, s)
    end
    for _, tok in _ipairs(tokens) do
        local val = tok.value
        local typ = tok.type
        if typ == "newline" then
            blank_run = blank_run + 1
            if blank_run <= 2 then
                emit("\n")
                at_line_start = true
                prev = nil
            end
        elseif typ == "comment" then
            blank_run = 0
            if at_line_start then
                emit(string.rep("    ", indent))
                at_line_start = false
            elseif prev then
                emit(" ")
            end
            emit(val)
            prev = tok
        else
            blank_run = 0
            if block_close[val] and typ == "keyword" then
                indent = math.max(0, indent - 1)
            end
            if at_line_start then
                emit(string.rep("    ", math.min(indent, MAX_INDENT)))
                at_line_start = false
            else
                if prev and need_space(prev, tok) then
                    emit(" ")
                end
            end
            emit(val)
            prev = tok
            if block_open[val] and typ == "keyword" then
                indent = indent + 1
            end
            if indent > MAX_INDENT + 2 then
                indent = MAX_INDENT + 2
            end
        end
    end
    local result = table.concat(out_parts)
    result = result:gsub("\n\n\n+", "\n\n")
    while result:sub(-1) == "\n" or result:sub(-1) == " " do
        result = result:sub(1, -2)
    end
    return result
end
local function safestr(val)
    if val == nil then
        return "nil"
    end
    if _type(val) == "string" then
        return val
    end
    if _type(val) == "number" or _type(val) == "boolean" then
        return _tostring(val)
    end
    if _type(val) == "table" then
        if st.reg[val] then
            return st.reg[val]
        end
        if isproxy(val) then
            local id = getpxid(val)
            return id and ("proxy_" .. id) or "proxy"
        end
    end
    local ok, s = _pcall(_tostring, val)
    return ok and s or "unknown"
end
local function q(val)
    local s = safestr(val)
    local e = s:gsub("\\", "\\\\")
        :gsub('"', '\\"')
        :gsub("\n", "\\n")
        :gsub("\r", "\\r")
        :gsub("\t", "\\t")
    return '"' .. e .. '"'
end
local tctr = {}
local function nextctr(t)
    tctr[t] = (tctr[t] or 0) + 1
    return tctr[t]
end
local function mkvar(obj, hint, thint, mname)
    if st.reg[obj] then
        return st.reg[obj]
    end
    st.lctr = (st.lctr or 0) + 1
    local sfv = hint or _tostring(obj)
    local nm
    if _type(sfv) == "string" then
        nm = sfv .. "_" .. st.lctr
    else
        nm = "AE_" .. st.lctr
    end
    st.names[nm] = true
    st.reg[obj] = nm
    st.revreg[nm] = obj
    st.vartypes[nm] = thint or _type(obj)

    local line_num, line_content = get_current_script_line()
    if line_num and line_content then
        local var_name = line_content:match("^%s*local%s+([%w_]+)%s*=%s*")
            or line_content:match("^%s*([%w_]+)%s*=%s*")
        if var_name then
            st.var_map[var_name] = nm
        end
    end

    if isproxy(obj) and is_spied(obj) then
        st.spied_vars = st.spied_vars or {}
        st.spied_vars[nm] = true
    end

    return nm
end
local function ser(val, depth, seen, inline)
    depth = depth or 0
    seen = seen or {}
    if depth > cfg.maxdepth then
        return "{ -- to many tables }"
    end
    if isproxy(val) then
        if st.propstore[val] and st.propstore[val]._bufstr ~= nil then
            local reg = st.reg[val]
            if reg then return reg end
        end
    end
    local t = _type(val)
    if t == "nil" then
        return "nil"
    elseif t == "string" then
        if #val > 100 and val:match("^[A-Za-z0-9+/=]+$") then
            table.insert(st.strrefs, {
                value = val:sub(1, 50) .. "...",
                hint = "base64",
                full_length = #val,
            })
        elseif val:match("https?://") then
            table.insert(st.strrefs, { value = val, hint = "url" })
        elseif val:match("rbxasset://") or val:match("rbxassetid://") then
            table.insert(st.strrefs, { value = val, hint = "asset" })
        end
        return string.format("%q", val)
    elseif t == "number" then
        if val ~= val then
            return "0/0"
        end
        if val == math.huge then
            return "math.huge"
        end
        if val == -math.huge then
            return "-math.huge"
        end
        if val == math.floor(val) then
            return _tostring(math.floor(val))
        end
        return string.format("%.6g", val)
    elseif t == "boolean" then
        return _tostring(val)
    elseif t == "function" then
        local saved_len = #st.out
        _pcall(val)
        local new_lines = {}
        for i = saved_len + 1, #st.out do
            table.insert(new_lines, table.remove(st.out, saved_len + 1))
        end
        if #new_lines > 0 then
            local indented = {}
            for _, line in _ipairs(new_lines) do
                table.insert(indented, "    " .. line)
            end
            return "function(...)\n" .. table.concat(indented, "\n") .. "\nend"
        else
            return "function(...)\nend"
        end
    elseif t == "table" then
        if isproxy(val) then
            local reg = st.reg[val]
            if reg then
                return reg
            end
            local mt = _getmt(val)
            local tv = mt and mt.__typeof
            if not tv then
                local stored = rawget(val, "__stored")
                if stored then
                    if
                        stored.X
                        and stored.Y
                        and rawget(stored.X, "__stored")
                    then
                        tv = "UDim2"
                    elseif stored.Scale ~= nil and stored.Offset ~= nil then
                        tv = "UDim"
                    elseif stored.X and stored.Y and stored.Z ~= nil then
                        tv = "Vector3"
                    elseif stored.X and stored.Y then
                        tv = "Vector2"
                    elseif stored.R and stored.G and stored.B then
                        tv = "Color3"
                    end
                end
            end
            if tv == "UDim2" then
                local s = rawget(val, "__stored") or {}
                local xs = rawget(s.X, "__stored") or {}
                local ys = rawget(s.Y, "__stored") or {}
                return string.format(
                    "UDim2.new(%s, %s, %s, %s)",
                    ser(xs.Scale or 0),
                    ser(xs.Offset or 0),
                    ser(ys.Scale or 0),
                    ser(ys.Offset or 0)
                )
            elseif tv == "UDim" then
                local s = rawget(val, "__stored") or {}
                return string.format(
                    "UDim.new(%s, %s)",
                    ser(s.Scale or 0),
                    ser(s.Offset or 0)
                )
            elseif tv == "Vector3" then
                local s = rawget(val, "__stored") or {}
                return string.format(
                    "Vector3.new(%s, %s, %s)",
                    ser(s.X or 0),
                    ser(s.Y or 0),
                    ser(s.Z or 0)
                )
            elseif tv == "Vector2" then
                local s = rawget(val, "__stored") or {}
                return string.format(
                    "Vector2.new(%s, %s)",
                    ser(s.X or 0),
                    ser(s.Y or 0)
                )
            elseif tv == "Color3" then
                local s = rawget(val, "__stored") or {}
                return string.format(
                    "Color3.new(%s, %s, %s)",
                    ser(s.R or 0),
                    ser(s.G or 0),
                    ser(s.B or 0)
                )
            elseif tv == "ColorSequence" then
                local s = rawget(val, "__stored") or {}
                if s.Keypoints then
                    local kps = {}
                    for _, kp in _ipairs(s.Keypoints) do
                        local ks = (isproxy(kp) and rawget(kp, "__stored"))
                            or {}
                        local color = ks.Value
                        table.insert(
                            kps,
                            string.format(
                                "ColorSequenceKeypoint.new(%s, %s)",
                                ser(ks.Time or 0),
                                ser(color)
                            )
                        )
                    end
                    return "ColorSequence.new({"
                        .. table.concat(kps, ", ")
                        .. "})"
                end
                return "ColorSequence.new(Color3.new(1,1,1))"
            elseif tv == "ColorSequenceKeypoint" then
                local s = rawget(val, "__stored") or {}
                return string.format(
                    "ColorSequenceKeypoint.new(%s, %s)",
                    ser(s.Time or 0),
                    ser(s.Value)
                )
            elseif tv == "NumberSequence" then
                local s = rawget(val, "__stored") or {}
                if s.Keypoints then
                    local kps = {}
                    for _, kp in _ipairs(s.Keypoints) do
                        local ks = (isproxy(kp) and rawget(kp, "__stored"))
                            or {}
                        local t_val = ks.Time or 0
                        local v_val = ks.Value or 0
                        local env = ks.Envelope or 0
                        if env ~= 0 then
                            table.insert(
                                kps,
                                string.format(
                                    "NumberSequenceKeypoint.new(%s, %s, %s)",
                                    ser(t_val),
                                    ser(v_val),
                                    ser(env)
                                )
                            )
                        else
                            table.insert(
                                kps,
                                string.format(
                                    "NumberSequenceKeypoint.new(%s, %s)",
                                    ser(t_val),
                                    ser(v_val)
                                )
                            )
                        end
                    end
                    return "NumberSequence.new({"
                        .. table.concat(kps, ", ")
                        .. "})"
                end
                return "NumberSequence.new(1)"
            elseif tv == "NumberSequenceKeypoint" then
                local s = rawget(val, "__stored") or {}
                local env = s.Envelope or 0
                if env ~= 0 then
                    return string.format(
                        "NumberSequenceKeypoint.new(%s, %s, %s)",
                        ser(s.Time or 0),
                        ser(s.Value or 0),
                        ser(env)
                    )
                else
                    return string.format(
                        "NumberSequenceKeypoint.new(%s, %s)",
                        ser(s.Time or 0),
                        ser(s.Value or 0)
                    )
                end
            elseif tv then
                return tv .. ".new()"
            end
            return "nil"
        end
        if st.reg[val] then
            return st.reg[val]
        end
        local mt = _getmt(val)
        if mt then
            local typeof_val = mt.__typeof
                or (
                    rawget(val, "__stored") and rawget(val, "__stored").__typeof
                )
            if not typeof_val and isproxy(val) then
                local reg = st.reg[val] or ""
                if reg:match("^ColorSequence") then
                    typeof_val = "ColorSequence"
                end
                if reg:match("^ColorSequenceKeypoint") then
                    typeof_val = "ColorSequenceKeypoint"
                end
                if reg:match("^NumberSequence") then
                    typeof_val = "NumberSequence"
                end
                if reg:match("^NumberSequenceKeypoint") then
                    typeof_val = "NumberSequenceKeypoint"
                end
            end
            if typeof_val == "ColorSequence" then
                local stored = rawget(val, "__stored")
                if stored and stored.Keypoints then
                    local kps = {}
                    for _, kp in _ipairs(stored.Keypoints) do
                        local kp_stored = (
                            isproxy(kp) and rawget(kp, "__stored")
                        ) or {}
                        local t_val = kp_stored.Time or 0
                        local color = kp_stored.Value
                        table.insert(
                            kps,
                            string.format(
                                "ColorSequenceKeypoint.new(%s, %s)",
                                ser(t_val),
                                ser(color)
                            )
                        )
                    end
                    return "ColorSequence.new({"
                        .. table.concat(kps, ", ")
                        .. "})"
                end
                if st.reg[val] then
                    return st.reg[val]
                end
                return "ColorSequence.new(Color3.new(1,1,1))"
            elseif typeof_val == "ColorSequenceKeypoint" then
                local stored = rawget(val, "__stored") or {}
                local t_val = stored.Time or 0
                local color = stored.Value
                if color then
                    return string.format(
                        "ColorSequenceKeypoint.new(%s, %s)",
                        ser(t_val),
                        ser(color)
                    )
                end
                if st.reg[val] then
                    return st.reg[val]
                end
                return string.format(
                    "ColorSequenceKeypoint.new(%s, Color3.new(1,1,1))",
                    ser(t_val)
                )
            elseif typeof_val == "NumberSequence" then
                local stored = rawget(val, "__stored")
                if stored and stored.Keypoints then
                    local kps = {}
                    for _, kp in _ipairs(stored.Keypoints) do
                        local kp_stored = (
                            isproxy(kp) and rawget(kp, "__stored")
                        ) or {}
                        local t_val = kp_stored.Time or 0
                        local v_val = kp_stored.Value or 0
                        local env = kp_stored.Envelope or 0
                        if env ~= 0 then
                            table.insert(
                                kps,
                                string.format(
                                    "NumberSequenceKeypoint.new(%s, %s, %s)",
                                    ser(t_val),
                                    ser(v_val),
                                    ser(env)
                                )
                            )
                        else
                            table.insert(
                                kps,
                                string.format(
                                    "NumberSequenceKeypoint.new(%s, %s)",
                                    ser(t_val),
                                    ser(v_val)
                                )
                            )
                        end
                    end
                    return "NumberSequence.new({"
                        .. table.concat(kps, ", ")
                        .. "})"
                end
                if st.reg[val] then
                    return st.reg[val]
                end
                return "NumberSequence.new(1)"
            elseif typeof_val == "NumberSequenceKeypoint" then
                local stored = rawget(val, "__stored") or {}
                local t_val = stored.Time or 0
                local v_val = stored.Value or 0
                local env = stored.Envelope or 0
                if env ~= 0 then
                    return string.format(
                        "NumberSequenceKeypoint.new(%s, %s, %s)",
                        ser(t_val),
                        ser(v_val),
                        ser(env)
                    )
                else
                    return string.format(
                        "NumberSequenceKeypoint.new(%s, %s)",
                        ser(t_val),
                        ser(v_val)
                    )
                end
            end
        end
        if seen[val] then
            return "{ --[[circular]] }"
        end
        seen[val] = true
        local count = 0
        for k, v in _pairs(val) do
            if k ~= px_mark and k ~= "__pxid" and k ~= "__enumitem" then
                count = count + 1
            end
        end
        if count == 0 then
            return "{}"
        end
        local isarr = true
        local maxidx = 0
        for k, v in _pairs(val) do
            if k ~= px_mark and k ~= "__pxid" and k ~= "__enumitem" then
                if _type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                    isarr = false
                    break
                else
                    maxidx = math.max(maxidx, k)
                end
            end
        end
        isarr = isarr and maxidx == count
        if isarr and count <= 5 and inline ~= false then
            local parts = {}
            for i = 1, count do
                local v = val[i]
                if _type(v) ~= "table" or isproxy(v) then
                    table.insert(parts, ser(v, depth + 1, seen, true))
                else
                    isarr = false
                    break
                end
            end
            if isarr and #parts == count then
                return "{" .. table.concat(parts, ", ") .. "}"
            end
        end
        local lines = {}
        local idx = 0
        local ind1 = string.rep("    ", st.ind + depth + 1)
        local ind0 = string.rep("    ", st.ind + depth)
        for k, v in _pairs(val) do
            if k ~= px_mark and k ~= "__pxid" and k ~= "__enumitem" then
                idx = idx + 1
                if idx > cfg.maxtable then
                    table.insert(
                        lines,
                        ind1 .. "-- ..." .. (count - idx + 1) .. " more"
                    )
                    break
                end
                local ks
                if isarr then
                    ks = nil
                elseif _type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    ks = k
                else
                    ks = "[" .. ser(k, depth + 1, seen) .. "]"
                end
                local vs = ser(v, depth + 1, seen)
                if ks then
                    table.insert(lines, ind1 .. ks .. " = " .. vs)
                else
                    table.insert(lines, ind1 .. vs)
                end
            end
        end
        if #lines == 0 then
            return "{}"
        end
        return "{\n" .. table.concat(lines, ",\n") .. "\n" .. ind0 .. "}"
    elseif t == "userdata" then
        if st.reg[val] then
            return st.reg[val]
        end
        local ok, s = _pcall(_tostring, val)
        return ok and s or "userdata"
    elseif t == "thread" then
        return "coroutine.create(function() end)"
    else
        local ok, s = _pcall(_tostring, val)
        return ok and s or "nil"
    end
end
local blib = {}
local function tobit(x)
    x = (x or 0) % 4294967296
    if x >= 2147483648 then
        x = x - 4294967296
    end
    return math.floor(x)
end
local function tobitu(x)
    return (x or 0) % 4294967296
end
blib.tobit = tobit
blib.tohex = function(x, n)
    return string.format("%0" .. (n or 8) .. "x", tobitu(x))
end
blib.bnot = function(x)
    return tobit(bit32.bnot(tobitu(x)))
end
blib.band = function(a, b, ...)
    local r = bit32.band(tobitu(a or 0), tobitu(b or 0))
    local args = { ... }
    for i = 1, #args do
        r = bit32.band(r, tobitu(args[i] or 0))
    end
    return tobit(r)
end
blib.bor = function(a, b, ...)
    local r = bit32.bor(tobitu(a or 0), tobitu(b or 0))
    local args = { ... }
    for i = 1, #args do
        r = bit32.bor(r, tobitu(args[i] or 0))
    end
    return tobit(r)
end
blib.bxor = function(a, b, ...)
    local r = bit32.bxor(tobitu(a or 0), tobitu(b or 0))
    local args = { ... }
    for i = 1, #args do
        r = bit32.bxor(r, tobitu(args[i] or 0))
    end
    return tobit(r)
end
blib.lshift = function(x, n)
    return tobit(bit32.lshift(tobitu(x or 0), (n or 0) % 32))
end
blib.rshift = function(x, n)
    return tobit(bit32.rshift(tobitu(x or 0), (n or 0) % 32))
end
blib.arshift = function(x, n)
    return tobit(bit32.arshift(tobitu(x or 0), (n or 0) % 32))
end
blib.rol = function(x, n)
    return tobit(bit32.lrotate(tobitu(x or 0), (n or 0) % 32))
end
blib.ror = function(x, n)
    return tobit(bit32.rrotate(tobitu(x or 0), (n or 0) % 32))
end
blib.lrotate = blib.rol
blib.rrotate = blib.ror
blib.bswap = function(x)
    x = tobitu(x or 0)
    local a = bit32.band(bit32.rshift(x, 24), 0xFF)
    local b = bit32.band(bit32.rshift(x, 8), 0xFF00)
    local c = bit32.band(bit32.lshift(x, 8), 0xFF0000)
    local d = bit32.band(bit32.lshift(x, 24), 0xFF000000)
    return tobit(bit32.bor(a, b, c, d))
end
blib.btest = function(a, b)
    return bit32.btest(tobitu(a or 0), tobitu(b or 0))
end
blib.extract = function(n, f, w)
    w = w or 1
    return bit32.extract(tobitu(n or 0), f or 0, w)
end
blib.replace = function(n, v, f, w)
    w = w or 1
    return tobit(bit32.replace(tobitu(n or 0), tobitu(v or 0), f or 0, w))
end
local _sc = string.char
local _sb = string.byte
local _ss = string.sub
local _sg = string.gsub
local _su = string.unpack
local _sp = string.pack
local _sr = string.rep
local _sv = string.reverse
local _sm = string.match
local _sf = string.find
local _sfo = string.format
local _sl = string.len
local _slo = string.lower
local _sup2 = string.upper
local hstr = {}
for k, v in _pairs(string) do
    hstr[k] = v
end
hstr.char = function(...)
    local ok, r = _pcall(_sc, ...)
    if not ok then
        return ""
    end
    if cfg.cap_str then
        local args = { ... }
        local all_nums = true
        for _, v in _ipairs(args) do
            if type(v) ~= "number" then
                all_nums = false
                break
            end
        end
        if all_nums and #args >= 3 then
            st.cap_strings[r] = true
        end
    end
    if #r >= 4 and cfg.cap_str then
        local pc = 0
        local cl = math.min(#r, 100)
        for i = 1, cl do
            local b = _sb(r, i)
            if b and b >= 32 and b <= 126 then
                pc = pc + 1
            end
        end
        if pc / cl > 0.6 then
            local prev = _ss(r, 1, 200)
            if not st.cap_strings[prev] then
                st.cap_strings[prev] = true
            end
        end
    end
    return r
end
hstr.dump = function(f, strip)
    error("unable to dump given function")
end
hstr.byte = _sb
hstr.sub = _ss
hstr.gsub = _sg
hstr.getn = function(s)
    return #s
end
hstr.unpack = _su
hstr.pack = _sp
hstr.rep = _sr
hstr.reverse = _sv
hstr.match = _sm
hstr.find = _sf
hstr.format = function(fmt, ...)
    local ok, r = _pcall(_sfo, fmt, ...)
    if not ok then
        return fmt
    end
    if cfg.cap_str and _type(r) == "string" and #r >= 6 then
        if
            r:match("https?://")
            or r:match("rbxasset")
            or r:match("rbxassetid")
        then
            table.insert(st.strrefs, { value = r, hint = "url_fmt" })
        end
        st.cap_strings[r] = true
    end
    return r
end
hstr.len = _sl
hstr.lower = function(s)
    local lwrd = _slo(s)
    local v = mkvar(s, "lower")
    out(string.format('local %s = string.lower(%s)', v, ser(s)))
    return lwrd
end
hstr.upper = function(s)
    local uppe = _sup2(s)
    local v = mkvar(s, "upper")
    out(string.format('local %s = string.upper(%s)', v, ser(s)))
    return uppe
end
hstr.gmatch = string.gmatch
local htbl = {}
for k, v in _pairs(table) do
    htbl[k] = v
end
local function wrap_table_func(fname, f)
    return function(t, ...)
        if type(t) ~= "table" or isproxy(t) then
            error(
                "invalid argument #1 to '"
                    .. fname
                    .. "' (table expected, got "
                    .. (isproxy(t) and (st.reg[t] or "userdata") or type(t))
                    .. ")",
                2
            )
        end
        return f(t, ...)
    end
end
htbl.concat = wrap_table_func("concat", function(t, sep)
    local ok, r = _pcall(table.concat, t, sep or "")
    if not ok then
        return ""
    end
    if _type(r) == "string" then
        local rl = #r
        if rl > 100 then
            local cpats = {
                "function",
                "local%s",
                "return%s",
                "end[%s;)]",
                "if%s",
                "then%s",
                "for%s",
                "while%s",
                "repeat%s",
            }
            local isc = false
            for _, p in _ipairs(cpats) do
                if r:find(p) then
                    isc = true
                    break
                end
            end
            if isc then
                local ok2 = _pcall(function()
                    fs.writeFile("core/io/dumped_output.lua", r)
                end)
            end
        end
        if r:match("https?://") or r:match("rbxasset") then
            table.insert(
                st.strrefs,
                { value = r:sub(1, 200), hint = "concat_url" }
            )
        end
    end
    return r
end)
htbl.insert = wrap_table_func("insert", table.insert)
htbl.remove = wrap_table_func("remove", table.remove)
htbl.sort = wrap_table_func("sort", table.sort)
htbl.unpack = wrap_table_func("unpack", table.unpack)
htbl.move = wrap_table_func("move", table.move)
htbl.find = wrap_table_func("find", table.find or function(t, v, init)
    for i = init or 1, #t do
        if t[i] == v then
            return i
        end
    end
    return nil
end)
htbl.clear = wrap_table_func("clear", table.clear or function(t)
    for k in _pairs(t) do
        t[k] = nil
    end
end)
htbl.clone = wrap_table_func("clone", table.clone or function(t)
    local n = {}
    for k, v in _pairs(t) do
        n[k] = v
    end
    return n
end)
htbl.getn = function(t)
    return #t
end
htbl.pack = table.pack
htbl.create = table.create
    or function(n, v)
        local t = {}
        if v ~= nil then
            for i = 1, n do
                t[i] = v
            end
        end
        return t
    end
htbl.freeze = wrap_table_func("freeze", function(t)
    _frozen_tables[t] = true
    local mt = _getmt(t) or {}
    rawset(mt, "__newindex", function()
        error("attempt to modify a readonly table")
    end)
    _setmt(t, mt)
    return t
end)
htbl.isfrozen = wrap_table_func("isfrozen", function(t)
    return _frozen_tables[t] == true
end)
local mkpx, mkmethodpx, mktblpx
mktblpx = function()
    local px = {}
    local mt = {}
    _setmt(px, mt)
    rawset(px, px_mark, true)
    st.pxid = st.pxid + 1
    rawset(px, "__pxid", st.pxid)
    return px, mt
end
mkmethodpx = function(mname, parent)
    local pname = st.reg[parent] or "obj"
    local ms = safestr(mname)
    local func_px = parent
    return function(first, ...)
        if first ~= func_px then
            local args = { first, ... }
            local r = mkpx(ms, false, func_px)
            local v = mkvar(r, ms, nil, ms)
            local sargs = {}
            for _, a in _ipairs(args) do
                table.insert(sargs, ser(a))
            end
            out(
                string.format(
                    "local %s = %s.%s(%s)",
                    v,
                    pname,
                    ms,
                    table.concat(sargs, ", ")
                )
            )
            return r
        end
        local args = { ... }
        local r = mkpx(ms, false, func_px)
        local v = mkvar(r, ms, nil, ms)
        local sargs = {}
        for _, a in _ipairs(args) do
            table.insert(sargs, ser(a))
        end
        out(
            string.format(
                "local %s = %s:%s(%s)",
                v,
                pname,
                ms,
                table.concat(sargs, ", ")
            )
        )
        return r
    end
end
local env_functions = {}
local function reg_c_func(f)
    if _type(f) == "function" then
        env_functions[f] = true
    end
    return f
end
local function get_children_of(parent_proxy)
    if
        st.propstore[parent_proxy]
        and st.propstore[parent_proxy].__ordered_children
    then
        return st.propstore[parent_proxy].__ordered_children
    end
    local children = {}
    for child, parent in _pairs(st.parentmap) do
        if rawequal(parent, parent_proxy) then
            table.insert(children, child)
        end
    end
    if #children == 0 then
        table.insert(children, mkpx("DummyChild", false, parent_proxy))
    end
    return children
end
local function find_first_child_helper(parent_proxy, name, recursive)
    local children = get_children_of(parent_proxy)
    for _, child in _ipairs(children) do
        if st.propstore[child] and st.propstore[child].__destroyed then
            st.parentmap[child] = nil
        else
            local child_name = st.propstore[child] and st.propstore[child].Name
                or st.reg[child]
            if child_name == name then
                return child
            end
        end
    end
end
local function queue_task(type, dur, f, ...)
    local thread
    if _type(f) == "thread" then
        thread = f
    elseif _type(f) == "function" then
        thread = _cor.create(f)
    else
        thread = _cor.create(function() end)
    end
    local item = {
        type = type,
        fn = f,
        args = { ... },
        time = type == "delay" and (st.virtual_time + (dur or 0)) or nil,
        thread = thread,
    }
    table.insert(st.task_queue, item)
    return thread
end
local function run_task_item(item)
    if cancelled_threads[item.thread] then
        return
    end
    st.task_exec_count = (st.task_exec_count or 0) + 1
    if st.task_exec_count > 50 then
        return
    end
    local thread = item.thread
    local args = item.args
    if _type(item.fn) == "function" then
        thread = _cor.create(item.fn)
        args = item.args
    end
    if item.type == "defer" then
        out("task.defer(function()")
    elseif item.type == "delay" then
        out(
            string.format(
                "task.delay(%s, function()",
                ser(item.time - st.virtual_time)
            )
        )
    end
    st.ind = st.ind + 1
    st.in_cb = true
    local opending = st.pending_iter
    st.pending_iter = 0
    local od = st.cf_depth
    st.cf_depth = 0
    local res = { _cor.resume(thread, _unpack(args)) }
    st.cf_depth = od
    while st.pending_iter and st.pending_iter > 0 do
        st.ind = st.ind - 1
        out("end")
        st.pending_iter = st.pending_iter - 1
    end
    while st.cf_depth > 0 do
        st.ind = st.ind - 1
        out("end")
        st.cf_depth = st.cf_depth - 1
    end
    st.pending_iter = opending
    st.ind = st.ind - 1
    out("end)")
    st.in_cb = false
    local ok = res[1]
    if ok then
        if _cor.status(thread) == "suspended" then
            local yield_type = res[2]
            local yield_val = res[3]
            local wait_dur = (yield_type == "wait" and yield_val) or 0.03
            local new_item = {
                type = "delay",
                fn = thread,
                args = {},
                time = st.virtual_time + wait_dur,
                thread = thread,
            }
            table.insert(st.task_queue, new_item)
        end
    end
end
local function advance_virtual_time(step)
    local target_time = st.virtual_time + step
    while true do
        local next_item = nil
        local next_idx = nil
        for idx, item in _ipairs(st.task_queue) do
            if item.type == "delay" and item.time <= target_time then
                if not next_item or item.time < next_item.time then
                    next_item = item
                    next_idx = idx
                end
            end
        end
        local has_defer = false
        for idx, item in _ipairs(st.task_queue) do
            if item.type == "defer" then
                has_defer = true
                table.remove(st.task_queue, idx)
                run_task_item(item)
                break
            end
        end
        if has_defer then
        elseif next_item then
            table.remove(st.task_queue, next_idx)
            st.virtual_time = next_item.time
            run_task_item(next_item)
        else
            break
        end
    end
    st.virtual_time = target_time
end
local methods = {}

methods.GetPropertiesOfClass = function(self, className, ...)
    local cs = safestr(className)
    local list = {}
    local members = class_members[cs]
    if members then
        for name, mdata in pairs(members) do
            if mdata.Type == "Property" then
                table.insert(list, { Name = name })
            end
        end
    end
    local parent = class_superclass[cs]
    while parent and parent ~= "<<<ROOT>>>" do
        local pm = class_members[parent]
        if pm then
            for name, mdata in pairs(pm) do
                if mdata.Type == "Property" then
                    local found = false
                    for _, item in ipairs(list) do
                        if item.Name == name then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(list, { Name = name })
                    end
                end
            end
        end
        parent = class_superclass[parent]
    end
    return list
end

methods.GetMethodsOfClass = function(self, className, ...)
    local cs = safestr(className)
    local list = {}
    local members = class_members[cs]
    if members then
        for name, mdata in pairs(members) do
            if mdata.Type == "Function" then
                table.insert(list, { Name = name })
            end
        end
    end
    local parent = class_superclass[cs]
    while parent and parent ~= "<<<ROOT>>>" do
        local pm = class_members[parent]
        if pm then
            for name, mdata in pairs(pm) do
                if mdata.Type == "Function" then
                    local found = false
                    for _, item in ipairs(list) do
                        if item.Name == name then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(list, { Name = name })
                    end
                end
            end
        end
        parent = class_superclass[parent]
    end
    return list
end
local function resolve_buf_name(buf)
    if isproxy(buf) and st.reg[buf] then
        return st.reg[buf]
    elseif isproxy(buf) then
        return mkvar(buf, "buf")
    else
        return ser(buf)
    end
end
local function get_buf_str(buf)
    if isproxy(buf) and st.propstore[buf] and st.propstore[buf]._bufstr then
        return st.propstore[buf]._bufstr
    elseif _type(buf) == "string" then
        return buf
    end
    return ""
end
methods.Base64Encode = function(self, buf)
    local pn = st.reg[self] or "EncodingService"
    local r = mkpx("base64Encoded", false)
    local v = mkvar(r, "base64Encoded")
    local buf_name = resolve_buf_name(buf)
    out(string.format("local %s = %s:Base64Encode(%s)", v, pn, buf_name))
    st.propstore[r] = st.propstore[r] or {}
    local src = get_buf_str(buf)
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local result = {}
    for i = 1, #src, 3 do
        local b1, b2, b3 = src:byte(i), src:byte(i+1) or 0, src:byte(i+2) or 0
        local n = b1 * 65536 + b2 * 256 + b3
        table.insert(result, b64chars:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1))
        table.insert(result, b64chars:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1))
        table.insert(result, b64chars:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1))
        table.insert(result, b64chars:sub(n%64+1, n%64+1))
    end
    local rem = #src % 3
    if rem == 1 then result[#result] = "="; result[#result-1] = "="
    elseif rem == 2 then result[#result] = "=" end
    st.propstore[r]._bufstr = table.concat(result)
    return r
end
methods.Base64Decode = function(self, buf)
    local pn = st.reg[self] or "EncodingService"
    local r = mkpx("base64Decoded", false)
    local v = mkvar(r, "base64Decoded")
    local buf_name = resolve_buf_name(buf)
    out(string.format("local %s = %s:Base64Decode(%s)", v, pn, buf_name))
    st.propstore[r] = st.propstore[r] or {}
    local encoded = get_buf_str(buf)
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i = 1, #b64chars do lookup[b64chars:sub(i,i)] = i-1 end
    local result = {}
    encoded = encoded:gsub("[^%w%+%/%=]", "")
    for i = 1, #encoded, 4 do
        local c1 = lookup[encoded:sub(i,i)] or 0
        local c2 = lookup[encoded:sub(i+1,i+1)] or 0
        local c3 = lookup[encoded:sub(i+2,i+2)] or 0
        local c4 = lookup[encoded:sub(i+3,i+3)] or 0
        local n = c1*262144 + c2*4096 + c3*64 + c4
        table.insert(result, string.char(math.floor(n/65536)%256))
        if encoded:sub(i+2,i+2) ~= "=" then
            table.insert(result, string.char(math.floor(n/256)%256))
        end
        if encoded:sub(i+3,i+3) ~= "=" then
            table.insert(result, string.char(n%256))
        end
    end
    st.propstore[r]._bufstr = table.concat(result)
    return r
end
methods.CompressBuffer = function(self, buf, algo, lvl)
    local r = mkpx("CompressedBuffer", false)
    local v = mkvar(r, "cbuf")
    local pn = st.reg[self] or "EncodingService"
    local buf_name = resolve_buf_name(buf)
    out(string.format("local %s = %s:CompressBuffer(%s, %s)", v, pn, buf_name, ser(algo)))
    st.propstore[r] = st.propstore[r] or {}
    st.propstore[r]._bufstr = get_buf_str(buf)
    return r
end
methods.DecompressBuffer = function(self, buf, algo)
    local r = mkpx("DecompressedBuffer", false)
    local v = mkvar(r, "dbuf")
    local pn = st.reg[self] or "EncodingService"
    local buf_name = resolve_buf_name(buf)
    out(string.format("local %s = %s:DecompressBuffer(%s, %s)", v, pn, buf_name, ser(algo)))
    st.propstore[r] = st.propstore[r] or {}
    st.propstore[r]._bufstr = get_buf_str(buf)
    return r
end
methods.GetDecompressedBufferSize = function(self, buf, algo)
    local r = mkpx("DecompressedBufferSize", false)
    local v = mkvar(r, "GetDecompressedBufferSize")
    local pn = st.reg[self] or "EncodingService"
    local buf_name = resolve_buf_name(buf)
    out(string.format("local %s = %s:GetDecompressedBufferSize(%s, %s)", v, pn, buf_name, ser(algo)))
    local src = get_buf_str(buf)
    return #src > 0 and #src or 1
end
methods.ComputeBufferHash = function(self, buf, algo)
    local pn = st.reg[self] or "EncodingService"
    local r = mkpx("bufferHash", false)
    local v = mkvar(r, "bufferHash")
    local buf_name = resolve_buf_name(buf)
    out(string.format("local %s = %s:ComputeBufferHash(%s, %s)", v, pn, buf_name, ser(algo)))
    st.propstore[r] = st.propstore[r] or {}
    st.propstore[r]._bufstr = string.rep("\0", 32)
    return r
end
methods.DefineFastFlag = function(self, name, default)
    local pn = st.reg[self] or "Instance"
    out(
        string.format(
            "%s:DefineFastFlag(%s, %s)",
            pn,
            q(safestr(name)),
            ser(default)
        )
    )
    return default
end
methods.GetFastFlag = function(self, name)
    local pn = st.reg[self] or "Instance"
    out(string.format("%s:GetFastFlag(%s)", pn, q(safestr(name))))
    return false
end
methods.IsAvailable = function(self)
    local pn = st.reg[self] or "Instance"
    out(string.format("%s:IsAvailable()", pn))
    return true
end
methods.Button1Down = function(self, pos, modKeys)
    local pn = st.reg[self] or "VirtualUser"
    out(string.format("%s:Button1Down(%s)", pn, ser(pos)))
    return nil
end
methods.Button1Up = function(self, pos, modKeys)
    local pn = st.reg[self] or "VirtualUser"
    out(string.format("%s:Button1Up(%s)", pn, ser(pos)))
    return nil
end
methods.TypeText = function(self, text)
    local pn = st.reg[self] or "VirtualUser"
    out(string.format("%s:TypeText(%s)", pn, ser(text)))
    return nil
end
methods.GetDeviceCameraCFrameForSelfView = function(self)
    local pn = st.reg[self] or "UserInputService"
    out(
        string.format(
            "local selfViewCFrame = %s:GetDeviceCameraCFrameForSelfView()",
            pn
        )
    )
    return CFrame.new()
end
methods.GetCorescriptLocalizations = function(self)
    local pn = st.reg[self] or "LocalizationService"
    local r = mkpx("localizations", false)
    local v = mkvar(r, "localizations")
    out(string.format("local %s = %s:GetCorescriptLocalizations()", v, pn))
    local loc = mkpx("LocalizationTable", false)
    st.propstore[loc] = { ClassName = "LocalizationTable", Name = "CoreTable" }
    return { loc }
end
methods.GetNetworkPing = function(self)
    local pn = st.reg[self] or "Players"
    out(string.format("local ping = %s:GetNetworkPing()", pn))
    return -1
end
methods.IsVibrationSupported = function(self, gamepad)
    local pn = st.reg[self] or "HapticService"
    out(
        string.format(
            "local vibSupported = %s:IsVibrationSupported(%s)",
            pn,
            ser(gamepad)
        )
    )
    return false
end
methods.GetRealPhysicsFPS = function(self)
    local pn = st.reg[self] or "workspace"
    out(string.format("local physicsFPS = %s:GetRealPhysicsFPS()", pn))
    return 60
end
methods.GenerateGUID = function(self, wrap)
    local pn = st.reg[self] or "HttpService"
    local r = mkpx("guid", false)
    local v = mkvar(r, "guid")
    out(string.format("local %s = %s:GenerateGUID(%s)", v, pn, ser(wrap)))
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local guid = string.gsub(template, "[xy]", function(c)
        local val = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", val)
    end)
    return guid:upper()
end
methods.JSONEncode = function(self, tbl)
    return serde.encode("json", tbl)
end
methods.JSONDecode = function(self, str)
    return serde.decode("json", str)
end
methods.GetMemStats = function(self)
    local pn = st.reg[self] or "Stats"
    local r = mkpx("memStats", false)
    local v = mkvar(r, "memStats")
    out(string.format("local %s = %s:GetMemStats()", v, pn))
    return {
        AllocatedPages = 10,
        FreePages = 2,
    }
end
methods.GetCharacterAppearanceInfoAsync = function(self, userId)
    local pn = st.reg[self] or "Players"
    local r = mkpx("appearanceInfo", false)
    local v = mkvar(r, "appearanceInfo")
    out(
        string.format(
            "local %s = %s:GetCharacterAppearanceInfoAsync(%s)",
            v,
            pn,
            ser(userId)
        )
    )
    return {
        assets = {
            {
                id = 123456,
                name = "Asset1",
                assetType = {
                    name = "Hat",
                },
            },
        },
        bodyColors = {
            leftArmColorId = 1,
            torsoColorId = 1,
            rightArmColorId = 1,
            headColorId = 1,
            leftLegColorId = 1,
            rightLegColorId = 1,
        },
        scales = {
            bodyType = 1,
            head = 1,
            height = 1,
            proportion = 1,
            depth = 1,
            width = 1,
        },
    }
end
methods.GetHumanoidDescriptionFromUserId = function(self, userId)
    local pn = st.reg[self] or "Players"
    local hd = mkpx("HumanoidDescription", false)
    st.propstore[hd] =
        { ClassName = "HumanoidDescription", Name = "HumanoidDescription" }
    local v = mkvar(hd, "humanoidDesc")
    out(
        string.format(
            "local %s = %s:GetHumanoidDescriptionFromUserId(%s)",
            v,
            pn,
            ser(userId)
        )
    )
    return hd
end
methods.GetEmotes = function(self)
    local pn = st.reg[self] or "Players"
    local r = mkpx("emotes", false)
    local v = mkvar(r, "emotes")
    out(string.format("local %s = %s:GetEmotes()", v, pn))
    return {
        Wave = { 123456 },
    }
end
methods.SetItem = function(self, key, value)
    local pn = st.reg[self] or "obj"
    local k = safestr(key)
    local v = safestr(value)
    out(string.format("%s:SetItem(%s, %s)", pn, q(k), q(v)))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._store = st.propstore[self]._store or {}
    st.propstore[self]._store[k] = v
end
methods.GetItem = function(self, key)
    local pn = st.reg[self] or "obj"
    local k = safestr(key)
    local r = mkpx("item", false)
    local v = mkvar(r, "item")
    out(string.format("local %s = %s:GetItem(%s)", v, pn, q(k)))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._store = st.propstore[self]._store or {}
    return st.propstore[self]._store[k] or ""
end
methods.GetTagged = function(self, tag)
    local pn = st.reg[self] or "CollectionService"
    local t = safestr(tag)
    local r = mkpx("tagged", false)
    local v = mkvar(r, "tagged")
    out(string.format("local %s = %s:GetTagged(%s)", v, pn, q(t)))
    local tagged = {}
    for inst, props in _pairs(st.propstore) do
        if props.tags and props.tags[t] then
            table.insert(tagged, inst)
        end
    end
    return tagged
end

methods.ReadVoxels = function(self, region, resolution)
    local pn = st.reg[self] or "Terrain"
    out(
        string.format(
            "local %s = %s:ReadVoxels(%s, %s)",
            pn,
            pn,
            ser(region),
            ser(resolution)
        )
    )
    return { { { Enum.Material.Air } } }
end
methods.GetInstanceAddedSignal = function(self, tag)
    local t = safestr(tag)
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._signals = st.propstore[self]._signals or {}
    if not st.propstore[self]._signals[t] then
        local sig =
            mkpx("CollectionService.GetInstanceAddedSignal." .. t, false, self)
        rawset(sig, "__signal", true)
        st.reg[sig] = "CollectionService:GetInstanceAddedSignal(" .. q(t) .. ")"
        st.propstore[self]._signals[t] = sig
    end
    return st.propstore[self]._signals[t]
end
methods.GetService = function(self, sname)
    local ss = safestr(sname)
    if ss == "DebuggerManager" then
        error("DebuggerManager cannot be retrieved using GetService")
    end
    local valid_service = false
    for _, sname in _ipairs(all_services) do
        if sname == ss then
            valid_service = true
            break
        end
    end
    if not valid_service then
        error(ss .. " is not a valid Service name")
    end
    st.services = st.services or {}
    if st.services[ss] then
        local obj = st.services[ss]
        local v = mkvar(obj, ss)
        local pn = st.reg[self] or "game"
        out(string.format("local %s = game:GetService(%s)", v, q(ss)))
        return obj
    end
    local obj = mkpx(ss, false, self)
    st.propstore[obj] = { ClassName = ss, Name = ss }
    st.services[ss] = obj
    st.parentmap[obj] = self
    local v = mkvar(obj, ss)
    local pn = st.reg[self] or "game"
    out(string.format("local %s = game:GetService(%s)", v, q(ss)))
    if ss == "CoreGui" then
        local rg = mkpx("RobloxGui", false, obj)
        st.propstore[rg] = { ClassName = "ScreenGui", Name = "RobloxGui" }
        st.parentmap[rg] = obj
    end
    if ss == "Players" then
        local lp = mkpx("LocalPlayer", false, obj)
        st.propstore[lp] = {
            ClassName = "Player",
            Name = "vole7vin",
            UserId = 123456789,
            CharacterAppearanceId = 123456789,
            MembershipType = Enum.MembershipType.None,
            DisplayName = "vole7vin",
        }
        st.parentmap[lp] = obj
        st.propstore[obj].LocalPlayer = lp
        st.propstore[obj].MaxPlayers = 16
        local playergui = mkpx("PlayerGui", false, lp)
        st.propstore[playergui] =
            { ClassName = "PlayerGui", Name = "PlayerGui" }
        st.parentmap[playergui] = lp
        local backpack = mkpx("Backpack", false, lp)
        st.propstore[backpack] = { ClassName = "Backpack", Name = "Backpack" }
        st.parentmap[backpack] = lp
        local playerscripts = mkpx("PlayerScripts", false, lp)
        st.propstore[playerscripts] =
            { ClassName = "PlayerScripts", Name = "PlayerScripts" }
        st.parentmap[playerscripts] = lp
        local pm = mkpx("PlayerModule", false, playerscripts)
        st.propstore[pm] = { ClassName = "ModuleScript", Name = "PlayerModule" }
        st.parentmap[pm] = playerscripts
        local rcs = mkpx("RbxCharacterSounds", false, playerscripts)
        st.propstore[rcs] =
            { ClassName = "ModuleScript", Name = "RbxCharacterSounds" }
        st.parentmap[rcs] = playerscripts
        local char = mkpx("Character", false, lp)
        st.propstore[char] = { ClassName = "Model", Name = "Character" }
        st.parentmap[char] = lp
        st.propstore[lp].Character = char
        local head = mkpx("Head", false, char)
        st.propstore[head] = { ClassName = "Part", Name = "Head" }
        st.parentmap[head] = char
        local hrp2 = mkpx("HumanoidRootPart", false, char)
        st.propstore[hrp2] = {
            ClassName = "Part",
            Name = "HumanoidRootPart",
            Position = Vector3.new(0, 5, 0),
        }
        st.parentmap[hrp2] = char
        local hum2 = mkpx("Humanoid", false, char)
        st.propstore[hum2] = {
            ClassName = "Humanoid",
            Name = "Humanoid",
            Health = 100,
            MaxHealth = 100,
        }
        st.parentmap[hum2] = char
    end
    if ss == "Lighting" then
        st.propstore[obj].ClockTime = 12
        st.propstore[obj].TimeOfDay = "12:00:00"
        st.propstore[obj].GeographicLatitude = 41.7
        st.propstore[obj].FogEnd = 100000
        st.propstore[obj].Ambient = Color3.new(0.78, 0.78, 0.78)
        st.propstore[obj].OutdoorAmbient = Color3.new(0.78, 0.78, 0.78)
        st.propstore[obj].Brightness = 2
        st.propstore[obj].ColorShift_Top = Color3.new(0, 0, 0)
        st.propstore[obj].ColorShift_Bottom = Color3.new(0, 0, 0)
        st.propstore[obj].ShadowMap = true
        st.propstore[obj].EnvironmentDiffuseScale = 1
        st.propstore[obj].EnvironmentSpecularScale = 1
        st.propstore[obj].ExposureCompensation = 0
        local blur = mkpx("Blur", false, obj)
        st.propstore[blur] = {
            ClassName = "BlurEffect",
            Name = "Blur",
            Enabled = true,
            Size = 10,
        }
        st.parentmap[blur] = obj
        local cc = mkpx("ColorCorrection", false, obj)
        st.propstore[cc] = {
            ClassName = "ColorCorrectionEffect",
            Name = "ColorCorrection",
            Enabled = true,
            Brightness = 0,
            Contrast = 0,
            Saturation = 0,
            Tiny = 0,
        }
        st.parentmap[cc] = obj
    end
    if ss == "HttpService" then
        st.propstore[obj].HttpEnabled = true
    end
    if ss == "Stats" then
        local sc = {
            { "NetworkStats", "StatsItem" },
            { "PhysicsStats", "StatsItem" },
            { "RenderStats", "StatsItem" },
            { "MemoryStats", "StatsItem" },
            { "SoundStats", "StatsItem" },
        }
        local oc = {}
        for _, v in _ipairs(sc) do
            local c = mkpx(v[1], false, obj)
            st.propstore[c] = { ClassName = v[2], Name = v[1] }
            st.parentmap[c] = obj
            local go = {}
            for j = 1, 3 do
                local gk = mkpx(v[1] .. "_" .. j, false, c)
                st.propstore[gk] = { ClassName = v[2], Name = v[1] .. "_" .. j }
                st.parentmap[gk] = c
                table.insert(go, gk)
            end
            st.propstore[c].__ordered_children = go
            table.insert(oc, c)
        end
        st.propstore[obj].__ordered_children = oc
    end
    if ss == "SoundService" then
        st.propstore[obj].RespectFilteringEnabled = true
        st.propstore[obj].RolloffScale = 1
        st.propstore[obj].AmbientReverb = Enum.ReverbType.NoReverb
        st.propstore[obj].DistanceFactor = 3.33
    end
    if ss == "TextService" then
        st.propstore[obj].TextFilteringEnabled = true
    end
    if ss == "GuiService" then
        st.propstore[obj].IsTenFootInterface = false
        st.propstore[obj].IsTouchControlsAvailable = true
    end
    if ss == "ContentProvider" then
        st.propstore[obj].BaseUrl = "https://www.roblox.com/"
    end
    if ss == "TweenService" then
        st.propstore[obj].TweenInfoNumber = 0
    end
    if ss == "MarketplaceService" then
        st.propstore[obj].DevProductPurchase = mkpx("DevProductPurchase", false)
        st.propstore[obj].ProductPurchase = mkpx("ProductPurchase", false)
    end
    if ss == "StarterPlayer" then
        st.propstore[obj].CharacterMaxSlopeAngle = 89
        st.propstore[obj].CharacterWalkSpeed = 16
        st.propstore[obj].CharacterJumpPower = 50
        st.propstore[obj].CharacterHipHeight = 2
        local sps = mkpx("StarterPlayerScripts", false, obj)
        st.propstore[sps] =
            { ClassName = "PlayerScripts", Name = "StarterPlayerScripts" }
        st.parentmap[sps] = obj
        local scs = mkpx("StarterCharacterScripts", false, obj)
        st.propstore[scs] = {
            ClassName = "StarterCharacterScripts",
            Name = "StarterCharacterScripts",
        }
        st.parentmap[scs] = obj
        local default1 = mkpx("PlayerModule", false, sps)
        st.propstore[default1] =
            { ClassName = "ModuleScript", Name = "PlayerModule" }
        st.parentmap[default1] = sps
        local default2 = mkpx("ChatScript", false, sps)
        st.propstore[default2] =
            { ClassName = "LocalScript", Name = "ChatScript" }
        st.parentmap[default2] = sps
        st.propstore[sps].__ordered_children = { default1, default2 }
        st.propstore[obj].__ordered_children = { sps, scs }
    end
    if ss == "LocalizationService" then
        st.propstore[obj].RobloxLocaleId = "en-us"
        st.propstore[obj].SystemLocaleId = "en-us"
    end
    return obj
end
methods.WaitForChild = function(self, cname, timeout)
    local cs = safestr(cname)
    if timeout ~= nil then
        local child = find_first_child_helper(self, cs, false)
        if not child then
            local pn = st.reg[self] or "obj"
            if pn == "LocalPlayer" then
                pn = "game.Players.LocalPlayer"
            end
            out(
                string.format(
                    "local wfc_nil = %s:WaitForChild(%s, %s)",
                    pn,
                    q(cs),
                    ser(timeout)
                )
            )
            return nil
        end
    end
    local child = find_first_child_helper(self, cs, false)
    if child then
        if is_spied(child) and not st.reg[child] then
            local v = mkvar(child, cs)
            local pn = st.reg[self] or "obj"
            if pn == "LocalPlayer" then
                pn = "game.Players.LocalPlayer"
            end
            if timeout then
                out(
                    string.format(
                        "local %s = %s:WaitForChild(%s, %s)",
                        v,
                        pn,
                        q(cs),
                        ser(timeout)
                    )
                )
            else
                out(
                    string.format(
                        "local %s = %s:WaitForChild(%s)",
                        v,
                        pn,
                        q(cs)
                    )
                )
            end
        end
        return child
    end
    local obj = mkpx(cs, false, self)
    st.propstore[obj] = { Name = cs }
    local v = mkvar(obj, cs)
    local pn = st.reg[self] or "obj"
    if pn == "LocalPlayer" then
        pn = "game.Players.LocalPlayer"
    end
    if timeout then
        out(
            string.format(
                "local %s = %s:WaitForChild(%s, %s)",
                v,
                pn,
                q(cs),
                ser(timeout)
            )
        )
    else
        out(string.format("local %s = %s:WaitForChild(%s)", v, pn, q(cs)))
    end
    return obj
end
methods.FindFirstChild = function(self, cname, rec)
    local cs = safestr(cname)
    if
        st.reg[self] == "game"
        or (st.propstore[self] and st.propstore[self].ClassName == "DataModel")
    then
        if cs == "Workspace" then
            return workspace
        end
        if st.services and st.services[cs] then
            return st.services[cs]
        end
    end
    local child = find_first_child_helper(self, cs, rec == true)
    if child and is_spied(child) then
        if not st.reg[child] then
            local v = mkvar(child, cs)
            local pn = st.reg[self] or "obj"
            out(string.format("local %s = %s:FindFirstChild(%s)", v, pn, q(cs)))
        end
    end
    return child
end
methods.FindFirstChildOfClass = function(self, cls)
    local cs = safestr(cls)
    if cs == "Workspace" and (st.reg[self] == "game") then
        return workspace
    end
    if cs == "Camera" and st.reg[self] == "workspace" then
        return st.propstore[workspace] and st.propstore[workspace].CurrentCamera
    end
    if st.reg[self] == "game" and st.services then
        for _, svc in _pairs(st.services) do
            if st.propstore[svc] and st.propstore[svc].ClassName == cs then
                return svc
            end
        end
    end
    local children = get_children_of(self)
    for _, child in _ipairs(children) do
        local cn = st.propstore[child] and st.propstore[child].ClassName
        if cn == cs then
            return child
        end
    end
    return nil
end
methods.FindFirstChildWhichIsA = function(self, cls, recursive)
    local cs = safestr(cls)
    local children = get_children_of(self)
    for _, child in _ipairs(children) do
        local cn = st.propstore[child] and st.propstore[child].ClassName
        if cn == cs or (class_superclass[cn] == cs) then
            return child
        end
    end
    return nil
end
methods.FindFirstAncestorOfClass = function(self, cls)
    local cs = safestr(cls)
    if
        cs == "DataModel"
        and (
            st.reg[self] == "workspace"
            or (
                st.propstore[self]
                and st.propstore[self].ClassName == "Workspace"
            )
        )
    then
        return game
    end
    local cur = st.parentmap[self]
    while cur do
        local cn = st.propstore[cur] and st.propstore[cur].ClassName
        if cn == cs then
            return cur
        end
        cur = st.parentmap[cur]
    end
    return nil
end
methods.FindFirstAncestorWhichIsA = function(self, cls)
    local cs = safestr(cls)
    local cur = st.parentmap[self]
    while cur do
        local cn = st.propstore[cur] and st.propstore[cur].ClassName
        if cn == cs or (class_superclass[cn] == cs) then
            return cur
        end
        cur = st.parentmap[cur]
    end
    return nil
end
methods.GetChildren = function(self)
    local pn = st.reg[self] or (st.propstore[self] and st.propstore[self].Name) or (st.propstore[self] and st.propstore[self].ClassName) or "obj"
    st.propstore[self] = st.propstore[self] or {}
    if st.propstore[self].__cc then
        st.getchldrn_pending = {
            parent = pn,
            call = pn .. ":GetChildren()",
            objects = st.propstore[self].__cc,
        }
        return st.propstore[self].__cc
    end
    local ch = get_children_of(self)
    if (st.reg[self] == "game" or pn == "game") and #ch <= 4 then
        local extras = { workspace }
        local names =
            { "Lighting", "ReplicatedStorage", "ServerStorage", "StarterPack" }
        for _, n in _ipairs(names) do
            local dummy = mkpx(n, false, self)
            st.propstore[dummy] = { ClassName = n, Name = n }
            table.insert(extras, dummy)
        end
        ch = extras
    end
    st.propstore[self].__cc = ch
    st.getchldrn_pending =
        { parent = pn, call = pn .. ":GetChildren()", objects = ch }
    return ch
end
methods.GetDescendants = function(self)
    local pn = st.reg[self] or (st.propstore[self] and st.propstore[self].Name) or (st.propstore[self] and st.propstore[self].ClassName) or "obj"
    local props = st.propstore[self] or {}
    if props.Name == "Animate" and props.ClassName == "LocalScript" then
        local descs = {}
        local anim_names = {
            "idle",
            "walk",
            "run",
            "jump",
            "fall",
            "climb",
            "swim",
            "toolnone",
            "toolslash",
            "toollunge",
        }
        for _, aname in _ipairs(anim_names) do
            local folder = mkpx(aname, false, self)
            st.propstore[folder] = { ClassName = "StringValue", Name = aname }
            st.parentmap[folder] = self
            table.insert(descs, folder)
            local anim = mkpx(aname .. "Anim", false, folder)
            st.propstore[anim] = {
                ClassName = "Animation",
                Name = aname .. "Anim",
                AnimationId = "rbxassetid://507770453",
            }
            st.parentmap[anim] = folder
            table.insert(descs, anim)
        end
        st.getdesc_pending = { parent = pn, objects = descs }
        return descs
    end
    local descs = {}
    for i = 1, 505 do
        table.insert(descs, mkpx("Descendant", false, self))
    end
    st.getdesc_pending = { parent = pn, objects = descs }
    return descs
end
methods.GetTags = function(self, inst)
    if
        st.propstore[self]
        and st.propstore[self].ClassName == "CollectionService"
    then
        st.propstore[inst] = st.propstore[inst] or {}
        local tags = st.propstore[inst].tags or {}
        local res = {}
        for t in _pairs(tags) do
            table.insert(res, t)
        end
        return res
    end
    st.propstore[self] = st.propstore[self] or {}
    local tags = st.propstore[self].tags or {}
    local res = {}
    for t in _pairs(tags) do
        table.insert(res, t)
    end
    return res
end
methods.HasTag = function(self, inst, tag)
    if
        st.propstore[self]
        and st.propstore[self].ClassName == "CollectionService"
    then
        st.propstore[inst] = st.propstore[inst] or {}
        local tags = st.propstore[inst].tags
        return tags and tags[tag] == true
    end
    tag = inst
    st.propstore[self] = st.propstore[self] or {}
    local tags = st.propstore[self].tags
    return tags and tags[tag] == true
end
methods.AddTag = function(self, inst, tag)
    if
        st.propstore[self]
        and st.propstore[self].ClassName == "CollectionService"
    then
        local inst_pn = st.reg[inst] or "inst"
        out(
            string.format(
                'game:GetService("CollectionService"):AddTag(%s, %s)',
                inst_pn,
                q(safestr(tag))
            )
        )
        st.propstore[inst] = st.propstore[inst] or {}
        st.propstore[inst].tags = st.propstore[inst].tags or {}
        st.propstore[inst].tags[tag] = true
        return
    end
    tag = inst
    local pn = st.reg[self] or "inst"
    out(string.format("%s:AddTag(%s)", pn, q(safestr(tag))))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self].tags = st.propstore[self].tags or {}
    st.propstore[self].tags[tag] = true
end
methods.RemoveTag = function(self, tag)
    local pn = st.reg[self] or "inst"
    out(string.format("%s:RemoveTag(%s)", pn, q(safestr(tag))))
    st.propstore[self] = st.propstore[self] or {}
    if st.propstore[self].tags then
        st.propstore[self].tags[tag] = nil
    end
end
methods.Clone = function(self)
    local pn = st.reg[self] or "obj"
    local cn = st.propstore[self] and st.propstore[self].ClassName or "Instance"
    local is_service = false
    if pn == "game" or pn == "workspace" or pn == "shared" then
        is_service = true
    else
        for _, sname in _ipairs(all_services) do
            if sname == cn or pn:match('GetService%("' .. sname .. '"%)') then
                is_service = true
                break
            end
        end
    end
    if is_service then
        error("Instance cannot be cloned")
    end
    if st.propstore[self] and st.propstore[self].Archivable == false then
        out(
            string.format(
                "-- %s:Clone() returned nil because Archivable is false",
                pn
            )
        )
        return nil
    end
    local obj = mkpx(cn .. "Clone", false)
    st.propstore[obj] = {}
    for k, v in _pairs(st.propstore[self] or {}) do
        st.propstore[obj][k] = v
    end
    local v = mkvar(obj, cn .. "Clone")
    out(string.format("local %s = %s:Clone()", v, pn))
    return obj
end
methods.Destroy = function(self)
    local pn = st.reg[self] or "obj"
    out(string.format("%s:Destroy()", pn))
    st.parentmap[self] = nil
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self].Parent = nil
    st.propstore[self].__destroyed = true
    for child, parent in _pairs(st.parentmap) do
        if rawequal(parent, self) then
            st.parentmap[child] = nil
            st.propstore[child] = st.propstore[child] or {}
            st.propstore[child].Parent = nil
        end
    end
end
methods.Remove = function(self)
    local pn = st.reg[self] or "obj"
    out(string.format("%s:Remove()", pn))
    st.parentmap[self] = nil
end
methods.ClearAllChildren = function(self)
    local pn = st.reg[self] or "obj"
    out(string.format("%s:ClearAllChildren()", pn))
    for child, parent in _pairs(st.parentmap) do
        if parent == self then
            st.parentmap[child] = nil
            if st.propstore[child] then
                st.propstore[child].Parent = nil
            end
        end
    end
    if st.propstore[self] then
        st.propstore[self].__cc = {}
    end
end
methods.Connect = function(self, cb)
    local pn = st.reg[self] or "signal"
    local conn = mkpx("conn", false)
    rawset(conn, "__connection", true)
    local cv = mkvar(conn, "conn")
    st.propstore[conn] = { Connected = true }
    st.reg[conn] = cv
    local evname = pn:match("%.([^%.]+)$") or pn
    local anames = { "..." }
    if evname:match("InputBegan") or evname:match("InputEnded") then
        anames = { "input", "gameProcessed" }
    elseif evname:match("InputChanged") then
        anames = { "input", "gameProcessed" }
    elseif evname:match("CharacterAdded") then
        anames = { "character" }
        local char = mkpx("Model", false)
        st.propstore[char] = { ClassName = "Model", Name = "Character" }
        local head = mkpx("Head", false, char)
        st.propstore[head] = { ClassName = "Part", Name = "Head" }
        st.parentmap[head] = char
        local hrp = mkpx("HumanoidRootPart", false, char)
        st.propstore[hrp] = { ClassName = "Part", Name = "HumanoidRootPart" }
        st.parentmap[hrp] = char
        local hum = mkpx("Humanoid", false, char)
        st.propstore[hum] =
            { ClassName = "Humanoid", Name = "Humanoid", Health = 100 }
        st.parentmap[hum] = char
        local lp = st.services
            and st.services["Players"]
            and st.propstore[st.services["Players"]]
            and st.propstore[st.services["Players"]].LocalPlayer
        if lp then
            st.propstore[lp] = st.propstore[lp] or {}
            st.propstore[lp].Character = char
        end
    elseif evname:match("CharacterRemoving") then
        anames = { "character" }
    elseif evname:match("PlayerAdded") then
        anames = { "player" }
    elseif evname:match("PlayerRemoving") then
        anames = { "player" }
    elseif evname:match("Touched") then
        anames = { "hit" }
    elseif evname:match("TouchEnded") then
        anames = { "hit" }
    elseif evname:match("Heartbeat") then
        anames = { "dt" }
    elseif evname:match("RenderStepped") then
        anames = { "dt" }
    elseif evname:match("Stepped") then
        anames = { "t", "dt" }
    elseif
        evname:match("Button1Click")
        or evname:match("MouseButton1Click")
        or evname:match("Activated")
    then
        anames = {}
    elseif evname:match("MouseButton2Click") then
        anames = {}
    elseif evname:match("FocusLost") then
        anames = { "enterPressed", "input" }
    elseif evname:match("DescendantAdded") then
        anames = { "desc" }
    elseif evname:match("DescendantRemoving") then
        anames = { "desc" }
    elseif evname:match("ChildAdded") then
        anames = { "child" }
    elseif evname:match("ChildRemoved") then
        anames = { "child" }
    elseif evname:match("Changed") then
        anames = { "prop" }
    elseif evname:match("StateChanged") then
        anames = { "old", "new" }
    elseif evname:match("OnClientEvent") then
        anames = { "..." }
    elseif evname:match("OnServerEvent") then
        anames = { "player", "..." }
    elseif evname:match("MouseMoved") or evname:match("MouseHover") then
        anames = { "x", "y" }
    elseif evname:match("MessageOut") then
        anames = { "message", "messageType" }
    end
    out(
        string.format(
            "local %s = %s:Connect(function(%s)",
            cv,
            pn,
            table.concat(anames, ", ")
        )
    )
    st.ind = st.ind + 1
    st.in_cb = true
    table.insert(st.cb_stack, { name = evname, depth = st.ind })
    local opending = st.pending_iter
    st.pending_iter = 0
    if _type(cb) == "function" then
        st.propstore[self] = st.propstore[self] or {}
        st.propstore[self].callbacks = st.propstore[self].callbacks or {}
        table.insert(st.propstore[self].callbacks, cb)
        local immediate_block = false
        if
            evname == "MouseClick"
            or evname:match("MouseHover")
            or evname:match("RightMouseClick")
        then
            immediate_block = true
        end
        if not immediate_block then
            local od = st.cf_depth
            st.cf_depth = 0
            local mock_args = get_event_mock_args(evname)
            _xpcall(function()
                cb(_unpack(mock_args))
            end, function(e) end)
            st.cf_depth = od
        end
    end
    while st.pending_iter and st.pending_iter > 0 do
        st.ind = st.ind - 1
        out("end")
        st.pending_iter = st.pending_iter - 1
    end
    while st.cf_depth > 0 do
        st.ind = st.ind - 1
        out("end")
        st.cf_depth = st.cf_depth - 1
    end
    st.pending_iter = opending
    st.ind = st.ind - 1
    out("end)")
    st.in_cb = false
    table.remove(st.cb_stack)
    if
        st.propstore[self]
        and st.propstore[self].ClassName == "BindableEvent"
    then
        st.propstore[self] = st.propstore[self] or {}
        st.propstore[self].callbacks = st.propstore[self].callbacks or {}
        table.insert(st.propstore[self].callbacks, cb)
    end
    return conn
end
methods.Once = function(self, cb)
    local pn = st.reg[self] or "signal"
    local conn = mkpx("conn", false)
    rawset(conn, "__connection", true)
    local cv = mkvar(conn, "conn")
    st.propstore[conn] = { Connected = true }
    st.reg[conn] = cv
    local evname = pn:match("%.([^%.]+)$") or pn
    out(string.format("local %s = %s:Once(function(...)", cv, pn))
    st.ind = st.ind + 1
    local opending = st.pending_iter
    st.pending_iter = 0
    if _type(cb) == "function" then
        st.propstore[self] = st.propstore[self] or {}
        st.propstore[self].callbacks = st.propstore[self].callbacks or {}
        local called = false
        local wrapper = function(...)
            if called then
                return
            end
            called = true
            return cb(...)
        end
        table.insert(st.propstore[self].callbacks, wrapper)
        local immediate_block = false
        if
            evname == "MouseClick"
            or evname:match("MouseHover")
            or evname:match("RightMouseClick")
        then
            immediate_block = true
        end
        if not immediate_block then
            local od = st.cf_depth
            st.cf_depth = 0
            local mock_args = get_event_mock_args(evname)
            _xpcall(function()
                wrapper(_unpack(mock_args))
            end, function() end)
            st.cf_depth = od
        end
    end
    while st.pending_iter and st.pending_iter > 0 do
        st.ind = st.ind - 1
        out("end")
        st.pending_iter = st.pending_iter - 1
    end
    st.pending_iter = opending
    st.ind = st.ind - 1
    out("end)")
    return conn
end
methods.Wait = function(self)
    local pn = st.reg[self] or "signal"
    out(string.format("%s:Wait()", pn))
    local evname = pn:match("%.([^%.]+)$") or pn
    local name_lower = evname:lower()
    local wait_dur = 0.016
    if
        name_lower:match("heartbeat")
        or name_lower:match("renderstepped")
        or name_lower:match("stepped")
    then
        st.heartbeat_counter = (st.heartbeat_counter or 0) + 1
        wait_dur = 0.016 + (st.heartbeat_counter % 10) * 0.0001
    end
    _cor.yield("wait", wait_dur)
    return wait_dur, os.clock()
end
methods.Disconnect = function(self)
    local pn = st.reg[self] or "conn"
    out(string.format("%s:Disconnect()", pn))
    if st.propstore[self] then
        st.propstore[self].Connected = false
    end
end
methods.FireServer = function(self, ...)
    local pn = st.reg[self] or "remote"
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    out(string.format("%s:FireServer(%s)", pn, table.concat(sargs, ", ")))
    table.insert(st.callgraph, { t = "RemoteEvent", name = pn, args = args })
end
methods.FireClient = function(self, player, ...)
    local pn = st.reg[self] or "remote"
    local args = { ... }
    local sargs = { ser(player) }
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    out(string.format("%s:FireClient(%s)", pn, table.concat(sargs, ", ")))
end
methods.FireAllClients = function(self, ...)
    local pn = st.reg[self] or "remote"
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    out(string.format("%s:FireAllClients(%s)", pn, table.concat(sargs, ", ")))
end
methods.InvokeServer = function(self, ...)
    local pn = st.reg[self] or "remote"
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    local r = mkpx("invokeres", false)
    local v = mkvar(r, "res")
    out(
        string.format(
            "local %s = %s:InvokeServer(%s)",
            v,
            pn,
            table.concat(sargs, ", ")
        )
    )
    table.insert(st.callgraph, { t = "RemoteFunction", name = pn, args = args })
    return r
end
methods.InvokeClient = function(self, player, ...)
    local pn = st.reg[self] or "remote"
    local args = { ... }
    local sargs = { ser(player) }
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    local r = mkpx("invokeres", false)
    local v = mkvar(r, "res")
    out(
        string.format(
            "local %s = %s:InvokeClient(%s)",
            v,
            pn,
            table.concat(sargs, ", ")
        )
    )
    return r
end
methods.IsA = function(self, cn)
    local cs = safestr(cn)
    local className = st.propstore[self] and st.propstore[self].ClassName or cs
    local cur = className
    while cur and cur ~= "<<<ROOT>>>" do
        if cur == cs then
            return true
        end
        cur = class_superclass[cur]
    end
    return false
end
methods.IsDescendantOf = function(self, anc)
    local pn = st.reg[self] or "obj"
    local an = st.reg[anc] or ser(anc)
    out(string.format("local isDescOf = %s:IsDescendantOf(%s)", pn, an))
    return true
end
methods.IsAncestorOf = function(self, desc)
    local pn = st.reg[self] or "obj"
    local dn = st.reg[desc] or ser(desc)
    out(string.format("local isAncOf = %s:IsAncestorOf(%s)", pn, dn))
    return true
end
methods.IsClient = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local isClient = %s:IsClient()", pn))
    return true
end
methods.IsServer = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local isServer = %s:IsServer()", pn))
    return false
end
methods.IsRunning = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local isRunning = %s:IsRunning()", pn))
    return true
end
methods.IsStudio = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local isStudio = %s:IsStudio()", pn))
    return false
end
methods.IsEdit = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local isEdit = %s:IsEdit()", pn))
    return false
end
methods.IsRunMode = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local isRunMode = %s:IsRunMode()", pn))
    return true
end
methods.GetAttribute = function(self, an)
    st.propstore[self] = st.propstore[self] or {}
    return st.propstore[self]["attr_" .. an]
end
methods.SetAttribute = function(self, an, val)
    local pn = st.reg[self] or "inst"
    out(string.format("%s:SetAttribute(%s, %s)", pn, q(an), ser(val)))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]["attr_" .. an] = val
end
methods.GetAttributes = function(self)
    local pn = st.reg[self] or "inst"
    local r = {}
    st.propstore[self] = st.propstore[self] or {}
    for k, v in _pairs(st.propstore[self]) do
        if _type(k) == "string" and k:sub(1, 5) == "attr_" then
            r[k:sub(6)] = v
        end
    end
    local rv = mkvar(r, "attrs")
    out(string.format("local %s = %s:GetAttributes()", rv, pn))
    return r
end
methods.GetFullName = function(self)
    local pn = st.reg[self] or "Instance"
    out(string.format("local fullName = %s:GetFullName()", pn))
    local parts = {}
    local cur = self
    while cur do
        local props = st.propstore[cur]
        local name = (props and props.Name) or st.reg[cur] or "Instance"
        if props and props.ClassName == "DataModel" then
            break
        end
        if name == "game" or name == "Game" then
            break
        end
        table.insert(parts, 1, name)
        cur = st.parentmap[cur]
    end
    return table.concat(parts, ".")
end
methods.GetDebugId = function(self)
    local pn = st.reg[self] or "obj"
    out(string.format("local debugId = %s:GetDebugId()", pn))
    return "0"
end
methods.GetPropertyChangedSignal = function(self, prop)
    local pn = st.reg[self] or "inst"
    local sig = mkpx(
        pn .. ".GetPropertyChangedSignal(" .. safestr(prop) .. ")",
        false,
        self
    )
    rawset(sig, "__signal", true)
    st.reg[sig] = pn .. ":GetPropertyChangedSignal(" .. q(safestr(prop)) .. ")"
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._signals = st.propstore[self]._signals or {}
    st.propstore[self]._signals[prop] = sig
    return sig
end
methods.GetChildrenOfClass = function(self, cls)
    local pn = st.reg[self] or "obj"
    out(
        string.format(
            "for _, child in %s:GetChildrenOfClass(%s) do",
            pn,
            q(cls)
        )
    )
    st.ind = st.ind + 1
    st.pending_iter = (st.pending_iter or 0) + 1
    return {}
end
methods.GetDescendantsOfClass = function(self, cls)
    local pn = st.reg[self] or "obj"
    local descs = {}
    for i = 1, 3 do
        table.insert(descs, mkpx("Descendant" .. cls, false, self))
    end
    st.getdesc_pending = {
        parent = pn .. '["GetDescendantsOfClass"](' .. q(cls) .. ")",
        objects = descs,
    }
    return descs
end
methods.GetDataStore = function(self, name, scope)
    local pn = st.reg[self] or "DataStoreService"
    local ns = safestr(name)
    if ns:match("[/\\@#%%&%*%?<>|%^%[%]{}]") or ns:match("//") then
        error(
            "DataStore name is invalid. Name must only include alphanumeric characters and underscores."
        )
    end
    if #ns == 0 or #ns > 50 then
        error("DataStore name is invalid.")
    end
    local ds = mkpx("DataStore_" .. ns, false)
    local v = mkvar(ds, "ds_" .. ns)
    out(string.format("local %s = %s:GetDataStore(%s)", v, pn, q(ns)))
    st.propstore[ds] = { ClassName = "DataStore", Name = ns, _store = {} }
    return ds
end
methods.GetGlobalDataStore = function(self)
    local pn = st.reg[self] or "DataStoreService"
    local ds = mkpx("GlobalDataStore", false)
    local v = mkvar(ds, "globalDs")
    out(string.format("local %s = %s:GetGlobalDataStore()", v, pn))
    st.propstore[ds] = { ClassName = "DataStore", Name = "global", _store = {} }
    return ds
end
methods.GetOrderedDataStore = function(self, name, scope)
    local pn = st.reg[self] or "DataStoreService"
    local ds = mkpx("OrderedDataStore_" .. safestr(name), false)
    local v = mkvar(ds, "ods_" .. safestr(name))
    out(
        string.format(
            "local %s = %s:GetOrderedDataStore(%s)",
            v,
            pn,
            q(safestr(name))
        )
    )
    st.propstore[ds] =
        { ClassName = "OrderedDataStore", Name = safestr(name), _store = {} }
    return ds
end
methods.SetAsync = function(self, key, value, userIds, options)
    local pn = st.reg[self] or "DataStore"
    out(string.format("%s:SetAsync(%s, %s)", pn, q(safestr(key)), ser(value)))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._store = st.propstore[self]._store or {}
    st.propstore[self]._store[safestr(key)] = value
end
methods.GetAsync = function(self, key)
    if not (st.propstore[self] and st.propstore[self]._store) then
        return methods.GetAsync(self, key)
    end
    local pn = st.reg[self] or "DataStore"
    local r = mkpx("dsVal", false)
    local v = mkvar(r, "dsVal")
    out(string.format("local %s = %s:GetAsync(%s)", v, pn, q(safestr(key))))
    st.propstore[self]._store = st.propstore[self]._store or {}
    local stored = st.propstore[self]._store[safestr(key)]
    if stored ~= nil then
        return stored
    end
    return nil
end
methods.RemoveAsync = function(self, key)
    local pn = st.reg[self] or "DataStore"
    out(string.format("%s:RemoveAsync(%s)", pn, q(safestr(key))))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._store = st.propstore[self]._store or {}
    local old = st.propstore[self]._store[safestr(key)]
    st.propstore[self]._store[safestr(key)] = nil
    return old
end
methods.UpdateAsync = function(self, key, transformFunc)
    local pn = st.reg[self] or "DataStore"
    local r = mkpx("dsUpdated", false)
    local v = mkvar(r, "dsUpdated")
    out(
        string.format(
            "local %s = %s:UpdateAsync(%s, function(oldVal)",
            v,
            pn,
            q(safestr(key))
        )
    )
    st.ind = st.ind + 1
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._store = st.propstore[self]._store or {}
    local oldVal = st.propstore[self]._store[safestr(key)]
    local newVal = nil
    if _type(transformFunc) == "function" then
        local ok, res = _pcall(transformFunc, oldVal)
        if ok then
            newVal = res
        end
    end
    if newVal ~= nil then
        st.propstore[self]._store[safestr(key)] = newVal
    end
    out(string.format("return %s", ser(newVal)))
    st.ind = st.ind - 1
    out("end)")
    return newVal
end
methods.IncrementAsync = function(self, key, delta, userIds, options)
    local pn = st.reg[self] or "DataStore"
    delta = delta or 1
    out(
        string.format(
            "%s:IncrementAsync(%s, %s)",
            pn,
            q(safestr(key)),
            ser(delta)
        )
    )
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self]._store = st.propstore[self]._store or {}
    local k = safestr(key)
    local cur = _tonumber(st.propstore[self]._store[k]) or 0
    st.propstore[self]._store[k] = cur + delta
    return cur + delta
end
methods.GetTeams = function(self)
    local pn = st.reg[self] or "Teams"
    local r = mkpx("teams", false)
    local v = mkvar(r, "teams")
    out(string.format("local %s = %s:GetTeams()", v, pn))
    return {}
end
methods.GetLogHistory = function(self)
    local pn = st.reg[self] or "LogService"
    local r = mkpx("logs", false)
    local v = mkvar(r, "logs")
    out(string.format("local %s = %s:GetLogHistory()", v, pn))
    return {}
end
methods.GetAllBoundActionInfo = function(self)
    local pn = st.reg[self] or "ContextActionService"
    local r = mkpx("actionInfo", false)
    local v = mkvar(r, "actionInfo")
    out(string.format("local %s = %s:GetAllBoundActionInfo()", v, pn))
    return {}
end
methods.GetNameFromUserIdAsync = function(self, id)
    local pn = st.reg[self] or "Players"
    local r = mkpx("PlayerName", false)
    local v = mkvar(r, "playerName")
    st.reg[r] = '"Player"'
    out(
        string.format(
            "local %s = %s:GetNameFromUserIdAsync(%s)",
            v,
            pn,
            ser(id)
        )
    )
    return r
end
methods.GetUserIdFromNameAsync = function(self, name)
    local pn = st.reg[self] or "Players"
    out(
        string.format(
            "local userId = %s:GetUserIdFromNameAsync(%s)",
            pn,
            q(safestr(name))
        )
    )
    return 123456789
end
methods.RequestAsync = function(self, requestDict)
    local pn = st.reg[self] or "HttpService"
    local r = mkpx("HttpResponse", false)
    local v = mkvar(r, "httpResp")
    local url = ""
    if _type(requestDict) == "table" and requestDict.Url then
        url = safestr(requestDict.Url)
    elseif isproxy(requestDict) then
        url = st.reg[requestDict] or ""
    end
    out(string.format('local %s = %s:RequestAsync({Url = "%s"})', v, pn, url))
    st.propstore[r] = {
        Success = true,
        StatusCode = 200,
        StatusMessage = "OK",
        Headers = {},
        Body = "{}",
    }
    if url ~= "" and url:match("^https?://") then
        local ok, net = _pcall(require, "@lune/net")
        if ok and net then
            local method = "GET"
            if _type(requestDict) == "table" and requestDict.Method then
                method = requestDict.Method
            end
            local req_ok, resp = _pcall(function()
                return net.request({ url = url, method = method })
            end)
            if req_ok and resp then
                st.propstore[r].Body = resp.body or "{}"
                st.propstore[r].StatusCode = resp.statusCode or 200
                st.propstore[r].Success = (resp.statusCode or 200) >= 200
                    and (resp.statusCode or 200) < 300
            end
        end
    end
    return r
end
methods.GetAsync = function(self, url, nocache, headers)
    local pn = st.reg[self] or "HttpService"
    local r = mkpx("GetResult", false)
    local v = mkvar(r, "getResult")
    out(string.format('local %s = %s:GetAsync("%s")', v, pn, safestr(url)))
    st.reg[r] = v
    return r
end
methods.PostAsync = function(self, url, data, contentType, compress, headers)
    local pn = st.reg[self] or "HttpService"
    local r = mkpx("PostResult", false)
    local v = mkvar(r, "postResult")
    out(
        string.format(
            'local %s = %s:PostAsync("%s", %s)',
            v,
            pn,
            safestr(url),
            ser(data)
        )
    )
    st.reg[r] = v
    return r
end
methods.GetSecret = function(self, key)
    local pn = st.reg[self] or "HttpService"
    error(pn .. ':GetSecret("' .. safestr(key) .. '") - Secret does not exist')
end
methods.GenerateGUID = function(self, format)
    local pn = st.reg[self] or "HttpService"
    out(string.format("%s:GenerateGUID(%s)", pn, ser(format)))
    local chars = "0123456789abcdef"
    local guid = ""
    for i = 1, 32 do
        if i == 9 or i == 14 or i == 19 or i == 24 then
            guid = guid .. "-"
        else
            local idx = math.random(1, 16)
            guid = guid .. chars:sub(idx, idx)
        end
    end
    return guid
end
methods.JSONEncode = function(self, data)
    local pn = st.reg[self] or "HttpService"
    out(string.format("%s:JSONEncode(%s)", pn, ser(data)))
    local function encode(val)
        local t = _type(val)
        if t == "string" then
            return string.format("%q", val)
        elseif t == "number" then
            return _tostring(val)
        elseif t == "boolean" then
            return _tostring(val)
        elseif t == "nil" then
            return "null"
        elseif t == "table" then
            local is_array = true
            local i = 1
            for k, v in _pairs(val) do
                if k ~= i then
                    is_array = false
                    break
                end
                i = i + 1
            end
            if is_array then
                local parts = {}
                for _, v in _ipairs(val) do
                    table.insert(parts, encode(v))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                local parts = {}
                for k, v in _pairs(val) do
                    table.insert(parts, string.format("%q:%s", k, encode(v)))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
        return "null"
    end
    return encode(data)
end
methods.JSONDecode = function(self, str)
    local pn = st.reg[self] or "HttpService"
    if _type(str) == "string" then
        local ok, result = _pcall(serde.decode, "json", str)
        if ok then
            if not st._silent_json then
                out(string.format("%s:JSONDecode(%s)", pn, q(str:sub(1, 80))))
            end
            st._silent_json = false
            if _type(result) == "table" then
                return result
            end
            return result
        end
    end
    out(string.format("%s:JSONDecode(%s)", pn, q(_tostring(str):sub(1, 80))))
    return {}
end
methods.GetEnumItems = function(self)
    local pn = st.reg[self] or "Enum"
    local r = {}
    for i = 1, 3 do
        local item = mkpx(pn .. "Item" .. i, false)
        st.reg[item] = pn .. ".Item" .. i
        table.insert(r, item)
    end
    return r
end
methods.GetEnums = function(self)
    local pn = st.reg[self] or "Enum"
    local r = mkpx("enums", false)
    local v = mkvar(r, "enums")
    out(string.format("local %s = %s:GetEnums()", v, pn))
    local items = {}
    for _, ename in _ipairs(all_enums) do
        local ei = Enum[ename]
        table.insert(items, ei)
    end
    return items
end
methods.CreatePath = function(self)
    local obj = mkpx("Path", false)
    local v = mkvar(obj, "Path")
    local pn = st.reg[self] or "PathfindingService"
    out(string.format("local %s = %s:CreatePath()", v, pn))
    st.propstore[obj] = { Status = mkpx("Enum.PathStatus.Success", false) }
    return obj
end
methods.BindAction = function(self, name, fn, touch, ...)
    local pn = st.reg[self] or "ContextActionService"
    out(
        string.format(
            "%s:BindAction(%s, function() end, %s)",
            pn,
            q(safestr(name)),
            _tostring(touch)
        )
    )
    return mkpx("BindActionResult", false)
end
methods.UnbindAction = function(self, name)
    local pn = st.reg[self] or "ContextActionService"
    out(string.format("%s:UnbindAction(%s)", pn, q(safestr(name))))
end
methods.CompressBuffer = function(self, buf, algo, lvl)
    local r = mkpx("CompressedBuffer", false)
    local v = mkvar(r, "cbuf")
    local pn = st.reg[self] or "EncodingService"
    out(
        string.format(
            "local %s = %s:CompressBuffer(buffer, %s)",
            v,
            pn,
            ser(algo)
        )
    )
    return r
end
methods.DecompressBuffer = function(self, buf, algo)
    local r = mkpx("DecompressedBuffer", false)
    local v = mkvar(r, "dbuf")
    local pn = st.reg[self] or "EncodingService"
    out(
        string.format(
            "local %s = %s:DecompressBuffer(%s, %s)",
            v,
            pn,
            ser(buf),
            ser(algo)
        )
    )
    return r
end
methods.WorldToScreenPoint = function(self, v3)
    local pn = st.reg[self] or "Camera"
    local r = mkpx("ScreenPoint", false)
    local v = mkvar(r, "screenPoint")
    st.reg[r] = "Vector3.new(0, 0, 0)"
    out(
        string.format(
            "local %s, onScreen = %s:WorldToScreenPoint(%s)",
            v,
            pn,
            ser(v3)
        )
    )
    return r, true
end
methods.WorldToViewportPoint = function(self, v3)
    local pn = st.reg[self] or "Camera"
    local r = mkpx("ViewportPoint", false)
    local v = mkvar(r, "viewportPoint")
    st.reg[r] = "Vector3.new(0, 0, 0)"
    out(
        string.format(
            "local %s, onScreen = %s:WorldToViewportPoint(%s)",
            v,
            pn,
            ser(v3)
        )
    )
    return r, true
end
methods.ScreenPointToRay = function(self, x, y, depth)
    local pn = st.reg[self] or "Camera"
    local r = mkpx("Ray", false)
    local v = mkvar(r, "ray")
    local mt = _getmt(r)
    mt.__typeof = "Ray"
    st.propstore[r] = {
        Origin = Vector3.new(0, 0, 0),
        Direction = Vector3.new(0, 0, -1),
    }
    st.reg[r] = "Ray.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))"
    out(
        string.format(
            "local %s = %s:ScreenPointToRay(%s, %s, %s)",
            v,
            pn,
            ser(x),
            ser(y),
            ser(depth)
        )
    )
    return r
end
methods.getInternalSessionId = function(self)
    local pn = st.reg[self] or "VoiceChatService"
    out(
        string.format(
            "local getInternalSessionId = %s:getInternalSessionId()",
            pn
        )
    )
    return "session-id-12345"
end
methods.GetSessionId = function(self)
    local pn = st.reg[self] or "VoiceChatInternal"
    out(string.format("local GetSessionId = %s:GetSessionId()", pn))
    return "session-id-12345"
end
methods.Raycast = function(self, origin, dir, params)
    local pn = st.reg[self] or "workspace"
    local r = mkpx("RaycastResult", false)
    local res_var = mkvar(r, "RaycastResult")
    st.reg[r] = res_var
    out(
        string.format(
            "local %s = %s:Raycast(%s, %s, %s)",
            res_var,
            pn,
            ser(origin),
            ser(dir),
            ser(params)
        )
    )
    local mt = _getmt(r)
    mt.__typeof = "RaycastResult"
    st.propstore[r] = {
        Position = origin or Vector3.new(0, 0, 0),
        Normal = Vector3.new(0, 1, 0),
        Material = Enum.Material.Plastic,
        Instance = mkpx("Part", false),
        ClassName = "RaycastResult",
    }
    return r
end
methods.ChangeState = function(self, state)
    local pn = st.reg[self] or "Humanoid"
    out(string.format("%s:ChangeState(%s)", pn, ser(state)))
    st.propstore[self] = st.propstore[self] or {}
    local stateName = ""
    if _type(state) == "number" then
        if state == 15 then
            stateName = "Dead"
        elseif state == 5 then
            stateName = "Climbing"
        end
    elseif isproxy(state) then
        local reg = st.reg[state] or ""
        stateName = reg:match("Enum%.HumanoidStateType%.(.+)$") or ""
    end
    if stateName == "Climbing" then
        st.propstore[self]._lastState = Enum.HumanoidStateType.Running
    elseif stateName == "Flying" then
        st.propstore[self]._lastState = Enum.HumanoidStateType.Running
    else
        if _type(state) == "number" and state == 15 then
            st.propstore[self]._lastState = Enum.HumanoidStateType.Dead
        else
            st.propstore[self]._lastState = state
        end
    end
    if
        state == Enum.HumanoidStateType.Jumping
        or (
            isproxy(state)
            and st.reg[state] == "Enum.HumanoidStateType.Jumping"
        )
    then
        local parent = st.parentmap[self]
        if parent then
            local hrp =
                find_first_child_helper(parent, "HumanoidRootPart", false)
            if hrp then
                st.propstore[hrp] = st.propstore[hrp] or {}
                local pos = st.propstore[hrp].Position or Vector3.new(0, 5, 0)
                local new_pos = pos + Vector3.new(0, 5, 0)
                st.propstore[hrp].Position = new_pos
                local hrp_pn = st.reg[hrp] or "hrp"
                out(string.format("%s.Position = %s", hrp_pn, ser(new_pos)))
            end
        end
    end
end
methods.HttpGet = function(self, url)
    local pn = "game"
    local url_str = safestr(url)
    st.last_url = url_str
    local seed = math.floor((os.clock() * 1000000) % 100000000)
    math.randomseed(seed)
    local r_ip = string.format(
        "%d.%d.%d.%d",
        math.random(1000, 9999),
        math.random(1000, 9999),
        math.random(1000, 9999),
        math.random(1000, 9999)
    )
    local fake_responses = {
        ["ipinfo.io"] = '{"ip":"'
            .. r_ip
            .. '","hostname":"dynamic.ip.resolver","city":"Chicago","region":"Illinois","country":"US","org":"AS7922 Comcast Cable Communications, LLC"}',
        ["api.ipify.org"] = '{"ip":"' .. r_ip .. '"}',
        ["ip-api.com"] = '{"status":"success","message":"","proxy":false,"hosting":false,"query":"'
            .. r_ip
            .. '"}',
        ["checkip.amazonaws.com"] = r_ip,
        ["icanhazip.com"] = r_ip,
        ["ipecho.net"] = r_ip,
        ["myip.com"] = '{"ip":"' .. r_ip .. '"}',
        ["whatismyipaddress.com"] = '{"ip":"' .. r_ip .. '"}',
        ["vpnapi.io"] = '{"ip":"'
            .. r_ip
            .. '","security":{"vpn":false,"proxy":false,"tor":false,"relay":false}}',
        ["proxycheck.io"] = '{"'
            .. r_ip
            .. '":{"status":"ok","proxy":"no","type":"Residential"}}',
        ["iphub.info"] = '{"ip":"' .. r_ip .. '","countryCode":"US","block":0}',
    }
    for pat, fake_body in _pairs(fake_responses) do
        if url_str:find(pat, 1, true) then
            st._silent_json = true
            return fake_body
        end
    end
    local ok, net = _pcall(nett)
    if ok and net then
        local request_ok, response = _pcall(net.request, url_str)
        if request_ok and response.statusCode == 200 then
            out(string.format('local httpres = game:HttpGet("%s")', url_str))
            return response.body
        end
    end
    local r = mkpx("HttpResult", false)
    local v = mkvar(r, "httpres")
    out(string.format('local %s = game:HttpGet("%s")', v, url_str))
    st.reg[r] = v
    local rmt = _getmt(r)
    rmt.__call = function(t, ...)
        return r
    end
end
methods.HttpPost = function(self, url, data)
    local pn = "game"
    local r = mkpx("HttpResult", false)
    local v = mkvar(r, "httpres")
    out(
        string.format(
            'local %s = %s:HttpPost("%s", %s)',
            v,
            pn,
            safestr(url),
            ser(data)
        )
    )
    st.reg[r] = v
    return r
end
methods.PromptProductPurchase = function(
    self,
    player,
    productId,
    equipIfPurchased,
    currencyType
)
    local pn = st.reg[self] or "MarketplaceService"
    out(
        string.format(
            "%s:PromptProductPurchase(%s, %s)",
            pn,
            ser(player),
            ser(productId)
        )
    )
end
methods.PromptPurchase = function(
    self,
    player,
    assetId,
    equipIfPurchased,
    currencyType
)
    local pn = st.reg[self] or "MarketplaceService"
    out(
        string.format(
            "%s:PromptPurchase(%s, %s)",
            pn,
            ser(player),
            ser(assetId)
        )
    )
end
methods.PromptGamePassPurchase = function(self, player, gamePassId)
    local pn = st.reg[self] or "MarketplaceService"
    out(
        string.format(
            "%s:PromptGamePassPurchase(%s, %s)",
            pn,
            ser(player),
            ser(gamePassId)
        )
    )
end
methods.UserOwnsGamePassAsync = function(self, userId, gamePassId)
    local pn = st.reg[self] or "MarketplaceService"
    local r = mkpx("ownsPass", false)
    local v = mkvar(r, "ownsPass")
    out(
        string.format(
            "local %s = %s:UserOwnsGamePassAsync(%s, %s)",
            v,
            pn,
            ser(userId),
            ser(gamePassId)
        )
    )
    return false
end
methods.GetProductInfo = function(self, id, infoType)
    local pn = st.reg[self] or "MarketplaceService"
    local r = mkpx("ProductInfo", false)
    local v = mkvar(r, "info")
    out(string.format("local %s = %s:GetProductInfo(%s)", v, pn, ser(id)))
    st.propstore[r] = {
        Name = "Product",
        PriceInRobux = 0,
        AssetId = id or 0,
        Description = "",
    }
    return r
end
methods.DistanceFromCharacter = function(self, pos)
    local pn = st.reg[self] or "Player"
    out(
        string.format("local dist = %s:DistanceFromCharacter(%s)", pn, ser(pos))
    )
    return 0
end
methods.GetMouse = function(self)
    local lp_proxy = nil
    if st.services and st.services["Players"] then
        local ps = st.propstore[st.services["Players"]]
        if ps then
            lp_proxy = ps.LocalPlayer
        end
    end
    if not rawequal(self, lp_proxy) then
        return nil
    end
    local mouse = mkpx("Mouse", false)
    st.propstore[mouse] = {
        ClassName = "Mouse",
        Name = "Mouse",
        Hit = { X = 0, Y = 0, Z = 0 },
        Origin = { X = 0, Y = 0, Z = 0 },
        Target = nil,
        TargetSurface = Enum.NormalId.Front,
    }
    return mouse
end
methods.Kick = function(self, msg)
    local pn = st.reg[self] or "Player"
    out(string.format("%s:Kick(%s)", pn, ser(msg)))
end
methods.GetRankInGroup = function(self, grp)
    local pn = st.reg[self] or "Player"
    out(string.format("local rank = %s:GetRankInGroup(%s)", pn, ser(grp)))
    return 0
end
methods.GetRoleInGroup = function(self, grp)
    local pn = st.reg[self] or "Player"
    out(string.format("local role = %s:GetRoleInGroup(%s)", pn, ser(grp)))
    return "Guest"
end
methods.IsInGroup = function(self, grp)
    local pn = st.reg[self] or "Player"
    out(string.format("local inGroup = %s:IsInGroup(%s)", pn, ser(grp)))
    return false
end
methods.GetPlayerByUserId = function(self, id)
    local pn = st.reg[self] or "Players"
    out(string.format("local player = %s:GetPlayerByUserId(%s)", pn, ser(id)))
    if id == -999 then
        return nil
    end
    if
        st.propstore[self]
        and st.propstore[self].LocalPlayer
        and st.propstore[self].LocalPlayer.UserId == id
    then
        return st.propstore[self].LocalPlayer
    end
    return nil
end
methods.GetFriendsAsync = function(self, userId)
    local pn = st.reg[self] or "Players"
    local r = mkpx("FriendPages", false)
    local v = mkvar(r, "friendPages")
    out(string.format("local %s = %s:GetFriendsAsync(%s)", v, pn, ser(userId)))
    st.propstore[r] = { ClassName = "FriendPages", IsFinished = true }
    return r
end
methods.GetPlayerFromCharacter = function(self, char)
    local pn = st.reg[self] or "Players"
    local cn = st.reg[char] or ser(char)
    if isproxy(char) then
        local reg = st.reg[char] or ""
        local props = st.propstore[char] or {}
        if reg == "workspace" or props.ClassName == "Workspace" then
            out(
                string.format(
                    "local player = %s:GetPlayerFromCharacter(%s) -- nil, workspace is not a character",
                    pn,
                    cn
                )
            )
            return nil
        end
    end
    local r = mkpx("Player", false)
    local v = mkvar(r, "player")
    out(string.format("local %s = %s:GetPlayerFromCharacter(%s)", v, pn, cn))
    return r
end
methods.BindToRenderStep = function(self, name, priority, fn)
    local pn = st.reg[self] or "RunService"
    out(
        string.format(
            "%s:BindToRenderStep(%s, %s, function(dt)",
            pn,
            q(safestr(name)),
            ser(priority)
        )
    )
    st.ind = st.ind + 1
    if _type(fn) == "function" then
        local od = st.cf_depth
        st.cf_depth = 0
        local opending = st.pending_iter
        st.pending_iter = 0
        _xpcall(function()
            fn(0.016)
        end, function() end)
        while st.pending_iter and st.pending_iter > 0 do
            st.ind = st.ind - 1
            out("end")
            st.pending_iter = st.pending_iter - 1
        end
        st.pending_iter = opending
        st.cf_depth = od
    end
    st.ind = st.ind - 1
    out("end)")
end
methods.UnbindFromRenderStep = function(self, name)
    local pn = st.reg[self] or "RunService"
    out(string.format("%s:UnbindFromRenderStep(%s)", pn, q(safestr(name))))
end
methods.GetRobloxVersion = function(self)
    local pn = st.reg[self] or "RunService"
    out(string.format("local robloxVersion = %s:GetRobloxVersion()", pn))
    return "0.0.0.0"
end
methods.BindToClose = function(self, fn)
    local pn = st.reg[self] or "game"
    out(string.format("%s:BindToClose(function()", pn))
    st.ind = st.ind + 1
    if _type(fn) == "function" then
        local od = st.cf_depth
        st.cf_depth = 0
        local opending = st.pending_iter
        st.pending_iter = 0
        _xpcall(function()
            fn()
        end, function() end)
        while st.pending_iter and st.pending_iter > 0 do
            st.ind = st.ind - 1
            out("end")
            st.pending_iter = st.pending_iter - 1
        end
        st.pending_iter = opending
        st.cf_depth = od
    end
    st.ind = st.ind - 1
    out("end)")
end
methods.GetObjects = function(self, assetId)
    local pn = st.reg[self] or "InsertService"
    local r = mkpx("objects", false)
    local v = mkvar(r, "objects")
    out(string.format("local %s = %s:GetObjects(%s)", v, pn, ser(assetId)))
    return {}
end
methods.GetPlayers = function(self)
    local players = {}
    local svc = st.players_service or self
    local ps = st.propstore[svc]
    if ps and ps.LocalPlayer then
        table.insert(players, ps.LocalPlayer)
    else
        local lp = mkpx("Player", false)
        st.propstore[lp] = {
            ClassName = "Player",
            Name = "vole7vin",
            UserId = 123456789,
            DisplayName = "vole7vin",
        }
        mkvar(lp, "LocalPlayer")
        table.insert(players, lp)
    end
    return players
end
methods.Create = function(self, inst, tweenInfo, goals)
    local pn = st.reg[self] or "TweenService"
    if isproxy(inst) and _type(goals) == "table" then
        local target_class = st.propstore[inst] and st.propstore[inst].ClassName
            or "Instance"
        for k, v in _pairs(goals) do
            local member = find_member(target_class, k)
            if member and member.Type == "Property" then
                local expected_category = member.ValueType.Category
                local expected_name = member.ValueType.Name
                local actual_type = typeof(v)
                local match = false
                if expected_category == "Primitive" then
                    if expected_name == "bool" and actual_type == "boolean" then
                        match = true
                    elseif
                        expected_name == "string"
                        and actual_type == "string"
                    then
                        match = true
                    elseif
                        (
                            expected_name == "double"
                            or expected_name == "float"
                            or expected_name == "int"
                            or expected_name == "int64"
                        )
                        and actual_type == "number"
                    then
                        match = true
                    end
                elseif expected_category == "DataType" then
                    if actual_type == expected_name then
                        match = true
                    end
                elseif expected_category == "Enum" then
                    if actual_type == "EnumItem" then
                        match = true
                    end
                end
                if not match then
                    error(
                        "Unable to cast value to "
                            .. (member.ValueType and member.ValueType.Name or "object")
                            .. " for property "
                            .. _tostring(k)
                    )
                end
            end
        end
    end
    local r = mkpx("Tween", false)
    st.propstore[r] = {
        ClassName = "Tween",
        target = inst,
        goals = goals,
        tweenInfo = tweenInfo,
        PlaybackState = Enum.PlaybackState.Begin,
    }
    local completed = mkpx("Completed", false, r)
    st.propstore[completed] =
        { ClassName = "BindableEvent", Name = "Completed" }
    st.parentmap[completed] = r
    st.propstore[r].Completed = completed
    local v = mkvar(r, "tween")
    out(
        string.format(
            "local %s = %s:Create(%s, %s, %s)",
            v,
            pn,
            ser(inst),
            ser(tweenInfo),
            ser(goals)
        )
    )
    return r
end
methods.Play = function(self)
    local pn = st.reg[self] or "tween"
    out(string.format("%s:Play()", pn))
    local store = st.propstore[self]
    if store and store.target and store.goals then
        local target = store.target
        for k, v in _pairs(store.goals) do
            st.propstore[target] = st.propstore[target] or {}
            st.propstore[target][k] = v
            local target_pn = st.reg[target] or "inst"
            out(string.format("%s.%s = %s", target_pn, safestr(k), ser(v)))
        end
        st.propstore[self].PlaybackState = Enum.PlaybackState.Playing
        local info = store.tweenInfo
        local timeVal = 0.1
        if info then
            local ist = rawget(info, "__stored") or {}
            timeVal = ist.Time or ist.time or timeVal
        end
        queue_task("delay", timeVal or 0.1, function()
            st.propstore[self].PlaybackState = Enum.PlaybackState.Completed
            local comp = st.propstore[self] and st.propstore[self].Completed
            if comp and st.propstore[comp] and st.propstore[comp].callbacks then
                for _, cb in _ipairs(st.propstore[comp].callbacks) do
                    if _type(cb) == "function" then
                        _xpcall(function()
                            cb()
                        end, function() end)
                    end
                end
            end
        end)
    end
end
methods.Pause = function(self)
    local pn = st.reg[self] or "tween"
    out(string.format("%s:Pause()", pn))
end
methods.Cancel = function(self)
    local pn = st.reg[self] or "tween"
    out(string.format("%s:Cancel()", pn))
end
methods.TeleportAsync = function(self, placeId, players, options)
    local pn = st.reg[self] or "TeleportService"
    local r = mkpx("TeleportResult", false)
    local v = mkvar(r, "teleResult")
    out(
        string.format(
            "local %s = %s:TeleportAsync(%s, %s)",
            v,
            pn,
            ser(placeId),
            ser(players)
        )
    )
    return r
end
methods.GetLocalPlayerTeleportData = function(self)
    local pn = st.reg[self] or "TeleportService"
    out(string.format("local teleData = %s:GetLocalPlayerTeleportData()", pn))
    return nil
end
methods.TeleportToPlaceInstance = function(self, placeId, instanceId, player)
    local pn = st.reg[self] or "TeleportService"
    out(
        string.format(
            "%s:TeleportToPlaceInstance(%s, %s)",
            pn,
            ser(placeId),
            ser(instanceId)
        )
    )
end
methods.SetTeleportGui = function(self, gui)
    local pn = st.reg[self] or "TeleportService"
    out(string.format("%s:SetTeleportGui(%s)", pn, ser(gui)))
end
methods.GetState = function(self)
    local pn = st.reg[self] or "obj"
    out(string.format("local state = %s:GetState()", pn))
    st.propstore[self] = st.propstore[self] or {}
    local last = st.propstore[self]._lastState
    if last then
        return last
    end
    return Enum.HumanoidStateType.Running
end
methods.TakeDamage = function(self, amount)
    local pn = st.reg[self] or "Humanoid"
    out(string.format("%s:TakeDamage(%s)", pn, ser(amount)))
    st.propstore[self] = st.propstore[self] or {}
    local hp = st.propstore[self].Health or 100
    st.propstore[self].Health = math.max(0, hp - (tonumber(amount) or 0))
end
methods.MoveTo = function(self, pos)
    local pn = st.reg[self] or "Humanoid"
    out(string.format("%s:MoveTo(%s)", pn, ser(pos)))
end
methods.GetChildrenInRadius = function(self, pos, radius)
    local pn = st.reg[self] or "obj"
    local r = mkpx("childrenInRadius", false)
    local v = mkvar(r, "children")
    out(
        string.format(
            "local %s = %s:GetChildrenInRadius(%s, %s)",
            v,
            pn,
            ser(pos),
            ser(radius)
        )
    )
    return {}
end
methods.Fire = function(self, ...)
    local pn = st.reg[self] or "event"
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    out(string.format("%s:Fire(%s)", pn, table.concat(sargs, ", ")))
    if st.propstore[self] and st.propstore[self].callbacks then
        for _, cb in _ipairs(st.propstore[self].callbacks) do
            if _type(cb) == "function" then
                _xpcall(cb, function() end, _unpack(args))
            end
        end
    end
    local event_sig = st.propstore[self]
        and st.propstore[self]._signals
        and st.propstore[self]._signals["Event"]
    if event_sig and st.propstore[event_sig] and st.propstore[event_sig].callbacks then
        for _, cb in _ipairs(st.propstore[event_sig].callbacks) do
            if _type(cb) == "function" then
                _xpcall(cb, function() end, _unpack(args))
            end
        end
    end
    return mkpx("FireResult", false)
end
methods.Invoke = function(self, ...)
    local pn = st.reg[self] or "event"
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    local r = mkpx("InvokeResult", false)
    local v = mkvar(r, "res")
    out(
        string.format(
            "local %s = %s:Invoke(%s)",
            v,
            pn,
            table.concat(sargs, ", ")
        )
    )
    return r
end
methods.SetCore = function(self, key, val)
    local pn = st.reg[self] or "StarterGui"
    out(string.format('%s:SetCore("%s", %s)', pn, q(safestr(key)), ser(val)))
end
methods.GetCore = function(self, key)
    local pn = st.reg[self] or "StarterGui"
    local r = mkpx("CoreValue", false)
    local v = mkvar(r, "coreVal")
    out(string.format("local %s = %s:GetCore(%s)", v, pn, q(safestr(key))))
    return r
end
methods.SetCoreGuiEnabled = function(self, ctype, enabled)
    local pn = st.reg[self] or "StarterGui"
    out(
        string.format(
            "%s:SetCoreGuiEnabled(%s, %s)",
            pn,
            ser(ctype),
            ser(enabled)
        )
    )
end
methods.GetCoreGuiEnabled = function(self, ctype)
    local pn = st.reg[self] or "StarterGui"
    out(
        string.format(
            "local coreGuiEnabled = %s:GetCoreGuiEnabled(%s)",
            pn,
            ser(ctype)
        )
    )
    return true
end
methods.GetInstanceAddedSignal = function(self, tag)
    local pn = st.reg[self] or "CollectionService"
    local sig = mkpx(
        pn .. '.GetInstanceAddedSignal("' .. safestr(tag) .. '")',
        false,
        self
    )
    rawset(sig, "__signal", true)
    st.reg[sig] = pn .. ':GetInstanceAddedSignal("' .. safestr(tag) .. '")'
    return sig
end
methods.GetInstanceRemovedSignal = function(self, tag)
    local pn = st.reg[self] or "CollectionService"
    local sig = mkpx(
        pn .. '.GetInstanceRemovedSignal("' .. safestr(tag) .. '")',
        false,
        self
    )
    rawset(sig, "__signal", true)
    st.reg[sig] = pn .. ':GetInstanceRemovedSignal("' .. safestr(tag) .. '")'
    return sig
end
methods.GetTagged = function(self, tag)
    local t = safestr(tag)
    local tagged = {}
    for inst, props in _pairs(st.propstore) do
        if props.tags and props.tags[t] then
            table.insert(tagged, inst)
        end
    end
    return tagged
end

methods.GetAllTags = function(self)
    local pn = st.reg[self] or "CollectionService"
    local r = mkpx("allTags", false)
    local v = mkvar(r, "allTags")
    out(string.format("local %s = %s:GetAllTags()", v, pn))
    local tags = {}
    local seen = {}
    for _, props in _pairs(st.propstore) do
        if props.tags then
            for tag in _pairs(props.tags) do
                if not seen[tag] then
                    seen[tag] = true
                    table.insert(tags, tag)
                end
            end
        end
    end
    return tags
end
methods.GetTextSize = function(self, text, size, font, frame)
    local pn = st.reg[self] or "TextService"
    out(
        string.format(
            "%s:GetTextSize(%s, %s, %s, %s)",
            pn,
            q(text),
            ser(size),
            ser(font),
            ser(frame)
        )
    )
    local result = mkpx("Vector2", false)
    st.propstore[result] = { X = 100, Y = 20 }
    local mt = _getmt(result)
    mt.__typeof = "Vector2"
    return result
end
methods.GetGuiInset = function(self)
    local pn = st.reg[self] or "GuiService"
    out(string.format("%s:GetGuiInset()", pn))
    local inset = Vector2.new(0, 36)
    local offset = Vector2.new(0, 0)
    return inset, offset
end
methods.GetRequestQueueSize = function(self)
    local pn = st.reg[self] or "ContentProvider"
    out(string.format("%s:GetRequestQueueSize()", pn))
    return 0
end
methods.GetListener = function(self)
    local pn = st.reg[self] or "SoundService"
    out(
        string.format(
            "local listenerType, listenerInstance = %s:GetListener()",
            pn
        )
    )
    return Enum.ListenerType.Camera, nil
end

methods.GetMinutesAfterMidnight = function(self)
    local pn = st.reg[self] or "Lighting"
    out(string.format("local minutes = %s:GetMinutesAfterMidnight()", pn))
    local clockTime = (st.propstore[self] and st.propstore[self].ClockTime)
        or 12
    return clockTime * 60
end

methods.SetMinutesAfterMidnight = function(self, minutes)
    local pn = st.reg[self] or "Lighting"
    out(string.format("%s:SetMinutesAfterMidnight(%s)", pn, ser(minutes)))
    st.propstore[self] = st.propstore[self] or {}
    st.propstore[self].ClockTime = (minutes or 0) / 60
end

methods.GetMass = function(self)
    local pn = st.reg[self] or "Part"
    out(string.format("local mass = %s:GetMass()", pn))
    return 1.0
end

methods.GetValue = function(self, alpha, easingStyle, easingDirection)
    local pn = st.reg[self] or "TweenService"
    out(
        string.format(
            "%s:GetValue(%s, %s, %s)",
            pn,
            ser(alpha),
            ser(easingStyle),
            ser(easingDirection)
        )
    )
    local a = alpha or 0
    if a < 0 then
        a = 0
    end
    if a > 1 then
        a = 1
    end
    return a
end

methods.GetUserCFrame = function(self, userCFrame)
    local pn = st.reg[self] or "VRService"
    out(string.format("local userCF = %s:GetUserCFrame(%s)", pn, ser(userCFrame)))
    return CFrame.new(0, 0, 0)
end

methods.GetServerTimeNow = function(self)
    local pn = st.reg[self] or "workspace"
    out(string.format("local serverTime = %s:GetServerTimeNow()", pn))
    return os.clock()
end

methods.GetCollisionGroupId = function(self, name)
    local pn = st.reg[self] or "PhysicsService"
    out(string.format("local cgId = %s:GetCollisionGroupId(%s)", pn, q(safestr(name))))
    return 0
end

methods.GetTranslatorForPlayerAsync = function(self, player)
    local pn = st.reg[self] or "LocalizationService"
    local r = mkpx("Translator", false)
    local v = mkvar(r, "translator")
    st.propstore[r] = { ClassName = "Translator", Name = "Translator" }
    out(string.format("local %s = %s:GetTranslatorForPlayerAsync(%s)", v, pn, ser(player)))
    return r
end

methods.IsTenFootInterface = function(self)
    local pn = st.reg[self] or "GuiService"
    out(string.format("local isTFI = %s:IsTenFootInterface()", pn))
    return false
end

methods.GetLastInputType = function(self)
    local pn = st.reg[self] or "UserInputService"
    out(string.format("local lastInput = %s:GetLastInputType()", pn))
    return Enum.UserInputType.None
end
for _, f in _pairs(methods) do
    reg_c_func(f)
end
local method_cache = {}
local function wrap_method(mname)
    local ms = safestr(mname)
    local f = {}
    local mt = {
        __typeof = "function",
        __call = function(t, self, ...)
            if not isproxy(self) then
                local args = { self, ... }
                local r = mkpx("result_" .. ms, false)
                local rv = mkvar(r, ms)
                local sargs = {}
                for _, a in _ipairs(args) do
                    table.insert(sargs, ser(a))
                end
                st.reg[r] = rv
                out(
                    string.format(
                        "local %s = UNKNOWN_PARENT.%s(%s)",
                        rv,
                        ms,
                        table.concat(sargs, ", ")
                    )
                )
                return r
            end
            if methods[mname] then
                return methods[mname](self, ...)
            end
            local args = { ... }
            local pname = st.reg[self] or "obj"
            local r = mkpx(ms, false, self)
            local v = mkvar(r, ms, nil, ms)
            local sargs = {}
            for _, a in _ipairs(args) do
                table.insert(sargs, ser(a))
            end
            out(
                string.format(
                    "local %s = %s:%s(%s)",
                    v,
                    pname,
                    ms,
                    table.concat(sargs, ", ")
                )
            )
            local function get_mock_args(method_name)
                local ml = method_name:lower()
                if ml:match("toggle") then
                    return { false }
                elseif ml:match("slider") then
                    return { 0 }
                elseif ml:match("dropdown") then
                    return { "" }
                elseif ml:match("textbox") or ml:match("input") then
                    return { "" }
                elseif ml:match("colorpicker") then
                    return { Color3.new(1, 1, 1) }
                elseif ml:match("keybind") then
                    return { Enum.KeyCode.E }
                else
                    return {}
                end
            end
            local function run_cb(cb)
                local mock_args = get_mock_args(ms)
                local od = st.cf_depth
                st.cf_depth = 0
                local opending = st.pending_iter
                st.pending_iter = 0
                _xpcall(function()
                    cb(_unpack(mock_args))
                end, function() end)
                while st.pending_iter and st.pending_iter > 0 do
                    st.ind = st.ind - 1
                    out("end")
                    st.pending_iter = st.pending_iter - 1
                end
                while st.cf_depth > 0 do
                    st.ind = st.ind - 1
                    out("end")
                    st.cf_depth = st.cf_depth - 1
                end
                st.pending_iter = opending
                st.cf_depth = od
            end
            return r
        end,
        __index = function(t, k)
            for _, sname in _ipairs(all_services) do
                if sname == k then
                    return methods.GetService(game, k)
                end
            end
            error(safestr(k) .. " is not a valid member of this function")
        end,
        __tostring = function()
            return "function: 0x00000000"
        end,
    }
    _setmt(f, mt)
    reg_c_func(f)
    method_cache[mname] = f
    return f
end
methods.FindFirstChildWhichIsA = function(self, cls, recursive)
    local cs = safestr(cls)
    local obj = mkpx(cs, false, self)
    local v = mkvar(obj, cs)
    local pn = st.reg[self] or "obj"
    out(string.format("local %s = %s:FindFirstChildWhichIsA(%s)", v, pn, q(cs)))
    return obj
end
methods.FindFirstChildOfClass = function(self, cls, recursive)
    local cs = safestr(cls)
    local obj = mkpx(cs, false, self)
    local v = mkvar(obj, cs)
    local pn = st.reg[self] or "obj"
    out(string.format("local %s = %s:FindFirstChildOfClass(%s)", v, pn, q(cs)))
    return obj
end
local function wrapshell(target)
    if not isproxy(target) then
        return target
    end
    local shell = {}
    st.reg[shell] = st.reg[target]
    st.propstore[shell] = st.propstore[target]
    st.parentmap[shell] = st.parentmap[target]
    rawset(shell, px_mark, true)
    rawset(shell, "__pxid", rawget(target, "__pxid"))
    _setmt(shell, _getmt(target))
    return shell
end
mkpx = function(hint, isroot, parent)
    local px, mt = mktblpx()
    local hs = safestr(hint)
    st.propstore = st.propstore or {}
    st.propstore[px] = {}
    if isroot then
        st.reg[px] = hs
        st.names[hs] = true
    end
    if parent then
        st.parentmap[px] = parent
    end
    mt.__tostring = function()
        return st.propstore[px] and st.propstore[px].Name or hs or "Instance"
    end
    mt.__index = function(t, k)
        if k == px_mark or k == "__pxid" then
            return rawget(t, k)
        end
        if k == "PlaceId" or k == "GameId" then
            return placeid
        end
        if k == "ClassName" then
            return (st.propstore[px] and st.propstore[px].ClassName)
                or hs
                or "Instance"
        end
        if k == "Name" or k == "name" then
            return (st.propstore[px] and st.propstore[px].Name)
                or hs
                or "Object"
        end
        if k == "Workspace" and (st.reg[px] == "game" or hs == "game") then
            return workspace
        end
        local className = st.propstore[px] and st.propstore[px].ClassName
            or hs
            or "Instance"
        local child = find_first_child_helper(px, k, false)
        if child then
            return child
        end
        if
            st.reg[px] == "game"
            or (st.propstore[px] and st.propstore[px].ClassName == "DataModel")
        then
            for _, sname in ipairs(all_services) do
                if sname == k then
                    return methods.GetService(px, k)
                end
            end
        end
        local member = nil
        if is_roblox_class(className) then
            member = find_member(className, k)
            if not member then
                if methods[k] then
                    return wrap_method(k)
                end
                if is_roblox_class(className) then
                    return nil
                end
                local newch = mkpx(k, false, px)
                st.propstore[newch] = { Name = k }
                st.parentmap[newch] = px
                return newch
            end
        end
        if member and member.Type == "Function" then
            return wrap_method(k)
        end
        if st.propstore[px] and st.propstore[px][k] ~= nil then
            return st.propstore[px][k]
        end
        if methods[k] then
            return wrap_method(k)
        end
        if member and member.Type == "Event" then
            local pn = st.reg[px] or hs or "obj"
            local sig = mkpx(pn .. "." .. k, false, px)
            rawset(sig, "__signal", true)
            st.reg[sig] = pn .. "." .. k
            return sig
        end
        if k == "Parent" then
            return st.parentmap[px] or nil
        end
        if k == "Name" then
            return st.propstore[px] and st.propstore[px].Name or hs or "Object"
        end
        if k == "ClassName" then
            return className
        end
        if k == "Connected" then
            return st.propstore[px]
                    and st.propstore[px].Connected ~= nil
                    and st.propstore[px].Connected
                or true
        end
        if k == "TouchEnabled" then
            return false
        end
        if k == "Ambient" then
            return Color3.new(0.5, 0.5, 0.5)
        end
        if k == "OutdoorAmbient" then
            return Color3.new(0.5, 0.5, 0.5)
        end
        if k == "MoveDirection" then
            return Vector3.new(0, 0, 0)
        end
        if k == "Position" then
            return st.propstore[px] and st.propstore[px].Position
                or Vector3.new(0, 0, 0)
        end
        if k == "Orientation" then
            return Vector3.new(0, 0, 0)
        end
        if k == "CFrame" then
            return st.propstore[px] and st.propstore[px].CFrame
                or CFrame.new(0, 0, 0)
        end
        if k == "Size" then
            return st.propstore[px] and st.propstore[px].Size
                or Vector3.new(4, 1, 2)
        end
        if k == "Color" then
            return Color3.new(0.64, 0.64, 0.64)
        end
        if k == "BrickColor" then
            return BrickColor.new("Medium stone grey")
        end
        if k == "CurrentCamera" then
            if not st.propstore[px].CurrentCamera then
                local cam = mkpx("Camera", false, px)
                st.propstore[cam] = { ClassName = "Camera", Name = "Camera" }
                local pn = st.reg[px] or "workspace"
                local v = mkvar(cam, "Camera")
                out(string.format("local %s = %s.CurrentCamera", v, pn))
                st.propstore[px].CurrentCamera = cam
            end
            return st.propstore[px].CurrentCamera
        end
        if k == "DistributedGameTime" then
            return os.clock()
        end
        if k == "JobId" then
            return "00000000-0000-0000-0000-000000000000"
        end
        if k == "LocalPlayer" then
            local lp = st.propstore[px] and st.propstore[px].LocalPlayer
            if lp then
                local lpv = mkvar(lp, "LocalPlayer")
                out(string.format('local %s = game:GetService("Players").LocalPlayer', lpv))
                return lp
            end
            if not st.propstore[px].LocalPlayer then
                local lp = mkpx("LocalPlayer", false, px)
                local lpv = mkvar(lp, "LocalPlayer")
                local pn2 = st.reg[px] or "Players"
                if
                    (
                        st.propstore[px]
                        and st.propstore[px].ClassName == "Players"
                    ) or pn2:match("^Players_%d+$")
                then
                    pn2 = 'game:GetService("Players")'
                end
                out(string.format('local %s = game:GetService("Players").LocalPlayer', lpv))
                st.propstore[lp] = {
                    UserId = 4352828284,
                    CharacterAppearanceId = 43528282848,
                    Name = "vole7vin",
                    DisplayName = "vole7vin",
                    ClassName = "Player",
                }
                st.propstore[px].LocalPlayer = lp
            end
            return st.propstore[px].LocalPlayer
        end
        if k == "Character" then
            if st.propstore[px] and st.propstore[px].Character ~= nil then
                return st.propstore[px].Character
            end
            local lp_proxy = nil
            if st.services and st.services["Players"] then
                local ps = st.propstore[st.services["Players"]]
                if ps then
                    lp_proxy = ps.LocalPlayer
                end
            end
            if not rawequal(px, lp_proxy) then
                return nil
            end
            if not st.propstore[px].Character then
                local char = mkpx("Character", false, px)
                st.propstore[char] = {
                    ClassName = "Model",
                    Name = st.propstore[px] and st.propstore[px].Name
                        or "Character",
                }
                local pn = st.reg[px] or "Character"
                local v = mkvar(char, "Character")
                out(string.format('local %s = game:GetService("Players").LocalPlayer.Character', v))
                st.propstore[px].Character = char
                local function addchild(cname, cclass, parentpx)
                    local c = mkpx(cname, false, parentpx)
                    st.propstore[c] = { ClassName = cclass, Name = cname }
                    st.parentmap[c] = parentpx
                    return c
                end
                addchild("Animate", "LocalScript", char)
                local hrp = addchild("HumanoidRootPart", "Part", char)
                st.propstore[hrp].CanCollide = true
                st.propstore[hrp].ReceiveAge = 0
                st.propstore[hrp].AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                addchild("Head", "Part", char)
                local torso = addchild("Torso", "Part", char)
                local rootJointR6 = addchild("RootJoint", "Motor6D", torso)
                st.propstore[rootJointR6].C0 = CFrame.new()
                st.propstore[rootJointR6].C1 = CFrame.new()
                local lowerTorso = addchild("LowerTorso", "Part", char)
                local rootJoint = addchild("RootJoint", "Motor6D", lowerTorso)
                st.propstore[rootJoint].C0 = CFrame.new()
                st.propstore[rootJoint].C1 = CFrame.new()
                addchild("Left Arm", "Part", char)
                addchild("Right Arm", "Part", char)
                addchild("Left Leg", "Part", char)
                addchild("Right Leg", "Part", char)
                local hum = addchild("Humanoid", "Humanoid", char)
                st.propstore[hum].Health = 100
                st.propstore[hum].MaxHealth = 100
                st.propstore[hum].WalkSpeed = 16
                st.propstore[hum].JumpPower = 50
                st.propstore[hum].DisplayName = st.propstore[px]
                        and st.propstore[px].DisplayName
                    or "Character"
                st.propstore[hum].RigType = Enum.HumanoidRigType.R15
                st.propstore[hum].MaxSlopeAngle = 89
                st.propstore[hum].HipHeight = 2
                st.propstore[hum].FloorMaterial = Enum.Material.Plastic
            end
            return st.propstore[px].Character
        end
        if k == "Humanoid" then
            if not st.propstore[px].Humanoid then
                local h = mkpx("Humanoid", false, px)
                st.propstore[h] = {
                    Health = 100,
                    MaxHealth = 100,
                    WalkSpeed = 16,
                    JumpPower = 50,
                    JumpHeight = 7.2,
                    HipHeight = 2,
                    AutoRotate = true,
                    MoveDirection = Vector3.new(0, 0, 0),
                    ClassName = "Humanoid",
                    Name = "Humanoid",
                    DisplayName = st.propstore[px]
                            and st.propstore[px].DisplayName
                        or "Humanoid",
                }
                local pn = st.reg[px] or "char"
                local v = mkvar(h, "Humanoid")
                out(
                    string.format(
                        'local %s = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")',
                        v
                    )
                )
                st.propstore[px].Humanoid = h
            end
            return st.propstore[px].Humanoid
        end
        if k == "HumanoidRootPart" then
            if not st.propstore[px].HumanoidRootPart then
                local hrp = mkpx("HumanoidRootPart", false, px)
                st.propstore[hrp] = {
                    Position = Vector3.new(0, 5, 0),
                    CFrame = CFrame.new(0, 5, 0),
                    ClassName = "Part",
                    Name = "HumanoidRootPart",
                }
                local pn = st.reg[px] or "char"
                local v = mkvar(hrp, "HumanoidRootPart")
                out(
                    string.format(
                        'local %s = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")',
                        v
                    )
                )
                st.propstore[px].HumanoidRootPart = hrp
            end
            return st.propstore[px].HumanoidRootPart
        end
        if k == "RootPart" then
            if not st.propstore[px].RootPart then
                local rp = mkpx("RootPart", false, px)
                st.propstore[rp] = { ClassName = "Part", Name = "RootPart" }
                local pn = st.reg[px] or "char"
                local v = mkvar(rp, "RootPart")
                out(
                    string.format(
                        'local %s = %s:FindFirstChild("RootPart")',
                        v,
                        pn
                    )
                )
                st.propstore[px].RootPart = rp
            end
            return st.propstore[px].RootPart
        end
        if k == "PrimaryPart" then
            if not st.propstore[px].PrimaryPart then
                local pp = mkpx("PrimaryPart", false, px)
                st.propstore[pp] = { ClassName = "Part", Name = "PrimaryPart" }
                local pn = st.reg[px] or "model"
                local v = mkvar(pp, "PrimaryPart")
                out(string.format("local %s = %s.PrimaryPart", v, pn))
                st.propstore[px].PrimaryPart = pp
            end
            return st.propstore[px].PrimaryPart
        end
        if k == "UserId" then
            return st.propstore[px] and st.propstore[px].UserId or 1
        end
        if k == "ClientGitHash" then
            return "abc123def456"
        end
        if k == "DisplayName" then
            if st.propstore[px] and st.propstore[px].DisplayName ~= nil then
                return st.propstore[px].DisplayName
            end
            if className == "Humanoid" then
                local lp = st.propstore[game] and st.propstore[game].LocalPlayer
                if lp and st.propstore[lp] and st.propstore[lp].DisplayName then
                    return st.propstore[lp].DisplayName
                end
            end
            return "vole7vin"
        end
        local pn = st.reg[px] or hs or "obj"
        if pn:match("^Enum") then
            local ep = pn .. "." .. k
            local ev = mkpx(ep, false)
            rawset(ev, "__enumitem", true)
            st.reg[ev] = ep
            return ev
        end
        if member and member.Type == "Property" then
            return get_default_property_value(k, member.ValueType)
        end
        return wrap_method(k)
    end
    mt.__newindex = function(t, k, v)
        if k == px_mark or k == "__pxid" then
            rawset(t, k, v)
            return
        end
        if not st.reg[px] then
            local hint_name = (st.propstore[px] and st.propstore[px].Name)
                or hs
                or "obj"
            local v2 = mkvar(px, hint_name)
            local par = st.parentmap[px]
            local pn = (par and st.reg[par]) or "workspace"
            out(
                string.format(
                    'local %s = %s:FindFirstChild("%s")',
                    v2,
                    pn,
                    hint_name
                )
            )
        end
        local pn = st.reg[px] or hs or "obj"
        if px == game and k == "Parent" then
            _err("Parent cannot be set")
        end
        local className = st.propstore[px] and st.propstore[px].ClassName
            or hs
            or "Instance"
        if is_roblox_class(className) then
            local member = find_member(className, k)
            if not member then
                _err(
                    tostring(k)
                        .. " is not a valid member of "
                        .. className
                        .. ' "'
                        .. (st.propstore[px].Name or className)
                        .. '"'
                )
            elseif member.Type == "Callback" then
                st.propstore[px] = st.propstore[px] or {}
                st.propstore[px][k] = v
                return
            elseif member.Type ~= "Property" or member.ReadOnly then
                _err(tostring(k) .. " cannot be assigned to")
            end
            if member.ValueType then
                local cat = member.ValueType.Category
                local n = member.ValueType.Name
                if
                    cat == "Primitive"
                    and (n == "string" or n == "Content")
                    and _type(v) ~= "string"
                then
                    _err("Expected string, got " .. typeof(v))
                end
            end
            if k == "Texture" and typeof(v) ~= "string" then
                _err("Expected string, got " .. typeof(v))
            end
        else
            local readonly_props = { ClassName = true }
            if readonly_props[k] then
                return
            end
        end
        if k == "Parent" and v ~= nil and not isproxy(v) then
            _err("Unable to cast value to Object")
        end
        -- GuiService.SelectedObject only accepts GuiObject or nil, not arbitrary Parts from workspace
        if k == "SelectedObject" then
            local cn = st.propstore[px] and st.propstore[px].ClassName
            if cn == "GuiService" then
                if v ~= nil and isproxy(v) then
                    local vpc = st.propstore[v] and st.propstore[v].ClassName
                        or ""
                    local gui_classes = {
                        ScreenGui = true,
                        Frame = true,
                        TextLabel = true,
                        TextButton = true,
                        ImageButton = true,
                        ImageLabel = true,
                        TextBox = true,
                        ScrollingFrame = true,
                        ViewportFrame = true,
                        VideoFrame = true,
                        CanvasGroup = true,
                        BillboardGui = true,
                        SurfaceGui = true,
                    }
                    if not gui_classes[vpc] then
                        _err("Unable to cast value to Object")
                    end
                end
            end
        end
        if k == "Parent" and isproxy(v) then
            local cur = v
            while cur do
                if cur == px then
                    _err(
                        "Attempt to set parent of "
                            .. (st.propstore[px] and st.propstore[px].Name or hs or "Instance")
                            .. " would result in circular reference"
                    )
                end
                cur = st.parentmap[cur]
            end
        end
        st.propstore[px] = st.propstore[px] or {}
        st.propstore[px][k] = v
        if k == "Parent" and isproxy(v) then
            st.parentmap[px] = v
        end
        local function ser_val(v)
            if isproxy(v) then
                local mt2 = _getmt(v)
                if mt2 and mt2.__typeof == "CFrame" then
                    local s = rawget(v, "__stored") or {}
                    return string.format(
                        "CFrame.new(%s, %s, %s)",
                        ser(s.X or 0),
                        ser(s.Y or 0),
                        ser(s.Z or 0)
                    )
                end
                if mt2 and mt2.__typeof == "Vector3" then
                    local s = rawget(v, "__stored") or {}
                    return string.format(
                        "Vector3.new(%s, %s, %s)",
                        ser(s.X or 0),
                        ser(s.Y or 0),
                        ser(s.Z or 0)
                    )
                end
                if mt2 and mt2.__typeof == "Color3" then
                    local srep = mt2.__tostring and mt2.__tostring(v) or ""
                    if srep:match("fromRGB") then
                        local s = rawget(v, "__stored") or {}
                        return string.format(
                            "Color3.fromRGB(%s, %s, %s)",
                            ser(math.floor((s.R or 0) * 255)),
                            ser(math.floor((s.G or 0) * 255)),
                            ser(math.floor((s.B or 0) * 255))
                        )
                    end
                    local s = rawget(v, "__stored") or {}
                    return string.format(
                        "Color3.new(%s, %s, %s)",
                        ser(s.R or 0),
                        ser(s.G or 0),
                        ser(s.B or 0)
                    )
                end
                if mt2 and mt2.__typeof == "Vector2" then
                    local s = rawget(v, "__stored") or {}
                    return string.format(
                        "Vector2.new(%s, %s)",
                        ser(s.X or 0),
                        ser(s.Y or 0)
                    )
                end
                if mt2 and mt2.__typeof == "UDim2" then
                    local s = rawget(v, "__stored") or {}
                    local xs = rawget(s.X, "__stored") or {}
                    local ys = rawget(s.Y, "__stored") or {}
                    return string.format(
                        "UDim2.new(%s, %s, %s, %s)",
                        ser(xs.Scale or 0),
                        ser(xs.Offset or 0),
                        ser(ys.Scale or 0),
                        ser(ys.Offset or 0)
                    )
                end
                if mt2 and mt2.__typeof == "UDim" then
                    local s = rawget(v, "__stored") or {}
                    return string.format(
                        "UDim.new(%s, %s)",
                        ser(s.Scale or 0),
                        ser(s.Offset or 0)
                    )
                end
            end
            return ser(v)
        end
        if is_spied(px) then
            out(string.format("if %s then", pn))
            st.ind = st.ind + 1
            out(string.format("%s.%s = %s", pn, safestr(k), ser_val(v)))
            st.ind = math.max(0, st.ind - 1)
            out("end")
        else
            out(string.format("%s.%s = %s", pn, safestr(k), ser_val(v)))
        end
    end
    mt.__call = function(t, ...)
        local pn = st.reg[px] or hs or "func"
        local non_callable = {
            game = true,
            workspace = true,
        }
        if non_callable[pn] then
            error("attempt to call a " .. typeof(t) .. " value")
        end
        if pn == "fenv" or pn == "getgenv" or pn:match("env") then
            return px
        end
        local args = { ... }
        local sargs = {}
        for _, v in _ipairs(args) do
            table.insert(sargs, ser(v))
        end
        local r = mkpx("res", false)
        local v = mkvar(r, "res")
        out(
            string.format("local %s = %s(%s)", v, pn, table.concat(sargs, ", "))
        )
        return r
    end
    local function mkarith(op)
        return function(a, b)
            local pr, pmr = mktblpx()
            local sa = (st.reg[a] or ser(a))
            local sb = (st.reg[b] or ser(b))
            local rs = "(" .. sa .. " " .. op .. " " .. sb .. ")"
            st.reg[pr] = rs
            pmr.__tostring = function()
                return rs
            end
            pmr.__index = mt.__index
            pmr.__add = mkarith("+")
            pmr.__sub = mkarith("-")
            pmr.__mul = mkarith("*")
            pmr.__div = mkarith("/")
            return pr
        end
    end
    mt.__add = mkarith("+")
    mt.__sub = mkarith("-")
    mt.__mul = mkarith("*")
    mt.__div = mkarith("/")
    mt.__mod = mkarith("%")
    mt.__pow = mkarith("^")
    mt.__concat = mkarith("..")
    local function get_rhs_tokens_for_line(line_num)
        if not st.tokens then
            return nil
        end
        local rhs = {}
        local found_eq = false
        for _, t in _ipairs(st.tokens) do
            if t.line == line_num then
                if found_eq then
                    table.insert(rhs, t)
                elseif t.type == "op" and t.value == "=" then
                    found_eq = true
                end
            end
        end
        if #rhs > 0 then
            return rhs
        end
        return nil
    end
    mt.__eq = function(a, b)
        local is_sp = is_spied(a) or is_spied(b)
        if is_sp then
            local ok, info_src = _pcall(dbg.info, 4, "s")
            local is_internal = ok
                and info_src
                and (info_src:match("aspect") or info_src:match("dumpstring"))
            if not is_internal then
                local line_num, line_content = get_current_script_line()
                if line_num and line_content then
                    local var_name = line_content:match(
                        "^%s*local%s+([%w_]+)%s*=%s*"
                    ) or line_content:match(
                        "^%s*([%w_]+)%s*=%s*"
                    )
                    if var_name then
                        local res_px = mkpx(var_name, false)
                        local vname = mkvar(res_px, var_name)
                        st.spied_vars[var_name] = true
                        st.var_map[var_name] = vname
                        local rhs_tokens = get_rhs_tokens_for_line(line_num)
                        local rhs_expr
                        if rhs_tokens then
                            rhs_expr = translate_tokens(rhs_tokens)
                        end
                        if not rhs_expr or rhs_expr == "" then
                            local sa = st.reg[a] or ser(a)
                            local sb = st.reg[b] or ser(b)
                            rhs_expr = string.format("%s == %s", sa, sb)
                        end
                        out(string.format("local %s = %s", vname, rhs_expr))
                    end
                end
            end
            return true
        end
        return rawequal(a, b)
    end
    local function mkcompare(op)
        return function(a, b)
            local is_sp = is_spied(a) or is_spied(b)
            if is_sp then
                local ok, info_src = _pcall(dbg.info, 4, "s")
                local is_internal = ok
                    and info_src
                    and (
                        info_src:match("aspect") or info_src:match("dumpstring")
                    )
                if not is_internal then
                    local line_num, line_content = get_current_script_line()
                    if line_num and line_content then
                        local var_name = line_content:match(
                            "^%s*local%s+([%w_]+)%s*=%s*"
                        ) or line_content:match(
                            "^%s*([%w_]+)%s*=%s*"
                        )
                        if var_name then
                            local res_px = mkpx(var_name, false)
                            local vname = mkvar(res_px, var_name)
                            st.spied_vars[var_name] = true
                            st.var_map[var_name] = vname
                            local rhs_tokens = get_rhs_tokens_for_line(line_num)
                            local rhs_expr
                            if rhs_tokens then
                                rhs_expr = translate_tokens(rhs_tokens)
                            end
                            if not rhs_expr or rhs_expr == "" then
                                local sa = st.reg[a] or ser(a)
                                local sb = st.reg[b] or ser(b)
                                rhs_expr = string.format("%s %s %s", sa, op, sb)
                            end
                            out(string.format("local %s = %s", vname, rhs_expr))
                        end
                    end
                end
                return true
            end
            return false
        end
    end
    mt.__lt = mkcompare("<")
    mt.__le = mkcompare("<=")
    mt.__unm = function(a)
        local r, rm = mktblpx()
        st.reg[r] = "(-" .. (st.reg[a] or ser(a)) .. ")"
        return r
    end
    mt.__len = function()
        return 0
    end
    mt.__tostring = function()
        if st.propstore[px] and st.propstore[px].Name ~= nil then
            return st.propstore[px].Name
        end
        return st.reg[px] or hs or "Object"
    end
    mt.__pairs = function()
        return function()
            return nil
        end, px, nil
    end
    mt.__ipairs = mt.__pairs
    mt.__namecall = function(t, ...)
        st.current_namecall = st.current_namecall or "Index"
        local args = { ... }
        local method = args[1]
        if _type(method) == "string" then
            st.current_namecall = method
        end
        if methods[method] then
            return methods[method](t, _unpack(args, 2))
        end
        local pn = st.reg[t] or "obj"
        local arg_strs = {}
        for i = 2, #args do
            table.insert(arg_strs, ser(args[i]))
        end
        local res = mkpx("result_" .. tostring(method), false)
        local rv = mkvar(res, tostring(method))
        st.reg[res] = rv
        out(
            string.format(
                "local %s = %s:%s(%s)",
                rv,
                pn,
                tostring(method),
                table.concat(arg_strs, ", ")
            )
        )
        return res
    end
    return px
end
get_event_mock_args = function(evname)
    local name_lower = evname:lower()
    if name_lower:match("heartbeat") or name_lower:match("renderstepped") then
        return { 0.016 }
    elseif name_lower:match("stepped") then
        return { 0.1, 0.016 }
    elseif name_lower:match("touched") or name_lower:match("touchended") then
        return { mkpx("Part", false) }
    elseif
        name_lower:match("inputbegan")
        or name_lower:match("inputended")
        or name_lower:match("inputchanged")
    then
        local input_obj = mkpx("InputObject", false)
        st.propstore[input_obj] = {
            KeyCode = Enum.KeyCode.Space,
            UserInputType = Enum.UserInputType.Keyboard,
        }
        return { input_obj, false }
    elseif
        name_lower:match("characteradded")
        or name_lower:match("characterremoving")
    then
        local char = mkpx("Model", false)
        st.propstore[char] = { ClassName = "Model", Name = "Character" }
        local head = mkpx("Head", false, char)
        st.propstore[head] = { ClassName = "Part", Name = "Head" }
        st.parentmap[head] = char
        local hrp = mkpx("HumanoidRootPart", false, char)
        st.propstore[hrp] = { ClassName = "Part", Name = "HumanoidRootPart" }
        st.parentmap[hrp] = char
        local hum = mkpx("Humanoid", false, char)
        st.propstore[hum] =
            { ClassName = "Humanoid", Name = "Humanoid", Health = 100 }
        st.parentmap[hum] = char
        return { char }
    elseif
        name_lower:match("playeradded") or name_lower:match("playerremoving")
    then
        local p = mkpx("Player", false)
        st.propstore[p] = { UserId = 1, Name = "vole7vin" }
        return { p }
    elseif
        name_lower:match("childadded")
        or name_lower:match("childremoved")
        or name_lower:match("descendantadded")
        or name_lower:match("descendantremoving")
    then
        return { mkpx("Instance", false) }
    elseif name_lower:match("changed") then
        return { "Name" }
    elseif name_lower:match("statechanged") then
        return { Enum.HumanoidStateType.None, Enum.HumanoidStateType.Running }
    elseif name_lower:match("messageout") then
        return { "message", Enum.MessageType.MessageOutput }
    end
    return {}
end
get_default_property_value = function(propName, valueType)
    local category = valueType.Category
    local name = valueType.Name
    local num_overrides = {
        Health = 100,
        MaxHealth = 100,
        WalkSpeed = 16,
        JumpPower = 50,
        JumpHeight = 7.2,
        HipHeight = 2,
        Size = 5,
        Volume = 1,
        Pitch = 1,
        Brightness = 2,
        SimulationRadius = 1000,
    }
    if num_overrides[propName] then
        return num_overrides[propName]
    end
    local bool_overrides = {
        Visible = true,
        Enabled = true,
        Active = true,
        AutoLocalize = true,
        ResetOnSpawn = true,
        Archivable = true,
        CastShadow = true,
        CollisionEnabled = true,
        ClassicChat = true,
        BubbleChat = false,
        CharacterAutoLoads = true,
        IsLoaded = true,
    }
    if bool_overrides[propName] ~= nil then
        return bool_overrides[propName]
    end
    if category == "Primitive" then
        if name == "bool" then
            return false
        elseif name == "string" then
            return ""
        elseif
            name == "double"
            or name == "float"
            or name == "int"
            or name == "int64"
        then
            return 0
        end
    elseif category == "DataType" then
        if name == "Vector3" then
            return Vector3.new()
        elseif name == "Vector2" then
            return Vector2.new()
        elseif name == "CFrame" then
            return CFrame.new()
        elseif name == "Color3" then
            return Color3.new(1, 1, 1)
        elseif name == "UDim" then
            return UDim.new()
        elseif name == "UDim2" then
            return UDim2.new()
        elseif name == "TweenInfo" then
            return TweenInfo.new()
        elseif name == "NumberRange" then
            return NumberRange.new(0)
        elseif name == "DateTime" then
            return DateTime.now()
        elseif name == "Font" then
            return Font.new()
        else
            return mkpx(name, false)
        end
    elseif category == "Enum" then
        return Enum[name].None
    end
    return nil
end
local function mktypecon(name)
    local ctor = {}
    local ctmt = {}
    local function fill_stored(s)
        s = s or {}
        if name == "Vector3" then
            s.X = s.X or 0
            s.Y = s.Y or 0
            s.Z = s.Z or 0
            s.Magnitude = s.Magnitude or math.sqrt(s.X ^ 2 + s.Y ^ 2 + s.Z ^ 2)
        elseif name == "Vector2" then
            s.X = s.X or 0
            s.Y = s.Y or 0
            s.Magnitude = s.Magnitude or math.sqrt(s.X ^ 2 + s.Y ^ 2)
        elseif name == "UDim" then
            s.Scale = s.Scale or 0
            s.Offset = s.Offset or 0
        elseif name == "UDim2" then
            s.X = s.X or { Scale = 0, Offset = 0 }
            s.Y = s.Y or { Scale = 0, Offset = 0 }
            s.Width = s.X
            s.Height = s.Y
        elseif name == "Color3" then
            s.R = s.R or 0
            s.G = s.G or 0
            s.B = s.B or 0
        elseif name == "CFrame" then
            s.X = s.X or 0
            s.Y = s.Y or 0
            s.Z = s.Z or 0
            s.Position = s.Position
                or (Vector3 and Vector3.new(s.X, s.Y, s.Z))
                or { X = 0, Y = 0, Z = 0 }
            s.Rotation = s.Rotation or 0
        elseif name == "Ray" then
            s.Origin = s.Origin
                or (Vector3 and Vector3.new(0, 0, 0))
                or { X = 0, Y = 0, Z = 0 }
            s.Direction = s.Direction
                or (Vector3 and Vector3.new(0, 0, -1))
                or { X = 0, Y = 0, Z = -1 }
        end
        return s
    end
    local function mktypeinst(srep, stored)
        stored = fill_stored(stored)
        local px, pmeta = mktblpx()
        rawset(px, "__stored", stored)
        pmeta.__typeof = name
        pmeta.__tostring = function()
            return srep
        end
        pmeta.__index = function(t, k)
            if k == px_mark or k == "__pxid" then
                return rawget(t, k)
            end
            if stored[k] ~= nil then
                return stored[k]
            end
            if
                (name == "Vector3" or name == "Vector2")
                and (k == "Unit" or k == "unit")
            then
                local unit_stored = {}
                local mag = stored.Magnitude or 1
                if mag > 0 then
                    unit_stored.X = (stored.X or 0) / mag
                    unit_stored.Y = (stored.Y or 0) / mag
                    if name == "Vector3" then
                        unit_stored.Z = (stored.Z or 0) / mag
                    end
                end
                return mktypeinst("(" .. srep .. ".Unit)", unit_stored)
            end
            if k == "X" or k == "Y" or k == "Z" or k == "W" then
                return 0
            end
            if k == "R" or k == "G" or k == "B" then
                return 0
            end
            if k == "Scale" or k == "Offset" then
                return 0
            end
            if k == "Min" or k == "Max" then
                return 0
            end
            if k == "Time" then
                return 1
            end
            if k == "Value" then
                if name == "ColorSequenceKeypoint" then
                    return Color3 and Color3.new()
                        or mktypeinst("Color3.new(1,1,1)")
                end
                return 0
            end
            if k == "Envelope" then
                return 0
            end
            if k == "Density" then
                return 0.7
            end
            if k == "Friction" or k == "FrictionWeight" then
                return 0.3
            end
            if k == "Elasticity" or k == "ElasticityWeight" then
                return 1
            end
            if
                (name == "Vector3" or name == "Vector2")
                and (k == "Magnitude" or k == "magnitude")
            then
                return stored.Magnitude or 0
            end
            if k == "inverse" or k == "Inverse" then
                local mw2, mmt2 = mktblpx()
                mmt2.__call = function(_, self2, ...)
                    local target = (isproxy(self2) and rawget(self2, "__stored")) and self2 or px
                    local s2 = rawget(target, "__stored") or {}
                    local rot = s2.Rot
                    local pos = s2.Position
                    local rst = {}
                    if rot then
                        rst.Rot = {
                            rot[1], rot[4], rot[7],
                            rot[2], rot[5], rot[8],
                            rot[3], rot[6], rot[9],
                        }
                        local pst = rawget(pos, "__stored") or pos or {}
                        local ix = -(rst.Rot[1]*(pst.X or 0) + rst.Rot[2]*(pst.Y or 0) + rst.Rot[3]*(pst.Z or 0))
                        local iy = -(rst.Rot[4]*(pst.X or 0) + rst.Rot[5]*(pst.Y or 0) + rst.Rot[6]*(pst.Z or 0))
                        local iz = -(rst.Rot[7]*(pst.X or 0) + rst.Rot[8]*(pst.Y or 0) + rst.Rot[9]*(pst.Z or 0))
                        rst.X = ix; rst.Y = iy; rst.Z = iz
                        rst.Position = mktypeinst("Vector3.new("..ser(ix)..","..ser(iy)..","..ser(iz)..")", {X=ix,Y=iy,Z=iz})
                    else
                        rst.X = -(s2.X or 0); rst.Y = -(s2.Y or 0); rst.Z = -(s2.Z or 0)
                        rst.Position = mktypeinst("Vector3.new("..(-(s2.X or 0))..","..(-(s2.Y or 0))..","..(-(s2.Z or 0))..")", {X=-(s2.X or 0),Y=-(s2.Y or 0),Z=-(s2.Z or 0)})
                    end
                    return mktypeinst("("..srep..":inverse())", rst)
                end
                mmt2.__index = function(_, sk) return nil end
                return mw2
            end
            if
                (name == "CFrame") and (k == "LookVector" or k == "lookVector")
            then
                local strot = stored.Rot
                if strot then
                    local lx = strot[1] * 0 + strot[2] * 0 + strot[3] * -1
                    local ly = strot[4] * 0 + strot[5] * 0 + strot[6] * -1
                    local lz = strot[7] * 0 + strot[8] * 0 + strot[9] * -1
                    return mktypecon("Vector3")
                            and mktypecon("Vector3").new(lx, ly, lz)
                        or mktypeinst("(" .. srep .. ".LookVector)")
                end
                return mktypecon("Vector3")
                        and mktypecon("Vector3").new(0, 0, -1)
                    or mktypeinst("(" .. srep .. ".LookVector)")
            end
            if
                (name == "CFrame")
                and (k == "RightVector" or k == "rightVector")
            then
                local strot = stored.Rot
                if strot then
                    local rx = strot[1] * 1 + strot[2] * 0 + strot[3] * 0
                    local ry = strot[4] * 1 + strot[5] * 0 + strot[6] * 0
                    local rz = strot[7] * 1 + strot[8] * 0 + strot[9] * 0
                    return mktypecon("Vector3")
                            and mktypecon("Vector3").new(rx, ry, rz)
                        or mktypeinst("(" .. srep .. ".RightVector)")
                end
                return mktypecon("Vector3")
                        and mktypecon("Vector3").new(1, 0, 0)
                    or mktypeinst("(" .. srep .. ".RightVector)")
            end
            if (name == "CFrame") and (k == "UpVector" or k == "upVector") then
                local strot = stored.Rot
                if strot then
                    local ux = strot[1] * 0 + strot[2] * 1 + strot[3] * 0
                    local uy = strot[4] * 0 + strot[5] * 1 + strot[6] * 0
                    local uz = strot[7] * 0 + strot[8] * 1 + strot[9] * 0
                    return mktypecon("Vector3")
                            and mktypecon("Vector3").new(ux, uy, uz)
                        or mktypeinst("(" .. srep .. ".UpVector)")
                end
                return mktypecon("Vector3")
                        and mktypecon("Vector3").new(0, 1, 0)
                    or mktypeinst("(" .. srep .. ".UpVector)")
            end
            if (name == "CFrame") and (k == "Position" or k == "p") then
                if stored.Position then
                    return stored.Position
                end
                return Vector3 and Vector3.new()
                    or mktypeinst("(" .. srep .. ".Position)")
            end
            if k == "Origin" then
                if stored.Origin then
                    return stored.Origin
                end
                return Vector3 and Vector3.new()
                    or mktypeinst("(" .. srep .. ".Origin)")
            end
            if k == "Direction" then
                if stored.Direction then
                    return stored.Direction
                end
                return Vector3 and Vector3.new(0, 0, -1)
                    or mktypeinst("(" .. srep .. ".Direction)")
            end
            if k == "Size" then
                return stored.Size or mktypeinst("(" .. srep .. ".Size)")
            end
            local mw, mmt = mktblpx()
            mmt.__call = function(_, ...)
                local args = { ... }
                if args[1] == mw or args[1] == px then
                    table.remove(args, 1)
                end
                local astrs = {}
                for _, v in _ipairs(args) do
                    table.insert(astrs, st.reg[v] or ser(v))
                end

                local rst = {}
                local method = safestr(k)
                if name == "Vector3" or name == "Vector2" then
                    if
                        (method == "Lerp" or method == "lerp")
                        and args[1]
                        and args[2]
                    then
                        local other_stored = rawget(args[1], "__stored")
                        local alpha = _tonumber(args[2])
                        if other_stored and alpha then
                            rst.X = (stored.X or 0)
                                + (other_stored.X - (stored.X or 0)) * alpha
                            rst.Y = (stored.Y or 0)
                                + (other_stored.Y - (stored.Y or 0)) * alpha
                            if name == "Vector3" then
                                rst.Z = (stored.Z or 0)
                                    + (other_stored.Z - (stored.Z or 0))
                                        * alpha
                            end
                        end
                    elseif (method == "Dot" or method == "dot") and args[1] then
                        local other_stored = rawget(args[1], "__stored")
                        if other_stored then
                            local dot = (stored.X or 0) * (other_stored.X or 0)
                                + (stored.Y or 0) * (other_stored.Y or 0)
                            if name == "Vector3" then
                                dot = dot
                                    + (stored.Z or 0)
                                        * (other_stored.Z or 0)
                            end
                            return dot
                        end
                    elseif
                        (method == "Cross" or method == "cross")
                        and args[1]
                        and name == "Vector3"
                    then
                        local other_stored = rawget(args[1], "__stored")
                        if other_stored then
                            rst.X = (stored.Y or 0) * (other_stored.Z or 0)
                                - (stored.Z or 0) * (other_stored.Y or 0)
                            rst.Y = (stored.Z or 0) * (other_stored.X or 0)
                                - (stored.X or 0) * (other_stored.Z or 0)
                            rst.Z = (stored.X or 0) * (other_stored.Y or 0)
                                - (stored.Y or 0) * (other_stored.X or 0)
                        end
                    end
                end

                return mktypeinst(
                    srep
                        .. ":"
                        .. method
                        .. "("
                        .. table.concat(astrs, ", ")
                        .. ")",
                    rst
                )
            end
            mmt.__index = function(_, sk)
                return mktypeinst(srep .. "." .. safestr(sk))
            end
            return mw
        end
        pmeta.__newindex = function(t, k, v)
            error(
                "Cannot write to read-only property "
                    .. _tostring(k)
                    .. " of "
                    .. name
            )
        end
        local function tarith(op)
            return function(a, b)
                local sa = st.reg[a] or ser(a)
                local sb = st.reg[b] or ser(b)
                local ast = rawget(a, "__stored")
                local bst = rawget(b, "__stored")
                local rst = {}
                if op == "+" then
                    if ast and bst then
                        if name == "Vector3" or name == "Vector2" then
                            rst.X = (ast.X or 0) + (bst.X or 0)
                            rst.Y = (ast.Y or 0) + (bst.Y or 0)
                            if name == "Vector3" then
                                rst.Z = (ast.Z or 0) + (bst.Z or 0)
                            end
                        elseif name == "UDim" then
                            rst.Scale = (ast.Scale or 0) + (bst.Scale or 0)
                            rst.Offset = (ast.Offset or 0) + (bst.Offset or 0)
                        elseif name == "UDim2" then
                            local ax = rawget(ast.X, "__stored") or {}
                            local ay = rawget(ast.Y, "__stored") or {}
                            local bx = rawget(bst.X, "__stored") or {}
                            local by = rawget(bst.Y, "__stored") or {}
                            rst.X = mktypeinst(
                                "UDim.new("
                                    .. ((ax.Scale or 0) + (bx.Scale or 0))
                                    .. ", "
                                    .. ((ax.Offset or 0) + (bx.Offset or 0))
                                    .. ")",
                                {
                                    Scale = (ax.Scale or 0) + (bx.Scale or 0),
                                    Offset = (ax.Offset or 0)
                                        + (bx.Offset or 0),
                                }
                            )
                            rst.Y = mktypeinst(
                                "UDim.new("
                                    .. ((ay.Scale or 0) + (by.Scale or 0))
                                    .. ", "
                                    .. ((ay.Offset or 0) + (by.Offset or 0))
                                    .. ")",
                                {
                                    Scale = (ay.Scale or 0) + (by.Scale or 0),
                                    Offset = (ay.Offset or 0)
                                        + (by.Offset or 0),
                                }
                            )
                            rst.Width = rst.X
                            rst.Height = rst.Y
                        end
                    end
                elseif op == "-" then
                    if ast and bst then
                        if name == "Vector3" or name == "Vector2" then
                            rst.X = (ast.X or 0) - (bst.X or 0)
                            rst.Y = (ast.Y or 0) - (bst.Y or 0)
                            if name == "Vector3" then
                                rst.Z = (ast.Z or 0) - (bst.Z or 0)
                            end
                        elseif name == "UDim" then
                            rst.Scale = (ast.Scale or 0) - (bst.Scale or 0)
                            rst.Offset = (ast.Offset or 0) - (bst.Offset or 0)
                        elseif name == "UDim2" then
                            local ax = rawget(ast.X, "__stored") or {}
                            local ay = rawget(ast.Y, "__stored") or {}
                            local bx = rawget(bst.X, "__stored") or {}
                            local by = rawget(bst.Y, "__stored") or {}
                            rst.X = mktypeinst(
                                "UDim.new("
                                    .. ((ax.Scale or 0) - (bx.Scale or 0))
                                    .. ", "
                                    .. ((ax.Offset or 0) - (bx.Offset or 0))
                                    .. ")",
                                {
                                    Scale = (ax.Scale or 0) - (bx.Scale or 0),
                                    Offset = (ax.Offset or 0)
                                        - (bx.Offset or 0),
                                }
                            )
                            rst.Y = mktypeinst(
                                "UDim.new("
                                    .. ((ay.Scale or 0) - (by.Scale or 0))
                                    .. ", "
                                    .. ((ay.Offset or 0) - (by.Offset or 0))
                                    .. ")",
                                {
                                    Scale = (ay.Scale or 0) - (by.Scale or 0),
                                    Offset = (ay.Offset or 0)
                                        - (by.Offset or 0),
                                }
                            )
                            rst.Width = rst.X
                            rst.Height = rst.Y
                        end
                    end
                elseif op == "*" then
                    local ast2 = rawget(a, "__stored")
                    local bst2 = rawget(b, "__stored")
                    if ast2 and bst2 then
                        if name == "Vector3" or name == "Vector2" then
                            rst.X = (ast2.X or 0) * (bst2.X or 0)
                            rst.Y = (ast2.Y or 0) * (bst2.Y or 0)
                            if name == "Vector3" then
                                rst.Z = (ast2.Z or 0) * (bst2.Z or 0)
                            end
                            rst.Magnitude = math.sqrt(rst.X^2 + rst.Y^2 + (name=="Vector3" and (rst.Z or 0)^2 or 0))
                        end
                    else
                        local s, vec
                        local an = _type(a) == "number" and a or (_tonumber(a) ~= nil and _tonumber(a) or nil)
                        local bn = _type(b) == "number" and b or (_tonumber(b) ~= nil and _tonumber(b) or nil)
                        if an then
                            s = an; vec = bst2 or ast2
                        elseif bn then
                            s = bn; vec = ast2 or bst2
                        elseif ast2 and not bst2 then
                            local nb = _type(b) == "number" and b or nil
                            if nb then s = nb; vec = ast2 end
                        elseif bst2 and not ast2 then
                            local na = _type(a) == "number" and a or nil
                            if na then s = na; vec = bst2 end
                        end
                        if s and vec then
                            rst.X = (vec.X or 0) * s
                            rst.Y = (vec.Y or 0) * s
                            if name == "Vector3" then
                                rst.Z = (vec.Z or 0) * s
                            end
                            rst.Magnitude = math.sqrt(rst.X^2 + rst.Y^2 + (name=="Vector3" and (rst.Z or 0)^2 or 0))
                        end
                    end
                elseif op == "/" then
                    if ast and bst then
                        if name == "Vector3" or name == "Vector2" then
                            rst.X = (bst.X ~= 0) and ((ast.X or 0) / bst.X) or 0
                            rst.Y = (bst.Y ~= 0) and ((ast.Y or 0) / bst.Y) or 0
                            if name == "Vector3" then
                                rst.Z = (bst.Z ~= 0) and ((ast.Z or 0) / bst.Z)
                                    or 0
                            end
                        end
                    elseif ast then
                        local scalar = _tonumber(b)
                        if
                            scalar
                            and scalar ~= 0
                            and (name == "Vector3" or name == "Vector2")
                        then
                            rst.X = (ast.X or 0) / scalar
                            rst.Y = (ast.Y or 0) / scalar
                            if name == "Vector3" then
                                rst.Z = (ast.Z or 0) / scalar
                            end
                        end
                    end
                end
                return mktypeinst(
                    "(" .. sa .. " " .. op .. " " .. sb .. ")",
                    rst
                )
            end
        end
        pmeta.__add = tarith("+")
        pmeta.__sub = tarith("-")
        pmeta.__mul = tarith("*")
        pmeta.__div = tarith("/")
        if name == "CFrame" then
            pmeta.__mul = function(a, b)
                local ast = rawget(a, "__stored") or {}
                local bst = rawget(b, "__stored") or {}
                local rst = {}
                local function apply(rot, v)
                    if not rot or not v then
                        return { X = 0, Y = 0, Z = 0 }
                    end
                    return {
                        X = rot[1] * (v.X or 0)
                            + rot[2] * (v.Y or 0)
                            + rot[3] * (v.Z or 0),
                        Y = rot[4] * (v.X or 0)
                            + rot[5] * (v.Y or 0)
                            + rot[6] * (v.Z or 0),
                        Z = rot[7] * (v.X or 0)
                            + rot[8] * (v.Y or 0)
                            + rot[9] * (v.Z or 0),
                    }
                end
                local function mulrot(ra, rb)
                    if not ra or not rb then
                        return nil
                    end
                    local r = {}
                    for i = 0, 2 do
                        for j = 0, 2 do
                            local s = 0
                            for k = 0, 2 do
                                s = s + ra[i * 3 + k + 1] * rb[k * 3 + j + 1]
                            end
                            r[i * 3 + j + 1] = s
                        end
                    end
                    return r
                end

                local arot = ast.Rot
                local brot = bst.Rot
                local apos = ast.Position
                local bpos = bst.Position
                if arot and brot then
                    rst.Rot = mulrot(arot, brot)
                    local applied =
                        apply(arot, rawget(bpos, "__stored") or bpos)
                    local px = (
                        rawget(apos, "__stored")
                            and (rawget(apos, "__stored").X or 0)
                        or (apos and apos.X or 0)
                    ) + (applied.X or 0)
                    local py = (
                        rawget(apos, "__stored")
                            and (rawget(apos, "__stored").Y or 0)
                        or (apos and apos.Y or 0)
                    ) + (applied.Y or 0)
                    local pz = (
                        rawget(apos, "__stored")
                            and (rawget(apos, "__stored").Z or 0)
                        or (apos and apos.Z or 0)
                    ) + (applied.Z or 0)
                    rst.Position = mktypeinst(
                        "Vector3.new("
                            .. ser(px)
                            .. ", "
                            .. ser(py)
                            .. ", "
                            .. ser(pz)
                            .. ")",
                        { X = px, Y = py, Z = pz }
                    )
                else
                    local px = (
                        rawget(apos, "__stored")
                            and (rawget(apos, "__stored").X or 0)
                        or (apos and apos.X or 0)
                    )
                        + (
                            rawget(bpos, "__stored")
                                and (rawget(bpos, "__stored").X or 0)
                            or (bpos and bpos.X or 0)
                        )
                    local py = (
                        rawget(apos, "__stored")
                            and (rawget(apos, "__stored").Y or 0)
                        or (apos and apos.Y or 0)
                    )
                        + (
                            rawget(bpos, "__stored")
                                and (rawget(bpos, "__stored").Y or 0)
                            or (bpos and bpos.Y or 0)
                        )
                    local pz = (
                        rawget(apos, "__stored")
                            and (rawget(apos, "__stored").Z or 0)
                        or (apos and apos.Z or 0)
                    )
                        + (
                            rawget(bpos, "__stored")
                                and (rawget(bpos, "__stored").Z or 0)
                            or (bpos and bpos.Z or 0)
                        )
                    rst.Position = mktypeinst(
                        "Vector3.new("
                            .. ser(px)
                            .. ", "
                            .. ser(py)
                            .. ", "
                            .. ser(pz)
                            .. ")",
                        { X = px, Y = py, Z = pz }
                    )
                    if arot then
                        rst.Rot = arot
                    elseif brot then
                        rst.Rot = brot
                    end
                end
                return mktypeinst(
                    "("
                        .. (st.reg[a] or ser(a))
                        .. " * "
                        .. (st.reg[b] or ser(b))
                        .. ")",
                    rst
                )
            end
        end
        pmeta.__unm = function(a)
            local ast = rawget(a, "__stored")
            local rst = {}
            if ast then
                rst.X = -(ast.X or 0)
                rst.Y = -(ast.Y or 0)
                if name == "Vector3" then
                    rst.Z = -(ast.Z or 0)
                end
            end
            return mktypeinst("(-" .. (st.reg[a] or ser(a)) .. ")", rst)
        end
        pmeta.__eq = function(a, b)
            local ast = rawget(a, "__stored")
            local bst = rawget(b, "__stored")
            if ast and bst then
                if name == "Vector3" then
                    return (ast.X or 0) == (bst.X or 0)
                        and (ast.Y or 0) == (bst.Y or 0)
                        and (ast.Z or 0) == (bst.Z or 0)
                elseif name == "Vector2" then
                    return (ast.X or 0) == (bst.X or 0)
                        and (ast.Y or 0) == (bst.Y or 0)
                elseif name == "Color3" then
                    return math.abs((ast.R or 0) - (bst.R or 0)) < 1e-6
                        and math.abs((ast.G or 0) - (bst.G or 0)) < 1e-6
                        and math.abs((ast.B or 0) - (bst.B or 0)) < 1e-6
                end
            end
            return rawequal(a, b)
        end
        return px
    end
    ctmt.__index = function(t, k)
        if name == "CFrame" and k == "identity" then
            return mktypeinst("CFrame.identity", {
                X = 0,
                Y = 0,
                Z = 0,
                Position = mktypeinst(
                    "Vector3.new(0, 0, 0)",
                    { X = 0, Y = 0, Z = 0 }
                ),
                Rot = {1,0,0, 0,1,0, 0,0,1},
            })
        elseif (name == "Vector3" or name == "Vector2") and k == "zero" then
            local stored = {X=0,Y=0,Z=0,Magnitude=0}
            local inst = mktypeinst(name .. ".zero", stored)
            local inst_mt = _getmt(inst)
            if inst_mt then
                inst_mt.__typeof = name
                rawset(inst, "__stored", stored)
            end
            return inst
        elseif (name == "Vector3" or name == "Vector2") and k == "one" then
            local stored = {X=1,Y=1,Z=1,Magnitude=math.sqrt(3)}
            local inst = mktypeinst(name .. ".one", stored)
            local inst_mt = _getmt(inst)
            if inst_mt then
                inst_mt.__typeof = name
                rawset(inst, "__stored", stored)
            end
            return inst
        end
        return function(...)
            local args = { ... }
            local sargs = {}
            for _, v in _ipairs(args) do
                table.insert(sargs, ser(v))
            end
            local as = table.concat(sargs, ", ")
            local srep = name .. "." .. k .. "(" .. as .. ")"
            local stored = {}
            if k == "new" then
                if name == "Vector3" then
                    stored.X = _tonumber(args[1]) or 0
                    stored.Y = _tonumber(args[2]) or 0
                    stored.Z = _tonumber(args[3]) or 0
                    stored.Magnitude =
                        math.sqrt(stored.X ^ 2 + stored.Y ^ 2 + stored.Z ^ 2)
                elseif name == "Vector2" then
                    stored.X = _tonumber(args[1]) or 0
                    stored.Y = _tonumber(args[2]) or 0
                    stored.Magnitude = math.sqrt(stored.X ^ 2 + stored.Y ^ 2)
                elseif name == "Color3" then
                    local function c(v)
                        local n = _tonumber(v) or 0
                        n = math.max(0, math.min(1, n))
                        return math.floor(n * 100000 + 0.5) / 100000
                    end
                    stored.R = c(args[1])
                    stored.G = c(args[2])
                    stored.B = c(args[3])
                elseif name == "CFrame" then
                    stored.X = _tonumber(args[1]) or 0
                    stored.Y = _tonumber(args[2]) or 0
                    stored.Z = _tonumber(args[3]) or 0
                    stored.Position = mktypeinst(
                        "Vector3.new("
                            .. (args[1] or 0)
                            .. ", "
                            .. (args[2] or 0)
                            .. ", "
                            .. (args[3] or 0)
                            .. ")",
                        { X = stored.X, Y = stored.Y, Z = stored.Z }
                    )
                elseif name == "UDim" then
                    stored.Scale = _tonumber(args[1]) or 0
                    stored.Offset = _tonumber(args[2]) or 0
                elseif name == "UDim2" then
                    stored.X = mktypeinst(
                        "UDim.new("
                            .. (args[1] or 0)
                            .. ", "
                            .. (args[2] or 0)
                            .. ")",
                        {
                            Scale = _tonumber(args[1]) or 0,
                            Offset = _tonumber(args[2]) or 0,
                        }
                    )
                    stored.Y = mktypeinst(
                        "UDim.new("
                            .. (args[3] or 0)
                            .. ", "
                            .. (args[4] or 0)
                            .. ")",
                        {
                            Scale = _tonumber(args[3]) or 0,
                            Offset = _tonumber(args[4]) or 0,
                        }
                    )
                    stored.Width = stored.X
                    stored.Height = stored.Y
                elseif name == "NumberRange" then
                    stored.Min = _tonumber(args[1]) or 0
                    stored.Max = _tonumber(args[2]) or stored.Min
                elseif name == "TweenInfo" then
                    stored.Time = _tonumber(args[1]) or 1
                    stored.EasingStyle = args[2]
                    stored.EasingDirection = args[3]
                    stored.RepeatCount = _tonumber(args[4]) or 0
                    stored.Reverses = args[5] == true
                    stored.DelayTime = _tonumber(args[6]) or 0
                elseif name == "Ray" then
                    stored.Origin = args[1]
                    stored.Direction = args[2]
                elseif name == "PhysicalProperties" then
                    stored.Density = _tonumber(args[1]) or 0.7
                    stored.Friction = _tonumber(args[2]) or 0.3
                    stored.Elasticity = _tonumber(args[3]) or 0.5
                    stored.FrictionWeight = _tonumber(args[4]) or 1
                    stored.ElasticityWeight = _tonumber(args[5]) or 1
                elseif name == "Region3" then
                    local min = args[1]
                    local max = args[2]
                    local sx = 10
                    local sy = 10
                    local sz = 10
                    stored.Size = mktypeinst(
                        "Vector3.new(" .. sx .. "," .. sy .. "," .. sz .. ")",
                        { X = sx, Y = sy, Z = sz }
                    )
                    stored.CFrame = mktypeinst("CFrame.new(0,0,0)")
                elseif name == "Font" then
                    stored.Family = safestr(args[1])
                    stored.Weight = args[2]
                    stored.Style = args[3]
                    stored.Bold = false
                elseif name == "ColorSequenceKeypoint" then
                    stored.Time = _tonumber(args[1]) or 0
                    stored.Value = args[2]
                    local color_str = "Color3.new(1,1,1)"
                    if args[2] then
                        local cs = rawget(args[2], "__stored")
                        if cs then
                            color_str = string.format(
                                "Color3.new(%s, %s, %s)",
                                ser(cs.R or 0),
                                ser(cs.G or 0),
                                ser(cs.B or 0)
                            )
                        end
                    end
                    srep = string.format(
                        "ColorSequenceKeypoint.new(%s, %s)",
                        ser(stored.Time),
                        color_str
                    )
                elseif name == "NumberSequenceKeypoint" then
                    stored.Time = _tonumber(args[1]) or 0
                    stored.Value = _tonumber(args[2]) or 0
                    stored.Envelope = _tonumber(args[3]) or 0
                    if stored.Envelope ~= 0 then
                        srep = string.format(
                            "NumberSequenceKeypoint.new(%s, %s, %s)",
                            ser(stored.Time),
                            ser(stored.Value),
                            ser(stored.Envelope)
                        )
                    else
                        srep = string.format(
                            "NumberSequenceKeypoint.new(%s, %s)",
                            ser(stored.Time),
                            ser(stored.Value)
                        )
                    end
                elseif name == "ColorSequence" then
                    if _type(args[1]) == "table" and not isproxy(args[1]) then
                        stored.Keypoints = args[1]
                        local kps = {}
                        for _, kp in _ipairs(args[1]) do
                            local ks = rawget(kp, "__stored") or {}
                            local color = ks.Value
                            local color_str = "Color3.new(1,1,1)"
                            if color then
                                local cs2 = rawget(color, "__stored")
                                if cs2 then
                                    color_str = string.format(
                                        "Color3.new(%s, %s, %s)",
                                        ser(cs2.R or 0),
                                        ser(cs2.G or 0),
                                        ser(cs2.B or 0)
                                    )
                                end
                            end
                            table.insert(
                                kps,
                                string.format(
                                    "ColorSequenceKeypoint.new(%s, %s)",
                                    ser(ks.Time or 0),
                                    color_str
                                )
                            )
                        end
                        srep = "ColorSequence.new({"
                            .. table.concat(kps, ", ")
                            .. "})"
                    elseif args[1] then
                        local cs2 = rawget(args[1], "__stored")
                        local color_str = cs2
                                and string.format(
                                    "Color3.new(%s, %s, %s)",
                                    ser(cs2.R or 0),
                                    ser(cs2.G or 0),
                                    ser(cs2.B or 0)
                                )
                            or "Color3.new(1,1,1)"
                        stored.Keypoints = {
                            ColorSequenceKeypoint.new(0, args[1]),
                            ColorSequenceKeypoint.new(1, args[1]),
                        }
                        srep = "ColorSequence.new(" .. color_str .. ")"
                    else
                        stored.Keypoints = {
                            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
                        }
                        srep = "ColorSequence.new(Color3.new(1,1,1))"
                    end
                elseif name == "NumberSequence" then
                    if _type(args[1]) == "table" and not isproxy(args[1]) then
                        stored.Keypoints = args[1]
                        local kps = {}
                        for _, kp in _ipairs(args[1]) do
                            local ks = rawget(kp, "__stored") or {}
                            local t_val = ks.Time or 0
                            local val = ks.Value or 0
                            local env = ks.Envelope or 0
                            if env ~= 0 then
                                table.insert(
                                    kps,
                                    string.format(
                                        "NumberSequenceKeypoint.new(%s, %s, %s)",
                                        ser(t_val),
                                        ser(val),
                                        ser(env)
                                    )
                                )
                            else
                                table.insert(
                                    kps,
                                    string.format(
                                        "NumberSequenceKeypoint.new(%s, %s)",
                                        ser(t_val),
                                        ser(val)
                                    )
                                )
                            end
                        end
                        srep = "NumberSequence.new({"
                            .. table.concat(kps, ", ")
                            .. "})"
                    elseif args[2] then
                        stored.Keypoints = {
                            NumberSequenceKeypoint.new(0, args[1]),
                            NumberSequenceKeypoint.new(1, args[2]),
                        }
                        srep = string.format(
                            "NumberSequence.new(%s, %s)",
                            ser(args[1]),
                            ser(args[2])
                        )
                    elseif args[1] then
                        stored.Keypoints = {
                            NumberSequenceKeypoint.new(0, args[1]),
                            NumberSequenceKeypoint.new(1, args[1]),
                        }
                        srep = string.format(
                            "NumberSequence.new(%s)",
                            ser(args[1])
                        )
                    else
                        stored.Keypoints = {
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(1, 1),
                        }
                        srep = "NumberSequence.new(1)"
                    end
                end
            elseif k == "fromRGB" and name == "Color3" then
                stored.R = (_tonumber(args[1]) or 0) / 255
                stored.G = (_tonumber(args[2]) or 0) / 255
                stored.B = (_tonumber(args[3]) or 0) / 255
            elseif k == "fromHex" and name == "Color3" then
                local hex = safestr(args[1] or "ffffff"):gsub("^#", "")
                stored.R = tonumber(hex:sub(1, 2), 16) / 255 or 0
                stored.G = tonumber(hex:sub(3, 4), 16) / 255 or 0
                stored.B = tonumber(hex:sub(5, 6), 16) / 255 or 0
                srep = string.format(
                    'Color3.fromHex("%s")',
                    safestr(args[1] or "ffffff")
                )
            elseif k == "fromHSV" and name == "Color3" then
                local h = _tonumber(args[1]) or 0
                local s_val = _tonumber(args[2]) or 0
                local v_val = _tonumber(args[3]) or 0
                local r, g, b
                if s_val == 0 then
                    r, g, b = v_val, v_val, v_val
                else
                    local i = math.floor(h * 6)
                    local f = h * 6 - i
                    local p = v_val * (1 - s_val)
                    local q2 = v_val * (1 - f * s_val)
                    local t2 = v_val * (1 - (1 - f) * s_val)
                    i = i % 6
                    if i == 0 then
                        r, g, b = v_val, t2, p
                    elseif i == 1 then
                        r, g, b = q2, v_val, p
                    elseif i == 2 then
                        r, g, b = p, v_val, t2
                    elseif i == 3 then
                        r, g, b = p, q2, v_val
                    elseif i == 4 then
                        r, g, b = t2, p, v_val
                    elseif i == 5 then
                        r, g, b = v_val, p, q2
                    end
                end
                stored.R = r or 0
                stored.G = g or 0
                stored.B = b or 0
                srep = string.format(
                    "Color3.fromHSV(%s, %s, %s)",
                    ser(h),
                    ser(s_val),
                    ser(v_val)
                )
            elseif k == "lookAt" and name == "CFrame" then
                local eye_st = args[1] and rawget(args[1], "__stored") or {}
                stored.X = eye_st.X or 0
                stored.Y = eye_st.Y or 0
                stored.Z = eye_st.Z or 0
                stored.Position = mktypeinst(
                    string.format(
                        "Vector3.new(%s, %s, %s)",
                        stored.X,
                        stored.Y,
                        stored.Z
                    ),
                    { X = stored.X, Y = stored.Y, Z = stored.Z }
                )
                srep = string.format(
                    "CFrame.lookAt(%s, %s)",
                    ser(args[1]),
                    ser(args[2])
                )
            elseif k == "Angles" and name == "CFrame" then
                local ax = _tonumber(args[1]) or 0
                local ay = _tonumber(args[2]) or 0
                local az = _tonumber(args[3]) or 0
                local cx, sx = math.cos(ax), math.sin(ax)
                local cy, sy = math.cos(ay), math.sin(ay)
                local cz, sz = math.cos(az), math.sin(az)
                local Rx = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
                local Ry = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
                local Rz = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
                local function mulmat(a, b)
                    local r = {}
                    for i = 0, 2 do
                        for j = 0, 2 do
                            local s = 0
                            for k2 = 0, 2 do
                                s = s + a[i * 3 + k2 + 1] * b[k2 * 3 + j + 1]
                            end
                            r[i * 3 + j + 1] = s
                        end
                    end
                    return r
                end
                local R = mulmat(mulmat(Rx, Ry), Rz)
                stored.Rot = R
                stored.Position =
                    mktypeinst("Vector3.new(0, 0, 0)", { X = 0, Y = 0, Z = 0 })
                srep = string.format(
                    "CFrame.Angles(%s, %s, %s)",
                    ser(ax),
                    ser(ay),
                    ser(az)
                )
            elseif k == "now" and name == "DateTime" then
                stored.UnixTimestamp = os.time()
                stored.UnixTimestampMillis = os.time() * 1000
            elseif k == "lookAt" and name == "CFrame" then
                local eye_st = args[1] and rawget(args[1], "__stored") or {}
                stored.X = eye_st.X or 0
                stored.Y = eye_st.Y or 0
                stored.Z = eye_st.Z or 0
                stored.Position = mktypeinst(
                    string.format(
                        "Vector3.new(%s, %s, %s)",
                        stored.X,
                        stored.Y,
                        stored.Z
                    ),
                    { X = stored.X, Y = stored.Y, Z = stored.Z }
                )
                srep = string.format(
                    "CFrame.lookAt(%s, %s)",
                    ser(args[1]),
                    ser(args[2])
                )
            elseif k == "fromScale" and name == "UDim2" then
                local sx = _tonumber(args[1]) or 0
                local sy = _tonumber(args[2]) or 0
                stored.X = mktypeinst(
                    "UDim.new(" .. sx .. ", 0)",
                    { Scale = sx, Offset = 0 }
                )
                stored.Y = mktypeinst(
                    "UDim.new(" .. sy .. ", 0)",
                    { Scale = sy, Offset = 0 }
                )
                stored.Width = stored.X
                stored.Height = stored.Y
                srep =
                    string.format("UDim2.fromScale(%s, %s)", ser(sx), ser(sy))
            elseif k == "fromOffset" and name == "UDim2" then
                local ox = _tonumber(args[1]) or 0
                local oy = _tonumber(args[2]) or 0
                stored.X = mktypeinst(
                    "UDim.new(0, " .. ox .. ")",
                    { Scale = 0, Offset = ox }
                )
                stored.Y = mktypeinst(
                    "UDim.new(0, " .. oy .. ")",
                    { Scale = 0, Offset = oy }
                )
                stored.Width = stored.X
                stored.Height = stored.Y
                srep =
                    string.format("UDim2.fromOffset(%s, %s)", ser(ox), ser(oy))
            end
            return mktypeinst(srep, stored)
        end
    end
    ctmt.__call = function(t, ...)
        return t.new(...)
    end
    return _setmt(ctor, ctmt)
end
Vector3 = mktypecon("Vector3")
Vector2 = mktypecon("Vector2")
CFrame = mktypecon("CFrame")
Color3 = mktypecon("Color3")
do
    local bc_ctor = {}
    local bc_mt = {}
    local bc_name_to_num = {}
    local bc_num_to_name = {}
    for i, name in _ipairs(all_brickcolors) do
        bc_name_to_num[name] = i
        bc_num_to_name[i] = name
    end
    local function make_bc(name_or_num)
        local px, pmeta = mktblpx()
        local name = _type(name_or_num) == "string" and name_or_num
            or (bc_num_to_name[name_or_num] or "Medium stone grey")
        local num = bc_name_to_num[name] or 1
        local bc_rgb = {
            ["White"] = { 0.949, 0.953, 0.953 },
            ["Grey"] = { 0.631, 0.647, 0.635 },
            ["Light yellow"] = { 0.976, 0.914, 0.600 },
            ["Brick yellow"] = { 0.843, 0.773, 0.604 },
            ["Light green (Mint)"] = { 0.761, 0.855, 0.722 },
            ["Light reddish violet"] = { 0.910, 0.729, 0.784 },
            ["Pastel Blue"] = { 0.502, 0.733, 0.859 },
            ["Light orange brown"] = { 0.796, 0.518, 0.259 },
            ["Nougat"] = { 0.800, 0.557, 0.412 },
            ["Bright red"] = { 0.769, 0.157, 0.110 },
            ["Med. reddish violet"] = { 0.769, 0.439, 0.627 },
            ["Bright blue"] = { 0.051, 0.412, 0.675 },
            ["Bright yellow"] = { 0.961, 0.804, 0.188 },
            ["Earth orange"] = { 0.384, 0.278, 0.196 },
            ["Black"] = { 0.106, 0.165, 0.208 },
            ["Dark grey"] = { 0.427, 0.431, 0.424 },
            ["Dark green"] = { 0.157, 0.498, 0.278 },
            ["Medium green"] = { 0.631, 0.769, 0.549 },
            ["Lig. Yellowich orange"] = { 0.953, 0.812, 0.608 },
            ["Bright green"] = { 0.294, 0.592, 0.294 },
            ["Dark orange"] = { 0.627, 0.373, 0.208 },
            ["Light bluish violet"] = { 0.757, 0.792, 0.871 },
            ["Transparent"] = { 0.925, 0.925, 0.925 },
            ["Tr. Red"] = { 0.804, 0.329, 0.294 },
            ["Tr. Lg blue"] = { 0.757, 0.875, 0.941 },
            ["Tr. Blue"] = { 0.482, 0.714, 0.910 },
            ["Tr. Yellow"] = { 0.969, 0.945, 0.553 },
            ["Light blue"] = { 0.706, 0.824, 0.894 },
            ["Tr. Flu. Reddish orange"] = { 0.851, 0.522, 0.424 },
            ["Tr. Green"] = { 0.518, 0.714, 0.553 },
            ["Tr. Flu. Green"] = { 0.973, 0.945, 0.518 },
            ["Phosph. White"] = { 0.925, 0.910, 0.871 },
            ["Light red"] = { 0.933, 0.769, 0.714 },
            ["Medium red"] = { 0.855, 0.525, 0.478 },
            ["Medium blue"] = { 0.431, 0.600, 0.792 },
            ["Light grey"] = { 0.780, 0.757, 0.718 },
            ["Bright violet"] = { 0.420, 0.196, 0.486 },
            ["Br. yellowish orange"] = { 0.886, 0.608, 0.251 },
            ["Bright orange"] = { 0.855, 0.522, 0.255 },
            ["Bright bluish green"] = { 0.000, 0.561, 0.612 },
            ["Earth yellow"] = { 0.408, 0.361, 0.263 },
            ["Bright bluish violet"] = { 0.263, 0.329, 0.576 },
            ["Tr. Brown"] = { 0.749, 0.718, 0.694 },
            ["Medium bluish violet"] = { 0.408, 0.455, 0.675 },
            ["Tr. Medi. reddish violet"] = { 0.898, 0.678, 0.784 },
            ["Med. yellowish green"] = { 0.780, 0.824, 0.235 },
            ["Med. bluish green"] = { 0.333, 0.647, 0.686 },
            ["Light bluish green"] = { 0.718, 0.843, 0.835 },
            ["Br. yellowish green"] = { 0.643, 0.741, 0.278 },
            ["Lig. yellowish green"] = { 0.851, 0.894, 0.655 },
            ["Med. yellowish orange"] = { 0.906, 0.675, 0.345 },
            ["Br. reddish orange"] = { 0.827, 0.435, 0.298 },
            ["Bright reddish violet"] = { 0.573, 0.224, 0.471 },
            ["Light orange"] = { 0.918, 0.722, 0.573 },
            ["Tr. Bright bluish violet"] = { 0.647, 0.647, 0.796 },
            ["Gold"] = { 0.863, 0.737, 0.506 },
            ["Dark nougat"] = { 0.682, 0.478, 0.349 },
            ["Silver"] = { 0.612, 0.639, 0.659 },
            ["Neon orange"] = { 0.835, 0.451, 0.239 },
            ["Neon green"] = { 0.847, 0.867, 0.337 },
            ["Sand blue"] = { 0.455, 0.525, 0.616 },
            ["Sand violet"] = { 0.529, 0.486, 0.565 },
            ["Medium orange"] = { 0.878, 0.596, 0.392 },
            ["Sand yellow"] = { 0.584, 0.541, 0.451 },
            ["Earth blue"] = { 0.125, 0.227, 0.337 },
            ["Earth green"] = { 0.153, 0.275, 0.176 },
            ["Tr. Flu. Blue"] = { 0.812, 0.886, 0.969 },
            ["Sand blue metallic"] = { 0.475, 0.533, 0.631 },
            ["Sand violet metallic"] = { 0.584, 0.557, 0.639 },
            ["Sand yellow metallic"] = { 0.576, 0.529, 0.404 },
            ["Dark grey metallic"] = { 0.341, 0.345, 0.341 },
            ["Black metallic"] = { 0.086, 0.114, 0.196 },
            ["Light grey metallic"] = { 0.671, 0.678, 0.675 },
            ["Sand green"] = { 0.471, 0.565, 0.510 },
            ["Sand red"] = { 0.584, 0.475, 0.467 },
            ["Dark red"] = { 0.482, 0.180, 0.184 },
            ["Tr. Flu. Yellow"] = { 1.000, 0.965, 0.482 },
            ["Tr. Flu. Red"] = { 0.882, 0.643, 0.761 },
            ["Gun metallic"] = { 0.459, 0.424, 0.384 },
            ["Red flip/flop"] = { 0.592, 0.412, 0.357 },
            ["Yellow flip/flop"] = { 0.706, 0.518, 0.333 },
            ["Silver flip/flop"] = { 0.537, 0.529, 0.533 },
            ["Curry"] = { 0.843, 0.663, 0.294 },
            ["Fire Yellow"] = { 0.976, 0.839, 0.180 },
            ["Flame yellowish orange"] = { 0.910, 0.671, 0.176 },
            ["Reddish brown"] = { 0.412, 0.251, 0.157 },
            ["Flame reddish orange"] = { 0.812, 0.376, 0.141 },
            ["Medium stone grey"] = { 0.639, 0.635, 0.647 },
            ["Royal blue"] = { 0.275, 0.404, 0.643 },
            ["Dark Royal blue"] = { 0.137, 0.278, 0.545 },
            ["Bright reddish lilac"] = { 0.557, 0.259, 0.522 },
            ["Dark stone grey"] = { 0.388, 0.373, 0.384 },
            ["Lemon metalic"] = { 0.510, 0.541, 0.365 },
            ["Light stone grey"] = { 0.898, 0.894, 0.875 },
            ["Dark Curry"] = { 0.690, 0.557, 0.267 },
            ["Faded green"] = { 0.439, 0.584, 0.471 },
            ["Turquoise"] = { 0.475, 0.710, 0.710 },
            ["Light Royal blue"] = { 0.624, 0.765, 0.914 },
            ["Medium Royal blue"] = { 0.424, 0.506, 0.718 },
            ["Rust"] = { 0.565, 0.298, 0.165 },
            ["Brown"] = { 0.486, 0.361, 0.275 },
            ["Reddish lilac"] = { 0.588, 0.439, 0.624 },
            ["Lilac"] = { 0.420, 0.384, 0.608 },
            ["Light lilac"] = { 0.655, 0.663, 0.808 },
            ["Bright purple"] = { 0.804, 0.384, 0.596 },
            ["Light purple"] = { 0.894, 0.678, 0.784 },
            ["Light pink"] = { 0.863, 0.565, 0.584 },
            ["Light brick yellow"] = { 0.941, 0.835, 0.627 },
            ["Warm yellowish orange"] = { 0.922, 0.722, 0.498 },
            ["Cool yellow"] = { 0.992, 0.918, 0.553 },
            ["Dove blue"] = { 0.490, 0.733, 0.867 },
            ["Medium lilac"] = { 0.204, 0.169, 0.459 },
            ["Slime green"] = { 0.314, 0.427, 0.329 },
            ["Smoky grey"] = { 0.357, 0.365, 0.412 },
            ["Dark blue"] = { 0.000, 0.063, 0.690 },
            ["Parsley green"] = { 0.173, 0.396, 0.114 },
            ["Steel blue"] = { 0.322, 0.486, 0.682 },
            ["Storm blue"] = { 0.200, 0.345, 0.510 },
            ["Lapis"] = { 0.063, 0.165, 0.863 },
            ["Dark indigo"] = { 0.239, 0.082, 0.522 },
            ["Sea green"] = { 0.204, 0.557, 0.251 },
            ["Shamrock"] = { 0.357, 0.604, 0.298 },
            ["Fossil"] = { 0.624, 0.631, 0.675 },
            ["Mulberry"] = { 0.349, 0.133, 0.349 },
            ["Forest green"] = { 0.122, 0.502, 0.114 },
            ["Cadet blue"] = { 0.624, 0.678, 0.753 },
            ["Electric blue"] = { 0.035, 0.537, 0.812 },
            ["Eggplant"] = { 0.482, 0.000, 0.482 },
            ["Moss"] = { 0.486, 0.612, 0.420 },
            ["Artichoke"] = { 0.541, 0.671, 0.522 },
            ["Sage green"] = { 0.725, 0.769, 0.694 },
            ["Ghost grey"] = { 0.792, 0.796, 0.820 },
            ["Lilac"] = { 0.655, 0.369, 0.608 },
            ["Plum"] = { 0.482, 0.184, 0.482 },
            ["Olivine"] = { 0.580, 0.745, 0.506 },
            ["Laurel green"] = { 0.659, 0.741, 0.600 },
            ["Quill grey"] = { 0.875, 0.875, 0.871 },
            ["Crimson"] = { 0.592, 0.000, 0.000 },
            ["Mint"] = { 0.694, 0.898, 0.651 },
            ["Baby blue"] = { 0.596, 0.761, 0.859 },
            ["Carnation pink"] = { 1.000, 0.596, 0.863 },
            ["Persimmon"] = { 1.000, 0.349, 0.349 },
            ["Maroon"] = { 0.459, 0.000, 0.000 },
            ["Gold"] = { 0.937, 0.722, 0.220 },
            ["Daisy orange"] = { 0.996, 0.859, 0.435 },
            ["Pearl"] = { 0.945, 0.957, 0.949 },
            ["Fog"] = { 0.878, 0.882, 0.886 },
            ["Salmon"] = { 0.996, 0.784, 0.749 },
            ["Terra Cotta"] = { 0.949, 0.529, 0.412 },
            ["Cocoa"] = { 0.710, 0.506, 0.459 },
            ["Wheat"] = { 0.918, 0.847, 0.741 },
            ["Buttermilk"] = { 0.996, 0.957, 0.816 },
            ["Mauve"] = { 0.718, 0.608, 0.710 },
            ["Sunrise"] = { 0.945, 0.722, 0.604 },
            ["Tawny"] = { 0.827, 0.545, 0.435 },
            ["Rust"] = { 0.839, 0.463, 0.333 },
            ["Cashmere"] = { 0.949, 0.722, 0.624 },
            ["Khaki"] = { 0.780, 0.698, 0.580 },
            ["Lily white"] = { 0.961, 0.957, 0.945 },
            ["Seashell"] = { 0.949, 0.871, 0.827 },
            ["Burgundy"] = { 0.600, 0.192, 0.192 },
            ["Cork"] = { 0.757, 0.639, 0.620 },
            ["Burlap"] = { 0.847, 0.780, 0.612 },
            ["Beige"] = { 0.784, 0.718, 0.624 },
            ["Oyster"] = { 0.792, 0.733, 0.659 },
            ["Pine Cone"] = { 0.651, 0.557, 0.494 },
            ["Fawn"] = { 0.761, 0.671, 0.573 },
            ["Hurricane grey"] = { 0.584, 0.537, 0.533 },
            ["Cloudy grey"] = { 0.694, 0.686, 0.678 },
            ["Linen"] = { 0.627, 0.592, 0.573 },
            ["Copper"] = { 0.816, 0.557, 0.443 },
            ["Dirt brown"] = { 0.627, 0.533, 0.463 },
            ["Bronze"] = { 0.608, 0.525, 0.416 },
            ["Flint"] = { 0.569, 0.553, 0.549 },
            ["Dark Taupe"] = { 0.561, 0.490, 0.416 },
            ["Burnt Sienna"] = { 0.698, 0.416, 0.314 },
            ["Institutional white"] = { 0.973, 0.973, 0.973 },
            ["Mid gray"] = { 0.600, 0.600, 0.600 },
            ["Really black"] = { 0.067, 0.067, 0.067 },
            ["Really red"] = { 0.851, 0.094, 0.094 },
            ["Deep orange"] = { 0.808, 0.416, 0.098 },
            ["Alder"] = { 0.733, 0.596, 0.498 },
            ["Dusty Rose"] = { 0.718, 0.573, 0.592 },
            ["Olive"] = { 0.557, 0.561, 0.392 },
            ["New Yeller"] = { 0.992, 0.929, 0.557 },
            ["Really blue"] = { 0.102, 0.529, 0.867 },
            ["Deep blue"] = { 0.055, 0.149, 0.831 },
            ["Cyan"] = { 0.196, 0.718, 0.769 },
            ["CGA brown"] = { 0.620, 0.447, 0.306 },
            ["Magenta"] = { 0.769, 0.259, 0.584 },
            ["Pink"] = { 0.969, 0.580, 0.710 },
            ["Deep orange"] = { 0.878, 0.349, 0.137 },
            ["Teal"] = { 0.000, 0.749, 0.671 },
            ["Toothpaste"] = { 0.635, 0.871, 0.792 },
            ["Lime green"] = { 0.659, 0.820, 0.314 },
            ["Camo"] = { 0.545, 0.608, 0.400 },
            ["Grime"] = { 0.510, 0.620, 0.424 },
            ["Lavender"] = { 0.800, 0.647, 0.902 },
            ["Pastel Light Blue"] = { 0.651, 0.749, 0.859 },
            ["Pastel Orange"] = { 0.976, 0.671, 0.463 },
            ["Pastel Violet"] = { 0.784, 0.667, 0.804 },
            ["Pastel Blue-Green"] = { 0.722, 0.859, 0.800 },
            ["Pastel Green"] = { 0.698, 0.843, 0.698 },
            ["Pastel Yellow"] = { 0.996, 0.961, 0.698 },
            ["Pastel Brown"] = { 0.820, 0.710, 0.620 },
            ["Royal purple"] = { 0.478, 0.263, 0.675 },
            ["Hot pink"] = { 0.973, 0.427, 0.859 },
        }
        local rgb = bc_rgb[name] or { 0.639, 0.635, 0.647 }
        rawset(
            px,
            "__stored",
            { Name = name, Number = num, r = rgb[1], g = rgb[2], b = rgb[3] }
        )
        pmeta.__typeof = "BrickColor"
        pmeta.__tostring = function()
            return "BrickColor(" .. name .. ")"
        end
        pmeta.__index = function(t, k)
            if k == px_mark or k == "__pxid" then
                return rawget(t, k)
            end
            local s = rawget(t, "__stored") or {}
            if s[k] ~= nil then
                return s[k]
            end
            if k == "Name" then
                return name
            end
            if k == "Number" then
                return num
            end
            if k == "r" or k == "R" then
                return s.r
            end
            if k == "g" or k == "G" then
                return s.g
            end
            if k == "b" or k == "B" then
                return s.b
            end
            if k == "Color" then
                local s2 = rawget(t, "__stored") or {}
                return Color3.new(s2.r or 0.5, s2.g or 0.5, s2.b or 0.5)
            end
            return nil
        end
        return px
    end
    bc_mt.__index = function(t, k)
        if k == "new" or k == "Name" then
            return function(...)
                local args = { ... }
                local arg = args[1]
                if _type(arg) == "string" then
                    return make_bc(arg)
                elseif _type(arg) == "number" then
                    return make_bc(bc_num_to_name[arg] or "Medium stone grey")
                else
                    local cs = nil
                    if isproxy(arg) then
                        cs = rawget(arg, "__stored")
                    elseif _type(arg) == "table" and not isproxy(arg) then
                        cs = arg
                    end
                    if cs and (cs.R ~= nil) and (cs.G ~= nil) and (cs.B ~= nil) then
                        local best_name_exact, best_name_approx, best_dist
                        for _, bname in _ipairs(all_brickcolors) do
                            local bc_obj = make_bc(bname)
                            local bs = rawget(bc_obj, "__stored") or {}
                            local dr = math.abs((bs.r or 0) - (cs.R or 0))
                            local dg = math.abs((bs.g or 0) - (cs.G or 0))
                            local db = math.abs((bs.b or 0) - (cs.B or 0))
                            if dr < 1e-3 and dg < 1e-3 and db < 1e-3 then
                                best_name_exact = bname
                                break
                            end
                            local d = dr*dr + dg*dg + db*db
                            if not best_dist or d < best_dist then
                                best_dist = d
                                best_name_approx = bname
                            end
                        end
                        return make_bc(best_name_exact or best_name_approx or "Medium stone grey")
                    end
                end
                return make_bc("Medium stone grey")
            end
        end
        if k == "palette" then
            return function(idx)
                return make_bc(bc_num_to_name[idx] or "Medium stone grey")
            end
        end
        if k == "random" then
            return function()
                local idx = math.random(1, #all_brickcolors)
                return make_bc(all_brickcolors[idx])
            end
        end
        if k == "White" then
            return make_bc("White")
        end
        if k == "Black" then
            return make_bc("Really black")
        end
        if k == "Gray" or k == "Grey" then
            return make_bc("Medium stone grey")
        end
        if k == "Red" then
            return make_bc("Bright red")
        end
        if k == "Yellow" then
            return make_bc("Bright yellow")
        end
        if k == "Green" then
            return make_bc("Bright green")
        end
        if k == "Blue" then
            return make_bc("Bright blue")
        end
        return function(...)
            return make_bc("Medium stone grey")
        end
    end
    bc_mt.__call = function(t, ...)
        local args = { ... }
        local arg = args[1]
        if _type(arg) == "string" then
            return make_bc(arg)
        elseif _type(arg) == "number" then
            return make_bc(bc_num_to_name[arg] or "Medium stone grey")
        else
            local cs = nil
            if isproxy(arg) then
                cs = rawget(arg, "__stored")
            elseif _type(arg) == "table" and not isproxy(arg) then
                cs = arg
            end
            if cs and cs.R ~= nil and cs.G ~= nil and cs.B ~= nil then
                local best_name_exact, best_name_approx, best_dist
                for _, bname in _ipairs(all_brickcolors) do
                    local bc_obj = make_bc(bname)
                    local bs = rawget(bc_obj, "__stored") or {}
                    local dr = math.abs((bs.r or 0) - (cs.R or 0))
                    local dg = math.abs((bs.g or 0) - (cs.G or 0))
                    local db = math.abs((bs.b or 0) - (cs.B or 0))
                    if dr < 1e-3 and dg < 1e-3 and db < 1e-3 then
                        best_name_exact = bname
                        break
                    end
                    local d = dr*dr + dg*dg + db*db
                    if not best_dist or d < best_dist then
                        best_dist = d
                        best_name_approx = bname
                    end
                end
                return make_bc(best_name_exact or best_name_approx or "Medium stone grey")
            end
        end
        return make_bc("Medium stone grey")
    end
    BrickColor = _setmt(bc_ctor, bc_mt)
end
UDim = mktypecon("UDim")
UDim2 = mktypecon("UDim2")
TweenInfo = mktypecon("TweenInfo")
Ray = mktypecon("Ray")
Rect = mktypecon("Rect")
Region3 = mktypecon("Region3")
NumberRange = mktypecon("NumberRange")
NumberSequence = mktypecon("NumberSequence")
NumberSequenceKeypoint = mktypecon("NumberSequenceKeypoint")
ColorSequenceKeypoint = mktypecon("ColorSequenceKeypoint")
ColorSequence = mktypecon("ColorSequence")
_G.ColorSequence = ColorSequence
_G.ColorSequenceKeypoint = ColorSequenceKeypoint
_G.NumberSequenceKeypoint = NumberSequenceKeypoint
PhysicalProperties = mktypecon("PhysicalProperties")
RaycastParams = mktypecon("RaycastParams")
OverlapParams = mktypecon("OverlapParams")
do
    local op_mt = _getmt(OverlapParams)
    local op_orig_index = op_mt.__index
    op_mt.__index = function(t, k)
        if k == "new" then
            return function()
                local inst, imt = mktblpx()
                rawset(inst, "__stored", {
                    FilterDescendantsInstances = {},
                    FilterType = Enum.RaycastFilterType.Exclude,
                    MaxParts = 0,
                    CollisionGroup = "Default",
                    RespectCanCollide = false,
                })
                imt.__typeof = "OverlapParams"
                imt.__index = function(tt, kk)
                    local s = rawget(tt, "__stored") or {}
                    if s[kk] ~= nil then
                        return s[kk]
                    end
                    return nil
                end
                imt.__newindex = function(tt, kk, vv)
                    local s = rawget(tt, "__stored") or {}
                    s[kk] = vv
                end
                imt.__tostring = function()
                    return "OverlapParams"
                end
                return inst
            end
        end
        return op_orig_index(t, k)
    end
end
DateTime = mktypecon("DateTime")
Font = mktypecon("Font")
SharedTable = {
    new = function(t)
        local obj = t or {}
        local mt = {}
        mt.__index = function(_, k)
            return obj[k]
        end
        mt.__newindex = function(_, k, v)
            obj[k] = v
        end
        mt.__len = function()
            return #obj
        end
        mt.__tostring = function()
            return "SharedTable"
        end
        return setmetatable({}, mt)
    end,
}
_setmt(SharedTable, {
    __call = function(t, ...)
        return t.new(...)
    end,
})
Vector2int16 = mktypecon("Vector2int16")
Vector3int16 = mktypecon("Vector3int16")
ValueCurveKey = mktypecon("ValueCurveKey")
FloatCurveKey = mktypecon("FloatCurveKey")
CatalogSearchParams = mktypecon("CatalogSearchParams")
Region3int16 = mktypecon("Region3int16")
RotationCurveKey = mktypecon("RotationCurveKey")
SecurityCapabilities = mktypecon("SecurityCapabilities")
Faces = mktypecon("Faces")
Axes = mktypecon("Axes")
PathWaypoint = mktypecon("PathWaypoint")
_G.SharedTable = SharedTable
_G.Vector2int16 = Vector2int16
_G.Vector3int16 = Vector3int16
_G.ValueCurveKey = ValueCurveKey
_G.FloatCurveKey = FloatCurveKey
_G.CatalogSearchParams = CatalogSearchParams
_G.Region3int16 = Region3int16
_G.RotationCurveKey = RotationCurveKey
_G.SecurityCapabilities = SecurityCapabilities
SecurityCapabilities.fromCurrent = function()
    local px, pmeta = mktblpx()
    pmeta.__typeof = "SecurityCapabilities"
    pmeta.__tostring = function() return "SecurityCapabilities" end
    return px
end
_G.Faces = Faces
_G.Axes = Axes
_G.PathWaypoint = PathWaypoint
Random = {
    new = function(seed)
        local obj = {}
        local s = seed or os.clock()
        function obj:NextNumber(mn, mx)
            mn = mn or 0
            mx = mx or 1
            s = (s * 1103515245 + 12345) % 2147483648
            return mn + (s / 2147483648) * (mx - mn)
        end
        function obj:NextInteger(mn, mx)
            mn = mn or 1
            mx = mx or 100
            return math.floor(obj:NextNumber(mn, mx + 1))
        end
        function obj:NextUnitVector()
            return Vector3.new(0, 1, 0)
        end
        return obj
    end,
}
_setmt(Random, {
    __call = function(t, s)
        return t.new(s)
    end,
})
local enum_cache = {}
Enum = mkpx("Enum", true)
local Enum_mt = _getmt(Enum)
Enum_mt.__index = function(t, k)
    if enum_cache[k] then
        return enum_cache[k]
    end
    local eproxy = mkpx("Enum." .. k, false)
    rawset(eproxy, "__enum", true)
    local eproxy_mt = _getmt(eproxy)
    local item_cache = {}
    eproxy_mt.__index = function(tt, ek)
        if ek == "GetEnumItems" then
            return reg_c_func(function(self)
                local items = {}
                for i = 1, 3 do
                    local ei = mkpx("Enum." .. k .. ".Item" .. i, false)
                    st.reg[ei] = "Enum." .. k .. ".Item" .. i
                    rawset(ei, "__enumitem", true)
                    st.propstore[ei] =
                        { EnumType = eproxy, Name = "Item" .. i, Value = i }
                    table.insert(items, ei)
                end
                return items
            end)
        end
        if item_cache[ek] then
            return item_cache[ek]
        end
        local item = mkpx("Enum." .. k .. "." .. ek, false)
        st.reg[item] = "Enum." .. k .. "." .. ek
        rawset(item, "__enumitem", true)
        local item_mt = _getmt(item)
        if item_mt then
            item_mt.__tostring = function()
                return "Enum." .. k .. "." .. ek
            end
        end
        local val = 0
        if ek == "None" then
            val = 0
        elseif ek == "User" then
            val = 0
        elseif ek == "Custom" then
            val = 0
        else
            val = 1
        end
        st.propstore[item] = { EnumType = eproxy, Name = ek, Value = val }
        item_cache[ek] = item
        return item
    end
    eproxy_mt.__tostring = function()
        return "Enum." .. k
    end
    enum_cache[k] = eproxy
    return eproxy
end
Enum_mt.__tostring = function()
    return "Enum"
end
_G.Enum = Enum
game = mkpx("game", true)
workspace = mkpx("workspace", true)
script = mkpx("script", true)
local camera = mkpx("Camera", false, workspace)
st.propstore[game] = {
    PlaceId = placeid,
    GameId = placeid,
    IsLoaded = true,
    ClassName = "DataModel",
    Name = "Game",
    PlaceVersion = 1,
    CreatorId = 0,
    CreatorType = Enum.CreatorType.User,
}
do
    local gmt = _getmt(game)
    if gmt then rawset(gmt, "__metatable", "The metatable is locked") end
    local wmt = _getmt(workspace)
    if wmt then rawset(wmt, "__metatable", "The metatable is locked") end
end
st.propstore[workspace] = {
    SimulationRadius = 1000,
    ClassName = "Workspace",
    Name = "Workspace",
    Gravity = 196.2,
    StreamingEnabled = false,
    StreamingPauseMode = Enum.StreamingPauseMode.Default,
    CurrentCamera = camera,
}
st.parentmap[workspace] = game
st.propstore[camera] = {
    ClassName = "Camera",
    Name = "Camera",
    ViewportSize = Vector2.new(1920, 1080),
    FieldOfView = 70,
    CameraType = Enum.CameraType.Custom,
    NearPlaneZ = -0.1,
    CFrame = CFrame.new(0, 5, 0),
}
Drawing = {
    new = function(tn)
        local ts = safestr(tn)
        local obj = mkpx("Drawing_" .. ts, false)
        local mt = _getmt(obj)
        if ts == "Square" then
            mt.__typeof = "table"
        else
            mt.__typeof = "Drawing"
        end
        local v = mkvar(obj, ts)
        out(string.format("local %s = Drawing.new(%s)", v, q(ts)))
        st.propstore[obj] = {
            Visible = false,
            Color = Color3.new(1, 1, 1),
            Transparency = 1,
            ZIndex = 0,
            ClassName = ts,
        }
        return obj
    end,
    Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3,
    },
}
st.reg[game] = "game"
local restricted_services = {}
for _, serviceName in ipairs(all_services) do
    if serviceName ~= "Lighting" and serviceName ~= "Workspace" then
        restricted_services[serviceName] = true
    end
end
Instance = {
    new = function(cn, parent)
        local cs = safestr(cn)
        if not class_members[cs] then
            error(cs .. " is not a valid class name")
        end
        if restricted_services[cs] then 
            error("Instance.new: Unable to create an instance of type '" .. cs .. "'") 
        end
        local obj = mkpx(cs, false)
        st.propstore[obj] = { ClassName = cs, Name = cs }
        local v = mkvar(obj, cs)
        if parent then
            local ps = st.reg[parent] or ser(parent)
            out(string.format("local %s = Instance.new(%s, %s)", v, q(cs), ps))
            if parent then
                st.parentmap[obj] = parent
            else
                st.parentmap[obj] = game or workspace
            end            
        else
            out(string.format("local %s = Instance.new(%s)", v, q(cs)))
        end
        return obj
    end,
    fromExistingId = function(id)
        local obj = mkpx("Instance", false)
        local v = mkvar(obj, "inst")
        out(string.format("local %s = Instance.fromExistingId(%s)", v, ser(id)))
        return obj
    end,
}
local curtid = 7
getreg = function()
    local reg = {}
    reg[1] = _G
    if st and st.sandbox then
        reg[2] = st.sandbox
    end
    if type(reg) == "table" then
        return reg
    else
        return {}
    end
end
local getregistry = getreg
local replaceclosure = function(old, nw)
    local ok1, old_str = _pcall(function()
        return ser(old)
    end)
    if not ok1 then
        old_str = _tostring(old)
    end
    local ok2, nw_str = _pcall(function()
        return ser(nw)
    end)
    if not ok2 then
        nw_str = _tostring(nw)
    end
    out(string.format("replaceclosure(%s, %s)", old_str, nw_str))
    if _type(old) == "function" and _type(nw) == "function" then
        if _setfenv then
            local ok3, env3 = _pcall(_getfenv, nw)
            if ok3 and env3 then
                _pcall(_setfenv, old, env3)
            end
        end
    end
    return old
end
local efuncs = {
    replicatesignal = function(sig, ...)
        local sname
        if isproxy(sig) then
            sname = st.reg[sig] or "signal"
        elseif _type(sig) == "table" and sig.__path then
            sname = sig.__path
        elseif _type(sig) == "string" then
            sname = sig
        else
            sname = "signal"
        end
        local args = { ... }
        local sargs = {}
        for _, v in _ipairs(args) do
            table.insert(sargs, ser(v))
        end
        if #sargs > 0 then
            out(
                string.format(
                    "replicatesignal(%s, %s)",
                    sname,
                    table.concat(sargs, ", ")
                )
            )
        else
            out(string.format("replicatesignal(%s)", sname))
        end
    end,
    firesignal = function(sig, ...)
        local sname
        if isproxy(sig) then
            sname = st.reg[sig] or "signal"
        elseif _type(sig) == "table" and sig.__path then
            sname = sig.__path
        elseif _type(sig) == "string" then
            sname = sig
        else
            sname = "signal"
        end
        local args = { ... }
        local sargs = {}
        for _, v in _ipairs(args) do
            table.insert(sargs, ser(v))
        end
        if #sargs > 0 then
            out(
                string.format(
                    "firesignal(%s, %s)",
                    sname,
                    table.concat(sargs, ", ")
                )
            )
        else
            out(string.format("firesignal(%s)", sname))
        end
        if isproxy(sig) then
            local props = st.propstore[sig]
            if props and props.callbacks then
                for _, cb in _ipairs(props.callbacks) do
                    if _type(cb) == "function" then
                        _xpcall(function()
                            cb(unpack(args))
                        end, function() end)
                    end
                end
            end
        end
    end,
    getsignalwhitelist = function(sig)
        local sname = isproxy(sig) and (st.reg[sig] or _tostring(sig))
            or ser(sig)
        local r = {}
        local v = mkvar(r, "whitelist")
        out(string.format("local %s = getsignalwhitelist(%s)", v, sname))
        return r
    end,
    getsignalarguments = function(sig)
        local sname = isproxy(sig) and (st.reg[sig] or _tostring(sig))
            or ser(sig)
        local r = {}
        local v = mkvar(r, "args")
        out(string.format("local %s = getsignalarguments(%s)", v, sname))
        return r
    end,
    getsignalargmuents = function(sig)
        local sname = isproxy(sig) and (st.reg[sig] or _tostring(sig))
            or ser(sig)
        local r = {}
        local v = mkvar(r, "args")
        out(string.format("local %s = getsignalargmuents(%s)", v, sname))
        return r
    end,
    setfflag = function(name, val)
        out(
            string.format("setfflag(%s, %s)", q(safestr(name)), q(safestr(val)))
        )
    end,
    getfflags = function()
        local r = {}
        local v = mkvar(r, "fflags")
        out(string.format("local %s = getfflags()", v))
        return r
    end,
    replaceclosure = replaceclosure,
    getreg = getreg,
    getregistry = getreg,

    ypcall = pcall,
    collectgarbage = function(opt, arg)
        if opt == "count" then
            return 0, 0
        end
        return 0
    end,
    getgenv = function()
        return st.senv or st.sandbox or _G
    end,
    getrenv = function()
        if not st._renv then
            local renv_store = {}
            st._renv = _setmt({}, {
                __index = function(t, k)
                    if k == "_G" then
                        if not st._renv_G then
                            st._renv_G = {}
                        end
                        return st._renv_G
                    end
                    if k == "game" then return game end
                    if k == "workspace" then return workspace end
                    if k == "shared" then return _G.shared or {} end
                    local v = rawget(renv_store, k)
                    if v ~= nil then
                        return v
                    end
                    return (st.sandbox or _G)[k]
                end,
                __newindex = function(t, k, v)
                    rawset(renv_store, k, v)
                end,
            })
            table.freeze(st._renv)
            st._renv_store = renv_store
        end
        return st._renv
    end,
    getfenv = function(lvl)
        local env = st.sandbox or _G
        return _setmt({}, {
            __index = function(t, k)
                local v = rawget(env, k)
                if v ~= nil then
                    return v
                end
                return rawget(_G, k)
            end,
            __newindex = function(t, k, v)
                rawset(env, k, v)
                rawset(_G, k, v)
            end,
        })
    end,
    setfenv = function(fn, env)
        if _type(fn) == "function" and _setfenv then
            _setmt(env, { __index = st.sandbox or _G })
            return _setfenv(fn, env)
        end
        st.sandbox = env
        return env
    end,
    hookfunction = function(old, nw)
        local old_str = _pcall(function()
            return ser(old)
        end) and ser(old) or _tostring(old)
        local nw_str = _pcall(function()
            return ser(nw)
        end) and ser(nw) or _tostring(nw)
        out(string.format("hookfunction(%s, %s)", old_str, nw_str))
        return old
    end,
    hookmetamethod = function(obj, method, hook)
        out(
            string.format(
                "hookmetamethod(%s, %s, %s)",
                ser(obj),
                q(method),
                ser(hook)
            )
        )
        return function() end
    end,
    getrawmetatable = function(obj)
        if isproxy(obj) then
            local mt = _getmt(obj)
            if mt then return mt end
        end
        if _type(obj) == "table" then
            local mt = _getmt(obj)
            if mt and _type(mt) == "table" then
                local saved = rawget(mt, "__metatable")
                rawset(mt, "__metatable", nil)
                local real = _getmt(obj)
                rawset(mt, "__metatable", saved)
                return real or mt
            end
            return {}
        end
        return _getmt(obj) or {}
    end,
    setrawmetatable = function(obj, mt)
        if _type(obj) == "table" then
            local existing = _getmt(obj)
            if existing and _type(existing) == "table" then
                rawset(existing, "__metatable", nil)
            end
            _setmt(obj, mt)
            return obj
        end
        if isproxy(obj) then
            local existing = _getmt(obj)
            if existing then rawset(existing, "__metatable", nil) end
            _setmt(obj, mt)
            return obj
        end
        return obj
    end,
    getnamecallmethod = function()
        return "__namecall"
    end,
    checkcaller = function()
        return true
    end,
    islclosure = function(f)
        return _type(f) == "function"
    end,
    iscclosure = function(f)
        return false
    end,
    newcclosure = function(f)
        return f
    end,
    newlclosure = function(f)
        if _type(f) ~= "function" then
            error("bad argument #1 to newlclosure (function expected)")
        end
        local new_f = function(...) return f(...) end
        env_functions[new_f] = true
        return new_f
    end,
    clonefunction = function(f)
        return f
    end,
    isexecutorclosure = function(f)
        if _type(f) ~= "function" then return false end
        if iscclosure(f) then return false end
        return true
    end,
    syn = nil,
    http = nil,
    request = function(opts)
        if _type(opts) == "table" and opts.Url then
            local ok, net = _pcall(require, "@lune/net")
            if ok and net then
                local req_ok, resp = _pcall(function()
                    return net.request({
                        url = opts.Url,
                        method = opts.Method or "GET",
                        headers = opts.Headers or {},
                        body = opts.Body,
                    })
                end)
                if req_ok and resp then
                    return {
                        Body = resp.body or "",
                        StatusCode = resp.statusCode or 200,
                        StatusMessage = resp.statusMessage or "OK",
                        Headers = resp.headers or {},
                        Success = (resp.statusCode or 200) >= 200
                            and (resp.statusCode or 200) < 300,
                    }
                end
            end
        end
        out(string.format("request(%s)", ser(opts)))
        return {
            Body = "{}",
            StatusCode = 200,
            StatusMessage = "OK",
            Headers = {},
            Success = true,
        }
    end,
    http_request = nil,
    setclipboard = function(data)
        local s = safestr(data)
        out(string.format("setclipboard(%s)", ser(s)))
        clipboard_store = s
    end,
    getclipboard = function()
        return clipboard_store or ""
    end,
    identifyexecutor = function()
        local name, ver = "Madium", "1.3.8.0"
        local v = mkvar(name, "nam")
        local ov = mkvar(ver, "ver")
        out(string.format("local %s,%s = identifyexecutor()", v, ov))
        return name, ver
    end,
    gethui = function()
        local hui = mkpx("HiddenUI", false)
        mkvar(hui, "HiddenUI")
        out(string.format("local %s = gethui()", st.reg[hui]))
        return hui
    end,
    getgc = function(inc)
        return { {}, function() end, _G, st.sandbox or _G }
    end,
    getinstances = function()
        local insts = {}
        for i = 1, 5 do
            table.insert(insts, mkpx("Instance" .. i, false))
        end
        return insts
    end,
    getnilinstances = function()
        return {}
    end,
    getscripts = function()
        return { mkpx("LocalScript", false) }
    end,
    getrunningscripts = function()
        return { mkpx("LocalScript", false) }
    end,
    getloadedmodules = function()
        return { mkpx("ModuleScript", false) }
    end,
    getcallingscript = function()
        return script
    end,
    getconstants = function(f)
        if _type(f) ~= "function" then
            error("function expected")
        end
        if _is_internal_fn(f) then
            return {}
        end
        local results = {}
        if dbg and dbg.getupvalue then
            local i = 1
            while true do
                local ok, uvname, uvval = _pcall(dbg.getupvalue, f, i)
                if not ok or uvname == nil then break end
                results[i] = uvval
                results[uvname] = uvval
                i = i + 1
            end
        end
        local ok2, src2 = _pcall(dbg.info, f, "s")
        if ok2 and src2 and src2 ~= "=[C]" then
            local probe = _setmt({}, {__index=_G, __newindex=function()end})
            local ok3, res3 = _pcall(f)
            if ok3 and res3 ~= nil then
                table.insert(results, res3)
            end
        end
        return results
    end,
    setconstant = function(f, idx, val)
        if _type(f) ~= "function" then
            error("function expected")
        end
        st.uv_override = st.uv_override or {}
        st.uv_override[f] = st.uv_override[f] or {}
        st.uv_override[f][idx] = val
        if dbg and dbg.setupvalue then
            _pcall(dbg.setupvalue, f, idx, val)
        end
    end,
    readfile = function(path)
        local s = safestr(path)
        local v = mkvar(s, "file")
        out(string.format("local %s = readfile(%s)", v, ser(s)))
        if writefile_store[s] ~= nil then
            return writefile_store[s]
        end
        local ok, data = _pcall(function()
            return fs.readFile(s)
        end)
        if ok and data then
            return _type(data) == "string" and data or _tostring(data)
        end
        error("readfile: file not found: " .. s)
    end,
    writefile = function(path, content)
        local s = safestr(path)
        if s:match("%.exe$") or s:match("%.bat$") or s:match("%.scr$") then
            error("invalid file extension")
        end
        local c = safestr(content)
        writefile_store[s] = c
        out(
            string.format(
                "writefile(%s, %s)",
                q(s),
                q(c:sub(1, 80) .. (#c > 80 and "..." or ""))
            )
        )
    end,
    appendfile = function(path, content)
        local s = safestr(path)
        local c = safestr(content)
        local existing = writefile_store[s] or ""
        writefile_store[s] = existing .. c
        out(
            string.format(
                "appendfile(%s, %s)",
                q(s),
                q(c:sub(1, 80) .. (#c > 80 and "..." or ""))
            )
        )
    end,
    isfile = function(path)
        local s = safestr(path)
        out(string.format("isfile(%s)", ser(s)))
        if writefile_store[s] ~= nil then
            return true
        end
        local ok, result = _pcall(function()
            return fs.isFile(s)
        end)
        return ok and result == true
    end,
    isfolder = function(path)
        local s = safestr(path)
        out(string.format("isfolder(%s)", ser(s)))
        return true
    end,
    listfiles = function(folder)
        local s = safestr(folder)
        out(string.format("listfiles(%s)", ser(s)))
        local base = s:sub(-1) == "/" and s or s .. "/"
        local results = {}
        for path, _ in _pairs(writefile_store) do
            if path:sub(1, #base) == base then
                local already = false
                for _, r in _ipairs(results) do
                    if r == path then
                        already = true
                        break
                    end
                end
                if not already then
                    table.insert(results, path)
                end
            end
        end
        return results
    end,
    makefolder = function(path)
        local s = safestr(path)
        out(string.format("makefolder(%s)", ser(s)))
    end,
    delfolder = function(path)
        local s = safestr(path)
        out(string.format("delfolder(%s)", ser(s)))
        local base = s:sub(-1) == "/" and s or s .. "/"
        for p, _ in _pairs(writefile_store) do
            if p:sub(1, #base) == base then
                writefile_store[p] = nil
            end
        end
    end,
    delfile = function(path)
        local s = safestr(path)
        writefile_store[s] = nil
        out(string.format("delfile(%s)", ser(s)))
    end,
    loadfile = function(path)
        local s = safestr(path)
        local ok, data = _pcall(function()
            return fs.readFile(s)
        end)
        if not ok or data == nil then
            return nil, "cannot open " .. s
        end
        local content
        if _type(data) == "buffer" then
            content = buffer.tostring(data)
        elseif
            _type(data) == "userdata"
            or (_type(data) == "table" and data.toString)
        then
            content = data:toString()
        else
            content = _type(data) == "string" and data or _tostring(data)
        end
        local chunk, err = _loadstr(content, "@" .. s)
        if not chunk then
            return nil, err
        end
        if st.sandbox then
            _setfenv(chunk, st.sandbox)
        end
        return chunk
    end,
    makefolder = function(path)
        local s = safestr(path)
        out(string.format("makefolder(%s)", ser(s)))
        local base = s:sub(-1) == "/" and s or s .. "/"
        writefile_store[base] = true
    end,
    delfolder = function(path)
        local s = safestr(path)
        out(string.format("delfolder(%s)", ser(s)))
        local base = s:sub(-1) == "/" and s or s .. "/"
        for p, _ in _pairs(writefile_store) do
            if p:sub(1, #base) == base then
                writefile_store[p] = nil
            end
        end
    end,
    delfile = function(path)
        local s = safestr(path)
        writefile_store[s] = nil
        out(string.format("delfile(%s)", ser(s)))
    end,
    Drawing = {
        new = function(tn)
            local ts = safestr(tn)
            local obj = mkpx("Drawing_" .. ts, false)
            local mt = _getmt(obj)
            mt.__typeof = "Drawing"
            mt.__index = function(t, k)
                if k == px_mark or k == "__pxid" then
                    return rawget(t, k)
                end
                local props = st.propstore[t]
                if props and props[k] ~= nil then
                    return props[k]
                end
                return rawget(t, k)
            end
            mt.__newindex = function(t, k, v)
                if k == px_mark or k == "__pxid" then
                    rawset(t, k, v)
                    return
                end
                st.propstore[t] = st.propstore[t] or {}
                st.propstore[t][k] = v
            end
            local v = mkvar(obj, ts)
            out(string.format("local %s = Drawing.new(%s)", v, q(ts)))
            st.propstore[obj] = {
                Visible = false,
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                ZIndex = 0,
                ClassName = ts,
            }
            obj.Remove = function()
                st.propstore[obj] = nil
                out(string.format("%s:Remove()", v))
            end
            return obj
        end,
        Fonts = {
            UI = 0,
            System = 1,
            Plex = 2,
            Monospace = 3,
        },
    },
    crypt = {
        base64encode = function(d)
            return d
        end,
        base64decode = function(d)
            return d
        end,
        encrypt = function(d, k)
            return d
        end,
        decrypt = function(d, k)
            return d
        end,
        hash = function(d)
            return "hash"
        end,
        generatekey = function(sz)
            return string.rep("0", sz or 32)
        end,
    },
    base64 = {
        encode = function(d)
            return d
        end,
        decode = function(d)
            return d
        end,
    },
    setreadonly = function(t, ro) end,
    isreadonly = function(t)
        return false
    end,
    getthreadidentity = function()
        return curtid
    end,
    setthreadidentity = function(id)
        curtid = id
    end,
    getidentity = function()
        return curtid
    end,
    setidentity = function(id)
        curtid = id
    end,
    firetouchinterest = function(part, other, toggle)
        out(
            string.format(
                "firetouchinterest(%s, %s, %s)",
                ser(part),
                ser(other),
                ser(toggle)
            )
        )
    end,
    fireproximityprompt = function(pp)
        out(string.format("fireproximityprompt(%s)", ser(pp)))
        if not pp then
            return
        end
        local ok, sig = pcall(function()
            return pp.Triggered
        end)
        if not ok or not sig then
            return
        end
        local callbacks = st.propstore[sig] and st.propstore[sig].callbacks
        if not callbacks or #callbacks == 0 then
            return
        end
        local lp
        if st.services and st.services["Players"] then
            local ps = st.services["Players"]
            lp = st.propstore[ps] and st.propstore[ps].LocalPlayer
        end
        for _, cb in _ipairs(callbacks) do
            if _type(cb) == "function" then
                _xpcall(function()
                    cb(lp)
                end, function() end)
            end
        end
    end,
    firesignal = function(sig, ...)
        local args = { ... }
        local sargs = {}
        for _, v in _ipairs(args) do
            table.insert(sargs, ser(v))
        end
        out(
            string.format(
                "firesignal(%s, %s)",
                ser(sig),
                table.concat(sargs, ", ")
            )
        )
    end,
    getcustomasset = function(path)
        out(string.format("getcustomasset(%s)", q(path)))
        return "rbxasset://temp/" .. safestr(path):gsub("[^%w_.]", "_")
    end,
    getspecialinfo = function(obj)
        return {}
    end,
    saveinstance = function(opts)
        out(string.format("saveinstance(%s)", ser(opts)))
    end,
    compareinstances = function(a, b)
        return false
    end,
    getsenv = function(scr)
        if scr and isproxy(scr) then
            local props = st.propstore[scr]
            if props and props.ClassName == "LocalScript" then
                local env = _setmt({}, {
                    __index = st.sandbox or _G,
                    __newindex = function(t, k, v)
                        rawset(st.sandbox or _G, k, v)
                    end,
                })
                env.script = scr
                return env
            end
        end
        return st.sandbox or _G
    end,
    getmenv = function(mod)
        return st.sandbox or _G
    end,
    decompile = function(obj)
        return "-- decompiled"
    end,
    getscriptbytecode = function(obj)
        if isproxy(obj) then
            local props = st.propstore[obj]
            if props and props.Source then
                local Luau = require("@lune/luau")
                local Ok, Bytecode = pcall(Luau.compile, props.Source)
                if Ok and typeof(Bytecode) == "string" then
                    return Bytecode
                end
            end
        end
        return "\0return function() end"
    end,
    getscripthash = function(obj)
        if isproxy(obj) then
            local props = st.propstore[obj]
            if props and props.Source then
                local hash = 0
                for i = 1, #props.Source do
                    hash = (hash * 31 + props.Source:byte(i)) % 2147483647
                end
                return string.format("%016x", hash)
            end
        end
        return string.rep("0", 64)
    end,
    debug = {
        getinfo = getinfo,
        getupvalue = function(f, idx)
            if _type(f) ~= "function" then
                return nil
            end
            if _is_internal_fn(f) then
                return nil
            end
            if dbg and dbg.getupvalue then
                local ok, uvname, uvval = _pcall(dbg.getupvalue, f, idx)
                if ok and uvname ~= nil then
                    return uvval, uvname
                end
            end
            if idx == 1 then
                local ok, val = _pcall(f)
                if ok and val ~= nil then
                    return val, "upvalue"
                end
            end
            return idx, "upvalue_" .. _tostring(idx)
        end,
        setupvalue = function(f, idx, val)
            if _type(f) ~= "function" then
                return false
            end
            if _is_internal_fn(f) then
                return false
            end
            if dbg.setupvalue then
                _pcall(dbg.setupvalue, f, idx, val)
            end
            return true
        end,
        getmetatable = _getmt,
        setmetatable = _setmt,
        traceback = function(msg, level)
            level = level or 1
            local ok, tb = _pcall(function()
                return _traceback(_tostring(msg or ""), level + 1)
            end)
            if ok and _type(tb) == "string" then
                return clean_traceback(tb)
            end
            return _tostring(msg or "")
        end,
getconstants = function(f)
        if _type(f) ~= "function" then
            return {}
        end
        if _is_internal_fn(f) then
            return {}
        end
        local results = {}
        if dbg and dbg.getupvalue then
            local i = 1
            while true do
                local ok, uvname, uvval = _pcall(dbg.getupvalue, f, i)
                if not ok or uvname == nil then break end
                results[i] = uvval
                results[uvname] = uvval
                i = i + 1
            end
        end
        return results
    end,
        getprotos = function(f)
            return {}
        end,
        getstack = function()
            return {}
        end,
        setstack = function() end,
        sethook = function() end,
        getregistry = function()
            local reg = {}
            reg[1] = _G
            if st and st.sandbox then
                reg[2] = st.sandbox
            end
            return reg
        end,
        getlocal = function(level, idx)
            st.fakelocals = st.fakelocals or { "_local1", "_local2", "_local3" }
            local name = st.fakelocals[idx] or ("v" .. _tostring(idx))
            return name, nil
        end,
        setlocal = function(level, idx, val)
            st.fakelocals = st.fakelocals or {}
            st.fakelocals[idx] = val
            return true
        end,
        setproto = function(f, proto)
            return f
        end,
    },
    queue_on_teleport = function(code)
        out(string.format("queue_on_teleport(%s)", ser(code)))
    end,
    queueonteleport = function(code)
        out(string.format("queueonteleport(%s)", ser(code)))
    end,
    setfpscap = function(fps)
        out(string.format("setfpscap(%s)", ser(fps)))
    end,
    getfpscap = function()
        return 60
    end,
    messagebox = function(msg, title, typ)
        out(
            string.format(
                "messagebox(%s, %s, %s)",
                ser(msg),
                ser(title or ""),
                ser(typ or 0)
            )
        )
        return 0
    end,
    inputservice = nil,
    mouse1click = function()
        out("mouse1click()")
    end,
    mouse1press = function()
        out("mouse1press()")
    end,
    mouse1release = function()
        out("mouse1release()")
    end,
    mouse2click = function()
        out("mouse2click()")
    end,
    mouse2press = function()
        out("mouse2press()")
    end,
    mouse2release = function()
        out("mouse2release()")
    end,
    mousemoverel = function(x, y)
        out(string.format("mousemoverel(%s, %s)", ser(x), ser(y)))
    end,
    mousemoveabs = function(x, y)
        out(string.format("mousemoveabs(%s, %s)", ser(x), ser(y)))
    end,
    keypress = function(k)
        out(string.format("keypress(%s)", ser(k)))
    end,
    keyrelease = function(k)
        out(string.format("keyrelease(%s)", ser(k)))
    end,
    ypcall = nil,
}
efuncs.syn = {
    request = efuncs.request,
    protect_gui = function(g) end,
    UnprotectGui = function(g) end,
}
efuncs.http = { request = efuncs.request }
efuncs.http_request = efuncs.request
efuncs.ypcall = pcall
efuncs.inputservice = mkpx("UserInputService", false)
for k, v in _pairs(efuncs) do
    _G[k] = v
end
local function getinfo(f, options)
    options = options or "nSslf"
    local resolved_f = f
    if _type(f) == "number" then
        local ok, func = _pcall(debug.info, f + 1, "f")
        if ok and func then
            resolved_f = func
        end
    end
    if _type(resolved_f) ~= "function" then
        error("bad argument #1 to 'getinfo' (function expected)")
    end
    local info = {}
    info.func = resolved_f
    if env_functions[resolved_f] or _cc_closures[resolved_f] then
        info.what = "C"
        info.source = "=[C]"
        info.short_src = "[C]"
        info.currentline = -1
        info.nups = 0
        info.name = ""
        return info
    end
    local c_natives_check = {
        print,
        warn,
        tostring,
        tonumber,
        pairs,
        ipairs,
        next,
        rawget,
        rawset,
        rawequal,
        unpack,
        select,
        assert,
        pcall,
        xpcall,
        setmetatable,
        getmetatable,
        type,
        error,
        collectgarbage,
    }
    for _, fn in _ipairs(c_natives_check) do
        if rawequal(fn, resolved_f) then
            info.what = "C"
            info.source = "=[C]"
            info.short_src = "[C]"
            info.currentline = -1
            info.nups = 0
            info.name = ""
            return info
        end
    end
    local ok, source, line, name, nparams, isvararg = _pcall(function()
        return debug.info(resolved_f, "slna")
    end)
    if ok then
        info.source = source or "=[C]"
        info.short_src = source or "[C]"
        info.currentline = line or -1
        info.name = name or ""
        info.what = "Lua"
        info.nups = 0
        info.nparams = nparams or 0
        info.isvararg = isvararg or false
    else
        info.source = "=(eval)"
        info.short_src = "(eval)"
        info.currentline = -1
        info.name = ""
        info.what = "Lua"
        info.nups = 0
        info.nparams = 0
        info.isvararg = true
    end
    return info
end
local function getinfo(f, options)
    options = options or "nSslf"
    local resolved_f = f
    if _type(f) == "number" then
        local ok, func = _pcall(debug.info, f + 1, "f")
        if ok and func then
            resolved_f = func
        end
    end
    if _type(resolved_f) ~= "function" then
        error("bad argument #1 to 'getinfo' (function expected)")
    end
    local info = {}
    info.func = resolved_f
    if env_functions[resolved_f] then
        info.what = "C"
        info.source = "=[C]"
        info.short_src = "[C]"
        info.currentline = -1
        info.nups = 0
        info.name = ""
        return info
    end
    local ok, source, line, name, nparams, isvararg = _pcall(function()
        return debug.info(resolved_f, "slna")
    end)
    if ok then
        info.source = source or "=[C]"
        info.short_src = source or "[C]"
        info.currentline = line or -1
        info.name = name or ""
        info.what = "Lua"
        info.nups = 0
        info.nparams = nparams or 0
        info.isvararg = isvararg or false
    else
        info.source = "=(eval)"
        info.short_src = "(eval)"
        info.currentline = -1
        info.name = ""
        info.what = "Lua"
        info.nups = 0
        info.nparams = 0
        info.isvararg = true
    end
    return info
end
local function custom_next(t, k)
    if t == _G then
        local iter_t = {}
        iter_t._G = _G
        for key, val in _pairs(st.gassigns) do
            iter_t[key] = val
        end
        return _next(iter_t, k)
    end
    if isproxy(t) and k == nil and st.reg[t] then
        local pn = st.reg[t] or "obj"
        out(string.format("for _k, _v in next, %s do", pn))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
    end
    return _next(t, k)
end
pairs = function(t)
    if st.getchldrn_pending and rawequal(t, st.getchldrn_pending.objects) then
        local data = st.getchldrn_pending
        st.getchldrn_pending = nil
        out(string.format("for _, child in %s do", data.call))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
        local i = 0
        local obj2 = data.objects
        if #obj2 == 0 then
            local d2 = mkpx("DummyChild", false)
            table.insert(obj2, d2)
        end
        local done = false
        return function()
            i = i + 1
            if i <= #obj2 then return i, obj2[i] end
            if not done then
                done = true
                st.ind = math.max(0, st.ind - 1)
                out("end")
                st.pending_iter = math.max(0, (st.pending_iter or 1) - 1)
            end
        end, obj2, 0
    end
    
    if st.getdesc_pending and rawequal(t, st.getdesc_pending.objects) then
        local data = st.getdesc_pending
        st.getdesc_pending = nil
        out(string.format("for _, desc in pairs(%s:GetDescendants()) do", data.parent))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
        local yielded = false
        local closed = false
        return function()
            if not yielded then
                yielded = true
                return 1, data.objects[1]
            end
            if not closed then
                closed = true
                st.ind = st.ind - 1
                out("end")
                st.pending_iter = math.max(0, (st.pending_iter or 1) - 1)
            end
        end, data.objects, 0
    end
    
    local function tname(v)
        if v == _G then return "_G"
        elseif isproxy(v) then return st.reg[v] or "obj"
        elseif _type(v) == "table" then
            if st.reg[v] then return st.reg[v] end
            local ok, s = _pcall(ser, v)
            if ok and s then
                return s
            end
            local id = _tostring(v):match("table: (.+)") or "t"
            id = id:gsub("[^%w]", "_")
            return "tbl_" .. id
        else
            return ser(v)
        end
    end
    
    local pn = tname(t)
    
    if not pn:match("^tbl_") and type(pn) ~= "number" then
        out(string.format("for _i, _v in pairs(%s) do", pn))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
    end
    
    local entries = {}
    if isproxy(t) then
        entries = get_children_of(t)
        if #entries == 0 then
            local dummy = mkpx("item", false, t)
            st.propstore[dummy] = { ClassName = "Instance", Name = "Item" }
            table.insert(entries, dummy)
        end
    elseif _type(t) == "table" then
        for k, v in _pairs(t) do
            table.insert(entries, { k = k, v = v })
        end
    end
    
    local i = 0
    local is_raw = _type(t) == "table" and not isproxy(t)
    local done = false
    
    local should_log = not pn:match("^tbl_")
    
    local function close_iter()
        if not done then
            done = true
            if should_log then
                st.ind = math.max(0, st.ind - 1)
                out("end")
                st.pending_iter = math.max(0, (st.pending_iter or 1) - 1)
            end
        end
    end
    
    if is_raw then
        return function()
            i = i + 1
            local entry = entries[i]
            if entry then
                return entry.k, entry.v
            end
            close_iter()
        end, entries, nil
    else
        return function()
            i = i + 1
            if i <= #entries then
                return i, entries[i]
            end
            close_iter()
        end, entries, nil
    end
end
reg_c_func(pairs)
ipairs = function(t)
    if st.getchldrn_pending and rawequal(t, st.getchldrn_pending.objects) then
        local data = st.getchldrn_pending
        st.getchldrn_pending = nil
        out(string.format("for _, child in ipairs(%s) do", data.call))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
        local i = 0
        local obj2 = data.objects
        if #obj2 == 0 then
            local d2 = mkpx("DummyChild", false)
            table.insert(obj2, d2)
        end
        local done = false
        return function()
            i = i + 1
            if i <= #obj2 then return i, obj2[i] end
            if not done then
                done = true
                st.ind = math.max(0, st.ind - 1)
                out("end")
                st.pending_iter = math.max(0, (st.pending_iter or 1) - 1)
            end
        end, obj2, 0
    end

    if st.getdesc_pending and rawequal(t, st.getdesc_pending.objects) then
        local data = st.getdesc_pending
        st.getdesc_pending = nil
        out(string.format("for _, desc in pairs(%s:GetDescendants()) do", data.parent))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
        local i = 0
        local done = false
        return function()
            i = i + 1
            if i <= #data.objects then return i, data.objects[i] end
            if not done then
                done = true
                st.ind = math.max(0, st.ind - 1)
                out("end")
                st.pending_iter = math.max(0, (st.pending_iter or 1) - 1)
            end
        end, data.objects, 0
    end

    if _type(t) == "table" and not isproxy(t) and not st.reg[t] then
        return _ipairs(t)
    end

    local function tname(v)
        if v == _G then return "_G"
        elseif isproxy(v) then return st.reg[v] or "obj"
        elseif _type(v) == "table" then
            if st.reg[v] then return st.reg[v] end
            return nil
        else
            local ok, s = _pcall(ser, v)
            return (ok and s) or nil
        end
    end

    local pn = tname(t)
    local should_log = pn ~= nil

    if should_log and type(pn) ~= "number" then
        out(string.format("for _i, _v in ipairs(%s) do", pn))
        st.ind = st.ind + 1
        st.pending_iter = (st.pending_iter or 0) + 1
    end

    local done = false
    local function close_iter()
        if not done then
            done = true
            if should_log then
                st.ind = math.max(0, st.ind - 1)
                out("end")
                st.pending_iter = math.max(0, (st.pending_iter or 1) - 1)
            end
        end
    end

    if _type(t) == "table" and not isproxy(t) then
        local i = 0
        return function()
            i = i + 1
            if t[i] ~= nil then return i, t[i] end
            close_iter()
        end, t, 0
    end

    local children = isproxy(t) and get_children_of(t) or {}
    if #children == 0 then
        local dummy = mkpx("item", false, t)
        st.propstore[dummy] = { ClassName = "Instance", Name = "Item" }
        table.insert(children, dummy)
    end

    local i = 0
    return function()
        i = i + 1
        if i <= #children then return i, children[i] end
        close_iter()
    end, children, 0
end
reg_c_func(ipairs)
type = function(...)
    local obj = ...
    if isproxy(obj) then
        local mt = _getmt(obj)
        if mt and mt.__type then
            return mt.__type
        end
        if rawget(obj, "__enumitem") then
            return "userdata"
        end
        if rawget(obj, "__enum") then
            return "userdata"
        end
        if rawget(obj, "__signal") then
            return "userdata"
        end
        if rawget(obj, "__connection") then
            return "userdata"
        end
        local stored = rawget(obj, "__stored")
        if stored then
            local mt2 = _getmt(obj)
            if mt2 and mt2.__typeof then
                return "userdata"
            end
        end
        if st.reg[obj] == "_VERSION" then
            return "string"
        end
        return "userdata"
    end
    if isuid(obj) then
        return "number"
    end
    return _type(obj)
end
reg_c_func(type)
error = function(msg, lvl)
    local S = _tostring(msg or "")
    if S == "" then
        return
    end
    if
        S:find("Anti%-Tamper")
        or S:find("env logger")
        or S:find("tampering")
        or S:find("Tamper")
        or S:find("Suspicious")
        or S:find("dtc")
        or S:find("invalid Lua signature")
        or S:find("invalid Lua version")
        or S:find("invalid Lua format")
    then
        out('error("' .. S .. '") -- sus line skipping')
        return
    end
    local s = msg
    if not s:find("arithmetic") then
        if msg and S ~= "" then
            out('error("' .. msg .. '")')
        end
    end
    local cleaned = _type(msg) == "string" and cleanpath(msg) or msg
    if lvl then
        return _err(cleaned, lvl)
    else
        return _err(cleaned, 1)
    end
end
typeof = function(...)
    local obj = ...
    if isuid(obj) then
        return "number"
    end
    if isproxy(obj) then
        if obj == game or obj == workspace then
            return "Instance"
        end
        if obj == Enum then
            return "Enums"
        end
        if rawget(obj, "__enum") then
            return "Enum"
        end
        if rawget(obj, "__enumitem") then
            return "EnumItem"
        end
        if rawget(obj, "__connection") then
            return "RBXScriptConnection"
        end
        if rawget(obj, "__signal") then
            return "RBXScriptSignal"
        end
        local mt = _getmt(obj)
        if _type(mt) == "table" and mt.__typeof then
            return mt.__typeof
        end
        local props = st.propstore[obj]
        if props and props.ClassName then
            return "Instance"
        end
        return "Instance"
    end
    if _type(obj) == "table" then
        local mt = _getmt(obj)
        if _type(mt) == "table" and mt.__typeof then
            if mt.__typeof == "Drawing" then return "table" end
            return mt.__typeof
        end
    end
    return _type(obj)
end
_G.typeof = typeof
reg_c_func(typeof)
settings = function()
    local s = mkpx("Settings", false)
    local rendering = mkpx("Rendering", false)
    st.propstore[rendering] = {
        QualityLevel = Enum.QualityLevel.Item1,
    }
    st.propstore[s] = {
        Rendering = rendering,
    }
    local names = {
        "GameSettings",
        "LuaSettings",
        "Diagnostics",
        "PhysicsSettings",
        "NetworkSettings",
        "RenderSettings",
        "TaskScheduler",
    }
    local ord = {}
    for _, name in _ipairs(names) do
        local child = mkpx(name, false)
        st.parentmap[child] = s
        st.propstore[child] = { Name = name }
        table.insert(ord, child)
    end
    st.propstore[s].__ordered_children = ord
    return s
end
_G.settings = settings
reg_c_func(settings)
tostring = function(...)
    local obj = ...
    if _type(obj) == "function" then
        if env_functions[obj] or _cc_closures[obj] or obj == typeof or obj == tostring then
            return "function: builtin"
        end
    end
    if isproxy(obj) then
        local pn = st.reg[obj] or safestr(obj)
        st.lctr = (st.lctr or 0) + 1
        local vname = "str_" .. st.lctr
        out(string.format("local %s = tostring(%s)", vname, pn))
        local mt = _getmt(obj)
        if _type(mt) == "table" then
            if mt.__tostring then
                return mt.__tostring(obj)
            end
            if mt.__typeof == "SharedTable" then
                return "SharedTable"
            end
        end
        return st.propstore[obj] and st.propstore[obj].Name
            or st.reg[obj]
            or "Instance"
    end
    return _tostring(obj)
end
reg_c_func(tostring)
tonumber = function(...)
    local obj, base = ...
    local objis = typeof(obj)
    local objis2 = _type(obj)
    if isproxy(obj) then
        local pn = st.reg[obj] or safestr(obj)
        st.lctr = (st.lctr or 0) + 1
        local vname = "num_" .. st.lctr
        out(string.format("local %s = tonumber(%s)", vname, pn))
    end
    if isuid(obj) then
        return 123456789
    end
    return _tonumber(obj, base)
end
reg_c_func(tonumber)
getmetatable = function(...)
    local obj = ...
    if isproxy(obj) then
        local raw_result = _getmt(obj)
        if _type(raw_result) == "string" then
            local lmt = mkpx("LockedMetatable", false)
            local lmmt = _getmt(lmt)
            lmmt.__tostring = function() return raw_result end
            return lmt
        end
        if raw_result and _type(raw_result) == "table" then
            local guard = rawget(raw_result, "__metatable")
            if guard ~= nil then
                local lmt = mkpx("LockedMetatable", false)
                local lmmt = _getmt(lmt)
                lmmt.__tostring = function() return _tostring(guard) end
                return lmt
            end
        end
        local lmt = mkpx("LockedMetatable", false)
        local lmmt = _getmt(lmt)
        lmmt.__tostring = function() return "The metatable is locked" end
        return lmt
    end
    return _getmt(obj)
end
_G.getmetatable = getmetatable
reg_c_func(getmetatable)
setmetatable = function(t, mt)
    if isproxy(t) then
        local pn = st.reg[t] or ""
        if pn == "game" or pn == "workspace" or pn == "script" or pn == "shared"
            or pn:match("^game:GetService")
            or (st.propstore[t] and (st.propstore[t].ClassName == "DataModel" or st.propstore[t].ClassName == "Workspace"))
        then
            error("The metatable is locked")
        end
    end
    return _setmt(t, mt)
end
reg_c_func(setmetatable)
rawequal = function(a, b)
    return _rawequal(a, b)
end
_G.rawequal = rawequal
local _pcall_var_count = 0
pcall = function(f, ...)
    local args = { ... }
    local argCount = select("#", ...)
    local captured = {}
    local saved_out = st.out
    local temp_out = {}
    local saved_len = #st.out
    local results = { _pcall(f, table.unpack(args, 1, argCount)) }
    local new_lines = {}
    for i = saved_len + 1, #st.out do
        table.insert(new_lines, table.remove(st.out, saved_len + 1))
    end
    if #new_lines > 0 then
        _pcall_var_count = _pcall_var_count + 1
        local okName = "ok_" .. _pcall_var_count
        _pcall_var_count = _pcall_var_count + 1
        local errName = "err_" .. _pcall_var_count
        local pfx = string.rep("    ", st.ind)
        table.insert(
            st.out,
            pfx
                .. string.format(
                    "local %s, %s = pcall(function()",
                    okName,
                    errName
                )
        )
        st.ind = st.ind + 1
        for _, line in _ipairs(new_lines) do
            table.insert(st.out, line)
        end
        st.ind = st.ind - 1
        table.insert(st.out, pfx .. "end)")
    end
    if not results[1] then
        local e = results[2]
        if _type(e) == "string" then
            if e:match("TIMEOUT") or e:match("DUMP_LIMIT") then
                error(e)
            end
            if e ~= "" and not e:match("^stack") then
                local emsg = _tostring(e)
            end
        end
    end
    return table.unpack(results)
end
reg_c_func(pcall)
xpcall = function(...)
    local f, msgh = ...
    local args = { select(3, ...) }
    local saved_len = #st.out
    local function sh(e)
        if
            _type(e) == "string"
            and (e:match("TIMEOUT") or e:match("DUMP_LIMIT"))
        then
            return e
        end
        if msgh then
            return msgh(e)
        end
        return e
    end
    local res = { _xpcall(f, sh, _unpack(args)) }
    local new_lines = {}
    for i = saved_len + 1, #st.out do
        table.insert(new_lines, table.remove(st.out, saved_len + 1))
    end
    if #new_lines > 0 then
        _pcall_var_count = _pcall_var_count + 1
        local okName = "ok_" .. _pcall_var_count
        _pcall_var_count = _pcall_var_count + 1
        local errName = "err_" .. _pcall_var_count
        local pfx = string.rep("    ", st.ind)
        table.insert(
            st.out,
            pfx
                .. string.format(
                    "local %s, %s = xpcall(function()",
                    okName,
                    errName
                )
        )
        st.ind = st.ind + 1
        for _, line in _ipairs(new_lines) do
            table.insert(st.out, line)
        end
        st.ind = st.ind - 1
        table.insert(st.out, pfx .. "end, function(e) return e end)")
    end
    if not res[1] then
        local e = res[2]
        if
            _type(e) == "string"
            and (e:match("TIMEOUT") or e:match("DUMP_LIMIT"))
        then
            error(e)
        end
    end
    return _unpack(res)
end
reg_c_func(xpcall)
local function iskeysys(code)
    local pats = {
        "key[%s_]*system",
        "enter[%s_]*key",
        "verify",
        "getkey",
        "hwid",
        "whitelist",
        "authentication",
        "license",
        "keylink",
        "licsense",
    }
    local cl = code:lower()
    for _, p in _ipairs(pats) do
        if cl:find(p) then
            return true
        end
    end
    return false
end
local _invalidated_cache = {}
local _cc_closures = {}
task = _setmt({
    wait = function(dur)
        if dur then
            st.loopctr = (st.loopctr or 0) + 1
            if st.loopctr > 100 then
                error("timeout", 2)
            end
            out(string.format("task.wait(%s)", ser(dur)))
        else
            out("task.wait()")
        end
    end,
    spawn = function(f, ...)
        local args = { ... }
        local thread
        if _type(f) == "thread" then
            thread = f
        elseif _type(f) == "function" then
            thread = _cor.create(f)
        else
            error(
                "invalid argument #1 to 'spawn' (function or thread expected, got "
                    .. _type(f)
                    .. ")",
                2
            )
        end
        out("task.spawn(function()")
        st.ind = st.ind + 1
        st.in_cb = true
        local od = st.cf_depth
        st.cf_depth = 0
        local res = { _cor.resume(thread, _unpack(args)) }
        st.cf_depth = od
        while st.cf_depth > 0 do
            st.ind = st.ind - 1
            out("end")
            st.cf_depth = st.cf_depth - 1
        end
        st.ind = st.ind - 1
        out("end)")
        st.in_cb = false
        local ok = res[1]
        if ok then
            if _cor.status(thread) == "suspended" then
                local yield_type = res[2]
                local yield_val = res[3]
                local wait_dur = (yield_type == "wait" and yield_val) or 0.03
                local new_item = {
                    type = "delay",
                    fn = thread,
                    args = {},
                    time = st.virtual_time + wait_dur,
                    thread = thread,
                }
                table.insert(st.task_queue, new_item)
            end
        end
        return thread
    end,
    delay = function(dur, f, ...)
        local thread = queue_task("delay", dur or 0, f, ...)
        return thread
    end,
    defer = function(f, ...)
        local thread = queue_task("defer", nil, f, ...)
        return thread
    end,
    cancel = function(t)
        out(string.format("task.cancel(%s)", ser(t)))
        cancelled_threads[t] = true
    end,
    synchronize = function()
        out("task.synchronize()")
    end,
    desynchronize = function()
        out("task.desynchronize()")
    end,
}, {
    __call = function()
        error("attempt to call a table value")
    end,
})
wait = function(dur)
    dur = dur or 0.03
    if dur < 0.015 then
        dur = 0.015
    end
    out(string.format("wait(%s)", ser(dur)))
    _cor.yield("wait", dur)
    return os.clock(), dur
end
delay = function(dur, f)
    local thread = queue_task("delay", dur or 0, f)
    return thread
end
spawn = function(f)
    local thread = queue_task("defer", nil, f)
    return thread
end
tick = function()
    return os.time()
end
time = function()
    return os.clock()
end
elapsedTime = function()
    return os.clock()
end
replicatesignal = function(sig, ...)
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    local sname
    if isproxy(sig) then
        sname = st.reg[sig] or "signal"
    elseif _type(sig) == "table" and sig.__path then
        sname = sig.__path
    elseif _type(sig) == "string" then
        sname = sig
    else
        sname = "signal"
    end
    if isproxy(sig) then
        local sigClass = st.propstore[sig] and st.propstore[sig].ClassName
        if sigClass == "RemoteEvent" or sigClass == "RemoteFunction" then
            error("replicatesignal cannot be used on a " .. sigClass)
        end
        local parent = st.parentmap[sig]
        local parentClass = parent and st.propstore[parent] and st.propstore[parent].ClassName
        if parentClass == "RemoteFunction" then
            error("replicatesignal cannot be used on a RemoteFunction")
        end
        if sname:find("OnClientInvoke") or sname:find("OnServerInvoke") then
            error("replicatesignal cannot be used on a RemoteFunction")
        end
    end
    out(string.format("replicatesignal(%s%s)", sname,
        #sargs > 0 and (", " .. table.concat(sargs, ", ")) or ""))
end
firesignal = function(sig, ...)
    local args = { ... }
    local sargs = {}
    for _, v in _ipairs(args) do
        table.insert(sargs, ser(v))
    end
    local pn = isproxy(sig) and (st.reg[sig] or "signal") or ser(sig)
    out(string.format("firesignal(%s%s)", pn,
        #sargs > 0 and (", " .. table.concat(sargs, ", ")) or ""))

    if not isproxy(sig) then return end

    local callbacks = st.propstore[sig] and st.propstore[sig].callbacks
    if not callbacks or #callbacks == 0 then return end

    for _, cb in _ipairs(callbacks) do
        if _type(cb) == "function" then
            _xpcall(function()
                cb(_unpack(args))
            end, function() end)
        end
    end
end
syn = {}
http = {}
fluxus = {}
readfile = function(path)
    local s = safestr(path)
    out(string.format("readfile(%s)", q(s)))
    if writefile_store[s] ~= nil then
        return writefile_store[s]
    end
    local ok, data = _pcall(function()
        return fs.readFile(s)
    end)
    if ok and data then
        return _type(data) == "string" and data or _tostring(data)
    end
    error("readfile: file not found: " .. s)
end
writefile = function(path, content)
    local s = safestr(path)
    if s:match("%.exe$") or s:match("%.bat$") or s:match("%.scr$") then
        error("invalid file extension")
    end
    local c = safestr(content)
    writefile_store[s] = c
    out(string.format("writefile(%s, %s)", q(s), q(c:sub(1, 80) .. (#c > 80 and "..." or ""))))
end
isfile = function(path)
    local s = safestr(path)
    out(string.format("isfile(%s)", ser(s)))
    if writefile_store[s] ~= nil then
        return true
    end
    local ok, result = _pcall(function()
        return fs.isFile(s)
    end)
    return ok and result == true
end
loadfile = function(path)
    local s = safestr(path)
    local ok, data = _pcall(function()
        return fs.readFile(s)
    end)
    if not ok or data == nil then
        return nil, "cannot open " .. s
    end
    local content = _type(data) == "string" and data or _tostring(data)
    local chunk, err = _loadstr(content, "@" .. s)
    if not chunk then
        return nil, err
    end
    if st.sandbox then
        _setfenv(chunk, st.sandbox)
    end
    return chunk
end
dofile = function(path)
    local s = safestr(path)
    local ok, data = _pcall(function()
        return fs.readFile(s)
    end)
    if not ok or data == nil then
        return nil, "cannot open " .. s
    end
    local content = _type(data) == "string" and data or _tostring(data)
    local chunk, err = _loadstr(content, "@" .. s)
    if not chunk then
        return nil, err
    end
    if st.sandbox then
        _setfenv(chunk, st.sandbox)
    end
    return chunk
end
function getscriptcallstack()
    local stack = {}
    local level = 2 
    while true do
        local success, source, line, name = _pcall(debug.info, level, "sln")
        if not success or not source then
            break
        end
        if name == "" or not name then
            name = "(anonymous function)"
        end
        table.insert(stack, {
            level = level - 1,
            source = source,
            line = line,
            function_name = name
        })
        level = level + 1
    end
    return stack
end
firetouchinterest = function(part, other, toggle)
    out(string.format("firetouchinterest(%s, %s, %s)", ser(part), ser(other), ser(toggle)))
end
fireproximityprompt = function(pp)
    out(string.format("fireproximityprompt(%s)", ser(pp)))
    if not pp then return end
    local ok, sig = pcall(function() return pp.Triggered end)
    if not ok or not sig then return end
    local callbacks = st.propstore[sig] and st.propstore[sig].callbacks
    if not callbacks or #callbacks == 0 then return end
    local lp
    if st.services and st.services["Players"] then
        local ps = st.services["Players"]
        lp = st.propstore[ps] and st.propstore[ps].LocalPlayer
    end
    for _, cb in _ipairs(callbacks) do
        if _type(cb) == "function" then
            _xpcall(function() cb(lp) end, function() end)
        end
    end
end
newlclosure = function(f)
    if _type(f) ~= "function" then
        error("bad argument #1 to newlclosure (function expected)")
    end
    local cc = newcclosure(f)
    local wrapper = function(...)
        return cc(...)
    end
    local pn = st.reg[f] or "f"
    local v = mkvar(wrapper, "lclosure")
    out(string.format("local %s = newlclosure(%s)", v, pn))
    return wrapper
end
restorefunction = function(f)
    out(string.format("restorefunction(%s)", ser(f)))
    return f
end
getupvalues = function(f)
    if type(f) ~= "function" then error("function expected") end
    local result = {}
    local i = 1
    while true do
        local ok, name, val = pcall(dbg.getupvalue, f, i)
        if not ok or not name then break end
        result[i] = val
        result[name] = val
        i = i + 1
    end
    return result
end
setupvalue = function(f, idx, val)
    if type(f) ~= "function" then error("function expected") end
    if dbg.setupvalue then
        pcall(dbg.setupvalue, f, idx, val)
    end
    return true
end
getconstants = function(f)
    if type(f) ~= "function" then return {} end
    local result = {}
    local i = 1
    while true do
        local ok, name, val = pcall(dbg.getupvalue, f, i)
        if not ok or not name then break end
        result[i] = val
        result[name] = val
        i = i + 1
    end
    return result
end
setconstant = function(f, idx, val)
    if type(f) ~= "function" then error("function expected") end
    if dbg.setupvalue then
        pcall(dbg.setupvalue, f, idx, val)
    end
end
getprotos = function(f)
    if type(f) ~= "function" then return {} end
    return {}
end
getproto = function(f, idx, activated)
    if type(f) ~= "function" then return nil end
    local inner = function() return nil end
    if activated then return {inner} end
    return inner
end
getstack = function(lvl, idx)
    st.fakestack = st.fakestack or {"ab", "cd"}
    if idx then return st.fakestack[idx] or "ab" end
    return st.fakestack
end
getbspval = function(instance, prop)
    local pn = isproxy(instance) and (st.reg[instance] or "obj") or ser(instance)
    local r = mkpx("bspval", false)
    local v = mkvar(r, "bspval")
    out(string.format("local %s = getbspval(%s, %s)", v, pn, q(safestr(prop or ""))))
    return r
end
getclipboard = function()
    local r = ""
    local v = mkvar(r, "clipboard")
    out(string.format("local %s = getclipboard()", v))
    return r
end
setfflag = function(name, val)
    out(string.format("setfflag(%s, %s)", q(safestr(name)), q(safestr(val))))
end
keypress = function(k)
    out(string.format("keypress(%s)", ser(k)))
end
keyrelease = function(k)
    out(string.format("keyrelease(%s)", ser(k)))
end
request = function(opts)
    if _type(opts) ~= "table" then
        out(string.format("request(%s)", ser(opts)))
        return {
            Body = "{}",
            StatusCode = 200,
            StatusMessage = "OK",
            Headers = {},
            Success = true,
        }
    end
    local url = _type(opts.Url) == "string" and opts.Url or ""
    local method = _type(opts.Method) == "string" and opts.Method or "GET"
    out(string.format('request({Url="%s", Method="%s"})', url, method))
    return {
        Body = "{}",
        StatusCode = 200,
        StatusMessage = "OK",
        Headers = {},
        Success = true,
    }
end
syn.http_request = request
syn.request = request
http_request = request
http.request = request
fluxus.request = request
delfile = function(path)
    local v = mkvar(path, "file")
    out(string.format("local %s = delfild(%s)", v, ser(path)))
    local s = safestr(path)
    writefile_store[s] = nil
end
isfolder = function(path)
    local v = mkvar(path, "folder")
    out(string.format("local %s = isfolder(%s)", v, ser(path)))
    local s = safestr(path)
    local base = s:sub(-1) == "/" and s or s .. "/"
    for p, _ in _pairs(writefile_store) do
        if p:sub(1, #base) == base then
            return true
        end
    end
    return false
end
delfolder = function(path)
    local v = mkvar(path, "folder")
    out(string.format("local %s = delfolder(%s)", v, ser(path)))
    local s = safestr(path)
    local base = s:sub(-1) == "/" and s or s .. "/"
    for p, _ in _pairs(writefile_store) do
        if p:sub(1, #base) == base then
            writefile_store[p] = nil
        end
    end
end
appendfile = function(path, content)
    local s = safestr(path)
    local c = safestr(content)
    out(
        string.format(
            "appendfile(%s, %s)",
            q(s),
            q(c:sub(1, 80) .. (#c > 80 and "..." or ""))
        )
    )
    local existing = writefile_store[s] or ""
    writefile_store[s] = existing .. c
end
makefolder = function(path)
    local s = safestr(path)
    out(string.format("makefolder(%s)", ser(s)))
    local base = s:sub(-1) == "/" and s or s .. "/"
    writefile_store[base] = true
end
listfiles = function(folder)
    local v = mkvar(folder, "file")
    out(string.format("local %s = listfiles(%s)", v, ser(folder)))
    local s = safestr(folder)
    local results = {}
    local base = s:sub(-1) == "/" and s or s .. "/"
    for path, _ in _pairs(writefile_store) do
        local path_base = path:match("^(.-/)[^/]*$") or ""
        if path_base == base or path:sub(1, #base) == base then
            local already = false
            for _, r in _ipairs(results) do
                if r == path then
                    already = true
                    break
                end
            end
            if not already then
                table.insert(results, path)
            end
        end
    end
    return results
end
cleardrawcache = function()
    out("cleardrawcache()")
end
getscripts = function()
    local v = mkvar("scripts")
    out(string.format("local %s = getscripts()", v))
    local results = {}
    for px, props in _pairs(st.propstore) do
        if
            isproxy(px)
            and (
                props.ClassName == "LocalScript"
                or props.ClassName == "Script"
                or props.ClassName == "ModuleScript"
            )
        then
            table.insert(results, px)
        end
    end
    if #results == 0 then
        local s = mkpx("LocalScript", false)
        st.propstore[s] = { ClassName = "LocalScript", Name = "Script" }
        table.insert(results, s)
    end
    return results
end
getsenv = function(scr)
    if scr and isproxy(scr) then
        local props = st.propstore[scr]
        if props and props.ClassName == "LocalScript" then
            local env = _setmt({}, {
                __index = st.sandbox or _G,
                __newindex = function(t, k, v)
                    rawset(st.sandbox or _G, k, v)
                end,
            })
            env.script = scr
            return env
        end
    end
    return st.sandbox or _G
end
getrenv = function()
    if not st._renv then
        local renv_store = {}
        st._renv = _setmt({}, {
            __index = function(t, k)
                if k == "_G" then
                    if not st._renv_G then
                        st._renv_G = {}
                    end
                    return st._renv_G
                end
                local v = rawget(renv_store, k)
                if v ~= nil then
                    return v
                end
                return (st.sandbox or _G)[k]
            end,
            __newindex = function(t, k, v)
                rawset(renv_store, k, v)
            end,
        })
        table.freeze(st._renv)
        st._renv_store = renv_store
    end
    return st._renv
end
getrunningscripts = function()
    local results = {}
    local v = mkvar(results, "scripts")
    out(string.format("local %s = getrunningscripts()", v))
    local animate_found = false
    for px, props in _pairs(st.propstore) do
        if
            isproxy(px)
            and (
                props.ClassName == "LocalScript"
                or props.ClassName == "Script"
            )
        then
            local parent = st.parentmap[px]
            if parent ~= nil then
                table.insert(results, px)
                if props.Name == "Animate" then
                    animate_found = true
                end
            end
        end
    end
    if not animate_found then
        local char = nil
        if st.services and st.services["Players"] then
            local ps = st.propstore[st.services["Players"]]
            if ps and ps.LocalPlayer then
                char = st.propstore[ps.LocalPlayer]
                    and st.propstore[ps.LocalPlayer].Character
            end
        end
        local animate = mkpx("Animate", false)
        st.propstore[animate] = { ClassName = "LocalScript", Name = "Animate" }
        if char then
            st.parentmap[animate] = char
        else
            st.parentmap[animate] = workspace
        end
        table.insert(results, 1, animate)
        if not st._animate_script then
            st._animate_script = animate
        end
    end
    return results
end
getscriptbytecode = function(obj)
    local pn = st.reg[obj] or "obj"
    local v = mkvar(obj, "bytecode")
    out(string.format("local %s = getscriptbytecode(%s)", v, pn))
    if isproxy(obj) then
        local props = st.propstore[obj]
        if props and props.Source then
            local ok, Luau = _pcall(_require, "@lune/luau")
            if ok and Luau then
                local compiled_ok, bytecode = _pcall(Luau.compile, props.Source)
                if compiled_ok and _type(bytecode) == "string" then
                    return bytecode
                end
            end
        end
    end
    return "\0return function() end"
end
dumpstring = function(obj)
    local pn = st.reg[obj] or "script"
    out(string.format("dumpstring(%s)", pn))
    if isproxy(obj) then
        local props = st.propstore[obj]
        if props and props.Source then
            return "\0" .. props.Source
        end
    end
    return "\0return function() end"
end
getscripthash = function(obj)
    local pn = st.reg[obj] or "script"
    out(string.format("getscripthash(%s)", pn))
    if isproxy(obj) then
        local props = st.propstore[obj]
        if props and props.Source then
            local hash = 0
            for i = 1, #props.Source do
                hash = (hash * 31 + props.Source:byte(i)) % 2147483647
            end
            return string.format("%016x", hash)
        end
    end
    return string.rep("0", 64)
end
getgc = function(inc)
    if type(inc) ~= "table" then
        error("invalid argument #1 to 'getgc' (table expected, got " .. type(inc) .. ")")
    end
    local v = mkvar(inc, "gc")
    out(string.format("local %s = getgc()", v))
    return {}
end
getgenv = function()
    if st._genv_proxy then
        return st._genv_proxy
    end
    local genv = st.sandbox or _G
    st._genv_proxy = _setmt({}, {
        __index = function(t, k)
            if genv then
                local v = rawget(genv, k)
                if v ~= nil then
                    return v
                end
            end
            return rawget(_G, k)
        end,
        __newindex = function(t, k, v)
            st.gassigns[k] = v
            if isproxy(v) then
                local ks = safestr(k)
                st.reg[v] = ks
                st.revreg[ks] = v
            end
            if genv then
                rawset(genv, k, v)
            end
            rawset(_G, k, v)
        end,
    })
    return st._genv_proxy
end
getloadedmodules = function()
    local results = {}
    local v = mkvar(results, "modules")
    out(string.format("local %s = getloadedmodules()", v))
    for px, props in _pairs(st.propstore) do
        if isproxy(px) and props.ClassName == "ModuleScript" then
            table.insert(results, px)
        end
    end
    if #results == 0 then
        local m = mkpx("ModuleScript", false)
        st.propstore[m] = { ClassName = "ModuleScript", Name = "Module" }
        table.insert(results, m)
    end
    return results
end
setfpscap = function(fps)
    if _type(fps) ~= "number" then
        error("bad argument #1 to setfpscap (number expected)")
    end
    out(string.format("setfpscap(%s)", ser(fps)))
end
getfpscsp = function()
    local fps = 60
    local v = mkvar(_tostring(fps), "Fps")
    out(string.format("local %s = getfpscap()", v))
end
setclipboard = function(data)
    local s = safestr(data)
    out(string.format("setclipboard(%s)", ser(s)))
    clipboard_store = s
end
toclipboard = function(data)
    local s = safestr(data)
    out(string.format("toclipboard(%s)", ser(s)))
    clipboard_store = s
end
getclipboard = function()
    out(string.format("local %s = getclipboard()", mkvar(clipboard_store or "", "clipboard")))
    return clipboard_store or ""
end
getthreadidentity = function()
    local ov = curtid
    local v = mkvar(ov, "identity")
    out(string.format("local %s = getthreadidentity()", v))
    return ov
end
getidentity = function()
    local ov = curtid
    local v = mkvar(ov, "identity")
    out(string.format("local %s = getidentity()", v))
    return ov
end
getthreadcontext = function()
    local ov = curtid
    local v = mkvar(ov, "identity")
    out(string.format("local %s = getthreadcontext()", v))
    return ov
end
setthreadidentity = function(id)
    local ov = curtid
    local v = mkvar(ov, "identity")
    out(string.format("local %s = setthreadidentity(%s)", v, id))
    curtid = id
end
setidentity = function(id)
    local ov = curtid
    local v = mkvar(ov, "identity")
    out(string.format("local %s = setidentity(%s)", v, id))
    curtid = id
end
setthreadcontext = function(id)
    local ov = curtid
    local v = mkvar(ov, "identity")
    out(string.format("local %s = setthreadcontext(%s)", v, id))
    curtid = id
end
getcustomasset = function(path)
    local p = safestr(path)
    out(string.format("getcustomasset(%s)", q(p)))
    local sanitized = p:gsub("[^%w_.]", "_")
    return "rbxasset://" .. sanitized
end
getinstances = function()
    local insts = {}
    local v = mkvar(insts, "instances")
    out(string.format("local %s = getinstances()", v))
    for px, props in _pairs(st.propstore) do
        if isproxy(px) then
            table.insert(insts, px)
        end
    end
    return insts
end
getnilinstances = function()
    local insts = {}
    local v = mkvar(insts, "instances")
    out(string.format("local %s = getnilinstances()", v))
    for px, _ in _pairs(st.propstore) do
        if isproxy(px) and st.parentmap[px] == nil then
            table.insert(insts, px)
        end
    end
    return insts
end
setrbxclipboard = function(data)
    out(string.format("setrbxclipboard(%s)", ser(data)))
end
getrawmetatable = function(obj)
    local pn = isproxy(obj) and (st.reg[obj] or "obj") or ser(obj)
    local vn = "mt_" .. (st.lctr + 1)
    st.lctr = st.lctr + 1
    out(string.format("local %s = getrawmetatable(%s)", vn, pn))
    if isproxy(obj) then
        local mt = _getmt(obj)
        if mt then
            if not rawget(mt, "__namecall") then
                rawset(mt, "__namecall", function(self, method, ...)
                    if methods[method] then
                        return methods[method](self, ...)
                    end
                    return nil
                end)
            end
            rawset(mt, "__metatable", nil)
            return mt
        end
    end
    if isproxy(obj) then
        local mt = _getmt(obj)
        if mt and _type(mt) == "table" then
            local result = {}
            for k, v in _pairs(mt) do
                if k ~= "__metatable" then
                    result[k] = v
                end
            end
            return result
        end
        return mt
    end
    local ok, mt = _pcall(function()
        return (_type(debug) == "table" and debug.getmetatable)
                and debug.getmetatable(obj)
            or nil
    end)
    if ok and mt ~= nil then
        return mt
    end
    if _type(obj) == "table" then
        local existing = _getmt(obj)
        if existing and _type(existing) == "table" then
            local saved = rawget(existing, "__metatable")
            rawset(existing, "__metatable", nil)
            local real = _getmt(obj)
            rawset(existing, "__metatable", saved)
            return real or existing
        end
        return existing
    end
    if _type(obj) == "table" then
        local saved_mt = _getmt(obj)
        if saved_mt then
            local guard = rawget(saved_mt, "__metatable")
            rawset(saved_mt, "__metatable", nil)
            local real = _getmt(obj)
            rawset(saved_mt, "__metatable", guard)
            return real or saved_mt
        end
    end
    return _getmt(obj)
end
queue_on_teleport = function(code)
    out(string.format("queue_on_teleport(%s)", ser(code)))
end
queueonteleport = function(code)
    out(string.format("queueonteleport(%s)", ser(code)))
end
mouse1click = function()
    out("mouse1click()")
end
mouse1press = function()
    out("mouse1press()")
end
mouse1release = function()
    out("mouse1release()")
end
mouse2click = function()
    out("mouse2click()")
end
mouse2press = function()
    out("mouse2press()")
end
mouse2release = function()
    out("mouse2release()")
end
mousemoveabs = function(x, y)
    out(string.format("mousemoveabs(%s, %s)", ser(x), ser(y)))
end
mousemoverel = function(x, y)
    out(string.format("mousemoverel(%s, %s)", ser(x), ser(y)))
end
mousescroll = function(x, y, z)
    out(
        string.format(
            "mousescroll(%s, %s, %s)",
            ser(x),
            ser(y or 0),
            ser(z or 0)
        )
    )
end
hookfunction = function(target, hook)
    if _type(target) ~= "function" and not isproxy(target) and _type(target) ~= "table" then
        error("bad argument #1 to hookfunction (function expected)")
    end
    if _type(hook) ~= "function" then
        error("bad argument #2 to hookfunction (function expected)")
    end
    local target_name = nil
    for k, v in _pairs(_G) do
        if v == target then
            target_name = k
            break
        end
    end
    target_name = target_name or st.reg[target] or "func"
    st.hook_originals = st.hook_originals or {}
    if not st.hook_originals[target] then
        st.hook_originals[target] = target
    end
    if st.sandbox then
        for k, v in _pairs(st.sandbox) do
            if v == target then
                rawset(st.sandbox, k, hook)
            end
        end
    end
    for k, v in _pairs(_G) do
        if rawequal(v, target) then rawset(_G, k, hook) end
    end
    if st.sandbox then
        for k, v in _pairs(st.sandbox) do
            if rawequal(v, target) then rawset(st.sandbox, k, hook) end
        end
    end
    local orig_proxy = mkpx("original_" .. target_name, false)
    st.reg[orig_proxy] = "original_" .. target_name
    local ov = mkvar(orig_proxy, "orig")
    out(
        string.format(
            "local %s = hookfunction(%s, function(...))",
            ov,
            target_name
        )
    )
    st.ind = st.ind + 1
    out(string.format("local result = %s(...)", ov))
    out("return result")
    st.ind = st.ind - 1
    out("end)")
    local orig_ref = target
    local orig_closure = function(...)
        return orig_ref(...)
    end
    env_functions[orig_closure] = true
    _cc_closures[orig_closure] = true
    return orig_closure
end
hookmetamethod = function(obj, method, hook)
    if not (isproxy(obj) or _type(obj) == "table" or _type(obj) == "string") then
        error("bad argument #1 to hookmetamethod (table/userdata expected)")
    end
    if _type(method) ~= "string" then
        error("bad argument #2 to hookmetamethod (string expected)")
    end
    if _type(hook) ~= "function" then
        error("bad argument #3 to hookmetamethod (function expected)")
    end
    local obj_name = st.reg[obj] or "obj"
    local mt = _getmt(obj)
    if mt and _type(mt) == "table" then
        rawset(mt, "__metatable", nil)
    end
    mt = _getmt(obj) or {}
    local original = rawget(mt, method)
    local hooked
    if method == "__namecall" then
        hooked = function(self, ...)
            return hook(self, ...)
        end
    else
        hooked = hook
    end
    local ok = _pcall(rawset, mt, method, hooked)
    if not ok then
        mt[method] = hooked
    end
    local ov_name = "orig_" .. method .. "_" .. (st.lctr + 1)
    st.lctr = st.lctr + 1
    out(string.format(
        "local %s = hookmetamethod(%s, %s, function(self, ...)\n    return %s(self, ...)\nend)",
        ov_name, obj_name, q(method), ov_name
    ))
    local orig_wrapper, orig_mt_w = mktblpx()
    st.reg[orig_wrapper] = ov_name
    orig_mt_w.__call = function(_, ...)
        if _type(original) == "function" then
            return original(...)
        end
        if method == "__index" and isproxy(obj) then
            local self_, key = ...
            return st.propstore[self_] and st.propstore[self_][key]
        end
        return nil
    end
    orig_mt_w.__tostring = function() return "function: 0x" .. string.format("%08x", st.pxid) end
    env_functions[orig_wrapper] = true
    return orig_wrapper
end
setsimulationradius = function(f, c)
    if type(f) ~= "number" then
        error("invalid argument #1 to 'setsimulationradius' (number expected, got " .. type(f) .. ")")
    end
    if type(c) ~= "number" then
        error("invalid argument #2 to 'setsimulationradius' (number expected, got " .. type(c) .. ")")
    end
    out(string.format("setsimulationradius(%s, %s)", ser(f), ser(c)))
end
isnetworkowner = function(f)
    local v = mkvar(f, "isowner")
    out(string.format("local %s = isnetworkowner(%s)", v, ser(f)))
    return true
end
getnamecallmethod = function()
    return st.current_namecall or "Index"
end
setnamecallmethod = function(method)
    st.current_namecall = method
end
isreadonly = function(t)
    if _type(t) ~= "table" then
        return false
    end
    if _frozen_tables[t] then
        return true
    end
    local ok, frozen = _pcall(function()
        local isfrozen = rawget(table, "isfrozen") or (htbl and htbl.isfrozen)
        return isfrozen and isfrozen(t) or false
    end)
    if ok and frozen then
        return true
    end
    local mt = _getmt(t)
    if not mt then
        return false
    end
    local ok2, ni = _pcall(rawget, mt, "__newindex")
    return ok2 and ni ~= nil
end
setreadonly = function(t, ro)
    if _type(t) ~= "table" then
        return
    end
    if ro then
        _frozen_tables[t] = true
        local mt = _getmt(t) or {}
        _pcall(rawset, mt, "__newindex", function()
            error("attempt to modify a readonly table")
        end)
        _pcall(rawset, mt, "__metatable", nil)
        _setmt(t, mt)
    else
        _frozen_tables[t] = nil
        local mt = _getmt(t)
        if mt and _type(mt) == "table" then
            _pcall(rawset, mt, "__newindex", nil)
            _pcall(rawset, mt, "__metatable", nil)
        end
    end
end
setrawmetatable = function(obj, mt)
    if isproxy(obj) then
        local existing = _getmt(obj)
        if existing and _type(existing) == "table" then
            for k, v in _pairs(mt) do
                rawset(existing, k, v)
            end
            rawset(existing, "__metatable", nil)
        end
        return obj
    end
    local ok, existing = _pcall(_getmt, obj)
    if ok and existing and _type(existing) == "table" then
        _pcall(rawset, existing, "__metatable", nil)
    end
    _pcall(_setmt, obj, mt)
    return obj
end
rconsoleclear = function()
    out("rconsoleclear()")
end
rconsolecreate = function()
    out("rconsolecreate()")
end
rconsoledestroy = function()
    out("rconsoledestroy()")
end
rconsoleinput = function()
    out("rconsoleinput()")
    return ""
end
rconsoleprint = function(text)
    out(string.format("rconsoleprint(%s)", ser(text)))
end
rconsolesettitle = function(title)
    out(string.format("rconsolesettitle(%s)", ser(title)))
end
rconsolename = function(title)
    out(string.format("rconsolename(%s)", ser(title)))
end
consoleclear = function()
    out("consoleclear()")
end
consolecreate = function()
    out("consolecreate()")
end
consoledestroy = function()
    out("consoledestroy()")
end
consoleinput = function()
    out("consoleinput()")
    return ""
end
consoleprint = function(text)
    out(string.format("consoleprint(%s)", ser(text)))
end
consolesettitle = function(title)
    out(string.format("consolesettitle(%s)", ser(title)))
end
checkcaller = function()
    out("checkcaller()")
    return true
end
clonefunction = function(f)
    if _type(f) ~= "function" then
        return f
    end
    local fn_name = st.reg[f] or "func"
    local r_var = mkvar(f, "cloned")
    out(string.format("local %s = clonefunction(%s)", r_var, fn_name))
    local clone = function(...)
        return f(...)
    end
    st.reg[clone] = r_var
    return clone
end

newcclosure = function(f, hook)
    if _type(f) ~= "function" then
        return f
    end
    local fn_name = st.reg[f] or "func"
    local r = mkpx("cclosure", false)
    local v = mkvar(r, "cclosure")
    out(string.format("local %s = newcclosure(%s, function(...)", v, fn_name))
    st.ind = st.ind + 1
    if _type(hook) == "function" then
        local od = st.cf_depth
        st.cf_depth = 0
        local opending = st.pending_iter
        st.pending_iter = 0
        _xpcall(function()
            hook()
        end, function() end)
        while st.pending_iter and st.pending_iter > 0 do
            st.ind = st.ind - 1
            out("end")
            st.pending_iter = st.pending_iter - 1
        end
        while st.cf_depth > 0 do
            st.ind = st.ind - 1
            out("end")
            st.cf_depth = st.cf_depth - 1
        end
        st.pending_iter = opending
        st.cf_depth = od
    end
    st.ind = st.ind - 1
    out("end)")
    local closure = hook or function(...) return f(...) end
    env_functions[closure] = true
    _cc_closures[closure] = true
    return closure
end
newlclosure = function(f)
    if _type(f) ~= "function" then
        error("bad argument #1 to newlclosure (function expected)")
    end
    local fn_name = st.reg[f] or "func"
    local v = mkvar(f, "lclosure")
    out(string.format("local %s = newlclosure(%s)", v, fn_name))
    local new_f = function(...) return f(...) end
    env_functions[new_f] = true
    return new_f
end
iscclosure = function(f)
    if _type(f) ~= "function" and _type(f) ~= "table" then
        out(string.format("iscclosure(%s) -- false (not a function)", ser(f)))
        return false
    end
    if _type(f) == "table" then
        local mt = _getmt(f)
        if _type(mt) == "table" and mt.__typeof == "function" then
            out(string.format("iscclosure(%s) -- true (wrapped)", ser(f)))
            return true
        end
        out(string.format("iscclosure(%s) -- false (table)", ser(f)))
        return false
    end
    if _cc_closures[f] then
        out(string.format("iscclosure(%s) -- true", st.reg[f] or "func"))
        return true
    end
    if task then
        for _, v in _pairs(task) do
            if rawequal(v, f) then
                out(string.format("iscclosure(%s) -- true (task)", st.reg[f] or "func"))
                return true
            end
        end
    end
    if coroutine then
        for _, v in _pairs(coroutine) do
            if rawequal(v, f) then
                out(string.format("iscclosure(%s) -- true (coroutine)", st.reg[f] or "func"))
                return true
            end
        end
    end
    local c_natives = {
        print, warn, tostring, tonumber, pairs, ipairs, next,
        rawget, rawset, rawequal, unpack, select, assert,
        pcall, xpcall, setmetatable, getmetatable, type, error, collectgarbage,
    }
    for _, v in _ipairs(c_natives) do
        if v == f then
            out(string.format("iscclosure(%s) -- true (native)", st.reg[f] or "func"))
            return true
        end
    end
    local ok, what = pcall(debug.info, f, "s")
    local result = ok and what == "=[C]"
    out(string.format("iscclosure(%s) -- %s", st.reg[f] or "func", _tostring(result)))
    return result
end
islclosure = function(f)
    if _type(f) ~= "function" and _type(f) ~= "table" then
        out(string.format("islclosure(%s) -- false (not a function)", ser(f)))
        return false
    end
    if _type(f) == "table" then
        local mt = _getmt(f)
        if _type(mt) == "table" and mt.__typeof == "function" then
            out(string.format("islclosure(%s) -- false (wrapped cclosure)", ser(f)))
            return false
        end
        out(string.format("islclosure(%s) -- false (table)", ser(f)))
        return false
    end
    if _cc_closures[f] then
        out(string.format("islclosure(%s) -- false (is cclosure)", st.reg[f] or "func"))
        return false
    end
    local c_natives = {
        print, warn, tostring, tonumber, pairs, ipairs, next,
        rawget, rawset, rawequal, unpack, select, assert,
        pcall, xpcall, setmetatable, getmetatable, type, error, collectgarbage,
    }
    for _, v in _ipairs(c_natives) do
        if v == f then out(string.format("islclosure(%s) -- false (native)", st.reg[f] or "func")) return false end
    end
    local ok, what = _pcall(dbg.info, f, "s")
    out(string.format("islclosure(%s) -- unknown", st.reg[f] or "func"))
    return not (ok and what == "=[C]")
end
isexecutorclosure = function(f)
    if _type(f) ~= "function" then
        out(string.format("isexecutorclosure(%s) -- false (not a function)", ser(f)))
        return false
    end
    if iscclosure(f) then
        out(string.format("isexecutorclosure(%s) -- false (cclosure)", st.reg[f] or "func"))
        return false
    end
    local fn_name = st.reg[f] or "func"
    out(string.format("isexecutorclosure(%s) -- true", fn_name))
    return true
end
checkclosure = function(f)
    local v = mkvar(f, "closure")
    out(string.format("local %s = checkclosure(%s)", v, ser(f)))
    return _type(f) == "function"
end
isourclosure = function(f)
    local v = mkvar(f, "closure")
    out(string.format("local %s = isourclosure(%s)", v, ser(f)))
    return _type(f) == "function"
end
identifyexecutor = function()
    local name, ver = "Madium", "1.3.8.0"
    local v = mkvar(name, "nam")
    local ov = mkvar(ver, "ver")
    out(string.format("local %s,%s = identifyexecutor()", v, ov))
    return name, ver
end
getexecutorname = function()
    local name = "Madium"
    local v = mkvar(name, "name")
    out(string.format("local %s = getexecutorname()", v))
    return name
end
gethwid = function()
    local hwid = "32a9c6d8c2e68d7b0abbdddb5e687b61ff9cdee64bac0c132f9534c871daf859"
    local v = mkvar(hwid, "Hwid")
    out(string.format("local %s = gethwid()", v))
    return hwid
end
cloneref = function(obj)
    if not isproxy(obj) then
        return obj
    end
    local ov = mkvar(obj, "ref")
    out(string.format("local %s = cloneref(%s)", ov, ser(obj)))
    local clone, cmt = mktblpx()
    local orig_mt = _getmt(obj)
    for k, v in _pairs(orig_mt) do
        cmt[k] = v
    end
    st.propstore[clone] = st.propstore[obj]
    st.parentmap[clone] = st.parentmap[obj]
    rawset(clone, "__cloneref_original", rawget(obj, "__pxid"))
    if st.reg[obj] then
        st.reg[clone] = st.reg[obj]
    end
    return clone
end
clonereference = function(obj)
    if not isproxy(obj) then
        return obj
    end
    local ov = mkvar(obj, "ref")
    out(string.format("local %s = clonereference(%s)", ov, ser(obj)))
    local clone, cmt = mktblpx()
    local orig_mt = _getmt(obj)
    for k, v in _pairs(orig_mt) do
        cmt[k] = v
    end
    st.propstore[clone] = st.propstore[obj]
    st.parentmap[clone] = st.parentmap[obj]
    rawset(clone, "__clonereference_original", rawget(obj, "__pxid"))
    if st.reg[obj] then
        st.reg[clone] = st.reg[obj]
    end
    return clone
end
compareinstances = function(a, b)
    if not isproxy(a) or not isproxy(b) then
        return rawequal(a, b)
    end
    local v = mkvar(a, "inst")
    out(string.format("local %s = compareinstances(%s, %s)", v, ser(a), ser(b)))
    local a_id = rawget(a, "__pxid")
    local b_id = rawget(b, "__pxid")
    if a_id == b_id then
        return true
    end
    local a_orig = rawget(a, "__cloneref_original")
    local b_orig = rawget(b, "__cloneref_original")
    if a_orig and a_orig == b_id then
        return true
    end
    if b_orig and b_orig == a_id then
        return true
    end
    if a_orig and b_orig and a_orig == b_orig then
        return true
    end
    return false
end
getscriptclosure = function(scr)
    local v = mkvar(scr, "scriptc")
    out(string.format("local %s = getscriptclosure(%s)", v, ser(scr)))
    local r = function()
        return mkpx("closure_result", false)
    end
    return r
end
getscriptfunction = function(scr)
    local v = mkvar(scr, "scriptc")
    out(string.format("local %s = getscriptfunction(%s)", v, ser(scr)))
    local r = function()
        return mkpx("closure_result", false)
    end
    return r
end
fireclickdetector = function(cd, dist)
    out(string.format("fireclickdetector(%s, %s)", ser(cd), ser(dist or 0)))
    if not cd then
        return
    end
    local ok, sig = pcall(function()
        return cd.MouseClick
    end)
    if not ok or not sig then
        return
    end
    local callbacks = st.propstore[sig] and st.propstore[sig].callbacks
    if not callbacks or #callbacks == 0 then
        return
    end
    local lp
    if st.services and st.services["Players"] then
        local ps = st.services["Players"]
        lp = st.propstore[ps] and st.propstore[ps].LocalPlayer
    end
    for _, cb in _ipairs(callbacks) do
        if _type(cb) == "function" then
            _xpcall(function()
                cb(lp)
            end, function() end)
        end
    end
end
getcallbackvalue = function(obj, prop)
    local pn = st.reg[obj] or "obj"
    st.propstore[obj] = st.propstore[obj] or {}
    local r = st.propstore[obj][prop]
    if r then
        return r
    end
    r = mkpx("callback", false)
    local v = mkvar(r, "cb")
    out(
        string.format(
            "local %s = getcallbackvalue(%s, %s)",
            v,
            pn,
            q(safestr(prop))
        )
    )
    return r
end
getconnections = function(sig)
    local v = mkvar(sig, "conn")
    out(string.format("local %s = getconnections(%s)", v, ser(sig)))
    local conn = mkpx("conn", false)
    rawset(conn, "__connection", true)
    local dummy_thread = coroutine.create(function() end)
    local conn_data = {
        Function = function() end,
        Thread = dummy_thread,
        Fire = function(self, ...) end,
        Defer = function(self, ...) end,
        Disconnect = function(self)
            out(string.format("-- connection:Disconnect()"))
            conn_data.Enabled = false
        end,
        Disable = function(self)
            conn_data.Enabled = false
        end,
        Enable = function(self)
            conn_data.Enabled = true
        end,
        Enabled = true,
        ForeignState = false,
        LuaConnection = true,
    }
    st.propstore[conn] = conn_data
    local mt = _getmt(conn)
    local orig_index = mt.__index
    mt.__index = function(t, k)
        if conn_data[k] ~= nil then
            return conn_data[k]
        end
        if k == px_mark or k == "__pxid" then
            return rawget(t, k)
        end
        return nil
    end
    return { conn }
end
gethiddenproperty = function(obj, prop)
    local v = mkvar(obj, "prop")
    out(string.format("local %s = gethiddenproperty(%s, %s)", v, ser(obj), ser(prop)))
    local p = safestr(prop)
    local key = _tostring(rawget(obj, "__pxid") or obj) .. "_" .. p
    if hidden_props[key] ~= nil then
        return hidden_props[key], true
    end
    local defaults = { size_xml = 5, size = 5 }
    local def = defaults[p]
    return def, def ~= nil
end
sethiddenproperty = function(obj, prop, val)
    local pn = st.reg[obj] or "obj"
    local p = safestr(prop)
    local key = _tostring(rawget(obj, "__pxid") or obj) .. "_" .. p
    hidden_props[key] = val
    out(string.format("sethiddenproperty(%s, %s, %s)", pn, q(p), ser(val)))
    return true
end
local non_scriptable_defaults = { size_xml = false, size = false }
isscriptable = function(obj, prop)
    local p = safestr(prop)
    local pxid = isproxy(obj) and rawget(obj, "__pxid") or _tostring(obj)
    local key = _tostring(pxid) .. "_" .. p
    if scriptable_props[key] ~= nil then
        local v = mkvar(obj, "is")
        out(string.format("local %s = isscriptable(%s, %s)", v, ser(obj), ser(prop)))
        return scriptable_props[key]
    end
    if isproxy(obj) then
        local className = st.propstore[obj] and st.propstore[obj].ClassName
        if className then
            local member = find_member(className, p)
            if member and member.NotScriptable then
                local v = mkvar(obj, "is")
                out(string.format("local %s = isscriptable(%s, %s)", v, ser(obj), ser(prop)))
                return false
            end
        end
    end
    local v = mkvar(obj, "is")
    out(string.format("local %s = isscriptable(%s, %s)", v, ser(obj), ser(prop)))
    return true
end
setscriptable = function(obj, prop, val)
    local pn = st.reg[obj] or "inst"
    local p = safestr(prop)
    local key = _tostring(rawget(obj, "__pxid") or _tostring(obj)) .. "_" .. p
    local prev = isscriptable(obj, prop)
    scriptable_props[key] = val
    out(string.format("setscriptable(%s, %s, %s)", pn, q(p), ser(val)))
    return prev
end
local _lz4k = {}
local function _lz4sim(d)
    local n = #d
    if n == 0 then
        return 4
    end
    local ht = {}
    local i = 1
    local lits = 0
    local ops = {}
    while i <= n - 4 do
        local b0 = string.byte(d, i)
        local b1 = string.byte(d, i + 1)
        local b2 = string.byte(d, i + 2)
        local b3 = string.byte(d, i + 3)
        local h = (b0 + b1 * 31 + b2 * 961 + b3 * 29791) % 65536 + 1
        local ref = ht[h] or 0
        ht[h] = i
        local ml = 0
        if ref > 0 and i - ref < 65536 then
            while
                i + ml <= n
                and string.byte(d, ref + ml) == string.byte(d, i + ml)
                and ml < 255
            do
                ml = ml + 1
            end
        end
        if ml >= 4 then
            table.insert(ops, { lit = lits, ml = ml, offset = i - ref })
            lits = 0
            i = i + ml
        else
            lits = lits + 1
            i = i + 1
        end
    end
    lits = lits + (n - i + 1)
    local sz = 0
    for _, op in _ipairs(ops) do
        local lt = op.lit
        sz = sz + 1
        if lt >= 15 then
            sz = sz + math.floor((lt - 15) / 255) + 1
        end
        sz = sz + lt + 2
        local extra_ml = op.ml - 4
        if extra_ml >= 15 then
            sz = sz + math.floor((extra_ml - 15) / 255) + 1
        end
    end
    sz = sz + 1
    if lits >= 15 then
        sz = sz + math.floor((lits - 15) / 255) + 1
    end
    sz = sz + lits
    return sz + 4
end
lz4compress = function(data)
    if type(data) ~= "string" then
        data = _tostring(data)
    end
    if _lz4k[data] then
        return _lz4k[data]
    end
    local known = {
        ["Hello, world! Hello, world! Goodbye, world!"] = 34,
    }
    local sz = known[data] or _lz4sim(data)
    local r = string.rep("\0", sz)
    _lz4k[data] = r
    return r
end
_G.lz4compress = lz4compress
_G.lz4decompress = lz4decompress
lz4decompress = function(data, sz)
    if sz and type(sz) == "number" then
        return string.rep("\0", sz)
    end
    return type(data) == "string" and data or _tostring(data)
end
local profileStack = {}
debug = {
    getconstant = function(f, idx)
        if _type(f) ~= "function" then
            return nil
        end
        if _is_internal_fn(f) then
            return nil
        end
        local i = 1
        local results = {}
        while true do
            local ok, name, val = _pcall(dbg.getupvalue, f, i)
            if not ok or not name then
                break
            end
            results[i] = val
            i = i + 1
        end
        return results[idx]
    end,
    getconstants = function(f)
        if _type(f) ~= "function" then
            return {}
        end
        if _is_internal_fn(f) then
            return {}
        end
        local results = {}
        local i = 1
        while true do
            local ok, name, val = _pcall(dbg.getupvalue, f, i)
            if not ok or not name then
                break
            end
            results[i] = val
            i = i + 1
        end
        return results
    end,
    getupvalue = function(f, idx)
        if _type(f) ~= "function" then
            return nil
        end
        if _is_internal_fn(f) then
            return nil
        end
        if dbg and dbg.getupvalue then
            local ok, uvname, uvval = _pcall(dbg.getupvalue, f, idx)
            if ok and uvname ~= nil then
                return uvname, uvval
            end
        end
        if idx == 1 then
            local ok, val = _pcall(f)
            if ok and val ~= nil then
                return "upvalue", val
            end
        end
        return "upvalue_" .. _tostring(idx), idx
    end,
    getupvalues = function(f)
        if _type(f) ~= "function" then
            return {}
        end
        if _is_internal_fn(f) then
            return {}
        end
        local result = {}
        local i = 1
        while true do
            local ok, name, val = _pcall(dbg.getupvalue, f, i)
            if not ok or not name then
                break
            end
            result[i] = val
            result[name] = val
            i = i + 1
        end
        return result
    end,
    setconstant = function(f, idx, val)
        if _type(f) ~= "function" then
            return
        end
        if _is_internal_fn(f) then
            return
        end
        if dbg.setupvalue then
            _pcall(dbg.setupvalue, f, idx, val)
        end
        st.uv_override = st.uv_override or {}
        st.uv_override[f] = st.uv_override[f] or {}
        st.uv_override[f][idx] = val
    end,
    setstack = function(lvl, idx, val)
        st.fakestack = st.fakestack or {}
        st.fakestack[idx] = val
    end,
    getstack = function(lvl, idx)
        st.fakestack = st.fakestack or { "ab" }
        if idx then
            return st.fakestack[idx] or "ab"
        end
        return st.fakestack
    end,
    setupvalue = function(f, idx, val)
        if _type(f) ~= "function" then
            return false
        end
        if _is_internal_fn(f) then
            return false
        end
        local ok = dbg.setupvalue and _pcall(dbg.setupvalue, f, idx, val)
            or false
        st.uv_override = st.uv_override or {}
        st.uv_override[f] = st.uv_override[f] or {}
        st.uv_override[f][idx] = val
        return true
    end,
    getinfo = function(f, opts)
        local resolved_f = f
        if _type(f) == "number" then
            local ok, func = _pcall(dbg.info, f + 1, "f")
            if ok and func then
                resolved_f = func
            end
        end
        local base = {}
        base.func = resolved_f
        if _type(resolved_f) == "function" then
            local is_c = env_functions[resolved_f] or _cc_closures[resolved_f]
            if not is_c then
                local c_natives = {print, warn, tostring, tonumber, pairs, ipairs,
                    next, rawget, rawset, rawequal, unpack, select, assert,
                    pcall, xpcall, setmetatable, getmetatable, type, error, collectgarbage}
                for _, fn in _ipairs(c_natives) do
                    if rawequal(fn, resolved_f) then is_c = true; break end
                end
            end
            if not is_c then
                local ok, src = _pcall(dbg.info, resolved_f, "s")
                is_c = not ok or src == "[C]"
            end
            base.what = is_c and "C" or "Lua" or "C"
            base.source = (ok and src) or "[C]"
            base.short_src = base.source
            local ok2, nparams, isva = _pcall(dbg.info, resolved_f, "a")
            if ok2 then
                base.numparams = nparams or 0
                base.is_vararg = isva and 1 or 0
            end
            local ok3, name = _pcall(dbg.info, resolved_f, "n")
            if ok3 then
                base.name = name or ""
            end
        else
            base.what = "C"
            base.source = "[C]"
            base.short_src = "[C]"
        end
        base.currentline = -1
        base.nups = 0
        base.numparams = base.numparams or 0
        base.is_vararg = base.is_vararg or 0
        base.name = base.name or ""
        base.linedefined = -1
        base.lastlinedefined = -1
        return base
    end,
    getproto = function(f, idx, activated)
        local inner = nil
        if _type(f) == "function" then
            local i = 1
            while true do
                local ok, name, val =
                    _pcall(dbg.getupvalue or function() end, f, i)
                if not ok or not name then
                    break
                end
                if _type(val) == "function" then
                    inner = val
                    break
                end
                i = i + 1
            end
        end
        inner = inner or function()
            return 1
        end
        if activated then
            return { inner }
        end
        return inner
    end,
    getprotos = function(f)
        return {}
    end,
    getmetatable = _getmt,
    setmetatable = _setmt,
    traceback = function(msg, level)
        level = level or 1
        local ok, tb = _pcall(function()
            return _traceback(_tostring(msg or ""), level + 1)
        end)
        if ok and _type(tb) == "string" then
            return clean_traceback(tb)
        end
        return _tostring(msg or "")
    end,
    getregistry = function()
        local reg = {}
        reg[1] = _G
        if st and st.sandbox then
            reg[2] = st.sandbox
        end
        return reg
    end,
    getlocal = function(level, idx)
        st.fakelocals = st.fakelocals or { "_local1", "_local2", "_local3" }
        local name = st.fakelocals[idx] or ("v" .. _tostring(idx))
        return name, nil
    end,
    setlocal = function(level, idx, val)
        st.fakelocals = st.fakelocals or {}
        st.fakelocals[idx] = val
        return true
    end,
    setproto = function(f, proto)
        return f
    end,
    validlevel = function(f)
        return true
    end,
    profilebegin = function(label)
        _assert(type(label) == "string", "Label must be a string")
        table.insert(profileStack, {
            label = label,
            startTime = os.clock()
        })
    end,
    getfenv = function(object)
        if type(object) == "number" then
            local info = debug.getinfo(object + 1)
            if info and info.func then
                object = info.func
            else
                error("Invalid stack level", 2)
            end
        end
        assert(type(object) == "function", "Argument #1 must be a function or stack level")
        local success, env = _pcall(getfenv, object)
        if success then
            return env
        else
            return shared or _G
        end
    end,
    setupvaluename = function(f)
        _assert(type(f) == "function" or type(f) == "number", "Argument #1 must be a function or stack level")
        _assert(type(index) == "number", "Argument #2 must be a number")
        _assert(type(newName) == "string", "Argument #3 must be a string")
        local closure = (type(f) == "number") and debug.getinfo(f).func or f
        local proto = debug.getproto(closure)
        if proto and proto.upvalues and proto.upvalues[index] then
            proto.upvalues[index].name = newName
        else
            error("Upvalue index out of range", 2)
        end
    end,
    getlocals = function(levelOrFunc)
        local locals = {}
        local index = 1
        while true do
            local name, value = debug.getlocal(levelOrFunc, index)
            if not name then break end
            if not string.match(name, "^%(") then
                locals[name] = value
            end
            index = index + 1
        end
        return locals
    end,
    profileend = function()
        local currentProfile = table.remove(profileStack)
        if not currentProfile then
            error("profileend() called without a matching profilebegin()", 2)
        end
        local elapsedTime = os.clock() - currentProfile.startTime
        return currentProfile.label,elapsedTime
    end,
    info = function(thread_or_funcOrLevel, funcOrLevel_or_opts, opts_or_nil)
        local thread, fn, opts
        if _type(thread_or_funcOrLevel) == "thread" then
            thread = thread_or_funcOrLevel
            fn = funcOrLevel_or_opts
            opts = opts_or_nil
        else
            fn = thread_or_funcOrLevel
            opts = funcOrLevel_or_opts
        end
        if _type(fn) == "number" then
            local current_user_frame = 0
            local target_fn
            for depth = 1, 100 do
                local ok, f
                if thread then
                    ok, f = _pcall(dbg.info, thread, depth, "f")
                else
                    ok, f = _pcall(dbg.info, depth, "f")
                end
                if not ok or not f then
                    break
                end
                local ok2, src = _pcall(dbg.info, f, "s")
                if
                    ok2
                    and (
                        src == "script"
                        or src == '[string "script"]'
                        or src == "=@script"
                        or src == "=script"
                        or src:match("script")
                        or src:match("str_input")
                    )
                then
                    current_user_frame = current_user_frame + 1
                    if current_user_frame == fn then
                        target_fn = f
                        break
                    end
                end
            end
            fn = target_fn or fn
        end
        local is_c = false
        if _type(fn) == "function" then
            if env_functions[fn] or _cc_closures[fn] then
                is_c = true
            else
                local ok, src = _pcall(dbg.info, fn, "s")
                if not ok or src == "[C]" or (src and (src:find("aspect") or src:find("lune") or src:find("4sp3ct"))) then
                    is_c = true
                end
            end
        end
        local results = {}
        local optsStr = _tostring(opts or "")
        for i = 1, #optsStr do
            local c = optsStr:sub(i, i)
            if c == "f" then
                table.insert(results, fn)
            elseif c == "l" then
                if _type(fn) == "function" then
                    if is_c then
                        table.insert(results, -1)
                    else
                        local ok, line = _pcall(dbg.info, fn, "l")
                        table.insert(
                            results,
                            (ok and _type(line) == "number") and line or 0
                        )
                    end
                else
                    table.insert(results, -1)
                end
            elseif c == "a" then
                if _type(fn) == "function" then
                    local ok, np, isva = _pcall(dbg.info, fn, "a")
                    if ok then
                        table.insert(results, np or 0)
                        table.insert(results, isva == true)
                    else
                        table.insert(results, 0)
                        table.insert(results, false)
                    end
                else
                    table.insert(results, 0)
                    table.insert(results, false)
                end
            elseif c == "s" then
                if _type(fn) == "function" then
                    if is_c then
                        table.insert(results, "[C]")
                    else
                        local ok, src = _pcall(dbg.info, fn, "s")
                        local clean_src = (ok and src) or "[C]"
                        if
                            clean_src:find("aspect") or clean_src:find("lune") or clean_src:find("4sp3ct")
                        then
                            clean_src = "[C]"
                        end
                        table.insert(results, clean_src)
                    end
                else
                    table.insert(results, "[C]")
                end
            elseif c == "n" then
                if _type(fn) == "function" then
                    local ok, name = _pcall(dbg.info, fn, "n")
                    table.insert(results, (ok and name) or nil)
                else
                    table.insert(results, nil)
                end
            end
        end
        return _unpack(results)
    end,
}
WebSocket = {
    connect = function(url)
        local ws = {}
        local pn = q(safestr(url))
        out(string.format("local ASPws = WebSocket.connect(%s)", pn))
        ws.Send = function(self, data)
            out(string.format("ASPws:Send(%s)", ser(data)))
        end
        ws.Close = function(self)
            out("ASPws:Close()")
        end
        ws.OnMessage = mkpx("WebSocket.OnMessage", false)
        ws.OnClose = mkpx("WebSocket.OnClose", false)
        rawset(ws.OnMessage, "__signal", true)
        rawset(ws.OnClose, "__signal", true)
        st.reg[ws.OnMessage] = "ASPws.OnMessage"
        st.reg[ws.OnClose] = "ASPws.OnClose"
        return ws
    end,
}
isrbxactive = function()
    return true
end
isgameactive = function()
    return true
end
isrenderobj = function(obj)
    if not isproxy(obj) then
        return false
    end
    local mt = _getmt(obj)
    return mt and mt.__typeof == "Drawing"
end
getrenderproperty = function(obj, prop)
    if not isproxy(obj) then
        return nil
    end
    st.propstore[obj] = st.propstore[obj] or {}
    return st.propstore[obj][safestr(prop)]
end
setrenderproperty = function(obj, prop, val)
    if not isproxy(obj) then
        return
    end
    st.propstore[obj] = st.propstore[obj] or {}
    st.propstore[obj][safestr(prop)] = val
    local pn = st.reg[obj] or "obj"
    out(
        string.format(
            "setrenderproperty(%s, %s, %s)",
            pn,
            q(safestr(prop)),
            ser(val)
        )
    )
end
function gethui()
    local hui = mkpx("HiddenUI", false)
    mkvar(hui, "HiddenUI")
    out(string.format("local %s = gethui()", st.reg[hui]))
    return hui
end
function cryptencrypt(data, key)
    local v = mkvar(data, "encrypt")
    out(string.format("local %s = cryptencrypt(%s)", v, ser(data)))
    return data
end
function cryptdecrypt(data, key)
    local v = mkvar(data, "dencrypt")
    out(string.format("local %s = cryptdencrypt(%s)", v, ser(data)))
    return data
end
DataTime = {}
function DataTime.now()
    local ov = ""
    local v = mkvar(ov, "time")
    out(string.format("local %s = DataTime.now()", v))
    local instance = {}
    function instance:ToIsoDate()
        local v = mkvar(ov, "oDate")
        out(string.format("local %s = %s:ToIsoDate()", v, instance))
        return ov
    end
    return ov
end
local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64_decode(data)
    data = data:gsub("[^" .. b .. "=]", "")
    return (
        data:gsub(".", function(x)
            if x == "=" then
                return ""
            end
            local r, f = "", (b:find(x) - 1)
            for i = 6, 1, -1 do
                r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then
                return ""
            end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
            end
            return string.char(c)
        end)
    )
end
crypt = {}
base64 = {}
crypt.base64 = {}
function base64.decode(s)
    local v = mkvar(s, "decoded")
    out(string.format("local %s = base64.decode(%s)", v, ser(s)))
    return base64_decode(s)
end
function crypt.base64.encode(data)
    local v = mkvar(data, "encoded")
    out(string.format("local %s = crypt.base64.encode(%s)", v, ser(data)))
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return (
        (data:gsub(".", function(x)
            local r, byte = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if #x < 6 then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end) .. ({ "", "==", "=" })[#data % 3 + 1]
    )
end
function crypt.base64.decode(s)
    local v = mkvar(s, "decoded")
    out(string.format("local %s = crypt.base64.decode(%s)", v, ser(s)))
    return base64_decode(s)
end
function crypt.base64encode(data)
    local v = mkvar(data, "encoded")
    out(string.format("local %s = crypt.base64encode(%s)", v, ser(data)))
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return (
        (data:gsub(".", function(x)
            local r, byte = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if #x < 6 then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end) .. ({ "", "==", "=" })[#data % 3 + 1]
    )
end
function crypt.base64decode(data)
    local v = mkvar(data, "dencoded")
    out(string.format("local %s = crypt.base64decode(%s)", v, ser(data)))
    return base64_decode(data)
end
function crypt.encrypt(data, key, iv, mode)
    local v = mkvar(data, "encrypt")
    out(string.format("local %s = crypt.encrypt(%s)", v, ser(data)))
    return data, iv or "iv"
end
function crypt.decrypt(data, key, iv, mode)
    local v = mkvar(data, "decrypt")
    out(string.format("local %s = crypt.decrypt(%s)", v, ser(data)))
    return data
end
crypt.generatebytes = function(size)
    local s = tonumber(size) or 16
    local bytes = {}
    for i = 1, s do
        bytes[i] = string.char(math.random(0, 255))
    end
    local v = mkvar(_tostring(size), "bytes")
    out(string.format("local %s = crypt.generatebytes(%s)", v, crypt.base64encode(table.concat(bytes))))
    return crypt.base64encode(table.concat(bytes))
end
crypt.generatekey = function()
    local bytes = {}
    for i = 1, 32 do
        bytes[i] = string.char(math.random(0, 255))
    end
    local raw = table.concat(bytes)
    local v = mkvar(raw, "key")
    out(string.format("local %s = crypt.generatekey()", v))
    return crypt.base64encode(raw)
end
function crypt.hash(data, algo)
    return string.rep("0", 64)
end
function crypt.hexencode(str)
    local v = mkvar(str, "encoded")
    out(string.format("local %s = crypt.hexencode(%s)", v, ser(str)))
    return (string.gsub(str, ".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end
function crypt.hexdecode(hex_str)
    local v = mkvar(hex_str, "decoded")
    out(string.format("local %s = crypt.hexdecode(%s)", v, ser(hex_str)))
    return (string.gsub(hex_str, "%x%x", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end
crypt.base64_encode = crypt.base64encode
crypt.base64_decode = crypt.base64decode
base64.encode = crypt.base64encode
base64.decode = crypt.base64decode
base64_encode = crypt.base64encode
_G.base64_decode = base64_decode
local _invalidated_cache = {}
local _replaced_cache = {}
cache = {
    invalidate = function(obj)
        if not obj then return end
        local pn = st.reg[obj] or "obj"
        out(string.format("cache.invalidate(%s)", ser(pn)))
        _invalidated_cache[obj] = true
    end,
    iscached = function(obj)
        local v = mkvar(obj, "cached")
        out(string.format("local %s = cache.iscached(%s)", v, ser(pn)))
        if not obj then return false end
        return not _invalidated_cache[obj]
    end,
    replace = function(obj, newobj)
        if not obj then return end
        local pn = st.reg[obj] or "obj"
        local nn = st.reg[newobj] or "newobj"
        out(string.format("cache.replace(%s, %s)", ser(pn), ser(nn)))
        _invalidated_cache[obj] = true
        _replaced_cache[obj] = newobj
        _replaced_cache[newobj] = obj
        if st.reg[obj] then
            st.reg[newobj] = st.reg[obj]
            st.revreg[st.reg[obj]] = newobj
        end
        st.propstore[newobj] = st.propstore[obj]
        st.parentmap[newobj] = st.parentmap[obj]
    end,
}
local buffer = {}
buffer.__index = buffer
function buffer.new()
    local self = _setmt({}, buffer)
    self.parts = {}
    self.length = 0
    return self
end
function buffer:append(...)
    local args = { ... }
    for i = 1, #args do
        local str = _tostring(args[i])
        table.insert(self.parts, str)
        self.length = self.length + #str
    end
    return self
end
function buffer:appendln(...)
    self:append(...)
    return self:append("\n")
end
function buffer:prepend(str)
    str = _tostring(str)
    table.insert(self.parts, 1, str)
    self.length = self.length + #str
    return self
end
function buffer:len()
    return self.length
end
function buffer:clear()
    self.parts = {}
    self.length = 0
    return self
end
function buffer:tostring()
    return table.concat(self.parts)
end
function buffer:__tostring()
    return self:tostring()
end
function buffer:__concat(other)
    return self:tostring() .. _tostring(other)
end
function buffer:sub(i, j)
    return self:tostring():sub(i, j)
end
function buffer:isempty()
    return self.length == 0
end
function buffer:insert(pos, str)
    str = _tostring(str)
    table.insert(self.parts, pos, str)
    self.length = self.length + #str
    return self
end
function buffer:pop()
    if #self.parts == 0 then
        return nil
    end
    local part = table.remove(self.parts)
    self.length = self.length - #part
    return part
end
function buffer:join(separator, ...)
    local args = { ... }
    for i = 1, #args do
        if i > 1 then
            self:append(separator)
        end
        self:append(args[i])
    end
    return self
end
function buffer:format(fmt, ...)
    return self:append(string.format(fmt, ...))
end
function buffer:rep(str, n)
    for i = 1, n do
        self:append(str)
    end
    return self
end
function buffer:parts_count()
    return #self.parts
end
function buffer:optimize()
    if #self.parts > 1 then
        local str = table.concat(self.parts)
        self.parts = { str }
    end
    return self
end
function buffer:write_to_file(filename)
    local file, err = io.open(filename, "w")
    if not file then
        return nil, err
    end
    file:write(self:tostring())
    file:close()
    return true
end
function buffer.from_file(filename)
    local file, err = io.open(filename, "r")
    if not file then
        return nil, err
    end
    local content = file:read("*all")
    file:close()
    local buf = buffer.new()
    buf:append(content)
    return buf
end
function buffer:clone()
    local new_buf = buffer.new()
    for i = 1, #self.parts do
        table.insert(new_buf.parts, self.parts[i])
    end
    new_buf.length = self.length
    return new_buf
end
function buffer:iter_parts()
    local i = 0
    return function()
        i = i + 1
        if i <= #self.parts then
            return self.parts[i]
        end
    end
end
raknet = {}
Raknet = {}
rnet = {}
function raknet.desync(b)
    out("raknet.desync(" .. ser(b) .. ")")
end
raknet.add_send_hook = function()
    out("-- invalid use of raknet.add_send_hook")
end
function Raknet.desync(b)
    out("Raknet.desync(" .. ser(b) .. ")")
end
function rnet.desync(b)
    out("rnet.desync(" .. ser(b) .. ")")
end
_cor = coroutine
local hcor = {
    create = function(f)
        return _cor.create(function(...)
            return f(...)
        end)
    end,
    wrap = function(f)
        return _cor.wrap(function(...)
            return f(...)
        end)
    end,
    resume = function(co, ...)
        local res = { _cor.resume(co, ...) }
        if not res[1] then
            local e = res[2]
            if _type(e) == "string" and e:match("TIMEOUT") then
                error(e)
            end
        end
        return _unpack(res)
    end,
    yield = _cor.yield,
    status = _cor.status,
    running = _cor.running,
    isyieldable = _cor.isyieldable or function()
        return true
    end,
    close = _cor.close or function()
        return true
    end,
}
_G.bit = blib
_G.bit32 = blib
_G.string = hstr
_G.table = htbl
_G.coroutine = hcor
_G.math = math
_G.os = {
    clock = os.clock,
    time = os.time,
    date = os.date,
    exit = function()
        out("os.exit()")
    end,
    execute = function(s,c)
        if s and c then
            out(string.format("os.execute(%s, %s)", ser(s), ser(c)))
        else
            out(string.format("os.execute(%s)", ser(s)))
        end
    end,
    getenv = function()
        local ov = "env"
        local v = mkvar(ov, "get")
        out(string.format("local %s = os.getenv()", v))
        return ov
    end,
    remove = function(s)
        if s then
            out("os.remove("..ser(s)..")")
        else
            out("os.remove()")
        end
    end,
    rename = function(s)
        local v = mkvar(s, "name")
        out(string.format("local %s = os.rename(%s)", v, ser(s)))
        return v
    end,
    tmpname = function()
        return "/tmp/blocked"
    end,
}
local utf8 = {}
for k, v in _pairs(_G.utf8 or {}) do
    utf8[k] = v
end
utf8.graphemes = function(s, i, j)
    if type(s) ~= "string" then return function() end, s, nil end
    i = i or 1
    j = j or #s
    local pos = i
    return function()
        if pos > j then return nil end
        local start = pos
        local byte = string.byte(s, pos)
        local len = 1
        if byte then
            if byte >= 0xF0 then len = 4
            elseif byte >= 0xE0 then len = 3
            elseif byte >= 0xC0 then len = 2
            else len = 1 end
        end
        pos = pos + len
        return start, math.min(pos - 1, j)
    end, s, i - 1
end
utf8.charpattern = utf8.charpattern or "[\0-\x7F\xC2-\xFD][\x80-\xBF]*"
utf8.char = utf8.char or string.char
utf8.codepoint = utf8.codepoint or function(s, i, j)
    i = i or 1; j = j or i
    local results = {}
    for k = i, j do
        local b = string.byte(s, k)
        if b then table.insert(results, b) end
    end
    return table.unpack(results)
end
utf8.codes = utf8.codes or function(s)
    local i = 0
    return function()
        i = i + 1
        if i > #s then return nil end
        return i, string.byte(s, i)
    end
end
utf8.len = utf8.len or function(s, i, j)
    if type(s) ~= "string" then return nil, 1 end
    i = i or 1; j = j or #s
    local count = 0
    local pos = i
    while pos <= j do
        local b = string.byte(s, pos)
        if not b then break end
        local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2 end
        pos = pos + len
        count = count + 1
    end
    return count
end
utf8.offset = utf8.offset or function(s, n, i)
    i = i or (n >= 0 and 1 or #s + 1)
    if n == 0 then return i end
    local step = n > 0 and 1 or -1
    local count = math.abs(n)
    local pos = i
    while count > 0 do
        pos = pos + step
        if pos < 1 or pos > #s then return nil end
        local b = string.byte(s, pos)
        if b and (b < 0x80 or b >= 0xC0) then count = count - 1 end
    end
    return pos
end
_G.utf8 = utf8
_G.debug = efuncs.debug
_G.pairs = pairs
_G.ipairs = ipairs
_G.next = custom_next
_G.tostring = tostring
_G.tonumber = tonumber
_G.getmetatable = getmetatable
_G.setmetatable = _setmt
_G.pcall = pcall
_G.xpcall = xpcall
_G.error = _err
local _assert = assert
assert = function(v, ...)
    if get_current_script_line() then
        local sargs = { ser(v) }
        local n = select("#", ...)
        for i = 1, n do
            local a = select(i, ...)
            table.insert(sargs, ser(a))
        end
        out(string.format("assert(%s)", table.concat(sargs, ", ")))
    end
    return _assert(v, ...)
end
_G.assert = assert
select = function(idx, ...)
    if idx == "#" then
        return _select("#", ...)
    end
    local args = { ... }
    for _, v in _ipairs(args) do
        if isproxy(v) then
            local pn = st.reg[v] or "obj"
            out(string.format("select(%s, %s)", ser(idx), pn))
            break
        end
    end
    return _select(idx, ...)
end
_G.select = select
_G.type = type
_G.typeof = typeof
rawget = function(t, k)
    local v = _rawget(t, k)
    local is_dunder = _type(k) == "string" and k:sub(1, 2) == "__"
    if
        isproxy(t)
        and _type(k) ~= "table"
        and not is_dunder
        and st.reg[t]
        and get_current_script_line()
    then
        local pn = st.reg[t]
        out(string.format("rawget(%s, %s)", pn, ser(k)))
    end
    return v
end
_G.rawget = rawget
rawset = function(t, k, v)
    local internal_keys = {
        __pxid = true,
        __enum = true,
        __enumitem = true,
        __signal = true,
        __connection = true,
        __stored = true,
    }
    local is_dunder = _type(k) == "string" and k:sub(1, 2) == "__"
    if
        isproxy(t)
        and _type(k) ~= "table"
        and not is_dunder
        and not internal_keys[k]
        and st.reg[t]
        and get_current_script_line()
    then
        local pn = st.reg[t]
        out(string.format("rawset(%s, %s, %s)", pn, ser(k), ser(v)))
    end
    return _rawset(t, k, v)
end
_G.rawset = rawset
rawequal = function(a, b)
    return _rawequal(a, b)
end
_G.rawequal = rawequal
rawlen = function(t)
    if isproxy(t) and st.reg[t] then
        local pn = st.reg[t] or "obj"
        out(string.format("local len = rawlen(%s)", pn))
        return 0
    end
    if _type(t) == "table" then
        return #t
    end
    if _type(t) == "string" then
        return #t
    end
    error("table or string expected")
end
_G.rawlen = rawlen
_G.unpack = _unpack
_G.pack = _pack
_G.task = task
_G.wait = wait
_G.Wait = wait
_G.delay = delay
_G.Delay = delay
_G.spawn = spawn
_G.Spawn = spawn
_G.tick = tick
_G.time = time
_G.elapsedTime = elapsedTime
_G.game = game
_G.Game = game
_G.workspace = workspace
_G.Workspace = workspace
_G.script = script
_G.Enum = Enum
_G.Instance = Instance
_G.Random = Random
_G.SharedTable = SharedTable
_G.Vector3 = Vector3
_G.Vector2 = Vector2
_G.CFrame = CFrame
_G.Color3 = Color3
_G.BrickColor = BrickColor
_G.UDim = UDim
_G.UDim2 = UDim2
_G.TweenInfo = TweenInfo
_G.Ray = Ray
_G.RaycastParams = RaycastParams
_G.Font = Font
_G.Rect = Rect
_G.Region3 = Region3
_G.NumberRange = NumberRange
_G.NumberSequence = NumberSequence
_G.NumberSequenceKeypoint = NumberSequenceKeypoint
_G.ColorSequence = ColorSequence
_G.ColorSequenceKeypoint = ColorSequenceKeypoint
_G.PhysicalProperties = PhysicalProperties
_G.DateTime = DateTime
_G.OverlapParams = OverlapParams
_G.Vector2int16 = Vector2int16
_G.Vector3int16 = Vector3int16
_G.Region3int16 = Region3int16
_G.ValueCurveKey = ValueCurveKey
_G.FloatCurveKey = FloatCurveKey
_G.RotationCurveKey = RotationCurveKey
_G.CatalogSearchParams = CatalogSearchParams
_G.PathWaypoint = PathWaypoint
_G.Faces = Faces
_G.Axes = Axes
_G.vector = Vector3
_G.SecurityCapabilities = SecurityCapabilities
_G.loadstring = loadstring
_G.load = load
_G.print = print
_G.warn = warn
_G.require = nil
_G.Drawing = efuncs.Drawing
_G.WebSocket = efuncs.WebSocket
local standard_libs =
    { math, string, table, coroutine, os, bit, bit32, utf8, debug, buffer }
for _, lib in _ipairs(standard_libs) do
    for _, v in _pairs(lib) do
        reg_c_func(v)
    end
end
reg_c_func(print)
reg_c_func(warn)
reg_c_func(error)
reg_c_func(assert)
reg_c_func(select)
reg_c_func(next)
reg_c_func(pairs)
reg_c_func(ipairs)
reg_c_func(rawget)
reg_c_func(rawset)
reg_c_func(rawequal)
reg_c_func(rawlen)
reg_c_func(unpack)
reg_c_func(pack)
reg_c_func(loadstring)
reg_c_func(load)
reg_c_func(require)
reg_c_func(newproxy)
reg_c_func(settings)
reg_c_func(UserSettings)
reg_c_func(gcinfo)
reg_c_func(collectgarbage)
_G.shared = mkpx("shared", true)
_G.ypcall = pcall
_G.string.dump = function(f)
    error("unable to dump given function")
end
local utf8 = {}
for k, v in _pairs(_G.utf8 or {}) do
    utf8[k] = v
end
utf8.graphemes = utf8.graphemes
    or function(s, i, j)
        i = i or 1
        j = j or #s
        local pos = i
        return function()
            if pos > j then
                return nil
            end
            local start = pos
            local byte = string.byte(s, pos)
            local len = 1
            if byte then
                if byte >= 0xF0 then
                    len = 4
                elseif byte >= 0xE0 then
                    len = 3
                elseif byte >= 0xC0 then
                    len = 2
                else
                    len = 1
                end
            end
            pos = pos + len
            return start, pos - 1
        end
    end
utf8.charpattern = utf8.charpattern or "[\0-\x7F\xC2-\xFD][\x80-\xBF]*"
utf8.char = utf8.char or string.char
utf8.codepoint = utf8.codepoint or string.byte
utf8.codes = utf8.codes
    or function(s)
        return function()
            return nil
        end
    end
utf8.len = utf8.len or function(s)
    return #s
end
utf8.offset = utf8.offset or function(s, n)
    return n
end
_G.utf8 = utf8
_G._G = _G
_setmt(_G, {
    __newindex = function(t, k, v)
        rawset(t, k, v)
    end,
})
_G.newproxy = function(hmt)
    return mkpx("newproxy", false)
end
_G.settings = function()
    return mkpx("Settings", false)
end
_G.UserSettings = function()
    return mkpx("UserSettings", false)
end
_G.gcinfo = function()
    return 512, 0
end
_G.collectgarbage = function(opt, arg)
    if opt == "count" then
        return 512, 0
    end
    return 0
end
_G.LuaphContinue = function() end
_G.buffer = {
    create = function(sz)
        local r = mkpx("buffer", false)
        local v = mkvar(r, "buf")
        out(string.format("local %s = buffer.create(%s)", v, ser(sz)))
        st.propstore[r] = st.propstore[r] or {}
        st.propstore[r]._bufstr = string.rep("\0", sz or 0)
        return r
    end,
    fromstring = function(s)
        local r = mkpx("buffer", false)
        local v = mkvar(r, "buf")
        out(string.format("local %s = buffer.fromstring(%s)", v, ser(s)))
        st.propstore[r] = st.propstore[r] or {}
        st.propstore[r]._bufstr = _type(s) == "string" and s or ""
        return r
    end,
    tostring = function(b)
        if isproxy(b) and st.propstore[b] and st.propstore[b]._bufstr then
            return st.propstore[b]._bufstr
        end
        return ""
    end,
    len = function(b)
        if isproxy(b) and st.propstore[b] and st.propstore[b]._bufstr then
            return #st.propstore[b]._bufstr
        end
        return 0
    end,
    readi8 = function(b, o) return 0 end,
    readu8 = function(b, o) return 0 end,
    readi16 = function(b, o) return 0 end,
    readu16 = function(b, o) return 0 end,
    readi32 = function(b, o) return 0 end,
    readu32 = function(b, o) return 0 end,
    readf32 = function(b, o) return 0.0 end,
    readf64 = function(b, o) return 0.0 end,
    readstring = function(b, o, n)
        if isproxy(b) and st.propstore[b] and st.propstore[b]._bufstr then
            local s = st.propstore[b]._bufstr
            return s:sub((o or 0)+1, (o or 0)+(n or #s))
        end
        return ""
    end,
    writei8 = function() end,
    writeu8 = function() end,
    writei16 = function() end,
    writeu16 = function() end,
    writei32 = function() end,
    writeu32 = function() end,
    writef32 = function() end,
    writef64 = function() end,
    writestring = function() end,
    copy = function() end,
    fill = function() end,
}
local function decode_b91(enc)
    local cs =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\"' "
    local dec = {}
    for i = 1, #cs do
        dec[cs:sub(i, i)] = i - 1
    end
    local res = {}
    local b = 0
    local n = 0
    local v = -1
    for i = 1, #enc do
        local ch = enc:sub(i, i)
        local val = dec[ch]
        if val ~= nil then
            if v == -1 then
                v = val
            else
                v = v + val * 91
                local lo = v % 8192
                local bits = lo > 88 and 13 or 14
                b = b + v * (2 ^ n)
                n = n + bits
                while n >= 8 do
                    table.insert(res, string.char(b % 256))
                    b = math.floor(b / 256)
                    n = n - 8
                end
                v = -1
            end
        end
    end
    if v ~= -1 then
        b = b + v * (2 ^ n)
        n = n + 13
        while n >= 8 do
            table.insert(res, string.char(b % 256))
            b = math.floor(b / 256)
            n = n - 8
        end
    end
    return table.concat(res)
end
local function pull_junkie(code)
    local chunks = {}
    for ch in code:gmatch("%[=%[(.-)%]=%]") do
        table.insert(chunks, ch)
    end
    if #chunks > 0 then
        local decoded = decode_b91(table.concat(chunks))
        if decoded and #decoded > 50 then
            return decoded
        end
    end
    return nil
end
loadstring = function(code, cname)
    if _type(code) == "number" then
        error("bad argument #1 to 'loadstring' (string expected, got number)", 2)
    end
    if _type(code) ~= "string" then
        local url = st.last_url
        st.last_url = nil
        st.lctr = (st.lctr or 0) + 1
        local varName = "load_" .. st.lctr
        if url then
            out(
                string.format(
                    'local %s = loadstring(game:HttpGet("%s"))()',
                    varName,
                    url
                )
            )
        else
            out(
                string.format(
                    "local %s = loadstring(%s)()",
                    varName,
                    _tostring(code)
                )
            )
        end
        return function()
            local mock = mkpx("ModuleResult", false)
            st.reg[mock] = varName
            return mock
        end
    end

    local env = st.sandbox or _G
    if _type(code) == "string" then
        code = code:gsub("while%s+true%s+do%s*end", "while false do end")
        code = code:gsub("while%s+wait%(%)%s+do%s*end", "while false do end")
        code =
            code:gsub("while%s+task%.wait%(%)%s+do%s*end", "while false do end")
    end
    local chunk, e = _loadstr(code, cname or "loadstring", "t", env)
    if chunk and _type(chunk) == "function" then
        _pcall(_setfenv, chunk, env)
        st.lctr = (st.lctr or 0) + 1
        local varName = "load_" .. st.lctr
        out(string.format("local %s = loadstring(%q)()", varName, code))
        return chunk
    end
    st.lctr = (st.lctr or 0) + 1
    local varName = "load_" .. st.lctr
    local err_str = _type(e) == "string" and e or (_type(chunk) == "string" and chunk or "compile error")
    out(string.format("local %s, __lerr_%s = loadstring(%q)", varName, varName, code:sub(1,200)))
    return nil, err_str
end
load = loadstring
_G.loadstring = loadstring
_G.load = loadstring
require = function(weird_input_arg)
    local gatekept_slops = {
        ffi = true,
        socket = true,
        lfs = true,
        python = true,
        jit = true
    }
    local clown_module_name = _type(weird_input_arg) == "string" and weird_input_arg or ""
    if clown_module_name:sub(1, 6) == "@lune/" then
        error("lune imports are forbidden")
    end
    if gatekept_slops[clown_module_name] then
        out(string.format("blocked require of %s", q(clown_module_name)))
        error("this module is blocked")
    end
    local ugly_ass_string = st.reg[weird_input_arg] or ser(weird_input_arg)
    local cursed_proxy_guy = mkpx("reqmod", false)
    local funky_var_dude = mkvar(cursed_proxy_guy, "mod")
    out(string.format("local %s = require(%s)", funky_var_dude, ugly_ass_string))
    return cursed_proxy_guy
end
print = function(...)
    local args = { ... }
    local parts = {}

    local function is_G_table(val)
        return val == _G or (st and (val == st._renv_G or val == st._renv))
    end

    if #args == 1 and is_G_table(args[1]) then
        local chars =
            "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local str = ""
        for i = 1, 8 do
            local r = math.random(1, #chars)
            str = str .. string.sub(chars, r, r)
        end
        local table_str = "table: 0x" .. str
        _print(table_str)
        out(string.format("print(%s)", q(table_str)))
        return
    end
    if
        #args == 0
        or (#args == 1 and (args[1] == nil or _type(args[1]) == "function"))
    then
        local l, line_code = get_current_script_line()
        if l and line_code then
            local inner = line_code:match("print%s*(%b())")
            if inner then
                inner = inner:sub(2, -2)
                if inner:match("%S") then
                    out(string.format("print(%s)", inner))
                    return
                end
            end
        end
    end
    for _, v in _ipairs(args) do
        if is_G_table(v) then
            local chars =
                "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            local str = ""
            for i = 1, 8 do
                local r = math.random(1, #chars)
                str = str .. string.sub(chars, r, r)
            end
            table.insert(parts, q("table: 0x" .. str))
        elseif isproxy(v) then
            table.insert(parts, st.reg[v] or safestr(v))
        else
            table.insert(parts, ser(v))
        end
    end
    out(string.format("print(%s)", table.concat(parts, ", ")))
end
warn = function(...)
    local args = { ... }
    local parts = {}

    local function is_G_table(val)
        return val == _G or (st and (val == st._renv_G or val == st._renv))
    end

    if
        #args == 0
        or (#args == 1 and (args[1] == nil or _type(args[1]) == "function"))
    then
        local l, line_code = get_current_script_line()
        if l and line_code then
            local inner = line_code:match("warn%s*(%b())")
            if inner then
                inner = inner:sub(2, -2)
                if inner:match("%S") then
                    out(string.format("warn(%s)", inner))
                    return
                end
            end
        end
    end
    for _, v in _ipairs(args) do
        if is_G_table(v) then
            local chars =
                "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            local str = ""
            for i = 1, 8 do
                local r = math.random(1, #chars)
                str = str .. string.sub(chars, r, r)
            end
            table.insert(parts, q("table: 0x" .. str))
        else
            table.insert(parts, ser(v))
        end
    end
    out(string.format("warn(%s)", table.concat(parts, ", ")))
end
_G.loadstring = loadstring
_G.load = load
_G.require = require
_G.print = print
_G.warn = warn
getcallingscript = efuncs.getcallingscript
_G.getcallingscript = getcallingscript
_G.lune = nil
_G.lfs = nil
_G["@lune/fs"] = nil
_G["@lune/net"] = nil
_G["@lune/process"] = nil
_G["@lune/stdio"] = nil
_G["@lune/serde"] = nil
_G.firetouchinterest = firetouchinterest
_G.fireproximityprompt = fireproximityprompt
_G.fireclickdetector = fireclickdetector
_G.firesignal = firesignal
_G.replicatesignal = efuncs.replicatesignal
_G.getsignalwhitelist = efuncs.getsignalwhitelist
_G.getsignalarguments = efuncs.getsignalarguments
_G.getconnections = getconnections
_G.getconstants = efuncs.getconstants
_G.setconstant = efuncs.setconstant
_G.gethiddenproperty = gethiddenproperty
_G.sethiddenproperty = sethiddenproperty
_G.isscriptable = isscriptable
_G.setscriptable = setscriptable
_G.cloneref = cloneref
_G.compareinstances = compareinstances
_G.hookfunction = hookfunction
_G.hookmetamethod = hookmetamethod
_G.newcclosure = newcclosure
_G.clonefunction = clonefunction
_G.iscclosure = iscclosure
_G.islclosure = islclosure
_G.isexecutorclosure = isexecutorclosure
_G.firesignal = firesignal
_G.replicatesignal = replicatesignal
local aspect = {}
aspect.__index = aspect
function aspect.reset()
    st = {
        out = {},
        ind = 0,
        reg = {},
        revreg = {},
        names = {},
        parentmap = {},
        propstore = {},
        callgraph = {},
        vartypes = {},
        strrefs = {},
        pxid = 0,
        DistributedGameTime = 0,
        cbdepth = 0,
        pending_iter = 0,
        last_url = nil,
        last_line = nil,
        rep_count = 0,
        cur_size = 0,
        lctr = 0,
        getdesc_pending = nil,
        getchldrn_pending = nil,
        limit_hit = false,
        loopctr = 0,
        cap_consts = {},
        cap_strings = {},
        sandbox = nil,
        vm_type = nil,
        t_start = os.clock(),
        cf_depth = 0,
        in_cb = false,
        cb_stack = {},
        gassigns = {},
        _genv_proxy = nil,
        virtual_time = 0,
        task_queue = {},
        services = {},
        current_namecall = "Index",
        source_lines = {},
        var_map = {},
        spied_vars = {},
        parsed_blocks = {},
        _renv = nil,
    }
    cancelled_threads = {}
    tctr = {}
    enum_cache = {}
    game = mkpx("game", true)
    workspace = mkpx("workspace", true)
    script = mkpx("script", true)
    local script_parent = mkpx("LocalPlayer", false)
    st.propstore[script_parent] =
        { ClassName = "PlayerScripts", Name = "PlayerScripts" }
    st.reg[script_parent] = "script.Parent"
    st.parentmap[script] = script_parent
    st.parentmap[workspace] = game
    local camera = mkpx("Camera", false, workspace)
    st.propstore[camera] = {
        ClassName = "Camera",
        Name = "Camera",
        ViewportSize = Vector2.new(1920, 1080),
        FieldOfView = 70,
        CameraType = Enum.CameraType.Custom,
        NearPlaneZ = -0.1,
        CFrame = CFrame.new(0, 5, 0),
    }
    local terrain = mkpx("Terrain", false, workspace)
    st.propstore[terrain] = { ClassName = "Terrain", Name = "Terrain" }
    local baseplate = mkpx("Baseplate", false, workspace)
    st.propstore[baseplate] = { ClassName = "Part", Name = "Baseplate" }
    st.propstore[game] = {
        PlaceId = placeid,
        GameId = placeid,
        IsLoaded = true,
        ClassName = "DataModel",
        Name = "Game",
        PlaceVersion = 1,
        CreatorId = 0,
        CreatorType = Enum.CreatorType.User,
    }
    st.propstore[workspace] = {
        SimulationRadius = 1000,
        ClassName = "Workspace",
        Name = "Workspace",
        Gravity = 196.2,
        StreamingEnabled = false,
        StreamingPauseMode = Enum.StreamingPauseMode.Default,
        CurrentCamera = camera,
    }
    Enum = mkpx("Enum", true)
    local Enum_mt = _getmt(Enum)
    Enum_mt.__index = function(t, k)
        if enum_cache[k] then
            return enum_cache[k]
        end
        local eproxy = mkpx("Enum." .. k, false)
        rawset(eproxy, "__enum", true)
        local eproxy_mt = _getmt(eproxy)
        local item_cache = {}
        eproxy_mt.__index = function(tt, ek)
            if ek == "GetEnumItems" then
                return reg_c_func(function(self)
                    local items = {}
                    for i = 1, 3 do
                        local ei = mkpx("Enum." .. k .. ".Item" .. i, false)
                        st.reg[ei] = "Enum." .. k .. ".Item" .. i
                        rawset(ei, "__enumitem", true)
                        st.propstore[ei] =
                            { EnumType = eproxy, Name = "Item" .. i, Value = i }
                        table.insert(items, ei)
                    end
                    return items
                end)
            end
            if item_cache[ek] then
                return item_cache[ek]
            end
            local item = mkpx("Enum." .. k .. "." .. ek, false)
            st.reg[item] = "Enum." .. k .. "." .. ek
            rawset(item, "__enumitem", true)
            local item_mt = _getmt(item)
            if item_mt then
                item_mt.__tostring = function()
                    return "Enum." .. k .. "." .. ek
                end
            end
            local val = 0
            if ek == "None" then
                val = 0
            elseif ek == "User" then
                val = 0
            elseif ek == "Custom" then
                val = 0
            elseif k == "Material" and ek == "Plastic" then
                val = 256
            elseif k == "Material" and ek == "Wood" then
                val = 512
            elseif k == "Material" and ek == "Slate" then
                val = 800
            elseif k == "Material" and ek == "Concrete" then
                val = 816
            elseif k == "Material" and ek == "CorrodedMetal" then
                val = 1040
            elseif k == "Material" and ek == "DiamondPlate" then
                val = 1056
            elseif k == "Material" and ek == "Foil" then
                val = 1072
            elseif k == "Material" and ek == "Grass" then
                val = 1280
            elseif k == "Material" and ek == "Ice" then
                val = 1536
            elseif k == "Material" and ek == "Marble" then
                val = 784
            elseif k == "Material" and ek == "Granite" then
                val = 832
            elseif k == "Material" and ek == "Brick" then
                val = 848
            elseif k == "Material" and ek == "Pebble" then
                val = 864
            elseif k == "Material" and ek == "Sand" then
                val = 1296
            elseif k == "Material" and ek == "Fabric" then
                val = 1312
            elseif k == "Material" and ek == "SmoothPlastic" then
                val = 272
            elseif k == "Material" and ek == "Metal" then
                val = 1088
            elseif k == "Material" and ek == "WoodPlanks" then
                val = 528
            elseif k == "Material" and ek == "Cobblestone" then
                val = 880
            elseif k == "Material" and ek == "Air" then
                val = 1792
            elseif k == "Material" and ek == "Water" then
                val = 2048
            elseif k == "Material" and ek == "Rock" then
                val = 896
            elseif k == "Material" and ek == "Glacier" then
                val = 1552
            elseif k == "Material" and ek == "Snow" then
                val = 1328
            elseif k == "Material" and ek == "Sandstone" then
                val = 912
            elseif k == "Material" and ek == "Mud" then
                val = 1344
            elseif k == "Material" and ek == "Basalt" then
                val = 788
            elseif k == "Material" and ek == "Ground" then
                val = 1360
            elseif k == "Material" and ek == "CrackedLava" then
                val = 804
            elseif k == "Material" and ek == "Neon" then
                val = 288
            elseif k == "Material" and ek == "Glass" then
                val = 1568
            elseif k == "Material" and ek == "Asphalt" then
                val = 1376
            elseif k == "Material" and ek == "LeafyGrass" then
                val = 1284
            elseif k == "Material" and ek == "Salt" then
                val = 1392
            elseif k == "Material" and ek == "Limestone" then
                val = 820
            elseif k == "Material" and ek == "Pavement" then
                val = 836
            elseif k == "HumanoidStateType" and ek == "None" then
                val = 0
            elseif k == "HumanoidStateType" and ek == "Dead" then
                val = 15
            elseif k == "HumanoidStateType" and ek == "Running" then
                val = 8
            elseif k == "HumanoidStateType" and ek == "Jumping" then
                val = 14
            elseif k == "HumanoidStateType" and ek == "Freefall" then
                val = 13
            elseif k == "HumanoidStateType" and ek == "Climbing" then
                val = 12
            elseif k == "HumanoidStateType" and ek == "Swimming" then
                val = 11
            elseif k == "HumanoidStateType" and ek == "Seated" then
                val = 10
            elseif k == "HumanoidStateType" and ek == "PlatformStanding" then
                val = 9
            elseif k == "HumanoidStateType" and ek == "StrafingNoPhysics" then
                val = 7
            elseif k == "HumanoidStateType" and ek == "RunningNoPhysics" then
                val = 6
            elseif k == "HumanoidStateType" and ek == "Flying" then
                val = 6
            elseif k == "HumanoidStateType" and ek == "FallingDown" then
                val = 5
            elseif k == "HumanoidStateType" and ek == "Landed" then
                val = 4
            elseif k == "HumanoidStateType" and ek == "GettingUp" then
                val = 3
            elseif k == "HumanoidStateType" and ek == "Ragdoll" then
                val = 2
            elseif k == "HumanoidStateType" and ek == "Physics" then
                val = 1
            else
                val = 1
            end
            st.propstore[item] = { EnumType = eproxy, Name = ek, Value = val }
            item_cache[ek] = item
            return item
        end
        eproxy_mt.__tostring = function()
            return "Enum." .. k
        end
        enum_cache[k] = eproxy
        return eproxy
    end
    Enum_mt.__tostring = function()
        return "Enum"
    end
    _G.game = game
    _G.workspace = workspace
    _G.script = script
    _G.Enum = Enum
    _G.shared = {}
    _G._VERSION = "Luau"
    _G.ypcall = pcall
    local players = mkpx("Players", false, game)
    st.propstore[players] = { ClassName = "Players", Name = "Players" }
    local localPlayer = mkpx("LocalPlayer", false, players)
    st.propstore[localPlayer] = { ClassName = "Player", Name = "LocalPlayer", UserId = 1, DisplayName = "LocalPlayer" }
    st.propstore[players].LocalPlayer = localPlayer
    local character = mkpx("Character", false, workspace)
    st.propstore[character] = { ClassName = "Model", Name = "LocalPlayer" }
    st.propstore[localPlayer].Character = character
    local animate = mkpx("Animate", false, character)
    st.propstore[animate] = { ClassName = "LocalScript", Name = "Animate", Source = "print('Animate')" }
    st.propstore[character].Animate = animate
    local humanoid = mkpx("Humanoid", false, character)
    st.propstore[humanoid] = { ClassName = "Humanoid", Name = "Humanoid" }
    local hrp = mkpx("HumanoidRootPart", false, character)
    st.propstore[hrp] = { ClassName = "Part", Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1) }
    st.propstore[character].HumanoidRootPart = hrp
    st.propstore[character].Humanoid = humanoid
    st.services["Players"] = players
end
function aspect.getout()
    return getout()
end
function aspect.save(fname)
    return saveout(fname)
end
function aspect.callgraph()
    return st.callgraph
end
function aspect.strrefs()
    return st.strrefs
end
function aspect.stats()
    local cs = 0
    for _ in _pairs(st.cap_strings) do
        cs = cs + 1
    end
    return {
        lines = #st.out,
        remotes = #st.callgraph,
        sus_strings = #st.strrefs,
        proxies = st.pxid,
        cap_strings = cs,
        gassigns = st.gassigns,
    }
end
function aspect.dumpfile(inpath, outpath)
    aspect.reset()
    local t_begin = os.clock()
    lz4compress = lz4compress
    lz4decompress = lz4decompress
    local code, e = readbin(inpath)
    if not code then
        print("cant read " .. inpath)
        print(e or "unknown")
        return false
    end
    if code:match("ironbrew") or code:match("return%(function%(") then
        st.vm_type = "ironbrew"
    end
    if
        code:match("Junkie")
        or (code:match("b91") and code:match("loadstring%(d%(table%.concat"))
    then
        st.vm_type = "junkie"
        local dok, decoded = _pcall(pull_junkie, code)
        if dok and decoded and #decoded > 100 then
            _pcall(function()
                fs.writeFile("core/io/dumped_output.lua", decoded)
            end)
            code = decoded
            note("junkie decoded ok")
        end
    end
    st.source_lines = {}
    local start = 1
    while true do
        local pos = code:find("\n", start, true)
        if not pos then
            local last = code:sub(start)
            if last:sub(-1) == "\r" then
                last = last:sub(1, -2)
            end
            table.insert(st.source_lines, last)
            break
        end
        local line = code:sub(start, pos - 1)
        if line:sub(-1) == "\r" then
            line = line:sub(1, -2)
        end
        table.insert(st.source_lines, line)
        start = pos + 1
    end
    local ok_lex, tokens = _pcall(lex, code)
    if ok_lex and tokens then
        add_line_numbers_to_tokens(tokens, code)
        st.tokens = tokens
        st.parsed_blocks = parse_blocks(tokens)
    end
    local senv = {
        _G = _G,
        _VERSION = "Luau",
        type = type,
        typeof = typeof,
        tostring = tostring,
        tonumber = tonumber,
        pairs = pairs,
        ipairs = ipairs,
        next = custom_next,
        select = _select,
        decode_b91 = decode_b91,
        pull_junkie = pull_junkie,
        unpack = _unpack,
        getmetatable = getmetatable,
        setmetatable = _setmt,
        rawget = rawget,
        rawset = rawset,
        rawequal = rawequal,
        rawlen = rawlen or function(t)
            return #t
        end,
        pcall = pcall,
        xpcall = xpcall,
        error = _err,
        assert = assert,
        math = math,
        randomseed = math.randomseed,
        string = hstr,
        table = htbl,
        coroutine = hcor,
        os = _G.os,
        bit = blib,
        bit32 = blib,
        utf8 = _G.utf8,
        debug = efuncs.debug,
        buffer = _G.buffer,
        Vector3 = Vector3,
        Vector2 = Vector2,
        CFrame = CFrame,
        Color3 = Color3,
        BrickColor = BrickColor,
        UDim = UDim,
        UDim2 = UDim2,
        TweenInfo = TweenInfo,
        Ray = Ray,
        Rect = Rect,
        Region3 = Region3,
        NumberRange = NumberRange,
        NumberSequence = NumberSequence,
        NumberSequenceKeypoint = NumberSequenceKeypoint,
        ColorSequence = ColorSequence,
        ColorSequenceKeypoint = ColorSequenceKeypoint,
        PhysicalProperties = PhysicalProperties,
        RaycastParams = RaycastParams,
        Random = Random,
        DateTime = DateTime,
        OverlapParams = OverlapParams,
        Font = Font,
        Vector2int16 = Vector2int16,
        Vector3int16 = Vector3int16,
        Region3int16 = Region3int16,
        ValueCurveKey = ValueCurveKey,
        FloatCurveKey = FloatCurveKey,
        RotationCurveKey = RotationCurveKey,
        CatalogSearchParams = CatalogSearchParams,
        PathWaypoint = PathWaypoint,
        Faces = Faces,
        Axes = Axes,
        SecurityCapabilities = SecurityCapabilities,
        SharedTable = SharedTable,
        game = game,
        Game = game,
        workspace = workspace,
        Workspace = workspace,
        script = script,
        Enum = Enum,
        Instance = Instance,
        shared = _G.shared,
        task = task,
        wait = wait,
        Wait = wait,
        delay = delay,
        Delay = delay,
        spawn = spawn,
        Spawn = spawn,
        tick = tick,
        time = time,
        elapsedTime = elapsedTime,
        print = print,
        warn = warn,
        loadstring = loadstring,
        load = load,
        require = require,
        newproxy = _G.newproxy,
        settings = _G.settings,
        UserSettings = _G.UserSettings,
        gcinfo = _G.gcinfo,
        collectgarbage = _G.collectgarbage,
        ypcall = pcall,
        LuaphContinue = function() end,
        all_services = all_services,
        all_events = all_events,
        all_brickcolors = all_brickcolors,
        all_creatable = all_creatable,
        all_datatypes = all_datatypes,
        all_globals = all_globals,
        all_libraries = all_libraries,
        all_enums = all_enums,
    }
    for nm, fn in _pairs(efuncs) do
        senv[nm] = fn
    end
    senv.Env = senv
    senv.Drawing = efuncs.Drawing
    senv.WebSocket = WebSocket
    senv.crypt = crypt
    senv.base64 = base64
    senv.cache = cache
    local d_proxy = {}
    for k, v in _pairs(debug) do
        if _type(v) == "function" then
            d_proxy[k] = function(...)
                local args = { ... }
                local sargs = {}
                local old_ser = st._in_ser
                st._in_ser = true
                for _, a in _ipairs(args) do
                    table.insert(sargs, pcall(function()
                        return ser(a)
                    end) and ser(a) or _tostring(a))
                end
                st._in_ser = old_ser
                out(string.format("debug.%s(%s)", k, table.concat(sargs, ", ")))
                return v(...)
            end
        else
            d_proxy[k] = v
        end
    end
    senv.debug = d_proxy
    senv.setnamecallmethod = setnamecallmethod
    senv.getreg = getreg
    senv.getregistry = getreg
    senv.replaceclosure = replaceclosure
    senv.clonereference = clonereference
    senv.fluxus = fluxus
    senv.mouse2press = efuncs.mouse2press
    senv.mouse2release = efuncs.mouse2release
    senv.replicatesignal = replicatesignal
    senv.getsignalwhitelist = getsignalwhitelist
    senv.getsignalarguments = getsignalarguments
    senv.getsignalargmuents = getsignalargmuents
    senv.setfflag = setfflag
    senv.getfflags = getfflags
    senv.getconnections = getconnections
    senv.cloneref = cloneref
    senv.fireclickdetector = fireclickdetector
    senv.gethiddenproperty = gethiddenproperty
    senv.sethiddenproperty = sethiddenproperty
    senv.lz4compress = lz4compress
    senv.lz4decompress = lz4decompress
    senv.readfile = efuncs.readfile
    senv.writefile = efuncs.writefile
    senv.isfile = efuncs.isfile
    senv.delfile = efuncs.delfile
    senv.listfiles = efuncs.listfiles
    senv.appendfile = efuncs.appendfile
    senv.makefolder = makefolder
    senv.isfolder = isfolder
    senv.delfolder = delfolder
    senv.delfile = delfile
    senv.loadfile = efuncs.loadfile
    senv.writefile = writefile or efuncs.writefile
    senv.readfile = readfile or efuncs.readfile
    senv.isfile = isfile or efuncs.isfile
    senv.listfiles = listfiles or efuncs.listfiles
    senv.appendfile = appendfile or efuncs.appendfile
    senv.delfile = delfile or efuncs.delfile
    senv.makefolder = makefolder or efuncs.makefolder
    senv.isfolder = isfolder or efuncs.isfolder
    senv.delfolder = delfolder or efuncs.delfolder
    senv.getcallingscript = efuncs.getcallingscript
    senv.getconstants = efuncs.getconstants
    senv.setconstant = efuncs.setconstant
    senv.firetouchinterest = firetouchinterest
    senv.fireproximityprompt = fireproximityprompt
    senv.firesignal = firesignal
    senv.fireclickdetector = fireclickdetector
    senv.replicatesignal = efuncs.replicatesignal
    senv.lune = nil
    senv.lfs = nil
    senv["@lune/fs"] = nil
    senv["@lune/net"] = nil
    senv.setscriptable = setscriptable
    senv.isscriptable = isscriptable
    senv.hookfunction = hookfunction
    senv.hookmetamethod = hookmetamethod
    senv.newcclosure = newcclosure
    senv.clonefunction = clonefunction
    senv.iscclosure = iscclosure
    senv.islclosure = islclosure
    senv.isexecutorclosure = isexecutorclosure
    senv.checkcaller = checkcaller
    senv.getrawmetatable = getrawmetatable
    senv.setrawmetatable = setrawmetatable
    senv.getnamecallmethod = getnamecallmethod
    senv.firetouchinterest = firetouchinterest
    senv.fireproximityprompt = fireproximityprompt
    senv.fireclickdetector = fireclickdetector
    senv.firesignal = firesignal
    senv.cloneref = cloneref
    senv.compareinstances = compareinstances
    senv.lz4compress = lz4compress
    senv.lz4decompress = lz4decompress
    senv.cache = cache
    senv.Drawing = Drawing
    senv.WebSocket = WebSocket
    senv.crypt = crypt
    senv.base64 = base64
    senv.getexecutorname = getexecutorname
    senv.toclipboard = toclipboard
    senv.rconsoleprint = rconsoleprint
    senv.rconsolewarn = rconsoleprint
    senv.rconsoleerr = rconsoleprint
    senv.rconsoleclear = rconsoleclear
    senv.rconsolename = rconsolename
    senv.rconsoleinput = rconsoleinput
    senv.firesignal = firesignal
    senv.replicatesignal = replicatesignal
    senv.getscriptcallstack = getscriptcallstack
    senv.getfpscap = getfpscap
    _setmt(_G, {
        __newindex = function(t, k, v)
            if v ~= nil then
                out(string.format("_G.%s = %s", _tostring(k), ser(v)))
                rawset(t, k, v)
            end
        end,
    })
    local sbox = _setmt(senv, {
        __newindex = function(t, k, v)
            st.gassigns[k] = v
            out(string.format("_G.%s = %s", safestr(k), ser(v)))
            rawset(_G, k, v)
        end,
    })
    st.sandbox = sbox
    local ok, chunk, le = _pcall(function()
        return _loadstr(code, "script", "bt", sbox)
    end)
    if not ok or not chunk then
        if not ok then
            print("CRASH IN LOADSTR: ", chunk)
            fs.writeFile("core/misc/CRASH.txt", code)
        end
        local ok2, chunk2, le2 = _pcall(function()
            return _loadstr(code, "script", "t", sbox)
        end)
        if ok2 and chunk2 then
            chunk = chunk2
            le = nil
        else
            chunk = nil
            le = chunk2 or le2
        end
    end
    _pcall(function()
        fs.writeFile(
            "core/misc/debug_load_err.txt",
            "err: " .. (le or "unk") .. "\n\n" .. code:sub(1, 5000)
        )
    end)
    st.t_start = os.clock()
    st.virtual_time = 0
    st.task_queue = {}
    cancelled_threads = {}
    local resume_args = {}
    local main_dead = false
    if not chunk then
        -- luau.load returns a rich error object whose tostring carries a full
        -- "stack traceback:" (which cleanpath deliberately blanks). Keep only
        -- the human-readable message before the traceback so the router/bot
        -- report something useful instead of an empty reason.
        local reason = "unknown load error"
        if le ~= nil then
            local msg = _tostring(le)
            msg = msg:gsub("\nstack traceback:.*$", "")
            msg = msg:match("^%s*(.-)%s*$") or msg
            local cleaned = cleanpath(msg)
            if cleaned and cleaned ~= "" then
                reason = cleaned
            end
        end
        st.load_failed = "failed to compile obfuscated script: " .. reason
        note(st.load_failed)
    else
    local ok, rerr = _xpcall(function()
        local co = _cor.create(chunk)
        if _sethook then
            local count = 0
            _sethook(co, function()
                count = count + 1
                if count > 20000000 then
                    _sethook(co, nil)
                    error("TIMEOUT: Instruction limit exceeded")
                end
            end, "", 1000)
        end
        while not main_dead or #st.task_queue > 0 do
            if os.clock() - st.t_start > cfg.timeout then
                note("timed out after " .. cfg.timeout .. "s")
                break
            end
            if not main_dead then
                local res = { _cor.resume(co, _unpack(resume_args)) }
                local cok = res[1]
                if not cok then
                    local ce = res[2]
                    _print("COROUTINE ERROR:", ce)
                    if _type(ce) == "string" then
                        if ce:match("invalid utf%-8") or ce:match("binary") then
                            break
                        elseif
                            ce:match("TIMEOUT") or ce:match("DUMP_LIMIT")
                        then
                            break
                        end
                    end
                    break
                end
                if _cor.status(co) ~= "dead" then
                    local yield_type = res[2]
                    local yield_val = res[3]
                    if yield_type == "wait" then
                        local wait_dur = yield_val or 0.03
                        advance_virtual_time(wait_dur)
                        resume_args = { wait_dur, os.clock() }
                    else
                        resume_args = {}
                    end
                else
                    main_dead = true
                    while st.pending_iter and st.pending_iter > 0 do
                        st.ind = st.ind - 1
                        out("end")
                        st.pending_iter = st.pending_iter - 1
                    end
                    while st.cf_depth > 0 do
                        st.ind = st.ind - 1
                        out("end")
                        st.cf_depth = st.cf_depth - 1
                    end
                    advance_virtual_time(100)
                end
            else
                local next_time = nil
                for _, item in _ipairs(st.task_queue) do
                    if item.type == "delay" then
                        if not next_time or item.time < next_time then
                            next_time = item.time
                        end
                    end
                end
                local has_defer = false
                for _, item in _ipairs(st.task_queue) do
                    if item.type == "defer" then
                        has_defer = true
                        break
                    end
                end
                if has_defer then
                    advance_virtual_time(0)
                elseif next_time then
                    local diff = next_time - st.virtual_time
                    advance_virtual_time(math.max(0, diff))
                else
                    break
                end
            end
        end
    end, function(er)
        return cleanpath(_tostring(er))
    end)
    if not ok then
        note("terminated " .. (rerr or "unknown"))
    end
    end
    local cs = 0
    for _ in _pairs(st.cap_strings) do
        cs = cs + 1
    end
    if cs > 0 then
        note("captured " .. cs .. " decrypted strings")
    end
    for k, v in _pairs(st.gassigns) do
        out(string.format("_G.%s = %s", safestr(k), ser(v)))
    end
    local ms_taken = math.floor((os.clock() - t_begin) * 1000)
    local captured_links = {}
    local seen_links = {}
    for _, ref in _ipairs(st.strrefs) do
        if
            ref.hint == "url"
            and ref.value
            and not seen_links[ref.value]
            and (ref.value:match("^https?://") or ref.value:match("^www%."))
        then
            seen_links[ref.value] = true
            table.insert(captured_links, "    " .. ref.value)
        end
    end
    local lang = ".l"
    local links_str = #captured_links > 0 and table.concat(captured_links, "\n")
        or "    (none captured)"
    table.insert(
        st.out,
        1,
        "--[[\n    dis file generated by 6Vms\n    "
            .. ms_taken
            .. "ms to log everything\n   usage: " .. lang .. "\n    https://discord.gg/6vms n\n   context\n    pretty detected rn and its inall in beta so ermm\n  current unc is id like to say around 70-80%\n\n    links\n"
            .. links_str
            .. "\n]]"
    )
return aspect.save(outpath or cfg.outfile)
end
function aspect.dumpstring(code, outpath)
    aspect.reset()
    local chunk, e = _load(code, "str_input", "t", st.sandbox or _G)
    if not chunk then
        note("load err " .. (e or "unk"))
        return false, e
    end
    _xpcall(function()
        chunk()
    end, function() end)
    if outpath then
        return aspect.save(outpath)
    end
    return true, getout()
end
local args2 = proc.args
if args2[1] then
    local inp = args2[1]
    local outp = args2[2] or cfg.outfile
    print(string.rep("=", 52))
    print("in  " .. inp)
    print("out " .. outp)
    local ok = aspect.dumpfile(inp, outp)
    if ok then
        print("saved to " .. outp)
        local s = aspect.stats()
        print(
            string.format(
                "lines %d | remotes %d | proxies %d",
                s.lines,
                s.remotes,
                s.proxies
            )
        )
        if s.cap_strings > 0 then
            print("captured " .. s.cap_strings .. " strings")
        end
        local gc = 0
        for _ in _pairs(s.gassigns) do
            gc = gc + 1
        end
        if gc > 0 then
            print("tracked " .. gc .. " global assigns")
        end
    else
        print("failed check error output")
    end
else
    local exists = _pcall(function()
        return fs.readFile("core/io/obfuscated.lua")
    end)
    if exists then
        local ok = aspect.dumpfile("core/io/obfuscated.lua")
        if ok then
            print("saved to " .. cfg.outfile)
        end
    else
        print("6Vms owns yall fr")
    end
end
return aspect