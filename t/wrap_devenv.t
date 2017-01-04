#
# Try and wrap devenv with citrun_wrap.
#
use strict;
use warnings;
use Test::Cmd;
use Test::More;

if ($^O eq "MSWin32") {
	plan tests => 1;
} else {
	plan skip_all => 'win32 only';
}

my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.vcxproj', <<'EOF' );
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="12.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup>
    <ProjectConfiguration Include="Debug|Win32">
      <Configuration>Debug</Configuration>
      <Platform>Win32</Platform>
    </ProjectConfiguration>
    <ProjectConfiguration Include="Release|Win32">
      <Configuration>Release</Configuration>
      <Platform>Win32</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <PropertyGroup Label="Globals">
    <ProjectGuid>{57E3F5BB-8348-4AE5-AFA1-12C2C7BCA0CC}</ProjectGuid>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.default.props" />
  <PropertyGroup>
    <ConfigurationType>Application</ConfigurationType>
    <PlatformToolset>v140</PlatformToolset>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />
  <ItemGroup>
    <ClCompile Include="main.cpp" />
  </ItemGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Targets" />
</Project>
EOF

$wrap->write( 'main.c', 'int main(void) { return 0; }' );

$wrap->run( args => 'devenv /useenv main.vcxproj /Build', chdir => $wrap->curdir );

print $wrap->stdout;
print $wrap->stderr;
is( $? >> 8,	1,	'is citrun_wrap exit code 1' );
