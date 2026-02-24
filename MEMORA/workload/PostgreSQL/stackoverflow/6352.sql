
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
), 
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.Tags,
    trp.CommentCount,
    trp.VoteCount,
    STRING_AGG(DISTINCT CONCAT(u.DisplayName, ': ', b.Name), '; ') AS UserBadges
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = trp.PostId)
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts p WHERE p.Id = trp.PostId)
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.ViewCount, trp.Tags, trp.CommentCount, trp.VoteCount
ORDER BY 
    trp.Score DESC;
