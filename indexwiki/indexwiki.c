// wiktmkrawidx (-d) en 20110321
//
// scans a MediaWiki XML dump file the latest revision of each article

// creates three index files
//	xxx-off.raw
//		a "seek_type" (64 bit) absolute offset to the start of each <page> line
//		an "unsigned long" (32 bit) relative offset to the latest <revision> line of the <page> 
//	xxx-all.txt
//		a UTF-8 text file with the page titles in the order found in the dump
//	xxx-all-off.raw
//		an "unsigned long" (32 bit) absolute offset to the start of each title in xxx-all.txt
//
// TODO config file should support separate dump and index paths
// TODO prompt user if output files already exist
// TODO decide frequency of progress reports from type and size of dump file
// TODO make it possible to run steps separately
// TODO how best to handle wikis with odd names such as "mediawikiwiki", the old daily wiktionary dumps, the hitchwiki dumps
// TODO write metadata to .txt file (number of pages, revs; max page offset, rev offset, number of bits needed for each)
// TODO instead of strdup()ing each title into its own node, malloc() big chunks of memory as nodes and concatenate lots of titles in them separated only by \0
// TODO   titles longer than the chunk size need to be special-case'd
// TODO instead of waiting till we have all the titles then putting them in an array and sorting them, use a tree structure
// TODO report more factoids: lowest page id, revision id, longest title
// TODO support dump file coming via a pipe

#include "stdafx.h"

struct stringnode {
	struct stringnode *next;
	char title[0];
};

// used by both process_dump() and sort_titles()
static struct stringnode * 	g_title_list_head = NULL;
static struct stringnode **	g_title_list_tail_address = &g_title_list_head;

// used by both sort_titles() and comparator()
static char **g_title_array;

// forward declarations
int process_dump(int opt_d, int opt_h, FILE *dump_file, FILE *off_raw_file, FILE *all_txt_file, FILE *all_off_raw_file, const _TCHAR *all_idx_raw_filename);
int check_range_and_length(const _TCHAR *s, _TCHAR minchar, _TCHAR maxchar, int minlen, int maxlen);
_TCHAR *get_config_filename(void);
int parse_args(const int argc, _TCHAR* argv[], int *opt_d, int *opt_h, _TCHAR **dumplang, _TCHAR **dumpproj, _TCHAR **dumpdate);
int read_config(_TCHAR **dumppath, _TCHAR **indexpath);
char *myreadline(FILE *);
char *alloc_sprintf(const char *fmt, ...);
_TCHAR *alloc_stprintf(const _TCHAR *fmt, ...);
_TCHAR *_tcsdup_from_A(const char *);
const char *strdup_to_list(struct stringnode ***, const char *);
static int comparator(const void *, const void *);
int sort_titles(int opt_d, int pc, FILE *all_txt_file, FILE *all_idx_raw_file);

#ifndef _WIN32
#define _tcsdup_from_A _tcsdup
#endif

