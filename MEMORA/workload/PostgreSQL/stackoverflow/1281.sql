
WITH UserReputation AS (
    SELECT
        Id AS UserId,
        DisplayName,
        Reputation,
        LastAccessDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        Users
),
PopularPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN va.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN va.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SUM(CASE WHEN va.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN va.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS Score
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes va ON p.Id = va.PostId
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title
),
PostHistories AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pt.Name || ' (' || CAST(ph.CreationDate AS DATE) || ')', ', ') AS History,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM
        PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY
        ph.PostId
)
SELECT
    u.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    pp.PostId,
    pp.Title,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.Score,
    ph.History,
    ph.LastChangeDate
FROM
    UserReputation ur
JOIN Users u ON ur.UserId = u.Id
JOIN Posts p ON p.OwnerUserId = u.Id
JOIN PopularPosts pp ON p.Id = pp.PostId
LEFT JOIN PostHistories ph ON p.Id = ph.PostId
WHERE
    ur.Reputation > 1000
ORDER BY
    pp.Score DESC NULLS LAST,
    ur.ReputationRank
LIMIT 50;
