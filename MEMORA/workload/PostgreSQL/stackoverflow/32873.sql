
WITH RECURSIVE RankedUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount, 
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.BadgeNames, 'No badges') AS BadgeNames,
        COALESCE(r.TotalPosts, 0) AS TotalPosts,
        COALESCE(r.QuestionsCount, 0) AS QuestionsCount,
        COALESCE(r.AnswersCount, 0) AS AnswersCount,
        COALESCE(r.AcceptedAnswersCount, 0) AS AcceptedAnswersCount,
        u.Reputation,
        rr.ReputationRank
    FROM 
        Users u
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    LEFT JOIN RecentPosts r ON u.Id = r.OwnerUserId
    JOIN RankedUsers rr ON u.Id = rr.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        BadgeCount, 
        BadgeNames, 
        TotalPosts, 
        QuestionsCount, 
        AnswersCount, 
        AcceptedAnswersCount,
        ReputationRank,
        RANK() OVER (ORDER BY Reputation DESC) AS OverallRank
    FROM 
        UserStatistics
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    tu.BadgeNames,
    tu.TotalPosts,
    tu.QuestionsCount,
    tu.AnswersCount,
    tu.AcceptedAnswersCount,
    tu.ReputationRank,
    tu.OverallRank
FROM 
    TopUsers tu
WHERE 
    tu.OverallRank <= 10
ORDER BY 
    tu.OverallRank;
