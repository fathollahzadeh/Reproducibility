WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerName, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),

TopRankedPosts AS (
    SELECT * FROM RankedPosts 
    WHERE PostRank <= 10
)

SELECT 
    p.PostId, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.OwnerName, 
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpVotes, 
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 3) AS DownVotes, 
    p.CommentCount
FROM TopRankedPosts p
ORDER BY p.Score DESC, p.ViewCount DESC;