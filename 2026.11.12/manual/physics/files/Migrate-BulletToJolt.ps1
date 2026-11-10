# Copyright © Plain Concepts S.L.U. All rights reserved. Use is subject to license terms.

<#
.SYNOPSIS
Migrates an Evergine project from the legacy Bullet/Physics3D API to Jolt.

.DESCRIPTION
The command is a dry run unless -Apply is supplied. It recursively migrates source
scene and prefab YAML, removes Bullet package/project references, converts common
C# types, members, queries and behavior idioms, and reports every conversion that
cannot preserve Bullet semantics exactly.

Generated assets are intentionally not edited. Rebuild the content after the
source .wescene and .weprefab files have been migrated.

Bullet categories collided unless masked; Jolt isolates them, so a CollisionMatrix
is built from the legacy masks. -StabilizeConstraintChains and -TuneVehicleChassis
opt in to mass/chassis retuning; -PreserveConstraintMasses is accepted and ignored.

.EXAMPLE
./Migrate-BulletToJolt.ps1 -ProjectPath D:\Projects\MyGame

.EXAMPLE
./Migrate-BulletToJolt.ps1 -ProjectPath D:\Projects\MyGame -Apply

.EXAMPLE
./Migrate-BulletToJolt.ps1 -ProjectPath D:\Projects\MyGame -Apply -AssetsOnly

.EXAMPLE
./Migrate-BulletToJolt.ps1 -ProjectPath D:\Projects\MyGame\MyGame.Windows.sln -Apply

.EXAMPLE
./Migrate-BulletToJolt.ps1 -ProjectPath D:\Projects\MyGame -Apply -StabilizeConstraintChains -TuneVehicleChassis
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $ProjectPath,

    [switch] $Apply,

    [switch] $AssetsOnly,

    [switch] $NoBackup,

    [switch] $StabilizeConstraintChains,

    [switch] $TuneVehicleChassis,

    [switch] $PreserveConstraintMasses,

    [string] $ReportPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:Invariant = [System.Globalization.CultureInfo]::InvariantCulture
$script:Findings = New-Object 'System.Collections.Generic.List[object]'
$script:ChangeCount = 0
$script:ConvertedComponentCount = 0
$script:StabilizedConstraintBodyCount = 0
$script:ReferenceVehicleMass = 0.0
$script:CurrentAssetVehicleMass = 0.0
$script:CurrentAssetWheelRadius = 0.35
$script:StabilizedConstraintIds = @{}
$script:LegacyVehicleComponents = @{}
$script:LegacyWheelComponents = @{}
$script:CollisionEvidence = New-Object 'System.Collections.Generic.List[object]'
$script:ProjectCollisionMatrix = $null
$script:CollisionMatrixTargets = 0
$script:Context = $null

$script:TypeMappings = @{
    'Evergine.Framework.Physics3D.RigidBody3D' = @('Evergine.Framework.Physics.RigidBody', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.StaticBody3D' = @('Evergine.Framework.Physics.StaticBody', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.CharacterController3D' = @('Evergine.Framework.Physics.CharacterController', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.BoxCollider3D' = @('Evergine.Framework.Physics.BoxCollider', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.SphereCollider3D' = @('Evergine.Framework.Physics.SphereCollider', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.CapsuleCollider3D' = @('Evergine.Framework.Physics.CapsuleCollider', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.CylinderCollider3D' = @('Evergine.Framework.Physics.CylinderCollider', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.ConeCollider3D' = @('Evergine.Framework.Physics.TaperedCylinderCollider', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.MeshCollider3D' = @('Evergine.Framework.Physics.MeshCollider', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.HingeJoint3D' = @('Evergine.Framework.Physics.HingeConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.FixedJoint3D' = @('Evergine.Framework.Physics.FixedConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.GearJoint3D' = @('Evergine.Framework.Physics.GearConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.PointToPointJoint3D' = @('Evergine.Framework.Physics.PointConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.SliderJoint3D' = @('Evergine.Framework.Physics.SliderConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.ConeTwistJoint3D' = @('Evergine.Framework.Physics.SwingTwistConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.Generic6DofJoint3D' = @('Evergine.Framework.Physics.SixDOFConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.SpringJoint3D' = @('Evergine.Framework.Physics.SixDOFConstraint', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.PhysicVehicle3D' = @('Evergine.Framework.Physics.WheeledVehicleController', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.PhysicWheel3D' = @('Evergine.Framework.Physics.VehicleWheel', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.RayEmitter' = @('Evergine.Framework.Physics.RayEmitter', 'Evergine.Framework')
    'Evergine.Framework.Physics3D.SweepTestEmitter' = @('Evergine.Framework.Physics.SweepTestEmitter', 'Evergine.Framework')
    'Evergine.Bullet.BulletPhysicManager3D' = @('Evergine.Framework.Physics.PhysicsManager', 'Evergine.Framework')
    'Evergine.Framework.Managers.PhysicManager3D' = @('Evergine.Framework.Physics.PhysicsManager', 'Evergine.Framework')
}

$script:SourceTypeMappings = [ordered]@{
    'BulletPhysicManager3D' = 'PhysicsManager'
    'ISphereColliderShape3D' = 'SphereCollider'
    'IBoxColliderShape3D' = 'BoxCollider'
    'ICapsuleColliderShape3D' = 'CapsuleCollider'
    'ICylinderColliderShape3D' = 'CylinderCollider'
    'IConeColliderShape3D' = 'TaperedCylinderCollider'
    'IMeshColliderShape3D' = 'MeshCollider'
    'IColliderShape3D' = 'Collider'
    'CharacterController3D' = 'CharacterController'
    'PointToPointJoint3D' = 'PointConstraint'
    'Generic6DofSpringJoint3D' = 'SixDOFConstraint'
    'Generic6DofJoint3D' = 'SixDOFConstraint'
    'ConeTwistJoint3D' = 'SwingTwistConstraint'
    'PhysicVehicle3D' = 'WheeledVehicleController'
    'PhysicWheel3D' = 'VehicleWheel'
    'CylinderCollider3D' = 'CylinderCollider'
    'CapsuleCollider3D' = 'CapsuleCollider'
    'SphereCollider3D' = 'SphereCollider'
    'BoxCollider3D' = 'BoxCollider'
    'MeshCollider3D' = 'MeshCollider'
    'ConeCollider3D' = 'TaperedCylinderCollider'
    'Collider3D' = 'Collider'
    'HingeJoint3D' = 'HingeConstraint'
    'SliderJoint3D' = 'SliderConstraint'
    'FixedJoint3D' = 'FixedConstraint'
    'GearJoint3D' = 'GearConstraint'
    'RigidBody3D' = 'RigidBody'
    'StaticBody3D' = 'StaticBody'
    'PhysicBody3D' = 'PhysicsBody'
    'PhysicManager3D' = 'PhysicsManager'
    'CollisionCategory3D' = 'CollisionCategory'
    'CollisionInfo3D' = 'CollisionInfo'
    'HitResult3D' = 'RayCastHit'
}

# Bullet member renames shared by assets, object initializers and typed member access. Keys are
# legacy type-name patterns.
$script:MemberRenames = @{
    'RigidBody3D|StaticBody3D|CharacterController3D' = 'CollisionCategories=CollisionCategory'
    'CharacterController3D' = 'MaxSlope=MaxSlopeAngle OnGround=IsOnGround'
    'ConeCollider3D' = 'Radius=BottomRadius'
    '\w*Joint3D' = 'AutoConfigureConnected=AutoConfigureConnectedAnchor OverrideNumSolverIterations=SolverVelocityIterationsOverride'
    'HingeJoint3D' = 'MotorTargetVelocity=TargetAngularVelocity LowerAngularLimit=MinAngle UpperAngularLimit=MaxAngle'
    'SliderJoint3D' = 'MaxLinearMotorForce=MaxMotorForce TargetLinearMotorVelocity=TargetVelocity LowerLinearLimit=MinDistance UpperLinearLimit=MaxDistance'
    'Generic6DofJoint3D|SpringJoint3D' = 'LowerLinearLimit=TranslationMin UpperLinearLimit=TranslationMax LowerAngularLimit=RotationMin UpperAngularLimit=RotationMax'
    'ConeTwistJoint3D' = 'Axis=TwistAxis MotorTarget=TargetOrientation'
    'BulletPhysicManager3D|PhysicManager3D' = 'PerformPhysicSteps=IsSimulationEnabled MaxSubSteps=MaxStepsPerFrame'
}

$script:CommonBodyProperties = @(
    'Id', 'IsEnabled', 'Friction', 'Restitution', 'CollisionCategory', 'IsSensor',
    'ShowAdvanced', 'EnhancedInternalEdgeRemoval', 'SurfaceVelocity'
)

$script:CommonConstraintProperties = @(
    'Id', 'IsEnabled', 'ConnectedEntityPath', 'ConnectedEntity', 'Anchor', 'AutoConfigureConnectedAnchor',
    'ConnectedAnchor', 'CollideConnected', 'IsBreakable', 'BreakForce', 'BreakTorque',
    'IsHolding', 'Priority', 'SolverVelocityIterationsOverride', 'SolverPositionIterationsOverride'
)

$script:AllowedProperties = @{
    'Evergine.Framework.Physics.RigidBody' = $script:CommonBodyProperties + @(
        'IsKinematic', 'MotionQuality', 'AllowedDegreesOfFreedom', 'Mass', 'InertiaMultiplier',
        'CenterOfMassOffset', 'LinearDamping', 'AngularDamping', 'GravityFactor',
        'MaxLinearVelocity', 'MaxAngularVelocity', 'AllowSleeping', 'ApplyGyroscopicForce',
        'CollideKinematicVsNonDynamic', 'SolverVelocityIterationsOverride', 'SolverPositionIterationsOverride'
    )
    'Evergine.Framework.Physics.StaticBody' = $script:CommonBodyProperties
    'Evergine.Framework.Physics.CharacterController' = @(
        'Id', 'IsEnabled', 'Radius', 'Height', 'MaxSlopeAngle', 'Up', 'Mass', 'MaxStrength',
        'StepHeight', 'StickToFloorDistance', 'PredictiveContactDistance', 'CharacterPadding',
        'PenetrationRecoverySpeed', 'EnableInnerBody', 'EnhancedInternalEdgeRemoval', 'ApplyGravity',
        'SupportingVolumeOffset', 'CollisionCategory'
    )
    'Evergine.Framework.Physics.BoxCollider' = @('Id', 'IsEnabled', 'Offset', 'RotationOffset', 'Density', 'UseModelBounds', 'Size', 'ConvexRadius')
    'Evergine.Framework.Physics.SphereCollider' = @('Id', 'IsEnabled', 'Offset', 'RotationOffset', 'Density', 'UseModelBounds', 'Radius')
    'Evergine.Framework.Physics.CapsuleCollider' = @('Id', 'IsEnabled', 'Offset', 'RotationOffset', 'Density', 'UseModelBounds', 'Radius', 'Height')
    'Evergine.Framework.Physics.CylinderCollider' = @('Id', 'IsEnabled', 'Offset', 'RotationOffset', 'Density', 'UseModelBounds', 'Radius', 'Height', 'ConvexRadius')
    'Evergine.Framework.Physics.TaperedCylinderCollider' = @('Id', 'IsEnabled', 'Offset', 'RotationOffset', 'Density', 'UseModelBounds', 'TopRadius', 'BottomRadius', 'Height', 'ConvexRadius')
    'Evergine.Framework.Physics.MeshCollider' = @('Id', 'IsEnabled', 'Offset', 'RotationOffset', 'Density', 'MeshType', 'ConvexRadius')
    'Evergine.Framework.Physics.HingeConstraint' = $script:CommonConstraintProperties + @(
        'Axis', 'NormalAxis', 'MinAngle', 'MaxAngle', 'MaxFrictionTorque', 'LimitsSpring',
        'MotorMode', 'TargetAngularVelocity', 'TargetAngle', 'MaxMotorTorque'
    )
    'Evergine.Framework.Physics.FixedConstraint' = $script:CommonConstraintProperties
    'Evergine.Framework.Physics.GearConstraint' = $script:CommonConstraintProperties + @('Axis', 'ConnectedAxis', 'Ratio')
    'Evergine.Framework.Physics.PointConstraint' = $script:CommonConstraintProperties
    'Evergine.Framework.Physics.SliderConstraint' = $script:CommonConstraintProperties + @(
        'Axis', 'NormalAxis', 'MinDistance', 'MaxDistance', 'MaxFrictionForce', 'LimitsSpring',
        'MotorMode', 'TargetVelocity', 'TargetPosition', 'MaxMotorForce'
    )
    'Evergine.Framework.Physics.SwingTwistConstraint' = $script:CommonConstraintProperties + @(
        'TwistAxis', 'PlaneAxis', 'NormalHalfConeAngle', 'PlaneHalfConeAngle', 'TwistMinAngle',
        'TwistMaxAngle', 'MaxFrictionTorque', 'SwingMotorMode', 'TwistMotorMode',
        'TargetAngularVelocity', 'MaxSwingTorque', 'MaxTwistTorque', 'MotorSpring'
    )
    'Evergine.Framework.Physics.SixDOFConstraint' = $script:CommonConstraintProperties + @(
        'FreeAxes', 'TranslationMin', 'TranslationMax', 'RotationMin', 'RotationMax',
        'LimitsSpring', 'MaxMotorForce', 'MaxMotorTorque', 'MotorSpring'
    )
    'Evergine.Framework.Physics.WheeledVehicleController' = @(
        'Id', 'IsEnabled', 'Up', 'Forward', 'MaxPitchRollAngle', 'CollisionTesterType',
        'EngineMaxTorque', 'EngineMinRPM', 'EngineMaxRPM', 'TransmissionMode', 'ShiftUpRPM',
        'ShiftDownRPM', 'ClutchStrength', 'GearRatios', 'ReverseGearRatios', 'FrontWheelLeft',
        'FrontWheelRight', 'RearWheelLeft', 'RearWheelRight', 'FrontWheelDrive', 'RearWheelDrive',
        'AntiRollStiffness'
    )
    'Evergine.Framework.Physics.VehicleWheel' = @(
        'Id', 'IsEnabled', 'Radius', 'Width', 'UseModelBounds', 'SuspensionDirection', 'SteeringAxis',
        'SuspensionMinLength', 'SuspensionMaxLength', 'SuspensionPreloadLength',
        'SuspensionSpring', 'MaxSteerAngle', 'MaxBrakeTorque', 'MaxHandBrakeTorque',
        'Inertia', 'AngularDamping', 'LongitudinalFrictionScale', 'LateralFrictionScale',
        'UpdateEntityTransform'
    )
    'Evergine.Framework.Physics.PhysicsManager' = @(
        'Id', 'IsEnabled', 'UpdateOrder', 'MaxBodies', 'MaxBodyPairs', 'MaxContactConstraints',
        'TempAllocatorSizeMB', 'WorkerThreadCount', 'Gravity', 'SolverVelocityIterations',
        'SolverPositionIterations', 'SpeculativeContactDistance', 'PenetrationSlop',
        'TimeBeforeSleep', 'PointVelocitySleepThreshold', 'AllowSleeping',
        'DeterministicSimulation', 'FixedTimeStep', 'MaxStepsPerFrame', 'CollisionSteps',
        'InterpolateTransforms', 'TimeScale', 'IsSimulationEnabled', 'AutoOptimizeBroadPhase',
        'CategoryNames', 'CollisionMatrix', 'DebugFlags'
    )
    'Evergine.Framework.Physics.RayEmitter' = @('Id', 'IsEnabled', 'UpdateOrder', 'Mask', 'Distance', 'All', 'Force', 'IncludeSensors')
    'Evergine.Framework.Physics.SweepTestEmitter' = @('Id', 'IsEnabled', 'UpdateOrder', 'Mask', 'Distance', 'All', 'IncludeSensors')
}

# Removing these Bullet-only properties loses nothing: no-ops, or values equal to the Bullet default.
$script:NoOpLegacyProperties = '^(?:DebugDrawSize|NeedsFeedback|ExecutionState|DrawFlags|TargetOrientation|MaskBits|OverrideVehicleSettings|IsDriveWheel|SearchVehicle|PhysicVehicleEntityPath|PhysicWorldResolution|Damping|MaxMotorImpulse|UseMotor|(?:UseSpring|EquilibriumPoint|SpringStiffness|SpringDamping)(?:Translation|Rotation)[XYZ])$'
$script:LegacyPropertyDefaults = @{
    UpdateOrder = '0.5'; CcdMotionThreshold = '0'; CcdSweptSphereRadius = '0.2'; RollingFriction = '0'; Restitution = '0'
    Friction = '0.5'; IsSensor = 'true|false'; LimitSoftness = '0.9|1'; LimitBiasFactor = '0.3'; LimitRelaxationFactor = '1'
    AngularOnly = 'false'; FixThresh = '0.05'; MaxSuspensionForce = '6000'; ApplySpeculativeContactRestitution = 'false'
    AngularVelocity = '0,0,0'; LinearVelocity = '0,0,0'; Gravity = '0,0,0'; LocalInertia = '0,0,0'; Axis = '1,0,0'; ConnectedAxis = '1,0,0'
}

function Add-Finding {
    param(
        [string] $Severity,
        [string] $Code,
        [string] $File,
        [int] $Line,
        [string] $Message
    )

    $script:Findings.Add([pscustomobject]@{
        Severity = $Severity
        Code = $Code
        File = $File
        Line = $Line
        Message = $Message
    })
}

function Get-MemberRenames {
    param([string] $Type)

    foreach ($key in $script:MemberRenames.Keys) {
        if ($Type -match ('(?:^|\.)(?:' + $key + ')$')) {
            foreach ($pair in $script:MemberRenames[$key].Split(' ')) { , $pair.Split('=') }
        }
    }
}

function Add-Change {
    $script:ChangeCount++
}

function Get-TextFile {
    param([string] $Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $preambleLength = 0

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $encoding = New-Object System.Text.UTF8Encoding($true)
        $preambleLength = 3
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $encoding = New-Object System.Text.UnicodeEncoding($false, $true)
        $preambleLength = 2
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $encoding = New-Object System.Text.UnicodeEncoding($true, $true)
        $preambleLength = 2
    }

    $text = $encoding.GetString($bytes, $preambleLength, $bytes.Length - $preambleLength)
    $newLine = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }

    return [pscustomobject]@{
        Text = $text
        Encoding = $encoding
        HasPreamble = $preambleLength -gt 0
        NewLine = $newLine
    }
}

function Set-TextFile {
    param(
        [string] $Path,
        [string] $Text,
        [System.Text.Encoding] $Encoding,
        [bool] $HasPreamble
    )

    $body = $Encoding.GetBytes($Text)
    if (-not $HasPreamble) {
        [System.IO.File]::WriteAllBytes($Path, $body)
        return
    }

    $preamble = $Encoding.GetPreamble()
    $result = New-Object byte[] ($preamble.Length + $body.Length)
    [System.Array]::Copy($preamble, 0, $result, 0, $preamble.Length)
    [System.Array]::Copy($body, 0, $result, $preamble.Length, $body.Length)
    [System.IO.File]::WriteAllBytes($Path, $result)
}

function Get-PropertyRange {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name
    )

    $prefix = ' ' * $Indent
    $wanted = '^' + [regex]::Escape($prefix + $Name) + ':\s*(?<value>.*)$'
    $anyProperty = '^' + [regex]::Escape($prefix) + '[A-Za-z_][A-Za-z0-9_]*:'

    for ($index = 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $wanted) {
            $value = $Matches['value'].Trim()
            $end = $index + 1
            while ($end -lt $Lines.Count -and $Lines[$end] -notmatch $anyProperty) {
                $end++
            }

            return [pscustomobject]@{ Start = $index; End = $end; Value = $value }
        }
    }

    return $null
}

function Get-DirectPropertyRanges {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent
    )

    $result = New-Object 'System.Collections.Generic.List[object]'
    $prefix = ' ' * $Indent
    $pattern = '^' + [regex]::Escape($prefix) + '(?<name>[A-Za-z_][A-Za-z0-9_]*):\s*(?<value>.*)$'

    for ($index = 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $pattern) {
            $result.Add([pscustomobject]@{ Name = $Matches['name']; Start = $index })
        }
    }

    for ($index = 0; $index -lt $result.Count; $index++) {
        $result[$index] | Add-Member -NotePropertyName End -NotePropertyValue $(
            if ($index + 1 -lt $result.Count) { $result[$index + 1].Start } else { $Lines.Count }
        )
    }

    return $result
}

function Remove-Property {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    if ($null -eq $range) {
        return $null
    }

    $Lines.RemoveRange($range.Start, $range.End - $range.Start)
    Add-Change
    return $range
}

function Rename-Property {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $OldName,
        [string] $NewName
    )

    $range = Get-PropertyRange $Lines $Indent $OldName
    if ($null -eq $range) {
        return $false
    }

    $prefix = ' ' * $Indent
    $Lines[$range.Start] = $Lines[$range.Start] -replace ('^' + [regex]::Escape($prefix + $OldName) + ':'), ($prefix + $NewName + ':')
    Add-Change
    return $true
}

function Set-ScalarProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name,
        [string] $Value
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    $line = (' ' * $Indent) + $Name + ': ' + $Value
    if ($null -ne $range) {
        if ($range.End -eq $range.Start + 1 -and $Lines[$range.Start] -ceq $line) {
            return
        }

        $Lines.RemoveRange($range.Start, $range.End - $range.Start)
        $Lines.Insert($range.Start, $line)
    }
    else {
        $Lines.Add($line)
    }

    Add-Change
}

function Get-VectorProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    if ($null -eq $range) {
        return $null
    }

    $values = @{}
    $childPrefix = ' ' * ($Indent + 2)
    $pattern = '^' + [regex]::Escape($childPrefix) + '(?<axis>[XYZW]):\s*(?<value>.+?)\s*$'
    for ($index = $range.Start + 1; $index -lt $range.End; $index++) {
        if ($Lines[$index] -match $pattern) {
            $number = 0.0
            if ([double]::TryParse($Matches['value'], [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$number)) {
                $values[$Matches['axis']] = $number
            }
        }
    }

    if (-not $values.ContainsKey('X') -or -not $values.ContainsKey('Y') -or -not $values.ContainsKey('Z')) {
        return $null
    }

    return [pscustomobject]@{
        X = [double]$values['X']
        Y = [double]$values['Y']
        Z = [double]$values['Z']
        W = if ($values.ContainsKey('W')) { [double]$values['W'] } else { 0.0 }
        Range = $range
    }
}

function Format-Float {
    param([double] $Value)
    if ($Value -eq 0) { $Value = 0.0 }
    return ([single]$Value).ToString('R', $script:Invariant)
}

function Set-VectorAt {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Index,
        [int] $Indent,
        [string] $Name,
        [double] $X,
        [double] $Y,
        [double] $Z
    )

    $prefix = ' ' * $Indent
    $childPrefix = ' ' * ($Indent + 2)
    $Lines.Insert($Index, $prefix + $Name + ':')
    $Lines.Insert($Index + 1, $childPrefix + 'X: ' + (Format-Float $X))
    $Lines.Insert($Index + 2, $childPrefix + 'Y: ' + (Format-Float $Y))
    $Lines.Insert($Index + 3, $childPrefix + 'Z: ' + (Format-Float $Z))
}

function Set-VectorProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name,
        [double] $X,
        [double] $Y,
        [double] $Z
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    $prefix = ' ' * $Indent
    $childPrefix = ' ' * ($Indent + 2)
    $wanted = @(
        $prefix + $Name + ':',
        $childPrefix + 'X: ' + (Format-Float $X),
        $childPrefix + 'Y: ' + (Format-Float $Y),
        $childPrefix + 'Z: ' + (Format-Float $Z)
    )
    if ($null -ne $range -and $range.End - $range.Start -eq $wanted.Count) {
        $same = $true
        for ($offset = 0; $offset -lt $wanted.Count; $offset++) {
            if ($Lines[$range.Start + $offset] -cne $wanted[$offset]) {
                $same = $false
                break
            }
        }
        if ($same) {
            return
        }
    }

    $index = $Lines.Count
    if ($null -ne $range) {
        $index = $range.Start
        $Lines.RemoveRange($range.Start, $range.End - $range.Start)
    }

    Set-VectorAt $Lines $index $Indent $Name $X $Y $Z
    Add-Change
}

function Set-SpringProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name,
        [string] $Mode,
        [double] $FrequencyOrStiffness,
        [double] $Damping
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    $prefix = ' ' * $Indent
    $childPrefix = ' ' * ($Indent + 2)
    $wanted = @(
        $prefix + $Name + ':',
        $childPrefix + 'Mode: ' + $Mode,
        $childPrefix + 'FrequencyOrStiffness: ' + (Format-Float $FrequencyOrStiffness),
        $childPrefix + 'Damping: ' + (Format-Float $Damping)
    )
    if ($null -ne $range -and $range.End - $range.Start -eq $wanted.Count) {
        $same = $true
        for ($offset = 0; $offset -lt $wanted.Count; $offset++) {
            if ($Lines[$range.Start + $offset] -cne $wanted[$offset]) {
                $same = $false
                break
            }
        }
        if ($same) {
            return
        }
    }

    $index = $Lines.Count
    if ($null -ne $range) {
        $index = $range.Start
        $Lines.RemoveRange($range.Start, $range.End - $range.Start)
    }

    $Lines.Insert($index, $prefix + $Name + ':')
    $Lines.Insert($index + 1, $childPrefix + 'Mode: ' + $Mode)
    $Lines.Insert($index + 2, $childPrefix + 'FrequencyOrStiffness: ' + (Format-Float $FrequencyOrStiffness))
    $Lines.Insert($index + 3, $childPrefix + 'Damping: ' + (Format-Float $Damping))
    Add-Change
}

function Set-PerpendicularNormalAxis {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $File,
        [int] $BaseLine
    )

    $axis = Get-VectorProperty $Lines $Indent 'Axis'
    if ($null -eq $axis) {
        return
    }

    $length = [Math]::Sqrt(($axis.X * $axis.X) + ($axis.Y * $axis.Y) + ($axis.Z * $axis.Z))
    if ($length -lt 0.000001) {
        Add-Finding 'Warning' 'constraint-axis-invalid' $File $BaseLine 'The legacy constraint axis is zero; a perpendicular Jolt NormalAxis could not be generated.'
        return
    }

    $x = $axis.X / $length
    $y = $axis.Y / $length
    $z = $axis.Z / $length

    # Match the tangent construction used by the legacy Physics3D joint frame.
    if ([Math]::Abs($z) -gt 0.7071067811865476) {
        $scale = 1.0 / [Math]::Sqrt(($y * $y) + ($z * $z))
        $normalX = 0.0
        $normalY = -$z * $scale
        $normalZ = $y * $scale
    }
    else {
        $scale = 1.0 / [Math]::Sqrt(($x * $x) + ($y * $y))
        $normalX = -$y * $scale
        $normalY = $x * $scale
        $normalZ = 0.0
    }

    Set-VectorProperty $Lines $Indent 'NormalAxis' $normalX $normalY $normalZ
}

