WITH PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Votes.Id) AS TotalVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN Badges.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Badges ON Posts.OwnerUserId = Badges.UserId
    WHERE 
        Posts.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'  
    GROUP BY 
        Posts.Id
)
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(TotalComments) AS AvgCommentsPerPost,
    AVG(TotalVotes) AS AvgVotesPerPost,
    AVG(UpVotes) AS AvgUpVotesPerPost,
    AVG(DownVotes) AS AvgDownVotesPerPost,
    AVG(TotalBadges) AS AvgBadgesPerPost
FROM 
    PostStats;