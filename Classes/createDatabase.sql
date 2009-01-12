BEGIN TRANSACTION;
CREATE TABLE file (
    'local_path'            TEXT PRIMARY KEY,    
    'size'                  INTEGER,
    'is_zipped'             INTEGER,
    'download_complete'     INTEGER,
    
    'last_position'         INTEGER,
    'bookmarks'             BLOB,
    
    'remote_path'           TEXT,
    'remote_mode'           INTEGER,
    'remote_host'           TEXT,
    'remote_port'           INTEGER,
    'remote_username'       TEXT,
    'remote_create_time'    REAL,
    'remote_modify_time'    REAL,
    
    'preview'               BLOB,
    'icon'                  BLOB,
    'webarchive'	    BLOB
);

CREATE TABLE version (
    'major'                 INTEGER,
    'minor'                 INTEGER
);

INSERT INTO version VALUES(2, 0);

COMMIT;
 