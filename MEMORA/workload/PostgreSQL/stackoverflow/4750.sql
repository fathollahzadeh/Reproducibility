
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties, 
        COUNT(DISTINCT V.PostId) AS BountyCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS BountyRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalBounties DESC, PostCount DESC) AS RowNum
    FROM 
        UserStats
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.TotalBounties,
    R.BountyCount,
    R.QuestionCount,
    R.AnswerCount,
    R.BountyRank
FROM 
    RankedUsers R
WHERE 
    R.RowNum <= 10
ORDER BY 
    R.TotalBounties DESC;
