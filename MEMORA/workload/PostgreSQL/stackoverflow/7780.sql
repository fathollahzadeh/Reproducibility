WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        rp.*, 
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted' 
        END AS AnswerStatus
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.AnswerStatus,
    COALESCE(au.DisplayName, 'Anonymous') AS OwnerDisplayName
FROM 
    TopPosts tp
LEFT JOIN 
    Users au ON tp.AcceptedAnswerId = au.Id
ORDER BY 
    tp.Score DESC;