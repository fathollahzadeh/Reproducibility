
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
QuestionStats AS (
    SELECT 
        Q.Id AS QuestionId,
        Q.Title,
        COALESCE(V.UpVotes, 0) AS UpVoteCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        CASE WHEN Q.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS HasAcceptedAnswer,
        Q.OwnerUserId
    FROM 
        Posts Q
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments GROUP BY PostId) C ON C.PostId = Q.Id
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
         FROM Votes GROUP BY PostId) V ON V.PostId = Q.Id
    WHERE 
        Q.PostTypeId = 1
), 
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.AvgPostScore,
    COUNT(DISTINCT Q.QuestionId) AS TotalQuestionsWithStats,
    SUM(Q.UpVoteCount) AS TotalUpVotes,
    SUM(Q.CommentCount) AS TotalComments,
    SUM(Q.HasAcceptedAnswer) AS TotalAcceptedAnswers,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserPostStats U
LEFT JOIN 
    QuestionStats Q ON U.UserId = Q.OwnerUserId
LEFT JOIN 
    UserBadges B ON U.UserId = B.UserId
GROUP BY 
    U.UserId, U.DisplayName, U.TotalPosts, U.TotalQuestions, U.TotalAnswers, U.AvgPostScore, 
    B.GoldBadges, B.SilverBadges, B.BronzeBadges
ORDER BY 
    U.TotalPosts DESC, U.AvgPostScore DESC
FETCH FIRST 50 ROWS ONLY;
