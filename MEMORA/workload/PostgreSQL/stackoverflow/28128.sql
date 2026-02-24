WITH UserTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.TagName) AS UniqueTagsContributed,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT DISTINCT 
            UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName, 
            p.Id AS PostId
        FROM 
            Posts p 
        WHERE 
            p.PostTypeId = 1) t ON p.Id = t.PostId
    GROUP BY 
        u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), CombinedStats AS (
    SELECT 
        ut.UserId,
        ut.DisplayName,
        ut.UniqueTagsContributed,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ut.AcceptedAnswers,
        ut.TotalViews,
        ut.TotalScore
    FROM 
        UserTags ut
    LEFT JOIN 
        UserBadges ub ON ut.UserId = ub.UserId
)

SELECT 
    *,
    COALESCE(TotalViews / NULLIF(AcceptedAnswers, 0), 0) AS ViewsPerAcceptedAnswer,
    COALESCE(TotalScore / NULLIF(UniqueTagsContributed, 0), 0) AS ScorePerTag
FROM 
    CombinedStats
ORDER BY 
    TotalScore DESC, UniqueTagsContributed DESC
LIMIT 10;