// this tool doesn't need any Unicode console parameters
int _tmain(int argc, _TCHAR* argv[])
{
	int opt_d = 0;				// enable for debugging
	int opt_h = 0;				// set if indexing a pages-meta-history rather than pages-articles
	_TCHAR *dumplang = NULL;	// wmain means UTF-16 console parameters
	_TCHAR *dumpproj = NULL;	// wmain means UTF-16 console parameters
	_TCHAR *dumpdate = NULL;	// wmain means UTF-16 console parameters
	_TCHAR *dumppath = NULL;	// allows Unicode paths
	_TCHAR *indexpath = NULL;	// allows Unicode paths

#ifdef _WIN32
	_setmode(_fileno(stderr), _O_U16TEXT);
#endif

	//_ftprintf(stderr, _T("** size of seek_type is %d\n"), sizeof(seek_type));

	if (parse_args(argc, argv, &opt_d, &opt_h, &dumplang, &dumpproj, &dumpdate)) {

		if (read_config(&dumppath, &indexpath)) {
			//if (opt_d) _ftprintf(stderr, _T("** read config OK\n"));

			// create filename strings
			_TCHAR *dump_filename = alloc_stprintf(_T("%s%s%s-%s-pages-%s.xml"), dumppath, dumplang, dumpproj, dumpdate, opt_h ? _T("meta-history") : _T("articles"));
			_TCHAR *off_raw_filename = alloc_stprintf(_T("%s%s%s-off.raw"), indexpath, dumplang, dumpdate);
			_TCHAR *all_txt_filename = alloc_stprintf(_T("%s%s%s-all.txt"), indexpath, dumplang, dumpdate);
			_TCHAR *all_off_raw_filename = alloc_stprintf(_T("%s%s%s-all-off.raw"), indexpath, dumplang, dumpdate);
			_TCHAR *all_idx_raw_filename = alloc_stprintf(_T("%s%s%s-all-idx.raw"), indexpath, dumplang, dumpdate);

			if (dump_filename && off_raw_filename && all_txt_filename && all_off_raw_filename) {

				// open input file
				FILE *dump_file = _tfopen(dump_filename, _T("rb"));					// crlf translation would interfere with ftell()
				//MessageBoxW(NULL, dump_filename, L"hippietrail", MB_OK);

				_ftprintf(stderr, _T("%s : %s\n"), dump_filename, dump_file ? _T("yes") : _T("no"));

				if (dump_file) {
					// output files
					FILE *off_raw_file;
					const _TCHAR *off_raw_state = NULL;
					FILE *all_txt_file;
					const _TCHAR *all_txt_state = NULL;
					FILE *all_off_raw_file;
					const _TCHAR *all_off_raw_state = NULL;

					// check if output files already exist
					off_raw_file = _tfopen(off_raw_filename, _T("rb"));
					all_txt_file = _tfopen(all_txt_filename, _T("rb"));
					all_off_raw_file = _tfopen(all_off_raw_filename, _T("rb"));

					if (off_raw_file) off_raw_state = _T("overwrite");
					if (all_txt_file) all_txt_state = _T("overwrite");
					if (all_off_raw_file) all_off_raw_state = _T("overwrite");

					// close output files
					if (off_raw_file) fclose(off_raw_file);
					if (all_txt_file) fclose(all_txt_file);
					if (all_off_raw_file) fclose(all_off_raw_file);

					// open output files for writing
					off_raw_file = _tfopen(off_raw_filename, _T("wb"));			// raw binary data
					all_txt_file = _tfopen(all_txt_filename, _T("wb"));			// crlf translation would interfere with ftell()
					all_off_raw_file = _tfopen(all_off_raw_filename, _T("wb"));	// raw binary data

					if (!off_raw_state) off_raw_state = off_raw_file ? _T("create") : _T("error");
					if (!all_txt_state) all_txt_state = all_txt_file ? _T("create") : _T("error");
					if (!all_off_raw_state) all_off_raw_state = all_off_raw_file ? _T("create") : _T("error");

					_ftprintf(stderr, _T("%s : %s\n%s : %s\n%s : %s\n"),
						off_raw_filename, off_raw_state,
						all_txt_filename, all_txt_state,
						all_off_raw_filename, all_off_raw_state);

					if (off_raw_file && all_txt_file && all_off_raw_file) {
						process_dump(opt_d, opt_h, dump_file, off_raw_file, all_txt_file, all_off_raw_file, all_idx_raw_filename);
					} /* if ( ... output files ... ) */

					// close output files
					if (off_raw_file) fclose(off_raw_file);
					if (all_txt_file) fclose(all_txt_file);
					if (all_off_raw_file) fclose(all_off_raw_file);

					// close input files
					fclose(dump_file);
				} /* if (dump_file) */
			} /* if ( ... filenames ... ) */

			if (dump_filename) free(dump_filename);
			if (off_raw_filename) free(off_raw_filename);
			if (all_txt_filename) free(all_txt_filename);
			if (all_off_raw_filename) free(all_off_raw_filename);
			if (all_idx_raw_filename) free(all_idx_raw_filename);
		}

		if (dumppath) free(dumppath);
		if (indexpath) free(indexpath);
	}

	if (dumplang) free(dumplang);
	if (dumpproj) free(dumpproj);
	if (dumpdate) free(dumpdate);

#ifdef _WIN32
	_CrtDumpMemoryLeaks();
#endif

	return 0;
}

