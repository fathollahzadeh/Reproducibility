WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON c.PostId = tp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.VoteCount,
    CASE 
        WHEN pd.VoteCount >= 100 THEN 'Highly Voted'
        WHEN pd.VoteCount >= 50 THEN 'Moderately Voted'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostDetails pd
ORDER BY 
    pd.VoteCount DESC, 
    pd.CommentCount DESC;