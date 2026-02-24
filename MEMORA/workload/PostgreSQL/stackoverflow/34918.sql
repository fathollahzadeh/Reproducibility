
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > DATE '2021-01-01'
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE
            WHEN u.Reputation >= 1000 THEN 'Veteran'
            WHEN u.Reputation >= 500 THEN 'Experienced'
            ELSE 'Novice'
        END AS ExperienceLevel
    FROM Users u
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS Closed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (11, 12) THEN 1 ELSE 0 END) AS IsDeleted,
        COUNT(ph.Id) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
PopularPostLinks AS (
    SELECT
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType,
        COUNT(pl.Id) AS LinkCount
    FROM PostLinks pl
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY pl.PostId, pl.RelatedPostId, lt.Name
)
SELECT
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ur.DisplayName,
    ur.ExperienceLevel,
    COALESCE(phd.Closed, 0) AS PostClosed,
    COALESCE(phd.IsDeleted, 0) AS PostDeleted,
    phd.EditCount,
    COALESCE(pl.LinkCount, 0) AS RelatedPostLinks
FROM RankedPosts rp
JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN PopularPostLinks pl ON rp.PostId = pl.PostId
WHERE rp.ScoreRank <= 5
ORDER BY rp.Score DESC, ur.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
