
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.ViewCount, 
        rp.Score, 
        rp.OwnerDisplayName, 
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    tp.Title, 
    tp.OwnerDisplayName, 
    tp.ViewCount, 
    tp.Score, 
    tp.CommentCount, 
    tp.VoteCount, 
    u.DisplayName AS TopUser, 
    u.Reputation, 
    u.PostCount
FROM 
    TopPosts tp
JOIN 
    UserReputation u ON tp.OwnerDisplayName = u.DisplayName
ORDER BY 
    tp.Score DESC, 
    u.Reputation DESC
LIMIT 20;
