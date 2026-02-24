
WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.PostTypeId,
        COUNT(Votes.Id) AS VoteCount,
        COUNT(Comments.Id) AS CommentCount,
        MAX(Posts.CreationDate) AS LastActivityDate
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    WHERE 
        Posts.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.PostTypeId
),
UserStatistics AS (
    SELECT 
        Users.Id AS UserId,
        AVG(Users.Reputation) AS AvgReputation,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.VoteCount,
    PS.CommentCount,
    PS.LastActivityDate,
    US.UserId,
    US.AvgReputation,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges
FROM 
    PostStatistics PS
JOIN 
    Users U ON PS.PostTypeId = U.Id  
JOIN 
    UserStatistics US ON US.UserId = U.Id
ORDER BY 
    PS.LastActivityDate DESC;
