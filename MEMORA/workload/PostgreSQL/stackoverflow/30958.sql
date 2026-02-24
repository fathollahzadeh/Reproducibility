
WITH RecursiveUserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS EngagementLevel
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ue.PostCount, 0) AS PostCount,
    COALESCE(ue.QuestionCount, 0) AS QuestionCount,
    COALESCE(ue.AnswerCount, 0) AS AnswerCount,
    COALESCE(ue.TotalCommentScore, 0) AS TotalCommentScore,
    COALESCE(ue.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(ue.TotalDownVotes, 0) AS TotalDownVotes,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, '') AS BadgeNames,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore,
    CASE
        WHEN ue.EngagementLevel IS NOT NULL AND ue.EngagementLevel > 10 THEN 'Very Active'
        WHEN ue.EngagementLevel IS NOT NULL AND ue.EngagementLevel BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS EngagementStatus
FROM Users u
LEFT JOIN RecursiveUserEngagement ue ON u.Id = ue.UserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.RecentRank = 1
WHERE COALESCE(ue.TotalUpVotes, 0) - COALESCE(ue.TotalDownVotes, 0) > 10
ORDER BY u.Reputation DESC
LIMIT 100;