function Convert-OrientationOffset {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $File,
        [int] $BaseLine
    )

    $orientation = Get-VectorProperty $Lines $Indent 'OrientationOffset'
    $range = Get-PropertyRange $Lines $Indent 'OrientationOffset'
    if ($null -eq $range) {
        return
    }

    $rotationX = 0.0
    $rotationY = 0.0
    $rotationZ = 0.0

    if ($null -eq $orientation) {
        Add-Finding 'Warning' 'orientation-defaulted' $File ($BaseLine + $range.Start) 'OrientationOffset could not be read; RotationOffset was set to zero.'
    }
    else {
        $length = [Math]::Sqrt(($orientation.X * $orientation.X) + ($orientation.Y * $orientation.Y) + ($orientation.Z * $orientation.Z) + ($orientation.W * $orientation.W))
        if ($length -gt 0.0000001) {
            $x = $orientation.X / $length
            $y = $orientation.Y / $length
            $z = $orientation.Z / $length
            $w = $orientation.W / $length

            $pitchValue = 2.0 * (($w * $x) - ($y * $z))
            $pitchValue = [Math]::Max(-1.0, [Math]::Min(1.0, $pitchValue))
            $rotationX = [Math]::Asin($pitchValue)
            $rotationY = [Math]::Atan2(2.0 * (($w * $y) + ($x * $z)), 1.0 - (2.0 * (($x * $x) + ($y * $y))))
            $rotationZ = [Math]::Atan2(2.0 * (($w * $z) + ($x * $y)), 1.0 - (2.0 * (($x * $x) + ($z * $z))))
        }
    }

    $Lines.RemoveRange($range.Start, $range.End - $range.Start)
    Set-VectorAt $Lines $range.Start $Indent 'RotationOffset' $rotationX $rotationY $rotationZ
    Add-Change
}

function Test-VectorZero {
    param($Vector)
    if ($null -eq $Vector) { return $false }
    return [Math]::Abs($Vector.X) -lt 0.000001 -and [Math]::Abs($Vector.Y) -lt 0.000001 -and [Math]::Abs($Vector.Z) -lt 0.000001
}

function Test-VectorOne {
    param($Vector)
    if ($null -eq $Vector) { return $false }
    return [Math]::Abs($Vector.X - 1.0) -lt 0.000001 -and [Math]::Abs($Vector.Y - 1.0) -lt 0.000001 -and [Math]::Abs($Vector.Z - 1.0) -lt 0.000001
}

function Convert-RigidBodyProperties {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $File,
        [int] $BaseLine
    )

    $bodyType = Get-PropertyRange $Lines $Indent 'PhysicBodyType'
    if ($null -ne $bodyType) {
        Set-ScalarProperty $Lines $Indent 'IsKinematic' $(if ($bodyType.Value -eq 'Kinematic') { 'true' } else { 'false' })
        Remove-Property $Lines $Indent 'PhysicBodyType' | Out-Null
    }

    $isKinematic = Get-PropertyRange $Lines $Indent 'IsKinematic'
    $isSensor = Get-PropertyRange $Lines $Indent 'IsSensor'
    if ($null -ne $isKinematic -and $isKinematic.Value -eq 'true' -and
        $null -ne $isSensor -and $isSensor.Value -eq 'true') {
        Set-ScalarProperty $Lines $Indent 'CollideKinematicVsNonDynamic' 'true'
        Add-Finding 'Info' 'kinematic-sensor-collisions-preserved' $File $BaseLine 'Enabled CollideKinematicVsNonDynamic so the migrated kinematic sensor can keep detecting static and kinematic bodies as it did in Bullet.'
    }

    $linearFactor = Get-VectorProperty $Lines $Indent 'LinearFactor'
    $angularFactor = Get-VectorProperty $Lines $Indent 'AngularFactor'
    if ($null -ne $linearFactor -or $null -ne $angularFactor) {
        if ($null -eq $linearFactor) { $linearFactor = [pscustomobject]@{ X = 1.0; Y = 1.0; Z = 1.0 } }
        if ($null -eq $angularFactor) { $angularFactor = [pscustomobject]@{ X = 1.0; Y = 1.0; Z = 1.0 } }

        $names = New-Object 'System.Collections.Generic.List[string]'
        if ([Math]::Abs($linearFactor.X) -gt 0.000001) { $names.Add('TranslationX') }
        if ([Math]::Abs($linearFactor.Y) -gt 0.000001) { $names.Add('TranslationY') }
        if ([Math]::Abs($linearFactor.Z) -gt 0.000001) { $names.Add('TranslationZ') }
        if ([Math]::Abs($angularFactor.X) -gt 0.000001) { $names.Add('RotationX') }
        if ([Math]::Abs($angularFactor.Y) -gt 0.000001) { $names.Add('RotationY') }
        if ([Math]::Abs($angularFactor.Z) -gt 0.000001) { $names.Add('RotationZ') }

        $allBinary = @(
            @($linearFactor.X, $linearFactor.Y, $linearFactor.Z, $angularFactor.X, $angularFactor.Y, $angularFactor.Z) |
                Where-Object { [Math]::Abs($_) -gt 0.000001 -and [Math]::Abs($_ - 1.0) -gt 0.000001 }
        )
        if ($allBinary.Count -gt 0) {
            Add-Finding 'Warning' 'factor-became-axis-lock' $File $BaseLine 'Fractional LinearFactor/AngularFactor values became Jolt free/locked axes; Jolt has no per-axis velocity multiplier.'
        }

        $degrees = if ($names.Count -eq 0) { 'None' } elseif ($names.Count -eq 6) { 'All' } else { [string]::Join(', ', $names) }
        Set-ScalarProperty $Lines $Indent 'AllowedDegreesOfFreedom' $degrees
        Remove-Property $Lines $Indent 'LinearFactor' | Out-Null
        Remove-Property $Lines $Indent 'AngularFactor' | Out-Null
    }

    $threshold = Get-PropertyRange $Lines $Indent 'CcdMotionThreshold'
    if ($null -ne $threshold) {
        $number = 0.0
        if ([double]::TryParse($threshold.Value, [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$number) -and $number -gt 0.0) {
            Set-ScalarProperty $Lines $Indent 'MotionQuality' 'LinearCast'
            Add-Finding 'Warning' 'ccd-approximated' $File ($BaseLine + $threshold.Start) 'Bullet CCD threshold/radius became Jolt MotionQuality.LinearCast; tune the body after migration.'
        }
    }

    Remove-Property $Lines $Indent 'CcdMotionThreshold' | Out-Null
    Remove-Property $Lines $Indent 'CcdSweptSphereRadius' | Out-Null

    $overrideGravity = Get-PropertyRange $Lines $Indent 'OverrideGravity'
    if ($null -ne $overrideGravity) {
        if ($overrideGravity.Value -eq 'true') {
            $gravity = Get-VectorProperty $Lines $Indent 'Gravity'
            if (Test-VectorZero $gravity) {
                Set-ScalarProperty $Lines $Indent 'GravityFactor' '0.0'
            }
            else {
                Add-Finding 'Warning' 'custom-gravity-not-preserved' $File ($BaseLine + $overrideGravity.Start) 'A per-body Bullet gravity vector has no exact Jolt property. Configure GravityFactor or apply a force in PhysicsStepStarting.'
            }
        }

        Remove-Property $Lines $Indent 'OverrideGravity' | Out-Null
        Remove-Property $Lines $Indent 'Gravity' | Out-Null
    }

    $localInertia = Get-VectorProperty $Lines $Indent 'LocalInertia'
    if ($null -ne $localInertia -and -not (Test-VectorZero $localInertia)) {
        Add-Finding 'Warning' 'inertia-not-preserved' $File ($BaseLine + $localInertia.Range.Start) 'Bullet LocalInertia has no exact Jolt asset property. Tune InertiaMultiplier or CenterOfMassOffset.'
    }
}

function Convert-CommonBodyProperties {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $File,
        [int] $BaseLine
    )

    $category = Get-PropertyRange $Lines $Indent 'CollisionCategory'
    if ($null -ne $category -and ($category.Value.Contains(',') -or $category.Value -eq 'All')) {
        Add-Finding 'Warning' 'multiple-categories-collapsed' $File ($BaseLine + $category.Start) 'Jolt accepts one category per body. When several bits are set, the lowest category is used.'
    }

    # The (category, mask) pair was already folded into the project CollisionMatrix.
    Remove-Property $Lines $Indent 'MaskBits' | Out-Null

    $rolling = Get-PropertyRange $Lines $Indent 'RollingFriction'
    if ($null -ne $rolling -and $rolling.Value -notmatch '^0(?:\.0+)?$') {
        Add-Finding 'Warning' 'rolling-friction-removed' $File ($BaseLine + $rolling.Start) 'Jolt has no equivalent serialized RollingFriction body property.'
    }
    Remove-Property $Lines $Indent 'RollingFriction' | Out-Null
}

function Convert-ColliderProperties {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $OldType,
        [string] $NewType,
        [string] $File,
        [int] $BaseLine
    )

    Convert-OrientationOffset $Lines $Indent $File $BaseLine

    $primitiveTypes = @(
        'Evergine.Framework.Physics.BoxCollider',
        'Evergine.Framework.Physics.SphereCollider',
        'Evergine.Framework.Physics.CapsuleCollider',
        'Evergine.Framework.Physics.CylinderCollider',
        'Evergine.Framework.Physics.TaperedCylinderCollider'
    )
    if ($primitiveTypes -contains $NewType) {
        Set-ScalarProperty $Lines $Indent 'UseModelBounds' 'true'
    }

    $margin = Get-PropertyRange $Lines $Indent 'Margin'
    if ($null -ne $margin) {
        if (@(
            'Evergine.Framework.Physics.BoxCollider',
            'Evergine.Framework.Physics.CylinderCollider',
            'Evergine.Framework.Physics.TaperedCylinderCollider',
            'Evergine.Framework.Physics.MeshCollider'
        ) -contains $NewType) {
            Set-ScalarProperty $Lines $Indent 'ConvexRadius' $margin.Value
        }
        elseif ($margin.Value -notmatch '^0(?:\.0+)?$' -and -not (Test-ScalarEquals $margin.Value '0.04')) {
            Add-Finding 'Warning' 'collider-margin-not-preserved' $File ($BaseLine + $margin.Start) 'This Jolt shape has no independent collision margin; verify its effective dimensions.'
        }
        Remove-Property $Lines $Indent 'Margin' | Out-Null
    }

    if ($OldType -eq 'Evergine.Framework.Physics3D.ConeCollider3D') {
        Set-ScalarProperty $Lines $Indent 'TopRadius' '0.0'
    }

    if ($OldType -eq 'Evergine.Framework.Physics3D.MeshCollider3D') {
        # Bullet defaulted to a triangle mesh and Jolt to ConvexHull. Jolt skips static-only
        # triangle meshes on dynamic bodies, which would leave them without collision.
        $isConvex = Get-PropertyRange $Lines $Indent 'IsConvex'
        $triangles = $null -eq $isConvex -or $isConvex.Value -ne 'true'
        $dynamic = $script:Context.DynamicCollider.ContainsKey($BaseLine - 1)
        Set-ScalarProperty $Lines $Indent 'MeshType' $(if ($triangles -and -not $dynamic) { 'TriangleMesh' } else { 'ConvexHull' })
        if ($triangles -and $dynamic) {
            Add-Finding 'Warning' 'mesh-collider-dynamic-convex' $File $BaseLine 'A triangle-mesh MeshCollider3D on a dynamic RigidBody became a ConvexHull; split concave shapes into convex colliders if the hull is too coarse.'
        }
        elseif ($null -eq $isConvex) {
            Add-Finding 'Info' 'mesh-collider-type-defaulted' $File $BaseLine 'MeshCollider3D had no IsConvex value; the Bullet default TriangleMesh was written explicitly.'
        }
        Remove-Property $Lines $Indent 'IsConvex' | Out-Null

        $size = Get-VectorProperty $Lines $Indent 'Size'
        if ($null -ne $size -and -not (Test-VectorOne $size)) {
            Add-Finding 'Warning' 'mesh-size-not-preserved' $File ($BaseLine + $size.Range.Start) 'MeshCollider3D.Size was not one. Jolt uses the entity scale; move this collider to a suitably scaled child entity.'
        }
        Remove-Property $Lines $Indent 'Size' | Out-Null
        Remove-Property $Lines $Indent 'AsyncShapeCreation' | Out-Null
    }
}

function Get-NumericProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name,
        [double] $DefaultValue
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    if ($null -ne $range) {
        $number = 0.0
        if ([double]::TryParse($range.Value, [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$number)) {
            return $number
        }
    }

    return $DefaultValue
}

function Convert-VehicleWheelProperties {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $File,
        [int] $BaseLine
    )

    $steerable = Get-PropertyRange $Lines $Indent 'IsSteerableWheel'
    $brakable = Get-PropertyRange $Lines $Indent 'IsBrakableWheel'
    $isFront = Get-PropertyRange $Lines $Indent 'IsFrontWheel'
    $wheelRadius = Get-NumericProperty $Lines $Indent 'WheelRadius' 0.5
    $restLength = Get-NumericProperty $Lines $Indent 'SuspensionRestLength' 0.2
    $maxTravel = Get-NumericProperty $Lines $Indent 'MaxSuspensionTravel' 5.0
    $stiffness = Get-NumericProperty $Lines $Indent 'SuspensionStiffness' 20.0
    $compression = Get-NumericProperty $Lines $Indent 'SuspensionCompression' 4.4
    $reboundDamping = Get-NumericProperty $Lines $Indent 'SuspensionDamping' 2.3
    $frictionSlip = Get-NumericProperty $Lines $Indent 'FrictionSlip' 1000.0

    # Bullet's wheel radius was a factor of the largest attached-model dimension,
    # whereas a native Jolt wheel uses metres. VehicleWheel.UseModelBounds retains
    # the old representation so the authored value can be preserved instead of
    # replacing every vehicle with the scale of VehiclesSample.
    $radius = [Math]::Max($wheelRadius, 0.01)
    $width = [Math]::Max($radius * 0.5, 0.05)

    # The legacy ray ended at rest length + radius, so the wheel could extend no
    # farther than SuspensionRestLength. MaxSuspensionTravel only widened the
    # compression clamp. Mapping rest to Jolt's minimum (the previous behavior)
    # placed the entire Jolt travel below the old wheel centre.
    $minimumLength = [Math]::Max(0.0, $restLength - $maxTravel)
    $maximumLength = [Math]::Max($restLength, $minimumLength)

    # Physics3D multiplied its dimensionless spring and damper coefficients by
    # the full chassis mass for each wheel. With four wheels the equivalent
    # natural frequency is sqrt(4 * stiffness) / 2pi. Jolt accepts that frequency
    # and one damping ratio, so use the mean of compression and rebound.
    $safeStiffness = [Math]::Max($stiffness, 0.01)
    $frequency = [Math]::Sqrt(4.0 * $safeStiffness) / (2.0 * [Math]::PI)
    $dampingRatio = (($compression + $reboundDamping) * 0.5) / [Math]::Sqrt($safeStiffness)
    $dampingRatio = [Math]::Max(0.1, [Math]::Min($dampingRatio, 2.0))

    # Bullet's default slip limit is about 10.5; very large values represented a
    # tyre that was effectively not impulse-limited. Map that logarithmically to
    # Jolt's tyre-curve multiplier and keep it in a sane road/off-road range.
    $frictionScale = 1.0 + (0.25 * [Math]::Log10([Math]::Max($frictionSlip, 0.01) / 10.5))
    $frictionScale = [Math]::Max(0.65, [Math]::Min($frictionScale, 1.5))

    $massScale = if ($script:CurrentAssetVehicleMass -gt 0.0) { $script:CurrentAssetVehicleMass / 1200.0 } else { 1.0 }
    $brakeTorque = [Math]::Max(250.0, 1500.0 * $massScale)
    $handBrakeTorque = [Math]::Max(1000.0, 6000.0 * $massScale)
    $inertia = [Math]::Max(0.05, [Math]::Min(10.0, 0.9 * [Math]::Pow($radius / 0.35, 2.0)))

    Remove-Property $Lines $Indent 'WheelRadius' | Out-Null
    Set-ScalarProperty $Lines $Indent 'Radius' (Format-Float $radius)
    Set-ScalarProperty $Lines $Indent 'Width' (Format-Float $width)
    Set-ScalarProperty $Lines $Indent 'UseModelBounds' 'true'
    Set-ScalarProperty $Lines $Indent 'MaxSteerAngle' $(if ($null -ne $steerable -and $steerable.Value -eq 'true') { '0.5235988' } else { '0.0' })
    Set-ScalarProperty $Lines $Indent 'MaxBrakeTorque' $(if ($null -ne $brakable -and $brakable.Value -eq 'false') { '0.0' } else { Format-Float $brakeTorque })
    Set-ScalarProperty $Lines $Indent 'MaxHandBrakeTorque' $(if ($null -ne $isFront -and $isFront.Value -eq 'false') { Format-Float $handBrakeTorque } else { '0.0' })
    Set-ScalarProperty $Lines $Indent 'SuspensionMinLength' (Format-Float $minimumLength)
    Set-ScalarProperty $Lines $Indent 'SuspensionMaxLength' (Format-Float $maximumLength)
    Set-ScalarProperty $Lines $Indent 'SuspensionPreloadLength' '0.0'
    Set-SpringProperty $Lines $Indent 'SuspensionSpring' 'FrequencyAndDamping' $frequency $dampingRatio
    Set-ScalarProperty $Lines $Indent 'Inertia' (Format-Float $inertia)
    Set-ScalarProperty $Lines $Indent 'AngularDamping' '0.2'
    Set-ScalarProperty $Lines $Indent 'LongitudinalFrictionScale' (Format-Float $frictionScale)
    Set-ScalarProperty $Lines $Indent 'LateralFrictionScale' (Format-Float $frictionScale)
    Set-ScalarProperty $Lines $Indent 'UpdateEntityTransform' 'true'

    foreach ($legacyProperty in @(
        'IsSteerableWheel', 'IsBrakableWheel', 'IsFrontWheel', 'MaxSuspensionTravel', 'FrictionSlip',
        'SuspensionRestLength', 'SuspensionStiffness', 'SuspensionCompression', 'SuspensionDamping')) {
        Remove-Property $Lines $Indent $legacyProperty | Out-Null
    }

    $rotationAxis = Get-VectorProperty $Lines $Indent 'RotationAxis'
    if ($null -ne $rotationAxis -and (
        [Math]::Abs([Math]::Abs($rotationAxis.X) - 1.0) -gt 0.0001 -or
        [Math]::Abs($rotationAxis.Y) -gt 0.0001 -or
        [Math]::Abs($rotationAxis.Z) -gt 0.0001)) {
        Add-Finding 'Warning' 'vehicle-wheel-axis-needs-review' $File ($BaseLine + $rotationAxis.Range.Start) 'The legacy wheel rotation axis was not X. VehicleWheel currently uses the Jolt X axle, so rotate the wheel child/model to match.'
    }
    Remove-Property $Lines $Indent 'RotationAxis' | Out-Null
}

function Copy-VehicleSettingsToWheel {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [object] $Vehicle
    )

    # With OverrideVehicleSettings off, Physics3D read suspension and grip from the vehicle.
    if ((Get-YamlValue $Lines $Indent 'OverrideVehicleSettings') -ne 'true') {
        foreach ($name in $Vehicle.VehicleValues.Keys) { Set-ScalarProperty $Lines $Indent $name $Vehicle.VehicleValues[$name] }
    }
}

