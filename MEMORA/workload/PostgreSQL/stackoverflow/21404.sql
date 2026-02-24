WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM Posts p
    WHERE p.CreationDate >= '2023-01-01' AND p.CreationDate < cast('2024-10-01 12:34:56' as timestamp)
),
TopUsers AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(*) as PostCount,
        SUM(p.Score) as TotalScore,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) as TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= '2023-01-01'
    WHERE u.Reputation > 50
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(*) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ',') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
ProjectedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) as UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) as DownVotes,
        COUNT(v.Id) as TotalVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
)
SELECT
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalScore,
    u.TotalViews,
    COALESCE(b.BadgeNames, 'No Badges') as BadgeNames,
    b.BadgeCount,
    rp.Title,
    rp.Score,
    COALESCE(v.UpVotes, 0) as UpVotes,
    COALESCE(v.DownVotes, 0) as DownVotes,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.Rank <= 5 THEN 'Top 5 Posts'
        ELSE 'Other'
    END as PostRank
FROM TopUsers u
LEFT JOIN UserBadges b ON u.UserId = b.UserId
LEFT JOIN RankedPosts rp ON u.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN ProjectedVotes v ON rp.Id = v.PostId
WHERE u.TotalScore > 100
ORDER BY u.TotalScore DESC, u.DisplayName ASC;