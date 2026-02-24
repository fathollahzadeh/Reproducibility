WITH PostStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
),
UserStatistics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation,
        MAX(Reputation) AS MaxReputation,
        MIN(Reputation) AS MinReputation
    FROM 
        Users
),
BadgeStatistics AS (
    SELECT 
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
    FROM 
        Badges
),
VoteStatistics AS (
    SELECT 
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes
)
SELECT 
    (SELECT TotalPosts FROM PostStatistics) AS TotalPosts,
    (SELECT TotalQuestions FROM PostStatistics) AS TotalQuestions,
    (SELECT TotalAnswers FROM PostStatistics) AS TotalAnswers,
    (SELECT TotalViews FROM PostStatistics) AS TotalViews,
    (SELECT AverageScore FROM PostStatistics) AS AverageScore,
    (SELECT TotalUsers FROM UserStatistics) AS TotalUsers,
    (SELECT AverageReputation FROM UserStatistics) AS AverageUserReputation,
    (SELECT MaxReputation FROM UserStatistics) AS MaxUserReputation,
    (SELECT MinReputation FROM UserStatistics) AS MinUserReputation,
    (SELECT TotalBadges FROM BadgeStatistics) AS TotalBadges,
    (SELECT TotalGoldBadges FROM BadgeStatistics) AS TotalGoldBadges,
    (SELECT TotalSilverBadges FROM BadgeStatistics) AS TotalSilverBadges,
    (SELECT TotalBronzeBadges FROM BadgeStatistics) AS TotalBronzeBadges,
    (SELECT TotalVotes FROM VoteStatistics) AS TotalVotes,
    (SELECT TotalUpVotes FROM VoteStatistics) AS TotalUpVotes,
    (SELECT TotalDownVotes FROM VoteStatistics) AS TotalDownVotes;