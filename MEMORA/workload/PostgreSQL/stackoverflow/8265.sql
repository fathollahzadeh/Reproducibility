WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        t.PostId,
        t.Title,
        t.CreationDate,
        t.Score,
        t.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        c.LastCommentDate
    FROM 
        TopPosts t
    LEFT JOIN 
        CommentStats c ON t.PostId = c.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.OwnerDisplayName,
    fr.CommentCount,
    fr.LastCommentDate
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC;