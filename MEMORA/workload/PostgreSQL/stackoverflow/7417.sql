
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName, p.Tags
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.TagRank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS Badge,
        tp.CommentCount,
        p.LastActivityDate
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON tp.PostId = b.UserId
    JOIN 
        Posts p ON tp.PostId = p.Id
    ORDER BY 
        tp.Score DESC, tp.CommentCount DESC
)
SELECT 
    pd.Title,
    pd.Score,
    pd.OwnerDisplayName,
    pd.Badge,
    pd.CommentCount,
    pd.LastActivityDate
FROM 
    PostDetails pd
WHERE 
    pd.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
ORDER BY 
    pd.CommentCount DESC, pd.LastActivityDate DESC
LIMIT 10;
