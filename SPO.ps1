﻿# Functions for SharePoint Online


# Jul 17th 2019
function Get-SPOSiteGroups
{
<#
    .SYNOPSIS
    Gets list of groups of SharePoint Online site

    .DESCRIPTION
    Gets list of groups of SharePoint Online site the user has access to.

    .Parameter Site
    Url of the SharePoint site

    .Parameter AuthHeader
    SharePoint Online authentication header
    
    .Example
    PS C:\>$auth=Get-AADIntSPOAuthenticationHeader -Site https://company.sharepoint.com
    PS C:\>Get-AADIntSPOSiteGroups -Site https://company.sharepoint.com/sales -AuthHeader $auth
#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Site,
        [Parameter(Mandatory=$False)]
        [String]$AuthHeader,
        [Parameter(Mandatory=$False)]
        [String]$AccessToken
    )
    Process
    {
        # Check the site url
        if($Site.EndsWith("/"))
        {
            $Site=$Site.Substring(0,$Site.Length-1)
        }

        $siteDomain=$Site.Split("/")[2]

        if(![string]::IsNullOrEmpty($AuthHeader))
        {
            # Create a WebSession object
            $siteSession = Create-WebSession -SetCookieHeader $AuthHeader -Domain $siteDomain
        }
        else
        {
            # Get from cache if not provided
            $AccessToken = Get-AccessTokenFromCache -AccessToken $AccessToken -Resource $site -ClientId "9bc3ab49-b65d-410a-85ad-de819febfddc"
            $headers=@{
                "Authorization" = "Bearer $AccessToken"
            }
        }

        # Invoke the request
        $response=Invoke-WebRequest -UseBasicParsing -Uri "$Site/_api/web/sitegroups" -Method Get -WebSession $siteSession -ErrorAction SilentlyContinue -Headers $headers

        if($response.StatusCode -eq 200)
        {
            [xml]$response=$response.Content


            $users=New-Object System.Collections.ArrayList

            # Loop through the entries
            foreach($entry in $response.feed.entry)
            {
                $attributes = @{}
                $attributes["Id"] = $entry.content.properties.Id.'#Text'
                $attributes["IsHiddenInUI"] = $entry.content.properties.IsHiddenInUI.'#Text' -eq "true"
                $attributes["LoginName"] = $entry.content.properties.LoginName
                $attributes["Title"] = $entry.content.properties.Title
                $attributes["PrincipalType"] = $entry.content.properties.PrincipalType.'#Text'
                $attributes["OwnerTitle"] = $entry.content.properties.OwnerTitle
                $attributes["Description"] = $entry.content.properties.Description.'#Text'
                
                $attributes["AllowMembersEditMembership"] = $entry.content.properties.AllowMembersEditMembership.'#Text' -eq "true"
                $attributes["AllowRequestToJoinLeave"] = $entry.content.properties.AllowRequestToJoinLeave.'#Text' -eq "true"
                $attributes["AutoAcceptRequestToJoinLeave"] = $entry.content.properties.AutoAcceptRequestToJoinLeave.'#Text' -eq "true"
                $attributes["OnlyAllowMembersViewMembership"] = $entry.content.properties.OnlyAllowMembersViewMembership.'#Text' -eq "true"
           
                $users+=New-Object PSObject -Property $attributes
            }

            # Return
            return $users
        }
    }
}

