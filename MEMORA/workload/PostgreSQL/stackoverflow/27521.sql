WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPostsPerTag AS (
    SELECT 
        rp.TagRank,
        rp.Tags,
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId = 8 
    WHERE 
        rp.TagRank = 1 
    GROUP BY 
        rp.TagRank, rp.Tags, rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score
),
PostsWithBadges AS (
    SELECT 
        t.Tags,
        t.Title,
        t.OwnerDisplayName,
        t.CreationDate,
        t.Score,
        b.Name AS BadgeName,
        b.Class
    FROM 
        TopPostsPerTag t
    LEFT JOIN 
        Badges b ON t.PostId = b.UserId 
)
SELECT 
    Tags,
    Title,
    OwnerDisplayName,
    CreationDate,
    Score,
    STRING_AGG(BadgeName, ', ') AS BadgeNames,
    COUNT(DISTINCT BadgeName) AS BadgeCount
FROM 
    PostsWithBadges
GROUP BY 
    Tags, Title, OwnerDisplayName, CreationDate, Score
ORDER BY 
    Score DESC, CreationDate DESC;