WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS TotalBadges, 
           STRING_AGG(Name, ', ') AS BadgeNames 
    FROM Badges 
    WHERE Class = 1 
    GROUP BY UserId
), 
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions, 
           SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
           COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
           MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
), 
UserReputation AS (
    SELECT u.Id AS UserId, 
           u.Reputation, 
           COALESCE(ub.TotalBadges, 0) AS GoldBadgeCount,
           COALESCE(ps.TotalPosts, 0) AS TotalPostsCount,
           COALESCE(ps.TotalQuestions, 0) AS TotalQuestionsCount,
           COALESCE(ps.TotalAcceptedAnswers, 0) AS TotalAcceptedAnswersCount,
           COALESCE(ps.TotalViews, 0) AS TotalPostViews
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
), 
RankedUsers AS (
    SELECT UserId, 
           Reputation, 
           GoldBadgeCount,
           TotalPostsCount,
           TotalQuestionsCount, 
           TotalAcceptedAnswersCount,
           TotalPostViews,
           RANK() OVER (ORDER BY Reputation DESC, TotalPostsCount DESC) AS UserRank
    FROM UserReputation
    WHERE Reputation IS NOT NULL
)
SELECT ru.UserId,
       ru.Reputation,
       ru.GoldBadgeCount,
       ru.TotalPostsCount,
       ru.TotalQuestionsCount,
       ru.TotalAcceptedAnswersCount,
       ru.TotalPostViews,
       ru.UserRank,
       STRING_AGG(DISTINCT ph.Comment, '; ') FILTER (WHERE ph.Comment IS NOT NULL) AS HistoryComments,
       SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
       (SELECT COUNT(*)
        FROM Votes v2
        WHERE v2.PostId IN (SELECT p.Id
                            FROM Posts p
                            WHERE p.OwnerUserId = ru.UserId)
          AND v2.VoteTypeId = 3) AS TotalDownVotes
FROM RankedUsers ru
LEFT JOIN PostHistory ph ON ru.UserId = ph.UserId
LEFT JOIN Votes v ON v.UserId = ru.UserId
GROUP BY ru.UserId, ru.Reputation, ru.GoldBadgeCount, ru.TotalPostsCount, 
         ru.TotalQuestionsCount, ru.TotalAcceptedAnswersCount, 
         ru.TotalPostViews, ru.UserRank
HAVING COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) > 
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)
ORDER BY ru.UserRank;