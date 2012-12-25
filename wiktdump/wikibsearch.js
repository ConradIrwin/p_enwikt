'use strict';

var fs   = require('fs'),
    path = require('path'),
    util = require('util');

var supportsBigFiles = process.version.substring(1).split('.') >= [0,7,9];

function getArticle(files, indexS, gotArticle) {
  var haystackLen = files.to.byteLen / 4;
  var indexR = new Buffer(4), record = new Buffer(12), chunk = new Buffer(1024);

  if (indexS < 0 || indexS >= haystackLen) {
    if (indexS === -1) {
      gotTitle('** beginning of list **');
    } else if (indexS === haystackLen) {
      gotTitle('** end of list **');
    } else {
      throw 'sorted index ' + indexS + ' out of range';
    }
  } else {
    fs.read(files.st.fd, indexR, 0, 4, indexS * 4, function (err, bytesRead, data) {
      if (!err && bytesRead === 4) {
        if (data.readUInt32LE !== undefined) {
          indexR = data.readUInt32LE(0);
        } else {
          indexR = data[3] * Math.pow(2, 24) + data[2] * Math.pow(2, 16) + data[1] * Math.pow(2, 8) + data[0];
        }

        //                               * 3 ??
        if (indexR < 0 || indexR >= haystackLen) throw 'raw index ' + indexR + ' out of range (sorted index ' + indexS + ')';

        fs.read(files.do.fd, record, 0, 12, indexR * 12, function (err, bytesRead, data) {
          if (!err && bytesRead === 12) {
            var lower, upper, offset, extra;

            if (data.readUInt32LE !== undefined) {
              lower = data.readUInt32LE(0);
              upper = data.readUInt32LE(4);
              offset = upper * (Math.pow(2, 32)) + lower;
              extra = data.readUInt32LE(8);
            } else {
              lower = data[3] * Math.pow(2, 24) + data[2] * Math.pow(2, 16) + data[1] * Math.pow(2, 8) + data[0];
              upper = data[7] * Math.pow(2, 24) + data[6] * Math.pow(2, 16) + data[5] * Math.pow(2, 8) + data[4];
              offset = upper * Math.pow(2, 32) + lower;
              extra = data[11] * Math.pow(2, 24) + data[10] * Math.pow(2, 16) + data[9] * Math.pow(2, 8) + data[8];
            }

            // skip to latest <revision>
            offset += extra;

            if (offset < 0 || offset >= files.d.byteLen) throw 'dump offset ' + offset + ' out of range';

            if (!supportsBigFiles && offset > 0x7fffffff) {
              throw 'offsets >= 2^31 are too big for node.js ' + process.version;
            }

            fs.read(files.d.fd, chunk, 0, 1023, offset, function (err, bytesRead, data) {
              if (!err && bytesRead > 0) {
                var article = data.toString('utf-8');

                gotArticle(article);
              } else {
                console.log('dump read err, bytesRead', err, bytesRead);
              }
            });

          }
        });
      } else { throw ['indexR', err, bytesRead]; }
    });
  }
}

function getTitle(files, indexS, gotTitle) {
  var haystackLen = files.to.byteLen / 4;
  var indexR = new Buffer(4), offset = new Buffer(4), title = new Buffer(256);

  if (indexS < 0 || indexS >= haystackLen) {
    if (indexS === -1) {
      gotTitle('** beginning of list **');
    } else if (indexS === haystackLen) {
      gotTitle('** end of list **');
    } else {
      throw 'sorted index ' + indexS + ' out of range';
    }
  } else {
    fs.read(files.st.fd, indexR, 0, 4, indexS * 4, function (err, bytesRead, data) {
      if (!err && bytesRead === 4) {
        if (data.readUInt32LE !== undefined) {
          indexR = data.readUInt32LE(0);
        } else {
          indexR = data[3] * Math.pow(2, 24) + data[2] * Math.pow(2, 16) + data[1] * Math.pow(2, 8) + data[0];
        }

        if (indexR < 0 || indexR >= haystackLen) throw 'raw index ' + indexR + ' out of range (sorted index ' + indexS + ')';

        fs.read(files.to.fd, offset, 0, 4, indexR * 4, function (err, bytesRead, data) {
          if (!err && bytesRead === 4) {
            if (data.readUInt32LE !== undefined) {
              offset = data.readUInt32LE(0);
            } else {
              offset = data[3] * Math.pow(2, 24) + data[2] * Math.pow(2, 16) + data[1] * Math.pow(2, 8) + data[0];
            }

            if (offset < 0 || offset >= files.t.byteLen) throw 'title offset ' + offset + ' out of range';

            fs.read(files.t.fd, title, 0, 256, offset, function (err, bytesRead, data) {
              if (!err && bytesRead > 0) {
                title = data.toString('utf-8');
                var spl = title.split(/\r?\n/);
                if (spl.length < 2) throw 'didn\'t read a long enough string';

                gotTitle(spl[0]);
              }
            });
          }
        });
      } else { throw ['indexR', err, bytesRead]; }
    });
  }
}

function bsearch(files, searchTerm, callback) {

  function bs(A, key, imin, imax, cb) {

    // test if array is empty
    if (imax < imin) {
      // set is empty, so return value showing not found
      cb({ok:false, a:imax, b:imin});
    } else {
      // calculate midpoint to cut set in half
      var imid = Math.floor((imin + imax) / 2); 

      // start while TODO recursion
      getTitle(A, imid, function (Aimid) {

        // three-way comparison
        if (Aimid > key) {
          // key is in lower subset
          bs(A, key, imin, imid-1, cb);
        } else if (Aimid < key) {
          // key is in upper subset
          bs(A, key, imid+1, imax, cb);
        } else {
          // key has been found
          cb({ok:true, a:imid, b:imid});
        }
      });
    }
  }

  bs(files, searchTerm, 0, files.to.byteLen / 4 - 1, callback);
}

