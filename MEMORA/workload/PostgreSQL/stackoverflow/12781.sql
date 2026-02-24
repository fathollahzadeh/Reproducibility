WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryTypesCount AS (
    SELECT 
        pht.Name AS PostHistoryType,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        pht.Name
)
SELECT 
    pc.PostTypeId,
    pc.TotalPosts,
    pc.AcceptedAnswers,
    pc.TotalViews,
    pc.AvgScore,
    um.TotalBadges,
    um.TotalBounty,
    phc.PostHistoryType,
    phc.HistoryCount
FROM 
    PostCounts pc
JOIN 
    UserMetrics um ON um.UserId = (SELECT MIN(Id) FROM Users) 
CROSS JOIN 
    PostHistoryTypesCount phc
ORDER BY 
    pc.PostTypeId;