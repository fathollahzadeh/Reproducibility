WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
), 
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.CreationDate,
    au.DisplayName AS TopUser,
    au.Reputation AS UserReputation,
    au.BadgeCount AS UserBadgeCount,
    ts.PostsCount AS RelatedTagCount,
    ts.AverageScore AS TagAverageScore
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers au ON rp.RankByViews = 1
JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%', ts.TagName, '%')
WHERE 
    rp.RankByViews <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    au.Reputation DESC
LIMIT 10;