function Convert-ConstraintProperties {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $OldType,
        [string] $NewType,
        [string] $File,
        [int] $BaseLine
    )

    $constraintId = Get-PropertyRange $Lines $Indent 'Id'
    $stabilizedKey = if ($null -ne $constraintId) { $File + '|' + $constraintId.Value } else { '' }
    if ($stabilizedKey.Length -gt 0 -and $script:StabilizedConstraintIds.ContainsKey($stabilizedKey)) {
        Set-ScalarProperty $Lines $Indent 'SolverVelocityIterationsOverride' '32'
        Set-ScalarProperty $Lines $Indent 'SolverPositionIterationsOverride' '8'
        Add-Finding 'Info' 'constraint-chain-solver-stabilized' $File $BaseLine 'This constraint belongs to a high-mass-ratio chain; its Jolt solver overrides were set to 32 velocity and 8 position iterations.'
    }

    $breakPoint = Get-PropertyRange $Lines $Indent 'BreakPoint'
    if ($null -ne $breakPoint) {
        $number = 0.0
        if ([double]::TryParse($breakPoint.Value, [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$number)) {
            if ($number -gt 0.000001 -and $number -lt 1.0e20) {
                Set-ScalarProperty $Lines $Indent 'IsBreakable' 'true'
                Set-ScalarProperty $Lines $Indent 'BreakForce' (Format-Float ($number * 60.0))
                Set-ScalarProperty $Lines $Indent 'BreakTorque' (Format-Float ($number * 60.0))
                Add-Finding 'Warning' 'break-threshold-approximated' $File ($BaseLine + $breakPoint.Start) 'Bullet impulse BreakPoint was converted to force and torque at 60 Hz. Retune both limits.'
            }
            else {
                # Physics3D serialized zero (and occasionally float.MaxValue) for an
                # unbreakable joint. Treating zero as a Jolt threshold makes it snap
                # during the first solver step.
                Set-ScalarProperty $Lines $Indent 'IsBreakable' 'false'
                Remove-Property $Lines $Indent 'BreakForce' | Out-Null
                Remove-Property $Lines $Indent 'BreakTorque' | Out-Null
            }
        }
        Remove-Property $Lines $Indent 'BreakPoint' | Out-Null
    }

    if ($NewType -eq 'Evergine.Framework.Physics.HingeConstraint') {
        Set-PerpendicularNormalAxis $Lines $Indent $File $BaseLine

        $useAngularLimit = Get-PropertyRange $Lines $Indent 'UseAngularLimit'
        if ($null -ne $useAngularLimit -and $useAngularLimit.Value -eq 'false') {
            # HingeConstraint uses -PI..PI as its unlimited representation. Omitting
            # both properties preserves those defaults; copying legacy 0..0 would
            # accidentally lock a free hinge solid.
            Remove-Property $Lines $Indent 'MinAngle' | Out-Null
            Remove-Property $Lines $Indent 'MaxAngle' | Out-Null
        }
        Remove-Property $Lines $Indent 'UseAngularLimit' | Out-Null

        $useMotor = Get-PropertyRange $Lines $Indent 'UseMotor'
        $motorImpulse = Get-PropertyRange $Lines $Indent 'MotorTargetImpulse'
        $hasEffectiveMotor = $null -ne $useMotor -and $useMotor.Value -eq 'true'
        $motorImpulseNumber = 0.0
        if ($null -ne $motorImpulse -and
            [double]::TryParse($motorImpulse.Value, [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$motorImpulseNumber) -and
            [Math]::Abs($motorImpulseNumber) -le 0.000001) {
            $hasEffectiveMotor = $false
        }

        if ($null -ne $useMotor) {
            Set-ScalarProperty $Lines $Indent 'MotorMode' $(if ($hasEffectiveMotor) { 'Velocity' } else { 'Off' })
            Remove-Property $Lines $Indent 'UseMotor' | Out-Null
        }
        if ($null -ne $motorImpulse) {
            if ([double]::TryParse($motorImpulse.Value, [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$motorImpulseNumber)) {
                Set-ScalarProperty $Lines $Indent 'MaxMotorTorque' (Format-Float ($motorImpulseNumber * 60.0))
            }
            Remove-Property $Lines $Indent 'MotorTargetImpulse' | Out-Null
            if ([Math]::Abs($motorImpulseNumber) -gt 0.000001) {
                Add-Finding 'Warning' 'hinge-motor-approximated' $File ($BaseLine + $motorImpulse.Start) 'Bullet motor impulse was converted to Jolt torque at 60 Hz; retune the motor.'
            }
            elseif ($null -ne $useMotor -and $useMotor.Value -eq 'true') {
                Add-Finding 'Info' 'zero-torque-hinge-motor-disabled' $File ($BaseLine + $motorImpulse.Start) 'Bullet enabled this hinge motor with zero impulse. Jolt motor mode was set to Off because it cannot apply torque.'
            }
        }
    }
    elseif ($NewType -eq 'Evergine.Framework.Physics.SliderConstraint') {
        Set-PerpendicularNormalAxis $Lines $Indent $File $BaseLine

        # Bullet's slider was free unless UseLinearLimit was set; Jolt treats +/-float.MaxValue as no limit.
        if ((Get-YamlValue $Lines $Indent 'UseLinearLimit') -ne 'true') {
            Remove-Property $Lines $Indent 'MinDistance' | Out-Null
            Remove-Property $Lines $Indent 'MaxDistance' | Out-Null
            Set-ScalarProperty $Lines $Indent 'MinDistance' (Format-Float (-[single]::MaxValue))
            Set-ScalarProperty $Lines $Indent 'MaxDistance' (Format-Float ([single]::MaxValue))
        }

        $useMotor = Get-PropertyRange $Lines $Indent 'UseLinearMotor'
        if ($null -ne $useMotor) {
            Set-ScalarProperty $Lines $Indent 'MotorMode' $(if ($useMotor.Value -eq 'true') { 'Velocity' } else { 'Off' })
        }

        # Jolt sliders always lock rotation, as Bullet's default 0..0 angular limit did.
        if ((Get-YamlValue $Lines $Indent 'UseAngularLimit') -eq 'false' -or (Get-YamlValue $Lines $Indent 'UseAngularMotor') -eq 'true' -or
            (Get-NumericProperty $Lines $Indent 'LowerAngularLimit' 0.0) -ne (Get-NumericProperty $Lines $Indent 'UpperAngularLimit' 0.0)) {
            Add-Finding 'Warning' 'slider-angular-part-removed' $File $BaseLine 'This Bullet slider allowed or drove rotation around its axis, which a Jolt SliderConstraint always locks.'
        }
        foreach ($name in @('UseLinearLimit', 'UseLinearMotor', 'UseAngularLimit', 'UseAngularMotor', 'LowerAngularLimit', 'UpperAngularLimit', 'MaxAngularMotorForce', 'TargetAngularMotorVelocity')) {
            Remove-Property $Lines $Indent $name | Out-Null
        }
    }
    elseif ($NewType -eq 'Evergine.Framework.Physics.SixDOFConstraint') {
        # Bullet applied limits only with the Use*Limit flag, and lower > upper meant a free axis.
        $free = @(foreach ($group in @('Linear/Translation', 'Angular/Rotation')) {
            $kind, $prefix = $group.Split('/')
            $enabled = (Get-YamlValue $Lines $Indent ('Use' + $kind + 'Limit')) -eq 'true'
            $lower = Get-VectorProperty $Lines $Indent ($prefix + 'Min')
            $upper = Get-VectorProperty $Lines $Indent ($prefix + 'Max')
            foreach ($axis in 'X', 'Y', 'Z') {
                if (-not $enabled -or ($null -ne $lower -and $null -ne $upper -and $lower.$axis -gt $upper.$axis)) { $prefix + $axis }
            }
            Remove-Property $Lines $Indent ('Use' + $kind + 'Limit') | Out-Null
        })
        Set-ScalarProperty $Lines $Indent 'FreeAxes' $(if ($free.Count -eq 0) { 'None' } elseif ($free.Count -eq 6) { 'All' } else { $free -join ', ' })

        $springs = @(Get-DirectPropertyRanges $Lines $Indent | Where-Object { $_.Name -like 'UseSpring*' -and $Lines[$_.Start] -match ':\s*true\s*$' })
        if ($springs.Count -gt 0) {
            Add-Finding 'Warning' 'six-dof-spring-not-migrated' $File $BaseLine ('Bullet springs on ' + (($springs | ForEach-Object { $_.Name -replace '^UseSpring', '' }) -join ', ') + ' have no per-axis Jolt equivalent; use SixDOFConstraint motors or LimitsSpring.')
        }
    }
    elseif ($NewType -eq 'Evergine.Framework.Physics.SwingTwistConstraint') {
        $axis = Get-VectorProperty $Lines $Indent 'TwistAxis'
        if ($null -eq $axis) {
            $axis = [pscustomobject]@{ X = 1.0; Y = 0.0; Z = 0.0 }
            Set-VectorProperty $Lines $Indent 'TwistAxis' 1.0 0.0 0.0
        }

        # Bullet's cone frame was (axis, q, p) from btPlaneSpace; span 1 limited rotation about p
        # and span 2 about q. With PlaneAxis = q, Jolt's normal axis is p.
        $frame = Get-PerpendicularAxes $axis
        if ($null -ne $frame) {
            Set-VectorProperty $Lines $Indent 'PlaneAxis' $frame.Q.X $frame.Q.Y $frame.Q.Z
        }

        $settings = Get-VectorProperty $Lines $Indent 'ConeTwistSettings'
        if ($null -eq $settings) {
            $settings = [pscustomobject]@{ X = [Math]::PI / 4.0; Y = [Math]::PI / 4.0; Z = 2.0 * [Math]::PI }
        }
        $twist = [Math]::Min([Math]::Abs($settings.Z), [Math]::PI)
        Set-ScalarProperty $Lines $Indent 'NormalHalfConeAngle' (Format-Float ([Math]::Min([Math]::Abs($settings.X), [Math]::PI)))
        Set-ScalarProperty $Lines $Indent 'PlaneHalfConeAngle' (Format-Float ([Math]::Min([Math]::Abs($settings.Y), [Math]::PI)))
        Set-ScalarProperty $Lines $Indent 'TwistMaxAngle' (Format-Float $twist)
        Set-ScalarProperty $Lines $Indent 'TwistMinAngle' (Format-Float (-$twist))
        Remove-Property $Lines $Indent 'ConeTwistSettings' | Out-Null

        $torque = 60.0 * (Get-NumericProperty $Lines $Indent 'MaxMotorImpulse' 0.0)
        if ((Get-YamlValue $Lines $Indent 'UseMotor') -eq 'true') {
            # TargetOrientation is not serialized; code sets it.
            Set-ScalarProperty $Lines $Indent 'SwingMotorMode' 'Position'
            Set-ScalarProperty $Lines $Indent 'TwistMotorMode' 'Position'
            Set-ScalarProperty $Lines $Indent 'MaxSwingTorque' (Format-Float $torque)
            Set-ScalarProperty $Lines $Indent 'MaxTwistTorque' (Format-Float $torque)
            Add-Finding 'Warning' 'swing-twist-motor-approximated' $File $BaseLine ('The ConeTwist motor became Position swing/twist motors with ' + (Format-Float $torque) + ' N m (impulse at 60 Hz); set TargetOrientation from code if MotorTarget was not identity.')
        }
        elseif ([Math]::Abs((Get-NumericProperty $Lines $Indent 'Damping' 0.01) - 0.01) -gt 0.0001) {
            Add-Finding 'Warning' 'swing-twist-damping-not-preserved' $File $BaseLine 'ConeTwist Damping has no direct Jolt equivalent; use MaxFrictionTorque.'
        }
    }

    # A path that resolves to one entity of this asset becomes a ConnectedEntity reference (its
    # Id); the path is removed because assigning it after the entity would clear the reference.
    if ($script:Context.ConnectedEntity.ContainsKey($BaseLine - 1)) {
        $target = $script:Context.ConnectedEntity[$BaseLine - 1]
        if ($target.Ambiguous -or $null -eq $target.Entity) {
            Add-Finding $(if ($target.Ambiguous) { 'Warning' } else { 'Info' }) $(if ($target.Ambiguous) { 'constraint-target-ambiguous' } else { 'constraint-target-unresolved' }) $File $BaseLine ('ConnectedEntityPath "' + $target.Path + '" ' + $(if ($target.Ambiguous) { 'matches more than one entity' } else { 'does not resolve inside this asset' }) + ' and was kept; pick the body in the Connected Body field.')
        }
        else {
            Remove-Property $Lines $Indent 'ConnectedEntityPath' | Out-Null
            Set-ScalarProperty $Lines $Indent 'ConnectedEntity' $target.Entity.Id
            if ($target.IsPrefab) {
                Add-Finding 'Info' 'constraint-target-prefab' $File $BaseLine ('ConnectedEntityPath "' + $target.Path + '" was resolved inside this prefab; Bullet resolved it against the scene roots.')
            }
        }
    }
}

function Remove-UnsupportedProperties {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $NewType,
        [string] $File,
        [int] $BaseLine
    )

    if (-not $script:AllowedProperties.ContainsKey($NewType)) {
        return
    }

    $allowed = @{}
    foreach ($name in $script:AllowedProperties[$NewType]) { $allowed[$name] = $true }
    $autoConfigured = Get-PropertyRange $Lines $Indent 'AutoConfigureConnectedAnchor'
    $ranges = @(Get-DirectPropertyRanges $Lines $Indent)
    for ($index = $ranges.Count - 1; $index -ge 0; $index--) {
        $range = $ranges[$index]
        if (-not $allowed.ContainsKey($range.Name)) {
            # ConnectedAxis was derived from Axis while AutoConfigureConnected was on.
            $isNoOp = (Test-LegacyDefaultProperty $Lines $range) -or ($range.Name -eq 'ConnectedAxis' -and $null -ne $autoConfigured -and $autoConfigured.Value -eq 'true')
            $Lines.RemoveRange($range.Start, $range.End - $range.Start)
            Add-Change
            if (-not $isNoOp) {
                Add-Finding 'Warning' 'property-needs-manual-migration' $File ($BaseLine + $range.Start) ($range.Name + ' has no Jolt equivalent on ' + ($NewType -replace '^.*\.', '') + ' and its non-default value was removed.')
            }
        }
    }
}

function Test-ScalarEquals {
    param([string] $Actual, [string] $Expected)

    # PowerShell number conversions use the invariant culture.
    $left = $Actual -as [double]
    $right = $Expected -as [double]
    if ($null -eq $left -or $null -eq $right) { return $Actual.Trim("'", '"', ' ') -eq $Expected }
    return [Math]::Abs($left - $right) -le (0.00001 * [Math]::Max(1.0, [Math]::Abs($right)))
}

function Test-LegacyDefaultProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [object] $Range
    )

    if ($Range.Name -match $script:NoOpLegacyProperties) { return $true }
    if (-not $script:LegacyPropertyDefaults.ContainsKey($Range.Name)) { return $false }

    # A scalar, or the X,Y,Z children of a vector.
    $actual = @(($Lines[$Range.Start] -split ':', 2)[1].Trim())
    if ($actual[0].Length -eq 0) {
        $actual = @(for ($line = $Range.Start + 1; $line -lt $Range.End; $line++) { ($Lines[$line] -split ':', 2)[1].Trim() })
    }

    foreach ($default in $script:LegacyPropertyDefaults[$Range.Name].Split('|')) {
        $expected = $default.Split(',')
        if ($expected.Count -eq $actual.Count -and @(for ($i = 0; $i -lt $actual.Count; $i++) { if (-not (Test-ScalarEquals $actual[$i] $expected[$i])) { $i } }).Count -eq 0) {
            return $true
        }
    }

    return $false
}

function Get-YamlContainingComponentsRange {
    param(
        [string[]] $Lines,
        [int] $ComponentIndex
    )

    $componentIndent = ([regex]::Match($Lines[$ComponentIndex], '^\s*').Value).Length
    $componentsIndent = $componentIndent - 2
    $start = $ComponentIndex - 1
    while ($start -ge 0) {
        $line = $Lines[$start]
        if ($line.Trim().Length -gt 0) {
            $indent = ([regex]::Match($line, '^\s*').Value).Length
            if ($indent -le $componentsIndent) {
                if ($indent -eq $componentsIndent -and $line.Trim() -eq 'Components:') {
                    break
                }

                return $null
            }
        }

        $start--
    }

    if ($start -lt 0) {
        return $null
    }

    $end = $start + 1
    while ($end -lt $Lines.Length) {
        $line = $Lines[$end]
        if ($line.Trim().Length -gt 0) {
            $indent = ([regex]::Match($line, '^\s*').Value).Length
            if ($indent -le $componentsIndent) {
                break
            }
        }

        $end++
    }

    return [pscustomobject]@{
        Start = $start + 1
        End = $end
        ComponentIndent = $componentIndent
    }
}

function Get-YamlComponentBlockEnd {
    param(
        [string[]] $Lines,
        [int] $Start,
        [int] $Indent,
        [int] $Limit
    )

    $end = $Start + 1
    while ($end -lt $Limit) {
        if ($Lines[$end].Trim().Length -gt 0) {
            $nextIndent = ([regex]::Match($Lines[$end], '^\s*').Value).Length
            if ($nextIndent -le $Indent) {
                break
            }
        }

        $end++
    }

    return $end
}

function Get-YamlBodyInfoFromComponents {
    param(
        [string[]] $Lines,
        [object] $Range
    )

    for ($index = $Range.Start; $index -lt $Range.End; $index++) {
        $line = $Lines[$index]
        $indent = ([regex]::Match($line, '^\s*').Value).Length
        if ($indent -ne $Range.ComponentIndent -or
            $line -notmatch '!Evergine\.Framework\.Physics(?:3D)?\.(?:RigidBody3D|RigidBody),Evergine\.Framework') {
            continue
        }

        $end = Get-YamlComponentBlockEnd $Lines $index $indent $Range.End
        $massIndex = -1
        $mass = 0.0
        $isDynamic = $true
        for ($propertyIndex = $index + 1; $propertyIndex -lt $end; $propertyIndex++) {
            $property = $Lines[$propertyIndex]
            $massMatch = [regex]::Match($property, '^\s*Mass:\s*(?<value>[-+0-9.eE]+)\s*$')
            if ($massMatch.Success) {
                $parsedMass = 0.0
                if ([double]::TryParse($massMatch.Groups['value'].Value, [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$parsedMass)) {
                    $massIndex = $propertyIndex
                    $mass = $parsedMass
                }
            }
            elseif ($property -match '^\s*PhysicBodyType:\s*(?<value>\S+)') {
                $isDynamic = $Matches['value'] -eq 'Dynamic'
            }
            elseif ($property -match '^\s*IsKinematic:\s*(?<value>true|false)') {
                $isDynamic = $Matches['value'] -eq 'false'
            }
        }

        return [pscustomobject]@{
            Start = $index
            End = $end
            MassIndex = $massIndex
            Mass = $mass
            IsDynamic = $isDynamic
        }
    }

    return $null
}

function Get-MaxVehicleMassFromYaml {
    param([string] $Text)

    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $maximum = 0.0
    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch '!Evergine\.Framework\.Physics(?:3D)?\.(?:PhysicVehicle3D|WheeledVehicleController),Evergine\.Framework') {
            continue
        }

        $range = Get-YamlContainingComponentsRange $lines $index
        if ($null -eq $range) {
            continue
        }

        $body = Get-YamlBodyInfoFromComponents $lines $range
        if ($null -ne $body -and $body.IsDynamic -and $body.Mass -gt $maximum) {
            $maximum = $body.Mass
        }
    }

    return $maximum
}

function Get-ComponentId {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent
    )

    $id = Get-PropertyRange $Lines $Indent 'Id'
    return $(if ($null -ne $id) { $id.Value } else { $null })
}

function Register-LegacyVehicleComponents {
    param([string] $Text)

    $lines = [regex]::Split((Expand-LegacyErrorComponents $Text '' "`n" $false), "`r`n|`n|`r")
    $context = Initialize-YamlFileContext $lines
    $tagPattern = '^\s*-\s+!Evergine\.Framework\.Physics3D\.(?<type>PhysicVehicle3D|PhysicWheel3D),Evergine\.Framework\s*$'
    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch $tagPattern) {
            continue
        }

        $type = $Matches['type']
        $indent = ([regex]::Match($lines[$index], '^\s*').Value).Length
        $end = Get-YamlComponentBlockEnd $lines $index $indent $lines.Length
        $block = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in $lines[$index..($end - 1)]) { $block.Add($line) }
        $propertyIndent = $indent + 2
        $id = Get-ComponentId $block $propertyIndent
        if ([string]::IsNullOrWhiteSpace($id)) {
            continue
        }

        if ($type -eq 'PhysicVehicle3D') {
            if (-not $script:LegacyVehicleComponents.ContainsKey($id)) {
                $script:LegacyVehicleComponents[$id] = $context.VehicleLayout[$index]
            }
        }
        elseif (-not $script:LegacyWheelComponents.ContainsKey($id)) {
            Copy-VehicleSettingsToWheel $block $propertyIndent $context.WheelVehicle[$index]
            $front = Get-PropertyRange $block $propertyIndent 'IsFrontWheel'
            $steerable = Get-PropertyRange $block $propertyIndent 'IsSteerableWheel'
            $brakable = Get-PropertyRange $block $propertyIndent 'IsBrakableWheel'
            $script:LegacyWheelComponents[$id] = [pscustomobject]@{
                WheelRadius = Get-NumericProperty $block $propertyIndent 'WheelRadius' 0.5
                SuspensionRestLength = Get-NumericProperty $block $propertyIndent 'SuspensionRestLength' 0.2
                MaxSuspensionTravel = Get-NumericProperty $block $propertyIndent 'MaxSuspensionTravel' 5.0
                SuspensionStiffness = Get-NumericProperty $block $propertyIndent 'SuspensionStiffness' 20.0
                SuspensionCompression = Get-NumericProperty $block $propertyIndent 'SuspensionCompression' 4.4
                SuspensionDamping = Get-NumericProperty $block $propertyIndent 'SuspensionDamping' 2.3
                FrictionSlip = Get-NumericProperty $block $propertyIndent 'FrictionSlip' 1000.0
                IsFrontWheel = $(if ($null -ne $front -and $front.Value -eq 'false') { 'false' } else { 'true' })
                IsSteerableWheel = $(if ($null -ne $steerable -and $steerable.Value -eq 'true') { 'true' } else { 'false' })
                IsBrakableWheel = $(if ($null -ne $brakable -and $brakable.Value -eq 'false') { 'false' } else { 'true' })
            }
        }
    }
}

function Initialize-LegacyVehicleBackupIndex {
    param([string] $ProjectRoot)

    $backupBase = Join-Path $ProjectRoot '.bullet-to-jolt-backup'
    if (-not [System.IO.Directory]::Exists($backupBase)) {
        return
    }

    # Newest backup wins. A later run can contain an already converted asset,
    # while an older one still contains the Bullet component values we need.
    $backupDirectories = Get-ChildItem -LiteralPath $backupBase -Directory | Sort-Object Name -Descending
    $changeCount = $script:ChangeCount
    foreach ($directory in $backupDirectories) {
        foreach ($file in Get-ChildItem -LiteralPath $directory.FullName -Recurse -File) {
            if ($file.Extension.ToLowerInvariant() -notin @('.wescene', '.weprefab')) {
                continue
            }

            Register-LegacyVehicleComponents (Get-TextFile $file.FullName).Text
        }
    }

    # Reading backups only builds an index; it changes nothing in the project.
    $script:ChangeCount = $changeCount
}

function Get-MaxAuthoredVehicleWheelRadius {
    param([string] $Text)

    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $maximum = 0.0
    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch '^\s*-\s+!Evergine\.Framework\.Physics(?:3D)?\.(?<type>PhysicWheel3D|VehicleWheel),Evergine\.Framework\s*$') {
            continue
        }

        $type = $Matches['type']
        $indent = ([regex]::Match($lines[$index], '^\s*').Value).Length
        $end = Get-YamlComponentBlockEnd $lines $index $indent $lines.Length
        $block = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in $lines[$index..($end - 1)]) { $block.Add($line) }
        $propertyIndent = $indent + 2
        $radius = 0.0

        if ($type -eq 'PhysicWheel3D') {
            $radius = Get-NumericProperty $block $propertyIndent 'WheelRadius' 0.5
        }
        else {
            $id = Get-ComponentId $block $propertyIndent
            if (-not [string]::IsNullOrWhiteSpace($id) -and $script:LegacyWheelComponents.ContainsKey($id)) {
                $radius = $script:LegacyWheelComponents[$id].WheelRadius
            }
            else {
                $radius = Get-NumericProperty $block $propertyIndent 'Radius' 0.35
            }
        }

        if ($radius -gt $maximum) {
            $maximum = $radius
        }
    }

    return $(if ($maximum -gt 0.0) { $maximum } else { 0.35 })
}

function Tune-VehicleChassis {
    param(
        [string] $Text,
        [string] $File,
        [string] $NewLine
    )

    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $replacements = New-Object 'System.Collections.Generic.List[object]'
    $seenBodies = @{}
    $controllerPattern = '^\s*-\s+!Evergine\.Framework\.Physics(?<legacy>3D)?\.(?:PhysicVehicle3D|WheeledVehicleController),Evergine\.Framework\s*$'

    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch $controllerPattern) {
            continue
        }

        $isLegacy = $Matches['legacy'] -eq '3D'
        $controllerIndent = ([regex]::Match($lines[$index], '^\s*').Value).Length
        $controllerEnd = Get-YamlComponentBlockEnd $lines $index $controllerIndent $lines.Length
        $controllerBlock = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in $lines[$index..($controllerEnd - 1)]) { $controllerBlock.Add($line) }
        $controllerId = Get-ComponentId $controllerBlock ($controllerIndent + 2)
        if (-not $isLegacy -and ([string]::IsNullOrWhiteSpace($controllerId) -or -not $script:LegacyVehicleComponents.ContainsKey($controllerId))) {
            continue
        }

        $range = Get-YamlContainingComponentsRange $lines $index
        if ($null -eq $range) {
            continue
        }

        $body = Get-YamlBodyInfoFromComponents $lines $range
        if ($null -eq $body -or -not $body.IsDynamic -or $seenBodies.ContainsKey($body.Start)) {
            continue
        }
        $seenBodies[$body.Start] = $true

        $bodyBlock = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in $lines[$body.Start..($body.End - 1)]) { $bodyBlock.Add($line) }
        $bodyIndent = ([regex]::Match($lines[$body.Start], '^\s*').Value).Length + 2
        $before = [string]::Join($NewLine, $bodyBlock)

        if ($null -eq (Get-PropertyRange $bodyBlock $bodyIndent 'CenterOfMassOffset')) {
            Set-VectorProperty $bodyBlock $bodyIndent 'CenterOfMassOffset' 0.0 (-0.5 * $script:CurrentAssetWheelRadius) 0.0 | Out-Null
        }
        if ($null -eq (Get-PropertyRange $bodyBlock $bodyIndent 'InertiaMultiplier')) {
            Set-ScalarProperty $bodyBlock $bodyIndent 'InertiaMultiplier' '1.25' | Out-Null
        }

        $angularDamping = Get-PropertyRange $bodyBlock $bodyIndent 'AngularDamping'
        if ($null -eq $angularDamping -or (Get-NumericProperty $bodyBlock $bodyIndent 'AngularDamping' 0.0) -le 0.0001) {
            Set-ScalarProperty $bodyBlock $bodyIndent 'AngularDamping' '0.15' | Out-Null
        }

        $after = [string]::Join($NewLine, $bodyBlock)
        if ($after -ne $before) {
            $replacements.Add([pscustomobject]@{ Start = $body.Start; End = $body.End; Lines = $bodyBlock.ToArray() })
            Add-Finding 'Info' 'vehicle-chassis-stabilized' $File ($body.Start + 1) 'The migrated vehicle chassis received a lower center of mass, moderate rotational inertia and angular damping to avoid the easy wheelies produced by a direct Bullet profile copy.'
        }
    }

    if ($replacements.Count -eq 0) {
        return $Text
    }

    $output = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $lines) { $output.Add($line) }
    foreach ($replacement in $replacements | Sort-Object Start -Descending) {
        $output.RemoveRange($replacement.Start, $replacement.End - $replacement.Start)
        $output.InsertRange($replacement.Start, [string[]]$replacement.Lines)
    }

    return [string]::Join($NewLine, $output)
}

function Repair-ExistingJoltVehicleProfiles {
    param(
        [string] $Text,
        [string] $File,
        [string] $NewLine
    )

    if ($script:LegacyVehicleComponents.Count -eq 0 -and $script:LegacyWheelComponents.Count -eq 0) {
        return $Text
    }

    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $output = New-Object 'System.Collections.Generic.List[string]'
    $index = 0
    $tagPattern = '^\s*-\s+!Evergine\.Framework\.Physics\.(?<type>WheeledVehicleController|VehicleWheel),Evergine\.Framework\s*$'

    while ($index -lt $lines.Length) {
        if ($lines[$index] -notmatch $tagPattern) {
            $output.Add($lines[$index])
            $index++
            continue
        }

        $type = $Matches['type']
        $indent = ([regex]::Match($lines[$index], '^\s*').Value).Length
        $end = Get-YamlComponentBlockEnd $lines $index $indent $lines.Length
        $block = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in $lines[$index..($end - 1)]) { $block.Add($line) }
        $propertyIndent = $indent + 2
        $id = Get-ComponentId $block $propertyIndent
        $before = [string]::Join($NewLine, $block)
        $changeCountBefore = $script:ChangeCount
        $findingCountBefore = $script:Findings.Count

        if ($type -eq 'WheeledVehicleController' -and -not [string]::IsNullOrWhiteSpace($id) -and $script:LegacyVehicleComponents.ContainsKey($id)) {
            Set-WheeledVehicleControllerProfile $block $propertyIndent $script:LegacyVehicleComponents[$id]
        }
        elseif ($type -eq 'VehicleWheel' -and -not [string]::IsNullOrWhiteSpace($id) -and $script:LegacyWheelComponents.ContainsKey($id)) {
            $legacy = $script:LegacyWheelComponents[$id]
            $prefix = ' ' * $propertyIndent
            # Full precision, so a rerun derives exactly the values of the first conversion.
            foreach ($name in 'WheelRadius', 'SuspensionRestLength', 'MaxSuspensionTravel', 'SuspensionStiffness', 'SuspensionCompression', 'SuspensionDamping', 'FrictionSlip') {
                $block.Add($prefix + $name + ': ' + ([double]$legacy.$name).ToString('R', $script:Invariant))
            }
            $block.Add($prefix + 'IsFrontWheel: ' + $legacy.IsFrontWheel)
            $block.Add($prefix + 'IsSteerableWheel: ' + $legacy.IsSteerableWheel)
            $block.Add($prefix + 'IsBrakableWheel: ' + $legacy.IsBrakableWheel)
            Convert-VehicleWheelProperties $block $propertyIndent $File ($index + 1)
        }

        $after = [string]::Join($NewLine, $block)
        if ($after -eq $before) {
            $script:ChangeCount = $changeCountBefore
            if ($script:Findings.Count -gt $findingCountBefore) {
                $script:Findings.RemoveRange($findingCountBefore, $script:Findings.Count - $findingCountBefore)
            }
        }
        else {
            Add-Finding 'Info' 'existing-jolt-vehicle-repaired' $File ($index + 1) ('A vehicle produced by an earlier migrator run was rebuilt from its Bullet backup values instead of retaining the fixed VehiclesSample geometry (asset chassis mass: ' + (Format-Float $script:CurrentAssetVehicleMass) + ' kg).')
        }

        foreach ($line in $block) { $output.Add($line) }
        $index = $end
    }

    return [string]::Join($NewLine, $output)
}

