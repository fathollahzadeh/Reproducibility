WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(p.ViewCount) AS AverageViewCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(CASE WHEN p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 1 ELSE 0 END) AS OldPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

PostTypeCount AS (
    SELECT 
        pt.Id AS PostTypeId,
        COUNT(p.Id) AS PostCount
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Id
)

SELECT 
    u.DisplayName,
    ups.PostCount,
    ups.PositiveScoreCount,
    ups.AverageViewCount,
    ups.AcceptedAnswerCount,
    ups.OldPostCount,
    pt.PostTypeId,
    pt.PostCount AS PostTypePostCount
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
JOIN 
    PostTypeCount pt ON ups.PostCount > 0
ORDER BY 
    ups.PostCount DESC, u.DisplayName;