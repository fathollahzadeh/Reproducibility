
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        ur.UserID,
        ur.Reputation,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserID
    WHERE 
        rp.OwnerPostRank <= 5
)
SELECT 
    tp.PostID,
    tp.Title,
    tp.CreationDate,
    tp.Reputation,
    tp.CommentCount,
    tp.VoteCount
FROM 
    TopPosts tp
ORDER BY 
    tp.VoteCount DESC, tp.CommentCount DESC
LIMIT 10;
