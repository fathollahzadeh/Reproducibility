
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.CommentCount, 
        rp.VoteCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges 
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId IN (
            SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId
        )
    WHERE 
        rp.Rank <= 10 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, rp.VoteCount
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.CommentCount, 
    tp.VoteCount, 
    tp.TotalBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