function Stabilize-ConstraintChains {
    param(
        [string] $Text,
        [string] $File,
        [string] $NewLine
    )

    if ($script:ReferenceVehicleMass -le 0.0) {
        return $Text
    }

    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $legacyJointPattern = '!Evergine\.Framework\.Physics3D\.HingeJoint3D,Evergine\.Framework'
    $joltConstraintPattern = '!Evergine\.Framework\.Physics\.HingeConstraint,Evergine\.Framework'
    $jointPattern = '(?:' + $legacyJointPattern + '|' + $joltConstraintPattern + ')'
    $candidatesByBody = @{}

    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch $jointPattern) {
            continue
        }

        $range = Get-YamlContainingComponentsRange $lines $index
        if ($null -eq $range) {
            continue
        }

        $body = Get-YamlBodyInfoFromComponents $lines $range
        if ($null -eq $body -or -not $body.IsDynamic -or $body.MassIndex -lt 0 -or $body.Mass -le 0.0) {
            continue
        }

        $ratio = $script:ReferenceVehicleMass / $body.Mass
        if ($ratio -lt 100.0) {
            continue
        }

        $key = $body.Start.ToString($script:Invariant)
        if (-not $candidatesByBody.ContainsKey($key)) {
            $candidatesByBody[$key] = [pscustomobject]@{
                Body = $body
                ConstraintIndices = New-Object 'System.Collections.Generic.List[int]'
            }
        }

        $candidatesByBody[$key].ConstraintIndices.Add($index)
    }

    # One unusually light constrained body may be intentional. Three or more
    # hinged bodies in the same asset is the characteristic bridge/chain case
    # where a heavy vehicle makes an iterative solver stretch the joints.
    if ($candidatesByBody.Count -lt 3) {
        return $Text
    }

    $targetMass = $script:ReferenceVehicleMass / 20.0
    if (-not $StabilizeConstraintChains) {
        # Opt-in only: report the fragile chain but keep every authored mass.
        $light = @($candidatesByBody.Values | Where-Object { $_.Body.Mass -lt $targetMass })
        if ($light.Count -gt 0) {
            $lightest = ($light | ForEach-Object { $_.Body.Mass } | Measure-Object -Minimum).Minimum
            Add-Finding 'Info' 'fragile-constraint-chain' $File ($light[0].Body.MassIndex + 1) ($light.Count.ToString($script:Invariant) + ' hinged bodies (from ' + (Format-Float $lightest) + ' kg) share the project with a ' + (Format-Float $script:ReferenceVehicleMass) + ' kg vehicle. Masses were kept; if the chain stretches under the vehicle, rerun with -StabilizeConstraintChains or raise the masses/solver iterations by hand.')
        }
        return $Text
    }

    $directConstraintIndices = New-Object 'System.Collections.Generic.List[int]'
    foreach ($candidate in $candidatesByBody.Values) {
        $body = $candidate.Body
        if ($body.Mass -ge $targetMass) {
            continue
        }

        $massMatch = [regex]::Match($lines[$body.MassIndex], '^(?<prefix>\s*Mass:\s*)(?<value>[-+0-9.eE]+)(?<suffix>\s*)$')
        if (-not $massMatch.Success) {
            continue
        }

        $lines[$body.MassIndex] = $massMatch.Groups['prefix'].Value + (Format-Float $targetMass) + $massMatch.Groups['suffix'].Value
        foreach ($constraintIndex in $candidate.ConstraintIndices) {
            $constraintIndent = ([regex]::Match($lines[$constraintIndex], '^\s*').Value).Length
            $constraintEnd = Get-YamlComponentBlockEnd $lines $constraintIndex $constraintIndent $lines.Length
            for ($propertyIndex = $constraintIndex + 1; $propertyIndex -lt $constraintEnd; $propertyIndex++) {
                if ($lines[$propertyIndex] -match '^\s*Id:\s*(?<value>\S+)') {
                    $script:StabilizedConstraintIds[$File + '|' + $Matches['value']] = $true
                    break
                }
            }

            if ($lines[$constraintIndex] -match $joltConstraintPattern -and -not $directConstraintIndices.Contains($constraintIndex)) {
                $directConstraintIndices.Add($constraintIndex)
            }
        }

        Add-Change
        $script:StabilizedConstraintBodyCount++
        Add-Finding 'Warning' 'constraint-chain-mass-stabilized' $File ($body.MassIndex + 1) ('Raised a constrained body from ' + (Format-Float $body.Mass) + ' kg to ' + (Format-Float $targetMass) + ' kg, keeping its ratio to the ' + (Format-Float $script:ReferenceVehicleMass) + ' kg vehicle at 20:1 (-StabilizeConstraintChains).')
    }

    # A project may already have been converted by an older revision of this
    # migrator. Repair existing Jolt constraints in place as well as marking
    # legacy joints for Convert-ConstraintProperties below.
    $insertAfter = @{}
    foreach ($constraintIndex in $directConstraintIndices) {
        $constraintIndent = ([regex]::Match($lines[$constraintIndex], '^\s*').Value).Length
        $propertyIndent = $constraintIndent + 2
        $propertyPrefix = ' ' * $propertyIndent
        $constraintEnd = Get-YamlComponentBlockEnd $lines $constraintIndex $constraintIndent $lines.Length
        $velocityIndex = -1
        $positionIndex = -1
        $motorModeIndex = -1
        $motorTorque = $null

        for ($propertyIndex = $constraintIndex + 1; $propertyIndex -lt $constraintEnd; $propertyIndex++) {
            if ($lines[$propertyIndex] -match '^\s*SolverVelocityIterationsOverride:') {
                $velocityIndex = $propertyIndex
            }
            elseif ($lines[$propertyIndex] -match '^\s*SolverPositionIterationsOverride:') {
                $positionIndex = $propertyIndex
            }
            elseif ($lines[$propertyIndex] -match '^\s*MotorMode:\s*(?:Velocity|Position)\s*$') {
                $motorModeIndex = $propertyIndex
            }
            elseif ($lines[$propertyIndex] -match '^\s*MaxMotorTorque:\s*(?<value>[-+0-9.eE]+)\s*$') {
                $parsedTorque = 0.0
                if ([double]::TryParse($Matches['value'], [System.Globalization.NumberStyles]::Float, $script:Invariant, [ref]$parsedTorque)) {
                    $motorTorque = $parsedTorque
                }
            }
        }

        if ($velocityIndex -ge 0) {
            if ($lines[$velocityIndex] -notmatch ':\s*32\s*$') {
                $lines[$velocityIndex] = $propertyPrefix + 'SolverVelocityIterationsOverride: 32'
                Add-Change
            }
        }
        else {
            $insertAfter[$constraintIndex] = New-Object 'System.Collections.Generic.List[string]'
            $insertAfter[$constraintIndex].Add($propertyPrefix + 'SolverVelocityIterationsOverride: 32')
            Add-Change
        }

        if ($positionIndex -ge 0) {
            if ($lines[$positionIndex] -notmatch ':\s*8\s*$') {
                $lines[$positionIndex] = $propertyPrefix + 'SolverPositionIterationsOverride: 8'
                Add-Change
            }
        }
        else {
            $insertIndex = if ($velocityIndex -ge 0) { $velocityIndex } else { $constraintIndex }
            if (-not $insertAfter.ContainsKey($insertIndex)) {
                $insertAfter[$insertIndex] = New-Object 'System.Collections.Generic.List[string]'
            }
            $insertAfter[$insertIndex].Add($propertyPrefix + 'SolverPositionIterationsOverride: 8')
            Add-Change
        }

        if ($motorModeIndex -ge 0 -and $null -ne $motorTorque -and [Math]::Abs($motorTorque) -le 0.000001) {
            $lines[$motorModeIndex] = $propertyPrefix + 'MotorMode: Off'
            Add-Change
            Add-Finding 'Info' 'zero-torque-hinge-motor-disabled' $File ($motorModeIndex + 1) 'A previously migrated Jolt hinge had an enabled zero-torque motor. Its motor mode was repaired to Off.'
        }

        Add-Finding 'Info' 'constraint-chain-solver-stabilized' $File ($constraintIndex + 1) 'This existing Jolt constraint belongs to a high-mass-ratio chain; its solver overrides were set to 32 velocity and 8 position iterations.'
    }

    if ($insertAfter.Count -gt 0) {
        $output = New-Object 'System.Collections.Generic.List[string]'
        for ($index = 0; $index -lt $lines.Length; $index++) {
            $output.Add($lines[$index])
            if ($insertAfter.ContainsKey($index)) {
                foreach ($insertedLine in $insertAfter[$index]) {
                    $output.Add($insertedLine)
                }
            }
        }

        $lines = $output.ToArray()
    }

    return [string]::Join($NewLine, $lines)
}

function Set-WheeledVehicleControllerProfile {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [object] $Layout
    )

    $vehicleMassScale = if ($script:CurrentAssetVehicleMass -gt 0.0) { $script:CurrentAssetVehicleMass / 1200.0 } else { 1.0 }
    $engineTorque = [Math]::Max(50.0, [Math]::Min(2000.0, 600.0 * $vehicleMassScale))
    $antiRollStiffness = [Math]::Max(100.0, [Math]::Min(5000.0, 1000.0 * $vehicleMassScale))

    Set-VectorProperty $Lines $Indent 'Up' 0.0 1.0 0.0 | Out-Null
    Set-VectorProperty $Lines $Indent 'Forward' 0.0 0.0 1.0 | Out-Null
    Set-ScalarProperty $Lines $Indent 'MaxPitchRollAngle' '0.7853982' | Out-Null
    Set-ScalarProperty $Lines $Indent 'CollisionTesterType' 'CastSphere' | Out-Null
    Set-ScalarProperty $Lines $Indent 'EngineMaxTorque' (Format-Float $engineTorque) | Out-Null
    foreach ($name in 'FrontWheelLeft', 'FrontWheelRight', 'RearWheelLeft', 'RearWheelRight', 'FrontWheelDrive', 'RearWheelDrive') {
        Set-ScalarProperty $Lines $Indent $name ([string]$Layout.$name).ToLowerInvariant() | Out-Null
    }
    Set-ScalarProperty $Lines $Indent 'AntiRollStiffness' (Format-Float $antiRollStiffness) | Out-Null
}

function Test-IsLegacyPhysicsType {
    param([string] $Type)
    return $Type -match '^Evergine\.(?:Framework\.Physics3D|Bullet)\.'
}

function Get-LineIndent {
    param([string] $Line)
    return ([regex]::Match($Line, '^\s*').Value).Length
}

function Get-YamlValue {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $Name
    )

    $range = Get-PropertyRange $Lines $Indent $Name
    if ($null -ne $range) { return $range.Value.Trim("'", '"') }
}

function Expand-LegacyErrorComponents {
    param(
        [string] $Text,
        [string] $File,
        [string] $NewLine,
        [bool] $Report = $true
    )

    if ($Text -notmatch 'Evergine\.Framework\.ErrorComponent') {
        return $Text
    }

    # The new Studio saves Physics3D components as ErrorComponent, keeping the tag in
    # OldType and the members in Properties. Restore the legacy block.
    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $output = New-Object 'System.Collections.Generic.List[string]'
    $restored = 0
    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch '^(?<indent>\s*)-\s+!Evergine\.Framework\.ErrorComponent,Evergine\.Framework\s*$') {
            $output.Add($lines[$index])
            continue
        }

        $indent = $Matches['indent'].Length
        $end = Get-YamlComponentBlockEnd $lines $index $indent $lines.Length
        $block = [System.Collections.Generic.List[string]]$lines[$index..($end - 1)]
        $properties = Get-PropertyRange $block ($indent + 2) 'Properties'
        $index = $end - 1
        if ($null -eq $properties -or (Get-YamlValue $block ($indent + 2) 'OldType') -notmatch '^!(?<type>Evergine\.(?:Framework\.Physics3D|Bullet)\.[^,]+,\S+)$') {
            $output.AddRange($block)
            continue
        }

        # Dedent the members, drop their dictionary tags and put the Id first.
        $output.Add((' ' * $indent) + '- !' + $Matches['type'])
        $members = @($block.GetRange($properties.Start + 1, $properties.End - $properties.Start - 1) | ForEach-Object { $_.Substring(2) -replace '^(\s*(?:\w+:|-))\s*!System\.\S+\s*$', '$1' })
        $idPattern = '^' + (' ' * ($indent + 2)) + 'Id:'
        $output.AddRange([string[]]@($members -match $idPattern))
        $output.AddRange([string[]]@($members -notmatch $idPattern))
        $restored++
    }

    if ($restored -gt 0 -and $Report) {
        Add-Change
        Add-Finding 'Warning' 'error-component-restored' $File 0 ($restored.ToString($script:Invariant) + ' Physics3D component(s) saved as ErrorComponent by the new Studio were restored from OldType/Properties and migrated.')
    }

    return $(if ($restored -gt 0) { [string]::Join($NewLine, $output) } else { $Text })
}

function Get-YamlEntityIndex {
    param([string[]] $Lines)

    # An entity is the mapping that holds a Components list. Entities appear in
    # document order, so the innermost one still open is the parent.
    $entities = New-Object 'System.Collections.Generic.List[object]'
    $roots = New-Object 'System.Collections.Generic.List[object]'
    $stack = New-Object 'System.Collections.Generic.List[object]'
    for ($line = 0; $line -lt $Lines.Length; $line++) {
        if ($Lines[$line] -notmatch '^(?<indent>\s*)Components:\s*$') {
            continue
        }

        $indent = $Matches['indent'].Length
        $header = $line - 1
        while ($header -ge 0 -and (Get-LineIndent $Lines[$header]) -ge $indent) { $header-- }
        $end = $line + 1
        while ($end -lt $Lines.Length -and (Get-LineIndent $Lines[$end]) -ge $indent) { $end++ }

        $block = [System.Collections.Generic.List[string]]$Lines[$header..($end - 1)]
        $entity = [pscustomobject]@{
            Name = Get-YamlValue $block $indent 'Name'
            Id = Get-YamlValue $block $indent 'Id'
            Header = $header
            End = $end
            Parent = $null
            Children = New-Object 'System.Collections.Generic.List[object]'
            Components = New-Object 'System.Collections.Generic.List[object]'
            Position = [pscustomobject]@{ X = 0.0; Y = 0.0; Z = 0.0 }
            Orientation = [pscustomobject]@{ X = 0.0; Y = 0.0; Z = 0.0; W = 1.0 }
            Scale = [pscustomobject]@{ X = 1.0; Y = 1.0; Z = 1.0 }
            HasModel = $false
        }

        for ($start = $line + 1; $start -lt $end -and (Get-LineIndent $Lines[$start]) -gt $indent; $start++) {
            if ($Lines[$start] -notmatch ('^' + (' ' * ($indent + 2)) + '-\s+!(?<type>[^,\s]+),')) {
                continue
            }

            $componentEnd = Get-YamlComponentBlockEnd $Lines $start ($indent + 2) $end
            $component = [pscustomobject]@{
                Type = $Matches['type']
                Start = $start
                Indent = $indent + 4
                Block = [System.Collections.Generic.List[string]]$Lines[$start..($componentEnd - 1)]
                Entity = $entity
            }
            $entity.Components.Add($component)
            if ($component.Type -eq 'Evergine.Framework.Graphics.Transform3D') {
                $entity.Position = Get-VectorProperty $component.Block $component.Indent 'LocalPosition'
                $entity.Orientation = Get-VectorProperty $component.Block $component.Indent 'LocalOrientation'
                $entity.Scale = Get-VectorProperty $component.Block $component.Indent 'LocalScale'
            }
            $entity.HasModel = $entity.HasModel -or ($component.Type -match '(?:Mesh|MeshComponent|Model)$' -and $component.Type -notmatch 'Collider')
            $start = $componentEnd - 1
        }

        while ($stack.Count -gt 0 -and $stack[$stack.Count - 1].End -le $header) { $stack.RemoveAt($stack.Count - 1) }
        if ($stack.Count -gt 0) {
            $entity.Parent = $stack[$stack.Count - 1]
            $entity.Parent.Children.Add($entity)
        }
        else {
            $roots.Add($entity)
        }

        $stack.Add($entity)
        $entities.Add($entity)
    }

    return [pscustomobject]@{ Entities = $entities; Roots = $roots; IsPrefab = $Lines[0] -match 'PrefabModel' }
}

function Find-EntityComponent {
    param([object] $Entity, [string] $Pattern)
    return $Entity.Components | Where-Object { $_.Type -match $Pattern } | Select-Object -First 1
}

function Resolve-YamlEntityPath {
    param([object] $Index, [string] $Path)

    # EntityPathHelper.EntityFromPath: the first root with the first name, then the first child with each name.
    $segments = $Path.Split('.')
    $candidates = @($Index.Roots | Where-Object { $_.Name -eq $segments[0] })
    $ambiguous = $candidates.Count -gt 1
    for ($segment = 1; $segment -lt $segments.Length -and $candidates.Count -gt 0; $segment++) {
        $candidates = @($candidates[0].Children | Where-Object { $_.Name -eq $segments[$segment] })
        $ambiguous = $ambiguous -or $candidates.Count -gt 1
    }

    return [pscustomobject]@{ Entity = $(if ($candidates.Count -gt 0) { $candidates[0] }); Ambiguous = $ambiguous }
}

function Get-PositionRelativeTo {
    param([object] $Entity, [object] $Ancestor)

    $x = 0.0; $y = 0.0; $z = 0.0
    for ($current = $Entity; $null -ne $current -and $current -ne $Ancestor; $current = $current.Parent) {
        # Scale, then rotate by the quaternion (v + 2w(q x v) + 2 q x (q x v)), then translate.
        $q = $current.Orientation
        $vx = $x * $current.Scale.X; $vy = $y * $current.Scale.Y; $vz = $z * $current.Scale.Z
        $tx = 2.0 * (($q.Y * $vz) - ($q.Z * $vy)); $ty = 2.0 * (($q.Z * $vx) - ($q.X * $vz)); $tz = 2.0 * (($q.X * $vy) - ($q.Y * $vx))
        $x = $vx + ($q.W * $tx) + (($q.Y * $tz) - ($q.Z * $ty)) + $current.Position.X
        $y = $vy + ($q.W * $ty) + (($q.Z * $tx) - ($q.X * $tz)) + $current.Position.Y
        $z = $vz + ($q.W * $tz) + (($q.X * $ty) - ($q.Y * $tx)) + $current.Position.Z
    }

    return [pscustomobject]@{ X = $x; Y = $y; Z = $z }
}

function Initialize-YamlFileContext {
    param([string[]] $Lines)

    # Facts that need more than one component, keyed by the component's first line.
    $index = Get-YamlEntityIndex $Lines
    $context = @{ DynamicCollider = @{}; ConnectedEntity = @{}; Character = @{}; Remove = @{}; VehicleLayout = @{}; WheelVehicle = @{}; HasLegacy = $false }
    foreach ($entity in $index.Entities) {
        foreach ($component in @($entity.Components | Where-Object { Test-IsLegacyPhysicsType $_.Type })) {
            $context.HasLegacy = $true
            $type = $component.Type -replace '^.*\.', ''
            if ($type -like '*Collider3D') {
                # A collider belongs to the nearest body on its entity or an ancestor.
                for ($owner = $entity; $null -ne $owner; $owner = $owner.Parent) {
                    $body = Find-EntityComponent $owner '\.(?:RigidBody3D|RigidBody|StaticBody3D|StaticBody|CharacterController3D)$'
                    if ($null -eq $body) { continue }
                    if ($body.Type -match 'RigidBody' -and (Get-YamlValue $body.Block $body.Indent 'PhysicBodyType') -ne 'Kinematic' -and (Get-YamlValue $body.Block $body.Indent 'IsKinematic') -ne 'true') {
                        $context.DynamicCollider[$component.Start] = $true
                    }
                    break
                }
            }
            elseif ($type -like '*Joint3D') {
                $path = Get-YamlValue $component.Block $component.Indent 'ConnectedEntityPath'
                if ($path -and $path -ne 'null') {
                    $resolved = Resolve-YamlEntityPath $index $path
                    $context.ConnectedEntity[$component.Start] = [pscustomobject]@{ Path = $path; Entity = $resolved.Entity; Ambiguous = $resolved.Ambiguous; IsPrefab = $index.IsPrefab }
                }
            }
            elseif ($type -eq 'CharacterController3D') {
                # The Jolt character owns its capsule: the legacy colliders on its entity are
                # removed and the first gives the size, scaled by the entity like Bullet did.
                $shape = $null
                foreach ($collider in @($entity.Components | Where-Object { $_.Type -match '\.(?:Capsule|Box|Sphere|Cylinder|Cone|Mesh)Collider3D$' })) {
                    $context.Remove[$collider.Start] = $true
                    if ($null -ne $shape) { continue }
                    $source = $collider.Type -replace '^.*\.', ''
                    $radius = Get-NumericProperty $collider.Block $collider.Indent 'Radius' 0.5
                    $height = Get-NumericProperty $collider.Block $collider.Indent 'Height' 1.0
                    if ($source -eq 'SphereCollider3D') { $height = 2.0 * $radius }
                    if ($source -eq 'BoxCollider3D') {
                        $size = Get-VectorProperty $collider.Block $collider.Indent 'Size'
                        $radius = 0.5 * [Math]::Max($size.X, $size.Z)
                        $height = $size.Y
                    }
                    $radius *= [Math]::Max([Math]::Abs($entity.Scale.X), [Math]::Abs($entity.Scale.Z))
                    $height *= [Math]::Abs($entity.Scale.Y)
                    $shape = [pscustomobject]@{ Radius = $radius; Height = [Math]::Max($height, 2.0 * $radius); Source = $source; Exact = $source -eq 'CapsuleCollider3D'; ModelRelative = $entity.HasModel }
                }
                $context.Character[$component.Start] = $shape
            }
            elseif ($type -eq 'PhysicVehicle3D') {
                # Wheels in VehicleController.CollectWheels order (the vehicle entity and its subtree in
                # document order, one wheel per entity). Left is negative X, -1 marks a missing wheel and
                # an axle is driven if any of its wheels was.
                $layout = [ordered]@{ FrontWheelLeft = -1; FrontWheelRight = -1; RearWheelLeft = -1; RearWheelRight = -1; FrontWheelDrive = $false; RearWheelDrive = $false; Unassigned = 0 }
                $wheels = @($index.Entities | Where-Object { $_.Header -ge $entity.Header -and $_.Header -lt $entity.End } | ForEach-Object { Find-EntityComponent $_ '\.(?:PhysicWheel3D|VehicleWheel)$' })
                for ($wheelIndex = 0; $wheelIndex -lt $wheels.Count; $wheelIndex++) {
                    $wheel = $wheels[$wheelIndex]
                    $axle = if ((Get-YamlValue $wheel.Block $wheel.Indent 'IsFrontWheel') -eq 'true') { 'FrontWheel' } else { 'RearWheel' }
                    $x = (Get-PositionRelativeTo $wheel.Entity $entity).X
                    $sides = if ($x -lt -0.0001) { 'Left' } elseif ($x -gt 0.0001) { 'Right' } else { 'Left', 'Right' }
                    $side = @($sides | Where-Object { $layout[$axle + $_] -lt 0 })
                    if ($side.Count -gt 0) { $layout[$axle + $side[0]] = $wheelIndex } else { $layout.Unassigned++ }
                    if ((Get-YamlValue $wheel.Block $wheel.Indent 'IsDriveWheel') -ne 'false') { $layout[$axle + 'Drive'] = $true }
                }
                $context.VehicleLayout[$component.Start] = [pscustomobject]$layout
            }
            elseif ($type -eq 'PhysicWheel3D') {
                # FromParents skips the wheel's own entity; FromEntityPath resolves a path.
                $fromPath = (Get-YamlValue $component.Block $component.Indent 'SearchVehicle') -eq 'FromEntityPath'
                $owner = if ($fromPath) { (Resolve-YamlEntityPath $index ([string](Get-YamlValue $component.Block $component.Indent 'PhysicVehicleEntityPath'))).Entity } else { $entity.Parent }
                $vehicle = $null
                for (; $null -ne $owner -and $null -eq $vehicle; $owner = $(if ($fromPath) { $null } else { $owner.Parent })) {
                    $vehicle = Find-EntityComponent $owner '\.PhysicVehicle3D$'
                }
                $values = @{}
                foreach ($name in @('SuspensionStiffness', 'SuspensionCompression', 'SuspensionDamping', 'MaxSuspensionTravel', 'FrictionSlip', 'MaxSuspensionForce')) {
                    if ($null -ne $vehicle -and $null -ne (Get-PropertyRange $vehicle.Block $vehicle.Indent $name)) { $values[$name] = (Get-PropertyRange $vehicle.Block $vehicle.Indent $name).Value }
                }
                $context.WheelVehicle[$component.Start] = [pscustomobject]@{ FromEntityPath = $fromPath; VehicleFound = $null -ne $vehicle; VehicleValues = $values }
            }
        }
    }

    return $context
}

function ConvertTo-CategoryMask {
    param([string] $Value)

    # "Cat1, Cat3", "CollisionCategory3D.Cat1 | CollisionCategory3D.Cat3", "All" or a number; $null if unreadable.
    if ($Value.Trim("'", '"', ' ') -match '^\d+$') { return [uint32]([int]$Matches[0] -band 0xFFFF) }
    $mask = [uint32]0
    foreach ($name in ($Value -split '[,|]' | ForEach-Object { ($_ -replace '^.*\.', '').Trim("'", '"', ' ') })) {
        if ($name -eq 'All') { $mask = $mask -bor [uint32]0xFFFF }
        elseif ($name -match '^Cat(\d+)$' -and [int]$Matches[1] -le 16) { $mask = $mask -bor ([uint32]1 -shl ([int]$Matches[1] - 1)) }
        elseif ($name -ne 'None') { return $null }
    }

    return $mask
}

function Add-CollisionEvidence {
    param([string] $Category, [string] $Mask, [string] $File)

    $categoryBits = ConvertTo-CategoryMask $(if ($Category) { $Category } else { 'Cat1' })
    $maskBits = ConvertTo-CategoryMask $(if ($Mask) { $Mask } else { 'All' })
    if ($null -eq $categoryBits -or $null -eq $maskBits) {
        Add-Finding 'Warning' 'collision-filter-unreadable' $File 0 ('The category/mask "' + $Category + '" / "' + $Mask + '" could not be evaluated for the generated CollisionMatrix; review it by hand.')
    }
    elseif ($categoryBits -ne 0) {
        $script:CollisionEvidence.Add([pscustomobject]@{ Category = $categoryBits; Mask = $maskBits })
    }
}

function Get-ProjectCollisionMatrix {
    # Bullet collided when (A.group & B.mask) && (B.group & A.mask). Jolt keeps the lowest
    # category bit of each body; a category with no recorded body acts like a Bullet
    # default body (mask All). Categories 17-32 did not exist and stay isolated.
    $byCategory = @{}
    foreach ($evidence in $script:CollisionEvidence) {
        $index = [int][Math]::Round([Math]::Log([double]($evidence.Category -band (-bnot ($evidence.Category - 1))), 2))
        if (-not $byCategory.ContainsKey($index)) { $byCategory[$index] = New-Object 'System.Collections.Generic.List[object]' }
        $byCategory[$index].Add($evidence)
    }

    $matrix = New-Object 'uint32[]' 32
    for ($i = 0; $i -lt 32; $i++) { $matrix[$i] = [uint32]1 -shl $i }
    $conflicts = New-Object 'System.Collections.Generic.List[string]'
    $disabled = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 0; $i -lt 16; $i++) {
        for ($j = $i; $j -lt 16; $j++) {
            $results = @(foreach ($a in $(if ($byCategory.ContainsKey($i)) { $byCategory[$i] } else { [pscustomobject]@{ Category = [uint32]1 -shl $i; Mask = [uint32]0xFFFF } })) {
                foreach ($b in $(if ($byCategory.ContainsKey($j)) { $byCategory[$j] } else { [pscustomobject]@{ Category = [uint32]1 -shl $j; Mask = [uint32]0xFFFF } })) {
                    (($a.Category -band $b.Mask) -ne 0) -and (($b.Category -band $a.Mask) -ne 0)
                }
            })
            $pair = 'Cat' + ($i + 1) + '/Cat' + ($j + 1)
            $used = $byCategory.ContainsKey($i) -and $byCategory.ContainsKey($j)
            if ($results -contains $true) {
                $matrix[$i] = $matrix[$i] -bor ([uint32]1 -shl $j)
                $matrix[$j] = $matrix[$j] -bor ([uint32]1 -shl $i)
                if ($used -and $results -contains $false) { $conflicts.Add($pair) }
            }
            else {
                if ($i -eq $j) { $matrix[$i] = $matrix[$i] -band (-bnot ([uint32]1 -shl $i)) }
                if ($used) { $disabled.Add($pair) }
            }
        }
    }

    $summary = 'CollisionMatrix generated from the Bullet category masks (categories in use: ' + (@($byCategory.Keys | Sort-Object | ForEach-Object { 'Cat' + ($_ + 1) }) -join ', ') + ')' + $(if ($disabled.Count -gt 0) { '; pairs that never collided stay disabled: ' + ($disabled -join ', ') }) + '.'
    return [pscustomobject]@{ Matrix = $matrix; Conflicts = $conflicts; Summary = $summary; NeedsMatrix = $byCategory.Count -gt 1 -or $disabled.Count -gt 0 }
}

function Set-CollisionMatrixProperty {
    param(
        [System.Collections.Generic.List[string]] $Lines,
        [int] $Indent,
        [string] $File,
        [int] $BaseLine
    )

    $script:CollisionMatrixTargets++
    $wanted = @((' ' * $Indent) + 'CollisionMatrix:') + @($script:ProjectCollisionMatrix.Matrix | ForEach-Object { (' ' * $Indent) + '  - ' + $_.ToString($script:Invariant) })
    $range = Get-PropertyRange $Lines $Indent 'CollisionMatrix'
    if ($null -ne $range) {
        if (($Lines.GetRange($range.Start, $range.End - $range.Start) -join "`n") -ceq ($wanted -join "`n")) { return }
        $Lines.RemoveRange($range.Start, $range.End - $range.Start)
    }

    $Lines.InsertRange($(if ($null -ne $range) { $range.Start } else { $Lines.Count }), [string[]]$wanted)
    Add-Change
    Add-Finding 'Info' 'collision-matrix-generated' $File $BaseLine $script:ProjectCollisionMatrix.Summary
}

