WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalPostOwners,
        AVG(ViewCount) AS AverageViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        AVG(Views) AS AverageViewsPerUser
    FROM 
        Users
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        AVG(BountyAmount) AS AverageBountyAmount
    FROM 
        Votes
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
)

SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT TotalPostOwners FROM PostStats) AS TotalPostOwners,
    (SELECT AverageViews FROM PostStats) AS AveragePostViews,
    (SELECT AverageScore FROM PostStats) AS AveragePostScore,
    
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT AverageReputation FROM UserStats) AS AverageUserReputation,
    (SELECT AverageViewsPerUser FROM UserStats) AS AverageViewsPerUser,
    
    (SELECT TotalVotes FROM VoteStats) AS TotalVotes,
    (SELECT AverageBountyAmount FROM VoteStats) AS AverageBountyAmount,
    
    (SELECT TotalComments FROM CommentStats) AS TotalComments,
    (SELECT AverageCommentScore FROM CommentStats) AS AverageCommentScore;