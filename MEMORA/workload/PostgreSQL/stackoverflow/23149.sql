
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS Rn
    FROM PostHistory ph
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
),
PostLinksAgg AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM PostLinks pl
    GROUP BY pl.PostId
)
SELECT 
    us.DisplayName,
    us.PostCount,
    us.UpVoteCount,
    us.DownVoteCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.PostRank,
    p.Title,
    p.CreationDate AS PostCreationDate,
    COALESCE(ph.UserDisplayName, 'No Edits') AS LastEditor,
    ph.CreationDate AS LastEditDate,
    COALESCE(pla.RelatedPostCount, 0) AS RelatedPostCounter,
    CASE
        WHEN COALESCE(ph.UserDisplayName, '') = '' THEN 'No Edits Found'
        WHEN us.PostCount = 0 THEN 'User has no posts'
        ELSE 'Has Edits'
    END AS PostEditStatus,
    CASE 
        WHEN us.UpVoteCount > us.DownVoteCount THEN 'Net Positive Voting'
        WHEN us.UpVoteCount < us.DownVoteCount THEN 'Net Negative Voting'
        ELSE 'Neutral Voting'
    END AS VoteStatus,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames
FROM UserStats us
JOIN Posts p ON us.UserId = p.OwnerUserId
LEFT JOIN RecentPostHistory ph ON p.Id = ph.PostId AND ph.Rn = 1
LEFT JOIN PostLinksAgg pla ON p.Id = pla.PostId
JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    us.PostCount > 0 
    AND (us.UpVoteCount > 0 OR us.DownVoteCount > 0)
GROUP BY 
    us.DisplayName, us.PostCount, us.UpVoteCount, us.DownVoteCount, 
    us.GoldBadges, us.SilverBadges, us.BronzeBadges, us.PostRank, 
    p.Title, p.CreationDate, ph.UserDisplayName, ph.CreationDate, pla.RelatedPostCount
ORDER BY 
    us.PostRank;