function Format-CollisionMatrixSource {
    return 'new uint[] { ' + (@($script:ProjectCollisionMatrix.Matrix | ForEach-Object { '0x' + $_.ToString('X', $script:Invariant) + 'u' }) -join ', ') + ' }'
}

function Convert-YamlBlock {
    param(
        [string[]] $Block,
        [string] $OldType,
        [string] $OldAssembly,
        [string] $File,
        [int] $BaseLine
    )

    $mapping = $script:TypeMappings[$OldType]
    $newType = $mapping[0]
    $newAssembly = $mapping[1]
    $lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $Block) { $lines.Add($line) }

    $lines[0] = $lines[0] -replace ('!' + [regex]::Escape($OldType + ',' + $OldAssembly)), ('!' + $newType + ',' + $newAssembly)
    $tagIndent = ([regex]::Match($lines[0], '^\s*').Value).Length
    $propertyIndent = $tagIndent + 2
    Add-Change
    $script:ConvertedComponentCount++
    foreach ($rename in @(Get-MemberRenames $OldType)) {
        Rename-Property $lines $propertyIndent $rename[0] $rename[1] | Out-Null
    }

    if ($newType -eq 'Evergine.Framework.Physics.RigidBody') {
        Convert-CommonBodyProperties $lines $propertyIndent $File $BaseLine
        Convert-RigidBodyProperties $lines $propertyIndent $File $BaseLine
    }
    elseif ($newType -eq 'Evergine.Framework.Physics.StaticBody') {
        Convert-CommonBodyProperties $lines $propertyIndent $File $BaseLine
    }
    elseif ($newType -eq 'Evergine.Framework.Physics.CharacterController') {
        $gravity = Get-NumericProperty $lines $propertyIndent 'Gravity' 29.4
        if ($null -ne (Get-PropertyRange $lines $propertyIndent 'Gravity')) {
            Set-ScalarProperty $lines $propertyIndent 'ApplyGravity' $(if ([Math]::Abs($gravity) -gt 0.000001) { 'true' } else { 'false' })
        }

        # The capsule comes from the legacy collider Initialize-YamlFileContext removed.
        $shape = $script:Context.Character[$BaseLine - 1]
        $notes = @(if ($null -eq $shape) { 'no collider found, Radius/Height keep the Jolt defaults' } else {
            Set-ScalarProperty $lines $propertyIndent 'Radius' (Format-Float $shape.Radius)
            Set-ScalarProperty $lines $propertyIndent 'Height' (Format-Float $shape.Height)
            'Radius/Height copied from the removed ' + $shape.Source
            if (-not $shape.Exact) { 'the shape was approximated by a capsule' }
            if ($shape.ModelRelative) { 'the size was relative to the model bounds in Bullet' }
        })
        foreach ($setting in @(@('JumpSpeed', 10.0, 'pass it to Jump(speed)'), @('FallSpeed', 55.0, 'no equivalent'), @('Gravity', 29.4, 'the world gravity applies'))) {
            $value = Get-NumericProperty $lines $propertyIndent $setting[0] $setting[1]
            if ([Math]::Abs([Math]::Abs($value) - $setting[1]) -gt 0.01) { $notes += $setting[0] + ' ' + (Format-Float $value) + ': ' + $setting[2] }
            Remove-Property $lines $propertyIndent $setting[0] | Out-Null
        }
        Add-Finding $(if ($notes.Count -gt 1 -or $null -eq $shape) { 'Warning' } else { 'Info' }) 'character-migrated' $File $BaseLine ('The Jolt character owns its capsule: ' + ($notes -join '; ') + '.')
    }
    elseif ($newType.EndsWith('Collider')) {
        Convert-ColliderProperties $lines $propertyIndent $OldType $newType $File $BaseLine
    }
    elseif ($newType.EndsWith('Constraint')) {
        Convert-ConstraintProperties $lines $propertyIndent $OldType $newType $File $BaseLine
    }
    elseif ($newType -eq 'Evergine.Framework.Physics.PhysicsManager') {
        $worldResolution = Get-PropertyRange $lines $propertyIndent 'PhysicWorldResolution'
        if ($null -ne $worldResolution -and $worldResolution.Value -notmatch '^1(?:\.0+)?$') {
            Add-Finding 'Warning' 'world-resolution-removed' $File ($BaseLine + $worldResolution.Start) 'Jolt has no PhysicWorldResolution scale. Scene units and physics dimensions must be converted manually.'
        }
        Set-CollisionMatrixProperty $lines $propertyIndent $File $BaseLine
    }
    elseif ($newType -eq 'Evergine.Framework.Physics.WheeledVehicleController') {
        Rename-Property $lines $propertyIndent 'ChassisBody' 'Body' | Out-Null
        # Suspension and grip were copied to the wheels that did not override them.
        foreach ($name in @('SuspensionStiffness', 'SuspensionCompression', 'SuspensionDamping', 'MaxSuspensionTravel', 'FrictionSlip', 'MaxSuspensionForce')) {
            Remove-Property $lines $propertyIndent $name | Out-Null
        }
        $layout = $script:Context.VehicleLayout[$BaseLine - 1]
        Set-WheeledVehicleControllerProfile $lines $propertyIndent $layout
        Add-Finding 'Warning' 'vehicle-derived-profile' $File $BaseLine ('The Jolt engine and wheel profile was derived from the Bullet values for a ' + (Format-Float $(if ($script:CurrentAssetVehicleMass -gt 0.0) { $script:CurrentAssetVehicleMass } else { 1200.0 })) + ' kg chassis (the heaviest in this asset); retune EngineMaxTorque if the legacy input was not a full-throttle force. Wheels: front ' + $layout.FrontWheelLeft + '/' + $layout.FrontWheelRight + ', rear ' + $layout.RearWheelLeft + '/' + $layout.RearWheelRight + ' (-1 = none), ' + $layout.Unassigned + ' unassigned; driven axles: ' + $(if ($layout.FrontWheelDrive) { 'front ' }) + $(if ($layout.RearWheelDrive) { 'rear' }) + '.')
    }
    elseif ($newType -eq 'Evergine.Framework.Physics.VehicleWheel') {
        $vehicle = $script:Context.WheelVehicle[$BaseLine - 1]
        if ($vehicle.FromEntityPath -or -not $vehicle.VehicleFound) {
            Add-Finding 'Warning' $(if ($vehicle.FromEntityPath) { 'vehicle-wheel-outside-vehicle' } else { 'vehicle-wheel-without-vehicle' }) $File $BaseLine 'A Jolt vehicle only collects the wheels on its own entity and its descendants; move this wheel under its vehicle entity.'
        }
        Copy-VehicleSettingsToWheel $lines $propertyIndent $vehicle
        Convert-VehicleWheelProperties $lines $propertyIndent $File $BaseLine
    }
    elseif ($newType -eq 'Evergine.Framework.Physics.RayEmitter' -or $newType -eq 'Evergine.Framework.Physics.SweepTestEmitter') {
        # CollisionCategory3D.All serialized as ushort.MaxValue; the Jolt enum covers 32 bits, so the numeric form would
        # only select the first sixteen categories. The names Cat1..Cat16, None and All are unchanged.
        $mask = Get-PropertyRange $lines $propertyIndent 'Mask'
        if ($null -ne $mask -and $mask.Value -eq '65535') {
            Set-ScalarProperty $lines $propertyIndent 'Mask' 'All' | Out-Null
        }
        elseif ($null -ne $mask -and $mask.Value -match '^(?:None|0)$') {
            Add-Finding 'Warning' 'query-mask-none' $File $BaseLine 'Mask None hit nothing in Bullet, but a Jolt QueryFilter treats None as every category; select the categories to test.'
        }
    }

    Remove-UnsupportedProperties $lines $propertyIndent $newType $File $BaseLine
    return $lines.ToArray()
}

function Convert-YamlContent {
    param(
        [string] $Text,
        [string] $File,
        [string] $NewLine
    )

    $Text = Expand-LegacyErrorComponents $Text $File $NewLine
    $script:CurrentAssetVehicleMass = Get-MaxVehicleMassFromYaml $Text
    $script:CurrentAssetWheelRadius = Get-MaxAuthoredVehicleWheelRadius $Text
    if ($TuneVehicleChassis) {
        $Text = Tune-VehicleChassis $Text $File $NewLine
    }
    $Text = Repair-ExistingJoltVehicleProfiles $Text $File $NewLine
    $Text = Stabilize-ConstraintChains $Text $File $NewLine
    $lines = [regex]::Split($Text, "`r`n|`n|`r")
    $script:Context = Initialize-YamlFileContext $lines
    $output = New-Object 'System.Collections.Generic.List[string]'
    $index = 0
    $tagPattern = '^\s*-\s+!(?<type>[^,\s]+),(?<assembly>[^\s]+)\s*$'

    while ($index -lt $lines.Length) {
        $line = $lines[$index]
        $tag = [regex]::Match($line, $tagPattern)
        $oldType = $tag.Groups['type'].Value
        $handled = $tag.Success -and ($script:TypeMappings.ContainsKey($oldType) -or $script:Context.Remove.ContainsKey($index) -or
            $oldType -match '\.Physics3D\.(?:ContactTestBehavior|SetCollisionEvents)$' -or ($oldType -eq 'Evergine.Framework.Physics.PhysicsManager' -and $script:Context.HasLegacy))
        if (-not $handled -and (Test-IsLegacyPhysicsType $oldType)) {
            Add-Finding 'Warning' 'legacy-component-unmapped' $File ($index + 1) ($oldType + ' has no Jolt counterpart and was left as is; remove or replace it by hand.')
        }

        if ($handled) {
            $oldAssembly = $tag.Groups['assembly'].Value
            $indent = ([regex]::Match($line, '^\s*').Value).Length
            $end = $index + 1
            while ($end -lt $lines.Length) {
                if ($lines[$end].Trim().Length -gt 0) {
                    $nextIndent = ([regex]::Match($lines[$end], '^\s*').Value).Length
                    if ($nextIndent -le $indent) { break }
                }
                $end++
            }

            $block = [System.Collections.Generic.List[string]]$lines[$index..($end - 1)]
            if ($script:Context.Remove.ContainsKey($index)) {
                # A collider that only shaped a Bullet character.
                Add-Change
                $block = @()
            }
            elseif ($script:TypeMappings.ContainsKey($oldType)) {
                $block = Convert-YamlBlock $block $oldType $oldAssembly $File ($index + 1)
            }
            elseif ($oldType -match 'PhysicsManager$') {
                # A manager the new Studio saved next to still-legacy bodies.
                Set-CollisionMatrixProperty $block ($indent + 2) $File ($index + 1)
            }
            else {
                Add-Change
                Add-Finding 'Warning' 'legacy-component-removed' $File ($index + 1) ($oldType + ' was a Bullet debugging helper and was removed; use the PhysicsBody collision events or PhysicsManager queries.')
                $block = @()
            }

            foreach ($convertedLine in $block) { $output.Add($convertedLine) }
            $index = $end
            continue
        }

        $output.Add($line)
        $index++
    }

    $result = [string]::Join($NewLine, $output)

    # Bullet serialized -1 to mean that a body/constraint inherits the global
    # solver iteration count. Jolt exposes the override as uint and uses zero for
    # that same behavior. Run this over the whole file as well so rerunning the
    # migrator repairs assets that were only partially converted by an older build.
    # Restrict whitespace to the current line. Using \s here also consumes the
    # carriage return in CRLF files and leaves a mixed-newline asset behind.
    $solverOverridePattern = '(?m)^(?<indent>[ \t]*)(?<name>Solver(?:Velocity|Position)IterationsOverride):[ \t]*-\d+[ \t]*(?<cr>\r?)$'
    $solverOverrides = [regex]::Matches($result, $solverOverridePattern)
    if ($solverOverrides.Count -gt 0) {
        $result = [regex]::Replace($result, $solverOverridePattern, '${indent}${name}: 0${cr}')
        Add-Change
        Add-Finding 'Info' 'solver-override-normalized' $File 0 ($solverOverrides.Count.ToString($script:Invariant) + ' negative solver-iteration override(s) changed to Jolt zero (inherit the manager setting).')
    }

    return $result
}

function Convert-ProjectContent {
    param(
        [string] $Text,
        [string] $File
    )

    # Include/Update package, version, project and assembly references, then item groups they emptied.
    $pattern = '(?ms)^[ \t]*<(?<item>PackageReference|PackageVersion|ProjectReference|Reference)\b[^>]*(?:Include|Update)\s*=\s*["''][^"'']*Evergine\.(?:Bullet|LibBulletc|BulletSharpPInvoke)\b[^"'']*["''][^>]*?(?:/>|(?<!/)>.*?</\k<item>>)[ \t]*\r?\n?'
    $result = [regex]::Replace($Text, $pattern, '')
    if ($result -ne $Text) {
        Add-Change
        $result = [regex]::Replace($result, '(?m)^[ \t]*<ItemGroup>\s*</ItemGroup>[ \t]*\r?\n', '')
    }

    if ($result -match 'Evergine\.(?:Bullet|LibBulletc)') {
        Add-Finding 'Warning' 'bullet-reference-remains' $File 0 'A Bullet reference remains in this project file and needs manual review.'
    }

    return $result
}

# A balanced (...), [...] or {...} group; string, char and line-comment literals are skipped.
$script:Literal = '"(?:\\.|[^"\\\n])*"|''(?:\\.|[^''\\\n])*''|//[^\n]*'
$script:Balanced = '[({\[](?>' + $script:Literal + '|[^(){}\[\]"''/]+|/|[({\[](?<depth>)|[)}\]](?<-depth>))*(?(depth)(?!))[)}\]]'

function Get-Balanced {
    param([string] $Text, [int] $Index)

    $match = [regex]::new('\G' + $script:Balanced).Match($Text, $Index)
    if ($match.Success) { return $match.Value }
}

function Split-CSharpTopLevel {
    param([string] $Text)
    return @([regex]::Matches($Text, '(?:' + $script:Balanced + '|' + $script:Literal + '|[^,(){}\[\]"''/]+|/)+') | ForEach-Object { $_.Value })
}

function ConvertFrom-CSharpNumber {
    param([string] $Expression)

    if ($Expression -match '^\s*(?<sign>-)?\s*(?:float|Single)\.MaxValue\s*$') { return $(if ($Matches['sign']) { -1 } else { 1 }) * [double][single]::MaxValue }
    if ($Expression -match '^\s*(?<number>[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)[fFdDmM]?\s*$') { return $Matches['number'] -as [double] }
}

function ConvertFrom-CSharpVector {
    param([string] $Expression)

    $named = @{ Zero = '0,0,0'; One = '1,1,1'; UnitX = '1,0,0'; UnitY = '0,1,0'; UnitZ = '0,0,1'; Up = '0,1,0'; Down = '0,-1,0'; Right = '1,0,0'; Left = '-1,0,0'; Forward = '0,0,-1'; Backward = '0,0,1' }
    if ($Expression -match '^\s*Vector3\.(?<name>\w+)\s*$' -and $named.ContainsKey($Matches['name'])) {
        $numbers = @($named[$Matches['name']].Split(',') | ForEach-Object { [double]$_ })
    }
    elseif ($Expression -match '^\s*new\s+Vector3\s*\((?<arguments>[^()]*)\)\s*$') {
        $numbers = @(Split-CSharpTopLevel $Matches['arguments'] | ForEach-Object { ConvertFrom-CSharpNumber $_ })
        if ($numbers.Count -eq 1) { $numbers = @($numbers[0], $numbers[0], $numbers[0]) }
    }
    else {
        return $null
    }

    if ($numbers.Count -eq 3 -and $numbers -notcontains $null) { return @{ X = $numbers[0]; Y = $numbers[1]; Z = $numbers[2] } }
}

function Format-CSharpFloat {
    param([double] $Value)

    if ([Math]::Abs($Value) -ge [double][single]::MaxValue) { return $(if ($Value -lt 0) { '-' }) + 'float.MaxValue' }
    $text = ([single]($Value + 0.0)).ToString('R', $script:Invariant)
    return $(if ($text -match '[.eE]') { $text } else { $text + '.0' }) + 'f'
}

function Format-CSharpVector {
    param([object] $Vector)
    return 'new Vector3(' + (Format-CSharpFloat $Vector.X) + ', ' + (Format-CSharpFloat $Vector.Y) + ', ' + (Format-CSharpFloat $Vector.Z) + ')'
}

function Get-PerpendicularAxes {
    param([object] $Axis)

    # btPlaneSpace1, as used by the Physics3D joint frames: p is perpendicular to the axis, q = axis x p.
    $length = [Math]::Sqrt(($Axis.X * $Axis.X) + ($Axis.Y * $Axis.Y) + ($Axis.Z * $Axis.Z))
    if ($length -lt 0.000001) { return $null }
    $nx = $Axis.X / $length; $ny = $Axis.Y / $length; $nz = $Axis.Z / $length
    if ([Math]::Abs($nz) -gt 0.7071067811865476) {
        $a = ($ny * $ny) + ($nz * $nz); $k = 1.0 / [Math]::Sqrt($a)
        $p = @{ X = 0.0; Y = -$nz * $k; Z = $ny * $k }
        return @{ P = $p; Q = @{ X = $a * $k; Y = -$nx * $p.Z; Z = $nx * $p.Y } }
    }

    $a = ($nx * $nx) + ($ny * $ny); $k = 1.0 / [Math]::Sqrt($a)
    $p = @{ X = -$ny * $k; Y = $nx * $k; Z = 0.0 }
    return @{ P = $p; Q = @{ X = -$nz * $p.Y; Y = $nz * $p.X; Z = $a * $k } }
}

function Get-DegreesOfFreedomExpression {
    param([string] $Expression, [string] $Prefix)

    # LinearFactor/AngularFactor: a non-zero component keeps the axis free.
    $vector = ConvertFrom-CSharpVector $Expression
    if ($null -eq $vector) {
        return (@('X', 'Y', 'Z' | ForEach-Object { '((' + $Expression.Trim() + ').' + $_ + ' != 0f ? DegreesOfFreedom.' + $Prefix + $_ + ' : DegreesOfFreedom.None)' }) -join ' | ')
    }

    $names = @('X', 'Y', 'Z' | Where-Object { [Math]::Abs($vector[$_]) -gt 0.000001 } | ForEach-Object { 'DegreesOfFreedom.' + $Prefix + $_ })
    return $(if ($names.Count -eq 0) { 'DegreesOfFreedom.None' } else { $names -join ' | ' })
}

function Get-InitializerMembers {
    param([string] $Inner)

    # Name = Value members of an object initializer, with the comment lines above each one.
    $members = New-Object 'System.Collections.Generic.List[object]'
    foreach ($segment in (Split-CSharpTopLevel $Inner)) {
        $comments = @([regex]::Matches($segment, '(?m)^\s*(//[^\r\n]*)') | ForEach-Object { $_.Groups[1].Value.TrimEnd() })
        $item = ($segment -replace '(?m)^\s*//[^\r\n]*', '').Trim()
        if ($item.Length -eq 0 -and $comments.Count -eq 0) { continue }
        $assignment = [regex]::Match($item, '^(?<name>[A-Za-z_]\w*)\s*=(?!=)\s*(?<value>[\s\S]+)$')
        $members.Add([pscustomobject]@{
            Name = $(if ($assignment.Success) { $assignment.Groups['name'].Value })
            Value = $(if ($assignment.Success) { $assignment.Groups['value'].Value.Trim() })
            Raw = $(if (-not $assignment.Success -and $item.Length -gt 0) { $item })
            Comments = $comments
        })
    }

    return , $members
}

function Format-Initializer {
    param([System.Collections.Generic.List[object]] $Members, [string] $Original, [string] $LineIndent, [string] $NewLine)

    $items = @($Members | ForEach-Object { if ($null -ne $_.Name) { $_.Name + ' = ' + $_.Value } elseif ($null -ne $_.Raw) { $_.Raw } })
    if (-not $Original.Contains("`n") -and @($Members | Where-Object { $_.Comments.Count -gt 0 }).Count -eq 0) {
        return $(if ($items.Count -eq 0) { '{ }' } else { '{ ' + ($items -join ', ') + ' }' })
    }

    # Multi-line: keep the item and closing-brace indentation of the original.
    $itemIndent = [regex]::Match($Original, '\n([ \t]*)[^\s}]')
    $itemIndent = if ($itemIndent.Success) { $itemIndent.Groups[1].Value } else { $LineIndent + '    ' }
    $closing = [regex]::Match($Original, '\n([ \t]*)\}$')
    $text = '{'
    foreach ($member in $Members) {
        foreach ($line in @($member.Comments) + @(if ($null -ne $member.Name) { $member.Name + ' = ' + $member.Value + ',' } elseif ($null -ne $member.Raw) { $member.Raw + ',' })) {
            $text += $NewLine + $itemIndent + $line
        }
    }

    return $text + $NewLine + $(if ($closing.Success) { $closing.Groups[1].Value } else { $LineIndent }) + '}'
}

function Get-Member {
    param($Members, [string] $Name)
    return @($Members | Where-Object { $_.Name -eq $Name })[0]
}

function Remove-Member {
    param($Members, [string] $Name)

    $found = Get-Member $Members $Name
    if ($null -ne $found) {
        # Keep the comments written above a removed member.
        $Members[$Members.IndexOf($found)] = [pscustomobject]@{ Name = $null; Value = $null; Raw = $null; Comments = $found.Comments }
    }
    return $found
}

function Set-Member {
    param($Members, [string] $Name, [string] $Value, [object] $After = $null, [System.Collections.Generic.List[string]] $Added = $null)

    # Replaces a member, or inserts it after $After (or at the end). With $Added, only a missing member is added.
    $found = Get-Member $Members $Name
    if ($null -ne $found -and $null -eq $Added) { $found.Value = $Value }
    if ($null -ne $found) { return }
    $Members.Insert($(if ($null -ne $After) { $Members.IndexOf($After) + 1 } else { $Members.Count }), [pscustomobject]@{ Name = $Name; Value = $Value; Raw = $null; Comments = @() })
    if ($null -ne $Added) { $Added.Add($Name) }
}

function Get-MotorModeExpression {
    param([string] $Value, [string] $On)
    if ($Value -eq 'true') { return 'MotorMode.' + $On }
    if ($Value -eq 'false') { return 'MotorMode.Off' }
    return '(' + $Value + ') ? MotorMode.' + $On + ' : MotorMode.Off'
}

