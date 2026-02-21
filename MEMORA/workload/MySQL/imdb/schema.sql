
CREATE TABLE aka_name (
    id integer NOT NULL PRIMARY KEY,
    person_id integer NOT NULL,
    name VARCHAR(1024),
    imdb_index VARCHAR(3),
    name_pcode_cf VARCHAR(11),
    name_pcode_nf VARCHAR(11),
    surname_pcode VARCHAR(11),
    md5sum VARCHAR(65)
);

CREATE TABLE aka_title (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer NOT NULL,
    title VARCHAR(1024),
    imdb_index VARCHAR(4),
    kind_id integer NOT NULL,
    production_year integer,
    phonetic_code VARCHAR(5),
    episode_of_id integer,
    season_nr integer,
    episode_nr integer,
    note VARCHAR(72),
    md5sum VARCHAR(32)
);

CREATE TABLE cast_info (
    id integer NOT NULL PRIMARY KEY,
    person_id integer NOT NULL,
    movie_id integer NOT NULL,
    person_role_id integer,
    note VARCHAR(5000),
    nr_order integer,
    role_id integer NOT NULL
);

CREATE TABLE char_name (
    id integer NOT NULL PRIMARY KEY,
    name VARCHAR(1024) NOT NULL,
    imdb_index VARCHAR(2),
    imdb_id integer,
    name_pcode_nf VARCHAR(5),
    surname_pcode VARCHAR(5),
    md5sum VARCHAR(32)
);

CREATE TABLE comp_cast_type (
    id integer NOT NULL PRIMARY KEY,
    kind VARCHAR(32) NOT NULL
);

CREATE TABLE company_name (
    id integer NOT NULL PRIMARY KEY,
    name VARCHAR(1024) NOT NULL,
    country_code VARCHAR(6),
    imdb_id integer,
    name_pcode_nf VARCHAR(5),
    name_pcode_sf VARCHAR(5),
    md5sum VARCHAR(32)
);

CREATE TABLE company_type (
    id integer NOT NULL PRIMARY KEY,
    kind VARCHAR(32)
);

CREATE TABLE complete_cast (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer,
    subject_id integer NOT NULL,
    status_id integer NOT NULL
);

CREATE TABLE info_type (
    id integer NOT NULL PRIMARY KEY,
    info VARCHAR(32) NOT NULL
);

CREATE TABLE keyword (
    id integer NOT NULL PRIMARY KEY,
    keyword VARCHAR(3000) NOT NULL,
    phonetic_code VARCHAR(5)
);

CREATE TABLE kind_type (
    id integer NOT NULL PRIMARY KEY,
    kind VARCHAR(15)
);

CREATE TABLE link_type (
    id integer NOT NULL PRIMARY KEY,
    link VARCHAR(32) NOT NULL
);

CREATE TABLE movie_companies (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer NOT NULL,
    company_id integer NOT NULL,
    company_type_id integer NOT NULL,
    note VARCHAR(10000)
);

CREATE TABLE movie_info_idx (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer NOT NULL,
    info_type_id integer NOT NULL,
    info VARCHAR(10000) NOT NULL,
    note VARCHAR(1)
);

CREATE TABLE movie_keyword (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer NOT NULL,
    keyword_id integer NOT NULL
);

CREATE TABLE movie_link (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer NOT NULL,
    linked_movie_id integer NOT NULL,
    link_type_id integer NOT NULL
);

CREATE TABLE name (
    id integer NOT NULL PRIMARY KEY,
    name VARCHAR(1024) NOT NULL,
    imdb_index VARCHAR(9),
    imdb_id integer,
    gender VARCHAR(1),
    name_pcode_cf VARCHAR(5),
    name_pcode_nf VARCHAR(5),
    surname_pcode VARCHAR(5),
    md5sum VARCHAR(32)
);

CREATE TABLE role_type (
    id integer NOT NULL PRIMARY KEY,
    role VARCHAR(32) NOT NULL
);

CREATE TABLE title (
    id integer NOT NULL PRIMARY KEY,
    title VARCHAR(3000) NOT NULL,
    imdb_index VARCHAR(5),
    kind_id integer NOT NULL,
    production_year integer,
    imdb_id integer,
    phonetic_code VARCHAR(5),
    episode_of_id integer,
    season_nr integer,
    episode_nr integer,
    series_years VARCHAR(49),
    md5sum VARCHAR(32)
);

CREATE TABLE movie_info (
    id integer NOT NULL PRIMARY KEY,
    movie_id integer NOT NULL,
    info_type_id integer NOT NULL,
    info TEXT NOT NULL,
    note TEXT
);

CREATE TABLE person_info (
    id integer NOT NULL PRIMARY KEY,
    person_id integer NOT NULL,
    info_type_id integer NOT NULL,
    info TEXT NOT NULL,
    note TEXT
);
