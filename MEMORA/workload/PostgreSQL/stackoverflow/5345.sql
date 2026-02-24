WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
), RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        rc.LastCommentDate,
        rp.PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentComments rc ON rp.PostId = rc.PostId
)
SELECT 
    cd.Title,
    cd.CreationDate,
    cd.Score,
    cd.ViewCount,
    cd.OwnerDisplayName,
    cd.CommentCount,
    cd.PostRank
FROM 
    CombinedData cd
WHERE 
    cd.PostRank = 1
ORDER BY 
    cd.Score DESC, cd.ViewCount DESC
LIMIT 10;
