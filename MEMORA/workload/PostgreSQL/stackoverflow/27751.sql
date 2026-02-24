
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.OwnerPostRank <= 5 
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        ARRAY_AGG(DISTINCT rp.PostId) AS RelatedPostIds
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN RecentPosts rp ON p.Id = rp.PostId
    GROUP BY t.TagName
)
SELECT 
    ts.TagName, 
    ts.PostCount,
    ts.TotalViews,
    ts.AverageScore,
    (
        SELECT 
            COUNT(DISTINCT bp.Id)
        FROM 
            Posts bp
        WHERE 
            bp.OwnerUserId IN (SELECT DISTINCT OwnerUserId FROM RecentPosts) 
            AND bp.Tags LIKE CONCAT('%', ts.TagName, '%')
    ) AS RelatedUserPostCount
FROM 
    TagStats ts
ORDER BY 
    ts.TotalViews DESC 
LIMIT 10;
