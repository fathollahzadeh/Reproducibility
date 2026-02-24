WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionsCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT UserId, Reputation, TotalPosts, QuestionsCount, AnswersCount,
           UpVotesReceived, DownVotesReceived,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
    WHERE Reputation IS NOT NULL AND Reputation > 0
),

PinnedQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ARRAY_AGG(t.TagName) AS Tags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    INNER JOIN Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE p.PostTypeId = 1 AND p.ClosedDate IS NULL
    GROUP BY p.Id
    ORDER BY p.CreationDate DESC
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
        COALESCE(ut.Reputation, 0) AS Reputation,
        COALESCE(pq.RecentPostRank, 0) AS RecentPostRank,
        COALESCE(pq.CommentCount, 0) AS RecentComments,
        (SELECT AVG(v.BountyAmount) FROM Votes v 
         WHERE v.UserId = u.Id AND v.VoteTypeId IN (8, 9)) AS AvgBounty
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN TopUsers ut ON u.Id = ut.UserId
    LEFT JOIN PinnedQuestions pq ON u.Id = pq.PostId
)

SELECT 
    ua.UserId,
    ua.Reputation,
    ua.Badges,
    ua.RecentPostRank,
    ua.RecentComments,
    ua.AvgBounty,
    (SELECT COUNT(*) FROM Posts p 
     WHERE p.OwnerUserId = ua.UserId AND p.Score > 0) AS PositiveScorePosts
FROM UserActivity ua
WHERE ua.Reputation > 1000 
ORDER BY ua.Reputation DESC, ua.RecentPostRank ASC
LIMIT 10;