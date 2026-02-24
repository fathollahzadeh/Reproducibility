WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
        AVG(ViewCount) AS AverageViewCount
    FROM Posts
),

UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM Users
),

CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM Comments
),

VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        AVG(BountyAmount) AS AverageBountyAmount
    FROM Votes
)

SELECT 
    (SELECT TotalPosts FROM PostStats) AS TotalPosts,
    (SELECT UniquePostOwners FROM PostStats) AS UniquePostOwners,
    (SELECT AverageViewCount FROM PostStats) AS AverageViewCount,
    (SELECT TotalUsers FROM UserStats) AS TotalUsers,
    (SELECT AverageReputation FROM UserStats) AS AverageReputation,
    (SELECT TotalComments FROM CommentStats) AS TotalComments,
    (SELECT AverageCommentScore FROM CommentStats) AS AverageCommentScore,
    (SELECT TotalVotes FROM VoteStats) AS TotalVotes,
    (SELECT AverageBountyAmount FROM VoteStats) AS AverageBountyAmount;