int process_dump(int opt_d, int opt_h, FILE *dump_file, FILE *off_raw_file, FILE *all_txt_file, FILE *all_off_raw_file, const _TCHAR *all_idx_raw_filename)
{
	int pc = 0;							// page count
	int rc = 0;							// revision count for this page
	int rc_all = 0;						// revision count over all pages
	const char *title = NULL;					// dump files are always UTF-8
	int pid = -1;						// page ID
	seek_type poff;						// page offset
	int rid = -1;						// rev ID
	int roff = -1;						// rev offset

	seek_type biggest_poff = 0;
	int biggest_roff = 0;
	char *biggest_roff_title = NULL;	// since dumps are always UTF-8
	int most_revs = 0;
	char *most_revs_title = NULL;

	int state = 0;
	int progress_modulo = opt_h ? 1000 : 10000;
	int show_progress = 0;

	char *line;							// since dumps are always UTF-8
	int line_len;

	while (line = myreadline(dump_file)) {
		line_len = strlen(line);

		if (state == 0) {
			if (strstr(line, "<page>")) {
				++ pc;

				if ((pc % progress_modulo) == 0)
					show_progress = 1;

				state = 1;
				rc = 0;

				poff = ftello(dump_file) - line_len;
				biggest_poff = poff;

			} else if (strstr(line, "<mediawiki ")) {
				char *p1, *p2;	// dumps are always UTF-8
				double dump_version;

				if ((p1 = strstr(line, " version=\"")) != NULL && (p2 = strchr(p1+10, '"')) != NULL) {
					*p2 = '\0';
					dump_version = atof(p1+10);

					if (opt_d) {
						_ftprintf(stderr, _T("***** dumpfile xml version '%0.01f' *****\n"), dump_version);

						if (dump_version < 0.25) {
							_ftprintf(stderr, _T("** earlier than version 0.3, no <redirect> element support\n"));
						} else if (dump_version > 0.35) {
							_ftprintf(stderr, _T("** version 0.4 or later, <redirect> element support\n"));
						} else {
							_ftprintf(stderr, _T("** version 0.3, may or may not have <redirect> elements\n"));
						}
					}
				}
			}

		} else if (state == 1) {
			char *p1, *p2;					// dumps are always UTF-8

			if ((p1 = strstr(line, "<title>")) != NULL && (p2 = strstr(p1, "</title>")) != NULL) {
				*p2 = '\0';

				// TODO keep these in a linked list for the sorting phase
				//title = _strdup(p1 + 7);	// TODO check for failure
				title = strdup_to_list(&g_title_list_tail_address, p1 + 7);
				
			} else if ((p1 = strstr(line, "<id>")) != NULL && (p2 = strstr(p1, "</id>")) != NULL) {
				*p2 = '\0';
				pid = atoi(p1+4);
				
			}
			// # <redirect>, <restrictions> are possible

			if (title != NULL && pid != -1)
				state = 2;

		} else if (state == 2) {
			if (strstr(line, "<revision>")) {
				seek_type told;

				++ rc;

				state = 3;

				told = ftello(dump_file) - line_len;
				roff = (int)(told - poff);

				if (roff >= biggest_roff) {
					const char *temp = roff == biggest_roff ? "several pages" : title;

					biggest_roff = roff;

					if (biggest_roff_title == NULL || strcmp(temp, biggest_roff_title)) {
						if (biggest_roff_title)
							free(biggest_roff_title);
						biggest_roff_title = _strdup(temp);
					}
				}

				// set rid to -1 so we know to read the first <id> tag
				rid = -1;

			} else if (strstr(line, "</page>")) {
				long told = ftell(all_txt_file);

				fwrite(&poff, sizeof poff, 1, off_raw_file);
				fwrite(&roff, sizeof roff, 1, off_raw_file);

				// windows text files should have \r\n - unix should have just \n
#ifdef _WIN32
				fprintf(all_txt_file, "%s\r\n", title);
#else
				fprintf(all_txt_file, "%s\n", title);
#endif

				fwrite(&told, sizeof told, 1, all_off_raw_file);

				if (show_progress) {
					if (opt_d) {
						const _TCHAR *t;
#ifdef _WIN32
						t = _tcsdup_from_A(title);
#else
						t = title;
#endif
						_ftprintf(stderr, _T("%d (pid %d:rid %d) : 0x%016llx (%llu) : 0x%08x (%u) \"%s\" [%d revs]\n"),
							pc, pid, rid, (unsigned long long)poff, (unsigned long long)poff, roff, roff, t, rc);
#ifdef _WIN32
						free(t);
#endif
					}
					show_progress = 0;
				}

				state = 0;
				rc_all += rc;

				if (rc >= most_revs) {
					const char *temp = rc == most_revs ? "several pages" : title;

					most_revs = rc;

					if (most_revs_title == NULL || strcmp(temp, most_revs_title)) {
						if (most_revs_title)
							free(most_revs_title);
						most_revs_title = _strdup(temp);
					}
				}

				// TODO keep these in a linked list for the sorting phase
				//if (title) free(title);
				title = NULL;

				pid = -1;
				rid = -1;
			}
			// <redirect>, <restrictions> are possible
		} else if (state == 3) {
			char *p1, *p2;	// dump file is byte-based UTF-8
			if ((p1 = strstr(line, "<id>")) != NULL && (p2 = strstr(p1, "</id>")) != NULL) {
				*p2 = '\0';

				// only take the revision id, not the contributor id!
				if (rid == -1)
					rid = atoi(p1+4);

				} else if (strstr(line, "</revision>")) {
				state = 2;
			}

		} else {
			if (opt_d)
				_ftprintf(stderr, _T("** unknown state '%d'\n"), state);
		}

		free(line);
	} /* while ( ... myreadline ... ) */

	// sorting
	{
		// open output files
		FILE *all_idx_raw_file = _tfopen(all_idx_raw_filename, _T("wb"));	// raw binary data

		_ftprintf(stderr, _T("%s : %s\n"),
			all_idx_raw_filename, all_idx_raw_file ? _T("yes") : _T("no"));

		if (all_idx_raw_file) {
			sort_titles(opt_d, pc, all_txt_file, all_idx_raw_file);
		} /* if ( ... output files ... ) */

		// close output files
		if (all_idx_raw_file) fclose(all_idx_raw_file);

		{
			// free all the page titles
			struct stringnode *item = g_title_list_head, *next;
			
			while (item != NULL) {
				next = item->next;
				free(item);
				item = next;
			}
		}
	}

	if (opt_d) {
		_ftprintf(stderr, _T("%d pages and %d revisions (average %0.02f revisions per page)\n"), pc, rc_all, (float)(pc == 0 ? -1 : (float)rc_all / (float)pc));
		_ftprintf(stderr, _T("biggest page offset: 0x%016llx (%llu)\n"), (unsigned long long)biggest_poff, (unsigned long long)biggest_poff);
#ifdef _WIN32
		{
			_TCHAR *a = _tcsdup_from_A(biggest_roff_title);
			_TCHAR *b = _tcsdup_from_A(most_revs_title);
			_ftprintf(stderr, _T("biggest revision offset: 0x%08x (%u) \"%s\"\n"), biggest_roff, biggest_roff, a);
			_ftprintf(stderr, _T("most revisions: %u \"%s\"\n"), most_revs, b);
			free(a);
			free(b);
		}
#else
		_ftprintf(stderr, _T("biggest revision offset: 0x%08x (%u) \"%s\"\n"), biggest_roff, biggest_roff, biggest_roff_title);
		_ftprintf(stderr, _T("most revisions: %u \"%s\"\n"), most_revs, most_revs_title);
#endif
	}

	if (biggest_roff_title) free(biggest_roff_title);
	if (most_revs_title) free(most_revs_title);

	// TODO return success/failure
	return 1;
}

