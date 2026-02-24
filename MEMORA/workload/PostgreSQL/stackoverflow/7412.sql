
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        p.PostTypeId,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5 AND rp.Score > 0
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.VoteCount,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    pt.Name AS PostTypeName,
    b.Name AS BadgeName,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
JOIN 
    PostTypes pt ON fp.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = fp.OwnerUserId AND b.Class = 1
LEFT JOIN 
    Tags t ON t.ExcerptPostId = fp.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.CommentCount, fp.VoteCount, 
    fp.OwnerDisplayName, fp.OwnerReputation, pt.Name, b.Name
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
