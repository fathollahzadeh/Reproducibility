WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM
        UserStats
),
ActiveTags AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM
        Tags T
    JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY
        T.TagName
    HAVING
        COUNT(DISTINCT P.Id) > 0
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM
        ActiveTags
)

SELECT
    TU.Rank AS UserRank,
    TU.DisplayName AS User,
    TU.Reputation,
    TU.BadgeCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.UpVotes,
    TU.DownVotes,
    TU.TotalViews,
    TT.Rank AS TagRank,
    TT.TagName AS ActiveTag,
    TT.PostCount AS TagPostCount,
    TT.TotalViews AS TagTotalViews
FROM
    TopUsers TU
CROSS JOIN
    TopTags TT
WHERE
    TU.Rank <= 10 AND TT.Rank <= 10
ORDER BY
    TU.Rank, TT.Rank;
