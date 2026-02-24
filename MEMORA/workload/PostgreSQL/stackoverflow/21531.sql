WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    WHERE u.Reputation IS NOT NULL AND u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation, ub.BadgeCount, ub.BadgeNames
),
AggregatePostStats AS (
    SELECT 
        pw.OwnerUserId,
        AVG(pw.UpVotes - pw.DownVotes) AS AvgScore,
        SUM(pw.CommentCount) AS TotalComments,
        SUM(pw.RelatedPostsCount) AS TotalRelatedPosts
    FROM PostsWithVotes pw
    GROUP BY pw.OwnerUserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    tu.BadgeNames,
    aps.AvgScore,
    aps.TotalComments,
    aps.TotalRelatedPosts,
    CASE 
        WHEN tu.Reputation IS NULL OR tu.Reputation < 0 THEN 'Inactive User'
        WHEN tu.BadgeCount = 0 THEN 'Newbie'
        WHEN tu.Reputation > 5000 THEN 'Expert'
        ELSE 'Intermediate' 
    END AS UserLevel
FROM TopUsers tu
LEFT JOIN AggregatePostStats aps ON tu.UserId = aps.OwnerUserId
WHERE tu.BadgeCount >= 0 OR tu.Reputation >= 1000
ORDER BY tu.Reputation DESC, tu.DisplayName
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;