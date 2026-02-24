
WITH RecursiveTagUsage AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Tags) AS TagUsageCount,
        RANK() OVER (ORDER BY COUNT(p.Tags) DESC) AS TagRank
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.Id, t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 100  
    GROUP BY u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount + ua.CommentCount + ua.UpVotes - ua.DownVotes AS EngagementScore,
        RANK() OVER (ORDER BY ua.TotalViews DESC) AS PopularityRank
    FROM UserActivity ua
    WHERE ua.PostCount > 5  
),
ClosingPostReasons AS (
    SELECT 
        p.Id AS PostId,
        hp.UserId,
        MIN(hp.CreationDate) AS FirstCloseDate,
        STRING_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM PostHistory hp
    JOIN CloseReasonTypes cr ON CAST(hp.Comment AS INT) = cr.Id  
    JOIN Posts p ON hp.PostId = p.Id
    WHERE hp.PostHistoryTypeId IN (10, 11)  
    GROUP BY p.Id, hp.UserId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    u.PostCount,
    u.CommentCount,
    u.UpVotes,
    u.DownVotes,
    u.BadgeCount,
    tg.TagUsageCount,
    tg.TagName,
    pu.EngagementScore AS UserEngagementScore,
    cp.FirstCloseDate,
    cp.CloseReasons
FROM UserActivity u
JOIN RecursiveTagUsage tg ON u.UserId = tg.TagId  
JOIN PopularUsers pu ON u.UserId = pu.UserId
LEFT JOIN ClosingPostReasons cp ON u.UserId = cp.UserId 
WHERE u.BadgeCount > 0 AND tg.TagRank <= 10  
ORDER BY pu.EngagementScore DESC, tg.TagUsageCount DESC;
