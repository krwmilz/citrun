package t::mem;

use strict;
use warnings;

use POSIX;		# NULL
use Win32::API;
use autodie;

our $os_allocsize = 64 * 1024;

use constant GENERIC_READ => 0x80000000;
use constant OPEN_EXISTING => 3;
use constant INVALID_HANDLE_VALUE => -1;
use constant PAGE_READONLY => 0x02;
use constant FILE_MAP_READ => 0x0004;

sub get_mem {
	my ($self, $procfile) = @_;

	# Roll our own Perl entry points into windows functions... wtf..
	my $CreateFile = Win32::API::More->new(
		'kernel32', 'HANDLE WINAPI CreateFile(
				LPCTSTR path,
				DWORD a,
				DWORD b,
				LPSECURITY_ATTRIBUTES c,
				DWORD d,
				DWORD e,
				HANDLE f)'
	);
	my $GetFileSize = Win32::API::More->new(
		'kernel32', 'HANDLE WINAPI GetFileSize(
				HANDLE hFile,
				LPWORD lpFileSizeHigh)'
	);
	my $CreateFileMapping = Win32::API::More->new(
		'kernel32', 'HANDLE WINAPI CreateFileMapping(
				HANDLE h,
				LPSECURITY_ATTRIBUTES lpAttr,
				DWORD prot,
				DWORD max_hi,
				DWORD max_lo,
				LPCTSTR lp)'
	);
	my $MapViewOfFile = Win32::API::More->new(
		'kernel32', 'UINT_PTR WINAPI MapViewOfFile(
				HANDLE h,
				DWORD acc,
				DWORD off_hi,
				DWORD off_lo,
				SIZE_T len)'
	);

	my $handle = $CreateFile->Call($procfile, GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
	die "CreateFile" if ($handle == INVALID_HANDLE_VALUE);

	my $size = $GetFileSize->Call($handle, NULL);
	#die "GetFileSize" if ($size == INVALID_FILE_SIZE);

	my $fm = $CreateFileMapping->Call($handle, NULL, PAGE_READONLY, 0, 0, NULL);
	die "CreateFileMapping" if ($fm == NULL);

	my $mem = $MapViewOfFile->Call($fm, FILE_MAP_READ, 0, 0, $size);
	die "MapViewOfFile" unless (defined $mem);

	$self->{mem} = unpack "P$size", pack 'Q', $mem;
	$self->{size} = $size;
}

1;
