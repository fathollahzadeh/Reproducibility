
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankPerType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPostScores AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts 
    WHERE 
        RankPerType <= 5
),
PostStats AS (
    SELECT 
        ps.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        TopPostScores ps
    LEFT JOIN 
        Comments c ON ps.PostId = c.PostId
    LEFT JOIN 
        Votes v ON ps.PostId = v.PostId
    GROUP BY 
        ps.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.OwnerDisplayName,
    s.CommentCount,
    s.UpVotes,
    s.DownVotes
FROM 
    TopPostScores ps
JOIN 
    PostStats s ON ps.PostId = s.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
