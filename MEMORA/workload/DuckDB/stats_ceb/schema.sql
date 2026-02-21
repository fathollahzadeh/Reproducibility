-- Users
CREATE TABLE users (
Id bigint PRIMARY KEY,
Reputation INTEGER ,
CreationDate TIMESTAMP ,
Views INTEGER ,
UpVotes INTEGER ,
DownVotes INTEGER
);

-- Posts
CREATE TABLE posts (
	Id bigint PRIMARY KEY,
	PostTypeId SMALLINT ,
	CreationDate TIMESTAMP ,
	Score INTEGER ,
	ViewCount INTEGER,
	OwnerUserId INTEGER,
  AnswerCount INTEGER ,
  CommentCount INTEGER ,
  FavoriteCount INTEGER,
  LastEditorUserId INTEGER
);

-- PostLinks
CREATE TABLE postLinks (
	Id bigint PRIMARY KEY,
	CreationDate TIMESTAMP ,
	PostId INTEGER ,
	RelatedPostId INTEGER ,
	LinkTypeId SMALLINT
);

-- PostHistory
CREATE TABLE postHistory (
	Id bigint PRIMARY KEY,
	PostHistoryTypeId SMALLINT ,
	PostId INTEGER ,
	CreationDate TIMESTAMP ,
	UserId INTEGER
);

-- Comments
CREATE TABLE comments (
	Id bigint PRIMARY KEY,
	PostId INTEGER ,
	Score SMALLINT ,
  CreationDate TIMESTAMP ,
	UserId INTEGER
);

-- Votes
CREATE TABLE votes (
	Id bigint PRIMARY KEY,
	PostId INTEGER,
	VoteTypeId SMALLINT ,
	CreationDate TIMESTAMP ,
	UserId INTEGER,
	BountyAmount SMALLINT
);

-- Badges
CREATE TABLE badges (
	Id bigint PRIMARY KEY,
	UserId INTEGER ,
	Date TIMESTAMP
);

-- Tags
CREATE TABLE tags (
	Id bigint PRIMARY KEY,
	Count INTEGER ,
	ExcerptPostId INTEGER
);

copy badges from 'badges.csv' with CSV header;
copy comments from 'comments.csv' with CSV header;
copy users from 'users.csv' with CSV header;
copy tags from 'tags.csv' with CSV header;
copy posts from 'posts.csv' with CSV header;
copy votes from 'votes.csv' with CSV header;
copy posthistory from 'postHistory.csv' with CSV header;
copy postlinks from 'postLinks.csv' with CSV header;


create index idx_posts_owneruserid on posts (owneruserid);
create index  idx_posts_lasteditoruserid on posts (lasteditoruserid);
create index idx_postlinks_relatedpostid on postLinks (relatedpostid);
create index idx_postlinks_postid on postLinks (postid);
create index idx_posthistory_postid on postHistory (postid);
create index idx_posthistory_userid on postHistory (userid);
create index idx_comments_postid on comments (postid);
create index idx_comments_userid on comments (userid);
create index idx_votes_userid on votes (userid);
create index idx_votes_postid on votes (postid);
create index idx_badges_userid on badges (userid);
create index idx_tags_excerptpostid on tags (excerptpostid);
analyze badges;
analyze comments;
analyze posthistory;
analyze postlinks;
analyze posts;
analyze tags;
analyze users;
analyze votes;