// helper functions

// On Windows the console parameters are UTF-16 though this tool only needs ASCII parameters so far
int parse_args(const int argc, _TCHAR* argv[], int *opt_d, int *opt_h, _TCHAR **dumplang, _TCHAR **dumpproj, _TCHAR **dumpdate)
{
	const _TCHAR *usage = _T("usage: wiktmkrawidx (-d -h) ll pppp... yyyymmdd\n");

	int mandatory_params = 3;
	int optional_params = 2;

	int ok = 1;

	if (argc >= mandatory_params + 1 && argc <= mandatory_params + optional_params + 1) {
		_TCHAR *arg_lang;
		_TCHAR *arg_proj;
		_TCHAR *arg_date;

		// switches
		if (argc > mandatory_params + 1) {

			int a;
			for (a = 0; a < optional_params && argv[a + 1][0] == '-'; ++a) {

				if (!_tcscmp(argv[a + 1], _T("-d"))) {
					_ftprintf(stderr, _T("** -d = debug\n"));
					*opt_d = 1;
				} else if (!_tcscmp(argv[a + 1], _T("-h"))) {
					_ftprintf(stderr, _T("** -h = meta-history\n"));
					*opt_h = 1;
				} else {
					_ftprintf(stderr, _T("** unknown parameter %d: %s\n"), a, argv[a + 1]);
					ok = 0;
				}

			}
		} else {
			_ftprintf(stderr, _T("** no optional params (mandatory = %d, optional <= %d)\n"), mandatory_params, optional_params);
		}

		arg_lang = argv[argc-3];
		arg_proj = argv[argc-2];
		arg_date = argv[argc-1];

		if (!check_range_and_length(arg_lang, 'a', 'z', 2, 3))
			_ftprintf(stderr, _T("** bad language code '%s'\n"), arg_lang);

		// TODO check_range_and_length arg_proj

		if (!check_range_and_length(arg_date, '0', '9', 8, 8))
			_ftprintf(stderr, _T("** bad date '%s'\n"), arg_date);

		*dumplang = _tcsdup(arg_lang);
		*dumpproj = _tcsdup(arg_proj);
		*dumpdate = _tcsdup(arg_date);

	} else {
		ok = 0;
	}

	if (!ok)
		_ftprintf(stderr, _T("%s"), usage);

	return ok;
}

