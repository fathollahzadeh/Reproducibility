
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.Tags
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags, p.PostTypeId
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(TRIM(BOTH '{}' FROM Tags), ',')) AS Tag
    FROM RankedPosts
    WHERE Rank <= 3
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM PopularTags
    GROUP BY Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(CASE WHEN p.CreationDate <= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' THEN p.CreationDate END) AS LastActiveBeforeLastMonth
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(DISTINCT CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(DISTINCT CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM Badges b 
    GROUP BY b.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    ua.PostsCount,
    ua.TotalBounty,
    COUNT(tp.Tag) FILTER (WHERE tp.UsageCount > 10) AS FrequentTags,
    COUNT(tp.Tag) FILTER (WHERE tp.UsageCount <= 10) AS RareTags,
    CASE 
        WHEN ua.LastActiveBeforeLastMonth IS NULL THEN 'Inactive' 
        ELSE 'Active' 
    END AS ActivityStatus
FROM UserActivity ua
LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN TagPopularity tp ON TRUE
GROUP BY 
    ua.UserId,
    ua.DisplayName,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ua.PostsCount,
    ua.TotalBounty,
    ua.LastActiveBeforeLastMonth
ORDER BY 
    TotalBounty DESC, 
    PostsCount DESC, 
    ua.DisplayName;
