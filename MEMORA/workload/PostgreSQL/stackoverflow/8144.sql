WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
DetailedPostStats AS (
    SELECT 
        tp.*,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3), 0) AS Downvotes,
        COALESCE((SELECT ARRAY_AGG(b.Name) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)), '{}') AS UserBadges
    FROM 
        TopPosts tp
)
SELECT 
    *,
    (Score + Upvotes - Downvotes) AS NetCommunityScore
FROM 
    DetailedPostStats
ORDER BY 
    NetCommunityScore DESC, CreationDate DESC;