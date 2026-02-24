
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        CommentCount,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS VoteRank,
        RANK() OVER (ORDER BY (TotalUpVotes - TotalDownVotes) DESC) AS ScoreRank
    FROM 
        UserMetrics
)
SELECT 
    UM.DisplayName,
    UM.QuestionCount,
    UM.TotalUpVotes,
    UM.TotalDownVotes,
    UM.CommentCount,
    CASE 
        WHEN QR.QuestionRank <= 10 THEN 'Top 10 by Questions'
        ELSE 'Others'
    END AS QuestionRankCategory,
    CASE 
        WHEN VR.VoteRank <= 10 THEN 'Top 10 by Votes'
        ELSE 'Others'
    END AS VoteRankCategory,
    CASE 
        WHEN SR.ScoreRank <= 10 THEN 'Top 10 by Score'
        ELSE 'Others'
    END AS ScoreRankCategory
FROM 
    UserMetrics UM
JOIN 
    UserRankings QR ON UM.UserId = QR.UserId
JOIN 
    UserRankings VR ON UM.UserId = VR.UserId
JOIN 
    UserRankings SR ON UM.UserId = SR.UserId
WHERE 
    UM.QuestionCount > 0 OR UM.TotalUpVotes > 0
ORDER BY 
    UM.QuestionCount DESC, UM.TotalUpVotes DESC;
