WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum
    FROM Posts p
    WHERE p.Score IS NOT NULL
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    tp.PostId,
    tp.Title,
    tp.Score AS TopPostScore
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN TopPosts tp ON u.Id = tp.OwnerUserId AND tp.RowNum = 1
WHERE 
    (ub.BadgeCount IS NOT NULL OR ps.PostCount IS NOT NULL)
ORDER BY 

    CASE 
        WHEN ub.BadgeCount IS NULL THEN 1 
        ELSE 0 
    END,
    CASE 
        WHEN ps.PostCount IS NULL THEN 1 
        ELSE 0 
    END,
    u.DisplayName ASC;