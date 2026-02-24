WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '365 days') 
        AND p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT ph.PostId) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON u.Id = ph.UserId AND ph.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years')
    GROUP BY u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        rc.VoteCount,
        RANK() OVER (ORDER BY ua.PostCount DESC, rc.VoteCount DESC) AS PopularityRank
    FROM UserActivity ua
    JOIN (
        SELECT UserId, COUNT(*) AS VoteCount
        FROM Votes 
        WHERE VoteTypeId = 2  
        GROUP BY UserId
    ) rc ON ua.UserId = rc.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pu.DisplayName AS Author,
    pu.PostCount AS AuthorPostCount,
    pu.PopularityRank
FROM RankedPosts rp
JOIN Posts p ON rp.PostId = p.Id
JOIN PopularUsers pu ON p.OwnerUserId = pu.UserId
WHERE 
    rp.rn <= 3  
ORDER BY 
    pu.PopularityRank,
    rp.Score DESC NULLS LAST  
LIMIT 100;