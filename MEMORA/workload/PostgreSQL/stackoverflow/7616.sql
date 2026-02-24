
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' AND 
        p.Score > 0
), 
PostStats AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Comments c
    JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.PostId
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostStats ps ON rp.PostId = ps.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    COALESCE(t.CommentCount, 0) AS TotalComments,
    COALESCE(t.UpVotes, 0) AS TotalUpVotes,
    COALESCE(t.DownVotes, 0) AS TotalDownVotes
FROM 
    TopPosts t
ORDER BY 
    t.Score DESC;
