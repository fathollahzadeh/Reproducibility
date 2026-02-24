WITH UserReputation AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT t.TagName,
           COUNT(p.Id) AS PostCount,
           SUM(p.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10
),
TopPostHistories AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           COUNT(ph.Id) AS ChangeCount,
           STRING_AGG(ph.UserDisplayName, ', ') AS Editors
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
    ORDER BY ChangeCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT u.Id AS UserId,
           COUNT(b.Id) AS BadgeCount,
           STRING_AGG(b.Name, ', ') AS Badges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT ur.DisplayName,
       ur.Reputation,
       ur.PostCount,
       pb.TagName,
       pb.PostCount AS TagPostCount,
       pb.TotalViews,
       tph.PostId,
       tph.ChangeCount,
       tph.Editors,
       ub.BadgeCount,
       ub.Badges
FROM UserReputation ur
JOIN PopularTags pb ON ur.PostCount > pb.PostCount
JOIN TopPostHistories tph ON ur.UserId = tph.PostId
JOIN UserBadges ub ON ur.UserId = ub.UserId
ORDER BY ur.Reputation DESC, pb.TotalViews DESC;
