
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        pt.Name AS PostType,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.PostType
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.PostType,
    COALESCE(ut.Reputation, 0) AS UserReputation
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN 
    Users ut ON u.Id = tp.PostId
ORDER BY 
    tp.UpVotes DESC, 
    tp.CommentCount DESC;
