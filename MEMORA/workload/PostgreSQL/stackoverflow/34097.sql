WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.TotalViews,
    u.TotalBounties,
    COALESCE(tp.PostCount, 0) AS TotalTags,
    COALESCE(tp.TotalViews, 0) AS TotalTagViews
FROM 
    UserStatistics u
LEFT JOIN 
    (SELECT 
         t.TagName,
         COUNT(DISTINCT p.Id) AS PostCount,
         SUM(p.ViewCount) AS TotalViews
     FROM 
         Tags t
     JOIN 
         Posts p ON p.Tags LIKE '%' || t.TagName || '%'
     GROUP BY 
         t.TagName) tp ON tp.TagName IN (SELECT DISTINCT Tags FROM Posts WHERE OwnerUserId = u.UserId)
WHERE 
    u.QuestionCount > 0 
ORDER BY 
    u.TotalViews DESC
LIMIT 10;