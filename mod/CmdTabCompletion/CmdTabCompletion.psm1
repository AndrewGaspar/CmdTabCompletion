using module CmdUsageSyntax
using module TabExpansionPlusPlus

$Script:CompletionRegistrations = @{}

function PoshNativeCompleteCommand {
    Param(
        $wordToComplete,
        $commandAst,
        $cursor,
        $depth,
        [PSCustomObject]$commandDescription
    )
    
    if($commandAst.CommandElements.Count -le 2) {
        $usage = "$($commandDescription.command) $($commandDescription.usage)" | New-CmdUsageSyntaxNode | Format-CmdUsageSyntax
        
        & {
        
            foreach($element in $usage.Elements) {
                if($element -is [ParameterUsage]) {
                    New-CompletionResult $element.Parameter $element.Parameter
                    
                    # [System.Management.Automation.CompletionResult]::new(
                    #     $element.Parameter,
                    #     $element.Parameter,
                    #     "Parameter",
                    #     $element.Parameter
                    # )
                }
            }
        
            foreach($subCommand in $commandDescription.sub_commands)
            {
                [System.Management.Automation.CompletionResult]::new(
                    $subCommand.command,
                    $subCommand.command,
                    "Command",
                    $subCommand.command
                )
            }
        } | ? { $_.CompletionText -like "$wordToComplete*"}
    }
}

function Register-CmdTabCompletion {
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [PSCustomObject]$Description
    )
    
    $Script:CompletionRegistrations[$Description.command] = $Description
    
    Register-ArgumentCompleter `
        -CommandName $Description.command `
        -Native `
        -ScriptBlock {
            Param(
                $wordToComplete,
                $commandAst,
                $cursor)
                
            $commandDescription = Get-CmdTabCompletion $commandAst.GetCommandName()
            
            PoshNativeCompleteCommand $wordToComplete $commandAst $cursor 1 $commandDescription
        }
}

function Read-CmdTabCompletion {
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [string]$Path
    )
    
    Get-Content $Path | ConvertFrom-Json 
}

function Get-CmdTabCompletion {
    Param(
        [string]$CommandName = "*"
    )
    
    $hash = $Script:CompletionRegistrations
    
    $hash.Keys | 
        Where-Object { $_ -like $CommandName } | 
        ForEach-Object { $hash[$_] }
}

