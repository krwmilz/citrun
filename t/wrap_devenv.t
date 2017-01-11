#
# Try and wrap devenv with citrun_wrap.
# TODO: devenv uses response files (not supported right now).
#
use strict;
use warnings;
use t::utils;

if ($^O eq "MSWin32") {
	plan tests => 3;
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

$wrap->write( 'main.cpp', 'int main(void) { return 0; }' );

$wrap->run( args => 'devenv /useenv main.vcxproj /Build', chdir => $wrap->curdir );
print $wrap->stdout;

# XXX: devenv uses response files so we don't detect any source files.
my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Modified command line is ''
No source files found on command line.
Forked compiler ''
>> citrun_inst
Compilers path = ''
PATH = ''
Modified command line is ''
No source files found on command line.
Forked compiler ''
EOF

my $log_file;
$wrap->read( \$log_file, 'citrun.log' );
$log_file = clean_citrun_log($log_file);

eq_or_diff( $log_file, $log_good,	'is devenv citrun.log identical' );
is( $wrap->stderr,	'',	'is citrun_wrap devenv stderr silent' );
is( $? >> 8,	0,	'is citrun_wrap exit code 0' );
