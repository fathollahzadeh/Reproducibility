WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        PostType
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
), 
PostDetails AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.CreationDate, 
        tp.Score, 
        tp.OwnerDisplayName, 
        tp.PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.PostType
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.VoteCount,
    pd.OwnerDisplayName,
    pd.PostType,
    CASE 
        WHEN pd.Score >= 100 THEN 'Hot'
        WHEN pd.Score BETWEEN 50 AND 99 THEN 'Trending'
        ELSE 'New'
    END AS EngagementLevel
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC,
    pd.CreationDate ASC;