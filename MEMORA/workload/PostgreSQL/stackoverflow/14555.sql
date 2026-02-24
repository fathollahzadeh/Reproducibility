WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        u.Reputation AS UserReputation,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostCounts AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        AVG(UserReputation) AS AverageUserReputation
    FROM 
        RecentPosts
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(*) AS PostTypeCount
    FROM 
        RecentPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    pc.TotalPosts,
    pc.TotalUsers,
    pc.AverageUserReputation,
    ptc.PostTypeName,
    ptc.PostTypeCount
FROM 
    PostCounts pc
LEFT JOIN 
    PostTypeCounts ptc ON true  
ORDER BY 
    ptc.PostTypeName;