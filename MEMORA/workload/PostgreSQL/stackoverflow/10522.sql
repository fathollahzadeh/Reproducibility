
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ut.Name AS PostType
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes ut ON p.PostTypeId = ut.Id
),
BadgeDetails AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.PostType,
    us.PostCount,
    us.TotalViews,
    us.AverageScore,
    COALESCE(bd.BadgeCount, 0) AS BadgeCount
FROM PostDetails pd
JOIN UserPostStats us ON pd.OwnerUserId = us.OwnerUserId
LEFT JOIN BadgeDetails bd ON pd.OwnerUserId = bd.UserId
ORDER BY pd.ViewCount DESC
LIMIT 100;
