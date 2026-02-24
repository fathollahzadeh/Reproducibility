
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.DownvoteCount,
    CASE 
        WHEN fp.UpvoteCount > fp.DownvoteCount THEN 'Positive'
        WHEN fp.UpvoteCount < fp.DownvoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    ARRAY_AGG(v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpvotedBy,
    ARRAY_AGG(v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownvotedBy
FROM 
    FilteredPosts fp
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Tags, fp.CreationDate, fp.OwnerDisplayName, 
    fp.CommentCount, fp.UpvoteCount, fp.DownvoteCount
ORDER BY 
    fp.CreationDate DESC
LIMIT 10;
