$PSDefaultParameterValues['Out-File:Encoding'] = 'ascii'

$targetDirectory = $args[0]

if(!$targetDirectory)
{
    $targetDirectory = "..\Dist\"
}

$json= Get-Content -Raw definition.json

$definition = ConvertFrom-Json $json


$maxNumber = $definition.maxNumber

$langFile = "$($targetDirectory)localisation\english\stackable-strategic-resources_l_english.yml"
$staticModifierFile = "$($targetDirectory)common\static_modifiers\stackable-strategic-resources_static_modifiers.txt"
$eventFile = "$($targetDirectory)events\stackable-strategic-resources_events.txt"

New-Item -ItemType File -Force -Path $langFile
New-Item -ItemType File -Force -Path $staticModifierFile
New-Item -ItemType File -Force -Path $eventFile

Out-File -InputObject "l_english:" -FilePath $langFile -Append -Encoding utf8
"namespace = stackableStrategicResources`r`n" >> $eventFile

$resourceMembers = (Get-Member -InputObject $definition.resources -MemberType NoteProperty)
for($j=0; $j -lt $resourceMembers.length; $j++)
{
    $resourceName = $resourceMembers[$j].Name

    # 输出语言文件
    for($i=1;$i -le $maxNumber;$i++)
    {
        $line = " $($resourceName)$($i):0 `"额外$($i)单位`$sr_$($resourceName)$`""
        Out-File -InputObject $line -FilePath $langFile -Append -Encoding utf8
    }
    Out-File -InputObject "" -FilePath $langFile -Append -Encoding utf8

    # 输出static modifier
    for($i=1;$i -le $maxNumber;$i++)
    {
        "$($resourceName)$($i) = {" >> $staticModifierFile

        foreach($modifierMember in (Get-Member -InputObject $definition.resources.$($resourceName) -MemberType NoteProperty))
        {
            $modifier = $modifierMember.Name
            $value = $definition.resources.$($resourceName).$($modifier)
            "`t$($modifier) = $($value * $i)" >> $staticModifierFile
        }
        "}`r`n" >> $staticModifierFile
    }

    "" >> $staticModifierFile

    # 输出事件
    @"
country_event = {
	id = stackableStrategicResources.$($j+1)

	hide_window = yes

	mean_time_to_happen = { days = 60 }

	trigger = {
		has_country_strategic_resource = { type = sr_$($resourceName) amount > 1 }
	}

	immediate = {
"@ >> $eventFile


    for($c=1;$c -le $maxNumber-1;$c++)
    {
    @"
		if = {
			limit = {
				has_country_strategic_resource = { type = sr_$($resourceName) amount = $($c+1) }
			}
			add_modifier = { modifier = $($resourceName)$($c) days = -1 }

			else = {
				remove_modifier = $($resourceName)$($c)
			}
		}
"@ >> $eventFile
    }

        @"
		if = {
			limit = {
				has_country_strategic_resource = { type = sr_$($resourceName) amount > $($maxNumber) }
			}
			add_modifier = { modifier = $($resourceName)$($maxNumber) days = -1 }

			else = {
				remove_modifier = $($resourceName)$($maxNumber)
			}
		}
	}
}`r`n
"@ >> $eventFile
}


