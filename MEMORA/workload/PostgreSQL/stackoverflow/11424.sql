
WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalOwners
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalVotes,
        MAX(CreationDate) AS LastVoteDate
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    pt.Name AS PostType,
    pc.TotalPosts,
    pc.TotalOwners,
    uc.TotalUsers,
    uc.TotalReputation,
    uc.AvgReputation,
    SUM(vc.TotalVotes) AS TotalVotes,
    MAX(vc.LastVoteDate) AS LastVoteDate
FROM 
    PostCounts pc
JOIN 
    PostTypes pt ON pc.PostTypeId = pt.Id
CROSS JOIN 
    UserCounts uc
LEFT JOIN 
    VoteCounts vc ON vc.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pc.PostTypeId)
GROUP BY 
    pt.Name, pc.TotalPosts, pc.TotalOwners, uc.TotalUsers, uc.TotalReputation, uc.AvgReputation
ORDER BY 
    pc.TotalPosts DESC;
