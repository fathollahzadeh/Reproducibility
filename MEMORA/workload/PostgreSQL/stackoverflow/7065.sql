WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeStats AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS Badges,
        COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        US.AnswerCount,
        US.QuestionCount,
        US.TotalBounty,
        COALESCE(BS.Badges, 'No Badges') AS Badges,
        BS.BadgeCount
    FROM 
        UserStats US
    LEFT JOIN 
        BadgeStats BS ON US.UserId = BS.UserId
    ORDER BY 
        US.Reputation DESC
    LIMIT 10
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    AnswerCount,
    QuestionCount,
    TotalBounty,
    Badges,
    BadgeCount
FROM 
    TopUsers;
