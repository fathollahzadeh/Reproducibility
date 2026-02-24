
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerUserId,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostDetails AS (
    SELECT 
        t.PostId,
        t.Title,
        t.Score,
        t.OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        TopPosts t
    LEFT JOIN 
        Comments c ON t.PostId = c.PostId
    LEFT JOIN 
        Votes v ON t.PostId = v.PostId
    GROUP BY 
        t.PostId, t.Title, t.Score, t.OwnerDisplayName
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.CommentCount,
    pd.VoteCount,
    pd.UpVoteCount,
    pd.DownVoteCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC;
