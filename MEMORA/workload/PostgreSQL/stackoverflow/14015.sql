
WITH PostStatistics AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        Posts.CreationDate, 
        Posts.ViewCount, 
        Posts.Score,
        Users.Reputation AS OwnerReputation,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(Votes.Id) AS VoteCount,
        Posts.OwnerUserId  -- Added OwnerUserId to the group by clause
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.ViewCount, Posts.Score, Users.Reputation, Posts.OwnerUserId
),
BadgeStatistics AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.OwnerReputation,
    PS.CommentCount,
    PS.VoteCount,
    COALESCE(BS.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    PostStatistics PS
LEFT JOIN 
    BadgeStatistics BS ON PS.OwnerUserId = BS.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