# Jul 17th 2019
function Get-SPOSiteUsers
{
<#
    .SYNOPSIS
    Gets list of users of SharePoint Online site

    .DESCRIPTION
    Gets list of users of SharePoint Online site the user has access to.

    .Parameter Site
    Url of the SharePoint site

    .Parameter AuthHeader
    SharePoint Online authentication header
    
    .Example
    PS C:\>$auth=Get-AADIntSPOAuthenticationHeader -Site https://company.sharepoint.com
    PS C:\>Get-AADIntSPOSiteUsers -Site https://company.sharepoint.com/sales -AuthHeader $auth
#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Site,
        [Parameter(Mandatory=$False)]
        [String]$AuthHeader,
        [Parameter(Mandatory=$False)]
        [String]$AccessToken
    )
    Process
    {
        # Check the site url
        if($Site.EndsWith("/"))
        {
            $Site=$Site.Substring(0,$Site.Length-1)
        }

        $siteDomain=$Site.Split("/")[2]

        if(![string]::IsNullOrEmpty($AuthHeader))
        {
            # Create a WebSession object
            $siteSession = Create-WebSession -SetCookieHeader $AuthHeader -Domain $siteDomain
        }
        else
        {
            # Get from cache if not provided
            $AccessToken = Get-AccessTokenFromCache -AccessToken $AccessToken -Resource "https://$Tenant.sharepoint.com/" -ClientId "9bc3ab49-b65d-410a-85ad-de819febfddc"
            $headers=@{
                "Authorization" = "Bearer $AccessToken"
            }
        }

        # Invoke the request
        $response=Invoke-WebRequest -UseBasicParsing -Uri "$Site/_api/web/siteusers" -Method Get -WebSession $siteSession -Headers $headers -ErrorAction SilentlyContinue

        if($response.StatusCode -eq 200)
        {
            [xml]$response=$response.Content


            $users=New-Object System.Collections.ArrayList

            # Loop through the entries
            foreach($entry in $response.feed.entry)
            {
                $attributes = @{}
                $attributes["Id"] = $entry.content.properties.Id.'#Text'
                $attributes["IsHiddenInUI"] = $entry.content.properties.IsHiddenInUI.'#Text' -eq "true"
                $attributes["LoginName"] = $entry.content.properties.LoginName
                $attributes["Title"] = $entry.content.properties.Title
                $attributes["PrincipalType"] = $entry.content.properties.PrincipalType.'#Text'
                $attributes["Email"] = $entry.content.properties.Email
                $attributes["IsEmailAuthenticationGuestUser"] = $entry.content.properties.IsEmailAuthenticationGuestUser.'#Text' -eq "true"
                $attributes["IsShareByEmailGuestUser"] = $entry.content.properties.IsShareByEmailGuestUser.'#Text' -eq "true"
                $attributes["IsSiteAdmin"] = $entry.content.properties.IsSiteAdmin.'#Text' -eq "true"
                $attributes["NameId"] = $entry.content.properties.UserId.NameId
                $attributes["NameIdIssuer"] = $entry.content.properties.UserId.NameIdIssuer
            

                if($entry.content.properties.UserPrincipalName.GetType().Name  -eq "String")
                {
                    $attributes["UserPrincipalName"] = $entry.content.properties.UserPrincipalName
                }
                else
                {
                    $attributes["UserPrincipalName"] = ""
                }
            
                $users+=New-Object PSObject -Property $attributes
            }

            # Return
            return $users
        }
    }
}

