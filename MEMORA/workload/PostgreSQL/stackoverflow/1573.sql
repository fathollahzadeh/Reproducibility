
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS Status,
        PH.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation UR
    WHERE 
        UR.PostCount > 5
),
RecentPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.Status,
        PD.LastEditDate,
        ROW_NUMBER() OVER (ORDER BY PD.LastEditDate DESC) AS RecentRank
    FROM 
        PostDetails PD
    WHERE 
        PD.EditRank = 1
)

SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    RP.Title AS RecentPostTitle,
    RP.Status,
    RP.LastEditDate
FROM 
    TopUsers TU
JOIN 
    RecentPosts RP ON RP.LastEditDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
ORDER BY 
    TU.Reputation DESC, RP.LastEditDate DESC
LIMIT 10;
