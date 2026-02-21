
LOAD DATA LOCAL INFILE 'users.csv' INTO TABLE users FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
    Reputation,
    CreationDate,
    DisplayName,
    LastAccessDate,
    WebsiteUrl,
    Location,
    AboutMe,
    Views,
    UpVotes,
    DownVotes,
    AccountId,
    Age,
    ProfileImageUrl);

LOAD DATA LOCAL INFILE 'badges.csv' INTO TABLE badges FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(Id, UserId, Name, Date);

LOAD DATA LOCAL INFILE 'posts.csv' INTO TABLE posts FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
    PostTypeId,
    AcceptedAnswerId,
    CreationDate,
    Score,
    ViewCount,
    Body,
    OwnerUserId,
    LasActivityDate,
    Title,
    Tags,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    LastEditorUserId,
    LastEditDate,
    CommunityOwnedDate,
    ParentId,
    ClosedDate,
    OwnerDisplayName,
    LastEditorDisplayName);


LOAD DATA LOCAL INFILE 'tags.csv' INTO TABLE tags FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(Id, TagName, Count, ExcerptPostId, WikiPostId);


LOAD DATA LOCAL INFILE 'postLinks.csv' INTO TABLE postLinks FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(Id, CreationDate, PostId, RelatedPostId, LinkTypeId);

LOAD DATA LOCAL INFILE 'postHistory.csv' INTO TABLE postHistory FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
    PostHistoryTypeId,
    PostId,
    RevisionGUID,
    CreationDate,
    UserId,
    Text,
    Comment,
    UserDisplayName);

LOAD DATA LOCAL INFILE 'comments.csv' INTO TABLE comments FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(   Id,
    PostId,
    Score,
    Text,
    CreationDate,
    UserId,
    UserDisplayName);


LOAD DATA LOCAL INFILE 'votes.csv' INTO TABLE votes FIELDS TERMINATED by ',' OPTIONALLY ENCLOSED BY '"' 
(Id, PostId, VoteTypeId, CreationDate, UserId, BountyAmount);