var wikiLang, wikiProj, wikiDate, searchTerm;

// process command line
if (process.argv.length === 6) {  // 0 is node.exe, 1 is wikibsearch.js
  wikiLang = process.argv[2];
  wikiProj = process.argv[3];
  wikiDate = process.argv[4];

  searchTerm = process.argv[5];
} else {
  console.error('usage: node wikibsearch language project dumpdate searchterm');
  process.exit(1);
}

// cross-platform for at least Windows and *nix (but possibly not Mac OS X)
// http://stackoverflow.com/questions/9080085/node-js-find-home-directory-in-platform-agnostic-way
var home = process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'], 
    wikipathpath = home + '/.wikipath';

path.exists(wikipathpath, function (x) {
  if (x) {
    var str = fs.createReadStream(wikipathpath, {start: 0, end: 1023}),
        wikipath = '',
        indexpath = '';

    // TODO ~/.wikipath only has wikipath - indexpath hardcoded for now!
    if (process.platform === 'sunos') {
      indexpath = '/mnt/user-store/hippietrail/';
    } else {
      indexpath = wikipath;
    }

    str.on('data', function (data) {
      wikipath = data.toString('utf-8').replace(/^\s*(.*?)\s*$/, '$1');
    });

    str.on('end', function () {
      path.exists(wikipath, function (x) {
        var fullDumpPath;

        if (x) {
          console.log('path to wikis "' + wikipath + '" exists');

          fullDumpPath = wikipath + wikiLang + wikiProj + '-' + wikiDate + '-pages-articles.xml';

          path.exists(fullDumpPath, function (x) {
            if (x) {
              console.log('dump "' + fullDumpPath + '" exists');

              // open titles, title offsets, title sequence, and dump offsets

              var files = {
                d:  { desc: 'dump',           fmt: '%s%s' + wikiProj + '-%d-pages-articles.xml' },
                do: { desc: 'dump offsets',   fmt: '%s%s%d-off.raw' },
                t:  { desc: 'titles',         fmt: '%s%s%d-all.txt' },
                to: { desc: 'title offsets',  fmt: '%s%s%d-all-off.raw' },
                st: { desc: 'sorted titles',  fmt: '%s%s%d-all-idx.raw' },
              };

              var left = Object.keys(files).length;
              for (var k in files) {
                (function (e) {
                  var p;

                  if (util.format !== undefined) {
                    // recent node.js version - running on my Windows box
                    // TODO doesn't support separate wikipath and indexpath
                    p = util.format(e.fmt, wikipath, wikiLang, wikiDate);
                  } else {
                    // old node.js version - running on toolserver (sunos)
                    switch (k) {
                      case 'd':
                        p = wikipath + wikiLang + wikiProj + '-' + wikiDate + '-pages-articles.xml';
                        break;
                      case 'do':
                        p = indexpath + wikiLang + wikiDate + '-off.raw';
                        break;
                      case 't':
                        p = indexpath + wikiLang + wikiDate + '-all.txt';
                        break;
                      case 'to':
                        p = indexpath + wikiLang + wikiDate + '-all-off.raw';
                        break;
                      case 'st':
                        p = indexpath + wikiLang + wikiDate + '-all-idx.raw';
                        break;
                      default:
                        throw 'mystery file';
                    }
                  }

                  fs.open(p, 'r', function (err, fd) {
                    if (err) {
                      console.error('error opening ' + e.desc + ' file): ' + err);
                    } else {
                      e.fd = fd;
                      fs.fstat(fd, function (err, stats) {
                        if (err) {
                          throw 'fs.fstat() failed';
                        } else {
                          e.byteLen = stats.size;

                          console.log('... ' + e.desc + ' file OK (' + e.byteLen + ')');

                          --left;

                          if (left === 0) {
                            // sanity check
                            if (files.to.byteLen === files.st.byteLen
                              && files.to.byteLen % 4 === 0
                              && files.do.byteLen / files.to.byteLen === 3) {

                              bsearch(files, searchTerm, function (result) {
                                var before, after,
                                  gotNearby = function () {
                                    console.log('"' + searchTerm + '" belongs between "' + before + '" and "' + after + '"');
                                  }; 

                                if (result.a === result.b) {
                                  getTitle(files, result.a, function (t) {
                                    console.log('"' + searchTerm + '" found at ' + result.a);
                                    var article = getArticle(files, result.a, function (a) {
                                      console.log('article\n', a, '\n');
                                    });
                                  });
                                } else {
                                  getTitle(files, result.a, function (t) {
                                    before = t;
                                    if (after) gotNearby();
                                  });
                                  getTitle(files, result.b, function (t) {
                                    after = t;
                                    if (before) gotNearby();
                                  });
                                }
                              });
                            } else {
                              console.log('sanity check fail');
                            }
                          }
                        }
                      });
                    }
                  });
                })(files[k]);
              }
            } else {
              console.error('dump "' + fullDumpPath + '" doesn\'t exist');
              path.exists(fullDumpPath + '.bz2', function (x) {
                if (x) {
                  console.error('but compressed dump "' + fullDumpPath + '.bz2" exists');
                } else {
                  console.error('compressed dump "' + fullDumpPath + '.bz2" doesn\'t exist either');
                }
              });
            }
          });
        } else {
          console.error('path to wikis "' + wikipath + '" doesn\'t exist');
        }
      });
    });
        
  } else {
    console.error('no ".wikipath" in home');
  }
});

