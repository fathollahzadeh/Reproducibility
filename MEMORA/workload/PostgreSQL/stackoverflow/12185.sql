
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),

PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.Score,
        Posts.ViewCount,
        COALESCE(Comments.CommentCount, 0) AS CommentCount,
        COALESCE(Votes.VoteCount, 0) AS VoteCount,
        Posts.OwnerUserId
    FROM 
        Posts
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS Comments ON Posts.Id = Comments.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS Votes ON Posts.Id = Votes.PostId
)

SELECT 
    U.UserId,
    U.PostCount,
    U.UpVotes,
    U.DownVotes,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.CommentCount,
    P.VoteCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.UserId DESC, P.Score DESC;
