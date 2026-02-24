
WITH FrequentUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users)
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        ARRAY_AGG(B.Name) AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        P.ViewCount,
        COALESCE(P.ClosedDate, '9999-12-31') AS ClosedOrNot,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)
)
SELECT 
    U.DisplayName,
    U.Reputation,
    FU.PostCount,
    FU.QuestionCount,
    FU.AnswerCount,
    UB.BadgeNames,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.PostRank,
    PD.ViewCount,
    PD.PostStatus
FROM 
    FrequentUsers FU
JOIN 
    Users U ON FU.UserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostDetails PD ON U.Id = PD.OwnerUserId
WHERE 
    PD.PostId IS NOT NULL OR PD.PostStatus = 'Open'
ORDER BY 
    U.Reputation DESC, PD.ViewCount DESC
LIMIT 100;
