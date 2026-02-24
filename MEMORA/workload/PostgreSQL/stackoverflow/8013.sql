
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopUsers AS (
    SELECT 
        RU.UserId, 
        RU.DisplayName, 
        RU.Reputation, 
        RU.ReputationRank, 
        RU.PostCount, 
        RU.QuestionCount, 
        RU.AnswerCount, 
        RU.UpVoteCount, 
        RU.DownVoteCount, 
        UB.BadgeCount,
        UB.BadgeNames
    FROM 
        RankedUsers RU
    LEFT JOIN 
        UserBadges UB ON RU.UserId = UB.UserId
    WHERE 
        RU.ReputationRank <= 10
)
SELECT 
    TU.DisplayName, 
    TU.Reputation, 
    TU.PostCount, 
    TU.QuestionCount, 
    TU.AnswerCount, 
    TU.UpVoteCount, 
    TU.DownVoteCount, 
    TU.BadgeCount, 
    TU.BadgeNames
FROM 
    TopUsers TU
ORDER BY 
    TU.Reputation DESC;
