
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        Score, 
        ViewCount, 
        CommentCount, 
        VoteCount 
    FROM RankedPosts 
    WHERE PostRank <= 5
),
PostUserDetails AS (
    SELECT 
        u.DisplayName, 
        u.Reputation, 
        tp.Title, 
        tp.Score, 
        tp.ViewCount, 
        tp.CommentCount, 
        tp.VoteCount 
    FROM TopPosts tp
    JOIN Users u ON tp.Id = u.Id
)
SELECT 
    pud.DisplayName, 
    pud.Reputation, 
    pud.Title, 
    pud.Score, 
    pud.ViewCount, 
    pud.CommentCount, 
    pud.VoteCount
FROM PostUserDetails pud
ORDER BY pud.Reputation DESC, pud.Score DESC;
