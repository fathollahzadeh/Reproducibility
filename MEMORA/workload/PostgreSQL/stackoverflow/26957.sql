
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpvoteCount,
        unnest(string_to_array(substring(tp.Body, 2, length(tp.Body)-2), '>')) AS TagName
    FROM 
        TopPosts tp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpvoteCount,
    ARRAY_AGG(DISTINCT pd.TagName) AS Tags,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    pd.PostId, pd.Title, pd.OwnerDisplayName, pd.CommentCount, pd.UpvoteCount
ORDER BY 
    pd.UpvoteCount DESC, pd.CommentCount DESC;
