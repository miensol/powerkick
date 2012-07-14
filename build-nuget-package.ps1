rm -Recurse -Force .\src\logs -ErrorAction SilentlyContinue
rm -Recurse -Force .\temp -ErrorAction SilentlyContinue
mkdir .\temp
$temp = "$(pwd)\temp"
cp .\src\ $temp\tools -Recurse 
cp powerkick.nuspec $temp
pushd $temp
nuget pack
cp *.nupkg ..\
popd
rm -Recurse -Force .\temp