function Convert-LegacyInitializer {
    param([string] $Type, [System.Collections.Generic.List[object]] $Members, [string] $File)

    # Maps the members of a code-created legacy object like the asset conversion does,
    # and writes the Bullet defaults that differ in Jolt. Edits $Members in place.
    $added = New-Object 'System.Collections.Generic.List[string]'
    $removed = New-Object 'System.Collections.Generic.List[string]'
    $notes = New-Object 'System.Collections.Generic.List[string]'
    foreach ($rename in @(Get-MemberRenames $Type)) {
        $member = Get-Member $Members $rename[0]
        if ($null -ne $member) { $member.Name = $rename[1] }
    }

    if ($Type -match '^(?:RigidBody3D|StaticBody3D|CharacterController3D)$') {
        if ($null -ne (Remove-Member $Members 'MaskBits')) { $notes.Add('MaskBits was folded into the generated CollisionMatrix') }
        $rolling = Remove-Member $Members 'RollingFriction'
        if ($null -ne $rolling -and (ConvertFrom-CSharpNumber $rolling.Value) -ne 0) { $removed.Add('RollingFriction') }
        $kind = Remove-Member $Members 'PhysicBodyType'
        if ($null -ne $kind) {
            Set-Member $Members 'IsKinematic' $(if ($kind.Value -match 'Kinematic$') { 'true' } elseif ($kind.Value -match 'Dynamic$') { 'false' } else { '(' + $kind.Value + ') == RigidBodyType3D.Kinematic' })
        }
        $threshold = Remove-Member $Members 'CcdMotionThreshold'
        Remove-Member $Members 'CcdSweptSphereRadius' | Out-Null
        if ($Type -eq 'RigidBody3D' -and $null -ne $threshold -and (ConvertFrom-CSharpNumber $threshold.Value) -ne 0) { Set-Member $Members 'MotionQuality' 'MotionQuality.LinearCast' }
        foreach ($factor in 'Linear/Translation/Rotation', 'Angular/Rotation/Translation') {
            $name, $prefix, $other = $factor.Split('/')
            $member = Remove-Member $Members ($name + 'Factor')
            if ($null -eq $member) { continue }
            $keep = 'DegreesOfFreedom.' + $other + 'X | DegreesOfFreedom.' + $other + 'Y | DegreesOfFreedom.' + $other + 'Z'
            $dof = Get-DegreesOfFreedomExpression $member.Value $prefix
            $existing = Get-Member $Members 'AllowedDegreesOfFreedom'
            if ($null -ne $existing) { $existing.Value = $existing.Value.Replace($keep, '(' + $dof + ')') } else { Set-Member $Members 'AllowedDegreesOfFreedom' ($dof + ' | ' + $keep) }
            $vector = ConvertFrom-CSharpVector $member.Value
            if ($null -eq $vector -or @($vector.Values | Where-Object { $_ -ne 0 -and $_ -ne 1 }).Count -gt 0) { $notes.Add($name + 'Factor became free/locked axes') }
        }
        $override = Remove-Member $Members 'OverrideGravity'
        $gravity = Remove-Member $Members 'Gravity'
        if ($null -ne $gravity -and $Type -eq 'CharacterController3D') {
            if ((ConvertFrom-CSharpNumber $gravity.Value) -eq 0) { Set-Member $Members 'ApplyGravity' 'false' } else { $removed.Add('Gravity') }
        }
        elseif ($null -ne $override -and $override.Value -eq 'true') {
            # Only a zero gravity override has a Jolt form.
            $vector = if ($null -ne $gravity) { ConvertFrom-CSharpVector $gravity.Value }
            if ($null -ne $vector -and $vector.X -eq 0 -and $vector.Y -eq 0 -and $vector.Z -eq 0) { Set-Member $Members 'GravityFactor' '0f' } else { $removed.Add('Gravity') }
        }
        if ($null -ne (Remove-Member $Members 'LocalInertia')) { $removed.Add('LocalInertia') }
    }

    if ($Type -like '*Joint3D') {
        $iterations = Get-Member $Members 'SolverVelocityIterationsOverride'
        if ($null -ne $iterations) {
            $number = ConvertFrom-CSharpNumber $iterations.Value
            $iterations.Value = if ($null -ne $number) { [string][int][Math]::Max(0, $number) } else { '(uint)System.Math.Max(0, ' + $iterations.Value + ')' }
        }
        foreach ($name in 'DebugDrawSize', 'NeedsFeedback', 'LimitSoftness', 'LimitBiasFactor', 'LimitRelaxationFactor', 'AngularOnly', 'FixThresh') { Remove-Member $Members $name | Out-Null }
        if ($Type -ne 'GearJoint3D' -and $null -ne (Remove-Member $Members 'ConnectedAxis')) { $notes.Add('ConnectedAxis is derived from Axis') }
    }

    # Bullet defaults that differ in Jolt; assets carry every value, code-created objects do not.
    $defaults = @{
        RigidBody3D = 'Mass=1f;Friction=0.5f;LinearDamping=0f;AngularDamping=0f'; StaticBody3D = 'Friction=0.5f'; CharacterController3D = 'StepHeight=0.2f'
        CapsuleCollider3D = 'Height=1f'; GearJoint3D = 'Axis=Vector3.UnitY;ConnectedAxis=Vector3.UnitY'; BulletPhysicManager3D = 'Gravity=new Vector3(0f, -9.8f, 0f)'
    }
    foreach ($default in @(if ($defaults.ContainsKey($Type)) { $defaults[$Type].Split(';') })) {
        Set-Member $Members $default.Split('=')[0] $default.Split('=', 2)[1] -Added $added
    }

    switch -regex ($Type) {
        '^CharacterController3D$' {
            foreach ($name in 'JumpSpeed', 'FallSpeed') { if ($null -ne (Remove-Member $Members $name)) { $removed.Add($name) } }
            foreach ($name in 'IsSensor', 'Friction', 'Restitution') { Remove-Member $Members $name | Out-Null }
            $notes.Add('the capsule is now CharacterController.Radius/Height; remove its collider')
        }
        '^ConeCollider3D$' { Set-Member $Members 'TopRadius' '0f' }
        '^MeshCollider3D$' {
            $convex = Remove-Member $Members 'IsConvex'
            $value = if ($null -eq $convex -or $convex.Value -eq 'false') { 'MeshColliderType.TriangleMesh' } elseif ($convex.Value -eq 'true') { 'MeshColliderType.ConvexHull' } else { '(' + $convex.Value + ') ? MeshColliderType.ConvexHull : MeshColliderType.TriangleMesh' }
            Set-Member $Members 'MeshType' $value
            if ($null -eq $convex) { $added.Add('MeshType') }
            if ($value -ne 'MeshColliderType.ConvexHull') { $notes.Add('a TriangleMesh is static-only: use ConvexHull on a dynamic RigidBody') }
            $size = Remove-Member $Members 'Size'
            if ($null -ne $size -and $size.Value -ne 'Vector3.One') { $removed.Add('Size (scale the entity instead)') }
            Remove-Member $Members 'AsyncShapeCreation' | Out-Null
        }
        '^HingeJoint3D$' {
            $axis = Get-Member $Members 'Axis'
            if ($null -eq $axis) {
                Set-Member $Members 'Axis' 'Vector3.UnitX'
                Set-Member $Members 'NormalAxis' 'Vector3.UnitY'
                $added.Add('Axis')
            }
            elseif ($null -eq (Get-Member $Members 'NormalAxis')) {
                $frame = if (ConvertFrom-CSharpVector $axis.Value) { Get-PerpendicularAxes (ConvertFrom-CSharpVector $axis.Value) }
                if ($null -ne $frame) { Set-Member $Members 'NormalAxis' (Format-CSharpVector $frame.P) $axis } else { $notes.Add('set NormalAxis perpendicular to Axis') }
            }
            $useLimit = Remove-Member $Members 'UseAngularLimit'
            if ($null -eq $useLimit -or $useLimit.Value -eq 'false') {
                Remove-Member $Members 'MinAngle' | Out-Null
                Remove-Member $Members 'MaxAngle' | Out-Null
            }
            $motor = Remove-Member $Members 'UseMotor'
            if ($null -ne $motor) { Set-Member $Members 'MotorMode' (Get-MotorModeExpression $motor.Value 'Velocity') }
            $impulse = Remove-Member $Members 'MotorTargetImpulse'
            if ($null -ne $impulse) { Set-Member $Members 'MaxMotorTorque' ('(' + $impulse.Value + ') * 60f'); $notes.Add('MotorTargetImpulse became MaxMotorTorque at 60 Hz') }
        }
        '^SliderJoint3D$' {
            # Bullet's slider was free unless UseLinearLimit was set.
            $useLimit = Remove-Member $Members 'UseLinearLimit'
            if ($null -eq $useLimit -or $useLimit.Value -eq 'false') {
                Remove-Member $Members 'MinDistance' | Out-Null
                Remove-Member $Members 'MaxDistance' | Out-Null
                Set-Member $Members 'MinDistance' '-float.MaxValue'
                Set-Member $Members 'MaxDistance' 'float.MaxValue'
                $added.Add('MinDistance/MaxDistance (unlimited)')
            }
            $motor = Remove-Member $Members 'UseLinearMotor'
            if ($null -ne $motor) { Set-Member $Members 'MotorMode' (Get-MotorModeExpression $motor.Value 'Velocity') }
            foreach ($name in 'UseAngularLimit', 'LowerAngularLimit', 'UpperAngularLimit', 'UseAngularMotor', 'MaxAngularMotorForce', 'TargetAngularMotorVelocity') {
                $member = Remove-Member $Members $name
                if ($null -ne $member -and $member.Value -notmatch '^(?:true|false|0f?|0\.0f?)$') { $removed.Add($name) }
            }
        }
        '^(?:Generic6DofJoint3D|SpringJoint3D)$' {
            $free = @(foreach ($group in 'Linear/Translation', 'Angular/Rotation') {
                $kind, $prefix = $group.Split('/')
                # Bullet applied limits only with the Use*Limit flag, and lower > upper meant a free axis.
                $flag = Remove-Member $Members ('Use' + $kind + 'Limit')
                if ($null -eq $flag -or $flag.Value -eq 'false') { foreach ($axis in 'X', 'Y', 'Z') { $prefix + $axis }; continue }
                $lower = if (Get-Member $Members ($prefix + 'Min')) { ConvertFrom-CSharpVector (Get-Member $Members ($prefix + 'Min')).Value } else { @{ X = 0.0; Y = 0.0; Z = 0.0 } }
                $upper = if (Get-Member $Members ($prefix + 'Max')) { ConvertFrom-CSharpVector (Get-Member $Members ($prefix + 'Max')).Value } else { @{ X = 0.0; Y = 0.0; Z = 0.0 } }
                if ($flag.Value -ne 'true' -or $null -eq $lower -or $null -eq $upper) { $notes.Add('the free axes could not be derived from non-literal limits; review FreeAxes'); continue }
                foreach ($axis in 'X', 'Y', 'Z') { if ($lower[$axis] -gt $upper[$axis]) { $prefix + $axis } }
            })
            Set-Member $Members 'FreeAxes' $(if ($free.Count -eq 0) { 'DegreesOfFreedom.None' } elseif ($free.Count -eq 6) { 'DegreesOfFreedom.All' } else { ($free | ForEach-Object { 'DegreesOfFreedom.' + $_ }) -join ' | ' })
            $axis = Remove-Member $Members 'Axis'
            if ($null -ne $axis -and $axis.Value -notmatch '^Vector3\.(?:UnitX|Right)$') { $notes.Add('SixDOFConstraint limits are world-axis aligned; the custom Axis was dropped') }
            $springs = @($Members | Where-Object { $_.Name -match '^(?:UseSpring|SpringStiffness|SpringDamping|EquilibriumPoint)' })
            foreach ($spring in $springs) { Remove-Member $Members $spring.Name | Out-Null }
            if (@($springs | Where-Object { $_.Name -like 'UseSpring*' -and $_.Value -ne 'false' }).Count -gt 0) { $removed.Add('per-axis springs (use SixDOFConstraint motors)') }
        }
        '^ConeTwistJoint3D$' {
            $axis = Get-Member $Members 'TwistAxis'
            if ($null -eq $axis) { Set-Member $Members 'TwistAxis' 'Vector3.UnitX'; $added.Add('TwistAxis') }
            $frame = if ($null -eq $axis) { Get-PerpendicularAxes @{ X = 1.0; Y = 0.0; Z = 0.0 } } elseif (ConvertFrom-CSharpVector $axis.Value) { Get-PerpendicularAxes (ConvertFrom-CSharpVector $axis.Value) }
            if ($null -ne $frame) { Set-Member $Members 'PlaneAxis' (Format-CSharpVector $frame.Q) (Get-Member $Members 'TwistAxis') } else { $notes.Add('set PlaneAxis perpendicular to TwistAxis') }
            $settings = Remove-Member $Members 'ConeTwistSettings'
            $limits = if ($null -ne $settings) { ConvertFrom-CSharpVector $settings.Value }
            if ($null -ne $limits) {
                # The twist span is +/-; 2 pi (the Bullet default) means free and Jolt caps it at pi.
                $twist = [Math]::Min([Math]::Abs($limits.Z), [Math]::PI)
                Set-Member $Members 'NormalHalfConeAngle' (Format-CSharpFloat ([Math]::Min([Math]::Abs($limits.X), [Math]::PI)))
                Set-Member $Members 'PlaneHalfConeAngle' (Format-CSharpFloat ([Math]::Min([Math]::Abs($limits.Y), [Math]::PI)))
                Set-Member $Members 'TwistMinAngle' (Format-CSharpFloat (-$twist))
                Set-Member $Members 'TwistMaxAngle' (Format-CSharpFloat $twist)
            }
            elseif ($null -ne $settings) {
                foreach ($assignment in Get-ConeTwistAssignments $settings.Value) { Set-Member $Members $assignment[0] $assignment[1] }
            }
            else {
                Set-Member $Members 'TwistMinAngle' '-MathHelper.Pi' -Added $added
                Set-Member $Members 'TwistMaxAngle' 'MathHelper.Pi' -Added $added
            }
            $motor = Remove-Member $Members 'UseMotor'
            if ($null -ne $motor) {
                Set-Member $Members 'SwingMotorMode' (Get-MotorModeExpression $motor.Value 'Position')
                Set-Member $Members 'TwistMotorMode' (Get-MotorModeExpression $motor.Value 'Position')
            }
            $impulse = Remove-Member $Members 'MaxMotorImpulse'
            if ($null -ne $impulse) {
                Set-Member $Members 'MaxSwingTorque' ('(' + $impulse.Value + ') * 60f')
                Set-Member $Members 'MaxTwistTorque' ('(' + $impulse.Value + ') * 60f')
                $notes.Add('MaxMotorImpulse became swing/twist torques at 60 Hz')
            }
            $rotation = Remove-Member $Members 'MotorTargetRotation'
            if ($null -ne $rotation) { Set-Member $Members 'TargetOrientation' (Get-YawPitchRollExpression $rotation.Value) }
            if ($null -ne (Remove-Member $Members 'Damping')) { $removed.Add('Damping (use MaxFrictionTorque)') }
        }
        '^BulletPhysicManager3D$' {
            if ($null -ne (Remove-Member $Members 'PhysicWorldResolution')) { $removed.Add('PhysicWorldResolution') }
            foreach ($name in 'DrawFlags', 'ApplySpeculativeContactRestitution') { Remove-Member $Members $name | Out-Null }
            if ($null -eq (Get-Member $Members 'CollisionMatrix')) {
                Set-Member $Members 'CollisionMatrix' (Format-CollisionMatrixSource)
                $script:CollisionMatrixTargets++
                Add-Finding 'Info' 'collision-matrix-generated' $File 0 $script:ProjectCollisionMatrix.Summary
            }
        }
    }

    if ($Type -like '*Joint3D') {
        $breakPoint = Remove-Member $Members 'BreakPoint'
        $number = if ($null -ne $breakPoint) { ConvertFrom-CSharpNumber $breakPoint.Value }
        if ($null -ne $number -and ($number -le 0.000001 -or $number -ge 1.0e20)) {
            Set-Member $Members 'IsBreakable' 'false'
        }
        elseif ($null -ne $breakPoint) {
            Set-Member $Members 'IsBreakable' 'true'
            Set-Member $Members 'BreakForce' ('(' + $breakPoint.Value + ') * 60f')
            Set-Member $Members 'BreakTorque' ('(' + $breakPoint.Value + ') * 60f')
            $notes.Add('BreakPoint (impulse) became BreakForce/BreakTorque at 60 Hz')
        }
    }

    if ($Type -match 'Collider3D$') {
        # Primitives were relative to the model bounds; Margin maps to ConvexRadius where it exists.
        $orientation = Get-Member $Members 'OrientationOffset'
        if ($null -ne $orientation) { $orientation.Name = 'RotationOffset'; $orientation.Value = 'Quaternion.ToEuler(' + $orientation.Value + ')' }
        $margin = Remove-Member $Members 'Margin'
        if ($null -ne $margin -and $Type -match '^(?:Box|Cylinder|Cone|Mesh)') { Set-Member $Members 'ConvexRadius' $margin.Value }
        if ($Type -ne 'MeshCollider3D' -and $null -eq (Get-Member $Members 'UseModelBounds')) { $Members.Insert(0, [pscustomobject]@{ Name = 'UseModelBounds'; Value = 'true'; Raw = $null; Comments = @() }) }
    }

    return [pscustomobject]@{ Added = $added; Removed = $removed; Notes = $notes }
}

function Get-ConeTwistAssignments {
    param([string] $Value)

    # ConeTwistSettings = (swing span 1, swing span 2, twist span) for a non-literal vector.
    $value = '(' + $Value + ')'
    return @(@('NormalHalfConeAngle', ($value + '.X')), @('PlaneHalfConeAngle', ($value + '.Y')),
        @('TwistMinAngle', ('-System.Math.Min(' + $value + '.Z, MathHelper.Pi)')), @('TwistMaxAngle', ('System.Math.Min(' + $value + '.Z, MathHelper.Pi)')))
}

function Get-YawPitchRollExpression {
    param([string] $Value)

    # Bullet's Euler vectors were (pitch, yaw, roll).
    $vector = ConvertFrom-CSharpVector $Value
    if ($null -ne $vector) { return 'Quaternion.CreateFromYawPitchRoll(' + (Format-CSharpFloat $vector.Y) + ', ' + (Format-CSharpFloat $vector.X) + ', ' + (Format-CSharpFloat $vector.Z) + ')' }
    return 'Quaternion.CreateFromYawPitchRoll((' + $Value + ').Y, (' + $Value + ').X, (' + $Value + ').Z)'
}

function Convert-LegacyObjectCreations {
    param([string] $Text, [string] $File)

    $pattern = '\bnew\s+(?:global::)?(?:Evergine\.Framework\.Physics3D\.|Evergine\.Bullet\.)?(?<type>(?:RigidBody|StaticBody|CharacterController|Box|Sphere|Capsule|Cylinder|Cone|Mesh)(?:Collider)?3D|(?:Hinge|Slider|Generic6Dof|Spring|ConeTwist|Gear|PointToPoint|Fixed)Joint3D|BulletPhysicManager3D)\b(?!\s*\[)(?:(?<arguments>\s*(?=\()' + $script:Balanced + '))?(?:(?<gap>\s*)(?<initializer>(?=\{)' + $script:Balanced + '))?'
    $creations = @([regex]::Matches($Text, $pattern))
    $newLine = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $defaultsOnly = New-Object 'System.Collections.Generic.List[string]'
    [array]::Reverse($creations)
    foreach ($match in $creations) {
        $type = $match.Groups['type'].Value
        $initializer = if ($match.Groups['initializer'].Success) { $match.Groups['initializer'].Value }
        $members = if ($null -ne $initializer) { Get-InitializerMembers $initializer.Substring(1, $initializer.Length - 2) } else { New-Object 'System.Collections.Generic.List[object]' }
        $result = Convert-LegacyInitializer $type $members $File
        $newType = switch ($type) { 'BulletPhysicManager3D' { 'global::Evergine.Framework.Physics.PhysicsManager' } 'SpringJoint3D' { 'SixDOFConstraint' } default { $script:SourceTypeMappings[$type] } }
        $replacement = 'new ' + $newType + $(if ($match.Groups['arguments'].Success) { $match.Groups['arguments'].Value.TrimStart() } else { '()' })
        if ($members.Count -gt 0 -or $null -ne $initializer) {
            $lineIndent = [regex]::Match($Text.Substring($Text.LastIndexOf("`n", [Math]::Max(0, $match.Index - 1)) + 1), '^[ \t]*').Value
            $replacement += $(if ($null -ne $initializer) { $match.Groups['gap'].Value } else { ' ' }) + (Format-Initializer $members ([string]$initializer) $lineIndent $newLine)
        }

        $Text = $Text.Substring(0, $match.Index) + $replacement + $Text.Substring($match.Index + $match.Length)
        $parts = @($result.Notes)
        if ($result.Removed.Count -gt 0) { $parts = @('no Jolt equivalent, removed: ' + ($result.Removed -join ', ')) + $parts }
        if ($result.Added.Count -gt 0) { $parts = @('Bullet defaults made explicit: ' + ($result.Added -join ', ')) + $parts }
        if ($result.Removed.Count -gt 0 -or $result.Notes.Count -gt 0) {
            Add-Finding $(if ($result.Removed.Count -gt 0) { 'Warning' } else { 'Info' }) 'source-object-migrated' $File (1 + ([regex]::Matches($Text.Substring(0, $match.Index), "`n")).Count) ('new ' + $type + ': ' + ($parts -join '; ') + '.')
        }
        elseif ($result.Added.Count -gt 0) {
            $defaultsOnly.Add($type)
        }
    }

    if ($defaultsOnly.Count -gt 0) {
        Add-Finding 'Info' 'source-bullet-defaults' $File 0 ('Code-created ' + (($defaultsOnly | Select-Object -Unique) -join ', ') + ' now set the Bullet defaults that differ in Jolt explicitly.')
    }

    return $Text
}

function Get-LegacyTypedVariables {
    param([string] $Text)

    # Names declared with a legacy type (fields, locals, parameters, var = new T / FindComponent<T>), by type.
    $types = '(?:Evergine\.Framework\.Physics3D\.|Evergine\.Bullet\.)?(?<type>RigidBody3D|StaticBody3D|PhysicBody3D|CharacterController3D|I?(?:Cone|Mesh)Collider(?:Shape)?3D|(?:Hinge|Slider|Generic6Dof|Generic6DofSpring|Spring|ConeTwist|Gear|PointToPoint|Fixed)Joint3D|PhysicWheel3D|PhysicVehicle3D|CollisionInfo3D|(?:Bullet)?PhysicManager3D)'
    $variables = @{}
    foreach ($declaration in [regex]::Matches($Text, '\b' + $types + '\??\s+(?<name>[A-Za-z_]\w*)\s*(?=[=;,){]|\bin\b)|\bvar\s+(?<name>[A-Za-z_]\w*)\s*=\s*(?:new\s+|[^;]*?\b(?:FindComponent|GetComponent|FindComponentInChildren|FindComponentInParents)\s*<\s*)' + $types + '\b')) {
        $type = $declaration.Groups['type'].Value -replace '^I(\w+)ColliderShape3D$', '$1Collider3D' -replace '^Generic6DofSpringJoint3D$', 'Generic6DofJoint3D' -replace '^BulletPhysicManager3D$', 'PhysicManager3D'
        if (-not $variables.ContainsKey($type)) { $variables[$type] = New-Object 'System.Collections.Generic.HashSet[string]' }
        [void]$variables[$type].Add($declaration.Groups['name'].Value)
    }

    return $variables
}

function Get-ReceiverPattern {
    param([hashtable] $Variables, [string] $Types)

    $names = @($Variables.Keys | Where-Object { $_ -match ('^(?:' + $Types + ')$') } | ForEach-Object { $Variables[$_] } | Select-Object -Unique)
    if ($names.Count -gt 0) { return '(?<receiver>(?<![\w.])(?:this\.)?(?:' + (@($names | ForEach-Object { [regex]::Escape($_) }) -join '|') + '))' }
}

