WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
),
AnswerCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(ac.AnswerCount, 0) AS AnswerCount,
    cp.FirstClosedDate,
    CASE 
        WHEN cp.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN r.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM RankedUsers r
LEFT JOIN RecentPosts rp ON r.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN AnswerCounts ac ON rp.PostId = ac.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    r.Reputation > 100
    AND (rp.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' OR cp.FirstClosedDate IS NOT NULL)
ORDER BY r.Reputation DESC, rp.CreationDate DESC;