
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Posts p
    LEFT JOIN Users U ON p.OwnerUserId = U.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 AND p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, U.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM Users U
    JOIN Posts p ON U.Id = p.OwnerUserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.OwnerDisplayName,
    r.RankScore,
    r.CommentCount,
    r.TotalUpVotes,
    r.TotalDownVotes,
    u.TotalViews,
    u.TotalScore,
    u.PostCount
FROM RankedPosts r
JOIN TopUsers u ON r.OwnerDisplayName = u.DisplayName
WHERE r.RankScore <= 5
ORDER BY u.TotalScore DESC, r.Score DESC;
