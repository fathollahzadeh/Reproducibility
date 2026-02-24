WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END, 0)) AS PositiveScoreCount,
        SUM(COALESCE(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END, 0)) AS NegativeScoreCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        PositiveScoreCount, 
        NegativeScoreCount, 
        TotalBounty,
        ActivityRank
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
),
TagSummary AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TagPostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.PositiveScoreCount,
    TU.NegativeScoreCount,
    TU.TotalBounty,
    TS.TagName,
    TS.TagPostCount,
    TS.TotalViews
FROM 
    TopUsers TU
LEFT JOIN 
    TagSummary TS ON TS.TagPostCount > 0
ORDER BY 
    TU.Reputation DESC, TU.PostCount DESC, TS.TotalViews DESC
LIMIT 20;