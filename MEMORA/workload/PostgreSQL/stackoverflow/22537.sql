WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND
        p.ViewCount > 0
),
TagsWithHighCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON position(t.TagName IN p.Tags) > 0
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        COUNT(p.Id) > 100
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        UserRank
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.ViewCount, 
    rp.Score, 
    COALESCE(badge.BadgeCount, 0) AS TotalBadges,
    CASE 
        WHEN rp.RankByViews < 5 OR rp.RankByScore < 5 THEN 'Underperforming'
        WHEN EXISTS (
            SELECT 1 
            FROM TagsWithHighCount t 
            WHERE position(t.TagName IN rp.Title) > 0
        ) THEN 'Trending Topic'
        ELSE 'Well-Performed'
    END AS PerformanceCategory,
    u.DisplayName AS TopUser
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges badge ON badge.UserId = rp.PostId 
CROSS JOIN 
    (SELECT DisplayName FROM TopUsers WHERE UserRank = 1) u
WHERE 
    rp.RankByViews <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;