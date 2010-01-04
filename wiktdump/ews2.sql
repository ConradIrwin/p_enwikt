DROP TABLE lang;
DROP TABLE head;
DROP TABLE titlescript;
DROP TABLE title;
DROP TABLE categorylinks;

DROP TABLE ews;

DROP TABLE seq;

CREATE TABLE lang (
    id INT(4) NOT NULL,
    lang_name VARCHAR(63) NOT NULL,
    PRIMARY KEY id (id) )
    CHARACTER SET utf8 COLLATE utf8_bin;

LOAD DATA LOCAL INFILE '/home/hippietrail/__langnames.txt'
    INTO TABLE lang
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 0 LINES
    (id, lang_name);


CREATE TABLE head (
    id INT(4) NOT NULL,
    head_name VARCHAR(63) NOT NULL,
    PRIMARY KEY id (id) );

LOAD DATA LOCAL INFILE '/home/hippietrail/__headings.txt'
    INTO TABLE head
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 0 LINES
    (id, head_name);


CREATE TABLE titlescript (
    page_id INT(4) NOT NULL,
    pva VARCHAR(48),
    KEY id (page_id),
    KEY pva (pva) );

LOAD DATA LOCAL INFILE '/home/hippietrail/__scripts.txt'
    INTO TABLE titlescript
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 0 LINES
    (page_id, pva);


CREATE TABLE title (
    page_id INT(4) NOT NULL,
    page_title VARCHAR(255) NOT NULL,
    sortkey VARBINARY(2048),
    KEY id (page_id),
    KEY sk (sortkey),
    KEY t (page_title) )
    CHARACTER SET utf8 COLLATE utf8_bin;

LOAD DATA LOCAL INFILE '/home/hippietrail/__titles.txt'
    INTO TABLE title
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 0 LINES
    ( page_id, page_title, sortkey );


CREATE TABLE ews (
    page_id INT(4) NOT NULL,
    lang_id INT(4),
    head_level INT(1),
    head_id INT(4),
    KEY id (page_id),
    KEY lh (lang_id, head_id),
    KEY h (head_id) );

LOAD DATA LOCAL INFILE '/home/hippietrail/__pages.txt'
    INTO TABLE ews
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 0 LINES
    ( page_id, lang_id, head_level, head_id );


SOURCE /mnt/user-store/enwiktionary-20091230-categorylinks.sql


CREATE TABLE seq (
    page_id INT(4) NOT NULL,
    seq INT(4) NOT NULL KEY UNIQUE AUTO_INCREMENT,
    KEY id (page_id) )
SELECT page_id from title ORDER BY sortkey;
