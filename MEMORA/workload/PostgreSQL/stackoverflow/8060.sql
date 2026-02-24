
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 
        AND p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
), 
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        RankedPosts p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
), 
TopRatedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.Upvotes,
        ps.Downvotes,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PostRank
    FROM 
        PostStatistics ps
)
SELECT 
    t.Title,
    t.ViewCount,
    t.Score,
    t.AnswerCount,
    t.Upvotes,
    t.Downvotes,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.Location
FROM 
    TopRatedPosts t
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
WHERE 
    t.PostRank <= 10
ORDER BY 
    t.PostRank;
