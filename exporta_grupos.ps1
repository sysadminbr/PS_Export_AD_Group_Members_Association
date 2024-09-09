<#
# CITRA IT - EXCELÊNCIA EM TI
# SCRIPT PARA EXPORTAR EM CSV APENAS OS GRUPOS INFORMADOS E SEUS USUÁRIOS ASSOCIADOS DO AD
# AUTOR: luciano@citrait.com.br
# DATA: 30/07/2020
# EXAMPLO DE USO: Powershell -ExecutionPolicy ByPass -File C:\scripts\exporta_grupos.ps1
# ! Importante: Este script deve ser executado em um Controlador de Domínio !
#>


# The name of the file containing the groups we want to extract member associations
$group_list_filename = "grupos.txt"

# The name of the output file
$output_csv_filename = "exportado.csv"


# The Headers of the CSV file
$csv_output_headers = "GROUP_NAME;PERSON;LOGIN"

#-----------------------------------------------------------------------------------
# DO NOT MODIFY FROM HERE
#-----------------------------------------------------------------------------------


# Log Function
Function Log
{
    Param([String]$text)
    $timestamp = Get-Date -Format G
    Write-Host -ForegroundColor Green "$timestamp`: $text"
}

# Log Error Function
Function LogError
{
    Param([String]$text)
    $timestamp = Get-Date -Format G
    Write-Host -ForegroundColor Red "$timestamp`: $text"
}

# Raw Log Function
Function LogRaw
{
    Param([String]$text)
    Write-Host -ForegroundColor Yellow "$text"
}



# Identifying from where the script is being invocated
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Get the list of groups that we will work from the file containing the groups' names
$grupos = Get-Content -Path (Join-Path -Path $ScriptPath -ChildPath $group_list_filename)

# 2. Import Active Directory Module
Import-Module ActiveDirectory

# 3. Veirfy if the output file already exists. Delete it if already exists.
$output_filepath = Join-Path -Path $ScriptPath -ChildPath $output_csv_filename
If ( [system.IO.file]::exists( $output_filepath ) )
{
    [System.IO.File]::Delete($output_filepath)
}

# 4. Addint columns to output csv file
Add-Content -Path $output_filepath -encoding UTF8 -Value $csv_output_headers


# 5. Pull the groups and associated users from Active Directory
# ! TODO: Detect subgroups and users under subgroups (nested objects on target groups)
$grupos | ForEach-Object{
    $grupo_atual = $_
	
	# Validating if the group exists in active directory
	Try{
		Get-ADGroup $grupo_atual | Out-Null
	}Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
		LogError("Grupo $grupo_atual não encontrado!!")
		LogError("Verifique os nomes dos grupos para exportar e execute novamente este script.")
		LogError("Encerrando...")
		Log("Pressione qualquer tecla para finalizar")
		[Console]::ReadLine()
		Exit(0)
	}
	
	# Exporting the list of users of each group
    Log("Exportando lista de usuários do grupo $grupo_atual")
    Get-ADGroupMember -Identity $grupo_atual -Recursive | ForEach-Object{
		$member = $_
		LogRaw([String]::Format("Encontrado membro {0}", $member.Name))
		$content_line = [String]::Format("{0};{1};{2}", $grupo_atual, $member.Name, $member.SamAccountName)
		Add-Content -Path $output_filepath -Encoding UTF8 -Value $content_line
		
		
	}
}

Log("====-------   EXPORTAÇÃO FINALIZADA   -------====")
Log("Pressione qualquer tecla para finalizar")
[Console]::ReadLine()
