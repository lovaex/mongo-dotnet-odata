Properties {
	$base_dir = Split-Path $psake.build_script_file	
	$artifacts_dir = "$base_dir\artifacts"
	$build_dir = "$artifacts_dir\build"
	$package_dir = "$artifacts_dir\packages"
	$src_dir = "$base_dir\src"
	$tools_dir = "$base_dir\tools"
	$sln_file = "$base_dir\MongoDB.OData.sln"
	$asm_file = "$src_dir\GlobalAssemblyInfo.cs"
	$nuspec_file = "$base_dir\MongoDB.OData.nuspec"

	$nuget_tool = "$tools_dir\nuget\nuget.exe"

	$version = "0.1.2.0"
	$sem_version = "0.1.2"
	$config = "Release"
}

Framework("4.0")

include .\psake_ext.ps1

Task Default -Depends Build

Task Clean {
	if (Test-Path $artifacts_dir) 
	{	
		rd $artifacts_dir -rec -force | out-null
	}
	
	Write-Host "Cleaning $sln_file" -ForegroundColor Green
	Exec { msbuild "$sln_file" /t:Clean /p:Configuration=$config /v:quiet } 
}

Task Init -Depends Clean {
	$infos = gci -rec "**\AssemblyInfo.cs"

	Generate-Assembly-Info `
		-file $asm_file `
		-version $version `
		-sem_version $sem_version `
		-copyright 'Craig Wilson 2012'
}

Task Build -Depends Init {	
	mkdir -p $build_dir

	Write-Host "Building $sln_file" -ForegroundColor Green
	Exec { msbuild "$sln_file" /t:Build /p:Configuration=Release /v:quiet /p:OutDir=$build_dir } 
}

task Package -Depends Build {
	mkdir -p $package_dir

	&$nuget_tool pack $nuspec_file -o $package_dir -Version $sem_version -Symbols -BasePath $base_dir
}

task Publish -Depends Package {
	&$nuget_tool push "$package_dir\MongoDB.OData.$sem_version.nupkg"
}