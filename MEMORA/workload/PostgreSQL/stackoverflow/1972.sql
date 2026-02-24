WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS AuthorDisplayName
    FROM 
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AuthorDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostsWithVotes AS (
    SELECT 
        tp.*,
        COALESCE(vs.Upvotes, 0) AS Upvotes,
        COALESCE(vs.Downvotes, 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY tp.Score DESC, tp.ViewCount DESC) AS PostRank
    FROM 
        TopPosts tp
    LEFT JOIN 
        VoteStats vs ON tp.PostId = vs.PostId
)
SELECT 
    p.*,
    CASE 
        WHEN p.Score > 10 THEN 'Popular'
        WHEN p.Score BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = p.PostId AND c.Score > 0) THEN 'Has Positive Comments'
        ELSE 'No Positive Comments'
    END AS CommentStatus 
FROM 
    PostsWithVotes p 
WHERE 
    p.PostRank <= 10
ORDER BY 
    p.Score DESC, p.Upvotes DESC;