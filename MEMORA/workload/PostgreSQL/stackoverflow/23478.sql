
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        CASE 
            WHEN Reputation < 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Regular'
            ELSE 'Expert'
        END AS ReputationGroup
    FROM Users
),
PostsWithReputation AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        ur.Reputation,
        ur.ReputationGroup,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN UserReputation ur ON p.OwnerUserId = ur.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, ur.Reputation, ur.ReputationGroup
),
PostHistoryWithTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    LEFT JOIN Tags t ON t.WikiPostId = p.Id
    WHERE ph.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
    GROUP BY ph.PostId
)
SELECT 
    pwr.PostId,
    pwr.Title,
    pwr.Reputation,
    pwr.ReputationGroup,
    pwr.ViewCount,
    pwr.CommentCount,
    pwr.UpVotes,
    pwr.DownVotes,
    pht.Tags,
    pht.LastEditDate,
    COALESCE(pht.CloseReason, 'N/A') AS CloseReason,
    CASE 
        WHEN pwr.CommentCount > 50 THEN 'Highly Engaged'
        WHEN pwr.CommentCount BETWEEN 20 AND 50 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM PostsWithReputation pwr
LEFT JOIN PostHistoryWithTags pht ON pwr.PostId = pht.PostId
WHERE pwr.ReputationGroup = 'Expert'
AND (pwr.UpVotes - pwr.DownVotes) > 0
ORDER BY pwr.ViewCount DESC, pwr.Reputation DESC
LIMIT 100;
