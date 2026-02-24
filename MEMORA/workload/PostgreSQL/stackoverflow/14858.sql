WITH PostVoteSummary AS (
    SELECT 
        p.PostTypeId,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.PostTypeId
),
PostCount AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        PostTypeId
)
SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(pvs.UniqueUsers, 0) AS UniqueUsers,
    COALESCE(pvs.TotalReputation, 0) AS TotalReputation,
    COALESCE(pc.PostCount, 0) AS PostCount,
    CASE 
        WHEN COALESCE(pc.PostCount, 0) > 0 THEN COALESCE(pvs.TotalVotes, 0) * 1.0 / pc.PostCount 
        ELSE 0 
    END AS AvgVotesPerPost,
    CASE 
        WHEN COALESCE(pvs.UniqueUsers, 0) > 0 THEN COALESCE(pvs.TotalReputation, 0) * 1.0 / pvs.UniqueUsers 
        ELSE 0 
    END AS AvgReputationPerUser
FROM 
    PostTypes pt
LEFT JOIN 
    PostVoteSummary pvs ON pt.Id = pvs.PostTypeId
LEFT JOIN 
    PostCount pc ON pt.Id = pc.PostTypeId
ORDER BY 
    pt.Id;