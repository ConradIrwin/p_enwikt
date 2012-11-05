// wiktmkrawidx (-d) en 20110321
//
// scans a MediaWiki XML dump file the latest revision of each article

// creates four index files
//	xxx-off.raw
//		a "seek_type" (64 bit) absolute offset to the start of each <page> line
//		an "unsigned long" (32 bit) relative offset to the latest <revision> line of the <page> 
//	xxx-all.txt
//		a UTF-8 text file with the page titles in the order found in the dump
//	xxx-all-off.raw
//		an "unsigned long" (32 bit) absolute offset to the start of each title in xxx-all.txt
//	xxx-all-idx.raw
//		an "unsigned long" (32 bit) index of the position each page title is in after sorting
//
// TODO for each page store in a new index the namespace and whether tha page is a redirect
// TODO config file should support separate dump and index paths
// TODO prompt user if output files already exist
// TODO write metadata to .txt file (number of pages, revs; max page offset, rev offset, number of bits needed for each)
// TODO report more factoids: lowest page id, revision id, longest title
// TODO support dump file coming via a pipe
// TODO support bzip2'd dump file using seek-bzip2
// TODO instead of strdup()ing each title into its own node, malloc() big chunks of memory as nodes and concatenate lots of titles in them separated only by \0
// TODO   titles longer than the chunk size need to be special-case'd
// TODO use the minimum number of bytes for offsets, we can adjust the files after we know the maximum offset
// TODO XXX the fwrite all-idx.raw code can segfault when the dump file is truncated
// TODO group all index files together in directory
// TODO move dumplang, dumpproj, dumpdate into the options structure?
// TODO specify name of config file on commandline?
// TODO decide frequency of progress reports from type and size of dump file
// TODO make it possible to run steps separately

#include "stdafx.h"

struct options {
	int opt_d;				// enable for debugging
	int opt_h;				// set if indexing a pages-meta-history rather than pages-articles

	_TCHAR *opt_dp;			// dump path
	_TCHAR *opt_ip;			// index path

	_TCHAR *opt_dfn;		// dump filename
    _TCHAR *opt_ifnb;       // index filename base
};

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
int process_dump(int opt_d, int opt_h, FILE *dump_file, FILE *off_raw_file, FILE *all_txt_file, FILE *all_off_raw_file, FILE *all_idx_raw_file);
int check_range_and_length(const _TCHAR *s, _TCHAR minchar, _TCHAR maxchar, int minlen, int maxlen);
_TCHAR *get_config_path(void);
_TCHAR *get_config_filename(void);
int parse_args(const int argc, _TCHAR* argv[], struct options *, _TCHAR **dumplang, _TCHAR **dumpproj, _TCHAR **dumpdate);
int read_config(struct options *, _TCHAR **dumppath, _TCHAR **indexpath);
char *myreadline(FILE *, int *lenptr);
char *alloc_sprintf(const char *fmt, ...);
_TCHAR *alloc_stprintf(const _TCHAR *fmt, ...);
_TCHAR *_tcsdup_from_A(const char *);
const char *strdup_to_list(struct stringnode ***, const char *);
static int comparator(const void *, const void *);
int sort_titles(int opt_d, int pc, FILE *all_txt_file, FILE *all_idx_raw_file);
int bits_needed(unsigned long long);

#ifndef _WIN32
#define _tcsdup_from_A _tcsdup
#endif

