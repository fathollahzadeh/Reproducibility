WITH RECURSIVE UserReputation AS (
    
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1000 WHEN b.Class = 2 THEN 500 WHEN b.Class = 3 THEN 100 END) AS CumulativeReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
RecentPostHistory AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastEditDate,
        p.LastActivityDate,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
AggregatedVotes AS (
    
    SELECT 
        postId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM Votes
    GROUP BY postId
),
UserPostStats AS (
    
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        COALESCE(SUM(vs.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(vs.DownVotes), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN vs.AcceptedVotes > 0 THEN 1 ELSE 0 END), 0) AS AcceptedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN AggregatedVotes vs ON p.Id = vs.postId
    GROUP BY u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation AS OriginalReputation,
    ur.CumulativeReputation,
    ups.TotalPosts,
    ups.TotalViews,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.AcceptedPosts,
    COUNT(rph.PostId) AS RecentEdits,
    STRING_AGG(rph.Title, ', ') AS RecentEditedTitles
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN UserPostStats ups ON u.Id = ups.UserId
LEFT JOIN RecentPostHistory rph ON u.Id = rph.PostId
WHERE u.Reputation > 1000
  AND ur.CumulativeReputation > 0
GROUP BY u.DisplayName, u.Reputation, ur.CumulativeReputation, ups.TotalPosts, ups.TotalViews,
         ups.TotalUpVotes, ups.TotalDownVotes, ups.AcceptedPosts
ORDER BY ur.CumulativeReputation DESC, ups.TotalPosts DESC
LIMIT 10;