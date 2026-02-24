WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        (CASE 
             WHEN u.Reputation >= 1000 THEN 'High'
             WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Medium'
             ELSE 'Low'
         END) AS ReputationCategory
    FROM
        Users u
    WHERE
        u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UsefulVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HarmfulVotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
),
CombinedData AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.ScoreRank,
        rp.TotalPosts,
        rp.UpVotes,
        rp.DownVotes,
        ur.ReputationCategory,
        pvc.UsefulVotes,
        pvc.HarmfulVotes
    FROM
        RankedPosts rp
    JOIN UserReputation ur ON rp.PostId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
)
SELECT
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.Score,
    cd.ScoreRank,
    cd.TotalPosts,
    cd.UpVotes,
    cd.DownVotes,
    cd.ReputationCategory,
    cd.UsefulVotes,
    cd.HarmfulVotes
FROM
    CombinedData cd
WHERE
    cd.UsefulVotes IS NOT NULL
    AND (cd.ReputationCategory <> 'Low' OR cd.HarmfulVotes = 0)
ORDER BY
    cd.Score DESC,
    cd.ViewCount ASC
LIMIT 50;