
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName) AS tag_ids ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CommentCount, 
        UpvoteCount, 
        DownvoteCount, 
        Tags
    FROM 
        RankedPosts
    WHERE 
        RN = 1 AND UpvoteCount > DownvoteCount
)
SELECT 
    fp.Title AS "Post Title",
    fp.OwnerDisplayName AS "Owner",
    fp.CommentCount AS "Number of Comments",
    fp.UpvoteCount AS "Number of Upvotes",
    fp.DownvoteCount AS "Number of Downvotes",
    fp.Tags AS "Associated Tags",
    ph.CreationDate AS "Post History Date",
    pht.Name AS "Post History Type"
FROM 
    FilteredPosts fp
JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    fp.UpvoteCount DESC, fp.CommentCount DESC
LIMIT 10;
