
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY LastAccessDate DESC) AS rn
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        COALESCE(c.Text, 'No comments') AS CommentText,
        COUNT(c.Id) AS CommentCount,
        LAG(p.Score) OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS PreviousScore,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score, c.Text
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        EXTRACT(EPOCH FROM ph.CreationDate) AS EditTimestamp,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Open'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            ELSE 'Other'
        END AS ActionType
    FROM PostHistory ph
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        ur.Reputation,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    JOIN UserReputation ur ON u.Id = ur.UserId
    WHERE ur.rn = 1
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    phd.EditTimestamp,
    phd.ActionType
FROM TopUsers tu
JOIN RecentPosts rp ON tu.UserId = rp.OwnerUserId
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE tu.Rank <= 10
AND (rp.Score - COALESCE(rp.PreviousScore, 0)) > 0
ORDER BY tu.Reputation DESC, rp.CreationDate DESC;
