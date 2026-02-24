
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
RecentActivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        DENSE_RANK() OVER (ORDER BY rp.CreationDate DESC) AS RecentRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 
)
SELECT 
    rap.PostId,
    rap.Title,
    rap.OwnerDisplayName,
    rap.Tags,
    rap.CommentCount,
    rap.CreationDate,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = rap.PostId 
         AND v.VoteTypeId = 2), 0) AS UpvoteCount
FROM 
    RecentActivePosts rap
WHERE 
    rap.RecentRank <= 10 
ORDER BY 
    rap.CreationDate DESC;
