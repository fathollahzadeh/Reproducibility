
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS ClosedPostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.AvgViewCount,
        rpa.CommentCount,
        rpa.ClosedPostCount,
        rpa.LastPostDate
    FROM 
        UserPostStats ups
    LEFT JOIN 
        RecentPostActivity rpa ON ups.UserId = rpa.OwnerUserId
)
SELECT 
    fs.DisplayName,
    fs.PostCount,
    COALESCE(fs.TotalScore, 0) AS TotalScore,
    ROUND(COALESCE(fs.AvgViewCount, 0), 2) AS AvgViewCount,
    COALESCE(fs.CommentCount, 0) AS CommentCount,
    COALESCE(fs.ClosedPostCount, 0) AS ClosedPostCount,
    fs.LastPostDate
FROM 
    FinalStats fs
WHERE 
    fs.PostCount > 0 
    AND fs.LastPostDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
ORDER BY 
    fs.TotalScore DESC
LIMIT 10;
