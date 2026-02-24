
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS MostRecentPost
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        COALESCE(pa.QuestionCount, 0) AS QuestionCount,
        COALESCE(pa.AnswerCount, 0) AS AnswerCount,
        COALESCE(pa.TotalScore, 0) AS TotalScore,
        COALESCE(pa.AvgViewCount, 0) AS AvgViewCount,
        pa.MostRecentPost,
        us.UpVotes,
        us.DownVotes,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        UserStatistics us
    LEFT JOIN 
        PostAggregates pa ON us.UserId = pa.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.QuestionCount,
    u.AnswerCount,
    u.TotalScore,
    u.AvgViewCount,
    u.UpVotes,
    u.DownVotes,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    CASE 
        WHEN u.TotalScore > 100 THEN 'High Performer' 
        WHEN u.TotalScore BETWEEN 50 AND 100 THEN 'Medium Performer' 
        ELSE 'Low Performer' 
    END AS PerformanceCategory
FROM 
    UserPerformance u
ORDER BY 
    u.TotalScore DESC;
