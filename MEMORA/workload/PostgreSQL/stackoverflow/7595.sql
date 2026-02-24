
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        Score, 
        CommentCount, 
        UpVotes, 
        DownVotes 
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 10
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.Score,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    pt.Name AS PostType
FROM 
    TopPosts t
JOIN 
    PostTypes pt ON (SELECT PostTypeId FROM Posts WHERE Id = t.PostId) = pt.Id
ORDER BY 
    t.Score DESC, 
    t.CreationDate DESC;