# Jul 18th 2019
function Get-SPOUserProperties
{
<#
    .SYNOPSIS
    Gets properties of SharePoint Online user

    .DESCRIPTION
    Gets properties of SharePoint Online user using PeopleManager API

    .Parameter Site
    Url of the SharePoint site

    .Parameter User
    SharePoint Online authentication header

    .Parameter AuthHeader
    LoginName of the user in format "i:0i.t|00000003-0000-0ff1-ce00-000000000000|app@sharepoint"
    
    .Example
    PS C:\>$auth=Get-AADIntSPOAuthenticationHeader -Site https://company.sharepoint.com
    PS C:\>Get-AADIntSPOUserProperties -Site https://company.sharepoint.com/sales -AuthHeader $auth -User "i:0i.t|00000003-0000-0ff1-ce00-000000000000|app@sharepoint"
#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Site,
        [Parameter(Mandatory=$True)]
        [String]$User,
        [Parameter(Mandatory=$True)]
        [String]$AuthHeader
    )
    Process
    {
        # Check the site url
        if($Site.EndsWith("/"))
        {
            $Site=$Site.Substring(0,$Site.Length-1)
        }

        $User=$User.Replace("#","%23")

        $siteDomain=$Site.Split("/")[2]

        # Create a WebSession object
        $siteSession = Create-WebSession -SetCookieHeader $AuthHeader -Domain $siteDomain

        # Invoke the request
        $response=Invoke-WebRequest -UseBasicParsing -Uri "$Site/_api/sp.userprofiles.peoplemanager/getpropertiesfor(@v)?@v='$User'" -Method Get -WebSession $siteSession -ErrorAction SilentlyContinue 

        if($response.StatusCode -eq 200)
        {
            [xml]$response=$response.Content
            $entry=$response.entry

            $attributes = [ordered]@{}

            $attributes["Updated"] = $response.entry.Updated
            $attributes["Author"] = $response.entry.Author.Name

            $properties = $response.entry.content.properties
            $attributes["AccountName"] = $properties.AccountName
            $attributes["DirectReports"] = Create-ListFromCollection $properties.DirectReports
            $attributes["DisplayName"] = $properties.DisplayName
            $attributes["Email"] = $properties.Email
            $attributes["ExtendedManagers"] = Create-ListFromCollection $properties.ExtendedManagers
            $attributes["ExtendedReports"] = Create-ListFromCollection $properties.ExtendedReports
            $attributes["IsFollowed"] = $properties.IsFollowed -eq "true"
            #$attributes["LatestPost"] = $properties.LatestPost
            $attributes["Peers"] = Create-ListFromCollection $properties.Peers
            #$attributes["PersonalSiteHostUrl"] = $properties.PersonalSiteHostUrl
            $attributes["PersonalUrl"] = [System.Net.WebUtility]::UrlDecode($properties.PersonalUrl)
            $attributes["PictureUrl"] = [System.Net.WebUtility]::UrlDecode($properties.PictureUrl)
            $attributes["UserUrl"] = [System.Net.WebUtility]::UrlDecode($properties.UserUrl)
            $attributes["Title"] = $properties.Title

            # Loop through the userprofile fields
            foreach($up in $properties.UserProfileProperties.Element)
            {
                $name = $up.Key
                $value = $up.Value
                $attributes[$name] = $value
            }

            # Return            
            New-Object PSObject -Property $attributes
        }
    }
}

# Jun 10th 2020
function Get-SPOSiteUserProperties
{
<#
    .SYNOPSIS
    Gets the SPO user properties

    .DESCRIPTION
    Gets the SPO user properties

    .Parameter Site
    Url of the SharePoint site

    .Parameter AuthHeader
    SharePoint Online authentication header

    .Parameter AccessToken
    SharePoint Online Access Token
    
    .Example
    PS C:\>$auth=Get-AADIntSPOAuthenticationHeader -Site https://company.sharepoint.com
    PS C:\>Get-AADIntSPOSiteGroups -Site https://company.sharepoint.com/sales -AuthHeader $auth

    .Example
    PS C:\>$at=Get-AADIntAccessTokenForSPO
    PS C:\>Get-AADIntSPOSiteGroups -Site https://company.sharepoint.com/sales -AccessToken $at
#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Site,
        [Parameter(Mandatory=$True)]
        [String]$UserName,
        [Parameter(Mandatory=$False)]
        [String]$AuthHeader,
        [Parameter(Mandatory=$False)]
        [String]$AccessToken
    )
    Process
    {
        # Check the site url
        if($Site.EndsWith("/"))
        {
            $Site=$Site.Substring(0,$Site.Length-1)
        }

        $siteDomain=$Site.Split("/")[2]

        # Check the username format
        if(!$UserName.StartsWith("i"))
        {
            $UserName="i:0%23.f|membership|$UserName"
        }

        if(![string]::IsNullOrEmpty($AuthHeader))
        {
            # Create a WebSession object
            $siteSession = Create-WebSession -SetCookieHeader $AuthHeader -Domain $siteDomain
        }
        else
        {
            # Get from cache if not provided
            $AccessToken = Get-AccessTokenFromCache -AccessToken $AccessToken -Resource "https://$Tenant.sharepoint.com/" -ClientId "9bc3ab49-b65d-410a-85ad-de819febfddc"
            $headers=@{
                "Authorization" = "Bearer $AccessToken"
            }
        }

        # Invoke the request
        $response=Invoke-WebRequest -UseBasicParsing -Uri "$Site/_api/SP.UserProfiles.PeopleManager/GetPropertiesFor(accountName=@v)?@v='$UserName'" -Method Get -WebSession $siteSession -ErrorAction SilentlyContinue -Headers $headers

        if($response.StatusCode -eq 200)
        {
            # Get the response
            [xml]$response=$response.Content

            # Create the attributes varialbe
            $attributes=@{}

            # Loop through the elements
            foreach($element in $response.entry.content.properties.UserProfileProperties.element)
            {
                $key=$element.Key
                $value=$element.Value

                $attributes[$key] = $value
            }

            # Sort by the key
            $attributes_sorted=[ordered]@{}
            $entries = $attributes.GetEnumerator() | sort Key
            foreach($entry in $entries)
            {
                $attributes_sorted[$entry.Name]=$entry.Value
            }

            # Return
            return New-Object psobject -Property $attributes_sorted
        }
    }
}

