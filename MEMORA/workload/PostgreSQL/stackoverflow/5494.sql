
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        UserStats
),
ActiveTags AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 YEAR'
    GROUP BY
        t.Id, t.TagName
),
MostPopularTags AS (
    SELECT
        TagId,
        TagName,
        PostCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM
        ActiveTags
)
SELECT
    u.DisplayName AS UserName,
    u.Reputation,
    t.TagName,
    t.TotalViews,
    t.PostCount,
    u.QuestionCount,
    u.UpVotes,
    u.DownVotes
FROM
    TopUsers u
JOIN
    MostPopularTags t ON u.PostCount > 0
WHERE
    u.ReputationRank <= 10 AND t.ViewRank <= 5
ORDER BY
    u.Reputation DESC,
    t.TotalViews DESC;
