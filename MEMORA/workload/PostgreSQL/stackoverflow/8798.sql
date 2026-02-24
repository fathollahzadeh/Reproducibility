
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), ActiveUsers AS (
    SELECT
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.Questions,
        ue.Answers,
        ue.TotalScore,
        DENSE_RANK() OVER (ORDER BY ue.TotalScore DESC) AS ScoreRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.TotalPosts > 5
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY
        b.UserId
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.TotalPosts,
    au.Questions,
    au.Answers,
    au.TotalScore,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, '') AS BadgeNames
FROM 
    ActiveUsers au
LEFT JOIN 
    UserBadges ub ON au.UserId = ub.UserId
WHERE 
    au.ScoreRank <= 10
ORDER BY 
    au.ScoreRank;
