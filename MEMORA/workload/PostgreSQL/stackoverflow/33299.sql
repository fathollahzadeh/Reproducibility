
WITH RecursiveTopPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 
    AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
           COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
           COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostCloseDetails AS (
    SELECT ph.PostId, 
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM PostHistory ph
    GROUP BY ph.PostId
),
UserPostStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
           COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
           COALESCE(MAX(p.ViewCount), 0) AS MaxViews,
           COALESCE(SUM(po.ViewCount), 0) AS TotalPostViews,
           b.GoldBadges, b.SilverBadges, b.BronzeBadges,
           rc.ClosedDate, rc.CloseReason
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostCloseDetails rc ON p.Id = rc.PostId
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    LEFT JOIN Posts po ON u.Id = po.OwnerUserId
    GROUP BY u.Id, u.DisplayName, b.GoldBadges, b.SilverBadges, b.BronzeBadges, rc.ClosedDate, rc.CloseReason
),
TopUsers AS (
    SELECT UserId, DisplayName, QuestionsAsked, AnswersGiven, MaxViews, TotalPostViews,
           GoldBadges, SilverBadges, BronzeBadges,
           ROW_NUMBER() OVER (ORDER BY QuestionsAsked DESC, AnswersGiven DESC) AS UserRank
    FROM UserPostStats
)
SELECT tU.DisplayName,
       tU.QuestionsAsked,
       tU.AnswersGiven,
       tU.MaxViews,
       tU.TotalPostViews,
       tU.GoldBadges,
       tU.SilverBadges,
       tU.BronzeBadges,
       COALESCE(rp.Title, 'No Top Post') AS TopPost
FROM TopUsers tU
LEFT JOIN RecursiveTopPosts rp ON tU.UserId = rp.OwnerUserId AND rp.Rank = 1
WHERE tU.UserRank <= 10 
ORDER BY tU.UserRank;
