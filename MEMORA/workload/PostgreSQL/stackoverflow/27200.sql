
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount
),
ProcessedTags AS (
    SELECT 
        pt.PostId,
        Tag
    FROM 
        RankedPosts pt,
        UNNEST(string_to_array(SUBSTRING(pt.Tags, 2, LENGTH(pt.Tags) - 2), '>')) AS Tag
),
TagStatistics AS (
    SELECT 
        p.Tag,
        COUNT(*) AS TagCount,
        STRING_AGG(DISTINCT rp.Title, '; ') AS RelatedPostTitles
    FROM 
        ProcessedTags p
    JOIN 
        RankedPosts rp ON p.PostId = rp.PostId
    GROUP BY 
        p.Tag
)
SELECT 
    ts.Tag,
    ts.TagCount,
    ts.RelatedPostTitles,
    COUNT(b.Id) AS UserBadgeCount,
    AVG(u.Reputation) AS AvgReputation
FROM 
    TagStatistics ts
LEFT JOIN 
    Posts p ON p.Title LIKE CONCAT('%', ts.Tag, '%')
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
WHERE 
    ts.TagCount > 3 
GROUP BY 
    ts.Tag, ts.TagCount, ts.RelatedPostTitles
ORDER BY 
    ts.TagCount DESC, AvgReputation DESC
LIMIT 10;
