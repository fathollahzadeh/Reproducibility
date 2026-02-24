
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName
),
PostStats AS (
    SELECT
        PostId,
        Title,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        (UpvoteCount - DownvoteCount) AS NetVotes,
        CASE 
            WHEN CommentCount > 10 THEN 'Highly Discussed'
            WHEN UpvoteCount > DownvoteCount THEN 'Popular'
            ELSE 'Less Popular'
        END AS Popularity
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.NetVotes,
    ps.Popularity,
    COALESCE((
        SELECT STRING_AGG(t.TagName, ', ')
        FROM Tags t
        JOIN LATERAL (
            SELECT unnest(string_to_array(p.Tags, '><')) AS tag
        ) AS split_tags ON t.TagName = split_tags.tag
        WHERE p.Id = ps.PostId
    ), 'No Tags') AS Tags
FROM 
    PostStats ps
LEFT JOIN 
    Posts p ON ps.PostId = p.Id
ORDER BY 
    ps.NetVotes DESC, ps.CommentCount DESC
LIMIT 20;
