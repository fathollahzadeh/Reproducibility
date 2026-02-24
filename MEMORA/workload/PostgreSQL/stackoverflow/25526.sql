WITH TagFrequency AS (
    SELECT 
        trim(split_part(tag, '>', 1)) AS TagName,
        COUNT(*) AS Frequency
    FROM (
        SELECT unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS tag
        FROM Posts
        WHERE PostTypeId = 1
    ) AS TagList
    GROUP BY TagName
),

MostFrequentTags AS (
    SELECT 
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM TagFrequency
),

UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN PH.Id IS NOT NULL THEN 1 ELSE 0 END) AS EditCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)  
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounties,
        CommentCount,
        EditCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalBounties DESC) AS UserRank
    FROM UserActivity
)

SELECT 
    T.TagName,
    T.Frequency AS TagFrequency,
    U.DisplayName AS TopUser,
    U.PostCount,
    U.TotalBounties,
    U.CommentCount,
    U.EditCount
FROM MostFrequentTags T
JOIN TopUsers U ON U.UserRank <= 5  
WHERE T.Frequency > 10  
ORDER BY T.Frequency DESC, U.TotalBounties DESC;