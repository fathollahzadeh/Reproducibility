
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(AVG(CASE WHEN c.Score IS NOT NULL THEN c.Score ELSE 0 END), 0) AS AverageCommentScore,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Upvotes,
        rp.Downvotes,
        rp.AverageCommentScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Upvotes,
    tp.Downvotes,
    tp.AverageCommentScore,
    u.DisplayName AS CreatorDisplayName,
    u.Reputation AS CreatorReputation,
    b.Count AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    (SELECT 
        UserId,
        COUNT(*) AS Count 
     FROM 
        Badges 
     GROUP BY 
        UserId) b ON u.Id = b.UserId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
