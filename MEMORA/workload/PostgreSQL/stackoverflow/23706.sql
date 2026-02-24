
WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN v.BountyAmount ELSE NULL END) AS AvgBountyForUpvotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN v.BountyAmount ELSE NULL END) AS AvgBountyForDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagPostCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryAnalytics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate ELSE NULL END) AS CloseDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE NULL END) AS ClosureActions
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName AS UserName,
    ups.UpVotes,
    ups.DownVotes,
    ups.TotalVotes,
    ups.AvgBountyForUpvotes,
    ups.AvgBountyForDownvotes,
    tpc.TagName,
    tpc.PostCount,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pha.PostId,
    pha.HistoryCount,
    pha.CloseDate,
    pha.ClosureActions
FROM 
    UserVoteStatistics ups
JOIN 
    Users u ON ups.UserId = u.Id
LEFT JOIN 
    TagPostCount tpc ON tpc.TagId = (
        SELECT id FROM Tags ORDER BY RANDOM() LIMIT 1
    )
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
LEFT JOIN 
    PostHistoryAnalytics pha ON pha.PostId = (
        SELECT id FROM Posts ORDER BY RANDOM() LIMIT 1
    )
WHERE 
    (u.Reputation >= 100 OR ups.TotalVotes > 10)
    AND (tpc.PostCount > 10)
ORDER BY 
    ups.UpVotes DESC, ups.DownVotes ASC
LIMIT 50;
