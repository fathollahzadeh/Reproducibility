WITH CommentsPerPost AS (
    SELECT 
        PostId,
        COUNT(Id) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
VotesPerUser AS (
    SELECT 
        UserId,
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
BadgesPerUser AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    (SELECT AVG(CommentCount) FROM CommentsPerPost) AS AvgCommentsPerPost,
    (SELECT SUM(VoteCount) FROM VotesPerUser) AS TotalVotes,
    (SELECT SUM(BadgeCount) FROM BadgesPerUser) AS TotalBadges