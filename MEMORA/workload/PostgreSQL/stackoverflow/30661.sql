
WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostHistoryLatest AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY
        ph.PostId
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        crt.Name AS CloseReason
    FROM
        Posts p
    INNER JOIN
        PostHistory ph ON p.Id = ph.PostId
    INNER JOIN
        CloseReasonTypes crt ON CAST(ph.Comment AS INTEGER) = crt.Id 
    WHERE
        ph.PostHistoryTypeId = 10 
)
SELECT
    u.DisplayName,
    u.Reputation,
    COALESCE(up.BadgeCount, 0) AS TotalBadges,
    COALESCE(up.GoldBadges, 0) AS GoldBadges,
    COALESCE(up.SilverBadges, 0) AS SilverBadges,
    COALESCE(up.BronzeBadges, 0) AS BronzeBadges,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    ph.LastEditDate,
    cp.ClosedDate,
    cp.CloseReason
FROM
    Users u
LEFT JOIN
    UserBadges up ON u.Id = up.UserId
LEFT JOIN
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN
    PostHistoryLatest ph ON rp.Id = ph.PostId
LEFT JOIN
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE
    u.Reputation > 1000
ORDER BY
    u.Reputation DESC, 
    rp.Score DESC;
