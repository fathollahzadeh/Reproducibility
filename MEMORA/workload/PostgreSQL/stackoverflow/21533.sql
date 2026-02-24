
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserVoting AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
FinalStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.AcceptedAnswers, 0) AS AcceptedAnswers,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AverageViews, 0) AS AverageViews,
        COALESCE(UV.TotalVotes, 0) AS TotalVotes,
        COALESCE(UV.UpVotes, 0) AS UpVotes,
        COALESCE(UV.DownVotes, 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN UserVoting UV ON U.Id = UV.UserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPosts,
    TotalQuestions,
    AcceptedAnswers,
    TotalScore,
    AverageViews,
    TotalVotes,
    UpVotes,
    DownVotes,
    CASE 
        WHEN TotalPosts = 0 THEN 'No posts'
        WHEN TotalQuestions = 0 THEN 'No questions'
        WHEN AcceptedAnswers > 0 THEN 'Active contributor'
        ELSE 'Lurker'
    END AS UserActivityStatus
FROM 
    FinalStats
WHERE 
    BadgeCount > 0 OR TotalPosts > 5
ORDER BY 
    TotalScore DESC, BadgeCount DESC, TotalPosts DESC;
