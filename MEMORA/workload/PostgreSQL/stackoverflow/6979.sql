
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)
),
TopPosts AS (
    SELECT 
        rp.*, 
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.Score, 
        tp.ViewCount, 
        tp.AnswerCount, 
        tp.CreationDate, 
        tp.OwnerDisplayName, 
        tp.PostTypeName, 
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CreationDate, tp.OwnerDisplayName, tp.PostTypeName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.TotalBounties,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.PostTypeName
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
