WITH PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
    FROM 
        Posts
),

VoteCounts AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT UserId) AS UniqueVoters
    FROM 
        Votes
),

CommentCounts AS (
    SELECT 
        COUNT(*) AS TotalComments,
        COUNT(DISTINCT UserId) AS UniqueCommenters
    FROM 
        Comments
),

UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(CASE WHEN Reputation > 0 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM 
        Users
)

SELECT 
    pc.TotalPosts,
    pc.UniquePostOwners,
    vc.TotalVotes,
    vc.UniqueVoters,
    cc.TotalComments,
    cc.UniqueCommenters,
    uc.TotalUsers,
    uc.ActiveUsers
FROM 
    PostCounts pc,
    VoteCounts vc,
    CommentCounts cc,
    UserCounts uc;