#ifndef _WIN32

_TCHAR *unix_get_config_filename(void)
{
	_TCHAR *config_filename = NULL;

	char *home = getenv("HOME");

    // TODO we can probably replace this with alloc_stprintf then get rid of alloc_sprintf
	if (home)
		config_filename = alloc_sprintf("%s%c%s", home, '/', "wiktpath.txt");

	return config_filename;
}

#else

// Windows paths are UTF-16
_TCHAR *win_get_config_filename(void)
{
	_TCHAR *config_filename = NULL;

	// This is only for Vista and above, for older OSes back to Windows 2000 use SHGetFolderPath
	// maybe we should really use AppData etc but Vim uses this so good enough for me
	PWSTR home;
	HRESULT hr = SHGetKnownFolderPath(&FOLDERID_Profile, 0, NULL, &home);

	if (hr == S_OK) {
		int homelen = _tcslen(home);
		_TCHAR rest[] = _T("\\wiktpath.txt");
		int restlen = sizeof rest / sizeof(_TCHAR);	// this includes the trailing null!

		if (config_filename = malloc((homelen + restlen) * sizeof(_TCHAR))) {
			memcpy(config_filename, home, homelen * sizeof(_TCHAR));
			memcpy(config_filename + homelen, rest, restlen * sizeof(_TCHAR));
		}

		CoTaskMemFree(home);
	}

	return config_filename;
}

