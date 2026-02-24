WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentEdits AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.UserId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(UA.QuestionCount, 0) AS QuestionCount,
        COALESCE(UA.AnswerCount, 0) AS AnswerCount,
        COALESCE(RE.EditCount, 0) AS RecentEdits,
        RE.LastEditDate
    FROM 
        Users U
    LEFT JOIN 
        UserActivity UA ON U.Id = UA.UserId
    LEFT JOIN 
        RecentEdits RE ON U.Id = RE.UserId
)
SELECT 
    UR.UserId,
    UR.Reputation,
    UR.QuestionCount,
    UR.AnswerCount,
    UR.RecentEdits,
    CASE 
        WHEN UR.Reputation > 1000 THEN 'High' 
        WHEN UR.Reputation BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'Low' 
    END AS ReputationCategory,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = UR.UserId AND B.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = UR.UserId AND B.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = UR.UserId AND B.Class = 3) AS BronzeBadges
FROM 
    UserReputation UR
WHERE 
    (UR.QuestionCount > 5 OR UR.AnswerCount > 10) 
    AND (UR.Reputation IS NOT NULL)
ORDER BY 
    UR.Reputation DESC, UR.UserId
LIMIT 10;