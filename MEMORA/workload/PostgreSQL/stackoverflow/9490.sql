WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS AuthorName,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserName,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 10 
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    T.UserId,
    T.UserName,
    T.AvgReputation,
    T.QuestionCount,
    T.AnswerCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score
FROM 
    TopUsers T
LEFT JOIN 
    UserBadges UB ON T.UserId = UB.UserId
LEFT JOIN 
    RankedPosts RP ON T.UserId = RP.PostRank
WHERE 
    RP.PostRank = 1 
ORDER BY 
    T.AvgReputation DESC, 
    T.QuestionCount DESC;