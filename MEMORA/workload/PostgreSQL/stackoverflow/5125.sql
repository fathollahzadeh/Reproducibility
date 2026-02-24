
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        COUNT(Vote.UserId) AS VoteCount,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        SUM(P.ViewCount) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes Vote ON P.Id = Vote.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        CommentCount, 
        VoteCount, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges, 
        TotalViewCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalViewCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    R.Rank,
    R.DisplayName,
    R.PostCount,
    R.QuestionCount,
    R.AnswerCount,
    R.CommentCount,
    R.VoteCount,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    R.TotalViewCount
FROM 
    RankedUsers R
WHERE 
    R.Rank <= 10
ORDER BY 
    R.Rank;
