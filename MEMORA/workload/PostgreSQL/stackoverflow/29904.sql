
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN a.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
    INNER JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.AnswerCount,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        ph.Comment AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY tp.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistory ph ON ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (4, 5) 
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.AnswerCount,
    pd.LastEditor,
    pd.LastEditDate,
    pd.LastEditComment
FROM 
    PostDetails pd
WHERE 
    pd.EditRank = 1;
