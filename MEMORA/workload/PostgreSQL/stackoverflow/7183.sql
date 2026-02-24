WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ViewCount DESC, UpvoteCount DESC) AS OverallRank
    FROM 
        RankedPosts
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    OverallRank
FROM 
    TopPosts
WHERE 
    OverallRank <= 10
ORDER BY 
    OverallRank;