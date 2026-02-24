
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(ROUND(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 3600.0), 0)) AS AverageAgeHours
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalMetrics AS (
    SELECT 
        u.DisplayName,
        ua.TotalPosts,
        ua.TotalAnswers,
        ua.TotalQuestions,
        ua.TotalViews,
        ua.TotalScore,
        ua.AverageAgeHours,
        vs.TotalVotes,
        vs.UpVotes,
        vs.DownVotes,
        bs.TotalBadges,
        bs.GoldBadges,
        bs.SilverBadges,
        bs.BronzeBadges
    FROM 
        UserActivity ua
    JOIN 
        PostVoteSummary vs ON ua.UserId = vs.OwnerUserId
    LEFT JOIN 
        UserBadges bs ON ua.UserId = bs.UserId
    JOIN 
        Users u ON ua.UserId = u.Id
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalViews,
    TotalScore,
    AverageAgeHours,
    TotalVotes,
    UpVotes,
    DownVotes,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    FinalMetrics
ORDER BY 
    TotalScore DESC, TotalViews DESC
LIMIT 10;
