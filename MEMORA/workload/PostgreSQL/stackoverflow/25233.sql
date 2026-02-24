
WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ph.CreationDate AS PostHistoryDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags tag
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', tag.TagName, '%')
    GROUP BY 
        tag.TagName
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        pi.PostId,
        pi.Title,
        pi.OwnerDisplayName,
        pi.PostHistoryDate,
        pi.Comment,
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.AverageScore
    FROM 
        PostInfo pi
    JOIN 
        TagStatistics ts ON pi.Tags LIKE CONCAT('%', ts.TagName, '%')
    WHERE 
        pi.HistoryRank = 1 AND pi.Comment IS NOT NULL
    ORDER BY 
        ts.TotalViews DESC
    LIMIT 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.PostHistoryDate,
    pp.Comment,
    u.DisplayName AS BadgeOwner,
    ub.BadgeCount
FROM 
    PopularPosts pp
LEFT JOIN 
    UserBadges ub ON pp.OwnerDisplayName = ub.DisplayName
LEFT JOIN 
    Users u ON pp.OwnerDisplayName = u.DisplayName
ORDER BY 
    pp.PostId;  -- Changed to pp.PostId, since pp.TotalViews is not selected
