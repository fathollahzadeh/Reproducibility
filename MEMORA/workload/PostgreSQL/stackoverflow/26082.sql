
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        OwnerDisplayName, 
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
PostInteraction AS (
    SELECT 
        t.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        TopPosts t
    LEFT JOIN 
        Comments c ON t.PostId = c.PostId
    LEFT JOIN 
        Votes v ON t.PostId = v.PostId
    GROUP BY 
        t.PostId
)
SELECT 
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.OwnerDisplayName,
    t.Score,
    pi.CommentCount,
    pi.UpvoteCount,
    pi.DownvoteCount,
    (pi.UpvoteCount - pi.DownvoteCount) AS NetVotes
FROM 
    TopPosts t
JOIN 
    PostInteraction pi ON t.PostId = pi.PostId
ORDER BY 
    t.Score DESC, NetVotes DESC;
