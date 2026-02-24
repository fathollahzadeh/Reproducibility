
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(uv.VoteCount, 0) AS VoteCount
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.PostId
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC, uv.VoteCount DESC;
