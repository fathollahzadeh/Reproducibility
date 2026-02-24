
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        rn <= 3
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostWithVoteCounts AS (
    SELECT 
        tp.*,
        COALESCE(pvc.Upvotes, 0) AS Upvotes,
        COALESCE(pvc.Downvotes, 0) AS Downvotes
    FROM 
        TopPosts tp
    LEFT JOIN PostVoteCounts pvc ON tp.PostId = pvc.PostId
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Score,
    pwc.Upvotes,
    pwc.Downvotes,
    pwc.CreationDate,
    pwc.OwnerName,
    ROUND((pwc.Upvotes::decimal / NULLIF((pwc.Upvotes + pwc.Downvotes), 0)) * 100, 2) AS UpvotePercentage
FROM 
    PostWithVoteCounts pwc
WHERE 
    pwc.Upvotes + pwc.Downvotes > 0
ORDER BY 
    pwc.Score DESC, 
    UpvotePercentage DESC
LIMIT 10;
