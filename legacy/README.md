Run the `setup_ai_helper.sh` script and follow the instructions.
Once the script finishes downloading the models to your machine, you'll have access to the helpwith command.
## USE LIKE THIS:
```
helpwith <your prompt here>
```
## Example cli output:
```
~$: helpwith copy contents of one folder into another, only the contents not the folders
Thinking...

To copy the contents of one folder into another in Linux, you can use the `cp` command. The basic syntax is:
\```
cp [-options] source destination
\```
Where `-options` are optional parameters that control the behavior of the command, and `source` is the directory or file that you want to copy, and `destination` is the 
directory where you want to copy the contents.

For example, let's say you have a folder called `myfolder` with some files and subfolders inside it, and you want to copy only the contents of this folder into another 
folder called `newfolder`. You can use the following command:
\```
cp -r myfolder/* newfolder
\```
```
