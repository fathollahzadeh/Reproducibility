
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.Score,
        r.CreationDate
    FROM 
        RankedPosts r
    WHERE 
        r.PostRank <= 5 
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        (
            SELECT 
                unnest(string_to_array(Posts.Tags, ', ')) AS TagName,
                Posts.Id AS PostId
            FROM 
                Posts
        ) t ON t.PostId = tp.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.CreationDate
),
VotesSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.CreationDate,
    pd.Tags,
    COALESCE(vs.Upvotes, 0) AS Upvotes,
    COALESCE(vs.Downvotes, 0) AS Downvotes
FROM 
    PostDetails pd
LEFT JOIN 
    VotesSummary vs ON pd.PostId = vs.PostId
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
