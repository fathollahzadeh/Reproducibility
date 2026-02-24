
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT pl.RelatedPostId) AS LinkedPostsCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.EditCount,
        rp.LinkedPostsCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerRank <= 5 
),
CommentStatistics AS (
    SELECT 
        p.PostId,
        AVG(LENGTH(c.Text)) AS AverageCommentLength,
        MAX(LENGTH(c.Text)) AS LongestCommentLength
    FROM 
        FilteredPosts p
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    GROUP BY 
        p.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.EditCount,
    fp.LinkedPostsCount,
    cs.AverageCommentLength,
    cs.LongestCommentLength,
    CASE 
        WHEN fp.ViewCount > 100 THEN 'High Engagement' 
        WHEN fp.ViewCount BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement' 
    END AS EngagementLevel
FROM 
    FilteredPosts fp
LEFT JOIN 
    CommentStatistics cs ON fp.PostId = cs.PostId
ORDER BY 
    fp.ViewCount DESC, 
    fp.CommentCount DESC;
