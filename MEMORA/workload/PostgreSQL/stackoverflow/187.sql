WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
PostVoteStatistics AS (
    SELECT 
        p.OwnerUserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.OwnerUserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    COALESCE(tp.PostCount, 0) AS PostCount,
    COALESCE(tp.PositivePosts, 0) AS PositivePosts,
    COALESCE(tp.NegativePosts, 0) AS NegativePosts,
    COALESCE(tp.TotalViews, 0) AS TotalViews,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High Reputation'
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserReputation ur
LEFT JOIN TopPosts tp ON ur.UserId = tp.OwnerUserId
LEFT JOIN PostVoteStatistics pvs ON ur.UserId = pvs.OwnerUserId
WHERE ur.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months' 
    OR ur.Reputation IS NULL
ORDER BY ur.Reputation DESC, ur.DisplayName
LIMIT 20;