
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount,
           STRING_AGG(CASE WHEN Class = 1 THEN Name ELSE NULL END, ', ') AS GoldBadges,
           STRING_AGG(CASE WHEN Class = 2 THEN Name ELSE NULL END, ', ') AS SilverBadges,
           STRING_AGG(CASE WHEN Class = 3 THEN Name ELSE NULL END, ', ') AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostDetails AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.Title,
           COALESCE(COUNT(c.Id), 0) AS CommentCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY p.OwnerUserId) AS QuestionsPosted,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.Title
),
AggregateResults AS (
    SELECT ud.Id AS UserId,
           ud.DisplayName,
           u.BadgeCount,
           COALESCE(pd.RecentPostRank, 0) AS RecentPostRank,
           COALESCE(pd.CommentCount, 0) AS CommentsMade,
           COALESCE(pd.UpVoteCount, 0) AS UpVotesReceived,
           COALESCE(pd.DownVoteCount, 0) AS DownVotesReceived,
           COALESCE(pd.QuestionsPosted, 0) AS QuestionsPosted
    FROM Users ud
    LEFT JOIN UserBadges u ON u.UserId = ud.Id
    LEFT JOIN PostDetails pd ON pd.OwnerUserId = ud.Id
)
SELECT ar.UserId, ar.DisplayName, ar.BadgeCount, ar.RecentPostRank, 
       ar.CommentsMade, ar.UpVotesReceived, ar.DownVotesReceived, ar.QuestionsPosted,
       CASE 
           WHEN ar.BadgeCount IS NULL THEN 'No Badges'
           WHEN ar.BadgeCount > 10 THEN 'Expert User'
           ELSE 'Novice User' 
       END AS UserLevel,
       CASE 
           WHEN ar.RecentPostRank <= 3 THEN 'Active Contributor'
           ELSE 'Occasional Contributor'
       END AS ContributionLevel
FROM AggregateResults ar
WHERE (ar.BadgeCount IS NOT NULL OR ar.RecentPostRank IS NOT NULL)
  AND (ar.CommentsMade > 0 OR ar.UpVotesReceived > ar.DownVotesReceived)
ORDER BY ar.UserId ASC, ar.CommentsMade DESC;