# Jun 10th 2020
function Set-SPOSiteUserProperty
{
<#
    .SYNOPSIS
    Sets the SPO user property

    .DESCRIPTION
    Sets the SPO user property

    .Parameter Site
    Url of the SharePoint site

    .Parameter AuthHeader
    SharePoint Online authentication header

    .Parameter AccessToken
    SharePoint Online Access Token

    .Parameter Property
    Property name
    
    .Parameter Value
    Property value

    .Example
    PS C:\>$auth=Get-AADIntSPOAuthenticationHeader -Site https://company.sharepoint.com
    PS C:\>Set-AADIntSPOUserProperty -Site https://company.sharepoint.com/sales -AuthHeader $auth -UserName user@company.com -Property "AboutMe" -Value "I'm a happy SPO user!"

    .Example
    PS C:\>$at=Get-AADIntAccessTokenForSPO
    PS C:\>Set-AADIntSPOUserProperty -Site https://company.sharepoint.com/sales -AccessToken $at -UserName user@company.com -Property "AboutMe" -Value "I'm a happy SPO user!"
#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Site,
        [Parameter(Mandatory=$True)]
        [String]$UserName,
        [Parameter(Mandatory=$False)]
        [String]$AuthHeader,
        [Parameter(Mandatory=$False)]
        [String]$AccessToken,
        [Parameter(Mandatory=$True)]
        [String]$Property,
        [Parameter(Mandatory=$False)]
        [String]$Value
    )
    Process
    {
        # Get the digest
        #$digest = Get-SPODigest -AccessToken $AccessToken -Cookie $Cookie -Site $Site
        # Set the headers
        $headers=@{
        #    "X-RequestDigest" = $digest
        }

        # Check the site url
        if($Site.EndsWith("/"))
        {
            $Site=$Site.Substring(0,$Site.Length-1)
        }

        $siteDomain=$Site.Split("/")[2]

        # Check the username format
        if(!$UserName.StartsWith("i"))
        {
            $UserName="i:0#.f|membership|$UserName"
        }

        if(![string]::IsNullOrEmpty($AuthHeader))
        {
            # Create a WebSession object
            $siteSession = Create-WebSession -SetCookieHeader $AuthHeader -Domain $siteDomain
        }
        else
        {
            # Get from cache if not provided
            $AccessToken = Get-AccessTokenFromCache -AccessToken $AccessToken -Resource "https://$Tenant.sharepoint.com/" -ClientId "9bc3ab49-b65d-410a-85ad-de819febfddc"
            $headers["Authorization"] = "Bearer $AccessToken"
        }

        # Create the body
        $body=@{
            "accountName" =   "$UserName"
            "propertyName" =  $Property
            "propertyValue" = $Value
        }

        # Invoke the request
        $response=Invoke-WebRequest -UseBasicParsing -Uri "$Site/_api/SP.UserProfiles.PeopleManager/SetSingleValueProfileProperty" -Method Post -WebSession $siteSession -ErrorAction SilentlyContinue -Headers $headers -ContentType "application/json" -Body ($body | ConvertTo-Json)

        if($response.StatusCode -eq 200)
        {
            # All good, nothing to return :)
        }
    }
}

