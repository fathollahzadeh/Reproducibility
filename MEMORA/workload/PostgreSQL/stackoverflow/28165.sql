
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName AS UserName, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges, 
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges, 
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts, 
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions, 
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers, 
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ub.UserName, 
    ub.GoldBadges, 
    ub.SilverBadges, 
    ub.BronzeBadges, 
    ps.TotalPosts, 
    ps.Questions, 
    ps.Answers, 
    ps.TotalScore, 
    ub.TotalUpVotes, 
    ub.TotalDownVotes, 
    ub.TotalViews,
    COALESCE(ROUND((CAST(ps.TotalScore AS DECIMAL) / NULLIF(ps.TotalPosts, 0)), 2), 0) AS AverageScorePerPost
FROM 
    UserBadges ub
JOIN 
    PostSummary ps ON ub.UserId = ps.OwnerUserId
ORDER BY 
    ub.TotalViews DESC, ub.GoldBadges DESC, ps.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;
