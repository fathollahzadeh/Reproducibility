WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
), PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate > '2022-01-01' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId, p.Score
), PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstHistoryDate,
        MAX(ph.CreationDate) AS LastHistoryDate,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
), UserPostStats AS (
    SELECT 
        ud.UserId,
        COUNT(pd.PostId) AS TotalPosts,
        AVG(pd.ViewCount) AS AvgPostViews
    FROM UserReputation ud
    LEFT JOIN PostDetails pd ON ud.UserId = pd.OwnerUserId
    GROUP BY ud.UserId
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(ups.TotalPosts, 0) AS TotalPosts,
    COALESCE(ups.AvgPostViews, 0) AS AvgPostViews,
    phd.FirstHistoryDate,
    phd.LastHistoryDate,
    phd.HistoryCount,
    phd.HistoryTypes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.CommentCount,
    pd.RelatedPosts
FROM UserReputation ur
LEFT JOIN UserPostStats ups ON ur.UserId = ups.UserId
LEFT JOIN PostDetails pd ON ur.UserId = pd.OwnerUserId
LEFT JOIN PostHistoryDetails phd ON pd.PostId = phd.PostId
WHERE ur.Reputation > (SELECT AVG(Reputation) FROM Users) 
  AND pd.ViewCount > (
      SELECT AVG(ViewCount) 
      FROM Posts 
      WHERE CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year' 
  )
ORDER BY ur.Reputation DESC, pd.ViewCount DESC;