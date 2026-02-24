
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ScoreRank,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.CommentCount,
    fp.VoteCount,
    COUNT(DISTINCT b.UserId) AS BadgeCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON b.UserId IN (
        SELECT DISTINCT po.OwnerUserId FROM Posts po WHERE po.Id = fp.PostId
    )
GROUP BY 
    fp.PostId, fp.Title, fp.Score, fp.ViewCount, fp.CreationDate, fp.LastActivityDate, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
