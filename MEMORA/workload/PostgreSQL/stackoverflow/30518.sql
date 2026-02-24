WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        UR.QuestionCount,
        UR.TotalViews,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY UR.TotalViews DESC) AS ViewRank
    FROM 
        UserReputation UR
    WHERE 
        UR.QuestionCount > 5
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    P.Title,
    P.CreationDate AS QuestionDate,
    P.Score AS QuestionScore,
    PH.CloseCount,
    PH.ReopenCount,
    PH.LastEditDate,
    U.DisplayName,
    U.Reputation,
    T.ViewRank,
    T.ReputationRank,
    COALESCE(UP.AnswerCount, 0) AS AnswerCount,
    COALESCE(COALESCE(UP.ViewCount, 0) * 1.0 / NULLIF(PH.CloseCount, 0), 0) AS ViewsPerClose
FROM 
    RankedPosts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistoryAnalysis PH ON P.PostId = PH.PostId
LEFT JOIN 
    TopUsers T ON U.Id = T.UserId
LEFT JOIN 
    (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount, 
            SUM(ViewCount) AS ViewCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) UP ON P.PostId = UP.ParentId
WHERE 
    P.RankByScore = 1
ORDER BY 
    P.Score DESC, 
    P.ViewCount DESC;