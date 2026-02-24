
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ur.Reputation,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    pvs.VoteCount,
    pvs.AverageBounty,
    pvs.LastVoteDate
FROM RankedPosts rp
LEFT JOIN UserReputation ur ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
LEFT JOIN PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE rp.RankByDate <= 5
  AND (ur.Reputation IS NOT NULL OR (ur.Reputation IS NULL AND rp.AnswerCount > 0))
ORDER BY rp.CreationDate DESC, rp.Score DESC;
