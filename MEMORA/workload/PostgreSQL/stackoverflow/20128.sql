
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0), 0) AS Upvotes,
        COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY UPPER(SUBSTRING(p.Title, 1, 1)) ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
),
AggregatedPostData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Upvotes,
        rp.Downvotes,
        CASE 
            WHEN rp.Upvotes > rp.Downvotes THEN 'Popular'
            WHEN rp.Upvotes < rp.Downvotes THEN 'Unpopular'
            ELSE 'Neutral'
        END AS Popularity
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    JOIN Users u ON b.UserId = u.Id
    WHERE u.Reputation > 1000
    GROUP BY b.UserId
),
FinalResults AS (
    SELECT 
        ap.Title,
        ap.CreationDate,
        ap.ViewCount,
        ap.Upvotes,
        ap.Downvotes,
        ap.Popularity,
        ub.BadgeCount,
        ub.BadgeNames
    FROM AggregatedPostData ap
    LEFT JOIN UserBadges ub ON ap.PostId = (SELECT MIN(p.Id) FROM Posts p WHERE p.OwnerUserId = ub.UserId)
)
SELECT 
    *,
    CASE 
        WHEN BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS UserBadgeStatus,
    CONCAT('Post Title: "', Title, '" has ', Upvotes, ' upvotes and ', Downvotes, ' downvotes.') AS PostSummary
FROM FinalResults
ORDER BY ViewCount DESC
LIMIT 10;
