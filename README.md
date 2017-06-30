# PDQ-Migration-Toolkit
Script to help you migrate your PDQ installation from One machine to another.

# Usage

./New-PDQMigration -OldServer [string] -NewServer [string] -System [string][array] -Fileshare [string]

#Example

./New-PDQMigration -OldServer server1.domain.com -NewServer server2.domain.com -System Deploy -Fileshare \\\files\pdq

