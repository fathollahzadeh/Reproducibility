WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserVotes AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(UV.UpVotes, 0) AS UpVotes,
        COALESCE(UV.DownVotes, 0) AS DownVotes,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        UserVotes UV ON U.Id = UV.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId, 
    Reputation, 
    GoldBadges, 
    SilverBadges, 
    BronzeBadges, 
    UpVotes, 
    DownVotes, 
    QuestionCount, 
    AnswerCount, 
    TotalViews,
    RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
FROM 
    UserActivity
WHERE 
    (UpVotes - DownVotes) > 10 
    OR (GoldBadges + SilverBadges) >= 2
ORDER BY 
    Reputation DESC, TotalViews DESC
LIMIT 100;
