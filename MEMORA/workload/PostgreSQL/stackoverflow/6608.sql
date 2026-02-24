
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS RN
    FROM 
        UserPostStats
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalBounty,
    TU.TotalViews,
    COALESCE(B.Name, 'No Badge') AS BadgeName
FROM 
    TopUsers TU
LEFT JOIN 
    Badges B ON TU.UserId = B.UserId
WHERE 
    TU.RN <= 10
ORDER BY 
    TU.PostCount DESC, TU.TotalViews DESC;
