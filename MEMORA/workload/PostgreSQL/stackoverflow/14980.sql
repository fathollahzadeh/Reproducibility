WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.BadgeCount,
    RANK() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank,
    RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
FROM 
    RankedPosts rp
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;