function Convert-LegacyMemberUsage {
    param([string] $Text, [string] $File, [hashtable] $Variables)

    # Assignments that need a different statement; the build block gets receiver and value.
    $statements = @(
        @('HingeJoint3D', 'UseMotor', { param($r, $v) $r + '.MotorMode = ' + (Get-MotorModeExpression $v 'Velocity') + ';' }),
        @('HingeJoint3D', 'MotorTargetImpulse', { param($r, $v) $r + '.MaxMotorTorque = (' + $v + ') * 60f;' }),
        @('SliderJoint3D', 'UseLinearMotor', { param($r, $v) $r + '.MotorMode = ' + (Get-MotorModeExpression $v 'Velocity') + ';' }),
        @('ConeTwistJoint3D', 'UseMotor', { param($r, $v) $r + '.SwingMotorMode = ' + (Get-MotorModeExpression $v 'Position') + '; ' + $r + '.TwistMotorMode = ' + (Get-MotorModeExpression $v 'Position') + ';' }),
        @('ConeTwistJoint3D', 'MaxMotorImpulse', { param($r, $v) $r + '.MaxSwingTorque = (' + $v + ') * 60f; ' + $r + '.MaxTwistTorque = (' + $v + ') * 60f;' }),
        @('ConeTwistJoint3D', 'MotorTargetRotation', { param($r, $v) $r + '.TargetOrientation = ' + (Get-YawPitchRollExpression $v) + ';' }),
        @('ConeTwistJoint3D', 'ConeTwistSettings', { param($r, $v) (@(Get-ConeTwistAssignments $v | ForEach-Object { $r + '.' + $_[0] + ' = ' + $_[1] + ';' })) -join ' ' }),
        @('\w+Joint3D', 'BreakPoint', { param($r, $v) $r + '.BreakForce = (' + $v + ') * 60f; ' + $r + '.BreakTorque = (' + $v + ') * 60f; ' + $r + '.IsBreakable = (' + $v + ') > 0f;' }),
        @('MeshCollider3D', 'IsConvex', { param($r, $v) $r + '.MeshType = ' + $(if ($v -eq 'true') { 'MeshColliderType.ConvexHull' } elseif ($v -eq 'false') { 'MeshColliderType.TriangleMesh' } else { '(' + $v + ') ? MeshColliderType.ConvexHull : MeshColliderType.TriangleMesh' }) + ';' })
    )
    foreach ($statement in $statements) {
        $receiver = Get-ReceiverPattern $Variables $statement[0]
        $build = $statement[2]
        if ($null -ne $receiver) {
            $Text = [regex]::Replace($Text, '(?m)' + $receiver + '\.' + $statement[1] + '\s*=(?!=)\s*(?<value>[^;\r\n]+?)\s*;', { param($m) & $build $m.Groups['receiver'].Value $m.Groups['value'].Value.Trim() })
        }
    }

    $character = Get-ReceiverPattern $Variables 'CharacterController3D'
    if ($null -ne $character) {
        $before = $Text
        $Text = [regex]::Replace($Text, '(?m)' + $character + '\.SetVelocity\s*\(\s*(?<value>[^;\r\n]+?)\s*\)\s*;', '${receiver}.LinearVelocity = ${value};')
        $Text = [regex]::Replace($Text, '(?m)' + $character + '\.Jump\s*\(\s*(?<value>[^;\r\n]+?)\s*\)\s*;', '${receiver}.Jump((${value}).Length());')
        # Jump() used JumpSpeed (Bullet default 10): use the single literal this file assigns to the receiver.
        $Text = [regex]::Replace($Text, $character + '\.Jump\s*\(\s*\)', {
            param($m)
            $receiver = [regex]::Escape(($m.Groups['receiver'].Value -replace '^this\.', ''))
            $speeds = @([regex]::Matches($Text, '(?<![\w.])(?:this\.)?' + $receiver + '\.JumpSpeed\s*=\s*([-+]?(?:\d+\.?\d*|\.\d+)[fF]?)\s*;') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
            return $m.Groups['receiver'].Value + '.Jump(' + $(if ($speeds.Count -eq 1) { $speeds[0] } else { '10f' }) + ')'
        })
        $Text = [regex]::Replace($Text, '(?m)' + $character + '\.Rotate\s*\(\s*(?<value>[^;\r\n]+?)\s*\)\s*;', '${receiver}.Transform3D.Orientation = Quaternion.Concatenate(${receiver}.Transform3D.Orientation, Quaternion.CreateFromAxisAngle(Vector3.Up, -(${value})));')
        if ($Text -ne $before) {
            Add-Finding 'Info' 'source-character-migrated' $File 0 'CharacterController calls were mapped: SetVelocity -> LinearVelocity, Jump() -> Jump(JumpSpeed), Jump(direction) -> Jump(direction.Length()), Rotate -> entity orientation.'
        }
    }

    # Renames shared with the asset conversion, plus WheelRadius (an asset computes Radius instead).
    foreach ($type in @($Variables.Keys)) {
        $receiver = Get-ReceiverPattern $Variables $type
        $renames = @(Get-MemberRenames $type)
        if ($type -eq 'PhysicWheel3D') { $renames += , @('WheelRadius', 'Radius') }
        foreach ($rename in $renames) {
            $Text = [regex]::Replace($Text, $receiver + '\.' + $rename[0] + '\b', '${receiver}.' + $rename[1])
        }
    }

    # Lambdas have no declared CollisionInfo3D type; these members only exist on collision info.
    if ($Text -match '\bCollisionInfo3D\b|\.(?:Begin|Update|End)Collision\b') {
        $Text = $Text -replace '\.ThisBody\b', '.ThisCollider.Body' -replace '\.NumContacts\b', '.PointCount'
    }
    $collisionInfo = Get-ReceiverPattern $Variables 'CollisionInfo3D'
    if ($null -ne $collisionInfo -and $Text -match ($collisionInfo + '\.(?:State|GetContacts?)\b')) {
        Add-Finding 'Warning' 'source-collision-info-contacts' $File 0 'CollisionInfo.State/GetContact(s) have no Jolt equivalent: the event gives the state, and CollisionInfo carries one aggregated contact (Point, Normal, PenetrationDepth, PointCount).'
    }

    # Assignments to members that no longer exist are commented out so the port compiles.
    $commented = New-Object 'System.Collections.Generic.List[string]'
    $dead = @{
        'HingeJoint3D' = 'UseAngularLimit|ConnectedAxis'
        'SliderJoint3D' = 'UseLinearLimit|UseAngularLimit|LowerAngularLimit|UpperAngularLimit|UseAngularMotor|MaxAngularMotorForce|TargetAngularMotorVelocity|ConnectedAxis'
        'Generic6DofJoint3D|SpringJoint3D' = 'UseLinearLimit|UseAngularLimit|UseSpring\w+|SpringStiffness\w+|SpringDamping\w+|EquilibriumPoint\w+|Axis|ConnectedAxis'
        'ConeTwistJoint3D' = 'Damping|ConnectedAxis'
        '\w+Joint3D' = 'DebugDrawSize|NeedsFeedback|LimitSoftness|LimitBiasFactor|LimitRelaxationFactor|AngularOnly|FixThresh'
        'CharacterController3D' = 'JumpSpeed|FallSpeed|Gravity'
        'RigidBody3D|StaticBody3D|PhysicBody3D|CharacterController3D' = 'RollingFriction|MaskBits|LocalInertia|CcdMotionThreshold|CcdSweptSphereRadius|OverrideGravity'
        'PhysicWheel3D' = 'IsFrontWheel|IsDriveWheel|IsSteerableWheel|IsBrakableWheel|OverrideVehicleSettings|SearchVehicle|PhysicVehicleEntityPath'
        'MeshCollider3D' = 'Size|AsyncShapeCreation'
        'PhysicManager3D' = 'PhysicWorldResolution|DrawFlags|ApplySpeculativeContactRestitution'
    }
    foreach ($types in $dead.Keys) {
        $receiver = Get-ReceiverPattern $Variables $types
        if ($null -eq $receiver) { continue }
        $Text = [regex]::Replace($Text, '(?m)^(?<indent>[ \t]*)(?<statement>' + $receiver + '\.(?<member>' + $dead[$types] + ')\s*(?:[-+*/]?=(?!=))[^;\r\n]*;)', {
            param($m)
            $commented.Add($m.Groups['member'].Value)
            return $m.Groups['indent'].Value + '// Bullet -> Jolt: ' + $m.Groups['member'].Value + ' has no Jolt equivalent. ' + $m.Groups['statement'].Value
        })
    }

    if ($commented.Count -gt 0) {
        Add-Finding 'Warning' 'source-member-removed' $File 0 ('Assignments to ' + (($commented | Select-Object -Unique) -join ', ') + ' were commented out because these Bullet members have no Jolt equivalent.')
    }

    return $Text
}

function Convert-SourceCalls {
    param([string] $Text, [string] $File, [System.Collections.Generic.HashSet[string]] $HitNames)

    # ResetTransform(position, orientation, scale) -> Teleport(position, orientation);
    # RayCastAll(ref from, ref to | ref ray, distance, results[, mask]) -> RayCastAll(origin, direction, distance, results, filter);
    # var hit = manager.ConvexSweepTest(shape, ref from, ref to[, mask]); -> bool hitSucceeded = manager.ShapeCast(..., out ShapeCastHit hit);
    $kinds = New-Object 'System.Collections.Generic.HashSet[string]'
    $calls = @([regex]::Matches($Text, '(?m)\.(?<null>\?)?(?<method>ResetTransform|RayCastAll)\s*\(|^(?<indent>[ \t]*)(?:var|HitResult3D|RayCastHit)\s+(?<hit>\w+)\s*=\s*(?<manager>[^;\r\n=]+?)\.(?<method>ConvexSweepTest)\s*\('))
    [array]::Reverse($calls)
    foreach ($call in $calls) {
        $list = Get-Balanced $Text ($call.Index + $call.Length - 1)
        if ($null -eq $list) { continue }
        $arguments = @(Split-CSharpTopLevel $list.Substring(1, $list.Length - 2) | ForEach-Object { $_.Trim() })
        $end = $call.Index + $call.Length - 1 + $list.Length
        $method = $call.Groups['method'].Value
        $mask = if ($arguments.Count -ge 4) { $arguments[3] } else { 'CollisionCategory.All' }
        $filter = 'new QueryFilter { CategoryMask = ' + $mask + ', IncludeSensors = true }'
        if ($method -ne 'ResetTransform' -and $mask -match '\.None$') { [void]$kinds.Add('none') }
        if ($method -eq 'ResetTransform' -and $arguments.Count -eq 3) {
            if ($arguments[2] -notmatch '^(?:Vector3\.One|new\s+Vector3\s*\(\s*1(?:\.0*)?f?\s*\)|(?:[\w.]+\.)?Transform3D\.(?:Local)?Scale)$') { [void]$kinds.Add('scale') }
            $replacement = '.' + $call.Groups['null'].Value + 'Teleport(' + $arguments[0] + ', ' + $arguments[1] + ')'
        }
        elseif ($method -eq 'RayCastAll' -and $arguments.Count -ge 3 -and $arguments[0] -match '^ref\s+(?<first>.+)$') {
            $first = $Matches['first']
            $replacement = if ($arguments[1] -match '^ref\s+(?<second>.+)$') {
                '.RayCastAll(' + $first + ', ' + $Matches['second'] + ' - ' + $first + ', Vector3.Distance(' + $first + ', ' + $Matches['second'] + '), ' + $arguments[2] + ', ' + $filter + ')'
            }
            else {
                '.RayCastAll(' + $first + '.Position, ' + $first + '.Direction, ' + $arguments[1] + ', ' + $arguments[2] + ', ' + $filter + ')'
            }
            [void]$kinds.Add('query')
        }
        elseif ($method -eq 'ConvexSweepTest' -and $arguments.Count -ge 3 -and $arguments[1] -match '^ref\s+(?<from>.+)$' -and $arguments[2] -match '^ref\s+(?<to>.+)$' -and $Text.Substring($end) -match '^\s*;') {
            $from = $arguments[1] -replace '^ref\s+', ''
            $to = $arguments[2] -replace '^ref\s+', ''
            $hit = $call.Groups['hit'].Value
            [void]$HitNames.Add($hit)
            $end += $Matches[0].Length
            $replacement = $call.Groups['indent'].Value + 'bool ' + $hit + 'Succeeded = ' + $call.Groups['manager'].Value + '.ShapeCast(' + $arguments[0] + ', ' + $from + '.Translation, ' + $from + '.Orientation, ' + $to + '.Translation - ' + $from + '.Translation, Vector3.Distance(' + $from + '.Translation, ' + $to + '.Translation), ' + $filter + ', out ShapeCastHit ' + $hit + ');'
            [void]$kinds.Add('query')
        }
        else {
            continue
        }

        $Text = $Text.Substring(0, $call.Index) + $replacement + $Text.Substring($end)
    }

    if ($kinds.Contains('scale')) {
        Add-Finding 'Warning' 'source-reset-transform-scale' $File 0 'ResetTransform(position, orientation, scale) became Teleport(position, orientation); set Transform3D.Scale if the call changed it.'
    }
    if ($kinds.Contains('query')) {
        Add-Finding 'Info' 'source-query-all-migrated' $File 0 'RayCastAll/ConvexSweepTest calls became RayCastAll/ShapeCast with a QueryFilter (RayCastAll now appends to the list; ShapeCast takes a Collider).'
    }
    if ($kinds.Contains('none') -or $Text -match 'CategoryMask\s*=\s*CollisionCategory(?:3D)?\.None\b') {
        Add-Finding 'Warning' 'query-mask-none' $File 0 'A query uses the None category mask, which hit nothing in Bullet but means every category in a Jolt QueryFilter.'
    }

    return $Text
}

function Add-UsingIfMissing {
    param([string] $Text, [string] $Namespace)

    $usings = @([regex]::Matches($Text, '(?m)^[ \t]*using\s+[\w.]+\s*;[ \t]*\r?\n'))
    if ($usings.Count -eq 0 -or $Text -match ('(?m)^\s*using\s+' + [regex]::Escape($Namespace) + '\s*;')) {
        return $Text
    }

    $last = $usings[$usings.Count - 1]
    return $Text.Insert($last.Index + $last.Length, ($last.Value -replace '[\w.]+(?=\s*;)', $Namespace))
}

function Convert-SourceContent {
    param(
        [string] $Text,
        [string] $File
    )

    $result = $Text
    $before = $result

    # Both need the legacy type names, so they run before any rename.
    $typedVariables = Get-LegacyTypedVariables $result
    $result = Convert-LegacyObjectCreations $result $File

    # Handle fully-qualified manager construction before the short-name pass. The
    # old pass could otherwise leave an invalid hybrid such as
    # global::Evergine.Bullet.PhysicsManager in partially migrated projects.
    $result = [regex]::Replace(
        $result,
        '(?:global::)?Evergine\.Bullet\.(?:BulletPhysicManager3D|PhysicsManager)\b',
        'global::Evergine.Framework.Physics.PhysicsManager')

    $result = $result -replace 'using\s+Evergine\.Framework\.Physics3D\s*;', 'using Evergine.Framework.Physics;'
    $result = $result -replace 'using\s+Evergine\.Bullet\s*;\s*\r?\n', ''
    $result = $result -replace 'Evergine\.Framework\.Physics3D\.', 'Evergine.Framework.Physics.'

    $bodyTypeComparisonPatterns = [ordered]@{
        '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\s*==\s*RigidBodyType3D\.Dynamic\b' = '!${receiver}.IsKinematic'
        '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\s*!=\s*RigidBodyType3D\.Dynamic\b' = '${receiver}.IsKinematic'
        '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\s*==\s*RigidBodyType3D\.Kinematic\b' = '${receiver}.IsKinematic'
        '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\s*!=\s*RigidBodyType3D\.Kinematic\b' = '!${receiver}.IsKinematic'
        'RigidBodyType3D\.Dynamic\s*==\s*(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\b' = '!${receiver}.IsKinematic'
        'RigidBodyType3D\.Dynamic\s*!=\s*(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\b' = '${receiver}.IsKinematic'
        'RigidBodyType3D\.Kinematic\s*==\s*(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\b' = '${receiver}.IsKinematic'
        'RigidBodyType3D\.Kinematic\s*!=\s*(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.PhysicBodyType\b' = '!${receiver}.IsKinematic'
    }
    $bodyTypeComparisons = 0
    foreach ($pattern in $bodyTypeComparisonPatterns.Keys) {
        $matches = [regex]::Matches($result, $pattern)
        if ($matches.Count -gt 0) {
            $bodyTypeComparisons += $matches.Count
            $result = [regex]::Replace($result, $pattern, $bodyTypeComparisonPatterns[$pattern])
        }
    }
    if ($bodyTypeComparisons -gt 0) {
        Add-Finding 'Info' 'source-body-type-comparison-migrated' $File 0 ($bodyTypeComparisons.ToString($script:Invariant) + ' PhysicBodyType comparison(s) became IsKinematic checks.')
    }

    $result = [regex]::Replace($result, '\bPhysicBodyType\s*=\s*RigidBodyType3D\.Kinematic\b', 'IsKinematic = true')
    $result = [regex]::Replace($result, '\bPhysicBodyType\s*=\s*RigidBodyType3D\.Dynamic\b', 'IsKinematic = false')
    $result = [regex]::Replace($result, '\.PhysicBodyType\s*=\s*RigidBodyType3D\.Kinematic\b', '.IsKinematic = true')
    $result = [regex]::Replace($result, '\.PhysicBodyType\s*=\s*RigidBodyType3D\.Dynamic\b', '.IsKinematic = false')

    # Bullet exposed disposable, manager-created shape interfaces. Jolt exposes collider
    # components directly. Handle the common source forms before renaming the interfaces.
    $result = [regex]::Replace(
        $result,
        '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.InternalColliderShape\s+as\s+I(?:Box|Sphere|Capsule|Cylinder|Cone|Mesh)ColliderShape3D\b',
        '${receiver}')
    $result = [regex]::Replace(
        $result,
        '(?:this\.)?Managers\.(?:PhysicManager3D|PhysicsManager)\.CreateColliderShape<I(?<shape>Box|Sphere|Capsule|Cylinder|Mesh)ColliderShape3D>\s*\(\s*\)',
        'new ${shape}Collider()')
    $result = [regex]::Replace(
        $result,
        '(?:this\.)?Managers\.(?:PhysicManager3D|PhysicsManager)\.CreateColliderShape<IConeColliderShape3D>\s*\(\s*\)',
        'new TaperedCylinderCollider() { TopRadius = 0f }')

    # Members of variables whose legacy type is known (joints, characters,
    # wheels, collision info...) before the type names change.
    $result = Convert-LegacyMemberUsage $result $File $typedVariables

    foreach ($oldName in $script:SourceTypeMappings.Keys) {
        $result = [regex]::Replace($result, '\b' + [regex]::Escape($oldName) + '\b', $script:SourceTypeMappings[$oldName])
    }

    # Bullet accepted independent absolute force, steering-angle and brake calls.
    # Jolt receives one normalized driver-input tuple. Convert the common adjacent
    # triplet so the port compiles, clamp the legacy values, and flag the semantic
    # retuning that is still required.
    $vehicleInputPattern = '(?m)^(?<indent>[ \t]*)(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.ApplyEngineForce\s*\(\s*(?<forward>[^,;\r\n]+?)\s*\);\s*\r?\n[ \t]*\k<receiver>\.SetSteeringValue\s*\(\s*(?<right>[^,;\r\n]+?)\s*\);\s*\r?\n[ \t]*\k<receiver>\.SetBrake\s*\(\s*(?<brake>[^,;\r\n]+?)\s*\);'
    if ($result -match '\bWheeledVehicleController\b' -and $result -match $vehicleInputPattern) {
        $result = [regex]::Replace(
            $result,
            $vehicleInputPattern,
            '${indent}${receiver}.SetDriverInput(global::System.Math.Clamp((float)(${forward}), -1f, 1f), global::System.Math.Clamp((float)(${right}) / 0.5235988f, -1f, 1f), global::System.Math.Clamp((float)(${brake}), 0f, 1f), 0f);')
        Add-Finding 'Warning' 'source-vehicle-input-migrated' $File 0 'Adjacent Bullet vehicle force/steering/brake calls became one normalized Jolt SetDriverInput call. Steering radians were normalized to the VehiclesSample 30-degree maximum; retune the legacy force and brake scales.'
    }

    # Older serializers used -1 as the inherited solver-iteration sentinel. Jolt
    # uses uint and reserves zero for the same inherit/default behavior.
    $sourceSolverOverridePattern = '\b(?<name>Solver(?:Velocity|Position)IterationsOverride)\s*=\s*-\d+\b'
    if ($result -match $sourceSolverOverridePattern) {
        $result = [regex]::Replace($result, $sourceSolverOverridePattern, '${name} = 0')
        Add-Finding 'Info' 'source-solver-override-normalized' $File 0 'A negative legacy solver-iteration override was changed to Jolt zero (inherit the manager setting).'
    }

    $memberMappings = [ordered]@{
        'CollisionCategories' = 'CollisionCategory'
        'ColliderList' = 'Colliders'
        'BeginCollision' = 'CollisionStarted'
        'UpdateCollision' = 'CollisionUpdated'
        'EndCollision' = 'CollisionEnded'
        'PerformPhysicSteps' = 'IsSimulationEnabled'
        'MaxSubSteps' = 'MaxStepsPerFrame'
        'ApplyForceAtPosition' = 'ApplyForce'
        'ApplyImpulseAtPosition' = 'ApplyImpulse'
        'ApplyTorqueImpulse' = 'ApplyAngularImpulse'
        'EffectiveOffset' = 'Offset'
    }
    foreach ($oldName in $memberMappings.Keys) {
        $result = [regex]::Replace($result, '\.' + [regex]::Escape($oldName) + '\b', '.' + $memberMappings[$oldName])
    }

    # OnPhysicStep was an EventHandler raised once per frame after the step, like SimulationUpdated.
    # Only the event access is renamed, not the user's handler.
    if ($result -match '\.OnPhysicStep(?=\s*[-+]=)') {
        $result = [regex]::Replace($result, '\.OnPhysicStep(?=\s*[-+]=)', '.SimulationUpdated')
        Add-Finding 'Info' 'source-physic-step-migrated' $File 0 'OnPhysicStep became PhysicsManager.SimulationUpdated (same signature and timing); apply forces in PhysicsStepStarting (EventHandler<float>, per fixed step).'
    }

    # CollisionCategories also occurs as a bare object-initializer member.
    $result = [regex]::Replace($result, '\bCollisionCategories\b', 'CollisionCategory')

    # A per-body MaskBits value no longer exists. Initializer assignments are removed;
    # standalone reads default to all categories and are reported for semantic review.
    $maskInitializerPattern = '(?m)^[ \t]*MaskBits\s*=\s*(?<value>[^\r\n,]*),\s*\r?\n'
    if ($result -match $maskInitializerPattern) {
        foreach ($maskMatch in [regex]::Matches($result, $maskInitializerPattern)) {
            $maskValue = $maskMatch.Groups['value'].Value.Trim()
            Add-Finding 'Warning' 'source-mask-removed' $File 0 ('MaskBits has no per-body Jolt equivalent. The initializer was removed; reproduce the old mask "' + $maskValue + '" with PhysicsManager.SetCollisionEnabled/CollisionMatrix. A ray or moving sensor should also exclude its own category explicitly.')
        }
        $result = [regex]::Replace($result, $maskInitializerPattern, '')
    }
    $maskAssignmentPattern = '(?m)^(?<indent>[ \t]*)(?<left>(?:(?:var|CollisionCategory3D|CollisionCategory)\s+)?(?:this\.)?[A-Za-z_]\w*)\s*=\s*[^;\r\n]+\.MaskBits\s*;'
    if ($result -match $maskAssignmentPattern) {
        $result = [regex]::Replace($result, $maskAssignmentPattern, '${indent}${left} = CollisionCategory.All;')
        Add-Finding 'Warning' 'source-mask-defaulted' $File 0 'A read of removed MaskBits was replaced with CollisionCategory.All. Restore the intended mask explicitly; for cursor rays, exclude the cursor category or the ray can hit its own sensor.'
    }

    # Collider orientation is authored as Euler radians in Jolt rather than as a quaternion;
    # Quaternion.ToEuler inverts CreateFromYawPitchRoll(Y, X, Z). Assignments first.
    $result = [regex]::Replace($result, '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.OrientationOffset\s*=(?!=)\s*(?<value>[^;\r\n]+?)\s*;', '${receiver}.RotationOffset = Quaternion.ToEuler(${value});')
    $orientationPattern = '(?<receiver>(?:this\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.OrientationOffset\b'
    $result = [regex]::Replace(
        $result,
        $orientationPattern,
        'Quaternion.CreateFromYawPitchRoll(${receiver}.RotationOffset.Y, ${receiver}.RotationOffset.X, ${receiver}.RotationOffset.Z)')

    # This Bullet broad-world tuning knob has no Jolt counterpart.
    $worldResolutionPattern = '(?m)^[ \t]*PhysicWorldResolution\s*=\s*[^\r\n]*,\s*\r?\n'
    if ($result -match $worldResolutionPattern) {
        $result = [regex]::Replace($result, $worldResolutionPattern, '')
        Add-Finding 'Info' 'source-property-removed' $File 0 'PhysicWorldResolution has no Jolt counterpart and was removed.'
    }

    # Convert the common Bullet RayCast assignment forms. Jolt returns success as a
    # bool and writes the hit through an out parameter.
    $rayResultNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $endpointRayPattern = '(?m)^(?<indent>[ \t]*)(?:var|HitResult3D|RayCastHit)\s+(?<hit>[A-Za-z_]\w*)\s*=\s*(?<manager>[^;\r\n]+?)\.RayCast\(\s*ref\s+(?<from>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*,\s*ref\s+(?<to>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*(?:,\s*(?<mask>[^\)\r\n]+))?\s*\)\s*;'
    $result = [regex]::Replace($result, $endpointRayPattern, {
        param($match)
        $hit = $match.Groups['hit'].Value
        [void]$rayResultNames.Add($hit)
        $indent = $match.Groups['indent'].Value
        $manager = $match.Groups['manager'].Value
        $from = $match.Groups['from'].Value
        $to = $match.Groups['to'].Value
        $mask = if ($match.Groups['mask'].Success) { $match.Groups['mask'].Value.Trim() } else { 'CollisionCategory.All' }
        return "${indent}bool ${hit}Succeeded = ${manager}.RayCast(${from}, ${to} - ${from}, Vector3.Distance(${from}, ${to}), new QueryFilter { CategoryMask = ${mask}, IncludeSensors = true }, out RayCastHit ${hit});"
    })

    $rayPattern = '(?m)^(?<indent>[ \t]*)(?:var|HitResult3D|RayCastHit)\s+(?<hit>[A-Za-z_]\w*)\s*=\s*(?<manager>[^;\r\n]+?)\.RayCast\(\s*ref\s+(?<ray>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*,\s*(?<distance>[^,\)\r\n]+?)\s*(?:,\s*(?<mask>[^\)\r\n]+))?\s*\)\s*;'
    $result = [regex]::Replace($result, $rayPattern, {
        param($match)
        $hit = $match.Groups['hit'].Value
        [void]$rayResultNames.Add($hit)
        $indent = $match.Groups['indent'].Value
        $manager = $match.Groups['manager'].Value
        $ray = $match.Groups['ray'].Value
        $distance = $match.Groups['distance'].Value.Trim()
        $mask = if ($match.Groups['mask'].Success) { $match.Groups['mask'].Value.Trim() } else { 'CollisionCategory.All' }
        return "${indent}bool ${hit}Succeeded = ${manager}.RayCast(ref ${ray}, ${distance}, new QueryFilter { CategoryMask = ${mask}, IncludeSensors = true }, out RayCastHit ${hit});"
    })

    $result = Convert-SourceCalls $result $File $rayResultNames

    # Repair RayCast calls emitted by older versions of this migrator. Bullet ray
    # queries included ghost/sensor objects, while QueryFilter.FromCategories does
    # not. Restrict the repair to the bool/out form generated above.
    $oldGeneratedRayFilterPattern = '(?m)(?<prefix>\.RayCast\([^\r\n]*?)QueryFilter\.FromCategories\((?<mask>[^\)\r\n]+)\)(?<suffix>\s*,\s*out\s+RayCastHit\b)'
    if ($result -match $oldGeneratedRayFilterPattern) {
        $result = [regex]::Replace($result, $oldGeneratedRayFilterPattern, {
            param($match)
            return $match.Groups['prefix'].Value +
                'new QueryFilter { CategoryMask = ' + $match.Groups['mask'].Value.Trim() + ', IncludeSensors = true }' +
                $match.Groups['suffix'].Value
        })
        Add-Finding 'Info' 'source-query-sensors-preserved' $File 0 'A RayCast generated by an older migrator was updated to include sensors, matching Bullet query behavior.'
    }

    foreach ($hit in $rayResultNames) {
        $escapedHit = [regex]::Escape($hit)
        $result = [regex]::Replace($result, '\b' + $escapedHit + '\.PhysicBody\??\.BodyComponent\??\.Owner\b', $hit + '.Entity')
        $result = [regex]::Replace($result, '\b' + $escapedHit + '\.PhysicBody\b', $hit + '.Body')
        $result = [regex]::Replace($result, '\b' + $escapedHit + '\.HitFraction\b', $hit + '.Fraction')
        $result = [regex]::Replace($result, '\b' + $escapedHit + '\.Succeeded\b', $hit + 'Succeeded')
    }

    if ($rayResultNames.Count -gt 0) {
        Add-Finding 'Info' 'source-query-migrated' $File 0 'A Bullet RayCast result was converted to the Jolt bool/out RayCastHit API with QueryFilter.'
    }

    # CollisionInfo no longer has Bullet's pair Id. When it is used directly as a
    # Dictionary<int, T> key, migrate that dictionary to the collider pair instead.
    # This keeps two sensor bodies touching the same target distinct; hashing only
    # OtherBody made proximity state stick after one of the contacts ended.
    $collisionInfoVariables = [regex]::Matches($result, '\bCollisionInfo\s+(?<name>[A-Za-z_]\w*)\b')
    foreach ($variableMatch in $collisionInfoVariables) {
        $name = $variableMatch.Groups['name'].Value
        $idPattern = '\b' + [regex]::Escape($name) + '\.Id\b'
        if ($result -notmatch $idPattern) {
            continue
        }

        $convertedDictionaryUse = $false
        $dictionaryUsePattern = '(?<receiver>(?:this\.)?(?<dictionary>[A-Za-z_]\w*))\.(?<method>Add|TryGetValue|Remove|ContainsKey)\s*\(\s*' + $idPattern
        $dictionaryUses = [regex]::Matches($result, $dictionaryUsePattern)
        foreach ($dictionaryUse in $dictionaryUses) {
            $dictionary = $dictionaryUse.Groups['dictionary'].Value
            # Stop the value-type match at the first closing generic bracket. The
            # declaration commonly initializes a second Dictionary<int, T> on the
            # same line; a greedy match would consume that initializer and miss the
            # field name that appears between both generic expressions.
            $dictionaryDeclarationPattern = '(?m)^(?<line>[^\r\n]*\bDictionary\s*<\s*int\s*,\s*[^>\r\n]+>\s+' + [regex]::Escape($dictionary) + '\b[^\r\n]*)(?<ending>\r?)$'
            $declarationMatch = [regex]::Match($result, $dictionaryDeclarationPattern)
            if (-not $declarationMatch.Success) {
                continue
            }

            $oldLine = $declarationMatch.Groups['line'].Value
            $newLine = [regex]::Replace(
                $oldLine,
                '\bDictionary\s*<\s*int\s*,\s*(?<value>[^>\r\n]+)>',
                'Dictionary<(Collider, Collider), ${value}>')
            $newLine += $declarationMatch.Groups['ending'].Value
            $result = $result.Substring(0, $declarationMatch.Index) + $newLine + $result.Substring($declarationMatch.Index + $declarationMatch.Length)

            $specificUsePattern = '(?<prefix>(?:this\.)?' + [regex]::Escape($dictionary) + '\.(?:Add|TryGetValue|Remove|ContainsKey)\s*\(\s*)' + $idPattern
            $result = [regex]::Replace($result, $specificUsePattern, '${prefix}(' + $name + '.ThisCollider, ' + $name + '.OtherCollider)')
            $convertedDictionaryUse = $true
        }

        if ($convertedDictionaryUse) {
            Add-Finding 'Info' 'source-collision-pair-key-migrated' $File 0 'A Dictionary keyed by CollisionInfo.Id now uses the (ThisCollider, OtherCollider) pair, preserving simultaneous contacts from different sensors.'
        }

        if ($result -match $idPattern) {
            $result = [regex]::Replace($result, $idPattern, $name + '.OtherBody.GetHashCode()')
            Add-Finding 'Warning' 'source-collision-id-fallback' $File 0 'A remaining CollisionInfo.Id use fell back to OtherBody.GetHashCode(). It cannot distinguish two colliders touching the same body; replace it with an explicit (ThisCollider, OtherCollider) key where contact identity matters.'
        }
    }

    # StaticBody is level geometry in Jolt. Unlike Bullet ghost objects, two static
    # bodies never produce contacts, and moving one by changing Transform3D does not
    # make it a moving broad-phase body. Report code-created static sensors because
    # cursors, tracked hands and other moving probes must be kinematic sensors.
    $staticSensorPattern = '(?s)\bnew\s+StaticBody\s*(?:\(\s*\))?\s*\{(?:(?!\}).)*?\bIsSensor\s*=\s*true\b'
    if ($result -match $staticSensorPattern) {
        Add-Finding 'Warning' 'source-static-sensor-motion-review' $File 0 'A code-created StaticBody sensor remains. If it moves or follows a hand/cursor, use RigidBody with IsKinematic = true and CollideKinematicVsNonDynamic = true; Jolt does not generate static-static contacts.'
    }

    # Collider components are AttachableObjects. Manager-created Bullet shapes were
    # IDisposable; their Jolt collider replacements use Destroy().
    $colliderVariables = [regex]::Matches($result, '\b(?:BoxCollider|SphereCollider|CapsuleCollider|CylinderCollider|TaperedCylinderCollider|MeshCollider)\s+(?<name>[A-Za-z_]\w*)\b')
    foreach ($variableMatch in $colliderVariables) {
        $name = [regex]::Escape($variableMatch.Groups['name'].Value)
        $result = [regex]::Replace($result, '(?<receiver>(?:this\.)?' + $name + ')\.OnShapeChanged\b', '${receiver}.ShapeChanged')
        $result = [regex]::Replace($result, '(?<receiver>(?:this\.)?' + $name + ')\?\.Dispose\s*\(\s*\)', '${receiver}?.Destroy()')
        $result = [regex]::Replace($result, '(?<receiver>(?:this\.)?' + $name + ')\.Dispose\s*\(\s*\)', '${receiver}.Destroy()')
    }

    # MeshCollider now consumes model/code geometry directly and has no authored Size.
    # Defaulting legacy Size reads to one preserves the old default and keeps the
    # migration compilable; non-default authored sizes are already called out in assets.
    $meshVariables = [regex]::Matches($result, '\bMeshCollider\s+(?<name>[A-Za-z_]\w*)\b')
    foreach ($variableMatch in $meshVariables) {
        $name = [regex]::Escape($variableMatch.Groups['name'].Value)
        $sizePattern = '(?:this\.)?' + $name + '\.Size\b'
        if ($result -match $sizePattern) {
            $result = [regex]::Replace($result, $sizePattern, 'Vector3.One')
            Add-Finding 'Warning' 'source-mesh-size-defaulted' $File 0 'MeshCollider.Size no longer exists and was replaced with Vector3.One. Derive bounds from the model when the old size was significant.'
        }
    }

    # Bullet Margin maps reasonably to Jolt's rounded convex radius where that
    # property exists. Sphere/capsule margins have no counterpart and are removed.
    $roundedMarginPattern = '(?ms)(?<prefix>\bnew\s+(?:Box|Cylinder|TaperedCylinder|Mesh)Collider\s*(?:\([^\)]*\))?\s*\{(?:(?!^[ \t]*\}).)*?)^(?<indent>[ \t]*)Margin(?<tail>\s*=\s*[^\r\n]*\r?\n)'
    if ($result -match $roundedMarginPattern) {
        $result = [regex]::Replace($result, $roundedMarginPattern, '${prefix}${indent}ConvexRadius${tail}')
        Add-Finding 'Info' 'source-margin-migrated' $File 0 'Collider Margin was mapped to Jolt ConvexRadius.'
    }
    $removedMarginPattern = '(?ms)(?<prefix>\bnew\s+(?:Sphere|Capsule)Collider\s*(?:\([^\)]*\))?\s*\{(?:(?!^[ \t]*\}).)*?)^[ \t]*Margin\s*=\s*[^\r\n]*\r?\n'
    if ($result -match $removedMarginPattern) {
        $result = [regex]::Replace($result, $removedMarginPattern, '${prefix}')
        Add-Finding 'Info' 'source-margin-removed' $File 0 'Sphere/Capsule Margin has no Jolt counterpart and was removed.'
    }

    # The common paired Bullet LinearFactor/AngularFactor save-lock-restore idiom
    # maps exactly to Jolt's AllowedDegreesOfFreedom.
    $factorDeclarationPattern = '(?m)^(?<indent>[ \t]*)private\s+Vector3\s+previousAngularFactor;\s*\r?\n[ \t]*private\s+Vector3\s+previousLinearFactor;'
    $result = [regex]::Replace($result, $factorDeclarationPattern, '${indent}private DegreesOfFreedom previousAllowedDegreesOfFreedom;')
    $factorReadPattern = '(?m)^(?<indent>[ \t]*)this\.previousLinearFactor\s*=\s*this\.(?<body>[A-Za-z_]\w*)\.LinearFactor;\s*\r?\n[ \t]*this\.previousAngularFactor\s*=\s*this\.\k<body>\.AngularFactor;'
    $result = [regex]::Replace($result, $factorReadPattern, '${indent}this.previousAllowedDegreesOfFreedom = this.${body}.AllowedDegreesOfFreedom;')
    $factorLockPattern = '(?m)^(?<indent>[ \t]*)this\.(?<body>[A-Za-z_]\w*)\.LinearFactor\s*=\s*Vector3\.Zero;\s*\r?\n[ \t]*this\.\k<body>\.AngularFactor\s*=\s*Vector3\.Zero;'
    $result = [regex]::Replace($result, $factorLockPattern, '${indent}this.${body}.AllowedDegreesOfFreedom = DegreesOfFreedom.None;')
    $factorRestorePattern = '(?m)^(?<indent>[ \t]*)this\.(?<body>[A-Za-z_]\w*)\.LinearFactor\s*=\s*this\.previousLinearFactor;\s*\r?\n[ \t]*this\.\k<body>\.AngularFactor\s*=\s*this\.previousAngularFactor;'
    $result = [regex]::Replace($result, $factorRestorePattern, '${indent}this.${body}.AllowedDegreesOfFreedom = this.previousAllowedDegreesOfFreedom;')

    # Any other LinearFactor/AngularFactor assignment updates its half of AllowedDegreesOfFreedom.
    $factorsBefore = $result
    foreach ($factor in 'Linear/Translation', 'Angular/Rotation') {
        $name, $prefix = $factor.Split('/')
        $result = [regex]::Replace($result, '(?m)^(?<indent>[ \t]*)(?<receiver>(?:this\.)?\w+(?:\.\w+)*)\.' + $name + 'Factor\s*=(?!=)\s*(?<value>[^;\r\n]+?)\s*;', {
            param($match)
            $receiver = $match.Groups['receiver'].Value
            return $match.Groups['indent'].Value + $receiver + '.AllowedDegreesOfFreedom = (' + $receiver + '.AllowedDegreesOfFreedom & ~(DegreesOfFreedom.' + $prefix + 'X | DegreesOfFreedom.' + $prefix + 'Y | DegreesOfFreedom.' + $prefix + 'Z)) | ' + (Get-DegreesOfFreedomExpression $match.Groups['value'].Value $prefix) + ';'
        })
    }
    if ($result -ne $factorsBefore) {
        Add-Finding 'Info' 'source-factor-migrated' $File 0 'LinearFactor/AngularFactor assignments became AllowedDegreesOfFreedom updates; a non-zero component keeps the axis free.'
    }

    # Physics bodies are no longer updateable components with their own UpdateOrder.
    $bodyOrderPattern = '(?m)^(?<indent>[ \t]*)this\.UpdateOrder\s*=\s*this\.(?:rigidBody|rigidBody3D|physicsBody|physicBody3D)\.UpdateOrder\s*\+\s*(?<offset>[^;\r\n]+);'
    if ($result -match $bodyOrderPattern) {
        $result = [regex]::Replace($result, $bodyOrderPattern, '${indent}this.UpdateOrder = ${offset};')
        Add-Finding 'Warning' 'source-update-order-migrated' $File 0 'A behavior order relative to a Bullet body was reduced to the explicit offset because Jolt bodies have no UpdateOrder.'
    }

    # Generated code uses short Jolt and mathematics type names.
    if ($result -ne $before -and $result -match '(?m)^\s*using\s+Evergine\.') {
        if ($result -match '\b(?:MotorMode|MeshColliderType|DegreesOfFreedom|QueryFilter|ShapeCastHit|RayCastHit|CollisionCategory|MotionQuality)\b') { $result = Add-UsingIfMissing $result 'Evergine.Framework.Physics' }
        if ($result -match '\b(?:Vector3|Quaternion|MathHelper)\.') { $result = Add-UsingIfMissing $result 'Evergine.Mathematics' }
    }

    if ($result -ne $before) { Add-Change }

    $reviewPatterns = [ordered]@{
        '\b(?:IPhysicBody3D|IRigidBody3D|IStaticBody3D|I[A-Za-z]*ColliderShape3D|Collider3D|ContactPoint3D|RigidBodyType3D)\b' = 'A removed Physics3D interface/value type still appears.'
        '\.(?:MaskBits|RollingFriction|LocalInertia|OverrideGravity|CcdMotionThreshold|CcdSweptSphereRadius)\b' = 'A Bullet-only body property still appears.'
        '\.(?:LinearFactor|AngularFactor|InternalColliderShape|OrientationOffset)\b' = 'A removed Bullet body/collider property still appears.'
        '\.(?:IsFrontWheel|IsDriveWheel|IsSteerableWheel|IsBrakableWheel)\b' = 'Wheel roles now live on WheeledVehicleController (wheel indices, FrontWheelDrive/RearWheelDrive) and VehicleWheel.MaxSteerAngle/MaxBrakeTorque.'
        '\.(?:JumpSpeed|FallSpeed)\b|\bCollisionInfo3DState\b|\.GetContacts?\s*\(|\.ClearForces\s*\(|\bOnBroke\b' = 'A Bullet member without Jolt equivalent still appears (JumpSpeed: pass it to Jump(speed); CollisionInfo has one aggregated contact; Joint3D.OnBroke became Constraint.Broken).'
        '\.(?:ApplyEngineForce|SetSteeringValue|SetBrake)\s*\(' = 'Legacy Bullet vehicle input calls must be combined into Jolt SetDriverInput(forward, right, brake, handBrake).'
        '\.(?:ConvexSweepTest|ConvexSweepTestAll|SweepTest|SweepTestAll|ContactTest|ContactPairTest|PointTest)\s*\(|\.RayCastAll\s*\(\s*ref\b' = 'The query API changed to RayCast/ShapeCast/Overlap methods with QueryFilter.'
        '\.ResetTransform\s*\(' = 'ResetTransform became Teleport(position, orientation); scale now belongs to the entity/collider shape.'
        '\bEvergine\.Bullet\b|\bBulletSharp\b' = 'Direct Bullet API usage cannot be mechanically migrated.'
    }
    foreach ($pattern in $reviewPatterns.Keys) {
        if ($result -match $pattern) {
            Add-Finding 'Warning' 'source-needs-review' $File 0 $reviewPatterns[$pattern]
        }
    }

    foreach ($rayCall in [regex]::Matches($result, '(?m)\.RayCast\s*\((?<arguments>[^;\r\n]*)\)')) {
        if ($rayCall.Groups['arguments'].Value -notmatch '\bout\s+RayCastHit\b') {
            Add-Finding 'Warning' 'source-needs-review' $File 0 'A RayCast call was not converted. Jolt RayCast returns bool and requires an out RayCastHit argument.'
            break
        }
    }

    if ($result -ne $before -and $Text -match '\b(?:PhysicVehicle3D|PhysicWheel3D)\b') {
        Add-Finding 'Warning' 'source-needs-review' $File 0 'Vehicle code moved to WheeledVehicleController/VehicleWheel, which model an engine, transmission and tyres: input goes through SetDriverInput and wheel roles through the controller indices.'
    }

    return $result
}

function Test-IsExcludedPath {
    param([string] $FullName)
    $normalized = $FullName.Replace('/', '\')
    return $normalized -match '\\(?:\.git|\.vs|bin|obj|node_modules|\.bullet-to-jolt-backup)(?:\\|$)'
}

function Get-CommonDirectoryPath {
    param([string[]] $Directories)

    if ($Directories.Count -eq 0) {
        throw 'At least one directory is required to determine the project root.'
    }

    $common = [System.IO.Path]::GetFullPath($Directories[0]).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)

    foreach ($directory in $Directories | Select-Object -Skip 1) {
        $candidate = [System.IO.Path]::GetFullPath($directory).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)

        while ($candidate -ne $common -and -not $candidate.StartsWith(
            $common + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase)) {
            $parent = [System.IO.Directory]::GetParent($common)
            if ($null -eq $parent) {
                throw "The solution references projects that do not share a filesystem root: $candidate"
            }

            $common = $parent.FullName.TrimEnd(
                [System.IO.Path]::DirectorySeparatorChar,
                [System.IO.Path]::AltDirectorySeparatorChar)
        }
    }

    return $common
}

