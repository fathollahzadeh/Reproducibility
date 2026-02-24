
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpvotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT
        pho.UserId,
        COUNT(*) AS HistoryCount,
        MAX(pho.CreationDate) AS LastActivityDate
    FROM
        PostHistory pho
    WHERE
        pho.CreationDate >= CURRENT_DATE - INTERVAL '6 MONTH'
    GROUP BY
        pho.UserId
)
SELECT
    u.DisplayName,
    u.Reputation,
    us.QuestionCount,
    us.TotalBadges,
    us.TotalBounty,
    us.TotalUpvotes,
    ra.HistoryCount,
    ra.LastActivityDate,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score
FROM
    Users u
LEFT JOIN
    UserStats us ON u.Id = us.UserId
LEFT JOIN
    RecentActivity ra ON u.Id = ra.UserId
LEFT JOIN
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.RankByUser = 1 
WHERE
    (us.QuestionCount > 5 OR us.Reputation > 100) 
ORDER BY
    us.Reputation DESC, 
    ra.LastActivityDate DESC;
