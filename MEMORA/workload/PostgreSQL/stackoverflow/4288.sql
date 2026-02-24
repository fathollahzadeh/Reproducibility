WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        AVG(NULLIF(U.Reputation, 0)) AS AvgReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId IN (8, 9) 
    GROUP BY U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserActivity
    WHERE PostCount > 0
),
TopUsers AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY TotalBounty DESC) AS RowNum,
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        AvgReputation
    FROM ActiveUsers
    WHERE Rank <= 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalBounty,
    CASE 
        WHEN U.AvgReputation IS NULL THEN 'No Reputation'
        ELSE CAST(U.AvgReputation AS VARCHAR)
    END AS AvgReputation,
    COALESCE((SELECT STRING_AGG(T.TagName, ', ') 
              FROM Tags T
              JOIN (
                  SELECT 
                      UNNEST(string_to_array(P.Tags, '><')) AS Tag
                  FROM Posts P
                  WHERE P.OwnerUserId = U.UserId
              ) ST ON ST.Tag = T.TagName
              WHERE T.Count > 50), 'No Tags') AS PopularTags
FROM TopUsers U
LEFT JOIN Badges B ON U.UserId = B.UserId
WHERE B.Class = 1 OR B.Class = 2 
ORDER BY U.TotalBounty DESC, U.PostCount DESC;