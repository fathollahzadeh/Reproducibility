
WITH TagCounts AS (
    SELECT
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagCounts
    WHERE
        PostCount > 5 
),
ActiveUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionsAsked,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE
        U.Reputation > 100 
    GROUP BY
        U.Id, U.DisplayName
),
UserTagRelationships AS (
    SELECT
        U.Id AS UserId,
        T.Tag,
        COUNT(*) AS UserTagCount
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    JOIN
        TagCounts T ON T.Tag = ANY(string_to_array(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><'))
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        U.Id, T.Tag
)
SELECT
    U.DisplayName AS UserName,
    T.Tag,
    U.QuestionsAsked,
    U.PositiveScoredQuestions,
    U.TotalBounty,
    TR.UserTagCount,
    T.PostCount
FROM
    ActiveUsers U
JOIN
    UserTagRelationships TR ON U.UserId = TR.UserId
JOIN
    TopTags T ON TR.Tag = T.Tag
ORDER BY
    U.TotalBounty DESC,
    T.PostCount DESC;
