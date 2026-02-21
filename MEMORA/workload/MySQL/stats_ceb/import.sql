
LOAD DATA LOCAL INFILE 'users.csv' INTO TABLE users FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
    Reputation,
    CreationDate,
    Views,
    UpVotes,
    DownVotes);

LOAD DATA LOCAL INFILE 'badges.csv' INTO TABLE badges FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(Id,UserId,Date);

LOAD DATA LOCAL INFILE 'posts.csv' INTO TABLE posts FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
	PostTypeId,
	CreationDate,
	Score,
	ViewCount,
	OwnerUserId,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    LastEditorUserId);


LOAD DATA LOCAL INFILE 'tags.csv' INTO TABLE tags FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(Id,Count,ExcerptPostId);


LOAD DATA LOCAL INFILE 'postLinks.csv' INTO TABLE postLinks FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
	CreationDate,
	PostId,
	RelatedPostId,
	LinkTypeId);


LOAD DATA LOCAL INFILE 'postHistory.csv' INTO TABLE postHistory FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
	PostHistoryTypeId,
	PostId,
	CreationDate,
	UserId);

LOAD DATA LOCAL INFILE 'comments.csv' INTO TABLE comments FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(  Id,
	PostId,
	Score,
    CreationDate,
	UserId);


LOAD DATA LOCAL INFILE 'votes.csv' INTO TABLE votes FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
	PostId,
	VoteTypeId,
	CreationDate,
	UserId,
	BountyAmount);