#endif

int read_config(_TCHAR **dumppath, _TCHAR **indexpath)
{
	int retval = 0;

	_TCHAR *config_path = get_config_filename();

	if (config_path) {
		FILE *config_fp = _tfopen(config_path, _T("r"));

		if (config_fp) {
			// TODO use myreadline
			char configlineA[256];

			if (fgets(configlineA, sizeof configlineA, config_fp) == NULL) {
				_ftprintf(stderr, _T("config read error\n"));
			} else {
				if (strchr(configlineA, '\n') || feof(config_fp)) {
					if (configlineA[strlen(configlineA)-1] == '\n')
						configlineA[strlen(configlineA)-1] = '\0';

                    *dumppath = _tcsdup_from_A(configlineA);
                    *indexpath = _tcsdup_from_A(configlineA);

                    _ftprintf(stderr, _T("dump path: %s\n"), *dumppath);
                    _ftprintf(stderr, _T("index path: %s\n"), *indexpath);

                    // TODO don't return success unless both paths were allcated
					retval = 1;
				} else {
					_ftprintf(stderr, _T("config line too long\n"));
				}
			}

			fclose(config_fp);
		} else {
			_ftprintf(stderr, _T("config file not found '%s'\n"), config_path);
		}

		free(config_path);
	}

	return retval;
}

// generic functions that could be used anywhere

// Needs to handle Unicode console parameters even though this tool only has ASCII parameters
int check_range_and_length(const _TCHAR *s, _TCHAR minchar, _TCHAR maxchar, int minlen, int maxlen)
{
	const _TCHAR *p;
	int retval = 0;

	for (p = s; 1; ++p) {
		if (*p == '\0') {
			if (p - s >= minlen)
				retval = 1;
			break;
		} else if (*p < minchar || *p > maxchar) {
			break;
		} else if (p - s + 1 > maxlen) {
			break;
		}
	}

	return retval;
}

// The config file is expected to be byte-based on all OSes
char *myreadline(FILE *f)
{
	char *line = NULL;
	int linelen = -1;
	char chunk[256];
	
	while (1) {
		if (fgets(chunk, sizeof chunk, f) == NULL) {
			if (feof(f)) {
				// TODO we don't have a way to indicate success
				// TODO we should only print if opt_d is on
				_ftprintf(stderr, _T("\n** end of file\n"));
			} else if (ferror(f)) {
				_ftprintf(stderr, _T("\n** read error\n"));
			} else {
				_ftprintf(stderr, _T("\n** unexpected condition!\n"));
			}
			break;

		} else {
			char *e = strchr(chunk, '\n');

			int chunklen = e ? (e - chunk + 1) : strlen(chunk);

			if (line) {
				// TODO check for out of memory
				char *temp = (char *)malloc(linelen + chunklen + 1);
				
				memcpy(temp, line, linelen + 1);
				free(line);
				memcpy(temp + linelen, chunk, chunklen + 1);
				line = temp;
				linelen += chunklen;
			} else {
				line = _strdup(chunk);
				linelen = strlen(chunk);
			}

			if (e || feof(f))
				break;
		}
	}

	return line;
}

// ANSI/UTF-8 sprintf into a buffer to be released with free()
//  only used by _TCHAR *unix_get_config_filename(void)
char *alloc_sprintf(const char *fmt, ...)
{
	char *result = NULL;

	va_list args;
	va_start(args, fmt);

#ifdef HAVE_SCPRINTF
	if (result = (char *)malloc(_vscprintf(fmt, args) +1))
		vsprintf(result, fmt, args);
#elif defined(HAVE_ASPRINTF)
    if (vasprintf(&result, fmt, args) == -1)
        result = NULL;
#elif defined (HAVE_GOOD_SNPRINTF)
    if (result = (char *)malloc(vsnprintf(NULL, 0, fmt, args) +1))
        vsprintf(result, fmt, args);
#else
# error no scprintf or asprintf or good snprintf support detected
#endif

	va_end(args);

	return result;
}

