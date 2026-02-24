WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserPostCounts
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName, 
    up.PostCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
    r.PostId AS RecentEditedPostId,
    r.CreationDate AS RecentEditDate,
    r.Comment AS RecentEditComment
FROM Users u
JOIN TopUsers up ON u.Id = up.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RecentEdits r ON u.Id = r.UserId AND r.EditRank = 1
WHERE 
    up.Rank <= 10  
    AND (ub.BadgeCount IS NULL OR ub.BadgeCount > 0) 
ORDER BY 
    up.PostCount DESC, 
    u.DisplayName;