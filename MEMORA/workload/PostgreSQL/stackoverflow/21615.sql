WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
        AND p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.ViewCount,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    (SELECT COUNT(v.Id) 
     FROM Votes v 
     WHERE v.PostId = t.PostId 
     AND v.VoteTypeId IN (2, 3, 7) 
    ) AS VoteCount,
    (SELECT STRING_AGG(DISTINCT tag.TagName, ', ') 
     FROM Tags tag 
     INNER JOIN LATERAL (
         SELECT 
             unnest(string_to_array(t.Title, ' ')) AS TagName 
     ) AS split_tags ON tag.TagName = split_tags.TagName
    ) AS AssociatedTags
FROM 
    TopPosts t
LEFT JOIN 
    Users u ON t.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
ORDER BY 
    t.Score DESC, 
    t.ViewCount DESC
LIMIT 10;