function Get-SolutionProjectFiles {
    param([System.IO.FileInfo] $Solution)

    $solutionDirectory = $Solution.Directory.FullName
    $projectFiles = New-Object 'System.Collections.Generic.List[string]'
    $solutionText = [System.IO.File]::ReadAllText($Solution.FullName)
    $extension = $Solution.Extension.ToLowerInvariant()

    if ($extension -eq '.sln') {
        $matches = [regex]::Matches(
            $solutionText,
            '(?m)^\s*Project\("[^"]+"\)\s*=\s*"[^"]*",\s*"(?<path>[^"]+)",\s*"[^"]+"\s*$')
        foreach ($match in $matches) {
            $referencedPath = $match.Groups['path'].Value.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $referencedExtension = [System.IO.Path]::GetExtension($referencedPath).ToLowerInvariant()
            if ($referencedExtension -notin @('.csproj', '.fsproj', '.vbproj', '.shproj', '.proj')) {
                continue
            }

            $fullPath = if ([System.IO.Path]::IsPathRooted($referencedPath)) {
                [System.IO.Path]::GetFullPath($referencedPath)
            }
            else {
                [System.IO.Path]::GetFullPath((Join-Path $solutionDirectory $referencedPath))
            }

            if ([System.IO.File]::Exists($fullPath)) {
                $projectFiles.Add($fullPath)
            }
            else {
                Add-Finding 'Warning' 'solution-project-missing' $Solution.Name 0 "The solution references a project that was not found: $referencedPath"
            }
        }
    }
    elseif ($extension -eq '.slnx') {
        foreach ($match in [regex]::Matches($solutionText, '<Project\s+[^>]*Path\s*=\s*["''](?<path>[^"'']+)["'']')) {
            $referencedPath = $match.Groups['path'].Value.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $fullPath = [System.IO.Path]::GetFullPath((Join-Path $solutionDirectory $referencedPath))
            if ([System.IO.File]::Exists($fullPath)) {
                $projectFiles.Add($fullPath)
            }
            else {
                Add-Finding 'Warning' 'solution-project-missing' $Solution.Name 0 "The solution references a project that was not found: $referencedPath"
            }
        }
    }

    return $projectFiles.ToArray()
}

function Find-EvergineProjectRoot {
    param([string] $StartDirectory)

    $current = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($StartDirectory))
    while ($null -ne $current) {
        if ($current.GetFiles('*.weproj', [System.IO.SearchOption]::TopDirectoryOnly).Count -gt 0) {
            return $current.FullName
        }

        $current = $current.Parent
    }

    return $null
}

function Find-RepositoryRoot {
    param([string] $StartDirectory)

    $current = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($StartDirectory))
    while ($null -ne $current) {
        $gitMarker = Join-Path $current.FullName '.git'
        if ([System.IO.Directory]::Exists($gitMarker) -or [System.IO.File]::Exists($gitMarker)) {
            return $current.FullName
        }

        $current = $current.Parent
    }

    return $null
}

$rootItem = Get-Item -LiteralPath $ProjectPath
$inputPath = $rootItem.FullName
if ($rootItem.PSIsContainer) {
    $root = $rootItem.FullName
}
else {
    $inputExtension = $rootItem.Extension.ToLowerInvariant()
    switch ($inputExtension) {
        { $_ -in @('.sln', '.slnx') } {
            $solutionProjects = @(Get-SolutionProjectFiles $rootItem)
            $repositoryRoot = Find-RepositoryRoot $rootItem.Directory.FullName
            if ($null -ne $repositoryRoot) {
                # A development solution may include the Evergine sources, SDKs or
                # other dependency repositories through absolute paths. Constrain
                # migration to the repository that owns the supplied solution so a
                # game migration can never rewrite those external dependencies.
                $root = $repositoryRoot
                $rootPrefix = $repositoryRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
                $externalSolutionProjects = New-Object 'System.Collections.Generic.List[string]'
                foreach ($solutionProject in $solutionProjects) {
                    if ($solutionProject -ne $repositoryRoot -and -not $solutionProject.StartsWith(
                        $rootPrefix,
                        [System.StringComparison]::OrdinalIgnoreCase)) {
                        $externalSolutionProjects.Add($solutionProject)
                    }
                }

                if ($externalSolutionProjects.Count -gt 0) {
                    $examples = ($externalSolutionProjects | Select-Object -First 3) -join '; '
                    Add-Finding 'Info' 'solution-external-projects-excluded' $rootItem.Name 0 "$($externalSolutionProjects.Count) external solution project(s) were intentionally excluded from migration. Examples: $examples"
                }
            }
            else {
                $rootDirectories = New-Object 'System.Collections.Generic.List[string]'
                $rootDirectories.Add($rootItem.Directory.FullName)
                foreach ($solutionProject in $solutionProjects) {
                    $rootDirectories.Add([System.IO.Path]::GetDirectoryName($solutionProject))
                }

                try {
                    $root = Get-CommonDirectoryPath $rootDirectories.ToArray()
                }
                catch {
                    # Without a repository marker there is no safe way to decide
                    # whether absolute/cross-drive projects belong to the product.
                    # Falling back to the solution directory is safer than editing
                    # a dependency tree or rejecting an otherwise valid solution.
                    $root = $rootItem.Directory.FullName
                    Add-Finding 'Warning' 'solution-root-fallback' $rootItem.Name 0 'The solution spans unrelated filesystem roots and has no .git marker. Only the solution directory will be migrated; pass the intended project directory to include shared sources.'
                }
            }
            break
        }
        { $_ -in @('.csproj', '.fsproj', '.vbproj', '.shproj', '.proj', '.weproj') } {
            $evergineRoot = Find-EvergineProjectRoot $rootItem.Directory.FullName
            $root = if ($null -ne $evergineRoot) { $evergineRoot } else { $rootItem.Directory.FullName }
            break
        }
        default {
            throw "ProjectPath must be a project directory, .sln, .slnx, .csproj or .weproj file: $ProjectPath"
        }
    }
}

$root = [System.IO.Path]::GetFullPath($root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$driveRoot = [System.IO.Path]::GetPathRoot($root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
if ($root -eq $driveRoot) {
    throw 'Refusing to scan and edit an entire drive. Pass the Evergine project directory.'
}

$candidateFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
$assetExtensions = @('.wescene', '.weprefab')
$projectExtensions = @('.csproj', '.props', '.targets', '.projitems')
$files = Get-ChildItem -LiteralPath $root -Recurse -File
foreach ($file in $files) {
    if (Test-IsExcludedPath $file.FullName) { continue }
    $extension = $file.Extension.ToLowerInvariant()
    if ($assetExtensions -contains $extension -or $projectExtensions -contains $extension -or (-not $AssetsOnly -and $extension -eq '.cs')) {
        $candidateFiles.Add($file)
    }
}

# Older versions of this script copied one fixed vehicle sample profile. Index
# any backups they produced so a rerun can recover the original Bullet wheel
# geometry and suspension by component Id without asking the user to restore the
# entire project first.
Initialize-LegacyVehicleBackupIndex $root

# Constraint-chain stability depends on the mass of the load the chain is meant
# to carry. Vehicle bodies often live in a prefab while a bridge lives in a scene,
# so collect the heaviest vehicle before converting either asset. The same pass collects
# every legacy (category, mask) pair for one project-wide CollisionMatrix.
$projectHasLegacyPhysics = $false
foreach ($file in $candidateFiles) {
    $extension = $file.Extension.ToLowerInvariant()
    $relativePath = $file.FullName.Substring($root.Length).TrimStart('\', '/')
    if ($assetExtensions -contains $extension) {
        $assetText = Expand-LegacyErrorComponents (Get-TextFile $file.FullName).Text $relativePath "`n" $false
        $projectHasLegacyPhysics = $projectHasLegacyPhysics -or $assetText -match '!Evergine\.(?:Framework\.Physics3D|Bullet)\.'
        foreach ($entity in (Get-YamlEntityIndex ([regex]::Split($assetText, "`r`n|`n|`r"))).Entities) {
            foreach ($body in @($entity.Components | Where-Object { $_.Type -match '\.Physics3D\.(?:RigidBody3D|StaticBody3D|CharacterController3D)$' })) {
                Add-CollisionEvidence (Get-YamlValue $body.Block $body.Indent 'CollisionCategories') (Get-YamlValue $body.Block $body.Indent 'MaskBits') $relativePath
            }
        }

        $vehicleMass = Get-MaxVehicleMassFromYaml $assetText
        if ($vehicleMass -gt $script:ReferenceVehicleMass) {
            $script:ReferenceVehicleMass = $vehicleMass
        }
    }
    elseif ($extension -eq '.cs') {
        $sourceText = (Get-TextFile $file.FullName).Text
        if ($sourceText -match '\bEvergine\.Framework\.Physics3D\b|\bBulletPhysicManager3D\b|\b(?:RigidBody3D|StaticBody3D|CharacterController3D)\b') {
            $projectHasLegacyPhysics = $true
            # Code-created bodies, and MaskBits assignments with the category of the same receiver.
            foreach ($creation in [regex]::Matches($sourceText, '\bnew\s+(?:global::)?(?:Evergine\.Framework\.Physics3D\.)?(?:RigidBody3D|StaticBody3D|CharacterController3D)\s*(?:\([^()]*\))?\s*\{')) {
                $initializer = Get-Balanced $sourceText ($creation.Index + $creation.Length - 1)
                $members = Get-InitializerMembers $initializer.Substring(1, $initializer.Length - 2)
                $category = Get-Member $members 'CollisionCategories'
                $mask = Get-Member $members 'MaskBits'
                if ($null -ne $category -or $null -ne $mask) {
                    Add-CollisionEvidence $(if ($category) { $category.Value }) $(if ($mask) { $mask.Value }) $relativePath
                }
            }
            foreach ($assignment in [regex]::Matches($sourceText, '(?<receiver>(?:this\.)?\w+)\.MaskBits\s*=(?!=)\s*(?<value>[^;\r\n]+);')) {
                $category = [regex]::Match($sourceText, [regex]::Escape($assignment.Groups['receiver'].Value) + '\.CollisionCategories\s*=(?!=)\s*(?<value>[^;\r\n]+);')
                Add-CollisionEvidence $(if ($category.Success) { $category.Groups['value'].Value }) $assignment.Groups['value'].Value $relativePath
            }
        }
    }
}

if ($projectHasLegacyPhysics) {
    $script:ProjectCollisionMatrix = Get-ProjectCollisionMatrix
    if ($script:ProjectCollisionMatrix.Conflicts.Count -gt 0) {
        Add-Finding 'Warning' 'collision-matrix-conflict' '' 0 ('Bodies of the same category used different MaskBits: ' + ($script:ProjectCollisionMatrix.Conflicts -join ', ') + ' were enabled so nothing that collided in Bullet passes through.')
    }
}

if ($PreserveConstraintMasses) {
    Add-Finding 'Info' 'obsolete-switch' '' 0 '-PreserveConstraintMasses is obsolete: masses are kept unless -StabilizeConstraintChains is supplied.'
}

$changedFiles = New-Object 'System.Collections.Generic.List[object]'
foreach ($file in $candidateFiles) {
    $relativePath = $file.FullName.Substring($root.Length).TrimStart('\', '/')
    $source = Get-TextFile $file.FullName
    $extension = $file.Extension.ToLowerInvariant()
    $converted = $source.Text

    if ($assetExtensions -contains $extension) {
        $converted = Convert-YamlContent $source.Text $relativePath $source.NewLine
    }
    elseif ($projectExtensions -contains $extension) {
        $converted = Convert-ProjectContent $source.Text $relativePath
    }
    elseif ($extension -eq '.cs') {
        $converted = Convert-SourceContent $source.Text $relativePath
    }

    if ($converted -ne $source.Text) {
        $changedFiles.Add([pscustomobject]@{
            File = $file
            RelativePath = $relativePath
            Original = $source
            Converted = $converted
        })
    }
}

if ($null -ne $script:ProjectCollisionMatrix -and $script:CollisionMatrixTargets -eq 0 -and $script:ProjectCollisionMatrix.NeedsMatrix) {
    Add-Finding 'Warning' 'collision-matrix-not-written' '' 0 ('No PhysicsManager was found in the assets or as new BulletPhysicManager3D() in code. Assign PhysicsManager.CollisionMatrix = ' + (Format-CollisionMatrixSource) + ' where it is created. ' + $script:ProjectCollisionMatrix.Summary)
}

$backupRoot = $null
if ($Apply -and $changedFiles.Count -gt 0) {
    if (-not $NoBackup) {
        $stamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss', $script:Invariant)
        $backupRoot = Join-Path $root ('.bullet-to-jolt-backup\' + $stamp)
        [System.IO.Directory]::CreateDirectory($backupRoot) | Out-Null
    }

    foreach ($change in $changedFiles) {
        if ($null -ne $backupRoot) {
            $backupFile = Join-Path $backupRoot $change.RelativePath
            $backupDirectory = [System.IO.Path]::GetDirectoryName($backupFile)
            [System.IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
            [System.IO.File]::Copy($change.File.FullName, $backupFile, $true)
        }

        Set-TextFile $change.File.FullName $change.Converted $change.Original.Encoding $change.Original.HasPreamble
    }
}

$changedFileNames = New-Object string[] $changedFiles.Count
for ($index = 0; $index -lt $changedFiles.Count; $index++) {
    $changedFileNames[$index] = $changedFiles[$index].RelativePath
}
$findingArray = New-Object object[] $script:Findings.Count
for ($index = 0; $index -lt $script:Findings.Count; $index++) {
    $findingArray[$index] = $script:Findings[$index]
}

$report = [pscustomobject]@{
    Tool = 'Evergine Bullet to Jolt migrator'
    InputPath = $inputPath
    ProjectPath = $root
    Mode = if ($Apply) { 'Apply' } else { 'DryRun' }
    GeneratedAt = [DateTimeOffset]::Now.ToString('o', $script:Invariant)
    ScannedFiles = $candidateFiles.Count
    ChangedFiles = $changedFileNames
    ConvertedComponents = $script:ConvertedComponentCount
    StabilizedConstraintBodies = $script:StabilizedConstraintBodyCount
    Changes = $script:ChangeCount
    BackupPath = $backupRoot
    Findings = $findingArray
}

if ([string]::IsNullOrWhiteSpace($ReportPath) -and $null -ne $backupRoot) {
    $ReportPath = Join-Path $backupRoot 'migration-report.json'
}

if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $resolvedReportPath = if ([System.IO.Path]::IsPathRooted($ReportPath)) { $ReportPath } else { Join-Path $root $ReportPath }
    $reportDirectory = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($resolvedReportPath))
    [System.IO.Directory]::CreateDirectory($reportDirectory) | Out-Null
    $json = $report | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($resolvedReportPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

$modeText = if ($Apply) { 'APPLIED' } else { 'DRY RUN' }
Write-Host "[$modeText] Bullet -> Jolt"
if ($inputPath -ne $root) { Write-Host ('Resolved project root: ' + $root) }
Write-Host ('Scanned files:       ' + $candidateFiles.Count)
Write-Host ('Files to change:     ' + $changedFiles.Count)
Write-Host ('Converted components:' + $script:ConvertedComponentCount)
Write-Host ('Stabilized bodies:    ' + $script:StabilizedConstraintBodyCount)
Write-Host ('Migration findings:  ' + $script:Findings.Count)
if ($null -ne $backupRoot) { Write-Host ('Backup:             ' + $backupRoot) }

if ($changedFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'Changed files:'
    $changedFiles | ForEach-Object { Write-Host ('  ' + $_.RelativePath) }
}

if ($script:Findings.Count -gt 0) {
    Write-Host ''
    Write-Host 'Manual review:'
    $script:Findings |
        Sort-Object @{ Expression = { if ($_.Severity -eq 'Warning') { 0 } else { 1 } } }, File, Line, Code |
        Format-Table -AutoSize Severity, Code, File, Line, Message |
        Out-Host
}

if (-not $Apply -and $changedFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'No files were modified. Run again with -Apply after reviewing the findings.'
}

Write-Output $report
