WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (1, 2) 
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        LEAD(p.CreationDate) OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS NextPostDate
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS Comments
    FROM PostHistory ph
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
ActiveUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.BadgeCount,
    us.TotalBounty,
    us.UserRank,
    rp.PostId AS RecentPostId,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    rp.ViewCount AS RecentPostViews,
    rp.CreationDate AS RecentPostCreationDate,
    phs.HistoryCount AS PostHistoryChangeCount,
    phs.Comments AS RecentPostComments,
    au.ActivePostCount,
    au.ClosedPostCount
FROM UserStatistics us
LEFT JOIN RecentPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN PostHistoryStats phs ON rp.PostId = phs.PostId
LEFT JOIN ActiveUsers au ON us.DisplayName = au.DisplayName
WHERE us.UserRank <= 10
ORDER BY us.UserRank, rp.CreationDate DESC NULLS LAST;