// _TCHAR sprintf into a buffer to be released with free()
_TCHAR *alloc_stprintf(const _TCHAR *fmt, ...)
{
	_TCHAR *result = NULL;

	va_list args;
	va_start(args, fmt);

#ifdef HAVE_SCPRINTF
	if (result = (_TCHAR *)malloc(sizeof(_TCHAR) * (_vsctprintf(fmt, args) +1)))
		_vstprintf(result, fmt, args);
#elif defined(HAVE_ASPRINTF)
    if (vasprintf(&result, fmt, args) == -1)
        result = NULL;
#elif defined (HAVE_GOOD_SNPRINTF)
    if (result = (_TCHAR *)malloc(sizeof(_TCHAR) * (vsnprintf(NULL, 0, fmt, args) +1)))
        vsprintf(result, fmt, args);
#else
# error no scprintf or asprintf or good snprintf support detected
#endif

	va_end(args);

	return result;
}

#ifdef _WIN32

// A version of strdup() that duplicates a UTF-8 string as a _TCHAR string
_TCHAR *_tcsdup_from_A(const char *utf8string)
{
    _TCHAR *tcharstring = NULL;
	int n1, n2;

    // configline is UTF-8 but paths are UTF-16
    n1 = MultiByteToWideChar(CP_UTF8, 0, utf8string, -1, NULL, 0);

    if (n1) {
        tcharstring = malloc(n1 * sizeof(WCHAR));	// TODO check for failure

        n2 = MultiByteToWideChar(CP_UTF8, 0, utf8string, -1, tcharstring, n1);
    }

    return tcharstring;
}

#endif

// TODO strdup that adds string to a linked list
const char *strdup_to_list(struct stringnode ***tail_ptr, const char *s)
{
	struct stringnode *self = NULL;
	size_t len = strlen(s);

	// TODO handle out of memory condition
	self = malloc(sizeof(struct stringnode) + len + 1);

	if (self) {
		self->next = NULL;
		strcpy(self->title, s);

		// link our new item onto the list
		**tail_ptr = self;

		// the next new item needs to link onto this one
		*tail_ptr = &self->next;
	}

	return self->title;
}

static int comparator(const void *a, const void *b)
{
	return strcmp(g_title_array[*(int *)a], g_title_array[*(int *)b]);
}

// create a sorted index of the page titles
int sort_titles(int opt_d, int page_count, FILE *all_txt_file, FILE *all_idx_raw_file)
{
    const int prog = 10000;
    int *index;

    g_title_array = (char **)malloc(page_count * sizeof(char *));
    index = (int *)malloc(page_count * sizeof(int));

    if (g_title_array && index) {
        struct stringnode *item;
		int i = 0;
		
		for (item = g_title_list_head; item != NULL; ++i, item = item->next) {
			g_title_array[i] = item->title;
            index[i] = i;

            if (opt_d && (i % prog == 0 || i == page_count -1)) {
                _TCHAR *t;
#ifdef _WIN32
                t = _tcsdup_from_A(g_title_array[i]);
#else
                t = g_title_array[i];
#endif
                _ftprintf(stderr, _T("%d: %s\n"), i, t);
#ifdef _WIN32
                free(t);
#endif
            }
        }

		_ftprintf(stderr, _T("page count was %d, i = %d\n"), page_count, i);

        _ftprintf(stderr, _T("sorting index\n"));

        qsort((void *)index, i, sizeof(int), comparator);

        _ftprintf(stderr, _T("saving index\n"));
		{
			int x = fwrite(index, sizeof(int), i, all_idx_raw_file);
			_ftprintf(stderr, _T("wrote %d\n"), x);
		}
    }

	if (g_title_array) free(g_title_array);
    if (index) free (index);

    // TODO return something meaningful
    return 0;
}

