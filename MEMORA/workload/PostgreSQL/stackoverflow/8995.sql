
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate,
        rp.Score, 
        rp.ViewCount, 
        rp.Tags,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        bh.Name AS BadgeName,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.PostId = u.Id
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
        tp.CommentCount, u.DisplayName, u.Reputation, bh.Name
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    ARRAY_AGG(DISTINCT pd.BadgeName) AS Badges,
    pd.VoteCount
FROM 
    PostDetails pd
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.Score, pd.ViewCount, 
    pd.CommentCount, pd.OwnerDisplayName, pd.OwnerReputation, pd.VoteCount
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
