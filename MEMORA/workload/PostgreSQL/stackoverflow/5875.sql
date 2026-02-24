
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
), RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(p.Score) AS AverageScore,
        COUNT(ph.Id) AS HistoryCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY p.OwnerUserId
)
SELECT 
    ru.DisplayName,
    ru.Upvotes,
    ru.Downvotes,
    ru.PostCount,
    rpa.CommentCount,
    rpa.AverageScore,
    rpa.HistoryCount
FROM RankedUsers ru
JOIN RecentPostActivity rpa ON ru.UserId = rpa.OwnerUserId
WHERE ru.UserRank <= 10
ORDER BY ru.Upvotes DESC, rpa.AverageScore DESC;
