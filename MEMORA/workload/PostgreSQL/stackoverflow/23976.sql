
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation IS NULL OR Reputation < 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            WHEN Reputation BETWEEN 501 AND 1000 THEN 'Experienced'
            ELSE 'Veteran'
        END AS ReputationTier
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
EnhancedPostMetrics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.Score, 0) AS CommentScore,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS VoteNet,
        up.ReputationTier
    FROM RecentPosts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.PostId = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(Score) AS Score
        FROM Comments
        GROUP BY PostId
    ) c ON p.PostId = c.PostId
    LEFT JOIN UserReputation up ON p.OwnerUserId = up.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        MIN(h.CreationDate) AS FirstCloseDate
    FROM Posts p
    JOIN PostHistory h ON p.Id = h.PostId 
    WHERE h.PostHistoryTypeId = 10 
    GROUP BY p.Id
),
PostInteractionMetrics AS (
    SELECT 
        e.PostId,
        e.Title,
        e.CreationDate,
        e.CommentScore,
        e.VoteNet,
        cp.FirstCloseDate,
        CASE 
            WHEN cp.FirstCloseDate IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS PostStatus,
        e.ReputationTier
    FROM EnhancedPostMetrics e
    LEFT JOIN ClosedPosts cp ON e.PostId = cp.Id
)
SELECT 
    pim.PostId,
    pim.Title,
    pim.CreationDate,
    pim.CommentScore,
    pim.VoteNet,
    pim.PostStatus,
    COALESCE(CASE WHEN pim.VoteNet < 0 THEN 'Needs Attention' ELSE 'Good' END, 'Unknown') AS PostQuality,
    pim.ReputationTier,
    CASE 
        WHEN pim.CommentScore IS NOT NULL THEN 'Active Discussion'
        ELSE 'No Comments'
    END AS DiscussionState,
    CONCAT('Post ID: ', pim.PostId, ' | Status: ', pim.PostStatus) AS PostSummary
FROM PostInteractionMetrics pim
WHERE pim.PostStatus = 'Active'
    AND (pim.VoteNet > 5 OR pim.CommentScore > 5)
ORDER BY pim.CreationDate DESC
LIMIT 50;