// this tool doesn't need any Unicode console parameters
int _tmain(int argc, _TCHAR* argv[])
{
	struct options opt = {0};

	_TCHAR *dumplang = NULL;
	_TCHAR *dumpproj = NULL;
	_TCHAR *dumpdate = NULL;
	_TCHAR *dumppath = NULL;
	_TCHAR *indexpath = NULL;
	
	_TCHAR *dump_filename = NULL;
	_TCHAR *off_raw_filename;
	_TCHAR *all_txt_filename;
	_TCHAR *all_off_raw_filename;
	_TCHAR *all_idx_raw_filename;

#ifdef _WIN32
	_setmode(_fileno(stderr), _O_U16TEXT);
#endif

	if (parse_args(argc, argv, &opt, &dumplang, &dumpproj, &dumpdate)) {
		if (opt.opt_dp) dumppath = _tcsdup(opt.opt_dp);
		if (opt.opt_ip) indexpath = _tcsdup(opt.opt_ip);

		if (read_config(&opt, &dumppath, &indexpath)) {
			if (opt.opt_d) _ftprintf(stderr, _T("** read config OK\n"));

			// these strings must be defined either on the command line or in the config file
			if (dumppath && indexpath && dumplang && dumpproj && dumpdate) {
				// create filename strings
				if (opt.opt_dfn) {
					dump_filename = alloc_stprintf(_T("%s%s.xml"), dumppath, opt.opt_dfn);
				} else {
					dump_filename = alloc_stprintf(_T("%s%s%s-%s-pages-%s.xml"), dumppath, dumplang, dumpproj, dumpdate, opt.opt_h ? _T("meta-history") : _T("articles"));
				}

				// TODO include project or make configurable with a template
				if (opt.opt_ifnb) {
					off_raw_filename = alloc_stprintf(_T("%s%s-off.raw"), indexpath, opt.opt_ifnb);
					all_txt_filename = alloc_stprintf(_T("%s%s-all.txt"), indexpath, opt.opt_ifnb);
					all_off_raw_filename = alloc_stprintf(_T("%s%s-all-off.raw"), indexpath, opt.opt_ifnb);
					all_idx_raw_filename = alloc_stprintf(_T("%s%s-all-idx.raw"), indexpath, opt.opt_ifnb);
				} else {
					off_raw_filename = alloc_stprintf(_T("%s%s%s-off.raw"), indexpath, dumplang, dumpdate);
					all_txt_filename = alloc_stprintf(_T("%s%s%s-all.txt"), indexpath, dumplang, dumpdate);
					all_off_raw_filename = alloc_stprintf(_T("%s%s%s-all-off.raw"), indexpath, dumplang, dumpdate);
					all_idx_raw_filename = alloc_stprintf(_T("%s%s%s-all-idx.raw"), indexpath, dumplang, dumpdate);
				}

				if (dump_filename && off_raw_filename && all_txt_filename && all_off_raw_filename && all_idx_raw_filename) {

					// open input file
					FILE *dump_file = _tfopen(dump_filename, _T("rb"));					// crlf translation would interfere with ftell()

					_ftprintf(stderr, _T("%s : %s\n"), dump_filename, dump_file ? _T("yes") : _T("no"));

					if (dump_file) {
						// output files
						FILE *off_raw_file;
						const _TCHAR *off_raw_state = NULL;
						FILE *all_txt_file;
						const _TCHAR *all_txt_state = NULL;
						FILE *all_off_raw_file;
						const _TCHAR *all_off_raw_state = NULL;
                        FILE *all_idx_raw_file;
                        const _TCHAR *all_idx_raw_state = NULL;

						// check if output files already exist
						off_raw_file = _tfopen(off_raw_filename, _T("rb"));
						all_txt_file = _tfopen(all_txt_filename, _T("rb"));
						all_off_raw_file = _tfopen(all_off_raw_filename, _T("rb"));
                        all_idx_raw_file = _tfopen(all_idx_raw_filename, _T("rb"));

						if (off_raw_file) off_raw_state = _T("overwrite");
						if (all_txt_file) all_txt_state = _T("overwrite");
						if (all_off_raw_file) all_off_raw_state = _T("overwrite");
						if (all_idx_raw_file) all_idx_raw_state = _T("overwrite");

						// close output files
						if (off_raw_file) fclose(off_raw_file);
						if (all_txt_file) fclose(all_txt_file);
						if (all_off_raw_file) fclose(all_off_raw_file);
						if (all_idx_raw_file) fclose(all_idx_raw_file);

						// open output files for writing
						off_raw_file = _tfopen(off_raw_filename, _T("wb"));			// raw binary data
						all_txt_file = _tfopen(all_txt_filename, _T("wb"));			// crlf translation would interfere with ftell()
						all_off_raw_file = _tfopen(all_off_raw_filename, _T("wb"));	// raw binary data
                        all_idx_raw_file = _tfopen(all_idx_raw_filename, _T("wb"));	// raw binary data

						if (!off_raw_state) off_raw_state = off_raw_file ? _T("create") : _T("error");
						if (!all_txt_state) all_txt_state = all_txt_file ? _T("create") : _T("error");
						if (!all_off_raw_state) all_off_raw_state = all_off_raw_file ? _T("create") : _T("error");
						if (!all_idx_raw_state) all_idx_raw_state = all_idx_raw_file ? _T("create") : _T("error");

						_ftprintf(stderr, _T("%s : %s\n%s : %s\n%s : %s\n%s : %s\n"),
							off_raw_filename, off_raw_state,
							all_txt_filename, all_txt_state,
							all_off_raw_filename, all_off_raw_state,
							all_idx_raw_filename, all_idx_raw_state);

						if (off_raw_file && all_txt_file && all_off_raw_file && all_idx_raw_file) {
							process_dump(opt.opt_d, opt.opt_h, dump_file, off_raw_file, all_txt_file, all_off_raw_file, all_idx_raw_file);
						} /* if ( ... output files ... ) */

						// close output files
						if (off_raw_file) fclose(off_raw_file);
						if (all_txt_file) fclose(all_txt_file);
						if (all_off_raw_file) fclose(all_off_raw_file);
						if (all_idx_raw_file) fclose(all_idx_raw_file);

						// close input files
						fclose(dump_file);
					} /* if (dump_file) */
				} /* if ( ... filenames ... ) */

				if (dump_filename) free(dump_filename);
				if (off_raw_filename) free(off_raw_filename);
				if (all_txt_filename) free(all_txt_filename);
				if (all_off_raw_filename) free(all_off_raw_filename);
				if (all_idx_raw_filename) free(all_idx_raw_filename);

			} else {
				// TODO we don't need language, project, date if we specify dump filename and index base filename on the commandline
				_ftprintf(stderr, _T("** the following must be set either in the config file or on the command line: dump path, index path, language code, project, date\n"));
				_ftprintf(stderr, _T("** dump path: '%s'\n"), dumppath);
				_ftprintf(stderr, _T("** index path: '%s'\n"), indexpath);
				_ftprintf(stderr, _T("** language: '%s'\n"), dumplang);
				_ftprintf(stderr, _T("** project: '%s'\n"), dumpproj);
				_ftprintf(stderr, _T("** date: '%s'\n"), dumpdate);
			}
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

int process_dump(int opt_d, int opt_h, FILE *dump_file, FILE *off_raw_file, FILE *all_txt_file, FILE *all_off_raw_file, FILE *all_idx_raw_file)
{
	int pc = 0;							// page count
	int rc = 0;							// revision count for this page
	int rc_all = 0;						// revision count over all pages
	const char *title = NULL;			// dump files are always UTF-8
	int pid = -1;						// page ID
	seek_type poff;						// page offset
	int rid = -1;						// rev ID
	int roff = -1;						// rev offset
	long txt_told;						// offset of title in -all.txt to write to -all-off.raw

	seek_type biggest_poff = 0;

	int biggest_roff = 0;
	char *biggest_roff_title = NULL;

	int most_revs = 0;
	char *most_revs_title = NULL;

	int biggest_rid = -1;
	int biggest_rid_pid = -1;
	char *biggest_rid_title = NULL;

	int smallest_rid = INT_MAX;
	int smallest_rid_pid = -1;
	char *smallest_rid_title = NULL;

	char latest_timestamp[] = "0000-00-00";	// yyyy-mm-dd

	int state = 0;
	int progress_modulo = opt_h ? 1000 : 10000;
	int show_progress = 0;

	char *line;								// since dumps are always UTF-8
	int line_len;

	while (line = myreadline(dump_file, &line_len)) {

		if (state == 0) {

            // TODO analyse the namespace declarations

			if (strstr(line, "<page>")) {
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

				title = strdup_to_list(&g_title_list_tail_address, p1 + 7);

                // TODO figure out namespace (possibly nonzero if title contains a colon ":")
				
			} else if ((p1 = strstr(line, "<id>")) != NULL && (p2 = strstr(p1, "</id>")) != NULL) {
				*p2 = '\0';
				pid = atoi(p1+4);
				
			}

			// # <redirect>, <restrictions> are possible
            // TODO is it a redirect or not
            // TODO write into a new index file the namespace and redirect status

			if (title != NULL && pid != -1)
				state = 2;

		} else if (state == 2) {
			if (strstr(line, "<revision>")) {
				seek_type dump_told;

				++ rc;

				state = 3;

				dump_told = ftello(dump_file) - line_len;
				roff = (int)(dump_told - poff);

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
				txt_told = ftell(all_txt_file);

				fwrite(&poff, sizeof poff, 1, off_raw_file);
				fwrite(&roff, sizeof roff, 1, off_raw_file);

				// windows text files should have \r\n - unix should have just \n
#ifdef _WIN32
				fprintf(all_txt_file, "%s\r\n", title);
#else
				fprintf(all_txt_file, "%s\n", title);
#endif

				fwrite(&txt_told, sizeof txt_told, 1, all_off_raw_file);

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
						free((void *)t);
#endif
					}
					show_progress = 0;
				}

				++ pc;
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

				title = NULL;

				pid = -1;
				rid = -1;
			}
			// <redirect>, <restrictions> are possible
		} else if (state == 3) {
			char *p1, *p2;
			if ((p1 = strstr(line, "<id>")) != NULL && (p2 = strstr(p1, "</id>")) != NULL) {
				*p2 = '\0';

				// only take the revision id, not the contributor id!
				if (rid == -1) {
					rid = atoi(p1+4);

					if (rid > biggest_rid) {
						biggest_rid = rid;
						biggest_rid_pid = pid;
						if (biggest_rid_title)
							free(biggest_rid_title);
						biggest_rid_title = _strdup(title);
					} else if (rid < smallest_rid) {
						smallest_rid = rid;
						smallest_rid_pid = pid;
						if (smallest_rid_title)
							free(smallest_rid_title);
						smallest_rid_title = _strdup(title);
					}
				}


			} else if (strstr(line, "</revision>")) {
				state = 2;
			}

            else if ((p1 = strstr(line, "<timestamp>")) != NULL && (p2 = strstr(p1, "</timestamp>")) != NULL) {
                *(p1 + 11 + 10) = '\0';

				if (strncmp(p1+11, latest_timestamp, 10) > 0)
					memcpy(latest_timestamp, p1+11, 10);
            }

		} else {
			if (opt_d)
				_ftprintf(stderr, _T("** unknown state '%d'\n"), state);
		}

		free(line);
	} /* while ( ... myreadline ... ) */

	// sorting
    sort_titles(opt_d, pc, all_txt_file, all_idx_raw_file);

    {
        // free all the page titles
        struct stringnode *item = g_title_list_head, *next;
        
        while (item != NULL) {
            next = item->next;
            free(item);
            item = next;
        }
    }

	if (opt_d) {
		int pobits = bits_needed(biggest_poff);
		int robits = bits_needed(biggest_roff);
		int txtbits = bits_needed(txt_told);
		int idxbits = bits_needed(pc-1);

		_ftprintf(stderr, _T("%d pages and %d revisions (average %0.02f revisions per page)\n"),
			pc, rc_all, (float)(pc == 0 ? -1 : (float)rc_all / (float)pc));
		_ftprintf(stderr, _T("biggest page offset: 0x%016llx (%llu) [needs %d bits, %d bytes]\n"),
			(unsigned long long)biggest_poff, (unsigned long long)biggest_poff, pobits, (pobits-1)/8+1);
		{
			_TCHAR *a;
			_TCHAR *b;
#ifdef _WIN32
			a = _tcsdup_from_A(biggest_roff_title);
			b = _tcsdup_from_A(most_revs_title);
#else
			a = biggest_roff_title;
			b = most_revs_title;
#endif
			_ftprintf(stderr, _T("biggest revision offset: 0x%08x (%u) [needs %d bits, %d bytes] \"%s\"\n"),
				biggest_roff, biggest_roff, robits, (robits-1)/8+1, a);
			_ftprintf(stderr, _T("most revisions: %u \"%s\"\n"), most_revs, b);
#ifdef _WIN32
			free(a);
			free(b);
#endif
		}
		_ftprintf(stderr, _T("biggest title offset: 0x%08lx (%ld) [needs %d bits, %d bytes]\n"),
			txt_told, txt_told, txtbits, (txtbits-1)/8+1);
			//(unsigned int)txt_told, (unsigned int)txt_told, txtbits, (txtbits-1)/8+1);
		_ftprintf(stderr, _T("biggest page index: 0x%08x (%u) [needs %d bits, %d bytes]\n"),
			pc-1, pc-1, idxbits, (idxbits-1)/8+1);
		_ftprintf(stderr, _T("latest revision timestamp: %hs\n"), latest_timestamp);

		{
			_TCHAR *a;
			_TCHAR *b;
#ifdef _WIN32
			a = _tcsdup_from_A(smallest_rid_title);
			b = _tcsdup_from_A(biggest_rid_title);
#else
			a = smallest_rid_title;
			b = biggest_rid_title;
#endif
			_ftprintf(stderr, _T("smallest revision id: %d (page id %d) \"%s\"\n"),
				smallest_rid, smallest_rid_pid, a);
			_ftprintf(stderr, _T("biggest revision id: %d (page id %d) \"%s\"\n"),
				biggest_rid, biggest_rid_pid, b);
#ifdef _WIN32
			free(a);
			free(b);
#endif
		}
	}

	if (biggest_roff_title) free(biggest_roff_title);
	if (most_revs_title) free(most_revs_title);
	if (biggest_rid_title) free(biggest_rid_title);
	if (smallest_rid_title) free(smallest_rid_title);

	// TODO return success/failure
	return 1;
}

// helper functions

// On Windows the console parameters are UTF-16 though this tool only needs ASCII parameters so far
int parse_args(const int argc, _TCHAR* argv[], struct options *opt, _TCHAR **dumplang, _TCHAR **dumpproj, _TCHAR **dumpdate)
{
	const _TCHAR *usage = _T("usage: wiktmkrawidx (-d -h -dp= -ip= -dfn= -ifnb=) ll pppp... yyyymmdd\n");

	int mandatory_params = 3;
	int optional_params = 6;

	int ok = 1;

	if (argc >= mandatory_params + 1 && argc <= mandatory_params + optional_params + 1) {
		_TCHAR *arg_lang;
		_TCHAR *arg_proj;
		_TCHAR *arg_date;

		// switches
		if (argc > mandatory_params + 1) {

			int a;
			for (a = 0; a < optional_params && argv[a + 1][0] == '-'; ++a) {
				_TCHAR *ap;

				// switches

				if (!_tcscmp(argv[a + 1], _T("-d"))) {
					_ftprintf(stderr, _T("** -d = debug\n"));
					opt->opt_d = 1;
				} else if (!_tcscmp(argv[a + 1], _T("-h"))) {
					_ftprintf(stderr, _T("** -h = meta-history\n"));
					opt->opt_h = 1;

				// arguments that take values

				} else if ((ap = _tcsstr(argv[a + 1], _T("-dp="))) != NULL) {
					_ftprintf(stderr, _T("** -dp = dump path: '%s'\n"), ap + 4);
					opt->opt_dp = ap + 4;
				} else if ((ap = _tcsstr(argv[a + 1], _T("-ip="))) != NULL) {
					_ftprintf(stderr, _T("** -ip = index path: '%s'\n"), ap + 4);
					opt->opt_ip = ap + 4;
				} else if ((ap = _tcsstr(argv[a + 1], _T("-dfn="))) != NULL) {
					_ftprintf(stderr, _T("** -dfn = dump filename: '%s'\n"), ap + 5);
					opt->opt_dfn = ap + 5;
				} else if ((ap = _tcsstr(argv[a + 1], _T("-ifnb="))) != NULL) {
					_ftprintf(stderr, _T("** -ifnb = index filename base: '%s'\n"), ap + 6);
					opt->opt_ifnb = ap + 6;

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

// *nix paths are UTF-8
_TCHAR *unix_get_config_path(void)
{
	_TCHAR *config_path = NULL;
	char *home = getenv("HOME");

	if (home)
		config_path = _tcsdup(home);

	return config_path;
}

#else

// Windows paths are UTF-16
_TCHAR *win_get_config_path(void)
{
	_TCHAR *config_path = NULL;
	// This is only for Vista and above, for older OSes back to Windows 2000 use SHGetFolderPath
	// maybe we should really use AppData etc but Vim uses this so good enough for me
	PWSTR home;
	HRESULT hr = SHGetKnownFolderPath(&FOLDERID_Profile, 0, NULL, &home);

	if (hr == S_OK) {
		config_path = _tcsdup(home);
		CoTaskMemFree(home);
	}

	return config_path;
}

#endif

_TCHAR *get_config_filename(void)
{
    _TCHAR *config_path = get_config_path();
    _TCHAR *config_filename = NULL;
#ifdef _WIN32
    _TCHAR sep = '\\';
#else
    _TCHAR sep = '/';
#endif

    if (config_path) {
        const _TCHAR *names[] = { _T(".wikipath"), _T("wikipath.txt"), _T("wiktpath.txt") };
        int i;
        for (i = 0; i < sizeof(names); ++i) {
            if (config_filename) {
                free(config_filename);
                config_filename = NULL;
            }

            //config_filename = alloc_stprintf(_T("%s%c%s"), config_path, sep, _T("wiktpath.txt"));
            config_filename = alloc_stprintf(_T("%s%c%s"), config_path, sep, names[i]);

            if (_taccess(config_filename, 00) == -1) {
                _ftprintf(stderr, _T("** can't access '%s'\n"), config_filename);
            } else {
                _ftprintf(stderr, _T("** can access '%s'\n"), config_filename);
                break;
            }


        }
        free(config_path);
    }

    return config_filename;
}

// TODO support tab separated key value pairs
int read_config(struct options *opt, _TCHAR **dumppath, _TCHAR **indexpath)
{
	int retval = 0;

	_TCHAR *config_path = get_config_filename();

	if (config_path) {
		FILE *config_file = _tfopen(config_path, _T("r"));

		if (config_file) {
            char *line;
            int linelen;

            if ((line = myreadline(config_file, &linelen)) != NULL) {
                // chomp EOL covering all platform variations
				if (linelen > 0) {
					if (line[linelen-1] == '\n') {
						line[linelen-1] = '\0';
						if (linelen > 1) {
							if (line[linelen-2] == '\r') {
								line[linelen-2] = '\0';
							}
						}
					}
				}

                if (opt->opt_dp) {
                    _ftprintf(stderr, _T("dump path override on command-line: %s\n"), opt->opt_dp);
                } else {
                    *dumppath = _tcsdup_from_A(line);
                    _ftprintf(stderr, _T("dump path: %s\n"), *dumppath);
                }

                if (opt->opt_ip) {
                    _ftprintf(stderr, _T("index path override on command-line: %s\n"), opt->opt_ip);
                } else {
                    *indexpath = _tcsdup_from_A(line);
                    _ftprintf(stderr, _T("index path: %s\n"), *indexpath);
                }

                retval = 1;

				free(line);
			} else {
				_ftprintf(stderr, _T("config read error\n"));
			}

			fclose(config_file);
		} else {
			_ftprintf(stderr, _T("** config file not found '%s'\n"), config_path);
		}

		free(config_path);
	} /* config_path */

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
char *myreadline(FILE *f, int *lenptr)
{
	char *line = NULL;
	int linelen = -1;
	char chunk[256];
	
	while (1) {
		if (fgets(chunk, sizeof chunk, f) == NULL) {
            // TODO we don't have a way to indicate success
			// TODO don't really want to pass opt_d to this function
            {
                if (feof(f))
                    _ftprintf(stderr, _T("\n** end of file\n"));
                else if (ferror(f))
                    _ftprintf(stderr, _T("\n** read error\n"));
                else
                    _ftprintf(stderr, _T("\n** unexpected condition!\n"));
            }
			break;

		} else {
			char *e = strchr(chunk, '\n');

			int chunklen = e ? (e - chunk + 1) : strlen(chunk);

			if (line == NULL) {
				line = _strdup(chunk);
				linelen = strlen(chunk);
			} else {
				// TODO check for out of memory
				char *temp = (char *)malloc(linelen + chunklen + 1);
				
				memcpy(temp, line, linelen + 1);
				free(line);
				memcpy(temp + linelen, chunk, chunklen + 1);
				line = temp;
				linelen += chunklen;
			}

			if (e || feof(f))
				break;
		}
	}

    if (lenptr != NULL) *lenptr = linelen;

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
// TODO would insertion sort be better?
int sort_titles(int opt_d, int page_count, FILE *all_txt_file, FILE *all_idx_raw_file)
{
    int *index;
    int written;
    int success = 0;

    // allocate arrays so we can use qsort()
    g_title_array = (char **)malloc(page_count * sizeof(char *));
    index = (int *)malloc(page_count * sizeof(int));

    if (g_title_array && index) {
        struct stringnode *item;
		int title_count = 0;
		
		for (item = g_title_list_head; item != NULL; ++title_count, item = item->next) {
			g_title_array[title_count] = item->title;
            index[title_count] = title_count;
        }

		//_ftprintf(stderr, _T("page count was %d, title_count = %d\n"), page_count, title_count);

        if (opt_d) _ftprintf(stderr, _T("sorting index\n"));

        qsort((void *)index, title_count, sizeof(int), comparator);

        if (opt_d) _ftprintf(stderr, _T("saving index\n"));

        // TODO XXX this code can segfault when the dump file is truncated
        written = fwrite(index, sizeof(int), title_count, all_idx_raw_file);

        if (opt_d) _ftprintf(stderr, _T("wrote %d\n"), written);

        if (written == title_count)
            success = 1;
    }

	if (g_title_array) free(g_title_array);
    if (index) free (index);

    return success;
}

int bits_needed(unsigned long long l)
{
	int n;
	for (n = 0; l; l >>= 1)
		++n;
	return n;
}
