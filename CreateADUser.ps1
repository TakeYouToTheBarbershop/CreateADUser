Add-Type -AssemblyName System.Web

#This assumes the username format is "firstname.lastname". Obviously this can be tweaked for your own environment.
$user_first = Read-Host "Input the user first name "
$user_last = Read-Host "Input the user last name "

#Constructs strings for different fields
$given_name = $user_first.substring(0,1).toupper() + $user_first.substring(1).tolower()
$sname = $user_last.substring(0,1).toupper() + $user_last.substring(1).tolower()
$name = $given_name + " " + $sname
$email = $user_first + "." + $user_last + "@yourcompany.com"
$sam_account = $user_first + '.' + $user_last
$upn = $user_first + '.' + $user_last + "@yourcompany.com"

while($true){
    $is_AD_user = Read-Host "Will the user be using their AD account? y or n"
    $is_AD_user = $is_AD_user.tolower()

    if($is_AD_user -eq "y"){
        #Generate default password for AD account
        $birth_date = Read-Host "Input user birthdate (MMYY)"
        $default_pass = "YourDefaultPass" + $birth_date + "!" | ConvertTo-SecureString -AsPlainText -Force

        #This creates the AD user with the given variables
        New-ADUser `
        -Name $name `
        -GivenName $given_name `
        -Surname $sname `
        -EmailAddress $email `
        -SamAccountName $sam_account `
        -UserPrincipalName $upn `
        -AccountPassword $default_pass `
        -ChangePasswordAtLogon $true `
        -Enabled $True
        break
    } elseif($is_AD_user -eq "n"){
        #If the user will not be signing in with their AD account, a random password will be set to their account
        $random_pass = [System.Web.Security.Membership]::GeneratePassword(20, 6) | ConvertTo-SecureString -AsPlainText -Force

        New-ADUser `
        -Name $name `
        -GivenName $given_name `
        -Surname $sname `
        -EmailAddress $email `
        -SamAccountName $sam_account `
        -UserPrincipalName $upn `
        -AccountPassword $random_pass `
        -ChangePasswordAtLogon $true `
        -Enabled $True
        break
    } 
}

#Gets Office department to determine OU placement. This will need to be tweaked depending on the structure of your Active Directory.
function Get-Office-Dept {
    while ($true) {
        $choose_dept = Read-Host "Which department is the user in? Enter the corresponding number`r`n1. Example`r`n2. Example`r`n"
        $choose_dept = [int]$choose_dept
        $office_list = @([Input a list of company departments here])
        
        if ($choose_dept -In 1..22 ) {
            $office_dept = $office_list[$choose_dept]
            $office_ou_path = "OU=" + $office_dept + "[Input your OU path here]"
            Write-Host -ForegroundColor Green "Office department successfully chosen..."
            break
        } else {
            Write-Host -ForegroundColor Red "Invalid Entry. Please try again`r`n"
        }
    }
    return $office_ou_path
}

#Adds the user to the chosen OU and adds any groups. If you have multiple groups for different OUs and users, you could expand on this to add a group selection tied to specific OUs
$office_ou_path = Get-Office-Dept

Get-ADUser -Identity $sam_account | Move-ADObject -TargetPath $office_ou_path
Add-ADGroupMember -Identity [Your group here] -Members $sam_account

Write-Host -ForegroundColor Green "User creation complete! Exiting..."
Start-Sleep -Seconds 3

