WITH PostTypeStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Name
),
PostHistoryStats AS (
    SELECT 
        pht.Name AS PostHistoryTypeName,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        pht.Name
)

SELECT 
    pts.PostTypeName,
    pts.PostCount,
    pts.AverageUserReputation,
    phs.PostHistoryTypeName,
    phs.HistoryCount
FROM 
    PostTypeStats pts
LEFT JOIN 
    PostHistoryStats phs ON phs.PostHistoryTypeName IS NOT NULL
ORDER BY 
    pts.PostCount DESC;