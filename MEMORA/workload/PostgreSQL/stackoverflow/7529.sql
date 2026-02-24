
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
        LEFT JOIN Users U ON p.OwnerUserId = U.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, U.DisplayName, p.OwnerUserId
), 
TopComments AS (
    SELECT 
        c.PostId,
        c.Text,
        c.UserDisplayName,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    tc.Text AS RecentComment,
    tc.UserDisplayName AS Commenter,
    tc.CreationDate AS CommentDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TopComments tc ON rp.PostId = tc.PostId AND tc.CommentRank = 1
WHERE 
    rp.OwnerPostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
