
WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY u.Reputation DESC) AS LocationRank
    FROM Users u
    WHERE u.Reputation > 1000
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE(MAX(v.VoteTypeId), 0) AS MaxVoteType,
        p.OwnerUserId,
        p.CreationDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.PostTypeId, p.Score, p.OwnerUserId, p.CreationDate
), 
PostStats AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.PostTypeId = 1 THEN pd.Score * 2 
            ELSE pd.Score 
        END AS AdjustedScore
    FROM PostDetails pd
), 
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.CreationDate AS ClosedDate,
        r.DisplayName AS Reason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN Users r ON ph.UserId = r.Id
    WHERE pht.Name = 'Post Closed' 
          AND ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.AdjustedScore DESC) AS OverallRank,
        AVG(CASE WHEN loc.LocationRank IS NOT NULL THEN loc.Reputation END) OVER (PARTITION BY ps.OwnerUserId) AS AvgLocationReputation
    FROM PostStats ps
    LEFT JOIN UserRankings loc ON ps.OwnerUserId = loc.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.AdjustedScore,
    c.ClosedDate,
    c.Reason,
    rp.OverallRank,
    rp.AvgLocationReputation
FROM RankedPosts rp
LEFT JOIN ClosedPosts c ON rp.PostId = c.Id
WHERE (rp.CommentCount > 0 OR c.ClosedDate IS NOT NULL)
      AND rp.AdjustedScore IS NOT NULL
      AND rp.AvgLocationReputation > 0
ORDER BY rp.OverallRank, rp.Score DESC
LIMIT 100;
