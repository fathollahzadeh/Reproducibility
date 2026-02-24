
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostRanked AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        pr.PostId,
        pr.Title,
        pr.CreationDate,
        pr.Score,
        us.DisplayName,
        us.Reputation,
        us.TotalBounty
    FROM PostRanked pr
    JOIN UserStats us ON us.PostCount > 0
    WHERE pr.PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.DisplayName,
    tp.Reputation,
    tp.TotalBounty,
    CASE 
        WHEN tp.TotalBounty > 100 THEN 'High Bounty'
        WHEN tp.TotalBounty BETWEEN 50 AND 100 THEN 'Medium Bounty'
        ELSE 'Low Bounty' 
    END AS BountyCategory
FROM TopPosts tp
LEFT JOIN Comments c ON c.PostId = tp.PostId
WHERE c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.DisplayName, tp.Reputation, tp.TotalBounty
HAVING COUNT(c.Id) > 5
ORDER BY tp.Score DESC, tp.CreationDate DESC;
