FormatTaskName {
    param($taskName)
    write-host "Executing Task: $taskName" -foregroundcolor Green
}

properties {
	$baseDir  = resolve-path ./
    $publishDir = "$baseDir\publish"

	$slnFile = "$basedir\MongoDB.OData.sln"
	$projectFile = "$baseDir\src\MongoDB.OData\MongoDB.OData.csproj"
	$assemblyInfoFile = "$baseDir\src\MongoDB.OData\Properties\AssemblyInfo.cs"
	
	$version = "$($projectParams.Product.Version.major).$($projectParams.Product.Version.minor).$($projectParams.Product.Version.release).$(Get-VcsRevision)"
	$vcsRevisionHash = Get-VcsRevisionHash
	$branchName = $(Get-VcsBranch)
}

task Build {
    Invoke-NuGetRestore -nuGetExePath "$YDeployDir/$($systemParams.Nuget.Path)" -slnFile $slnFile
	Invoke-MsBuild -msBuildPath msbuild -slnFile $slnFile -config $build_cfg -skipVcsRevision
}

task CreateNugetPackage {
	Remove-Artifacts -publishDir $publishDir
	Invoke-NuGetRestore -nuGetExePath "$YDeployDir/$($systemParams.Nuget.Path)" -slnFile $slnFile

	Set-AssemblyInfo -config "Release" -assemblyInfoFile $assemblyInfoFile -productName $projectParams.Product.Name -version $version -branch $branchName -revision $vcsRevisionHash

    Invoke-MsBuild `
	 -msBuildPath msbuild `
	 -appProjectFile $projectFile `
	 -config "Release" `
	 -publishDir $publishDir `
 	 -skipVcsRevision
	
	remove-item -path $publishDir\*.pdb
	remove-item -path $publishDir\*.xml
	
	Invoke-PsakeRunnerExecuteTemplateTask -taskname CreateNugetPackage -YDeployDir $YDeployDir -parameters @{ "NugetPackage" = $projectParams.NugetPackage; "hashedVersion" = $version }
	Invoke-PsakeRunnerExecuteTemplateTask -taskname PublishToNuget -YDeployDir $YDeployDir -parameters @{ "NugetPackage" = $projectParams.NugetPackage; }
}