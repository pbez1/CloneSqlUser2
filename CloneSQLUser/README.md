# CloneSQLUser
Clones SQL permissions from an existing user and applies them to another user.

## Usage:
### Description
This function gathers all of -FromUser's permission in the specified SQL Server -ServerInstance and returns a formatted string that contains a SQL script
that will duplicate and grant those permissions to -ToUser.  

There are a couple of options with regard to where that SQL script is written:
1) If the -OutputPath parameter is not supplied, the script will be returned to the standard output device which, in most cases, is the user's monitor screen.
2) If the -OutputPath parameter is supplied, the script will be written to a file with a default file name at the location described in the -OutputPath 
parameter.  (Note: the -OutputPath should *not* contain the file name.)
3) If the -FileName parameter is supplied along with the -OutputPath parameter, the resulting script will be written to a file with the specified name in the
location specified by the -OutputPath parameter.  Note: If the user requests permissions from more than one SQL Server, the -FileName parameter is ignored
and default file names are used for each of the resulting files (one for each SQL Server).

### Parameters:
#### ServerInstance
<pre>This is the name of the server that will receive the snap mount.  This parameter can accept a list of servers separated by a comma.  Permissions from
each server will be returned and if an -OutputPath parameter is provided the output will be written to separate files.  (Note, if multiple servers are
specified, the -FileName parameter is ignored and default files names are used.)</pre>

#### FromUser
<pre>This is the name of the user from which permissions will be cloned.</pre>

#### ToUser
<pre>This is the name of the user who will receive the new cloned permissions.</pre>

#### OutputPath
<pre>This is the UNC path where permissions files will be written.  It should NOT contain a file name!</pre>

#### FileName
<pre>This is the name of the file that will be written to the OutputPath location and will contain the T-SQL code to create the permissions for the new user.  (Note: this parameter is only used if the user supplies one and only one SQL Server Instance in the -ServerInstance parameter.  Otherwise, the -FileName parameter is ignored and default files names are used.)</pre>
