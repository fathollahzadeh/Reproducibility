WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.UpVotes,
    u.DisplayName AS Author,
    u.Reputation,
    (SELECT 
        STRING_AGG(pt.Name, ', ') 
     FROM 
        PostTypes pt 
     WHERE 
        pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = t.PostId)) AS PostType
FROM 
    TopPosts t
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts p WHERE p.Id = t.PostId);